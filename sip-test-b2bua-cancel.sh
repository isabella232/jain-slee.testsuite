#!/bin/bash

### SIP B2BUA CANCEL
echo -e "\nTesting SIP B2BUA CANCEL Example"
cd $HOME/examples/sip-b2bua

echo -e "\nStart Single Test\n"
cp $LOG/siptests-jboss.log $LOG/out-b2bua-cancel-0.log
cd sipp

$SIPP -trace_err -sf uas_CANCEL.xml -i 127.0.0.1 -p 5090 -r 1 -m 10 -l 100 -bg
#UAS_PID=$!
UAS_PID=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
if [ "$UAS_PID" == "" ]; then
  exit -1
fi
echo "UAS: $UAS_PID"

sleep 1
$SIPP 127.0.0.1:5060 -trace_err -sf uac_CANCEL.xml -i 127.0.0.1 -p 5050 -r 1 -m 10 -l 100 -bg
#UAC_PID=$!
UAC_PID=$(ps aux | grep '[u]ac_CANCEL.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit
fi
echo "UAC: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    break
  fi
done

SIP_B2BUA_CANCEL_EXIT=$?
echo -e "SIP B2BUA CANCEL Single Test result: $SIP_B2BUA_CANCEL_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Single test"

diff $LOG/out-b2bua-cancel-0.log $LOG/siptests-jboss.log > $LOG/out-b2bua-cancel.simple.log
ERRCOUNT=$(grep -ic " error " $LOG/out-b2bua-cancel.simple.log)
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-b2bua-cancel.simple.log\n" >> $REPORT
else
  rm -f $LOG/out-b2bua-cancel.simple.log
fi

echo -e "\nStart Performance Test\n"
cp $LOG/siptests-jboss.log $LOG/out-b2bua-cancel-0.log

$SIPP -trace_err -sf uas_CANCEL.xml -i 127.0.0.1 -p 5090 -r 10 -m 500 -l 400 -bg
#$SIPP -trace_err -sf uas_CANCEL.xml -i 127.0.0.1 -p 5090 -r 400 -rp 85s -m 500 -l 400 -bg
#UAS_PID=$!
UAS_PID=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
if [ "$UAS_PID" == "" ]; then
  exit -1
fi
echo "UAS: $UAS_PID"

sleep 1
$SIPP 127.0.0.1:5060 -trace_err -sf uac_CANCEL.xml -i 127.0.0.1 -p 5050 -r 10 -m 500 -l 400 -bg
#$SIPP 127.0.0.1:5060 -trace_err -sf uac_CANCEL.xml -i 127.0.0.1 -p 5050 -r 400 -rp 85s -m 500 -l 400 -bg
#UAC_PID=$!
UAC_PID=$(ps aux | grep '[u]ac_CANCEL.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit
fi
echo "UAC: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    break
  fi
done

SIP_B2BUA_CANCEL_PERF_EXIT=$?
echo -e "SIP B2BUA CANCEL Performance Test result: $SIP_B2BUA_CANCEL_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"

diff $LOG/out-b2bua-cancel-0.log $LOG/siptests-jboss.log > $LOG/out-b2bua-cancel.perf.log
ERRCOUNT=$(grep -ic " error " $LOG/out-b2bua-cancel.perf.log)
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-b2bua-cancel.perf.log\n" >> $REPORT
else
  rm -f $LOG/out-b2bua-cancel.perf.log
fi
###

sleep 30
rm -f $LOG/$LOG/out-*-0.log