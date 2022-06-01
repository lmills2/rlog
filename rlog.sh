#!/bin/bash
## ------------------
## rlog Kx Surveillance log reading utility
	VER="v1.0.1"
## ------------------

ASSET_CLASS="def"
REGION="global"

print_usage() {
	printf "============================================================================
		rlog - Kx Surveillance log reading utility
============================================================================

Usage: Calls less on the latest log for the given process name. Either the full process name or the shortcuts listed below can be used.

Optional Flags:
	- [-t] Calls tail -f on the latest log.
	- [-s] Looks in stage logs .
	- [-l] Returns the list of found logs.
	- [-e] Greps the last log for 'error'.
	- [-f] Finds the given phrase in the latest log. (Phrase must not be separated by white space from option).
	- [-a] Set the asset class to use for looking for logs. Default is '${ASSET_CLASS}'.
	- [-r] Set the region to use for looking for logs. Default is '${REGION}'.
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
	- hdb\t\t${REGION}_hdb_core_transactionData_${ASSET_CLASS}_0_a
	- hdb2\t\t${REGION}_hdb_core_transactionData_${ASSET_CLASS}_2_a
	- hdb3\t\t${REGION}_hdb_core_transactionData_${ASSET_CLASS}_3_a

Core:
	- master\tsurv_master_a
	- at\t\tsurv_at_a
	- gwat\t\tsurv_gw_at_a
	- qrgw1-3\tqr_gw_surv_entrypoint_1_a_1-3
	- qr\t\temea_qr_surv_entrypoint_1_a_1
	- gw\t\temea_gw_0_a
	- qm\t\temea_qm_0_a

Realtime WF:
	- rman\t\tsurv_manager_realtime_${ASSET_CLASS}_1_a_1
	- reng\t\tsurv_engine_realtime_${ASSET_CLASS}_1_a_1
	- reng2\t\tsurv_engine_realtime_${ASSET_CLASS}_1_a_2
	- reng3\t\tsurv_engine_realtime_${ASSET_CLASS}_1_a_3
	- rhdb\t\tsurv_hdb_benchmark_realtime_${ASSET_CLASS}_1_a_1
	- rhdb2\t\tsurv_hdb_benchmark_realtime_${ASSET_CLASS}_1_a_2
	- rtp\t\tsurv_tp_realtime_${ASSET_CLASS}_1_a_1
	- rppe\t\tsurv_preprocessing_realtime_${ASSET_CLASS}_1_a_1

Replay WF 1:
        - wman\t\tsurv_manager_replay_${ASSET_CLASS}_1_a_1
        - weng\t\tsurv_engine_replay_${ASSET_CLASS}_1_a_1
        - weng2\t\tsurv_engine_replay_${ASSET_CLASS}_1_a_2
        - weng3\t\tsurv_engine_replay_${ASSET_CLASS}_1_a_3
        - whdb\t\tsurv_hdb_benchmark_replay_${ASSET_CLASS}_1_a_1
        - whdb2\t\tsurv_hdb_benchmark_replay_${ASSET_CLASS}_1_a_2
        - wppe\t\tsurv_preprocessing_replay_${ASSET_CLASS}_1_a_1
	- wreplay\tsurv_replay_replay_1_a_1

Dataloader:
	- disp\t\tsurv_dl_dispatcher_a
	- dl1-3\t\tsurv_dl_(1-3)_a
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
while getopts 'tshledf::a::r::' flag; do
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
		f) grep_flag='true'
		   grep_str="${OPTARG}" ;;
        esac
done

if [ "$tomcat_flag" == 'true' ]; then
	LOGDIR="${SCRIPT_DIR}/../software/Tomcat_9_0_54/latest/logs"
else
	LOGDIR="${SCRIPT_DIR}/../../delta-data/DeltaControlData/logdir"
fi
LOG="${BASH_ARGV[0]}"

