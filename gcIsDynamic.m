function val = gcIsDynamic(clus)
    val = size(clus.gaze_matrix, 1) == 3;
end