#!/usr/bin/env bash

about() {
	echo ""
	echo " ========================================================= "
	echo " \               Speedtest Bench.Monster                 / "
	echo " \         https://bench.monster/speedtest.html          / "
	echo " \    System info, Geekbench, I/O test and speedtest     / "
	echo " \                  v1.4.5   2019-10-13                  / "
	echo " ========================================================= "
	echo ""
}

cancel() {
	echo ""
	next;
	echo " Abort ..."
	echo " Cleanup ..."
	cleanup;
	echo " Done"
	exit
}

trap cancel SIGINT

benchram="$HOME/tmpbenchram"
NULL="/dev/null"

echostyle(){
	if hash tput 2>$NULL; then
		echo " $(tput setaf 6)$1$(tput sgr0)"
		echo " $1" >> $log
	else
		echo " $1" | tee -a $log
	fi
}

benchinit() {
	# check release
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	fi

	# check OS
	#if [ "${release}" == "centos" ]; then
	#                echo "Checking OS ... [ok]"
	#else
	#                echo "Error: This script must be run on CentOS!"
	#		exit 1
	#fi
	#echo -ne "\e[1A"; echo -ne "\e[0K\r"
	
	# check root
	[[ $EUID -ne 0 ]] && echo -e "Error: This script must be run as root!" && exit 1
	

	# check python
	if  [ ! -e '/usr/bin/python' ]; then
	        echo " Installing Python2 ..."
	            if [ "${release}" == "centos" ]; then
	                    yum update > /dev/null 2>&1
	                    yum install -y python2 > /dev/null 2>&1
			    alternatives --set python /usr/bin/python2 > /dev/null 2>&1
	                else
	                	apt-get update > /dev/null 2>&1
	                    apt-get install -y python > /dev/null 2>&1
	                fi
	        echo -ne "\e[1A"; echo -ne "\e[0K\r" 
	fi

	# check curl
	if  [ ! -e '/usr/bin/curl' ]; then
	        echo " Installing Curl ..."
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum install -y curl > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get install -y curl > /dev/null 2>&1
	            fi
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi

	# check wget
	if  [ ! -e '/usr/bin/wget' ]; then
	        echo " Installing Wget ..."
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum install -y wget > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get install -y wget > /dev/null 2>&1
	            fi
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	
	# check bzip2
	if  [ ! -e '/usr/bin/bzip2' ]; then
	        echo " Installing bzip2 ..."
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum install -y bzip2 > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get install -y bzip2 > /dev/null 2>&1
	            fi
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi

	# install speedtest-cli
	if  [ ! -e 'speedtest.py' ]; then
		echo " Installing Speedtest-cli ..."
		wget --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest.py > /dev/null 2>&1
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	chmod a+rx speedtest.py


	# install tools.py
	if  [ ! -e 'tools.py' ]; then
		echo " Installing tools.py ..."
		wget --no-check-certificate https://raw.githubusercontent.com/laset-com/speedtest/master/tools.py > /dev/null 2>&1
		echo -ne "\e[1A"; echo -ne "\e[0K\r"
	fi
	chmod a+rx tools.py

	sleep 5

	# start
	start=$(date +%s) 
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
}
next2() {
    printf "%-57s\n" "-" | sed 's/\s/-/g'
}

delete() {
    echo -ne "\e[1A"; echo -ne "\e[0K\r"
}

speed_test(){
	if [[ $1 == '' ]]; then
		temp=$(python speedtest.py --share 2>&1)
		is_down=$(echo "$temp" | grep 'Download')
		result_speed=$(echo "$temp" | awk -F ' ' '/results/{print $3}')
		if [[ ${is_down} ]]; then
	        local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
	        local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
	        local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')

	        temp=$(echo "$relatency" | awk -F '.' '{print $1}')
        	if [[ ${temp} -gt 50 ]]; then
            	relatency="*"${relatency}
        	fi
	        local nodeName=$2

	        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "%-17s%-17s%-17s%-7s\n" " ${nodeName}" "${reupload}" "${REDownload}" "${relatency}" | tee -a $log
	        fi
		else
	        local cerror="ERROR"
		fi
	else
		temp=$(python speedtest.py --server $1 --share 2>&1)
		is_down=$(echo "$temp" | grep 'Download') 
		if [[ ${is_down} ]]; then
	        local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
	        local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
	        #local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
	        local relatency=$(pingtest $3)
	        #temp=$(echo "$relatency" | awk -F '.' '{print $1}')
        	#if [[ ${temp} -gt 1000 ]]; then
            	#relatency=" - "
        	#fi
	        local nodeName=$2

	        temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "%-17s%-17s%-17s%-7s\n" " ${nodeName}" "${reupload}" "${REDownload}" "${relatency}" | tee -a $log
			fi
		else
	        local cerror="ERROR"
		fi
	fi
}

