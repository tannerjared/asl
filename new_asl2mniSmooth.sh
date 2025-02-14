#!/bin/bash
#SBATCH --job-name=asl2mniSmooth     # Job name
#SBATCH --mail-type=END,FAIL         # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=jjtanner@ufl.edu # Where to send mail
#SBATCH --ntasks=2                   # Run on 2 CPU cores
#SBATCH --mem=8gb                    # Job memory request
#SBATCH --time=72:00:00              # Time limit hrs:min:sec
#SBATCH --output=asl2mniSmooth_%j.log # Standard output/error log

# This script loops over all ASL NIfTI files and associated transformation files 
# to perform:
#   1. Copy necessary files (transformation matrices, mean CBF image, T1w image)
#   2. Invert the transformation matrix (ASL->T1w) [if needed]
#   3. Apply the transformation from ASL to T1w
#   4. Apply transforms to MNI space (using two-file transforms from T12MNI)
#   5. Smooth the final MNI-space image
#
# Before running, ensure:
#   - Directories and filenames follow consistent conventions
#   - FSL and ANTs are loaded (module load fsl, module load ants)
#   - 'tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz' is correct for your system

pwd; hostname; date

# ------------------------------------------------------------------------------
# Directories
# ------------------------------------------------------------------------------
BASE_DIR="/blue/jjtanner/shared/proact/dcm2bids/derivatives"
ASL_PROCESSED="${BASE_DIR}/asl/processed"
FMRIPREP_DIR="${BASE_DIR}/fmriprep"
ASL2ANAT_DIR="${ASL_PROCESSED}/asl2anat"
ASL2MNI_DIR="${ASL_PROCESSED}/asl2mni"
ASL2MNISM_DIR="${ASL_PROCESSED}/asl2mniSmoothed"

TEMPLATE="${BASE_DIR}/asl/processed/mniTemplate/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz"

mkdir -p "${ASL2ANAT_DIR}" "${ASL2MNI_DIR}" "${ASL2MNISM_DIR}"
mkdir -p "${ASL_PROCESSED}/logs"

PROCESSED_LOG="${ASL_PROCESSED}/logs/processed.log"
MISSING_CBF_LOG="${ASL_PROCESSED}/logs/missingCBF.log"
MISSING_FMRIPREP_LOG="${ASL_PROCESSED}/logs/missingfMRIprep.log"

module load ants
module load fsl

