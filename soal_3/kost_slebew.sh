#!/bin/bash

menu(){
    cat << 'EOF'                  
 _ __ ___  ___  ___   ___  _    ___  ___  ___  _ _ _  
| / /| . |/ __>|_ _| / __>| |  | __>| . >| __>| | | | 
|  \ | | |\__ \ | |  \__ \| |_ | _> | . \| _> | | | | 
|_\_\`___'<___/ |_|  <___/|___||___>|___/|___>|__/_/  
                                                                               
EOF

    echo "===================================================="
    echo "            SISTEM MANAJEMEN KOST SELEBEW"
    echo "===================================================="
    echo " ID | MENU"
    echo "----+----------------------------------------------"
    echo " 1  | Tambah Penghuni Baru"
    echo " 2  | Hapus Penghuni"
    echo " 3  | Tampilkan Daftar Penghuni"
    echo " 4  | Update Status Penghuni"
    echo " 5  | Cetak Laporan Keuangan"
    echo " 6  | Kelola Cron (Pengingat Tagihan)"
    echo " 7  | Exit Program"
    echo "===================================================="
}


tambah_penghuni(){
    echo "======================================"
    echo "   Menambahkan Data Penghuni Baru"
    echo "======================================"
    
    file="data/penghuni.csv"

    mkdir -p data

    if [ ! -s "$file" ]; then
        printf "id,nama,kamar,harga_sewa,tanggal_masuk,status\n" > "$file"
    fi 

    #nama
    while true; do
        read -p "Masukkan Nama: " nama

        if [[ ! "$nama" =~ ^[A-Za-z\ ]+$ ]]; then
            echo "Nama hanya boleh huruf dan spasi!"
        else
            break
        fi
    done
    
    #nomor kamar
    while true; do
        read -p "Masukkan Nomor Kamar: " kamar
        if ! [[ "$kamar" =~ ^[0-9]+$ ]]; then
            echo "Nomor kamar harus berupa angka!"
            continue
        fi

        if [ "$kamar" -le 0 ]; then
            echo "Nomor kamar harus lebih dari 0!"
            continue
        fi

        if awk -F',' -v k="$kamar" 'NR>1 && $3==k {found=1} END{exit !found}' "$file"; then
            echo "Kamar sudah terisi! Pilih nomor lain."
        else
            break
        fi
    done

    #harga
    while true; do
        read -p "Masukkan Harga Sewa: " harga_sewa

        if ! [[ "$harga_sewa" =~ ^-?[0-9]+$ ]]; then
            echo "Harus angka!"
            continue
        fi

        if [ "$harga_sewa" -le 0 ]; then
            echo "Harga harus lebih dari 0!"
        else
            break
        fi
        
    done  

    #tanggal
    while true
    do 
        read -p "Masukkan Tanggal Masuk (YYYY-MM-DD): " tanggal_masuk
        # cek format
        [[ "$tanggal_masuk" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || {
            echo "Format tanggal tidak valid"
            continue
        }

        # cek apakah tanggal valid 
        tanggal_num=$(date -d "$tanggal_masuk" +%Y%m%d 2>/dev/null) || {
            echo "Tanggal tidak valid"
            continue
        }

        today_num=$(date +%Y%m%d)

        # cek apakah tanggal di masa depan
        if (( tanggal_num > today_num )); then
            echo "Tanggal tidak boleh melebihi hari ini"
            continue
        fi

        break
    done
    
    #status awal
    while true
    do
        read -p "Masukkan Status Awal (Aktif/Menunggak): " status_awal
        if [[ $status_awal == "Aktif" || $status_awal == "Menunggak" ]]; then
            break
        else
            echo 'Format tidak valid! Silakan tulis "Aktif" atau "Menunggak"'
        fi
    done

    #simpan
    last_id=$(tail -n 1 "$file" | cut -d',' -f1)

    if [[ "$last_id" =~ ^[0-9]+$ ]]; then
        new_id=$((last_id + 1))
    else
        new_id=1
    fi

    echo "$new_id,$nama,$kamar,$harga_sewa,$tanggal_masuk,$status_awal" >> "$file"

    echo ""
    echo "Penghuni ["$nama"] berhasil ditambahkan ke Kamar" [$kamar] "dengan status "[$status_awal]

    echo ""
    read -p "Tekan [ENTER] untuk melanjutkan..."


}

hapus_penghuni(){
    file="data/penghuni.csv"
    history="sampah/history_hapus.csv"

    mkdir -p sampah

    # header 

    if [ ! -s "$history" ]; then
        printf "id,nama,kamar,harga_sewa,tanggal_masuk,status,tanggal_hapus\n" > "$history"
    fi

    # cek apakah ada data penghuni 
    if [ ! -f "$file" ] || [ $(wc -l < "$file") -le 1 ]; then
        echo "Belum ada data penghuni!"
        read -p "Tekan [ENTER] untuk melanjutkan..."
        return
    fi
    echo "======================================================="
    echo "               Menghapus penghuni kos"
    echo "======================================================="

    while true
    do
        read -p "Masukkan nama penghuni yang ingin dihapus: " nama

        # cek ada atau tidak
        if ! awk -F',' -v n="$nama" 'NR>1 && $2==n {found=1} END{exit !found}' "$file"; then
            echo "Penghuni tidak ditemukan!"
            read -p "Tekan [ENTER] untuk melanjutkan..."
        else 
            break
        fi

    done

    echo "Data yang akan dihapus:"
    awk -F',' -v n="$nama" 'NR>1 && $2==n' "$file"

    echo
    read -p "Yakin ingin menghapus data ini? (y/n): " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Penghapusan dibatalkan."
        return
    fi
    tanggal_hapus=$(date +%Y-%m-%d)
    awk -F',' -v n="$nama" -v t="$tanggal_hapus" '
    NR>1 && $2==n {
        print $0 "," t
    }
    ' "$file" >> "$history"

    awk -F',' -v n="$nama" '
    NR==1 || $2!=n
    ' "$file" > temp.csv
    mv temp.csv "$file"

    echo "Penghuni berhasil dihapus!"

    echo ""
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

tampilkan_penghuni(){
    file="data/penghuni.csv"

    if [ ! -f "$file" ]; then
        echo "File tidak ditemukan!"
        return
    fi

    if [ ! -f "$file" ] || [ $(wc -l < "$file") -le 1 ]; then
        echo "Belum ada data penghuni!"
        read -p "Tekan [ENTER] untuk melanjutkan..."
        return
    fi

    echo "============================================================================="
    echo "                       DAFTAR PENGHUNI KOST SLEBEW"
    echo "============================================================================="
    echo "ID   |         Nama         |  Kamar  |         Harga        |    Status"
    echo "-----------------------------------------------------------------------------"

    awk -F',' '
    NR>1 {
        id=$1
        nama=$2
        kamar=$3
        harga=$4
        status=$6

        # padding manual (sederhana)
        while(length(nama) < 20) nama=nama " "
        while(length(kamar) < 7) kamar=kamar " "
        while(length(harga) < 10) harga=harga " "

        print id "    | " nama " | " kamar " | " harga "           | " status

        total++
        if (status == "Aktif") aktif++
        if (status == "Menunggak") menunggak++

        if (aktif < 1) aktif = 0
        if (menunggak < 1) menunggak = 0
    }
    END {
        print "-----------------------------------------------------------------------"
        print "Total Penghuni   : " total
        print "Status Aktif     : " aktif
        print "Status Menunggak : " menunggak
    }
    ' "$file"

    echo "============================================================================="
    echo
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

update_status(){
    file="data/penghuni.csv"

    if [ ! -f "$file" ]; then
        echo "File tidak ditemukan!"
        return
    fi

    if [ ! -f "$file" ] || [ $(wc -l < "$file") -le 1 ]; then
        echo "Belum ada data penghuni!"
        read -p "Tekan [ENTER] untuk melanjutkan..."
        return
    fi
    echo "==================================================="
    echo "           Memperbarui status penghuni"
    echo "==================================================="

    while true
    do
        read -p "Masukkan nama penghuni: " nama

        # cek ada atau tidak
        if ! awk -F',' -v n="$nama" 'NR>1 && $2==n {found=1} END{exit !found}' "$file"; then
            echo "Penghuni tidak ditemukan!"
            read -p "Tekan [ENTER] untuk melanjutkan..."
        else 
            break
        fi

    done

    echo "Data ditemukan:"
    awk -F',' -v n="$nama" '
    NR>1 && $2==n {
        print "ID:", $1, "| Nama:", $2, "| Status saat ini:", $6
    }' "$file"

    echo

    # input status baru
    while true; do
        read -p "Masukkan status baru (Aktif/Menunggak): " status_baru

        if [[ "$status_baru" == "Aktif" || "$status_baru" == "Menunggak" ]]; then
            break
        else
            echo "Format tidak valid!"
        fi
    done

    # update file
    awk -F',' -v n="$nama" -v s="$status_baru" '
    BEGIN { OFS="," }
    NR==1 { print; next }

    {
        if ($2 == n) {
            $6 = s
        }
        print
    }
    ' "$file" > temp.csv

    mv temp.csv "$file"

    echo "Status berhasil diperbarui!"
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

cetak_laporan(){
    file="data/penghuni.csv"

    if [ ! -f "$file" ]; then
        echo "File tidak ditemukan!"
        return
    fi

    if [ ! -f "$file" ] || [ $(wc -l < "$file") -le 1 ]; then
        echo "Belum ada data penghuni!"
        read -p "Tekan [ENTER] untuk melanjutkan..."
        return
    fi

    laporan="rekap/laporan_bulanan.txt"

    mkdir -p rekap

    tanggal_laporan=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "======================================================"
        echo "               LAPORAN KEUANGAN KOST"
        echo "                ""$tanggal_laporan"
        echo "======================================================"

    awk -F',' '
    BEGIN {
        total_penghuni=0
        aktif=0
        menunggak=0
        pemasukan=0
        tunggakan=0
    }
    NR>1 {
        total_penghuni++

        if ($6 == "Aktif") {
            pemasukan += $4
            aktif++
        }

        if ($6 == "Menunggak") {
            tunggakan += $4
            menunggak++
            data_menunggak = data_menunggak $1 "|" $2 "|" $3 "|" $4 "\n"
        }
    }
    END {
        print "Total Penghuni   : " total_penghuni
        print "Kamar Terisi     : " total_penghuni
        print "Status Aktif     : " aktif
        print "Status Menunggak : " menunggak
        print "--------------------------------------"
        print "Total Pemasukan  : Rp " pemasukan
        print "Total Tunggakan  : Rp " tunggakan
        print "--------------------------------------"

        print "Daftar Penghuni Menunggak:"

        if (menunggak == 0) {
            print "(Tidak ada)"
        } else {
            split(data_menunggak, arr, "\n")
            for (i in arr) {
                if (arr[i] != "") {
                    split(arr[i], f, "|")
                    print "| " f[2] " | No Kamar : " f[3] " | Total Tunggakan : Rp " f[4] " |"
                }
            }
        }
    }
    ' "$file"

    echo "======================================================"
    } | tee -a "$laporan"
    echo
    echo "Laporan berhasil disimpan ke rekap/laporan_bulanan.txt"
    read -p "Tekan [ENTER] untuk melanjutkan..."
}


check_tagihan(){
    file="data/penghuni.csv"
    log="log/tagihan.log"

    mkdir -p log

    tanggal=$(date "+%Y-%m-%d %H:%M:%S")

    {
        echo "=================================================="
        echo "CEK TAGIHAN - $tanggal"
        echo "=================================================="

        if [ ! -f "$file" ] || [ $(wc -l < "$file") -le 1 ]; then
            echo "(Belum ada data penghuni)"
            echo
            return
        fi

        awk -F',' '
        BEGIN {
            found=0
            total=0
        }
        NR>1 {
            if ($6=="Menunggak") {
                print "| " $2 " | KAMAR " $3 " | TUNGGAKAN: Rp " $4 " |"
                total++
                found=1
            }
        }
        END {
            if (found==0) {
                print "(Tidak ada penghuni menunggak)"
            } else {
                print "------------------------------------------"
                print "Total Menunggak : " total " penghuni"
            }
        }
        ' "$file"

        echo
    } >> "$log"
    echo "Data tagihan sudah disimpan di file tagihan.log "
}

if [ "$1" == "--check--tagihan" ]; then
    check_tagihan
    exit
fi

cron_menu(){
    echo "============================================="
    echo "            MENU KELOLA CRON"
    echo "============================================="
    echo " ID | MENU"
    echo "----+----------------------------------------"
    echo " 1  | Lihat Cron Job Aktif "
    echo " 2  | Daftarkan Cron Job Pengingat"
    echo " 3  | Hapus Cron Job Pengingat "
    echo " 4  | Kembali "
    echo "=============================================" 
}

lihat_cron(){
    echo "============================================="
    echo "     --- Cron Job Pengingat Tagihan ---"
    echo "============================================="
    
    crontab -l 2>/dev/null | grep -- "--check--tagihan"

    if [ $? -ne 0 ]; then
        echo "(Tidak ada jadwal aktif)"
    fi

    echo
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

tambah_cron(){
    script_path="$(realpath "$0")"

    echo "============================================="
    echo "     --- Menambahkan Jadwal Baru ---"
    echo "============================================="

    while true; do
        read -p "Masukkan jam (0-23): " jam

        if ! [[ "$jam" =~ ^[0-9]+$ ]]; then
            echo "Jam harus angka!"
            continue
        fi

        if [ "$jam" -lt 0 ] || [ "$jam" -gt 23 ]; then
            echo "Jam harus antara 0-23!"
        else
            break
        fi
    done

    while true; do
        read -p "Masukkan menit (0-59): " menit

        if ! [[ "$menit" =~ ^[0-9]+$ ]]; then
            echo "Menit harus angka!"
            continue
        fi

        if [ "$menit" -lt 0 ] || [ "$menit" -gt 59 ]; then
            echo "Menit harus antara 0-59!"
        else
            break
        fi
    done

    echo
    echo "Jadwal yang dipilih: $jam:$menit"

    read -p "Yakin ingin menyimpan? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Dibatalkan."
        read -p "Tekan [ENTER] untuk melanjutkan..."
        return
    fi

    (crontab -l 2>/dev/null | grep -v -- "--check--tagihan"; echo "$menit $jam * * * $script_path --check--tagihan") | crontab -

    echo
    echo "Cron berhasil disimpan!"
    echo "Akan berjalan setiap hari pukul $jam:$menit"

    echo
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

hapus_cron(){
    script_path="$(realpath "$0")"

    echo "============================================="
    echo "         --- Menghapus Jadwal ---"
    echo "============================================="

    read -p "Yakin ingin menghapus? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Dibatalkan."
        read -p "Tekan [ENTER] untuk melanjutkan..."
        return
    fi


    crontab -l 2>/dev/null | grep -v -- "--check--tagihan" | crontab -

    echo "Jadwal berhasil dihapus."
    echo
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

cron_default(){
    script_path="$(realpath "$0")"

    if ! crontab -l 2>/dev/null | grep -q -- "--check--tagihan"; then
        
        (crontab -l 2>/dev/null; echo "0 7 * * * $script_path --check--tagihan") | crontab -

    fi
}

cron_dashboard(){
    while true; do 
    clear
    cron_menu
    read -p "Masukkan opsi [1-4]: " choice
    case $choice in
    1) 
        clear
        lihat_cron
        ;;
    2) 
        clear
        tambah_cron
        ;;
    3)
        clear
        hapus_cron
        ;;
    4)  
        clear
        break
        ;;
    *)
        echo "Opsi tidak valid! Silakan masukkan angka [1-4]"
        read -p "Tekan [ENTER] untuk melanjutkan..."
        ;;
    esac
done
}

cron_default
while true; do
    clear
    menu
    read -p "Masukkan opsi [1-7]: " choice
    case $choice in
    1) 
        clear
        tambah_penghuni 
        ;;
    2)
        clear
        hapus_penghuni
        ;;
    3)
        clear
        tampilkan_penghuni
        ;;
    4) 
        clear
        update_status
        ;;
    5)
        clear
        cetak_laporan
        ;;
    6)
        clear
        cron_dashboard
        ;;
    7)  
        echo "KELUAR DARI SISTEM MANAJEMEN KOST SLEBEW"
        exit
        ;;
    *)
        echo "Opsi tidak valid! Silakan masukkan angka [1-7]"
        read -p "Tekan [ENTER] untuk melanjutkan..."
        ;;
    esac
done