print_speedtest() {
	echo "" | tee -a $log
	echostyle "### {全球}網路速度測試"
	echo "" | tee -a $log
	printf "%-32s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
        speed_test '' 'Speedtest.net                 '
	speed_test '16974' 'US, CA, 洛杉磯 (Spectrum)     ' 'http://speedtest.west.rr.com'
	speed_test '22288' 'US, TX, 達拉斯 (Hivelocity)   ' 'http://speedtest.dal.hivelocity.net'
	speed_test '24151' 'US, IL, 芝加哥 (Verizon)      ' 'http://ilhhp1.speed.vzwnet.com'
	speed_test '18956' 'US, NY, 紐約 (Hivelocity)     ' 'http://speedtest.nyc.hivelocity.net'
	speed_test '14237' 'US, FL, 坦帕 (Spectrum)       ' 'http://tampp-speedtest-01.noc.bhn.net'
	### https://www.speedtest.net/reports/canada/#fixed
	### https://ispspeedindex.netflix.com/country/canada/
	speed_test '3575' 'CA, 多倫多 (Telus)            ' 'http://toronto.speedtest.telus.com'
	speed_test '3049' 'CA, 溫哥華 (Telus)            ' 'http://vancouver.speedtest.telus.com'
	### https://ispspeedindex.netflix.com/country/chile/
	speed_test '1858' 'CL, 聖地亞哥 (Entel)          ' 'http://speedtest1.entelchile.net'
	### https://ispspeedindex.netflix.com/country/peru/
	speed_test '1858' 'PE, 利馬 (Fiberluxperu)       ' 'http://medidor.fiberluxperu.com'
	speed_test '3967' 'TW, 臺北市 (是方電訊)         ' 'http://tpv3-1.speedtest.idv.tw'
	speed_test '18840' 'TW, 臺北市 (BGP Network)      ' 'http://speedtest.tw.bgp.net'
	speed_test '24375' 'HK, 上環 (GTT.net)            ' 'http://hon.speedtest.gtt.net'
	speed_test '27377' 'CN, 北京市 (中國電信 5G)      ' 'http://speedtest25.jillbanging.com'
	speed_test '20976' 'JP, 東京 (GLBB)               ' 'http://speedtest-xg-tokyo.glbb.ne.jp'
	speed_test '20637' 'SG, 新加坡市 (OVH Cloud)      ' 'http://speedtest-sgp.apac-tools.ovh'
	### https://www.speedtest.net/reports/australia/#fixed
	### https://ispspeedindex.netflix.com/country/australia/
	speed_test '20638' 'AU, 雪梨 (OVH Cloud)          ' 'http://speedtest-syd.apac-tools.ovh'
	speed_test '24383' 'UK, 倫敦 (GTT.net)            ' 'http://lon.speedtest.gtt.net'
	speed_test '9913' 'NL, 阿姆斯特丹 (fdcservers)   ' 'http://lg.ams2-c.fdcservers.net'
	speed_test '24386' 'FR, 巴黎 (GTT.net)            ' 'http://par.speedtest.gtt.net'
	speed_test '24380' 'DE, 法蘭克福 (GTT.net)        ' 'http://fra.speedtest.gtt.net'
	speed_test '24389' 'CH, 蘇黎世 (GTT.net)          ' 'http://zrh.speedtest.gtt.net'
	speed_test '24388' 'SE, 斯德哥爾摩 (GTT.net)      ' 'http://sto.speedtest.gtt.net'
	speed_test '24384' 'ES, 馬德里 (GTT.net)          ' 'http://mad.speedtest.gtt.net'
	speed_test '24385' 'IT, 米蘭 (GTT.net)            ' 'http://mil.speedtest.gtt.net'
	speed_test '6070' 'AT, 維也納 (fdcservers)       ' 'http://lg.vie-c.fdcservers.net'
	speed_test '6386' 'RU, 莫斯科 (MegaFon)          ' 'http://speedtest-stf.megafon.ru'
	 
	rm -rf speedtest.py
}

print_speedtest_asia() {
	echo "" | tee -a $log
	echostyle "### {亞太地區}網路速度測試"
	echo "" | tee -a $log
	printf "%-34s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	### https://ispspeedindex.netflix.com/country/taiwan/
	speed_test '3967' 'TW, 臺北市 (是方電訊)         ' 'http://tpv3-1.speedtest.idv.tw'
	speed_test '18840' 'TW, 臺北市 (BGP Network)      ' 'http://speedtest.tw.bgp.net'
	### https://www.speedtest.net/reports/hong-kong/
	### https://ispspeedindex.netflix.com/country/hong-kong/
	speed_test '24375' 'HK, 上環 (GTT.net)            ' 'http://hon.speedtest.gtt.net'
	speed_test '13538' 'HK, 葵涌 (香港移動通訊)       ' 'http://csl.hkspeedtest.com'
	speed_test '27377' 'CN, 北京市 (中國電信 5G)      ' 'http://speedtest25.jillbanging.com'
	speed_test '24447' 'CN, 上海市 (中國聯通 5G)      ' 'http://5g.shunicomtest.com'
	### https://ispspeedindex.netflix.com/country/singapore/
	speed_test '13623' 'SG, 淡賓尼 (SingTel)          ' 'http://speedtest.singnet.com.sg'
	speed_test '20637' 'SG, 新加坡市 (OVH Cloud)      ' 'http://speedtest-sgp.apac-tools.ovh'
	### https://ispspeedindex.netflix.com/country/japan/
	speed_test '20976' 'JP, 東京 (GLBB)               ' 'http://speedtest-xg-tokyo.glbb.ne.jp'
	speed_test '24333' 'JP, 東京 (Rakuten Mobile)     ' 'http://ookla.mbspeed.net'
	### https://ispspeedindex.netflix.com/country/south-korea/
	speed_test '6527' 'KR, 首爾 (kdatacenter)        ' 'http://koreatest.kdatacenter.com'
	### speed_test '6842' 'KR, 金海 (Korea Telecom)      ' 'http://speedtest.randomco.ml'
	### https://ispspeedindex.netflix.com/country/india/
	speed_test '8978' 'IN, 孟買 (Spectra)            ' 'http://mumbaispeedtest.spectra.co'
	speed_test '8978' 'IN, 新德里 (Airtel)           ' 'http://speedtestggn1.airtel.in'
	### speed_test '10204' 'IN, 班加羅爾 (Spectra)        ' 'http://bangalorespeedtest.spectra.co'
	 
	rm -rf speedtest.py
}