# ------------------------------------------------------------------------------
# Main loop: find all *_ASL2T1_mcf_brain.mat
# ------------------------------------------------------------------------------
find "${BASE_DIR}/asl" -type f -name "*_ASL2T1_mcf_brain.mat" | while read -r MCF_MAT; do

    FILENAME=$(basename "${MCF_MAT}")
    DIRNAME=$(dirname "${MCF_MAT}")

    # Extract Subject ID
    SUB=$(echo "${FILENAME}" | sed 's/.*sub-\([0-9]\+\).*/\1/')

    # Example parent dir: "ses-pre_task-REST_run-1"
    PARENT_DIR=$(basename "$(dirname "$(dirname "${DIRNAME}")")")

    # Extract session, task, run
    IFS=_ read -r SESPART TASKPART RUNPART <<< "$PARENT_DIR"
    SESSION="${SESPART#ses-}"     # 'pre' or 'post', typically
    TASK="${TASKPART#task-}"      # e.g. 'REST'
    RUN="${RUNPART#run-}"         # e.g. '1'

    # ------------------------------------------------------------------------------
    # Find meanCBF file
    # ------------------------------------------------------------------------------
    MEANCBF_FILE=$(find "${ASL_PROCESSED}" -type f \
        -name "meanCBF_0_sub-${SUB}_GMWM2ASL_mcf_brain_thr-130_ses-${SESSION}_task-${TASK}_run-${RUN}.nii.gz" \
        | head -n 1)

    if [ ! -f "${MEANCBF_FILE}" ]; then
        echo "meanCBF file not found for sub-${SUB}, ses-${SESSION}, task-${TASK}, run-${RUN}. Skipping..." \
            >> "${MISSING_CBF_LOG}"
        continue
    fi

    # ------------------------------------------------------------------------------
    # Attempt to find T1w file from fMRIPrep
    # (Same fallback logic as before: no session → ses-pre → ses-post)
    # ------------------------------------------------------------------------------
    T1W_FILE="${FMRIPREP_DIR}/sub-${SUB}/anat/sub-${SUB}_desc-preproc_T1w.nii.gz"
    if [ ! -f "${T1W_FILE}" ]; then
        # Try ses-pre
        T1W_FILE="${FMRIPREP_DIR}/sub-${SUB}/ses-pre/anat/sub-${SUB}_ses-pre_desc-preproc_T1w.nii.gz"
        if [ ! -f "${T1W_FILE}" ]; then
            # Try ses-post
            T1W_FILE="${FMRIPREP_DIR}/sub-${SUB}/ses-post/anat/sub-${SUB}_ses-post_desc-preproc_T1w.nii.gz"
            if [ ! -f "${T1W_FILE}" ]; then
                echo "T1w not found for sub-${SUB}. Skipping..." >> "${MISSING_FMRIPREP_LOG}"
                continue
            fi
        fi
    fi

    # ------------------------------------------------------------------------------
    # Identify which T1->MNI warp files to use from T12MNI/sub-XXXX
    # based on the session of the meanCBF. 
    # If ses-pre, prefer ses-pre transforms; else fallback to ses-post, etc.
    # ------------------------------------------------------------------------------
    WARP_DIR="/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/T12MNI/sub-${SUB}"
    AFFINE_FILE=""
    NL_WARP_FILE=""

    if [[ "${SESSION}" == "pre" ]]; then
        # Prefer ses-pre
        if [ -f "${WARP_DIR}/sub-${SUB}_ses-pre_0GenericAffine.mat" ] && \
           [ -f "${WARP_DIR}/sub-${SUB}_ses-pre_1Warp.nii.gz" ]; then

            AFFINE_FILE="${WARP_DIR}/sub-${SUB}_ses-pre_0GenericAffine.mat"
            NL_WARP_FILE="${WARP_DIR}/sub-${SUB}_ses-pre_1Warp.nii.gz"
        else
            # Fallback: ses-post
            if [ -f "${WARP_DIR}/sub-${SUB}_ses-post_0GenericAffine.mat" ] && \
               [ -f "${WARP_DIR}/sub-${SUB}_ses-post_1Warp.nii.gz" ]; then

                AFFINE_FILE="${WARP_DIR}/sub-${SUB}_ses-post_0GenericAffine.mat"
                NL_WARP_FILE="${WARP_DIR}/sub-${SUB}_ses-post_1Warp.nii.gz"
            else
                echo "No valid warp files for sub-${SUB}, ses-pre → fallback ses-post. Skipping..."
                echo "sub-${SUB}, session-${SESSION} missing warp" >> "${MISSING_FMRIPREP_LOG}"
                continue
            fi
        fi
    else
        # If session is 'post' (or anything else), prefer ses-post
        if [ -f "${WARP_DIR}/sub-${SUB}_ses-post_0GenericAffine.mat" ] && \
           [ -f "${WARP_DIR}/sub-${SUB}_ses-post_1Warp.nii.gz" ]; then

            AFFINE_FILE="${WARP_DIR}/sub-${SUB}_ses-post_0GenericAffine.mat"
            NL_WARP_FILE="${WARP_DIR}/sub-${SUB}_ses-post_1Warp.nii.gz"
        else
            # Fallback: ses-pre
            if [ -f "${WARP_DIR}/sub-${SUB}_ses-pre_0GenericAffine.mat" ] && \
               [ -f "${WARP_DIR}/sub-${SUB}_ses-pre_1Warp.nii.gz" ]; then

                AFFINE_FILE="${WARP_DIR}/sub-${SUB}_ses-pre_0GenericAffine.mat"
                NL_WARP_FILE="${WARP_DIR}/sub-${SUB}_ses-pre_1Warp.nii.gz"
            else
                echo "No valid warp files for sub-${SUB}, ses-post → fallback ses-pre. Skipping..."
                echo "sub-${SUB}, session-${SESSION} missing warp" >> "${MISSING_FMRIPREP_LOG}"
                continue
            fi
        fi
    fi

    # ------------------------------------------------------------------------------
    # Copy needed files into ASL2ANAT_DIR
    # ------------------------------------------------------------------------------
    ASL2T1W_MAT="${ASL2ANAT_DIR}/sub-${SUB}_ASL2T1_mcf_ses-${SESSION}_task-${TASK}_run-${RUN}.mat"
    cp "${MCF_MAT}" "${ASL2T1W_MAT}"

    cp "${MEANCBF_FILE}" "${ASL2ANAT_DIR}/"
    cp "${T1W_FILE}" "${ASL2ANAT_DIR}/"

    # Optional: copy the chosen transforms to ASL2ANAT_DIR if you want them local
    cp "${AFFINE_FILE}" "${ASL2ANAT_DIR}/"
    cp "${NL_WARP_FILE}" "${ASL2ANAT_DIR}/"

    # ------------------------------------------------------------------------------
    # ASL -> T1 (linear)
    # ------------------------------------------------------------------------------
    cd "${ASL2ANAT_DIR}" || exit 1

    MEANCBF_BASENAME=$(basename "${MEANCBF_FILE}")
    OUT_ASL2T1W="${MEANCBF_BASENAME%.nii.gz}_2T1w.nii.gz"

    T1W_BASENAME=$(basename "${T1W_FILE}")

    flirt -in "${MEANCBF_BASENAME}" \
          -ref "${T1W_BASENAME}" \
          -applyxfm -init "${ASL2T1W_MAT}" \
          -out "${OUT_ASL2T1W}" \
          -dof 6

    # ------------------------------------------------------------------------------
    # T1 -> MNI (nonlinear), combining affine + warp with ANTs
    # ------------------------------------------------------------------------------
    cd "${ASL2MNI_DIR}" || exit 1
    cp "${ASL2ANAT_DIR}/${OUT_ASL2T1W}" .

    OUT_MNI="${OUT_ASL2T1W%.nii.gz}_2MNI.nii.gz"

    antsApplyTransforms -d 3 \
        -i "${OUT_ASL2T1W}" \
        -r "${TEMPLATE}" \
        -t "${AFFINE_FILE}" \
        -t "${NL_WARP_FILE}" \
        -n Linear \
        -o "${OUT_MNI}"

    # ------------------------------------------------------------------------------
    # Smooth final MNI image
    # ------------------------------------------------------------------------------
    cd "${ASL2MNISM_DIR}" || exit 1
    SmoothImage 3 "${ASL2MNI_DIR}/${OUT_MNI}" 3.82 \
        "${ASL2MNISM_DIR}/${OUT_MNI%.nii.gz}_9FWHM.nii.gz"

    # ------------------------------------------------------------------------------
    # Done for this subject/run
    # ------------------------------------------------------------------------------
    echo "Processed sub-${SUB}, ses-${SESSION}, task-${TASK}, run-${RUN}" >> "${PROCESSED_LOG}"

done
