#!/bin/bash

BEGIN {
	FS =  ","
	input = ARGV[2]
	delete ARGV[2]
}	

NR > 1 {
	if (input == "a") count++
	else if(input == "b") gerbong[$4]++
	else if(input == "c") {
		if ($2 > oldest) {oldest = $2; name = $1}
	} 
	else if(input == "d" ) {count++; total+=$2}
	else if(input == "e") {
		if ($3 == "Business") {count_class++}
	}  
} END {
	if (input == "a") print "Jumlah seluruh penumpang KANJ adalah" ,count, "orang"
	else if (input =="b") print "Jumlah gerbong penumpang KANJ adalah" ,length(gerbong)-1
	else if(input =="c") print name, "adalah penumpang tertua dengan usia", oldest, "tahun"
	else if (input == "d") print "Rata-rata usia penumpang adalah" ,int(total/count), "tahun"
	else if(input == "e") print "Jumlah penumpang business class ada" ,count_class, "orang"
	else {
		print "Soal tidak dikenali. Gunakan a, b ,c ,d, atau e."
		print "Contoh format: awk -f KANJ.sh passenger.csv a"
	}
}
