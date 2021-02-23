function clus = gcRemoveInvalidClusters(clus)

    idx = ~clus.cluster_validity;
    
    idx_samp = [];
    for c = 1:length(idx)
        if idx(c)
            idx_samp = [idx_samp, clus.cluster_members{c}];
        end
    end
    clus.cluster_idx(idx_samp) = [];
    clus.gaze_matrix(:, idx_samp) = [];
    clus.numGazePoints = size(clus.gaze_matrix, 2);
    
    clus.cluster_centre(:, idx) = [];
    clus.cluster_members(idx) = [];
    clus.cluster_validity(idx) = [];
    clus.cluster_propGaze(idx) = [];
    clus.cluster_numGazePoints(idx) = [];
    clus.numClusters = clus.numValidClusters;
 
end