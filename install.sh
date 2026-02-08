#!/bin/bash

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
  echo "Lütfen bu betiği sudo ile çalıştırın."
  exit
fi

THEME_NAME="Matrices-circle-window"
THEME_DIR="/boot/grub2/themes/$THEME_NAME"

echo "-----------------------------------------------"
echo "GRUB Güzelleştirme ve OS-Prober Zorlama Betiği"
echo "-----------------------------------------------"

# 1. os-prober Kontrolü ve Kurulumu
if ! command -v os-prober &> /dev/null; then
    echo "[1/6] os-prober bulunamadı, kuruluyor..."
    dnf install -y os-prober
else
    echo "[1/6] os-prober zaten kurulu."
fi

# 2. Temayı Klasöre Kopyala
echo "[2/6] Tema dosyaları kopyalanıyor..."
mkdir -p /boot/grub2/themes/
cp -r . /boot/grub2/themes/$THEME_NAME 2>/dev/null

# 3. Windows UUID Tespit Etme
echo "[3/6] Diskler Windows için taranıyor..."
WIN_UUID=$(lsblk -no UUID,FSTYPE | grep vfat | awk '{print $1}' | head -n 1)

# 4. 40_custom Yapılandırması (Garantili Manuel Giriş)
if [ -n "$WIN_UUID" ]; then
    echo "[4/6] Windows bulundu (UUID: $WIN_UUID). Manuel giriş ekleniyor..."
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
fi

# 5. /etc/default/grub Ayarlarını ZORLA Güncelle
echo "[5/6] /etc/default/grub zorlanıyor (os-prober aktif)..."
# Mevcut çakışan ayarları temizle
sed -i '/GRUB_THEME=/d' /etc/default/grub
sed -i '/GRUB_ENABLE_BLSCFG=/d' /etc/default/grub
sed -i '/GRUB_DISTRIBUTOR=/d' /etc/default/grub
sed -i '/GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub

# Ayarları dosyaya işle
cat <<EOF >> /etc/default/grub
GRUB_DISTRIBUTOR="Fedora"
GRUB_ENABLE_BLSCFG=false
GRUB_THEME="$THEME_DIR/theme.txt"
GRUB_DISABLE_OS_PROBER=false
EOF

# 6. Yapılandırmayı Oluştur
echo "[6/6] GRUB menüsü oluşturuluyor..."
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "-----------------------------------------------"
echo "İşlem Tamam! Artık boot ekranında her şeyi görmelisin."
echo "-----------------------------------------------"