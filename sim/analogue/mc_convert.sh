#!/bin/bash

spice_name=filter_out
octave_name=v_filter_out

for i in `find . | grep '\.raw'` ; do
    octave_file=`basename $i .raw`.octave
    octave_dir=`dirname $i`
    ../spice_to_octave $i $spice_name $octave_dir/$octave_file $octave_name
done
