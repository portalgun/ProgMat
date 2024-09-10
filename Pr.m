classdef Pr < handle
% obj= Pr(N,modIter,text,animation,bSound,logFname)
% NOTE PLACE p.u() AT START OF LOOP and p.c() at end
% u(obj,bSoft,info)
properties
    bSound=false
    i=-1
    iPre=0 % counts that don't contribute to eta
    iCur=0 % counts that contribute to eta
    N      % display total
    NReal  % total adjusted if continuing
    modIter=1
    preModIter
    lstStrLngth=0
    last=0
    mode = 'progress'
    lastchar= ''
    lastanim='...DONE'
    erroranim='...ERROR'
    anim= '_.-*-._ '
    first=1
    eta

    tStart
    msg
    warnmsg
    info=newline
    lastInfo=''

    bLog=false
    Log

    caller
    text
end
properties(Hidden)
    CL
    bComplete=false
    bar
    title
end
methods
    function obj= Pr(N,modIter,text,moude,bSound,logFname)
        %bCombine=false;
        %if Data.isInBase('PR_OBJECT_')
        %    OBJ=Data.fromBase('PR_OBJECT_');
        %end
        if exist('N','var') && ~isempty(N)
            obj.N=N;
            obj.NReal=N;
        end
        if exist('modIter','var') && ~isempty(modIter)
            obj.modIter=modIter;
        end
        obj.preModIter=obj.modIter*10;
        if exist('bSound','var') && ~isempty(bSound)
            obj.bSound=bSound;
        end

        if exist('moude','var') && ~isempty(moude)
            obj.mode=moude;
        end

        if exist('text','var') && ~isempty(text)
            disp([text ':'])
        elseif ~strcmp(obj.mode,'log')
            fprintf(newline);
        end

        if  strcmp(obj.mode,'animate') || isempty(N)
            obj.mode= 'animate';
            %obj.anim= '_.-o-._.-*-._.-*-._.-*-._.-*-._.-*-. ';
            obj.lstStrLngth=length(obj.anim);
            disp('  ')
        end
        if exist('logFname','var')
            obj.init_log(logFname);
            caller=dbstack(1);
            obj.caller=caller(1).name;
            obj.text=text;
            obj.bLog=true;
        end
        %if bCombine
        %    obj.combine(OBJ);
        %end
    end
    function obj=combine(obj,OBJ)
    end
    function obj=c(obj)
        obj.complete();
    end
    function obj=u(obj,bSoft,info)
        if nargin < 2
            bSoft=[];
        end
        if nargin < 3
            info=[];
        end
        obj.update(bSoft,info);
        %obj.msg='';
    end
    function obj=update(obj,bSoft,info)
        if nargin < 2 || isempty(bSoft)
            bSoft=0;
        elseif ischar(bSoft) || iscell(bSoft)
            info=bSoft;
            bSoft=0;
        end
        if nargin < 3 || isempty(info)
            info=[];
        end

        if bSoft
            obj.iPre=obj.iPre+1;
        else
            obj.iCur=obj.iCur+1;
        end
        obj.i=obj.i+1;

        if obj.first==1 && ~bSoft
            obj.tStart=tic;
        end
        if obj.first==1 && (mod(obj.i,obj.preModIter) ~= 0)
            return
        elseif mod(obj.i,obj.modIter) ~=0
            return
        end
        obj.run_mode();
        if obj.iCur == 1
            obj.first=0;
        end
    end
    function obj=run_mode(obj)
        switch obj.mode
            case 'progress'
                obj.progress();
            case 'animate'
                obj.animate();
            case 'visual'
                obj.visual();
            case 'log'
                obj.log_only();
        end
    end
%% MESSASGE
    function obj =set_msg(obj,msg)
        obj.msg=msg;
        obj.(obj.mode);
        if obj.bLog
            obj.add2log(msg);
        end
    end
    function obj=append_error(obj,ME,bClose)

        stk='';
        for i = 1:length(ME.stack)
            stk=[ '      line ' num2str(ME.stack(i).line) ' in ' ME.stack(i).name() ];
        end
        msg=['ERROR:' ME.identifier newline ...
             '      ' ME.message newline ...
             stk ...
            ];
        obj.add2log(msg);
        if bClose
            obj.incomplete();
            rethrow(ME);
        end
    end
    function obj=append_msg(obj,msg,bQuiet)
        if ~exist('bQuiet','var') || isempty(bQuiet)
            bQuiet=false;
        end
        if isempty(obj.msg)
            obj.msg=msg;
        else
            obj.msg=[obj.msg newline msg];
        end
        if obj.bLog
            obj.add2log(msg);
        end
        if ~bQuiet
            obj.run_mode();
        end
    end
    function obj=inform(obj,text)
        text=indent(text,1);
        %text=text(2:end);
        if strcmp(obj.info,newline) && ~isempty(text)
            obj.info=[text newline];
        elseif ~isempty(text) && ~strcmp(text,obj.lastInfo)
            obj.info=[obj.info text newline];
        end
        obj.lastInfo=text;
    end
