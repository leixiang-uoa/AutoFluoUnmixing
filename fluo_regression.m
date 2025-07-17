clc;
clear;
close all;

fluo_file = 'fluorescence.rta';

oct_record_start = 1;
oct_record_no = 48;

[~, metadata, ~] = RtafGetMetadata(fluo_file);
oct_last_frame = floor(metadata.numEntries/oct_record_no)-2;

oct_start_frame = 1;

OCTframe = oct_start_frame;

data_all = zeros(oct_last_frame-oct_start_frame+1,48,1024);

while (OCTframe<=oct_last_frame)

    recordNo = oct_record_start; 
    data = zeros(1024,48);
    while (recordNo<=oct_record_no)
        [~, ~, ~, tempdata_1] = RtafGetGenericData(fluo_file, recordNo+OCTframe*oct_record_no);
        data(:,recordNo-oct_record_start+1)= tempdata_1;
        recordNo = recordNo + 1;
    end
    data_all(OCTframe-oct_start_frame+1,:,:) = data';
    OCTframe=OCTframe+1;
end

max_fluo = zeros(oct_last_frame-oct_start_frame+1,32);
for i = 1:oct_last_frame-oct_start_frame+1
    for j = 1:32
        max_fluo(i,j) = max(squeeze(data_all(i,j,:)));
    end
end

max_vec = max_fluo(:);

[sort_max, index] = sort(max_vec);

back_per = 0.005;

sum_back = zeros(1024,1);
for i = 1:floor(length(sort_max)*back_per)
    sum_back = sum_back + squeeze(data_all(index(i)-(oct_last_frame-oct_start_frame+1)*(ceil(index(i)/double(oct_last_frame-oct_start_frame+1))-1),ceil(index(i)/double(oct_last_frame-oct_start_frame+1)),:));
end

mean_back = sum_back/floor(length(sort_max)*back_per);
min_back =  squeeze(data_all(index(1)-(oct_last_frame-oct_start_frame+1)*(ceil(index(1)/double(oct_last_frame-oct_start_frame+1))-1),ceil(index(1)/double(oct_last_frame-oct_start_frame+1)),:));

corr_fluo = zeros(oct_last_frame-oct_start_frame+1,32);
corr_min = 1;
index_i = 0;
index_j = 0;
for i = 1:oct_last_frame-oct_start_frame+1
    for j = 1:32
        corr_fluo(i,j) = corr(squeeze(data_all(i,j,550:1000)),mean_back(550:1000));
        if corr_fluo(i,j) < corr_min
            corr_min = corr_fluo(i,j);
            index_i = i;
            index_j = j;
        end
    end
end

if corr_min > 0.95
    disp('No sample fluorescence found');
    return
end

back = mean_back;
fluo = squeeze(data_all(index_i,index_j,:))-0.9*mean_back;

lb = [1 0];
x = zeros(oct_last_frame-oct_start_frame+1,32,2);
data_regression = zeros(oct_last_frame-oct_start_frame+1,32,1024);
data_fluo = zeros(oct_last_frame-oct_start_frame+1,32,1024);
data_reflect = zeros(oct_last_frame-oct_start_frame+1,32,1024);

for i = 1:oct_last_frame-oct_start_frame+1
    for j = 1:32
        x(i,j,:) = lsqlin([back fluo], squeeze(data_all(i,j,:)),[],[],[],[],lb,[]);
        data_regression(i,j,:) = x(i,j,1)*back + x(i,j,2)*fluo;
        data_fluo(i,j,:) = x(i,j,2)*fluo;
        data_reflect(i,j,:) = x(i,j,1)*back-mean_back;
    end
end

save('fluo.mat','data_all','data_regression','data_fluo','x','back','fluo','data_reflect');



