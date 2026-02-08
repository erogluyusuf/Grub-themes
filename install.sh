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
echo "[1/5] Tema dosyaları sisteme kopyalanıyor..."
mkdir -p /boot/grub2/themes/
cp -r . /boot/grub2/themes/$THEME_NAME 2>/dev/null

# 2. Windows UUID Tespit Etme
echo "[2/5] Windows önyükleme bölümü aranıyor..."
WIN_UUID=$(lsblk -no UUID,FSTYPE | grep vfat | awk '{print $1}' | head -n 1)

if [ -z "$WIN_UUID" ]; then
    WIN_UUID="79C9-93A2" # Senin sistemin için yedek [cite: 2026-01-30]
fi

# 3. Windows Girişini 40_custom Dosyasına Ekle
echo "[3/5] /etc/grub.d/40_custom yapılandırılıyor (UUID: $WIN_UUID)..."
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

# 4. /etc/default/grub Ayarlarını Optimize Et (os-prober dahil)
echo "[4/5] /etc/default/grub ayarları güncelleniyor..."
# Eski ayarları temizle
sed -i '/GRUB_THEME=/d' /etc/default/grub
sed -i '/GRUB_ENABLE_BLSCFG=/d' /etc/default/grub
sed -i '/GRUB_DISTRIBUTOR=/d' /etc/default/grub
sed -i '/GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub

# Yeni ayarları ekle
cat <<EOF >> /etc/default/grub
GRUB_DISTRIBUTOR="Fedora"
GRUB_ENABLE_BLSCFG=false
GRUB_THEME="$THEME_DIR/theme.txt"
GRUB_DISABLE_OS_PROBER=false
EOF

# 5. Sistemi Güncelle ve os-prober'ı Tetikle
echo "[5/5] GRUB yapılandırması yenileniyor ve os-prober zorlanıyor..."
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "-----------------------------------------------"
echo "İşlem Tamam! Tema Aktif"
echo "-----------------------------------------------"