function [img_aoi, def, clus] = gcStaticDataDrivenAOI(clus, img)

    numClusters = clus.numClusters;

% rescale

    % scale x, y, to image res
    w       = size(img, 2);
    h       = size(img, 1);
    x       = clus.gaze_matrix(1, :) * w;
    y       = clus.gaze_matrix(2, :) * h;
    
    % scale cluster centres to image res, and prepare colours for plotting
    cx      = clus.cluster_centre(1, :) * w;
    cy      = clus.cluster_centre(2, :) * h;
    cols    = jet(max(clus.cluster_idx));
    
% produce heatmaps, and threshold into binary AOIs
    
    % prepare heatmap 
    hm_res = [30, 30];
    hm_xe = 1:hm_res(1);
    hm_ye = 1:hm_res(2);
    hm = cell(clus.numClusters, 1);
    
    % prepare legend
    labLeg = cell(sum(clus.cluster_validity), 1);
    idx_labLeg = 1;
    
    % loop through clusters
    for c = 1:numClusters
        
        % skip invalid clusters
        if ~clus.cluster_validity(c), continue, end
        
        % make legend entry
        labLeg{idx_labLeg} = sprintf('Cluster %d [%.1f of samples]',...
            idx_labLeg, clus.cluster_propGaze(c) * 100);
        idx_labLeg = idx_labLeg + 1;
        
        % rescale gaze to hm res
        hm_x = (x(clus.cluster_idx == c) / w) * hm_res(1);
        hm_y = (y(clus.cluster_idx == c) ./ h) * hm_res(2);
        
        % make heatmap
        hm{c} = histcounts2(hm_y, hm_x, hm_ye, hm_xe);
        
        % normnalise heatmap, rescale to image res
        hm{c} = hm{c} ./ max(hm{c}(:));
        hm{c} = imresize(hm{c}, [h, w]);

        % binarize
        hm{c} = imbinarize(hm{c}, .05);
        
    end
    
    % plot overlay
    
        % prepare figure, show stimuli
        fig_overlay = figure('visible', 'off');
        set(0, 'CurrentFigure', fig_overlay)
        imshow(rgb2gray(img));
        hold on

        for c = 1:numClusters
            
            % skip invalid clusters
            if ~clus.cluster_validity(c), continue, end
        
            % plot this cluster
            img_col = repmat(reshape(cols(c, :), 1, 1, 3), h, w);
            hImg_col = imagesc(img_col);
            set(hImg_col, 'AlphaData', 0.5 * hm{c});

            % plot labels
            scatter(cx(c), cy(c), 400, cols(c, :), 'MarkerEdgeColor', 'none',...
                'MarkerFaceColor', 'flat')
            strLab =...
                sprintf('Cluster %d (%.2f%%)', c, clus.cluster_propGaze(c) * 100);
            text(cx(c), cy(c), strLab, 'FontSize', 20, 'Color',...
                'w', 'HorizontalAlignment', 'center')

        end
        legend(labLeg)
        
        % get image and store in cluster struct
        frame_overlay = getframe(fig_overlay);
        img_overlay = frame2im(frame_overlay);
        delete(fig_overlay)        
        
    % plot AOI image
    
        def = cell(clus.numValidClusters, 2);
    
        % prepare figure, show stimuli
        fig_aoi = figure('visible', 'off', 'color', 'k');
        set(0, 'CurrentFigure', fig_aoi)
        img_black = zeros(h, w, 3);
        imshow(img_black, 'border', 'tight')
        hold on

        idx_def = 1;
        for c = 1:numClusters
            
            % skip invalid clusters
            if ~clus.cluster_validity(c), continue, end
        
            % plot AOI
            img_col = repmat(reshape(cols(c, :), 1, 1, 3), h, w);
            hImg_col = imagesc(img_col);
            set(hImg_col, 'AlphaData', hm{c});
            
            % make def entry
            def{idx_def, 1} = sprintf('Cluster_%d', c);
            def{idx_def, 2} = {round(cols(c, :) * 255)};
            idx_def = idx_def + 1;
            
        end
        
        % get image and store in cluster struct
        frame_aoi = getframe(fig_aoi);
        img_aoi = frame2im(frame_aoi);
        delete(fig_aoi)
    
    if nargout == 3
        clus.stimulus = img;
        clus.heatmaps = hm;
        clus.image_overlay = img_overlay;
        clus.image_aoi = img_aoi;
    end
    
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