classdef SG384
    % Wrapper for programming Signal Generator SG384 from SRS.
    % Maxime Joos 2020/04/11
    
    properties
       srs;
    end
    
    methods
        
        function obj = SG384(vendor, boardindex, primaryaddress)
            % vendor: str ('ni')
            % boardindex: int (0)
            % primaryaddress: in (for example 24)
            
            % gpib connection to device
            obj.srs = gpib(vendor, boardindex, primaryaddress);           
            
        end
       
        function command(obj, varargin)
            narg = length(varargin);
            fopen(obj.srs);
            if narg == 1    % one command, no argument
                fprintf(obj.srs, varargin{1});
            elseif narg > 1 % at least one command and one argument
                for k = 1:narg/2
                fprintf(obj.srs, [varargin{2*k-1}, num2str(varargin{2*k})]);
                end
            end
            fclose(obj.srs);
        end
        
        function enableNType(obj)
            obj.command('ENBR ', '1');
        end
        
        function disableNType(obj)
            obj.command('ENBR ', '0');
        end
        
        function set_amp(obj, amp)
            obj.command('AMPR ', amp);
        end
        
        function set_freq(obj, freq)
            obj.command('FREQ ', freq);
        end
        
        function set_IQ_on(obj)
            obj.command('MODL ', '1', ...   %enable modulation
                    'TYPE ', '6', ...       % IQ modulation
                    'QFNC ', '5');          % External modulation
        end
        
        function set_IQ_off(obj)
            obj.command('MODL ', '0');
        end
        
        function create_list(obj, freqlist)
            n = length(freqlist);
            fopen(obj.srs);
            fprintf(obj.srs, ['LSTC? ', num2str(n)]);     % create a list of size n
            
%             fprintf(srs_obj, ['LSTC? ', num2str(length(freqValues))]); % create a list of SG states
            fprintf(obj.srs, '*CLS'); % needed to prevent an error of buffer overload
            for i = 1:n
                % pre-load each state of the list into the SG384 memory
                fprintf(obj.srs, ['LSTP ', num2str(i-1), ',', num2str(freqlist(i)), ',N,N,N,N,N,N,N,N,N,N,N,N,N,N']);
            end
            % enable the list
            fprintf(obj.srs, 'LSTE 1');     % enable the list to be able to be triggered
            fclose(obj.srs);          
        end
        
        function create_amp_list(obj, amplist)
            n = length(amplist);
            fopen(obj.srs);
            fprintf(obj.srs, ['LSTC? ', num2str(n)]); % create a list of SG states
            fprintf(obj.srs, '*CLS');
            for i = 1:n
                % pre-load each state of the list into the SG384 memory
                % first slot is center frequency, third slot is
                % amplitude
                fprintf(obj.srs, ['LSTP ', num2str(i-1), ',N,N,N,N,', num2str(amplist(i)),',N,N,N,N,N,N,N,N,N,N']);
            end
            % enable the list
            fprintf(obj.srs,'LSTE 1');  % 1 or 0 for enabled or disabled
            fclose(obj.srs);
        end
        
        function list_trigger(obj)
            obj.command('*TRG');
        end
        
        function disable_list(obj)
            obj.command('LSTE ', '0');
        end
        
        function destroy_list(obj)
            obj.command('LSTD');
        end
        
        function overload_prevent(obj)
            obj.command('*CLS'); % needed to prevent an error of buffer overload
        end
        
        function enable_BNC(obj)
            obj.command('ENBL','1'); % enable BNC output
        end
        
        function disable_BNC(obj)
            obj.command('ENBL','0'); % disable BNC output
        end
        
    end    
end

