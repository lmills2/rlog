#!/bin/bash
#### ------------------
## rlog Kx Surveillance log reading utility
VER="v1.0.7"
#### ------------------
# This script uses the directory it is started from to find the environment to read, and
# assumes it is in the delta-bin/bin directory. It won't run from a different directory.
#### ------------------

## The default asset class and region to use
ASSET_CLASS="def"
REGION="global"
WF="1"

print_usage() {
	printf "============================================================================
		rlog - Kx Surveillance log reading utility
============================================================================

Utility for reading Kx Surveillance process logs. The default behaviour is to call less on the given log, however this can be
modified using the optional flags. Either a full process name or a log-type shortcut can be used.
Logs for processes with multiple clones can be viewed by adding the clone number to the end of the log type input. For example, 'reng2' will
retrieve the log for realtime engine clone 2 -> surv_engine_realtime_${ASSET_CLASS}_1_a_2. If no number is given, the log for the first clone
will be retrieved (0 or 1, process dependent).

It is recommended to create an alias pointing to this script for ease of use.

Example:\trlog hdb <-> will less the log for ${REGION}_hdb_core_transactionData_${ASSET_CLASS}_0_a
\t\trlog -t master <-> will tail the log for surv_master_a

Optional Flags:
	- [-t] Calls tail -f on the latest log.
	- [-s] Looks in stage logs .
	- [-l] Returns the list of found logs.
	- [-e] Greps the last log for 'error'.
	- [-f] Finds the given phrase in the latest log. (Phrase must not be separated by white space from option).
	- [-a] Set the asset class to use for looking for logs. Default is '${ASSET_CLASS}'.
	- [-r] Set the region to use for looking for logs. Default is '${REGION}'.
	- [-w] Set the WF Clone to look for. Default is '${WF}'.
	- [-d] Options for Tomcat logs.
	- [-h] Help.
	
Required arguments:
	- log-type/name

======================================

Log types available:

Delta:
	- delta\t\tDeltaControl
	- daemon\tDeltaControlDaemon

Global Stack:
	- rdb\t\t${REGION}_rdb_core_transactionData_${ASSET_CLASS}_0_a
	- tp\t\t${REGION}_tp_core_transactionData_${ASSET_CLASS}_0_a
	- rte\t\t${REGION}_rte_core_transactionData_${ASSET_CLASS}_0_a
	- pdb\t\t${REGION}_pdb_core_transactionData_${ASSET_CLASS}_0_a
	- ctp\t\t${REGION}_ctp_core_transactionData_${ASSET_CLASS}_0_a
	- hdb(n)\t${REGION}_hdb_core_transactionData_${ASSET_CLASS}_(n)_a

Core:
	- master\tsurv_master_a
	- at\t\tsurv_at_a
	- gwat\t\tsurv_gw_at_a
	- qrgw(n)\tqr_gw_surv_entrypoint_1_a_(n)
	- qr\t\temea_qr_surv_entrypoint_1_a_1
	- gw\t\temea_gw_0_a
	- qm\t\temea_qm_0_a
	- udf\t\temea_udf_0_a

Ops:
	- ogw\t\tds_gw_ops_a
	- ohdb\t\tds_hdb_ops_a
	- oqm\t\tds_qm_ops_a
	- ordb\t\tds_rdb_ops_a
	- orte\t\tds_rte_ops_a
	- otp\t\tds_tp_ops_a

Realtime WF:
	- rman\t\tsurv_manager_realtime_${ASSET_CLASS}_1_a_1
	- reng(n)\tsurv_engine_realtime_${ASSET_CLASS}_1_a_(n)
	- rhdb(n)\tsurv_hdb_benchmark_realtime_${ASSET_CLASS}_1_a_(n)
	- rtp\t\tsurv_tp_realtime_${ASSET_CLASS}_1_a_1
	- rppe\t\tsurv_preprocessing_realtime_${ASSET_CLASS}_1_a_1

Replay WF 1:
        - wman\t\tsurv_manager_replay_${ASSET_CLASS}_1_a_1
        - weng(n)\tsurv_engine_replay_${ASSET_CLASS}_1_a_(n)
        - whdb(n)\tsurv_hdb_benchmark_replay_${ASSET_CLASS}_1_a_(n)
        - wppe\t\tsurv_preprocessing_replay_${ASSET_CLASS}_1_a_1
	- wreplay\tsurv_replay_replay_1_a_1

Dataloader:
	- disp\t\tsurv_dl_dispatcher_a
	- dl(n)\t\tsurv_dl_(n)_a
	- mvf\t\tsurv_dl_moveFiles_a
	- ogf\t\tsurv_dl_outgoingFiles_a

Tomcat: 
	- derror\tdeltaError
	- dclient\tdeltaClient
	- tstart\ttomcat_start
	- delta
	- connect
	- security
	- streaming

rlog ${VER}
"
}

## Assumes we are in delta-data/bin
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";

if [ ! "$1" ]; then
	print_usage
	exit 0;
fi

