#!/bin/csh -f

source config/experiment.csh
source config/filestructure.csh
source config/tools.csh
source config/mpas/${MPASGridDescriptor}/mesh.csh


####################
## static data files
####################
## common directories
set ModelData = /glade/p/mmm/parc/guerrett/pandac/fixed_input
set OuterModelData = ${ModelData}/${MPASGridDescriptorOuter}
set InnerModelData = ${ModelData}/${MPASGridDescriptorInner}
set EnsembleModelData = ${ModelData}/${MPASGridDescriptorEnsemble}

set GFSAnaDirOuter = ${OuterModelData}/GFSAna
set GFSAnaDirInner = ${InnerModelData}/GFSAna
set GFSAnaDirEnsemble = ${EnsembleModelData}/GFSAna

## GFS analyses for model-space verification
setenv GFSAnaDirVerify ${GFSAnaDirOuter}

## file date for first background
set yy = `echo ${FirstCycleDate} | cut -c 1-4`
set mm = `echo ${FirstCycleDate} | cut -c 5-6`
set dd = `echo ${FirstCycleDate} | cut -c 7-8`
set hh = `echo ${FirstCycleDate} | cut -c 9-10`
setenv FirstFileDate ${yy}-${mm}-${dd}_${hh}.00.00

## date from which first background is initialized
set prevFirstCycleDate = `$advanceCYMDH ${FirstCycleDate} -${CyclingWindowHR}`
setenv prevFirstCycleDate ${prevFirstCycleDate}
set yy = `echo ${prevFirstCycleDate} | cut -c 1-4`
set mm = `echo ${prevFirstCycleDate} | cut -c 5-6`
set dd = `echo ${prevFirstCycleDate} | cut -c 7-8`
set hh = `echo ${prevFirstCycleDate} | cut -c 9-10`
set prevFirstFileDate = ${yy}-${mm}-${dd}_${hh}.00.00
setenv NMLFirstFileDate ${yy}-${mm}-${dd}_${hh}:00:00

# externally sourced model states
# -------------------------------
## deterministic - GFS
setenv GFS6hfcFORFirstCycleOuter ${OuterModelData}/SingleFCFirstCycle/${prevFirstCycleDate}
setenv GFS6hfcFORFirstCycleInner ${InnerModelData}/SingleFCFirstCycle/${prevFirstCycleDate}

# first cycle background state
setenv firstDetermFCDirOuter ${GFS6hfcFORFirstCycleOuter}
setenv firstDetermFCDirInner ${GFS6hfcFORFirstCycleInner}

## stochastic - GEFS
set gefsMemFmt = "/{:02d}"
set nGEFSMembers = 20
set GEFS6hfcFOREnsBDir = ${EnsembleModelData}/EnsForCov
set GEFS6hfcFOREnsBFilePrefix = EnsForCov
set GEFS6hfcFORFirstCycle = ${EnsembleModelData}/EnsFCFirstCycle/${prevFirstCycleDate}

# first cycle background states
# TODO: determine firstEnsFCNMembers from source data
setenv firstEnsFCNMembers 80
setenv firstEnsFCDir ${GEFS6hfcFORFirstCycle}
if ( $nEnsDAMembers > $firstEnsFCNMembers ) then
  echo "WARNING: nEnsDAMembers must be <= firstEnsFCNMembers, changing ensemble size"
  setenv nEnsDAMembers ${firstEnsFCNMembers}
endif


if ( "$DAType" =~ *"eda"* ) then
  setenv firstFCMemFmt "${gefsMemFmt}"
  setenv firstFCDirOuter ${firstEnsFCDir}
  setenv firstFCDirInner ${firstEnsFCDir}
  setenv firstFCFilePrefix ${FCFilePrefix}
else
  setenv firstFCMemFmt " "
  setenv firstFCDirOuter ${firstDetermFCDirOuter}
  setenv firstFCDirInner ${firstDetermFCDirInner}
  setenv firstFCFilePrefix ${FCFilePrefix}
endif

# background covariance
# ---------------------
## stochastic analysis (dynamic directory structure, depends on $nEnsDAMembers)
set dynamicEnsBMemFmt = "${flowMemFmt}"
set dynamicEnsBFilePrefix = ${FCFilePrefix}

