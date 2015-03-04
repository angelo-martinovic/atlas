#!/bin/sh
if [ $# -ne 5 ]
then
    echo "Usage: `basename $0` fold imnumber set(eval/valid) dataweight gridweight"
  exit 1
fi

ulimit -v unlimited
ulimit -s unlimited
cd /users/visics/mmathias/devel/3layerJournal
./run_run_fold_image.sh /users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexa64:/software/matlab/current/ $1 $2 $3 $4 $5
 #mcc -m -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexa64' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexglx' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexmaci' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexmaci64' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexw32' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mex/mexw64' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/aib' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/demo' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/geometry' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/imop' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/kmeans'  -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/misc' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/mser' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/noprefix' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/plotop' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/quickshift' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/sift' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/slic' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/special' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/test' -I '/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox/xtest' -I '/users/visics/mmathias/sw/ssim' run_fold_image

