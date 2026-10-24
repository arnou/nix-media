# NixOS Media Center — Lenovo ThinkCentre M720q

Menu plein écran : Kodi, YouTube, Twitch, Jellyfin. KDE Plasma, connexion automatique au compte `media`, Chromium en mode kiosque, serveur HTTP local sur 127.0.0.1:8765.

## Prérequis

- NixOS installé en mode UEFI sur le ThinkCentre (installation standard, SSD sauvegardé).
- Un accès administrateur et un réseau fonctionnel.
- Écran connecté en DisplayPort ou HDMI selon équipement.
- La configuration est prévue pour **une installation NixOS existante** ; elle ne partitionne pas le SSD.

## Mise en place

1. Copier ce dossier sur le ThinkCentre, par exemple dans `/etc/nixos/media-center`.
2. **Remplacer** `hardware-configuration.nix` par `/etc/nixos/hardware-configuration.nix` généré sur **ce PC** :
   `sudo cp /etc/nixos/hardware-configuration.nix /etc/nixos/media-center/hardware-configuration.nix`
3. Vérifier `boot.loader.*`, le fuseau horaire et `system.stateVersion` : garder la valeur `system.stateVersion` de l'installation NixOS existante (ne pas la mettre à jour arbitrairement). La configuration suppose un démarrage UEFI systemd-boot ; adapter si GRUB est déjà utilisé.
4. **Changer le mot de passe initial** après premier démarrage : `passwd` depuis le compte `media`, ou définir le compte de façon plus sûre avant déploiement. `initialPassword` est une valeur de démonstration à modifier avant tout déploiement.
5. Activer flakes si nécessaire :
   `sudo nix --extra-experimental-features 'nix-command flakes' flake show /etc/nixos/media-center`
6. Tester puis déployer :
   `sudo nix --extra-experimental-features 'nix-command flakes' flake check /etc/nixos/media-center`
   `sudo nix --extra-experimental-features 'nix-command flakes' build /etc/nixos/media-center#nixosConfigurations.media-center.config.system.build.toplevel`
   `sudo nix --extra-experimental-features 'nix-command flakes' nixos-rebuild switch --flake /etc/nixos/media-center#media-center`
7. Redémarrer.

**Attention :** `flake.nix` pointe vers nixos-26.05. Générer `flake.lock` sur la machine, et vérifier la disponibilité des options sur cette version. Le projet est un modèle à adapter, pas une image ISO prévalidée.

## Utilisation

- Kodi : clique la tuile ; Kodi s'ouvre au-dessus de Chromium.
- YouTube / Twitch : ouvrent leurs sites dans Chromium. `Alt+←` revient au menu.
- Jellyfin : premier clic -> saisir l'URL de ton serveur ; clic suivant -> ouvrir.
- En cas de problème : `journalctl --user -u media-center-server -e` (depuis le compte `media`).
- Pour quitter le kiosque Chromium : `Alt+F4` ; pour revenir au menu, relancer la session.

## Sécurité et limitations

- **Autologin** : toute personne devant l'ordinateur peut accéder au compte `media`.
- Le serveur HTTP n'écoute que sur 127.0.0.1 ; l'action Kodi vérifie l'origine HTTP.
- Les navigateurs Linux peuvent être limités en DRM / 4K pour les plateformes commerciales.
- L'usage en kiosque avec Plasma peut nécessiter un ajustement du placement/focus de Kodi selon le compositeur et les écrans.
- Le menu est navigable au clavier (Tab, Entrée) et à la souris ; pas de télécommande IR préconfigurée.
- Le bouton Jellyfin ne démarre **pas** de serveur Jellyfin ; il ouvre un serveur existant.
- La fermeture de Kodi revient normalement au navigateur, qui reste ouvert derrière.

## Installation neuve avec partitionnement Disko

Le flake importe maintenant `disko.nixosModules.disko` et `disko.nix`.
**Ne pas appliquer ce flake tel quel a une installation existante** sans adapter ou retirer le module Disko : le schema de disque doit correspondre au systeme en place.

Pour une installation neuve sur SSD dedie, lire **[INSTALL-DISKO.md](INSTALL-DISKO.md)** avant toute commande. Le partitionnement est destructif, et le chemin du SSD est volontairement laisse en placeholder dans `disko.nix`.
