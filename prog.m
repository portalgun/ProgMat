classdef prog
properties
    f
    t
    k
    L
    text
    title
    modIter
end
methods
    function obj=prog(L,text,modIter)
        obj.L=L;
        obj.k=-1;
        obj.text=strrep(text,'_',' ');
        obj.title=['Prog: ' text];
        if exist('modIter','var') && ~isempty(modIter)
            obj.modIter=modIter;
        else
            obj.modIter=1;
        end
        obj=obj.update;
    end
    function obj = close(obj)
        close(obj.f)
    end
    function obj = update(obj,k)
        if ~exist('k','var') || isempty(k)
            obj.k=obj.k+1;
            k=obj.k;
        else
            obj.k=k;
        end
        pcnt=k./obj.L;
        if isempty(obj.f)
            obj.f=waitbar(pcnt,obj.text,'Name',obj.title);
            obj.t=tic;
        elseif mod(k,obj.modIter)==0
            time=toc(obj.t);
            eta=(1-pcnt)*time/pcnt;
            TEXT=[obj.text newline 'Elapsed:' sprintf('%5.0f',time) ' seconds' newline 'ETA:' sprintf('%5.0f',eta) ' seconds'];
            waitbar(pcnt,obj.f,TEXT,'Name',obj.title,'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
        end

        if k./obj.L==1
            obj.close;
        end
        if nargout < 1
            error('You should assign an output!')
        end
    end
end
end
