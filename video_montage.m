%% SET UP

% I make a lot of assumptions here:  1) you want to tile all of the videos
% in the folder you choose (*.avi), 2) your videos have uniform dimensions, 3) your
% videos have uniform frame rate, 4) the tiled size you chose will fit on
% your display, 5) your videos are uncompressed AVI and you want to oupput
% compressed AVI, 6) you want the output video to be played as close to
% realtime as possible

% Add to path
addpath(genpath(pwd));

% Get datestamp
now_str = datestr(now,30);

% Set the directory
path = uigetdir %#ok<NOPTS>
cd(path);

% Get a listing of avi files
filetype = 'avi' %#ok<NOPTS>
ls(['*.' filetype])
contents = dir(fullfile(path,['*.' filetype]));

% Define the row length and max row number for output
columns = 4;
rows = 1;
sets = ceil(length(contents)/(rows*columns));

% Define the start and end time in seconds
start_time = 1;
end_time = 900;

% Define the decimation rate... only use every Nth frame
decimation = 5;

%% CREATE VIDEOS
% For each set of row_length*max_row videos
for set_index = 1:sets
    
    % Open video objects
    movies = [];
    max_length = rows*columns;
    if set_index == sets && mod(length(contents),rows*columns) > 0
        max_length = mod(length(contents),rows*columns);
    end
    for file_index = 1:max_length
        [~, sourcename, ext] = fileparts(contents(file_index+(set_index-1)*columns*rows).name);
        movies(file_index).sourcename = sourcename;
        movies(file_index).ext = ext;
        movies(file_index).reader = VideoReader([sourcename ext]);
    end

    % Create output video object and open
    vidObj = VideoWriter(['montage' num2str(set_index) '_' now_str '.mp4'],'MPEG-4');
    native_framerate = movies(1).reader.FrameRate/decimation;
    if native_framerate < 4 % VLC can't play videos with very low framerates
        vidObj.FrameRate = 4; % so we set the framerate to 4 fps if lower than 4
    else
        vidObj.FrameRate = native_framerate; % otherwise we adjust to play in realtime
    end
    open(vidObj);

    % Calculate start and end frames using start and end times from above.
    % If end_time is greater than the length of the video, use the end of
    % the video
    start_frame = movies(1).reader.FrameRate*start_time + 1;    
    if end_time > movies(1).reader.NumberOfFrames/movies(1).reader.FrameRate
        end_frame = movies(1).reader.NumberofFrames;
    else end_frame = end_time*movies(1).reader.FrameRate;
    end
    
    % Write the output video
    for i = start_frame:decimation:end_frame
        reader_obj = arrayfun(@(x) read(x.reader,i), movies, 'UniformOutput', false);
        % If there aren't enough videos to fill out the tile, use empty
        % (black) frames
        if set_index == sets && mod(length(contents),rows*columns) > 0
            empty_frames(1:rows*columns-mod(length(contents),rows*columns)) = {uint8(zeros([movies(1).reader.Width, movies(1).reader.Height, 3]))};
            reader_obj = [reader_obj empty_frames];
        end

        % Draw frames to screen.  Example: If row = 4, columns = 2 and your
        % arrays is [A B C D E F], it will be reshaped according to the 
        % columns/rows into something like:
        % A B C D
        % E F X X
        % where X is a black frame.
        imshow(cell2mat(reshape(reader_obj,columns,rows)'));
        
        % Overlay video index number
        for j = 1:columns*rows
            x_grid = mod(j-1,columns);
            y_grid = floor((j-1)/columns);
            text(x_grid*movies(1).reader.Width+5,y_grid*movies(1).reader.Height+10,num2str((set_index-1)*(rows*columns)+j),'Color','r','FontSize',11,'FontWeight','bold','Interpreter','none')
        end
        
        % Overlay time
        text(columns*movies(1).reader.Width-50,rows*movies(1).reader.Height-15,[num2str(i/(movies(1).reader.FrameRate),'%.1f') 's'],'Color','w','FontSize',11,'FontWeight','bold','Interpreter','none')
        
        % Write video
        writeVideo(vidObj,getframe);
    end
        
    close(vidObj);
end

%% INDEX

output_table = {};
for file_index = 1:length(contents)
    [~, sourcename, ext] = fileparts(contents(file_index).name);
    output_table{file_index,1} = file_index;
    output_table{file_index,2} = [sourcename ext];
end
xlswrite(['montage' num2str(set_index) '_' now_str '.xls'],output_table);

%% CLEAN UP

clear all