#!/bin/bash

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
  echo "Lütfen bu betiği sudo ile çalıştırın."
  exit
fi

THEME_NAME="Matrices-circle-window"
THEME_DIR="/boot/grub2/themes/$THEME_NAME"

echo "-----------------------------------------------"
echo "GRUB Özelleştirme ve Tema Kurulumu Başlıyor..."
echo "-----------------------------------------------"

# 1. Temayı Klasöre Kopyala
echo "[1/4] Tema dosyaları sisteme kopyalanıyor..."
mkdir -p /boot/grub2/themes/
cp -r . /boot/grub2/themes/$THEME_NAME 2>/dev/null

# 2. Windows UUID Tespit Etme
echo "[2/4] Windows önyükleme bölümü aranıyor..."
# Sistemdeki FAT32 bölümlerinden UUID'yi otomatik çeker
WIN_UUID=$(lsblk -no UUID,FSTYPE | grep vfat | awk '{print $1}' | head -n 1)

# Eğer otomatik bulamazsa senin mevcut UUID'ni (79C9-93A2) yedek olarak kullanır
if [ -z "$WIN_UUID" ]; then
    WIN_UUID="79C9-93A2"
fi

# 3. Windows Girişini 40_custom Dosyasına Ekle
echo "[3/4] /etc/grub.d/40_custom yapılandırılıyor (UUID: $WIN_UUID)..."
cat <<EOF > /etc/grub.d/40_custom
#!/usr/bin/sh
exec tail -n +3 \$0
menuentry 'Windows' --class windows --class os {
    insmod part_gpt
    insmod fat
    search --no-floppy --fs-uuid --set=root $WIN_UUID
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
chmod +x /etc/grub.d/40_custom

# 4. /etc/default/grub Ayarlarını Optimize Et
echo "[4/4] /etc/default/grub ayarları güncelleniyor..."
# Temizlik ve senin Fedora ayarlarının eklenmesi
sed -i '/GRUB_THEME=/d' /etc/default/grub
sed -i '/GRUB_ENABLE_BLSCFG=/d' /etc/default/grub
sed -i '/GRUB_DISTRIBUTOR=/d' /etc/default/grub

cat <<EOF >> /etc/default/grub
GRUB_DISTRIBUTOR="Fedora"
GRUB_ENABLE_BLSCFG=false
GRUB_THEME="$THEME_DIR/theme.txt"
EOF

# 5. Sistemi Güncelle
echo "-----------------------------------------------"
echo "GRUB yapılandırması yenileniyor..."
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "-----------------------------------------------"
echo "İşlem Tamam! Windows eklendi ve $THEME_NAME aktif edildi."
echo "-----------------------------------------------"