# ASL Processing Pipeline — PROACT Study

This repository contains the scripts used to process **Arterial Spin Labeling (ASL)** neuroimaging data from the PROACT study. The pipeline calculates quantitative cerebral blood flow (CBF), registers images to MNI standard space, and performs group-level statistical analysis comparing pain vs. rest task conditions across pre- and post-intervention sessions.

---

## Software Requirements

| Tool | Purpose |
|---|---|
| **FSL** | Motion correction (mcflirt), registration (flirt), brain extraction (bet), smoothing |
| **ANTs** | Nonlinear T1→MNI registration (antsRegistrationSyN.sh, antsApplyTransforms) |
| **MATLAB** + SPM8 + ASL Toolbox | Quantitative CBF calculation (asl_perf_subtract) |
| **Python 3** + nibabel, numpy, scipy, pandas, statsmodels | Image flipping, cluster statistics, permutation testing |

---

## Pipeline Workflow

Scripts are numbered in execution order. Steps that can run in parallel share the same number (e.g., `02a` and `02b` are alternatives; choose one). **Steps 08 and 10 (laterality flipping) are optional** and only needed if correcting for hemispheric asymmetry in a subset of subjects.

```
PHASE 1 — Data Setup & Registration (can run steps 01 and 02 in parallel)
│
├── 01_generate_asl_scripts.sh
│       Reads subjects.txt and generates 16 per-run SBATCH job scripts
│       (2 sessions × 2 conditions × 4 runs). Each generated script copies
│       raw ASL/T1w/tissue segmentation data, runs mcflirt motion correction,
│       flirt registration, and bet brain extraction.
│       OUTPUT: asl_setup_full_{session}_{condition}_{run}.sh scripts
│
├── 02a_create_ants_registration_scripts.sh   [HPC batch approach — recommended]
│       Reads subjects.txt and generates per-subject SBATCH scripts that register
│       T1w to MNI152 template using ANTs SyN registration.
│       OUTPUT: run_antsRegistrationSyN_{subj}.sh scripts (submit with sbatch)
│
└── 02b_proact_T1_to_MNI_ANTs.sh             [Direct-run alternative to 02a]
        Finds all T1.nii.gz files and runs antsRegistrationSyN.sh directly
        (non-batched). Use instead of 02a for small datasets or interactive jobs.
        OUTPUT: T12MNI/sub-{id}/sub-{id}_ses-{session}_0GenericAffine.mat
                T12MNI/sub-{id}/sub-{id}_ses-{session}_1Warp.nii.gz

PHASE 2 — Perfusion Calculation
│
├── 03_perfCalc_prep.sh
│       Validates motion-corrected ASL files (*_GMWM2ASL_mcf_brain.nii.gz).
│       Checks that each 4D file has exactly 52 volumes. Creates file_list.txt
│       and bad_files.txt in each session/task/run directory.
│       OUTPUT: file_list.txt (passed to MATLAB), bad_files.txt
│
├── 04_Postmcflirt_PerfusionCalculation.m    [Base parameters — run this first]
├── 04a_Postmcflirt_PerfusionCalculation_4000.m  \
├── 04b_Postmcflirt_PerfusionCalculation_4040.m   > Alternate arterial transit
└── 04c_Postmcflirt_PerfusionCalculation_4200.m  /  time parameter variants
        MATLAB scripts that read the file lists from step 03, extract individual
        3D volumes, and call asl_perf_subtract() to compute quantitative CBF
        (lambda=0.85, GM/WM segmentation-weighted). The _4000/_4040/_4200 variants
        use different bolus duration parameters; run only the one that matches your
        acquisition protocol.
        OUTPUT: meanCBF_0_sub-*_GMWM2ASL_mcf_brain.nii images

PHASE 3 — Thresholding
│
├── 05a_postPerf_thr.sh          [All subjects]
│       Applies physiologically valid intensity thresholds to CBF images
│       (lower: −85, upper: 130 ml/100g/min) using fslmaths.
│       OUTPUT: *_thr-130.nii images
│
└── 05b_postPerf_thr40404000.sh  [Subject subset — QC/sensitivity check]
        Same thresholding as 05a but restricted to 7 specific subject IDs
        (2001–2005, 2008, 2009). Use for targeted reprocessing only.

PHASE 4 — Spatial Normalization & Smoothing
│
└── 06_new_asl2mniSmooth.sh
        DEPENDS ON: 02a/02b outputs (T12MNI transforms) + 05a outputs (CBF images)
        Applies a two-step registration:
          1. Linear: ASL space → T1 space (flirt, using mcflirt motion matrix)
          2. Nonlinear: T1 space → MNI space (antsApplyTransforms, affine + warp)
        Smooths the result with a 3.82mm FWHM Gaussian kernel (SmoothImage).
        OUTPUT: *_2MNI_9FWHM.nii.gz  (smoothed CBF in MNI space)

PHASE 5 — Subject-Level Averaging
│
├── 07_asl_average.sh
│       Merges runs 1–4 per subject/session/task (fslmerge) and computes
│       mean CBF across runs (fslmaths -Tmean).
│       OUTPUT: Mean CBF image per subject/session/task in asl2mniSmAvg/
│
└── 08_flip_meanCBF2mniSmoothed.py  [OPTIONAL — laterality correction]
        Flips images along the x-axis (left↔right) for 127 specified subjects
        (e.g., left-handed or dominant-hemisphere-adjusted subjects). Copies
        unflipped images for all other subjects.
        OUTPUT: Flipped/copied images in asl2mniSmoothed_flipped/

PHASE 6 — Group-Level Contrasts
│
├── 09_merge_tasks.sh
│       DEPENDS ON: 07 outputs
│       Creates pain-minus-rest and rest-minus-pain contrast maps per subject,
│       merges valid subjects into 4D group images, and applies a brain mask.
│       OUTPUT: all_ses-{pre|post}_task-{pain-rest|rest-pain}_sub.nii.gz
│
└── 10_flip-copy_asl2mniSmSub.py   [OPTIONAL — laterality correction on contrasts]
        Same flipping logic as step 08, applied to individual difference maps
        from step 09.
        OUTPUT: Flipped difference maps in asl2mniSmAvgSub_flipped/,
                asl2mniSmAvgSubTaskRest_flipped/

PHASE 7 — Statistical Thresholding & Clustering
│       (assumes FSL randomise or similar has already produced t-stat maps)
│
└── 11_thr_cluster.py
        Thresholds t-statistic maps at t ≥ 3.09, labels contiguous clusters,
        runs 1000-iteration permutation test to generate null cluster-size
        distribution (smoothing σ = 3.82mm), computes cluster-level p-values,
        applies FDR correction (α = 0.05), and outputs only surviving clusters.
        OUTPUT: *_thr.nii.gz, *_clusters.nii.gz

PHASE 8 — ROI Statistics Extraction (choose one or both)
│
├── 12a_cluster_stats.py
│       Loads cluster masks, identifies individual 3D clusters using 26-connected
│       component labeling (scipy.ndimage), computes center-of-mass in MNI
│       coordinates, and extracts mean/std CBF per cluster per subject.
│       OUTPUT: asl_cluster_statistics_flipped.csv
│
└── 12b_asl_2cluster_stats.py
        Simpler alternative: loads two binary cluster masks (pain-rest,
        rest-pain), overlays on smoothed CBF images, and extracts mean/std
        per mask per subject/session/task/run.
        OUTPUT: asl_activation_deactivation_cluster_statistics.csv
```

