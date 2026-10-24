# Installation neuve avec Disko (destructive)

Cette procedure est pour un **SSD entierement dedie a NixOS** sur le Lenovo ThinkCentre M720q en **UEFI**. Elle efface les partitions et les donnees du SSD cible. Sauvegarder les donnees avant toute commande de partitionnement.

## 1. Demarrer sur la cle USB NixOS

Utiliser une image NixOS Live x86_64, demarrer en UEFI (menu F12 Lenovo), connecter le reseau et ouvrir un terminal. Copier le projet dans `/tmp/nixos-media-center` (par exemple depuis une autre cle USB ou un depot Git). Se placer dans ce dossier.

```bash
cd /tmp/nixos-media-center
lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

Identifier le **SSD interne** sans ambiguite. Eviter le disque USB d'installation. Copier son chemin stable `/dev/disk/by-id/...` dans `disko.nix` a la place de `REPLACE_WITH_SSD_ID`. Verifier le lien avec `readlink -f /dev/disk/by-id/...` et `lsblk`.

## 2. Verifier le flake et la cible

```bash
nix --extra-experimental-features 'nix-command flakes' flake show .
grep 'device =' disko.nix
```

**Derniere verification : la commande suivante DETRUIT les partitions du SSD choisi.**

## 3. Partitionner et monter avec Disko

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko ./disko.nix
findmnt /mnt
findmnt /mnt/boot
lsblk -f
```

Disko partitionne, formate et monte normalement les systemes de fichiers sous `/mnt` dans ce mode. Si les montages ne sont pas presents, ne pas poursuivre : verifier les messages d'erreur.

## 4. Generer la configuration materielle

```bash
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix ./hardware-configuration.nix
```

IMPORTANT : le fichier genere peut contenir des declarations `fileSystems` et `swapDevices` qui doublonnent avec Disko. Dans `hardware-configuration.nix`, **conserver les modules noyau et options materielle** mais retirer les definitions `fileSystems` et `swapDevices` generees : Disko les definit deja. Ne pas supprimer les imports materiels. Verifier aussi la compatibilite avec `boot.loader.systemd-boot` et UEFI.

## 5. Installer

Changer dans `configuration.nix` le `initialPassword = "change-me-now"` avant installation ; utiliser un mot de passe temporaire robuste ou, de preference, une configuration de mot de passe hache. La valeur `system.stateVersion` doit correspondre a la version de premiere installation souhaitee, et ne pas etre modifiee arbitrairement ensuite.

```bash
sudo nix --extra-experimental-features 'nix-command flakes' flake lock
sudo nixos-install --root /mnt --flake .#media-center
```

Si la commande d'installation ne prend pas en charge les fonctionnalites experimentales, les activer dans la session Live (`nix.settings.experimental-features = nix-command flakes` ou configuration Nix appropriee).

Apres succes, redemarrer. La session `media` se connectera automatiquement et le menu plein ecran devrait se lancer.

## Installation existante : ne pas repartitionner

Ne **jamais** lancer `disko --mode disko` sur un SSD contenant un systeme ou des donnees a conserver. Pour mettre a jour le Media Center sur une installation existante, utiliser la version sans module Disko ou adapter le flake au partitionnement existant ; ne pas appliquer ce schema destructif en l'etat.

## Notes

- Schéma : GPT, ESP 1 Gio FAT32, swap 8 Gio, racine ext4 sur le reste.
- Pas de chiffrement LUKS ni de partition `/home` separee.
- Pas d'hibernation configuree.
- Le chemin `/dev/disk/by-id/REPLACE_WITH_SSD_ID` est un placeholder intentionnel : ne pas lancer Disko avant son remplacement.
- Cette configuration n'a pas ete testee sur le ThinkCentre reel.
