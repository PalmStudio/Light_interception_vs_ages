# Ligth interception for increasing ages

This project aims at comparing the light interception of palm trees of different ages in a regular quincunx planting design.

## Building OPFs

The OPFs were built using VPALM for ~9, 12, 24, 36, 48, 60, 72, 84 months after planting (MAP) for an average palm tree from the DA1 progeny. The 9, 12 and 24 MAP palm trees were built using parameter files from the thesis of Raphael Perez (Perez, 2014). These files were a little bit modified for the new version of VPALM (`H0` was put to 0, and `residStemHeight` at ~0.92). The other MAPs were built using the field data from SMSE that are included in VPALM-IDE.

The parameter files from the thesis of R. Perez are named according to the number of leaves emitted since plantation, but their corresponding OPFs were named according to their MAP (or an estimation of it). So 22, 30 and 60 leaves emitted corresponds to 9, 12 and 24 MAP.

To build OPF files from text files, use this command:

```bash
java -jar .\vpalm.jar <input text file> <desired output OPF name>
```
For example to build the `DA1_AverageTree_30LeavesEmitted.txt` palm tree, we would use this command:

```bash
java -jar .\vpalm.jar DA1_AverageTree_30LeavesEmitted.txt DA1_AverageTree_MAP_12.opf
```

## Building the scene

The scene was taken as a regular East-West oriented quincunx planting design from the PLPE project (see `Control_EW_MAP_44.ops` in this project). The scene is reduced to two palm trees simulated using the toricity option from ARCHIMED to replicate the design infinitely. A single OPS file was built for each simulated age using one OPF replicated twice (two palms in the scene).
