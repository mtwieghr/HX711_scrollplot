function [s] = create_serial_port_DMS(port)
% global s;
% a=whos('s');
% if sum(a.class=='serial')~=6
%     warning('WARNING: serial port was not defined')
    delete(instrfindall);
    s = serial(port, 'BaudRate', 1000000);
    set(s,'InputBufferSize',4096*4,'Outputbuffersize',256,'Timeout',2);
    set(s,'DataBits',8);
    set(s,'Parity','none');
    %set(s,'Terminator','CR');
    fopen(s);
% end
 
while(s.Bytesavailable>0)
    s.Bytesavailable;
    extradata=fread(s,s.Bytesavailable,'uint8');
end

tic
%the DMS might echo the X character
pause(0.01);
while(toc<0.5)
    if s.Bytesavailable>1
        fread(s,s.Bytesavailable,'uint8')
        break;
    end
end
% extradata=fread(s,s.Bytesavailable,'uint8')
    
serial_status=1; 
%0 means success 
%1 means try with custom settings, 
%2 means trying with default settings, 
%3 means trying again with custom settings
%255 means failure

% while serial_status~=255
%     %test to see if interface is working
%     disp('printing ADC_INIT*')
%     fprintf(s,'ADC_INIT*');
%     tic
%     
% 
%     switch serial_status
%         case 1
%             while(s.BytesAvailable<9)
%                 if (toc>1)
%                     serial_status=2;
%                     disp('No reply from DMS. Try again.')
%                     
%                     %disp('Try with default baud rate 19200')
%                     %fclose(s);
%                     %s = serial(port, 'BaudRate', 19200);
%                     %set(s,'Terminator','CR');
%                     %fopen(s);
%                     break;
%                 end
%             end
%             
%             if serial_status==1
%                 %reply=fgetl(s);
%                 reply=fscanf(s,'%s',9)
%                 if(strcmp(reply,'ADC_INIT')~=1)
%                     disp(['Bad reply: ',reply]);
%                     disp('Failure!')
%                     serial_status=255;
%                 else
%                     %=fgetl(s);
%                     %status=reply(2:end);
%                     %status=str2num(status);
%                     %disp(['Status is ',num2str(status)])
%                     serial_status=0;
%                 end
%             end
%         case 2
%             while(s.BytesAvailable<9)
%                 if (toc>1)
%                     serial_status=2;
%                     disp('No reply from LIA')
%                     disp('Failure!')
%                     serial_status=255;
%                     break;
%                 end
%             end
%                 
%             if serial_status==2
%                 %reply=fgetl(s);
%                 reply=fscanf(s,'%s',9)
%                 if(strcmp(reply,'ADC_INIT')~=1)
%                     disp(['Bad reply: ',reply]);
%                     disp('Failure!')
%                     serial_status=255;
%                 else
%                     %reply=fgetl(s);
%                     %status=reply(2:end);
%                     %status=str2num(status);
%                     %disp(['Status is ',num2str(status)])
%                     serial_status=0;
%                     
%                 end
%             end
%     end
%     if serial_status==0
%         disp('Success!')
%         break;
%     end
% end

pause(0.1);
while(s.Bytesavailable>0)
    s.Bytesavailable;
    extradata=fread(s,s.Bytesavailable,'uint8');
end



%     
%     if (s.BytesAvailable>=5)
%         reply=fgetl(s);
%         if(strcmp(reply,'ST')~=1)
%             disp(['Bad reply to status byte command: ',reply]);
%             serial_status=255;
%         else
%             reply=fgetl(s);
%             status=reply(2:end);
%             status=str2num(status);
%             disp(['Status is ',num2str(status)])
%             serial_status=1;
%         end
%     elseif serial_status==0
%         disp('Try with default baud rate 19200')
%         s = serial(port, 'BaudRate', 19200);
%     end
end
    