%% LOG
    function sep=log_sep(obj)
        sep=cell(2,1);
        sep{1}=[ '--- ' char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')) ' -------- ' newline];
        if isempty(obj.caller) && isempty(obj.text)
            sep(2)=[];
        elseif isempty(obj.caller)
            sep{2}=['-- :' obj.text];
        elseif isempty(obj.text)
            sep{2}=['-- ' obj.caller];
        else
            sep{2}=['-- ' obj.caller ':' obj.text];
        end
    end
    function obj=init_log(obj,logFname)
        Fil.touch(logFname);
        obj.Log=Fil.append(logFname,obj.log_sep);
    end
    function obj=add2log(obj,msg)
        if obj.i > 0
            msg=['iter=' num2str(obj.i) ': ' msg];
        end
        obj.Log=Fil.append(obj.Log,[msg newline]);
    end
%%
    function obj = visual(obj)
        pcnt=obj.i/obj.N;
        time=toc(obj.tStart);
        eta=(1-pcnt)*time/pcnt;
        TEXT=[obj.text newline 'Elapsed:' sprintf('%5.0f',time) ' seconds' newline 'ETA:' sprintf('%5.0f',eta) ' seconds'];

        if isempty(obj.bar)

            obj.bar=waitbar(pcnt,obj.text,'Name', obj.title);
        else
            waitbar(pcnt,obj.bar,TEXT,'Name', obj.title,'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
        end
    end
    function obj = progress(obj)
        FRC=obj.i/obj.N;
        if obj.iCur > 1
            frc=(obj.iCur-obj.iPre)./(obj.N-obj.iPre);

            tm=toc(obj.tStart);
            eta=tm*(1/frc)-tm;

            el=Time.Sec.humanStr(tm);
            eta=Time.Sec.humanStr(eta);

            eta=eta(1:end-3);
            el=el(1:end-3);


            outputStr = [ ' ' num2str(100.*FRC,'%.1f') '%% ' num2str(obj.i) '/' num2str(obj.N) newline ' ELAPSED: ' el   ' ETA: ' eta newline ' ' obj.msg obj.info];
        elseif obj.iPre > 1
            outputStr = [ ' ' num2str(100.*FRC,'%.1f') '%% ' num2str(obj.i) '/' num2str(obj.N) newline ' ' obj.msg obj.info ];
        else
            outputStr = [ ' ' num2str(0,'%.1f') '%% 0/' num2str(obj.N) newline ' ' obj.msg obj.info ];
        end

        if obj.lstStrLngth > 0
            str=repmat('\b',1,obj.lstStrLngth-1);
            fprintf([str outputStr]); %pause(0.1);
            obj.lstStrLngth=length(outputStr);
        else
            obj.lstStrLngth=length(outputStr);
            fprintf(outputStr);
        end
    end
    function obj = log_only(obj)
        outputStr = [ obj.msg obj.info];

        if obj.lstStrLngth > 0
            str=repmat('\b',1,obj.lstStrLngth-1);
            fprintf([str outputStr]); %pause(0.1);
            obj.lstStrLngth=length(outputStr);
        else
            obj.lstStrLngth=length(outputStr);
            fprintf(outputStr);
        end
    end
    function obj = animate(obj)
        if ~isempty(obj.lastchar)
            obj.anim=[obj.lastchar obj.anim(1:end-1)];
            str=repmat('\b',1,obj.lstStrLngth);
        end
        if obj.first==1
            %fprintf(['\b\b\b' 'o' obj.anim])
            fprintf(['\b\b\b\b'  obj.anim]);
        else
            fprintf([str  obj.anim]);
            %Tfprintf([str 'o' obj.anim])
        end
        obj.lastchar=obj.anim(end);
    end
    function obj=cleanup(obj)
        if ~obj.bComplete
            obj.incomplete();
        end
    end
    function ojb=incomplete(obj)
        str=repmat('\b',1,obj.lstStrLngth);
        %fprintf([str obj.erroranim newline]);
        if obj.first==0;
            disp(['    Time ' Time.Sec.humanStr(toc(obj.tStart)) ]);
        end
        if ~strcmp(obj.info,newline);
            disp([' Messages:' newline indent(obj.info,2)]);
        end
        if obj.bSound
            Pr.soundFlat();

        end
        if obj.bLog
            Fil.close(obj.Log);
        end
    end
    function obj=complete(obj)
        obj.bComplete=1;
        str=repmat('\b',1,obj.lstStrLngth);
        if ~strcmp(obj.mode,'log')
            fprintf([str obj.lastanim newline]);
            if obj.first==0;
                disp(['    Time ' Time.Sec.humanStr(toc(obj.tStart)) ]);
            end
            if ~strcmp(obj.info,newline);
                disp([' Messages:' newline indent(obj.info,2)]);
            end
            if obj.bSound
                Pr.sound();
            end
        end
        if obj.bLog
            fclose(obj.Log);
        end
    end
end
methods(Static)
    function soundFlat(f)
        Pr.sound(0.73/2);
    end
    function sound(f)
        if nargin < 1 || isempty(f)
            f= 0.73;
        end
        sound(sin(f*(0:1439)).*cosWindowFlattop([1 1440],720,720,0));
    end
    function obj=log(logFname)
        bSound=false;
        if ~exist('logFname','var') || isempty(logFname)
            stk=dbstack;
            file=stk(2).name;
            prj=Env.var('PX_CUR_PRJ_NAME');
            logFname=[Env.var('PX_LOG') prj '.' file '.log'];
        end
        obj= Pr(1,1,'','log',false,logFname);
    end
    function test_log()
        obj=Pr.log();
        try
            dk
        catch ME
        end
        obj.append_error(ME,true);
        pause(2);
        %obj.append_msg('test2');
        %pause(2)
        %obj.c();
    end

end
end