## select the ensPb settings based on DAType
if ( "$DAType" =~ *"eda"* ) then
  set dynamicEnsBNMembers = ${nEnsDAMembers}
  set dynamicEnsBDir = ${CyclingFCWorkDir}

  setenv ensPbDir ${dynamicEnsBDir}
  setenv ensPbFilePrefix ${dynamicEnsBFilePrefix}
  setenv ensPbMemFmt "${dynamicEnsBMemFmt}"
  setenv ensPbNMembers ${dynamicEnsBNMembers}
else
  ## deterministic analysis (static directory structure)
  # parse selections
  if ("$fixedEnsBType" == "GEFS") then
    set fixedEnsBMemFmt = "${gefsMemFmt}"
    set fixedEnsBNMembers = ${nGEFSMembers}
    set fixedEnsBDir = ${GEFS6hfcFOREnsBDir}
    set fixedEnsBFilePrefix = ${GEFS6hfcFOREnsBFilePrefix}
  else if ("$fixedEnsBType" == "PreviousEDA") then
    set fixedEnsBMemFmt = "${dynamicEnsBMemFmt}"
    set fixedEnsBNMembers = ${nPreviousEnsDAMembers}
    set fixedEnsBDir = ${PreviousEDAForecastDir}
    set fixedEnsBFilePrefix = ${dynamicEnsBFilePrefix}
  else
    echo "ERROR in $0 : unrecognized value for fixedEnsBType --> ${fixedEnsBType}" >> ./FAIL
    exit 1
  endif

  setenv ensPbDir ${fixedEnsBDir}
  setenv ensPbFilePrefix ${fixedEnsBFilePrefix}
  setenv ensPbMemFmt "${fixedEnsBMemFmt}"
  setenv ensPbNMembers ${fixedEnsBNMembers}
endif


# MPAS-Model
# ----------
## directory containing x1.${MPASnCells}.graph.info* files
setenv GraphInfoDir /glade/work/duda/static_moved_to_campaign

## sea/ocean surface files
setenv updateSea 1
setenv seaMaxMembers ${nGEFSMembers}
setenv SeaFilePrefix x1.${MPASnCellsOuter}.sfc_update
setenv deterministicSeaAnaDir ${GFSAnaDirOuter}
if ( "$DAType" =~ *"eda"* ) then
  # using member-specific sst/xice data from GEFS
  # 60km and 120km
  setenv SeaAnaDir ${ModelData}/GEFS/surface/000hr/${forecastPrecision}
  setenv seaMemFmt "${gefsMemFmt}"
else
  # deterministic
  # 60km and 120km
  setenv SeaAnaDir ${deterministicSeaAnaDir}
  setenv seaMemFmt " "
endif

## static stream data
if ( "$DAType" =~ *"eda"* ) then
  # stochastic
  # 60km and 120km
  setenv StaticFieldsDirOuter ${ModelData}/GEFS/init/000hr/${prevFirstCycleDate}
  setenv StaticFieldsDirInner ${ModelData}/GEFS/init/000hr/${prevFirstCycleDate}
  setenv StaticFieldsDirEnsemble ${ModelData}/GEFS/init/000hr/${prevFirstCycleDate}
  setenv staticMemFmt "${gefsMemFmt}"

  #TODO: switch to using FirstFileDate static files for GEFS
  setenv StaticFieldsFileOuter ${InitFilePrefixOuter}.${prevFirstFileDate}.nc
  setenv StaticFieldsFileInner ${InitFilePrefixInner}.${prevFirstFileDate}.nc
  setenv StaticFieldsFileEnsemble ${InitFilePrefixEnsemble}.${prevFirstFileDate}.nc
else
  # deterministic
  # 30km, 60km, and 120km
  setenv StaticFieldsDirOuter ${GFSAnaDirOuter}
  setenv StaticFieldsDirInner ${GFSAnaDirInner}
  setenv StaticFieldsDirEnsemble ${GFSAnaDirEnsemble}
  setenv staticMemFmt " "
  setenv StaticFieldsFileOuter ${InitFilePrefixOuter}.${FirstFileDate}.nc
  setenv StaticFieldsFileInner ${InitFilePrefixInner}.${FirstFileDate}.nc
  setenv StaticFieldsFileEnsemble ${InitFilePrefixEnsemble}.${FirstFileDate}.nc
  setenv InitialStaticFieldsFileOuter ${InitFilePrefixOuter}.${prevFirstFileDate}.nc  
endif
