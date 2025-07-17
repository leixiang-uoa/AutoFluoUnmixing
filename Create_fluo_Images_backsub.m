clear;
clc;
close all;

fluo_dir = 'fluo_backsub\';
if not(isfolder(fluo_dir))
    mkdir(fluo_dir);
end

fluo_Record_No = 1;

oct_record_no = 48;

load('fluo.mat');

size_fluo = size(data_all);

oct_last_frame = size_fluo(1);

oct_start_frame = 1;

OCTframe = oct_start_frame;

fluo_sum = zeros(oct_last_frame-oct_start_frame+1,1);

while (OCTframe<=oct_last_frame)
    data = squeeze(data_all(OCTframe,:,:))'-back;
    data_expanded = zeros(1024,32);
    for i = 1:32
        for j = 1:50
            data_expanded(:,(i-1)*50+j) = data(:,i);
        end
    end

    data_expanded = data_expanded(400:1000,:);
    data_expanded = flip(data_expanded,1);

    fluo_sum(OCTframe) = sum(data,'all');

    dcontrast=80; 
    colordata=data_expanded/dcontrast; 
    filename=[num2str(OCTframe)];
    load('blackjet.mat');
    imwrite(colordata,cmap,[fluo_dir filename 'fluo.jpg'], 'quality',100);
    OCTframe=OCTframe+1;
end

