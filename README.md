# video_montage.m

Authors: Billy Rowell <william.rowell@gmail.com>

MATLAB script takes a folder of movies with uniform dimensions (including 
framerate) and returns a tiled, labelled montage video with a key file.
Videos are decimated to save space, but output video is as close to the 
original framerate as possible (unless the framerate is very low, <4 fps). 
