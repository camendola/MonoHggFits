#!/bin/bash

## version=full_analysis_anv1_v19
version=$1 && shift

fitname=cic 
www=~/www/plotsMonoH
   
shapes="default_shapes"
default_model=""

opts=""
input_opts=""
data_version=""
while [[ -n $1 ]]; do
    case $1 in
	--fit-name)
	    fitname=$2
	    shift
	    ;;
	--www)
	    www=$2
	    shift
	    ;;
	--verbose)
	    verbose="--verbose"
	    opts="$opts --verbose"
	    ;;
	--redo-input)
	    rerun="1"
	    ;;
	--label)
	    addlabel=$2
	    shift
	    ;;
	--use-templates)
	    templates="semiparam"
	    opts="$opts $1"
	    ;;
        --mix-templates)
            mix="--mix-templates"
            ;;
	--bkg-shapes)
	    shapes=$(echo $(basename $2 | sed 's%.json%%'))
	    opts="$opts $1 $2"
	    shift
	    ;;
	--default-model)
	    default_model=$2
	    opts="$opts $1 $2"
	    shift
	    ;;
	--use-templates)
	    templates="use_templates"
	    opts="$opts $1"
	    ;;
	--mix-templates)
	    mix="--mix-templates"
	    ;;
	--nuisance-fractions-covariance)
	    covariance=$(echo $(basename $2 | sed 's%.json%%'))
	    opts="$opts $1"
	    ;;
	--generate-ws-bkgnbias)
	    spurious="bias";
	    opts="$opts $1"
	    ;;
	--fwhm-input-file)
	    fwhm="$2"
	    opts="$opts $1"
	    ;;
	--only-coup*)
	    log_label="${log_label}$(echo $2 | tr ',' '_')"
	    opts="$opts $1 $2"
	    shift
	    ;;
	--lumi*)
	    lumi=$2
	    shift
	    ;;
	--data-file)
	    input_opts="$input_opts $1 $2"
	    data_version="$(basename $(dirname $2))"
	    shift
	    ;;
	--*-file)
	    input_opts="$input_opts $1 $2"
	    shift
	    ;;
	--fit-background)
	    just_fit_bkg="1"
	    ;;
	*)
	    opts="$opts $1"
	    ;;	    
    esac
    shift
done
shift

echo $version $lumi

if [[ -z $version ]] || [[ -z $lumi ]]; then
    echo "usage: $0 <analysis_version> --lumi <lumi> [run_options]"
    exit 0
fi

input_folder=$version

[[ -n $data_version ]] && version=$data_version

label="$shapes"
[[ -n $default_model ]] && label="${label}_${default_model}"
[[ -n $covariance ]] && label="${label}_${covariance}"
[[ -n $templates ]] && label="${label}_${templates}"
[[ -n $bias ]] && label="${label}_${bias}"
[[ -n $templates ]] && label="${label}_${templates}"
[[ -n $addlabel ]] && label="${label}_${addlabel}"

input=${version}_${fitname}_final_ws_MonoHgg.root
input_log=${version}_${fitname}_final_ws_MonoHgg.log
treesdir=test/
## ls $treesdir/$version
ls $treesdir/$input_folder
[[ ! -d $treesdir/$input_folder ]] && treesdir=$PWD
workdir=${version}_${fitname}_${label}_lumi_${lumi}

if [[ -n $bias ]]; then
    if [[ -z $fwhm ]]; then
	opts="--compute-fwhm"
    fi
fi

mkdir $workdir

mkdir $www/$version

set -x
if [[ -n $rerun  ]] || [[ ! -f $input ]]; then
    echo "**************************************************************************************************************************"
    echo "creating $input"
    echo "**************************************************************************************************************************"
    subset=$fitname
    if [[ "$fitname" == "2D" ]]; then
        subset="2D,singlePho"
        mix="--mix-templates"
    fi
    ./templates_maker_MonoHgg.py --load templates_maker_MonoHgg.json,templates_maker_prepare_MonoHgg.json --only-subset $subset $mix --input-dir $treesdir/$input_folder -o $input $verbose $input_opts 2>&1 | tee $input_log
    echo "**************************************************************************************************************************"
elif [[ -n $mix ]]; then
    echo "**************************************************************************************************************************"
    echo "running event mixing"
    echo "**************************************************************************************************************************"    
    ./templates_maker_MonoHgg.py --load templates_maker_prepare_MonoHgg.json --read-ws $input $mix $verbose 2>&1 | tee mix_$input_log
    echo "**************************************************************************************************************************"
fi


echo "**************************************************************************************************************************"
echo "running model creation"
echo "**************************************************************************************************************************"

if [[ -n $just_fit_bkg ]]; then #commented by livia DEC28
echo "------------------------------------------*******************---------------------------------------------------------"
    ##--binned-data-in-datacard \
./combine_maker_MonoHgg.py \
    --fit-name $fitname  --luminosity $lumi  --lumi $lumi \
    --fit-background \
    --plot-blind-data \
    --generate-signal \
    --generate-Higgs-dataset \
    --read-ws $input \
    --ws-dir $workdir \
    -O $www/$version/$workdir \
    -o ${workdir}_MonoHgg.root  \
    --cardname datacard_${workdir}_MonoHgg.txt $opts 2>&1 | tee $workdir/combine_maker${log_label}_MonoHgg.log
else
./combine_maker_MonoHgg.py \
    --fit-name $fitname  --luminosity $lumi  --lumi $lumi \
    --fit-background \
    --generate-signal \
    --generate-Higgs-dataset \
    --generate-datacard \
    --read-ws $input \
    --ws-dir $workdir \
    -O $www/$version/$workdir \
    -o ${workdir}_MonoHgg.root  \
    --cardname datacard_${workdir}_MonoHgg.txt $opts 2>&1 | tee $workdir/combine_maker${log_label}_MonoHgg.log
fi

echo "**************************************************************************************************************************"
#    --generate-Higgs-dataset \
#    
