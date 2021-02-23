function clus = gc3DInterpolate(clus, gaze, present, crit)

    % default criterion is inf, so fill any gaps
    if ~exist('crit', 'var') || isempty(crit)
        warning('All gaps of any duration between clusters will be interpolated. To limit this, supply a maximum gap duration criterion as the third argument.')
        crit = inf;
    end
    
    for c = 1:clus.numClusters
        
        % find gaps
        
            % find non-empty samples
            idx_present = ~cellfun(@isempty, clus.
        
            ctm = findcontig2(gaze.Missing(:, s) | notInAny(:, s), true);
            if isempty(ctm), continue, end

            % convert to secs
            [ctm_time, ctm]         = contig2time(ctm, gaze.Time);

        % remove gaps longer than criterion
        
        % interpolate
        
            % find sample indices of clusters on either side of the gap
            
            % interpolate the gap
            
        
        
        
        
        
        
        
        
        
        
        
        
    end
    
    
    
    
    

  % find runs of missing or out-of-AOI samples
        ctm = findcontig2(gaze.Missing(:, s) | notInAny(:, s), true);
        if isempty(ctm), continue, end

        % convert to secs
        [ctm_time, ctm]         = contig2time(ctm, gaze.Time);

        % remove gaps longer than criterion 
        tooLong                 = ctm_time(:, 3) > maxS;
        ctm(tooLong, :)         = [];
        ctm_time(tooLong, :)    = [];
        dur                     = ctm_time(:, 3);

        % find samples on either side of the edges of missing data
        e1                      = ctm(:, 1) - 1;
        e2                      = ctm(:, 2) + 1;

        % remove out of bounds 
        outOfBounds             = e1 == 0 | e2 > size(in, 1);
        e1(outOfBounds)         = [];
        e2(outOfBounds)         = [];
        ctm(outOfBounds, :)     = [];
        dur(outOfBounds)        = [];

        % check each edge and flag whether a) gaze was in an AOI at both edges,
        % and b) gaze was in the SAME AOI at both edges
        val = false(length(dur), numAOIs);
        for e = 1:length(e1)

            % get state of all AOIs at edge samples
            check1 = in(e1(e), s, :);
            check2 = in(e2(e), s, :);

            % check state is valid 
            val(e, :) = sum([check1; check2], 1) == 2;

            % fill in gaps
            for a = 1:numAOIs
                if val(e, a)
%                     in(ctm(e, 1):ctm(e, 2), s, a) = true;
                    in(e1(e):e2(e), s, a) = true;
                    postInterpMissing(e1(e):e2(e), s) = false;
                end        
            end

        end



end