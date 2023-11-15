#!/bin/bash

# Kaynak sunucu bilgileri
source_host="88.99.146.8"
source_user="root"
source_path_prefix="/home/hls/public_html/cdn/down/"  # Değişken kısım
source_password="DxwwEwuGhryT9d"   # Belirtilmiş şifre

# Kullanıcıdan alınan kaynak yolunu kullanarak tam kaynak yolunu oluştur
source_path="$source_path_prefix$1"

# Hedef sunucu bilgileri
target_host="49.12.8.157"
target_user="root"
target_path="/home/hls/public_html/cdn/down/"  # Sabit kısım
target_password="Ma.437588"  # Belirtilmiş şifre

# Kontrol: Kaynak yolu belirtilmiş mi?
if [ -z "$1" ]; then
    echo "Hata: Kaynak yolu belirtmelisiniz."
    echo "Kullanım: ./dosya_kopyalama.sh /burası/değişken/olacak"
    exit 1
fi

# Dosya kopyalama
copy_files() {
    echo "Dosyalar kopyalanıyor..."
    # -B parametresi kullanıcıdan şifreyi alır
    sshpass -p "$source_password" scp -r "$source_user@$source_host:$source_path" "$target_user@$target_host:$target_path"
    echo "Dosya kopyalama işlemi tamamlandı."
}

# Ana fonksiyonu çağır
copy_files
