function [img_aoi, def, clus] = gcDynamicDataDrivenAOI(clus, img,lab)

% load video

    vr = VideoReader(img);
    img = vr.readFrame;


    % remove invalid clusters (<1% of gaze)
    clus = gcRemoveInvalidClusters(clus);
    numClusters = clus.numClusters;
    numSamples = clus.gaze.NumSamples;
    
% rescale

    % scale x, y, to image res
    w       = size(img, 2);
    h       = size(img, 1);
    x       = clus.gaze_matrix(1, :) * w;
    y       = clus.gaze_matrix(2, :) * h;
    t       = clus.gaze_matrix(3, :);
    
    % scale cluster centres to image res, and prepare colours for plotting
    cx      = clus.cluster_centre(1, :) * w;
    cy      = clus.cluster_centre(2, :) * h;
    cols    = jet(sum(clus.cluster_validity));
% produce heatmaps, and threshold into binary AOIs
    
    % prepare heatmap 
    hm_res = [30, 30];
    hm_xe = 1:hm_res(1) + 1;
    hm_ye = 1:hm_res(2) + 1;
    hm = cell(numClusters, numSamples);
    present = zeros(numClusters, numSamples);
    
    % rescale gaze to hm res
    hm_x = (x ./ w) .* hm_res(1);
    hm_y = (y ./ h) .* hm_res(2);
                
%     % prepare legend
%     labLeg = cell(sum(clus.cluster_validity), 1);
%     idx_labLeg = 1;
    
    % loop through clusters
    tic
    idx_cluster = clus.cluster_idx;
    idx_clusterVal = clus.cluster_validity;
    t_scaled = clus.time_scaled;
    parfor c = 1:numClusters
        
        % skip invalid clusters
        if ~idx_clusterVal(c), continue, end
        
        fprintf('Heatmaps: Cluster %d of %d...\n', c, numClusters);
        
        % index samples in this cluster here, for performance
        idx_thisCluster = idx_cluster == c;
        
        % loop through time samples. Find any cluster that exists on each
        % sample and form it into a ddAOI
        for s = 1:numSamples
            
            % select samples to include in the heatmap. This is all samples
            % that belong to the current cluster (c), AND which belong to
            % the current sample (s)
            idx = idx_thisCluster & t == t_scaled(s);
            
            % if any gaze samples in this cluster, for this sample, produce
            % a heatmap 
            if any(idx)
                hm{c, s} = histcounts2(hm_y(idx), hm_x(idx), hm_ye, hm_xe);
                present(c, s) = true;
            end
               
        end 
    end
    
    for c = 1:numClusters
        
        fprintf('Interpolation: Cluster %d of %d...\n', c, numClusters);
        
        % post-process clusters. Interpolate samples with missing clusters,
        % and apply a temporal smooth
        
            % default max gap length is 200ms
            maxS = 0.200;
            
            % find gaps between clusters
            ct = findcontig2(~present(c, :));
            
            if ~isempty(ct)
                
                ctt = contig2time(ct, clus.gaze.Time);
                
                % remove gaps longer than criterion
                tooLong = ctt(:, 3) > maxS;
                ctt(tooLong, :) = [];
                ct(tooLong, :) = [];

                % find samples on either edge of each gap
                e1 = ct(:, 1) - 1;
                e2 = ct(:, 2) + 1;

                % remove out of bounds
                oob = e1 == 0 | e2 > size(present, 2);
                e1(oob) = [];
                e2(oob) = [];
                ct(oob, :) = [];

                % interpolate each gap 
                numGaps = size(ct, 1);
                for g = 1:numGaps

                    % get heatmaps at each edge
                    hm1 = hm{c, e1(g)};
                    hm2 = hm{c, e2(g)};

                    % interpolate
                    hm_gap = cat(3, hm1, hm2);
                    hm_gap = permute(hm_gap, [3, 1, 2]);
                    t_present = clus.gaze.Time([e1(g), e2(g)]);
                    t_gap = clus.gaze.Time(e1(g)+1:e2(g) - 1);
                    hm_int = interp1(t_present, hm_gap, t_gap);

                    % store interpolated heatmaps
                    cnt = 1;
                    for s = e1(g) + 1:e2(g) - 1
                        hm{c, s} = squeeze(hm_int(cnt, :, :));
                        cnt = cnt + 1;
                        present(c, s) = 2;
                    end

                end
                
            end

        % finalise ddAOI by thresholding the heatmap
        for s = 1:numSamples
            
            if ~present(c, s), continue, end
        
            % normalise heatmap
            hm{c, s} = hm{c, s} ./ max(hm{c, s}(:));
            
            % rescale to image res
            hm{c, s} = imresize(hm{c, s}, [h, w]);

