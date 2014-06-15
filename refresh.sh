#!/bin/bash
source /home/ec2-user/.bash_profile

echo "Starting..."
mv ./slaves $HADOOP_CONF_DIR/slaves
mv ./masters $HADOOP_CONF_DIR/masters
filename="$HADOOP_CONF_DIR/slaves"
filelines=`cat $filename`
for line in $filelines ; do
	echo "Refreshing $line"
    scp $HADOOP_CONF_DIR/masters ec2-user@$line:$HADOOP_CONF_DIR/
    scp $HADOOP_CONF_DIR/slaves ec2-user@$line:$HADOOP_CONF_DIR/
done
echo "Finished!"
