online_db_name=$1
dev_db_name=$2
back=$3
[ -z "${online_db_name}" ] && echo "usage $0 online_db_name dev_db_name [bak]" && exit 1
[ -z "${dev_db_name}" ] && echo "usage $0 online_db_name dev_db_name [bak]" && exit 1
mysqldumpbin="/usr/bin/mysqldump"
mysqlbin="/usr/bin/mysql"
[ ! -f "${mysqldumpbin}" ] && mysqldumpbin="$(which mysqldump)"
[ ! -f "${mysqlbin}" ] && mysqlbin="$(which mysql)"
online_db_file="online-${online_db_name}-$(date +%H%M%S).sql"
dev_back_file="dev-backup-$(date +%H%M%S).sql"
echo -ne "=========== get online db ${online_db_name} to ~/${online_db_file} .."
${mysqldumpbin} -hw-w7.wg.zwt.qihoo.net -udevget -pdev_passwd@qihoo@game ${online_db_name} > ~/"${online_db_file}"
[ $? -ne 0 ] && exit 1
echo "done ======"
[ "${back}zzz" == "bakzzz" ] && echo -ne "=========== backup mysql.demo.1360.com ${dev_db_name} to ~/${dev_back_file} .. " && ${mysqldumpbin} -hmysql.demo.1360.com -udev -pwan@qihoo@CN $dev_db_name > ~/"${dev_back_file}" && echo "done ======"
echo -ne "=========== put ~/${online_db_file} to mysql.demo.1360.com ${dev_db_name} .. "
${mysqlbin} -hmysql.demo.1360.com -udev -pwan@qihoo@CN "$dev_db_name" < ~/"${online_db_file}"
[ $? -ne 0 ] && exit 1
echo "done ======"