%             % binarize
%             hm{c, s} = imbinarize(hm{c, s}, .05);
            
        end
        
        % smooth the heatmaps for this cluster
        
            % find cluster extent
            ct = findcontig2(present(c, :) ~= 0);
            
            % pull heatmaps into matrix ready for smoothing
            numSegs = size(ct, 1);
            for seg = 1:numSegs
                
                % pull segment of cluster
                s1 = ct(seg, 1);
                s2 = ct(seg, 2);
                numSamps = s2 - s1 + 1;
                tmp = zeros(h, w, numSamps);
                for s = s1:s2
                    tmp(:, :, s) = hm{c, s};
                end
                
                % smooth
                tmp = smoothdata(tmp, 3, 'movmean', 10);
                
                % threshold and put back into cell
                for s = s1:s2
                    hm{c, s} = imbinarize(tmp(:, :, s), .05);
                end
                
            end
        
        
    end
    toc
    clf
        heatmap(double(present))
%     % temporal smooth on clusters
%     for c = 1:numClusters
%         
%         ct = findcontig2(present(c, :));
%         ctt = contig2time(ct, clus.time_scaled)
%         
%         
%         
%         
%         
%     end
    
    
    
    % plot overlay
    
        % prepare figure, show stimuli
        fig_overlay = figure('visible', 'off');
        set(0, 'CurrentFigure', fig_overlay)
        
        vw = VideoWriter(sprintf('clus3dtest_%s_%s.mp4', lab, datestr(now, 30)), 'MPEG-4');
        vw.FrameRate = 10;
        open(vw)


            
        for s = 1:numSamples
            
            clf
            img = vr.readFrame;
            imshow(rgb2gray(img));
            hold on
        
            for c = 1:numClusters

                % skip invalid clusters
                if ~present(c, s), continue, end
%                 if ~clus.cluster_validity(c), continue, end
            
                % plot this cluster
                img_col = repmat(reshape(cols(c, :), 1, 1, 3), h, w);
                hImg_col = imagesc(img_col);
                set(hImg_col, 'AlphaData', 0.5 * hm{c, s});

                % plot labels
                scatter(cx(c), cy(c), 400, cols(c, :), 'MarkerEdgeColor', 'none',...
                    'MarkerFaceColor', 'flat')
                strLab =...
                    sprintf('Cluster %d (%.2f%%)', c, clus.cluster_propGaze(c) * 100);
                text(cx(c), cy(c), strLab, 'FontSize', 20, 'Color',...
                    'w', 'HorizontalAlignment', 'center')
                
            end
            
            fr = getframe(gca);
            writeVideo(vw, fr);

        end
        close(vw)


%         legend(labLeg)
%         
%         % get image and store in cluster struct
%         frame_overlay = getframe(fig_overlay);
%         img_overlay = frame2im(frame_overlay);
%         delete(fig_overlay)        
        
%     % plot AOI image
%     
%         def = cell(clus.numValidClusters, 2);
%     
%         % prepare figure, show stimuli
%         fig_aoi = figure('visible', 'off', 'color', 'k');
%         set(0, 'CurrentFigure', fig_aoi)
%         img_black = zeros(h, w, 3);
%         imshow(img_black, 'border', 'tight')
%         hold on
% 
%         idx_def = 1;
%         for c = 1:numClusters
%             
%             % skip invalid clusters
%             if ~clus.cluster_validity(c), continue, end
%         
%             % plot AOI
%             img_col = repmat(reshape(cols(c, :), 1, 1, 3), h, w);
%             hImg_col = imagesc(img_col);
%             set(hImg_col, 'AlphaData', hm{c, s});
%             
%             % make def entry
%             def{idx_def, 1} = sprintf('Cluster_%d', c);
%             def{idx_def, 2} = {round(cols(c, :) * 255)};
%             idx_def = idx_def + 1;
%             
%         end
%         
%         % get image and store in cluster struct
%         frame_aoi = getframe(fig_aoi);
%         img_aoi = frame2im(frame_aoi);
%         delete(fig_aoi)
%     
%     if nargout == 3
%         clus.stimulus = img;
%         clus.heatmaps = hm;
%         clus.image_overlay = img_overlay;
%         clus.image_aoi = img_aoi;
%     end
    
end



%     % plot clustered data
%     fig = figure('visible', 'off');
%     set(0, 'CurrentFigure', fig)
%     imagesc(img)
%     hold on
%     scatter(x, y, 5, cols(clus.cluster_idx, :), 'MarkerEdgeAlpha', .05)
%     scatter(cx, cy, 400, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'none')
%     title(sprintf('%d clusters', clus.numClusters))
%     clImg = getimage(fig);
%     delete(fig);

%         % blur
%         hm{c} = imgaussfilt(hm{c}, 1);

%         % dilate
%         se = strel('sphere', 15);
%         hm{c} = imdilate(hm{c}, se);





% 
%         % make legend entry
%         labLeg{idx_labLeg} = sprintf('Cluster %d [%.1f of samples]',...
%             idx_labLeg, clus.cluster_propGaze(c) * 100);
%         idx_labLeg = idx_labLeg + 1;