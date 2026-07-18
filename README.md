# Mob Health Modifier

Mod **Forge 1.20.1 côté serveur** permettant de multiplier la vie maximale des mobs hostiles, y compris la majorité des mobs hostiles ajoutés par des mods.

La version actuelle est **1.0.3**.

## Fonctionnement

Le mod utilise l'interface Minecraft `Enemy` afin de ne cibler que les créatures hostiles.

Sont concernés :

- monstres vanilla ;
- boss hostiles ;
- la majorité des mobs hostiles moddés correctement déclarés.

Ne sont pas modifiés :

- joueurs ;
- animaux et créatures passives ;
- villageois ;
- armor stands ;
- autres entités non hostiles.

Le mod est prévu pour un **serveur dédié**. Les joueurs n'ont pas besoin de l'installer côté client.

## Compatibilité

- Minecraft **1.20.1**
- Forge **47.2.0 ou supérieur**
- Java **17**
- Serveur dédié

## Installation

1. Arrêter complètement le serveur.
2. Supprimer les anciennes versions du mod.
3. Placer `hostile-mob-health-multiplier-1.0.3.jar` dans le dossier `mods/`.
4. Redémarrer le serveur.

Le fichier suivant est créé automatiquement :

```text
config/mob-health-multiplier.properties
```

Configuration par défaut :

```properties
multiplier=2.0
```

Exemples :

| Valeur | Résultat |
|---:|---|
| `1.0` | Vie vanilla |
| `1.5` | +50 % de vie |
| `2.0` | Vie doublée |
| `3.0` | Vie triplée |

La valeur autorisée est comprise entre `1.0` et `1000.0`.

## Commandes

Les commandes nécessitent le niveau de permission OP 2 :

```text
/mobhealth
/mobhealth get
/mobhealth set <multiplicateur>
/mobhealth reload
/mobhealth apply
/mobhealth config
```

### Détail

- `/mobhealth` ou `/mobhealth get` : affiche le multiplicateur actif.
- `/mobhealth set 1.5` : enregistre la nouvelle valeur et l'applique immédiatement aux mobs hostiles chargés.
- `/mobhealth reload` : relit le fichier de configuration et applique la valeur sans redémarrer.
- `/mobhealth apply` : réapplique le multiplicateur actuel aux mobs hostiles suivis.
- `/mobhealth config` : affiche le chemin absolu du fichier de configuration.

Lorsque le multiplicateur change, le mod conserve le **pourcentage de vie actuel** du mob.

Exemple : un mob à 50 % de sa vie restera à 50 % après le changement du multiplicateur.

## Sécurité contre le cumul

Le mod utilise un UUID fixe pour son modificateur de vie. L'ancien modificateur est supprimé avant l'application du nouveau, ce qui empêche la vie de se multiplier plusieurs fois lors d'un changement de dimension ou d'un rechargement.

## Compilation

Le projet contient un système de compilation autonome basé sur Java 17 et des stubs de l'API Forge/Minecraft.

Sous Linux :

```bash
chmod +x build.sh test.sh
./build.sh
```

Le JAR est généré dans :

```text
build/hostile-mob-health-multiplier-1.0.3.jar
```

## Tests

```bash
./test.sh
```

Les tests vérifient notamment :

- la création du fichier de configuration ;
- l'application aux mobs hostiles ;
- l'absence de cumul ;
- l'exclusion des joueurs et mobs passifs ;
- les commandes `get`, `set`, `reload`, `apply` et `config` ;
- le refus des commandes pour un joueur non OP.

## Licence

Projet distribué sous licence [MIT](LICENSE).
