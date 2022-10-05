#!/bin/bash

#This script will recieve 4 input arguments and will output transformed ROI masks from MNI space into T1w subject space and save them in an output path. It will read the mask files and then perform the correct linear and non-linear registration from STD space to Subject Space.

##INPUT 1:  Full path to  raw structural T1w file that has gone through the necessary flywheel gear

#INPUT 2: Full path of the directory containing all masks that needs adjustment (in a 3D NIFTI format) - Preferrably in a 1mm , standard MNI space

#INPUT 3: A Full Path to the Brain Extracted template matching the space and dimentions of the input mask (input 2)

#INPUT 4: A Full path of the directory for output masks (will be saved in a 3D NIFTI format)
 # -----------------------------------------------Establishing file tags and setting up output. No registrations decisions made here ----------------------
T1=$1
ROI_DIR=$2
STD=$3
OUT=outputs
mkdir -p $OUT
OUT_DIR=$OUT/Targets
mkdir -p $OUT_DIR
SUB=$(basename "${T1}" | cut -d. -f1)
MASK_ADJ_DATA_DIR=MASK_TRANSFORM_DATA
mkdir -p $MASK_ADJ_DATA_DIR

#  -----------------------------------------------Cleaning the T1 and brain extracting it. Still not making a decision about which registration tool to use -----------------
#Brain extracting the T1
N4BiasFieldCorrection -d 3 -i ${T1} -o ${T1}
cp ${T1} ${OUT}/T1.nii
fsl5.0-bet ${T1} ${MASK_ADJ_DATA_DIR}/${SUB}_bet.nii.gz -f 0.25 -R -B

#  -----------------------------------------------Begin ANTs Registration Comment out if we are bailing on ANTs----------------------------------------------------

#Performing the initial Affine Registration with ANTs
antsRegistrationSyN.sh -d 3 -m ${MASK_ADJ_DATA_DIR}/${SUB}_bet.nii.gz -f $STD -o ${MASK_ADJ_DATA_DIR}/t1_to_MNI_aff_  -t a -r 2 -j 1

#Performing the non-linear registration with ANTs
antsRegistrationSyN.sh -d 3 -m ${MASK_ADJ_DATA_DIR}/t1_to_MNI_aff_Warped.nii.gz -f $STD -o ${MASK_ADJ_DATA_DIR}/t1_to_MNI_opt_  -t b -r 2 -j 1

#Applying the transformation to the masks with ANTs
echo Transforming masks...
for ROI in ${ROI_DIR}/*.nii.gz; do
MASK=$(basename "${ROI}" | cut -f 1 -d '.')
antsApplyTransforms -d 3 -r ${MASK_ADJ_DATA_DIR}/${SUB}_bet.nii.gz   -i $ROI   -o ${OUT_DIR}/NTV_${MASK}.nii.gz -n NearestNeighbor -t [${MASK_ADJ_DATA_DIR}/t1_to_MNI_aff_0GenericAffine.mat,1] -t [${MASK_ADJ_DATA_DIR}/t1_to_MNI_opt_0GenericAffine.mat,1]  -t ${MASK_ADJ_DATA_DIR}/t1_to_MNI_opt_1InverseWarp.nii.gz


#Binarizing the  Mask Output
fsl5.0-fslmaths ${OUT_DIR}/NTV_${MASK}.nii.gz  -bin ${OUT_DIR}/NTV_${MASK}.nii.gz
gunzip ${OUT_DIR}/*nii.gz


# -----------------------------------------------End of ANTs Registration. Do not remove the following command-----------------------------------------------

fsl5.0-fslstats -t ${OUT_DIR}/NTV_${MASK}.nii -c >  ${OUT_DIR}/NTV_${MASK}_CRD.txt
done
