classdef ClincalAirways < TubeNetwork
    % short desc
    %
    % long desc
    %
    % .. todo: add documentation to this function
    %
    % Args:
    %   x(type):
    %
    % Return:
    %   y(type):
    %

    methods
        function obj = ClincalAirways(varargin)
            % short desc
            %
            % long desc
            %
            % .. todo: add documentation to this function
            %
            % Args:
            %   x(type):
            %
            % Return:
            %   y(type):
            obj@TubeNetwork(varargin{:})
            
            obj.IdentifyCarinaAndTrachea()

            obj.ClassifyLungLobes()

        end

        function IdentifyCarinaAndTrachea(obj)
            % short desc
            %
            % long desc
            %
            % .. todo:
            %   * May need to add further methods to reidentify generations
            %   for all airways.
            %
            % Args:
            %   x(type):
            %
            % Return:
            %   y(type):
            %

            % identfy carina
            g = TubesAsEdges(obj);
            [~, carina_node] = max(centrality(g,'outcloseness'));
            carinaend_gidx = inedges(carina_node);
            obj.tubes(g.Edges.ID(carinaend_gidx)).carinaend = true;

            % all tubes predecessing the carina is considered part of the
            % trachea and are therefore generation 0
            tracheanodes = predecessors(g, carina_node);
            for nid = tracheanodes
                eid = inedges(g, nid);
                tubeid = g.Edges(eid).ID;
                obj.tubes(tubeid).istrachea = true;
                obj.tubes(tubeid).generation = 0;
            end

            % reclass all tube generations by n decendants from 0 gen.
            obj.RunAllTubes('SetGeneration')
        end

        function obj = ClassifyLungLobes(obj)
            % Attempt to classify airways into their lobes.
            %
            % Adapted from original algorithm by Gu et al. 2012.
            %
            %

            % find trachea tubes and assign
            tubegens = [obj.tubes(:).generation];
            tracheaID = find(tubegens == 0);
            for ii = tracheaID
                obj.tubes(ii).SetRegion('lobe','T')
                obj.tubes(ii).SetRegion('name','Trachea')
            end

            % find carina-end tube and init algorithm
            carinaendID = find([obj.tubes(:).carinaend]);
            assert(length(carinaendID) == 1, ['There should only be one carina end.' ...
                'this indicates a major failure in the lobe classification algorithm.'])

            % Identify left and right major bronchi by comparing ends of
            % child of carina-end trachea
            MB = obj.tubes(carinaendID).children;
            [mX, ~, ~] = I2S([MB(:).skelpoints(end)]);
            [~,leftMBI] = max(mX);
            [~,rightMBI] = min(mX);
            MB(leftMBI).SetRegion('lobe','B')
            MB(leftMBI).SetRegion('name','LeftMajor')
            MB(rightMBI).SetRegion('lobe','B')
            MB(rightMBI).SetRegion('name','RightMajor')

            % Identify upper/lingular and lower left lobe 'LLL'
            MLlung = MB(leftMBI).children;
            [~, ~, MLlz] = I2S([MLlung(:).skelpoints(end)]);
            [~,MLULLML] = max(MLlz);
            [~,MLLL] = min(MLlz);
            MLlung(MLULLML).SetRegion('lobe','B')
            MLlung(MLULLML).SetRegion('name','LeftIntermedius')
            MLlung(MLLL).SetRegionDescendants('lobe','LLL')

            % identify upper lobe and lingular
            MLULLML2 = MLlung(MLULLML).children;
            [~, ~, MLl2z] = I2S([MLULLML2(:).skelpoints(end)]);
            [~,MLUL] = max(MLl2z);
            [~,MLML] = min(MLl2z);
            MLULLML2(MLUL).SetRegionDescendants('lobe','LUL')
            MLULLML2(MLML).SetRegionDescendants('lobe','LML')

            % % Identify right upper lobe
            MRlung = MB(rightMBI).children;
            [~, ~, MRz] = I2S([MRlung(:).skelpoints(end)]);
            [~,MRULi] = max(MRz);
            MRlung(MRULi).SetRegionDescendants('lobe','RUL');


            % check ratio of right major bronchi to the RUL bronchus.
            ratio = MRlung(MRULi).stats.euclength/MB(rightMBI).stats.euclength;
            if ratio < 0.5
                warning(['Relatively short right major bronchi detected, ' ...
                    'this case may have abnormal RUL branching, ' ...
                    'check the lobe classification.' ...
                    'No changes have been made.'])
            end

            % subgraph remaining and get endtubes
            subtubes = MRlung(MRMLRLLi).Descendants;
            endtubes = subtubes(isempty(subtubes.children));
            % compare endpoints of endtubes
            endtubes_ep = [endtubes(:).skelpoints(end)];
            [~, epy, epz] = I2S(endtubes_ep);
            z_minus_y = epz - epy;
            [~, RMLepi] = max(z_minus_y);
            RML_eptube = endtubes(RMLepi);
            [~, RLLepi] = min(z_minus_y);
            RLL_eptube = endtubes(RLLepi);
            % get ancestor list and find intersection
            RML_endpath = [RML_eptube.Ancestors().ID];
            RLL_endpath = [RLL_eptube.Ancestors().ID];
            [~, intersections] = intersect(RML_endpath, RLL_endpath);
            RML_RLLNid = RML_endpath(min(intersections));

            % assign right bronchus intermedius
            obj.tubes(RML_RLLNid).SetRegion('lobe','B')
            obj.tubes(RML_RLLNid).SetRegion('name','RightIntermedius')

            % assign RML
            RML_id = RML_endpath(min(intersections)-1);
            obj.tubes(RML_id).SetRegionDescendants('lobe','RML')

            % assign remaining labels to RLL
            for ii = 1:length(obj.subtubes)
                if ~isfield(obj.subtubes(ii).region,'lobe')
                    obj.subtubes(ii).SetRegion('lobe','RLL')
                end
            end

            % check for empty lobe fields
            for ii = 1:length(obj.tubes)
                if ~isfield(obj.tubes(ii).region,'lobe')
                    warning(['Lobe classification failed as some tubes were ' ...
                        'not assigned a lobe. Please manually correct.'])
                end
            end

            % set gen by lobe
            obj.RunAllTubes('SetRegionGeneration', 'lobe')
        end

    end
end


