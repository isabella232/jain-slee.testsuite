#!/bin/bash
#export JSLEE=/opt/mobicents/mobicents-slee-2.8.14.40
#export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA
#export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"
#export SIPP=$PWD/sipp

#export LBVERSION=2.0.17
#rm -rf logs
#mkdir logs

export START=1
export SUCCESS=0

echo -e "\nUAS Performance Test\n"
echo -e "Start Load Balancer and Cluster\n"

export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false"
java $JAVA_OPTS -DlogConfigFile=$LBTEST/lb-log4j.xml -jar $LBPATH/sip-balancer-jar-$LBVERSION-jar-with-dependencies.jar -mobicents-balancer-config=$LBTEST/lb-configuration.xml &
export LB_PID="$!"
echo "Load Balancer: $LB_PID"
echo "Wait 10 seconds.."
sleep 10

export JBOSS_HOME=$LB_JBOSS1
$LB_JBOSS1/bin/run.sh -c default -b 127.0.0.1 -Djboss.service.binding.set=ports-01 -Djboss.messaging.ServerPeerID=0 -Dsession.serialization.jboss=false > $LOG/lb-uas-load-port-1-jboss.log 2>&1 &
export NODE1_PID="$!"
echo "NODE1: $NODE1_PID"

sleep 10

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo " .. $TIME seconds"
  STARTED_IN_1=$(grep -c " Started in " $LOG/lb-uas-load-port-1-jboss.log)
  if [ "$STARTED_IN_1" == 1 ]; then break; fi
  
  if [ $TIME -gt 300 ]; then
    export START=0
    break
  fi
done

if [ "$START" -eq 0 ]; then
  echo "There is a problem with starting Load Balancer and Cluster!"
  echo "Wait 10 seconds.."
  
  pkill -TERM -P $NODE1_PID
  sleep 10
  
  kill $LB_PID
  wait $LB_PID 2>/dev/null
  exit $SUCCESS
fi

export JBOSS_HOME=$LB_JBOSS2
$LB_JBOSS2/bin/run.sh -c default -b 127.0.0.2 -Djboss.service.binding.set=ports-02 -Djboss.messaging.ServerPeerID=1 -Dsession.serialization.jboss=false > $LOG/lb-uas-load-port-2-jboss.log 2>&1 &
export NODE2_PID="$!"
echo "NODE2: $NODE2_PID"

sleep 10

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo " .. $TIME seconds"
  STARTED_IN_2=$(grep -c " Started in " $LOG/lb-uas-load-port-2-jboss.log)
  if [ "$STARTED_IN_2" == 1 ]; then break; fi
  
  if [ $TIME -gt 300 ]; then
    export START=0
    break
  fi
done

if [ "$START" -eq 1 ]; then
  echo "Load Balancer and Cluster are ready!"
else
  echo "There is a problem with starting Load Balancer and Cluster!"
  echo "Wait 20 seconds.."
    
  pkill -TERM -P $NODE1_PID
  sleep 10
  pkill -TERM -P $NODE2_PID
  sleep 10
  
  kill $LB_PID
  wait $LB_PID 2>/dev/null
  exit $SUCCESS
fi

echo "sleeping 10 sec"
sleep 10

####
#exit 1

echo -e "\nStart UAS Performance Test\n"
echo -e "    UAS Performance Test is Started\n" >> $REPORT

#cp $LOG/load-balancer.log $LOG/out-load-balancer-uas-0.log
#cp $LOG/lb-port-1-jboss.log $LOG/out-port-1-uas-0.log
#cp $LOG/lb-port-2-jboss.log $LOG/out-port-2-uas-0.log

cd $JSLEE/examples/sip-uas/sipp
#$SIPP 127.0.0.1:5060 -inf users.csv -nd -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 600 -rp 60s -m 800 -l 1000 -bg
$SIPP 127.0.0.1:5060 -inf users.csv -nd -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 10 -m 700 -l 1000 -bg

UAC_PID=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit -1
fi
echo "UAC_PID: $UAC_PID"

#sleep 210s
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  
  #diff $LOG/out-load-balancer-uas-0.log $LOG/load-balancer.log > $LOG/out-$TIME.lbuas.log
  #diff $LOG/out-port-1-uas-0.log $LOG/lb-port-1-jboss.log >> $LOG/out-$TIME.lbuas.log
  #diff $LOG/out-port-2-uas-0.log $LOG/lb-port-2-jboss.log >> $LOG/out-$TIME.lbuas.log
  
  #ERRCOUNT=$(grep -ic " error " $LOG/out-$TIME.lbuas.log)
  #SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
  #if [ "$ERRCOUNT" != 0 ]; then
  #  export SUCCESS=0
  #  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-TIME.lbuas.log\n"
  #  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-TIME.lbuas.log\n" >> $REPORT
  #  kill -9 $UAC_PID
  #  break
  #else
  #  echo "Nothing"
  #  #rm -f $LOG/out-*.lbuas.log
  #fi
  # error handling
  
  
  TEST=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then
    export SUCCESS=1
    break
  fi
done

# error handling
if [ -f $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log ]; then
  NUMOFLINES=$(wc -l < $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log)
  WATCHDOG=$(grep -c "Overload warning: the minor watchdog timer" $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log)
  TEST=$((NUMOFLINES-1-WATCHDOG))
  if [ "$TEST" -gt 0 ]
  then
    export SUCCESS=0
    echo "WATCHDOG: $WATCHDOG of NUMOFLINES: $NUMOFLINES"
    echo -e "There are errors. See ERRORs in $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log\n"
    echo -e "        There are errors. See ERRORs in $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log\n" >> $REPORT
  fi
fi

SIP_UAS_PERF_EXIT=$?
echo -e "UAS Performance Test is Finished: $SIP_UAS_PERF_EXIT for $TIME seconds\n"
echo -e "    UAS Performance Test is Finished: $SIP_UAS_PERF_EXIT for $TIME seconds\n" >> $REPORT

echo "Stopping Cluster nodes and Load Balancer."
echo "Wait 20 seconds.."

pkill -TERM -P $NODE1_PID
sleep 10
pkill -TERM -P $NODE2_PID
sleep 10

#kill -9 $LB_PID
kill $LB_PID
wait $LB_PID 2>/dev/null

cd $LOG
echo $PWD
find . -name 'load-balancer.log*' -exec bash -c 'mv $0 ${0/load-balancer/lb-uas-load-loadbalancer}' {} \;

exit $SUCCESS