print_speedtest_europe() {
	echo "" | tee -a $log
	echostyle "### {歐洲}網路速度測試"
	echo "" | tee -a $log
	printf "%-34s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	### https://www.broadbandspeedchecker.co.uk/isp-directory/Ireland.html
	### https://ispspeedindex.netflix.com/country/ireland/
	speed_test '1041' 'IE, 都柏林 (Digiweb)          ' 'http://speedtest.digiweb.ie'
	### speed_test '1756' 'IE, 都柏林 (Vodafone)         ' 'http://speedtest.vodafone.ie'
	### https://www.speedtest.net/reports/united-kingdom/#fixed
	### https://ispspeedindex.netflix.com/country/uk/
	speed_test '4078' 'UK, 倫敦 (Vorboss)            ' 'http://if0-0.speedtest.lon.vorboss.net'
	### speed_test '23968' 'UK, 曼徹斯特 (Vodafone)       ' 'http://speedtest-manchester.vodafone.co.uk'
	speed_test '24387' 'UK, 斯勞 (GTT.net)            ' 'http://slo.speedtest.gtt.net'
	### https://ispspeedindex.netflix.com/country/netherlands/
	speed_test '3386' 'NL, 阿姆斯特丹 (NFOrce)       ' 'http://mirror.nforce.com'
	### speed_test '13218' 'NL, 阿姆斯特丹 (XS4ALL)       ' 'http://speedtest.xs4all.nl'
	### speed_test '11433' 'NL, Middelburg (DELTA)        ' 'http://speedtest.zeelandnet.nl'
	### https://www.speedtest.net/reports/germany/
	### https://ispspeedindex.netflix.com/country/germany/
	speed_test '3585' 'DE, 法蘭克福 (LeaseWeb)       ' 'http://speedtest.fra1.de.leaseweb.net'
	### speed_test '3865' 'DE, 賓茲 (KABEL)              ' 'http://speedtest1.binz-kabel.de'
	### https://ispspeedindex.netflix.com/country/switzerland/
	### speed_test '23969' 'CH, 蘇黎世 (Sunrise)          ' 'http://pzur01speedtst02.sunrise.ch'
	speed_test '24381' 'CH, 日內瓦 (GTT.net)          ' 'http://gva.speedtest.gtt.net'
	### https://ispspeedindex.netflix.com/country/denmark/
	speed_test '14902' 'DK, 哥本哈根 (丹麥有線電視)   ' 'http://speedtest.danskkabeltv.dk'
	### speed_test '4435' 'DK, Skanderborg (Waoo)        ' 'http://speedtest01.waoo.dk'
	### https://ispspeedindex.netflix.com/country/sweden/
	speed_test '26852' 'SE, 斯德哥爾摩 (SUNET)        ' 'http://fd.sunet.se'
	### speed_test '5235' 'SE, Umea (A3)                 ' 'http://ookla-umea.a3.se'
	### https://ispspeedindex.netflix.com/country/norway/
	speed_test '13544' 'NO, 奧斯陸 (Altibox)          ' 'http://osl-ulv-speedtest1.altibox.net'
	### speed_test '13544' 'NO, 里爾哈默 (Eidsiva)        ' 'http://speedtest.eidsiva.net'
	### https://ispspeedindex.netflix.com/country/france/
	speed_test '12746' 'FR, 巴黎 (SFR)                ' 'http://speedtest.mire.sfr.net'
	### speed_test '24394' 'FR, 里昂 (ORANGE)             ' 'http://lyon3.speedtest.orange.fr'
	### https://ispspeedindex.netflix.com/country/spain/
	speed_test '14979' 'ES, 馬德里 (Orange)           ' 'http://testvelocidad1.orange.es'
	### speed_test '15111' 'ES, 巴塞隆納 (Orange)         ' 'http://testvelocidad2.orange.es'
	### https://ispspeedindex.netflix.com/country/portugal/
	speed_test '1249' 'PT, 里斯本 (NOS)              ' 'http://a.lisboa.speedtest.net.zon.pt'
	### speed_test '10183' 'PT, 帕爾梅拉 (NOWO)           ' 'http://ookla2.nowo.pt'
	### https://ispspeedindex.netflix.com/country/italy/
	speed_test '3997' 'IT, 米蘭 (EOLO)               ' 'http://test.eolo.it'
	### speed_test '3243' 'IT, 羅馬 (Telecom Italia)     ' 'http://speedtestrm1.telecomitalia.it'
	### https://ispspeedindex.netflix.com/country/austria/
	speed_test '12390' 'AT, 維也納 (A1)               ' 'http://speedtest.a1.net'
	### speed_test '6070' 'AT, 林茲 (LIWEST)             ' 'http://speedcheck.liwest.at'
	### https://ispspeedindex.netflix.com/country/poland/
	speed_test '4166' 'PL, 華沙 (Orange)             ' 'http://war-o2.speedtest.orange.pl'
	### speed_test '18870' 'PL, 斯塞新 (Orange)           ' 'http://szc-o1.speedtest.orange.pl'
	### https://ispspeedindex.netflix.com/country/romania/
	speed_test '7758' 'RO, 布加勒斯特 (AKTA)         ' 'http://speedtest.akta.ro'
	### speed_test '15004' 'RO, 布加勒斯特 (UPC)          ' 'http://ro-buh01a-speedtestnet01.upcnet.ro'
	### https://www.speedtest.net/reports/russia/
	speed_test '6386' 'RU, 莫斯科 (MegaFon)          ' 'http://speedtest-stf.megafon.ru'
	speed_test '4247' 'RU, 聖彼得堡 (MTS)            ' 'http://speedtest-it.spb.mts.ru'
	### speed_test '17036' 'RU, 車里雅賓斯克 (MegaFon)    ' 'http://chelyabinsk.speedtest-uf.megafon.ru'
	### https://ispspeedindex.netflix.com/country/greece/
	### speed_test '4201' 'GR, 雅典 (OTE)                ' 'http://speedtest.otenet.gr'
	speed_test '19078' 'GR, 雅典 (Vodafone)           ' 'http://ooklaspeedtest.vodafone.gr'
	### https://ispspeedindex.netflix.com/country/turkey/
	speed_test '20984' 'TR, 伊斯坦堡 (Turksat Kablo)  ' 'http://st-atakoy-1.turksatkablo.com.tr'
	### speed_test '24520' 'TR, 伊茲密爾 (Turkcell)       ' 'http://brnv01.hizinitestet.com'
	 
	rm -rf speedtest.py
}

print_speedtest_usa() {
	echo "" | tee -a $log
	echostyle "### {美國}網路速度測試"
	echo "" | tee -a $log
	printf "%-36s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	### https://www.speedtest.net/reports/united-states/2018/#fixed
	### https://ispspeedindex.netflix.com/country/us/
	speed_test '19230' 'CA, Los Angeles (Hivelocity)  ' 'http://speedtest.lax.hivelocity.net'
	speed_test '15786' 'CA, San Jose (Sprint)         ' 'http://ookla1.snjsca.sprintadp.net'
	speed_test '16615' 'CA, San Diego (Cox)           ' 'http://speedtest.rd.sd.cox.net'
	speed_test '2407' 'OR, Medford (Spectrum)        ' 'http://spt01mdfdor.mdfd.or.charter.com'
	speed_test '14232' 'WA, Seattle (Frontier)        ' 'http://seattle-speedtest.glb.frontiernet.net'
	speed_test '27746' 'AZ, Phoenix (Xiber LLC)       ' 'http://speedtest.phoenix.xiber.net'
	speed_test '16622' 'NV, Las Vegas (Cox)           ' 'http://speedtest.rd.lv.cox.net'
	speed_test '16968' 'CO, Centennial (Spectrum)     ' 'http://speedtest.peakview.rr.com'
	speed_test '22288' 'TX, Dallas (Hivelocity)       ' 'http://speedtest.dal.hivelocity.net'
	speed_test '16623' 'KS, Wichita (Cox)             ' 'http://speedtest.rd.ks.cox.net'
	speed_test '21566' 'MO, Kansas City (Xiber LLC)   ' 'http://speedtest.ohiordc.rr.com'
	speed_test '16969' 'OH, Columbus (Spectrum)       ' 'http://speedtest.ohiordc.rr.com'
	speed_test '24151' 'IL, Chicago (Verizon)         ' 'http://ilhhp1.speed.vzwnet.com'
	speed_test '16973' 'MI, Livonia (Spectrum)        ' 'http://detrp-speedtest-01.noc.bhn.net'
	speed_test '18956' 'NY, New York (Hivelocity)     ' 'http://speedtest.nyc.hivelocity.net'
	speed_test '17383' 'VA, Ashburn (Windstream)      ' 'http://ashburn02.speedtest.windstream.net'
	speed_test '16970' 'NC, Durham (Spectrum)         ' 'http://speedtest.southeast.rr.com'
	speed_test '16611' 'GA, Atlanta (Cox)             ' 'http://speedtest.rd.at.cox.net'
	speed_test '14237' 'FL, Tampa (Spectrum)          ' 'http://tampp-speedtest-01.noc.bhn.net'
	speed_test '20229' 'Washington, DC (Xiber LLC)    ' 'http://speedtest.washington-dc.xiber.net'
	 
	rm -rf speedtest.py
}