---

## Input Data Layout

All processing paths are currently hardcoded to the UFL HPC system under `/blue/jjtanner/shared/proact/`. The expected input layout is:

```
/blue/jjtanner/shared/proact/dcm2bids/
├── {subject_id}/{session}/perf/          Raw ASL NIfTI files
└── derivatives/fmriprep/
    └── sub-{id}/ses-{session}/anat/      T1w, brain mask, tissue segmentations
```

---

## Automation Suggestions

The pipeline currently consists of manually submitted individual scripts. Below are suggestions for improving automation, reproducibility, and portability.

### 1. Replace hardcoded paths with a configuration file

All scripts reference `/blue/jjtanner/shared/proact/` directly. Extract all root paths, subject list location, and parameter values into a single `config.sh` (or `config.env`) file and source it at the top of each script. This makes the pipeline portable across users and HPC systems with a one-line change.

```sh
# config.sh
ROOT=/blue/jjtanner/shared/proact/dcm2bids
DERIV=$ROOT/derivatives/asl
SUBJECTS_FILE=$DERIV/subjects.txt
FWHM=3.82
```

### 2. Add a master pipeline runner script

Create a single `run_pipeline.sh` that calls each numbered step in order, waits for SLURM array jobs to finish (using `--dependency=afterok`), and logs each stage. This turns the 12-step manual process into a single command.

```sh
JID1=$(sbatch --parsable 01_generate_asl_scripts.sh)
JID2=$(sbatch --parsable --dependency=afterok:$JID1 02a_create_ants_registration_scripts.sh)
# ...
```

### 3. Convert MATLAB perfusion scripts to a parameterized function

The four `Postmcflirt_PerfusionCalculation*.m` scripts are nearly identical, differing only in a handful of parameters (bolus duration, session/run identifiers). Consolidate them into a single function that accepts parameters as arguments, then call it from a wrapper that reads from `config.sh` or a CSV parameter table. This eliminates ~3,000 lines of duplicated code.

### 4. Add a subjects.txt-driven SLURM job array

Scripts like `01_generate_asl_scripts.sh` and `02a_create_ants_registration_scripts.sh` loop over subjects and generate many individual scripts. Replace this pattern with a single SLURM job array (`#SBATCH --array=1-N`) where each task reads its subject ID from `subjects.txt` using `$SLURM_ARRAY_TASK_ID`. This is simpler, avoids 100+ generated script files, and gives better cluster utilization.

### 5. Wrap the Python environment in a requirements file and conda/venv

Create a `requirements.txt` (or `environment.yml` for conda) listing nibabel, numpy, scipy, pandas, and statsmodels with pinned versions. Add a brief setup section to this README. This ensures reproducibility across machines and removes silent dependency failures.

```
nibabel>=3.2
numpy>=1.21
scipy>=1.7
pandas>=1.3
statsmodels>=0.13
```

### 6. Add quality-control checkpoints between phases

Insert lightweight QC scripts between phases that verify expected outputs exist and pass basic sanity checks (correct number of volumes, non-zero voxel count, file size thresholds) before the next phase begins. On failure, the pipeline should log the offending subject and skip rather than silently propagate bad data.

### 7. Separate the laterality-correction subjects list into a data file

The 127 subject IDs hardcoded inside `08_flip_meanCBF2mniSmoothed.py` and `10_flip-copy_asl2mniSmSub.py` should be stored in a dedicated `flip_subjects.txt` file that both scripts read at runtime. This avoids editing Python code when the flip list changes and makes the decision auditable.

### 8. Consider a workflow manager for complex dependency tracking

For long-term maintenance, a lightweight workflow manager such as **Snakemake** or **Nextflow** would replace the manual dependency chain with a declarative pipeline definition. Each rule/process maps inputs → outputs, and the manager handles re-running only stale steps, parallel execution, and cluster submission automatically. Snakemake integrates particularly well with SLURM and Python-based bioinformatics pipelines.
