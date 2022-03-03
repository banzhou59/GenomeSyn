$Env:CONDA_EXE = "/home/zwzhou/test_GenomeSyn.2022.1.27/localperl_miniconda/GenomeSyn-1.2.3/miniconda3/bin/conda"
$Env:_CE_M = ""
$Env:_CE_CONDA = ""
$Env:_CONDA_ROOT = "/home/zwzhou/test_GenomeSyn.2022.1.27/localperl_miniconda/GenomeSyn-1.2.3/miniconda3"
$Env:_CONDA_EXE = "/home/zwzhou/test_GenomeSyn.2022.1.27/localperl_miniconda/GenomeSyn-1.2.3/miniconda3/bin/conda"
$CondaModuleArgs = @{ChangePs1 = $True}

Import-Module "$Env:_CONDA_ROOT\shell\condabin\Conda.psm1" -ArgumentList $CondaModuleArgs
Remove-Variable CondaModuleArgs