print_speedtest_taiwan() {
	echo "" | tee -a $log
	echostyle "### {中華民國}網路速度測試"
	echo "" | tee -a $log
	printf "%-34s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	### https://ispspeedindex.netflix.com/country/taiwan/
	speed_test '18445' '臺北市 (中華電信)             ' 'http://tp1.chtm.hinet.net'
	speed_test '3967' '臺北市 (是方電訊)             ' 'http://tpv3-1.speedtest.idv.tw'
	speed_test '18840' '臺北市 (BGP Network)          ' 'http://speedtest.tw.bgp.net'
	speed_test '13506' '臺北市 (臺灣智慧光網)         ' 'http://speedtest.taifo.com.tw'
	speed_test '24429' '臺北市 (中嘉寬頻)             ' 'http://tp-speedtest.bbtv.tw'
	speed_test '23811' '臺北市 (臺灣大寬頻)           ' 'http://tp-speedtest-1.twmbroadband.net'
	speed_test '2133' '臺北市 (臺灣固網)             ' 'http://spttp1.tfn.net.tw'
	speed_test '2181' '臺北市 (凱擘大寬頻)           ' 'http://ntp-sptest.kbro.com.tw'
	speed_test '18448' '臺北市 (和宇寬頻)             ' 'http://tpspt1.kgex.com.tw'
	speed_test '7429' '臺北市 (北都數位)             ' 'http://speedtest1.taipeinet.com.tw'
	speed_test '18453' '桃園市中壢區 (和宇寬頻)       ' 'http://tyspt1.kgex.com.tw'
	speed_test '18453' '桃園市 (中華電信)             ' 'http://ty1.chtm.hinet.net'
	speed_test '4938' '桃園市 (是方電訊)             ' 'http://tyv3-1.speedtest.idv.tw'
	speed_test '24462' '桃園市 (中嘉寬頻)             ' 'http://ty-speedtest.bbtv.tw'
	speed_test '18456' '臺中市 (中華電信)             ' 'http://tc1.chtm.hinet.net'
	speed_test '4940' '臺中市 (是方電訊)             ' 'http://tcv3-1.speedtest.idv.tw'
	speed_test '12000' '臺中市 (台灣寬頻 TBC)         ' 'http://custom.tbcnet.net.tw'
	speed_test '7076' '臺中市 (逢甲大學)             ' 'http://spt.oms.fcu.edu.tw'
	speed_test '18458' '高雄市 (中華電信)             ' 'http://kh1.chtm.hinet.net'
	speed_test '4941' '高雄市 (是方電訊)             ' 'http://khv3-1.speedtest.idv.tw'
	speed_test '17205' '基隆市 (遠傳電信)             ' 'http://fetkl1.seed.net.tw'
	speed_test '4948' '花蓮市 (是方電訊)             ' 'http://hlv3-1.speedtest.idv.tw'
	speed_test '18480' '臺東市 (是方電訊)             ' 'http://ttv3-1.speedtest.idv.tw'
	 
	rm -rf speedtest.py
}

print_speedtest_china() {
	echo "" | tee -a $log
	echostyle "### {中國大陸}網路速度測試"
	echo "" | tee -a $log
	printf "%-34s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	speed_test '27377' '華北, 北京市 (中國電信 5G)    ' 'http://speedtest25.jillbanging.com'
	speed_test '27154' '華北, 天津市 (中國聯通 5G)    ' 'http://speedtest3.online.tj.cn'
	speed_test '24447' '華東, 上海市 (中國聯通 5G)    ' 'http://5g.shunicomtest.com'
	speed_test '27594' '華東, 廣州市 (中國電信)       ' 'http://www.gdspeedtest.com'
	speed_test '4515' '華東, 深圳市 (中國聯通)       ' 'http://speedtest3.gd.chinamobile.com'
	speed_test '26331' '華中, 鄭州市 (中國移動 5G)    ' 'http://5ghenan.ha.chinamobile.com'
	speed_test '17145' '華中, 合肥市 (中國電信 5G)    ' 'http://speedtest1.ah163.com'
	speed_test '27539' '西部, 昆明市 (中國電信 5G)    ' 'http://speedtest101.jillbanging.com'
	speed_test '26380' '西北, 西安市 (中國移動)       ' 'http://speedtest1.sn.chinamobile.com'
	speed_test '2461' '西南, 成都市 (中國移動)       ' 'http://speedtest1.wangjia.net'
	 
	rm -rf speedtest.py
}

print_speedtest_singapore() {
	echo "" | tee -a $log
	echostyle "### {新加坡}網路速度測試"
	echo "" | tee -a $log
	printf "%-34s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	### https://www.speedtest.net/reports/singapore/
	### https://ispspeedindex.netflix.com/country/singapore/
	speed_test '2054' '新加坡市 (ViewQwest)          ' 'http://speedtest10.vqbn.com'
	speed_test '5935' '新加坡市 (MyRepublic)         ' 'http://speedtest.myrepublic.com.sg'
	speed_test '7556' '新加坡市 (FirstMedia)         ' 'http://sg-speedtest.fast.net.id'
	speed_test '20637' '新加坡市 (OVH Cloud)          ' 'http://speedtest-sgp.apac-tools.ovh'
	speed_test '13623' '淡賓尼 (SingTel)              ' 'http://speedtest.singnet.com.sg'
	speed_test '4235' '芽籠區 (StarHub)              ' 'http://co2speedtest1.starhub.com'
	speed_test '367' '加冷區 (NewMedia)             ' 'http://www.speedtest.com.sg'
	 
	rm -rf speedtest.py
}

print_speedtest_dryrun() {
	echo "" | tee -a $log
	echostyle "### 試驗運行"
	echo "" | tee -a $log
	printf "%-34s%-17s%-17s%-7s\n" " Location" "Upload" "Download" "Ping" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
	speed_test '19230' 'CA, Los Angeles (Hivelocity)  ' 'http://speedtest.lax.hivelocity.net'
	speed_test '5861' 'CA, Los Angeles (WebNX)       ' 'http://lax1a-speedtest.webnx.com'
	 
	rm -rf speedtest.py
}

