clear th
addpath('StripChart')

sensorType='LDC';

number_of_channels=1; %number of coil pairs
number_of_meas_per_channel=3; %raw of each coil, and difference 

ch_name={'LEDT','RIGHT','diff'};
cap_per_trigger=1;
% dt_us=6000;
dt_us=12000;
RCOUNT=2^16-1;
% RCOUNT=1250;
Ltank=5.6e-6;

N1=32; % number of triggers per plot update
N2=16; % number of plot updates per plot
N=N1*N2; % total measurements per plot
Naxis=(1:N1*N2);
taxis=[dt_us:dt_us:dt_us*N]*1e-6;

set_defaults;
s=create_serial_port_LDC('COM12');

Fref_ext=40e6;
Fref_div=1;
Fref=Fref_ext/Fref_div;
tconv=RCOUNT*16/Fref; %tc=(RCOUNT*16+4)/Fref
snr_ncaps=128;
tail_len=3;


Vbias=4.1;               %bias voltage to load cell
LC_capacity_kg=20.0;     %//load cell rated capacity
LC_sensitivity=0.001;    %//sensitivity in V/V
ADC_vin_FSR=0.04;        %//for gain = 128, input range is +/-20mV
% ADC_vin_FSR=0.08;        %//for gain = 64, input range is +/-40mV
% ADC_vin_FSR=0.16;        %//for gain = 32, input range is +/-80mV
ADC_raw_FSR=(2^24-1);    %//full scale range of the ADC output code

while(1)
    msg_rx=fgetl(s);
    disp(msg_rx);
    if((strcmp(strtrim(msg_rx),'CAL DONE')))
%     if(strfind(msg_rx,'CAL DONE'))
        break;
    end
end

seg.y=zeros(number_of_meas_per_channel,number_of_channels,N1);
seg.y_plot=zeros(number_of_channels,N1);
strip.y=zeros(number_of_meas_per_channel,number_of_channels,N2*N1);
strip.y(:)=NaN;
strip.y_plot=zeros(number_of_meas_per_channel,N2*N1);
strip.y_plot(:)=NaN;    


strip.unit='Hz';
% strip.unit='pF';

hLine=zeros(1,3);

statmax=3; statcount=statmax; 

%figure 2 is for histogram
figure(2); clf;

figure(1); clf; 
[h1, ha1] = tight_subplot_position(1,number_of_meas_per_channel, 1, [.02 0.05], [0.05 0.05],[0.06 0.01],[1 2 18 8]);
tic
t=zeros(10,500);
xlimits=[0 max(taxis)];

% fprintf(s,['AUTOSCAN',num2str(dt_us),'*']); rx=fgetl(s)
expected_TR_idx=(0:1:N1-1);

init_valuesreceived = s.ValuesReceived;
% msg=sprintf('valuesreceived = %d\n',init_valuesreceived); disp(msg)
for stripidx=1:5000
    t(1,stripidx)=toc;        
    t(2,stripidx)=toc;
 
    t(3,stripidx)=toc;
    if strcmp(sensorType,'LDC')
        
        for N1idx=1:N1
            for measidx=1:3
                msg_rx=strtrim(fgetl(s));
%                 disp(msg_rx);
                nums_in_str=extractNumFromStr(msg_rx);
                seg.y(measidx,1,N1idx)=nums_in_str(end);
            end
        end
%         apply scaling
%         first convert to raw input voltage
        seg.y=seg.y*(ADC_vin_FSR/ADC_raw_FSR);
%         then to kg
        seg.y=seg.y*LC_capacity_kg/LC_sensitivity/Vbias;
        
        
        seg.y_plot=squeeze(seg.y);
    end
    

    
%     t(4,stripidx)=toc;
    figure(1);
    if stripidx>1
        strip.y(:,:,1:end-N1) = strip.y(:,:,N1+1:end);  % shift old data left
        strip.y(:,:,end-N1+1:end) = seg.y;
        
%         strip.v(:,1:end-N1) = strip.v(:,N1+1:end);  % shift old data left
%         strip.v(:,end-N1+1:end) = seg.v;
        
        strip.y_plot(:,1:end-N1) = strip.y_plot(:,N1+1:end);  % shift old data left
        strip.y_plot(:,end-N1+1:end) = seg.y_plot;
      
        t(5,stripidx)=toc;
        for hidx=1:number_of_meas_per_channel
            StripChart('Update',hLine(1,hidx),squeeze(seg.y(hidx,1,:)));
%             StripChart('Update',hLine(2,hidx),squeeze(seg.y(hidx,1,:)));
        end
        
        if 0
            % make it so that all plots have same limits
            % the limit will be the largest y value from all plots
            ymax=0;
            for hidx=1:number_of_meas_per_channel
                temp=squeeze(strip.y(hidx,1,:));
                temp=abs(temp);
                temp=max(temp);
                ymax=max(ymax,temp);
            end
            for hidx=1:number_of_meas_per_channel
                axes(ha1(hidx));
                ylim([-ymax ymax]);
            end
        elseif 0
            ymax=0;
            for hidx=1:number_of_meas_per_channel
                temp=squeeze(strip.y(hidx,1,:));
                temp=abs(temp);
                temp=max(temp);
                ymax=temp;