tail_flag='false'
list_flag='false'
grep_flag='false'
tomcat_flag='false'

ENV="dev"
grep_str=" "
while getopts 'tshledf::a::r::w::' flag; do
        case "${flag}" in
                t) tail_flag='true' ;;
		s) ENV="stage" ;;
                h) print_usage
                   exit 1 ;;
		l) list_flag='true' ;; 
		e) grep_flag='true'
		   grep_str="error" ;;
		d) tomcat_flag='true' ;;
		a) ASSET_CLASS="${OPTARG}" ;;
		r) REGION="${OPTARG}" ;;
		w) WF="${OPTARG}" ;;
		f) grep_flag='true'
		   grep_str="${OPTARG}" ;;
        esac
done

if [ "$tomcat_flag" == 'true' ]; then
	LOGDIR="${SCRIPT_DIR}/../software/Tomcat_9_0_54/latest/logs"
else
	LOGDIR="${SCRIPT_DIR}/../../delta-data/DeltaControlData/logdir"
fi
INP="${BASH_ARGV[0]}"
wordRegex='(^.+?)(?=[0-9]+$|$)'
numRegex='[0-9]+$'
LOG=$(echo $INP | grep -oP $wordRegex)
NUM=$(echo $INP | grep -oP $numRegex)
FOUND_NUM='true'
if [ -z "$NUM" ]; then
	NUM='1'
	FOUND_NUM='false'
fi

case "$LOG" in
	"delta")	RES="DeltaControl\.*log*" ;;
	"daemon")	RES="DeltaControlDaemon*.log*" ;;
	"rdb")		RES="${REGION}_rdb_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"tp")		RES="${REGION}_tp_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"rte")		RES="${REGION}_rte_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"pdb")		RES="${REGION}_pdb_core_transactionData_${ASSET_CLASS}_0_a.1*.log*" ;;
	"ctp")		RES="${REGION}_ctp_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"hdb")		if [ "$FOUND_NUM" == 'false' ]; then NUM='0'; fi
			RES="${REGION}_hdb_core_transactionData_${ASSET_CLASS}_${NUM}_a*.log*" ;;
	"master")	RES="surv_master_a*.log*" ;;
	"at")		RES="surv_at_a*.log*" ;;
	"gwat")		RES="surv_gw_at_a*.log*" ;;
	"qrgw")		RES="qr_gw_surv_entrypoint_${WF}_a_${NUM}*.log*" ;;
	"qr")		RES="emea_qr_surv_entrypoint_${WF}_a_${NUM}*.log*" ;;
	"gw")		RES="emea_gw_0_a*.log*" ;;
	"qm")		RES="emea_qm_0_a*.log*" ;;
	"udf")		RES="emea_udf_0_a*.log*" ;;
	"ogw")		RES="ds_gw_ops_a*.log*" ;;
	"ohdb")		RES="ds_hdb_ops_a*.log*" ;;
	"oqm")		RES="ds_qm_ops_a*.log*" ;;
	"ordb")		RES="ds_rdb_ops_a*.log*" ;;
	"orte")		RES="ds_rte_ops_a*.log*" ;;
	"otp")		RES="ds_tp_ops_a*.log*" ;;
	"rman")		RES="surv_manager_realtime_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"reng")		RES="surv_engine_realtime_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"rhdb")		RES="surv_hdb_benchmark_realtime_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"rtp")		RES="surv_tp_realtime_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"rppe")		RES="surv_preprocessing_realtime_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"wman")         RES="surv_manager_replay_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
        "weng")         RES="surv_engine_replay_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
        "whdb")         RES="surv_hdb_benchmark_replay_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"wppe")         RES="surv_preprocessing_replay_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"wreplay")	RES="surv_replay_replay_${ASSET_CLASS}_${WF}_a_${NUM}*.log*" ;;
	"disp")		RES="surv_dl_dispatcher_a*.log*" ;;
	"dl")		RES="surv_dl_${NUM}_a*.log*" ;;
	"mvf")		RES="surv_dl_moveFiles_a*.log*" ;;
	"ogf")		RES="surv_dl_outgoingFiles_a*.log*" ;;
	"derror")	RES="deltaError.log*" ;;
	"dclient")	RES="deltaClient.log*" ;;
	"delta")	RES="delta.log*" ;;
	"connect")	RES="connect.log*" ;;
	"security")	RES="security.log*" ;;
	"tstart")	RES="tomcat_start.out" ;;
	"streaming")	RES="streaming.log*" ;;
	*)		RES="$LOG*.log*" ;;
esac

echo "Opening log -- ${RES}"

if [ "$tail_flag" == 'true' ]; then
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort -r | head -n1 | cut -d ' ' -f2 - | xargs tail -f
elif [ "$list_flag" == 'true' ]; then
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort 
elif [ "$grep_flag" == 'true' ]; then
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort -r | head -n1 | cut -d ' ' -f2 - | xargs -I {} grep -i --color -B5 "$grep_str" {}
else
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort -r | head -n1 | cut -d ' ' -f2 - | xargs -I {} less {}
fi