geekbench4() {
	echo "" | tee -a $log
	echostyle "### 執行 {Geekbench v4} CPU 性能測試，請稍待幾分鐘..."

	GEEKBENCH_PATH=$HOME/geekbench
	mkdir -p $GEEKBENCH_PATH
	curl -s http://cdn.geekbench.com/Geekbench-4.3.4-Linux.tar.gz  | tar xz --strip-components=1 -C $GEEKBENCH_PATH
	GEEKBENCH_TEST=$($GEEKBENCH_PATH/geekbench4 | grep "https://browser")
	GEEKBENCH_URL=$(echo -e $GEEKBENCH_TEST | head -1)
	GEEKBENCH_URL_CLAIM=$(echo $GEEKBENCH_URL | awk '{ print $2 }')
	GEEKBENCH_URL=$(echo $GEEKBENCH_URL | awk '{ print $1 }')
	sleep 10
	GEEKBENCH_SCORES=$(curl -s $GEEKBENCH_URL | grep "class='score' rowspan")
	GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
	GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(<|>)" '{ print $7 }')
	
	if [[ $GEEKBENCH_SCORES_SINGLE -le 1200 ]]; then
		grank="(C | 悲劇)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 1500 && $GEEKBENCH_SCORES_SINGLE -le 2300 ]]; then
		grank="(C+ | 有點慘)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 1700 && $GEEKBENCH_SCORES_SINGLE -le 2300 ]]; then
		grank="(B | 普普通通)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 2300 && $GEEKBENCH_SCORES_SINGLE -le 3000 ]]; then
		grank="(B+ | 良好)"
	elif [[ $GEEKBENCH_SCORES_SINGLE -ge 3000 && $GEEKBENCH_SCORES_SINGLE -le 4000 ]]; then
		grank="(A | 好棒棒)"
	else
		grank="(A+ | 叫你第一名)"
	fi
	
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echo "" | tee -a $log
	echostyle "### Geekbench v4 CPU 性能測試結果:"
	echo "" | tee -a $log
	echo -e "  Single Core : $GEEKBENCH_SCORES_SINGLE  $grank" | tee -a $log
	echo -e "   Multi Core : $GEEKBENCH_SCORES_MULTI" | tee -a $log
	[ ! -z "$GEEKBENCH_URL_CLAIM" ] && echo -e "$GEEKBENCH_URL_CLAIM" > geekbench4_claim.url 2> /dev/null
	echo "" | tee -a $log
	echo -e " Cooling down..."
	sleep 9
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echo -e " Ready to continue..."
	sleep 3
	echo -ne "\e[1A"; echo -ne "\033[0K\r"
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

power_time() {

	result=$(smartctl -a $(result=$(cat /proc/mounts) && echo $(echo "$result" | awk '/data=ordered/{print $1}') | awk '{print $1}') 2>&1) && power_time=$(echo "$result" | awk '/Power_On/{print $10}') && echo "$power_time"
}

install_smart() {
	# install smartctl
	if  [ ! -e '/usr/sbin/smartctl' ]; then
		echo "Installing Smartctl ..."
	    if [ "${release}" == "centos" ]; then
	    	yum update > /dev/null 2>&1
	        yum install -y smartmontools > /dev/null 2>&1
	    else
	    	apt-get update > /dev/null 2>&1
	        apt-get install -y smartmontools > /dev/null 2>&1
	    fi      
	fi
}

ip_info(){
	# use jq tool
	result=$(curl -s 'http://ip-api.com/json')
	country=$(echo $result | jq '.country' | sed 's/\"//g')
	city=$(echo $result | jq '.city' | sed 's/\"//g')
	isp=$(echo $result | jq '.isp' | sed 's/\"//g')
	as_tmp=$(echo $result | jq '.as' | sed 's/\"//g')
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(echo $result | jq '.org' | sed 's/\"//g')
	countryCode=$(echo $result | jq '.countryCode' | sed 's/\"//g')
	region=$(echo $result | jq '.regionName' | sed 's/\"//g')
	if [ -z "$city" ]; then
		city=${region}
	fi

	echo -e " ASN & ISP     : $asn, $isp" | tee -a $log
	echo -e " 組織          : $org" | tee -a $log
	echo -e " 伺服器所在地  : $city, $country / $countryCode" | tee -a $log
	echo -e " 地區          : $region" | tee -a $log
}

ip_info2(){
	# no jq
	country=$(curl -s https://ipapi.co/country_name/)
	city=$(curl -s https://ipapi.co/city/)
	asn=$(curl -s https://ipapi.co/asn/)
	org=$(curl -s https://ipapi.co/org/)
	countryCode=$(curl -s https://ipapi.co/country/)
	region=$(curl -s https://ipapi.co/region/)

	echo -e " ASN & ISP     : $asn, $isp" | tee -a $log
	echo -e " 組織          : $org" | tee -a $log
	echo -e " 伺服器所在地  : $city, $country / $countryCode" | tee -a $log
	echo -e " 地區          : $region" | tee -a $log
}

ip_info3(){
	# use python tool
	country=$(python ip_info.py country)
	city=$(python ip_info.py city)
	isp=$(python ip_info.py isp)
	as_tmp=$(python ip_info.py as)
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(python ip_info.py org)
	countryCode=$(python ip_info.py countryCode)
	region=$(python ip_info.py regionName)

	echo -e " ASN & ISP     : $asn, $isp" | tee -a $log
	echo -e " 組織          : $org" | tee -a $log
	echo -e " 伺服器所在地  : $city, $country / $countryCode" | tee -a $log
	echo -e " 地區          : $region" | tee -a $log

	rm -rf ip_info.py
}

ip_info4(){
	ip_date=$(curl -4 -s http://api.ip.la/en?json)
	echo $ip_date > ip_json.json
	isp=$(python2 tools.py geoip isp)
	as_tmp=$(python2 tools.py geoip as)
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(python2 tools.py geoip org)
	if [ -z "ip_date" ]; then
		echo $ip_date
		echo "hala"
		country=$(python2 tools.py ipip country_name)
		city=$(python2 tools.py ipip city)
		countryCode=$(python2 tools.py ipip country_code)
		region=$(python2 tools.py ipip province)
	else
		country=$(python2 tools.py geoip country)
		city=$(python2 tools.py geoip city)
		countryCode=$(python2 tools.py geoip countryCode)
		region=$(python2 tools.py geoip regionName)	
	fi
	if [ -z "$city" ]; then
		city=${region}
	fi

	echo -e " ASN & ISP     : $asn, $isp" | tee -a $log
	echo -e " 組織          : $org" | tee -a $log
	echo -e " 伺服器所在地  : $city, $country / $countryCode" | tee -a $log
	echo -e " 地區          : $region" | tee -a $log

	rm -rf tools.py
	rm -rf ip_json.json
}

virt_check(){
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi

	virtualx=$(dmesg) 2>/dev/null
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated"
	fi
}

power_time_check(){
	echo -ne " Power time of disk   : "
	install_smart
	ptime=$(power_time)
	echo -e "$ptime Hours"
}

freedisk() {
	# check free space
	#spacename=$( df -m . | awk 'NR==2 {print $1}' )
	#spacenamelength=$(echo ${spacename} | awk '{print length($0)}')
	#if [[ $spacenamelength -gt 20 ]]; then
   	#	freespace=$( df -m . | awk 'NR==3 {print $3}' )
	#else
	#	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	#fi
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace == "" ]]; then
		$freespace=$( df -m . | awk 'NR==3 {print $3}' )
	fi
	if [[ $freespace -gt 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -gt 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -gt 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -gt 128 ]]; then
		printf "%s" $((128*2))
	else
		printf "1"
	fi
}

print_system_info() {
	echo -e " OS           : $opsy ($lbit Bit)" | tee -a $log
	echo -e " Virt/Kernel  : $virtual / $kern" | tee -a $log
	echo -e " CPU Model    : $cname" | tee -a $log
	echo -e " CPU Cores    : $cores @ $freq MHz $arch $corescache Cache" | tee -a $log
	echo -e " CPU Flags    : $cpu_aes & $cpu_virt" | tee -a $log
	echo -e " Load Average : $load" | tee -a $log
	echo -e " Total Space  : $hdd ($hddused ~$hddfree used)" | tee -a $log
	echo -e " Total RAM    : $uram MB / $tram MB ($bram MB Buff)" | tee -a $log
	echo -e " Total SWAP   : $uswap MB / $swap MB" | tee -a $log
	echo -e " Uptime       : $up" | tee -a $log
	#echo -e " TCP CC       : $tcpctrl" | tee -a $log
	printf "%-75s\n" "-" | sed 's/\s/-/g' | tee -a $log
}

get_system_info() {
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cpu_aes=$(cat /proc/cpuinfo | grep aes)
	[[ -z "$cpu_aes" ]] && cpu_aes="AES-NI Disabled" || cpu_aes="AES-NI Enabled"
	cpu_virt=$(cat /proc/cpuinfo | grep 'vmx\|svm')
	[[ -z "$cpu_virt" ]] && cpu_virt="VM-x/AMD-V Disabled" || cpu_virt="VM-x/AMD-V Enabled"
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	bram=$( free -m | awk '/Mem/ {print $6}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d:%d\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )
	#ipv6=$( wget -qO- -t1 -T2 ipv6.icanhazip.com )
	#disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
	#disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
	#disk_total_size=$( calc_disk ${disk_size1[@]} )
	#disk_used_size=$( calc_disk ${disk_size2[@]} )
	hdd=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs -t swap --total -h | grep total | awk '{ print $2 }')
	hddused=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs -t swap --total -h | grep total | awk '{ print $3 }')
	hddfree=$(df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs -t swap --total -h | grep total | awk '{ print $5 }')
	#tcp congestion control
	#tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )

	#tmp=$(python2 tools.py disk 0)
	#disk_total_size=$(echo $tmp | sed s/G//)
	#tmp=$(python2 tools.py disk 1)
	#disk_used_size=$(echo $tmp | sed s/G//)

	virt_check
}

write_test() {
    (LANG=C dd if=/dev/zero of=test_file_$$ bs=512K count=$1 conv=fdatasync && rm -f test_file_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

averageio() {
	ioraw1=$( echo $1 | awk 'NR==1 {print $1}' )
		[ "$(echo $1 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
	ioraw2=$( echo $2 | awk 'NR==1 {print $1}' )
		[ "$(echo $2 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
	ioraw3=$( echo $3 | awk 'NR==1 {print $1}' )
		[ "$(echo $3 | awk 'NR==1 {print $2}')" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
	ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
	ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
	printf "%s" "$ioavg"
}

cpubench() {
	if hash $1 2>$NULL; then
		io=$( ( dd if=/dev/zero bs=512K count=$2 | $1 ) 2>&1 | grep 'copied' | awk -F, '{io=$NF} END {print io}' )
		if [[ $io != *"."* ]]; then
			printf "%4i %s" "${io% *}" "${io##* }"
		else
			printf "%4i.%s" "${io%.*}" "${io#*.}"
		fi
	else
		printf " %s not found on system." "$1"
	fi
}

iotest() {
	echostyle "### IO 測試"
	echo "" | tee -a $log

	# start testing
	writemb=$(freedisk)
	if [[ $writemb -gt 512 ]]; then
		writemb_size="$(( writemb / 2 / 2 ))MB"
		writemb_cpu="$(( writemb / 2 ))"
	else
		writemb_size="$writemb"MB
		writemb_cpu=$writemb
	fi

	# CPU Speed test
	echostyle "## CPU 速度:"
	echo "    bzip2     :$( cpubench bzip2 $writemb_cpu )" | tee -a $log 
	echo "   sha256     :$( cpubench sha256sum $writemb_cpu )" | tee -a $log
	echo "   md5sum     :$( cpubench md5sum $writemb_cpu )" | tee -a $log
	echo "" | tee -a $log

	# RAM Speed test
	# set ram allocation for mount
	tram_mb="$( free -m | grep Mem | awk 'NR=1 {print $2}' )"
	if [[ tram_mb -gt 1900 ]]; then
		sbram=1024M
		sbcount=2048
	else
		sbram=$(( tram_mb / 2 ))M
		sbcount=$tram_mb
	fi
	[[ -d $benchram ]] || mkdir $benchram
	mount -t tmpfs -o size=$sbram tmpfs $benchram/
	echostyle "## 記憶體速度:"
	iow1=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior1=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	iow2=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior2=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	iow3=$( ( dd if=/dev/zero of=$benchram/zero bs=512K count=$sbcount ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	ior3=$( ( dd if=$benchram/zero of=$NULL bs=512K count=$sbcount; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo "   Avg. write : $(averageio "$iow1" "$iow2" "$iow3") MB/s" | tee -a $log
	echo "   Avg. read  : $(averageio "$ior1" "$ior2" "$ior3") MB/s" | tee -a $log
	rm $benchram/zero
	umount $benchram
	rm -rf $benchram
	echo "" | tee -a $log
	
	# Disk test
	#echostyle "## 磁碟速度:"
	#if [[ $writemb != "1" ]]; then
	#	io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	#	echo "   I/O Speed  :$io" | tee -a $log

	#	io=$( ( dd bs=512K count=$writemb if=/dev/zero of=test oflag=direct; rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	#	echo "   I/O Direct :$io" | tee -a $log
	#else
	#	echo "   Not enough space to test." | tee -a $log
	#fi
	#echo "" | tee -a $log
}


write_io() {
	writemb=$(freedisk)
	writemb_size="$(( writemb / 2 ))MB"
	if [[ $writemb_size == "1024MB" ]]; then
		writemb_size="1.0GB"
	fi

	if [[ $writemb != "1" ]]; then
		echostyle "## 磁碟寫入速度:"
		echo -n "   1st run    : " | tee -a $log
		io1=$( write_test $writemb )
		echo -e "$io1" | tee -a $log
		echo -n "   2dn run    : " | tee -a $log
		io2=$( write_test $writemb )
		echo -e "$io2" | tee -a $log
		echo -n "   3rd run    : " | tee -a $log
		io3=$( write_test $writemb )
		echo -e "$io3" | tee -a $log
		ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
		[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
		ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
		[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
		ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
		[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
		ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
		echo -e "   -----------------------" | tee -a $log
		echo -e "   Average    : $ioavg MB/s" | tee -a $log
	else
		echo -e " Not enough space!"
	fi
}

# https://github.com/masonr/yet-another-bench-script
function disk_test () {
	I=0
	DISK_WRITE_TEST_RES=()
	DISK_READ_TEST_RES=()
	DISK_WRITE_TEST_AVG=0
	DISK_READ_TEST_AVG=0
	DATE=`date -Iseconds | sed -e "s/:/_/g"`
	OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	while [ $I -lt 3 ]
	do
		DISK_WRITE_TEST=$(dd if=/dev/zero of=$DISK_PATH/$DATE.test bs=64k count=16k oflag=direct |& grep copied | awk '{ print $(NF-1) " " $(NF)}')
		VAL=$(echo $DISK_WRITE_TEST | cut -d " " -f 1)
		[[ "$DISK_WRITE_TEST" == *"GB"* ]] && VAL=$(awk -v a="$VAL" 'BEGIN { print a * 1000 }')
		DISK_WRITE_TEST_RES+=( "$VAL" )
		DISK_WRITE_TEST_AVG=$(awk -v a="$DISK_WRITE_TEST_AVG" -v b="$VAL" 'BEGIN { print a + b }')

		DISK_READ_TEST=$($DISK_PATH/ioping -R -L -D -B -w 6 . | awk '{ print $4 / 1000 / 1000 }')
		DISK_READ_TEST_RES+=( "$DISK_READ_TEST" )
		DISK_READ_TEST_AVG=$(awk -v a="$DISK_READ_TEST_AVG" -v b="$DISK_READ_TEST" 'BEGIN { print a + b }')

		I=$(( $I + 1 ))
	done	
	DISK_WRITE_TEST_AVG=$(awk -v a="$DISK_WRITE_TEST_AVG" 'BEGIN { print a / 3 }')
	DISK_READ_TEST_AVG=$(awk -v a="$DISK_READ_TEST_AVG" 'BEGIN { print a / 3 }')
}

ioping() {
	echo "" | tee -a $log
	echostyle "### 執行 {ioping} 磁碟性能測試，請稍待幾分鐘..."

	DISK_PATH=$HOME/disk
	mkdir -p $DISK_PATH
	curl -s https://raw.githubusercontent.com/masonr/yet-another-bench-script/master/ioping -o $DISK_PATH/ioping
	chmod +x $DISK_PATH/ioping

	disk_test

	if [ $(echo $DISK_WRITE_TEST_AVG | cut -d "." -f 1) -ge 1000 ]; then
		DISK_WRITE_TEST_AVG=$(awk -v a="$DISK_WRITE_TEST_AVG" 'BEGIN { print a / 1000 }')
		DISK_WRITE_TEST_UNIT="GB/s"
	else
		DISK_WRITE_TEST_UNIT="MB/s"
	fi
	if [ $(echo $DISK_READ_TEST_AVG | cut -d "." -f 1) -ge 1000 ]; then
		DISK_READ_TEST_AVG=$(awk -v a="$DISK_READ_TEST_AVG" 'BEGIN { print a / 1000 }')
		DISK_READ_TEST_UNIT="GB/s"
	else
		DISK_READ_TEST_UNIT="MB/s"
	fi

	echo -ne "\e[1A"; echo -ne "\033[0K\r"
	echostyle "## {ioping}磁碟寫入速度:" | tee -a $log
	echo -e "" | tee -a $log
	echo -e "   1st run    : ${DISK_WRITE_TEST_RES[0]} MB/s" | tee -a $log
	echo -e "   2dn run    : ${DISK_WRITE_TEST_RES[1]} MB/s" | tee -a $log
	echo -e "   3rd run    : ${DISK_WRITE_TEST_RES[2]} MB/s" | tee -a $log
	echo -e "   -----------------------" | tee -a $log
	echo -e "   Average    : ${DISK_WRITE_TEST_AVG} ${DISK_WRITE_TEST_UNIT}" | tee -a $log
	echo -e "" | tee -a $log
	echostyle "## {ioping}磁碟讀取速度:" | tee -a $log
	echo -e "" | tee -a $log
	echo -e "   1st run    : ${DISK_READ_TEST_RES[0]} MB/s" | tee -a $log
	echo -e "   2dn run    : ${DISK_READ_TEST_RES[1]} MB/s" | tee -a $log
	echo -e "   3rd run    : ${DISK_READ_TEST_RES[2]} MB/s" | tee -a $log
	echo -e "   -----------------------" | tee -a $log
	echo -e "   Average    : ${DISK_READ_TEST_AVG} ${DISK_READ_TEST_UNIT}" | tee -a $log
	echo -e "" | tee -a $log
	rm -rf $DISK_PATH;
	rm -f speedtest.sh
}

print_end_time() {
	echo "" | tee -a $log
	utc_time=$(date -u '+%F %T')
	echo " Timestamp      : $utc_time UTC" | tee -a $log
	end=$(date +%s) 
	time=$(( $end - $start ))
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne " 測試耗費時間   : ${min} min ${sec} sec"
	else
		echo -ne " 測試耗費時間   : ${time} sec"
	fi
	#echo -ne "\n 目前時間 : "
	#echo $(date +%Y-%m-%d" "%H:%M:%S)
	printf '\n'
	#echo " 測試完成!"
	echo " 紀錄檔案位置   : $log"
	echo "" | tee -a $log
}

print_intro() {
	printf "%-75s\n" "-" | sed 's/\s/-/g'
	printf ' Speedtest Monster v.1.4.5 2019-10-13 \n' | tee -a $log
	printf " Region: %s  https://bench.monster/speedtest.html\n" $region_name | tee -a $log
	printf " Usage : curl -LsO bench.monster/speedtest.sh; bash speedtest.sh -%s\n" $region_name | tee -a $log
	echo "" | tee -a $log
}

sharetest() {
	echostyle "### 分享測試結果:"
	echo ""
	echo " - $result_speed"
	log_preupload
	case $1 in
	'ubuntu')
		share_link=$( curl -v --data-urlencode "content@$log_up" -d "poster=speedtest.sh" -d "syntax=text" "https://paste.ubuntu.com" 2>&1 | \
			grep "Location" | awk '{print "https://paste.ubuntu.com"$3}' );;
	'haste' )
		share_link=$( curl -X POST -s -d "$(cat $log)" https://hastebin.com/documents | awk -F '"' '{print "https://hastebin.com/"$4}' );;
	'clbin' )
		share_link=$( curl -sF 'clbin=<-' https://clbin.com < $log );;
	esac

	# print result info
	echo " - $GEEKBENCH_URL" | tee -a $log
	echo " - $share_link"
	echo ""
	rm -f $log_up

}

log_preupload() {
	log_up="$HOME/speedtest_upload.log"
	true > $log_up
	$(cat speedtest.log 2>&1 | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" > $log_up)
}

get_ip_whois_org_name(){
	#ip=$(curl -s ip.sb)
	result=$(curl -s https://rest.db.ripe.net/search.json?query-string=$(curl -s ip.sb))
	#org_name=$(echo $result | jq '.objects.object.[1].attributes.attribute.[1].value' | sed 's/\"//g')
	org_name=$(echo $result | jq '.objects.object[1].attributes.attribute[1]' | sed 's/\"//g')
    echo $org_name;
}

pingtest() {
	local ping_link=$( echo ${1#*//} | cut -d"/" -f1 )
	local ping_ms=$( ping -w 1 -c 1 -q $ping_link | grep 'rtt' | cut -d"/" -f5 )

	# get download speed and print
	if [[ $ping_ms == "" ]]; then
		printf "ping error!"
	else
		printf "%3i.%s ms" "${ping_ms%.*}" "${ping_ms#*.}"
	fi
}

cleanup() {
	rm -f test_file_*;
	rm -f speedtest.py;
	rm -f speedtest.sh;
	rm -f tools.py;
	rm -f ip_json.json;
	rm -f geekbench4_claim.url;
	rm -rf geekbench;
}

bench_all(){
	region_name="Global"
	print_intro;
	benchinit;
	clear
	next;
	get_system_info;
	print_system_info;
	ip_info4;
	next;
	iotest;
	write_io;
	print_speedtest;
	next;
	geekbench4;
	print_end_time;
	cleanup;
	sharetest clbin;
}

usa_bench(){
	region_name="USA"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	next;
	print_speedtest_usa;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

asia_bench(){
	region_name="Asia"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	next;
	print_speedtest_asia;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

europe_bench(){
	region_name="Europe"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	next;
	print_speedtest_europe;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

taiwan_bench(){
	region_name="Taiwan"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	next;
	print_speedtest_taiwan;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

china_bench(){
	region_name="China"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	next;
	print_speedtest_china;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

singapore_bench(){
	region_name="Singapore"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	next;
	print_speedtest_singapore;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

dryrun_bench(){
	region_name="DryRun"
	print_intro;
	benchinit;
	clear
	next;
	ip_info4;
	print_speedtest_dryrun;
	next;
	print_end_time;
	cleanup;
	sharetest clbin;
}

log="$HOME/speedtest.log"
true > $log

case $1 in
	'info'|'-i'|'--i'|'-info'|'--info' )
		clear;about;sleep 3;next;get_system_info;print_system_info;;
	'version'|'-v'|'--v'|'-version'|'--version')
		clear;next;about;next;;
	'gb'|'-gb'|'--gb'|'geek'|'-geek'|'--geek' )
		clear;next;geekbench4;next;cleanup;;
	'io'|'-io'|'--io' )
		clear;next;iotest;write_io;next;;
	'ioping'|'-ioping'|'--ioping' )
		clear;next;ioping;next;;
	'dd'|'-dd'|'--dd'|'disk'|'-disk'|'--disk' )
		clear;about;ioping;next2;cleanup;;
	'speed'|'-speed'|'--speed'|'-speedtest'|'--speedtest'|'-speedcheck'|'--speedcheck' )
		about;benchinit;next;print_speedtest;next;cleanup;;
	'ip'|'-ip'|'--ip'|'geoip'|'-geoip'|'--geoip' )
		clear;about;benchinit;next;ip_info4;next;cleanup;;
	'bench'|'-a'|'--a'|'-all'|'--all'|'-bench'|'--bench'|'-Global' )
		bench_all;;
	'about'|'-about'|'--about' )
		about;;
	'usa'|'-usa'|'--usa'|'us'|'-us'|'--us'|'USA'|'-USA'|'--USA' )
		usa_bench;;
	'europe'|'-europe'|'--europe'|'eu'|'-eu'|'--eu'|'Europe'|'-Europe'|'--Europe' )
		europe_bench;;
	'asia'|'-asia'|'--asia'|'as'|'-as'|'--as'|'Asia'|'-Asia'|'--Asia' )
		asia_bench;;
	'taiwan'|'-taiwan'|'--taiwan'|'tw'|'-tw'|'--tw'|'taiwan'|'-Taiwan'|'--Taiwan' )
		taiwan_bench;;
	'china'|'-china'|'--china'|'cn'|'-cn'|'--cn'|'china'|'-China'|'--China' )
		china_bench;;
	'singapore'|'-singapore'|'--singapore'|'sg'|'-sg'|'--sg'|'Singapore'|'-Singapore'|'--Singapore' )
		singapore_bench;;
	'dryrun'|'-dryrun'|'--dryrun'|'sg'|'-sg'|'--sg'|'Dryrun'|'-Dryrun'|'--Dryrun' )
		dryrun_bench;;
	'-s'|'--s'|'share'|'-share'|'--share' )
		bench_all;
		is_share="share"
		if [[ $2 == "" ]]; then
			sharetest ubuntu;
		else
			sharetest $2;
		fi
		;;
	'debug'|'-d'|'--d'|'-debug'|'--debug' )
		get_ip_whois_org_name;;
*)
    bench_all;;
esac



if [[  ! $is_share == "share" ]]; then
	case $2 in
		'share'|'-s'|'--s'|'-share'|'--share' )
			if [[ $3 == '' ]]; then
				sharetest ubuntu;
			else
				sharetest $3;
			fi
			;;
	esac
fi

# ring a bell
printf '\007'