case "$LOG" in
	"delta")	RES="DeltaControl\.*log*" ;;
	"daemon")	RES="DeltaControlDaemon*.log*" ;;
	"rdb")		RES="${REGION}_rdb_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"tp")		RES="${REGION}_tp_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"rte")		RES="${REGION}_rte_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"pdb")		RES="${REGION}_pdb_core_transactionData_${ASSET_CLASS}_0_a.1*.log*" ;;
	"ctp")		RES="${REGION}_ctp_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"hdb")		RES="${REGION}_hdb_core_transactionData_${ASSET_CLASS}_0_a*.log*" ;;
	"hdb2")		RES="${REGION}_hdb_core_transactionData_${ASSET_CLASS}_1_a*.log*" ;;
	"hdb3")		RES="${REGION}_hdb_core_transactionData_${ASSET_CLASS}_2_a*.log*" ;;
	"master")	RES="surv_master_a*.log*" ;;
	"at")		RES="surv_at_a*.log*" ;;
	"gwat")		RES="surv_gw_at_a*.log*" ;;
	"qrgw1")	RES="qr_gw_surv_entrypoint_1_a_1*.log*" ;;
	"qrgw2")	RES="qr_gw_surv_entrypoint_1_a_2*.log*" ;;
	"qrgw3")	RES="qr_gw_surv_entrypoint_1_a_3*.log*" ;;
	"qr")		RES="emea_qr_surv_entrypoint_1_a_1*.log*" ;;
	"gw")		RES="emea_gw_0_a*.log*" ;;
	"qm")		RES="emea_qm_0_a*.log*" ;;
	"rman")		RES="surv_manager_realtime_${ASSET_CLASS}_1_a_1*.log*" ;;
	"reng")		RES="surv_engine_realtime_${ASSET_CLASS}_1_a_1*.log*" ;;
	"reng2")	RES="surv_engine_realtime_${ASSET_CLASS}_1_a_2*.log*" ;;
	"reng3")	RES="surv_engine_realtime_${ASSET_CLASS}_1_a_3*.log*" ;;
	"rhdb")		RES="surv_hdb_benchmark_realtime_${ASSET_CLASS}_1_a_1*.log*" ;;
	"rhdb2")	RES="surv_hdb_benchmark_realtime_${ASSET_CLASS}_1_a_2*.log*" ;;
	"rtp")		RES="surv_tp_realtime_${ASSET_CLASS}_1_a_1*.log*" ;;
	"rppe")		RES="surv_preprocessing_realtime_${ASSET_CLASS}_1_a_1*.log*" ;;
	"wman")         RES="surv_manager_replay_${ASSET_CLASS}_1_a_1*.log*" ;;
        "weng")         RES="surv_engine_replay_${ASSET_CLASS}_1_a_1*.log*" ;;
        "weng2")        RES="surv_engine_replay_${ASSET_CLASS}_1_a_2*.log*" ;;
        "weng3")        RES="surv_engine_replay_${ASSET_CLASS}_1_a_3*.log*" ;;
        "whdb")         RES="surv_hdb_benchmark_replay_${ASSET_CLASS}_1_a_1*.log*" ;;
        "whdb2")        RES="surv_hdb_benchmark_replay_${ASSET_CLASS}_1_a_2*.log*" ;;
	"wppe")         RES="surv_preprocessing_replay_${ASSET_CLASS}_1_a_1*.log*" ;;
	"wreplay")	RES="surv_replay_replay_${ASSET_CLASS}_1_a_1*.log*" ;;
	"disp")		RES="surv_dl_dispatcher_a*.log*" ;;
	"dl1")		RES="surv_dl_1_a*.log*" ;;
	"dl2")		RES="surv_dl_2_a*.log*" ;;
	"dl3")		RES="surv_dl_3_a*.log*" ;;
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

if [ "$tail_flag" == 'true' ]; then
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort -r | head -n1 | cut -d ' ' -f2 - | xargs tail -f
elif [ "$list_flag" == 'true' ]; then
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort 
elif [ "$grep_flag" == 'true' ]; then
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort -r | head -n1 | cut -d ' ' -f2 - | xargs -I {} grep -i --color -B5 "$grep_str" {}
else
	find $LOGDIR -type f -name "$RES" -printf '%T+ %p\n' | sort -r | head -n1 | cut -d ' ' -f2 - | xargs -I {} less {}
fi