%                 axes(ha1(hidx));
%                 ylim([-ymax ymax]);
                set(ha1(hidx),'YLimMode','Auto');
            end
            
            % each plot has its own y limit
        else
            for hidx=1:number_of_meas_per_channel
                axes(ha1(hidx));
                ylim([-5 5]*2);
            end
        end
        
%         for hidx=5:8
%             StripChart('Update',hLine(1,hidx),squeeze(seg.v(hidx-4,:)));
%         end
        t(6,stripidx)=toc;
    else
        
        strip.y(:,:,N1*(stripidx-1)+1:N1+N1*(stripidx-1))=seg.y(:,:,:);
        strip.y_plot(:,N1*(stripidx-1)+1:N1+N1*(stripidx-1))=seg.y_plot(:,:);
        if stripidx==1
%             hidx=1;
            t(5,stripidx)=toc;
            
            ymax=0;
            for hidx=1:number_of_meas_per_channel
                temp=squeeze(strip.y(hidx,1,:));
                temp=abs(temp);
                temp=max(temp);
                ymax=max(ymax,temp);
            end
            
            for hidx=1:number_of_meas_per_channel
                axes(ha1(hidx));
%                 hLine(:,hidx) = plot(taxis,squeeze(strip.y(hidx,1,:)),taxis,squeeze(strip.y(2,hidx,:))); xlim(xlimits);
                hLine(:,hidx) = plot(taxis,squeeze(strip.y(hidx,1,:))); xlim(xlimits);
                th(hidx)=text(0.05,0.1,['Std=',num2str(0),'Hz'],'Units','normalized'); set(gca,'XTickLabel',[]); text(0.02,0.85,['Channel ',num2str(hidx-1),' (',ch_name{hidx},'), FREQ'],'Units','normalized');
                th_seg_new(hidx)=text(0.55,0.1,['Std=',num2str(0),'Hz'],'Units','normalized'); set(gca,'XTickLabel',[]); text(0.02,0.85,['Channel ',num2str(hidx-1),' (',ch_name{hidx},'), FREQ'],'Units','normalized');
                ylim([-ymax ymax]);
%                 temp=get(gca,'YLim'); temp=abs(temp); temp=max(temp);
%                 ymax=max(ymax,temp);
            end
%             for hidx=5:8
%                 axes(ha1(hidx));
%                 hLine(1,hidx) = plot(taxis,strip.v(hidx-4,:)); xlim(xlimits);
%                 th(hidx)=text(0.05,0.1,['Std=',num2str(0),'Hz'],'Units','normalized'); set(gca,'XTickLabel',[]); text(0.02,0.85,['Channel ',num2str(hidx-5),' (',ch_name{hidx-4},'), FREQ'],'Units','normalized');
%             end
%            
        end
    end
    
    if statcount==statmax
        t(6,stripidx)=toc;
        y_mean=mean(strip.y_plot,2);
        y_std=std(strip.y_plot,0,2);
        y_pp=max(strip.y_plot,[],2)-min(strip.y_plot,[],2);
        
        y_mean_newseg=mean(seg.y_plot,2);
        y_std_newseg=std(seg.y_plot,0,2);
        y_pp_newseg=max(seg.y_plot,[],2)-min(seg.y_plot,[],2);
        for hidx=1:number_of_meas_per_channel
            msg=sprintf('mean=%fHz, Std=%fHz, p-p=%f %s',y_mean(hidx),y_std(hidx),y_pp(hidx),strip.unit); th(hidx).String=msg;
            msg=sprintf('mean=%fHz, Std=%fHz, p-p=%f %s',y_mean_newseg(hidx),y_std_newseg(hidx),y_pp_newseg(hidx),strip.unit); th_seg_new(hidx).String=msg;
        
        end
        
        statcount=0;
    else
        statcount=statcount+1;
    end
    

    tdisp=t(:,stripidx)-t(1,stripidx);
    
    expected_TR_idx=expected_TR_idx+N1;
end
fwrite(s,'X');
return;
print(h1,'-dpng','-r150','noise_only.png')


rev_means=mean(rev,2);
fwd_means=mean(fwd,2);

Naxis=1:N;

[h1, ha1] = tight_subplot_position(1,2, 4, [.05 0.05], [0.05 0.05],[0.03 0.01],[1 2 18 8]);
axes(ha1(1)); plot(Naxis,rev);
axes(ha1(2)); plot(Naxis,rev-rev_means)

axes(ha1(1+4)); plot(Naxis,fwd);
axes(ha1(2+4)); plot(Naxis,fwd-fwd_means)

figure(1); clf; plot(Naxis,rev)
figure(2); clf; plot(Naxis,rev-rev_means)
std(rev,0,2)

return;


