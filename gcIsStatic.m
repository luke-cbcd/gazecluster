function val = gcIsStatic(clus)
    val = size(clus.gaze_matrix, 1) == 2;
end