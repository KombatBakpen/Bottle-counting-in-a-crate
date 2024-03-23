
clear; close all; clc;

%% First part: Function call will diplay the key preprocessing step as subplots 
%Instruction: choose the image you want ,
%             for example: countBottles(1)  will give results for 'bottle_crate_03.png' 
countBottles(1); 
%%  Second part: Loop for all the images and all bottle counted written into a txt file, "Bottles_counts.txt"

% read all images 
folder_path = 'bottle_crate_images';
file_list = dir(fullfile(folder_path, '*.png')); 

% Initialize a table to store the counts
counts = cell(length(file_list), 2);
counts{1, 1} = 'Image Name';
counts{1, 2} = 'Number of Bottles';

% Open the text file for writing
fid = fopen('Bottles_counts.txt', 'w'); 

% Write header
fprintf(fid, '%-20s %s\n', 'Image Name', 'Circle Count'); 
%% Main for Loop for preprocessing 

for i = 1:length(file_list)
    img_name = file_list(i).name;
    img = imread(fullfile(folder_path, img_name));

    % convert from RGB to gray
    if ndims(img) == 3 && size(img, 3) == 3
        img_gray = rgb2gray(img);
    else
        img_gray = img;
    end

    % top-hat morphology
    im_th = imtophat(img_gray, strel('disk', 95));

    % Binarize the image   
    im_bin = imbinarize(im_th, graythresh(im_th));

    % closing 
    im_closed = imclose(im_bin, strel('disk', 2));

    % Define the bounding box for the region of interest (ROI) (geometric operation)
    bbox = [50, 50, size(im_closed, 2) - 100, size(im_closed, 1) - 100]; % [x, y, width, height]

    % Create a binary mask for the ROI
    roi_mask = zeros(size(im_closed));
    roi_mask(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1) = 1;

    % Convert roi_mask to logical data type
    roi_mask = logical(roi_mask);

    % Apply the mask to the binary image
    im_roi = im_closed .* roi_mask;

    %% Hough transform to detect circles

    % detect the bottel cap
    [centers1, radii1, ~] = imfindcircles(im_roi, [12 23], ...
                                           'ObjectPolarity', 'bright', ...
                                           'Sensitivity', 0.92, ...
                                           'EdgeThreshold', 0.1);
    % detect the bottel bottom
    [centers2, radii2, ~] = imfindcircles(im_roi, [30 50], ...
                                           'ObjectPolarity', 'bright', ...
                                           'Sensitivity', 0.92, ...
                                           'EdgeThreshold', 0.1);

    % Combine the results from both detections
    all_centers = [centers1; centers2];
    all_radii = [radii1; radii2];

    % Post-process detected circles to remove or merge closely spaced circles
    [all_centers, all_radii] = merge_or_remove_circles(all_centers, all_radii);

    % Count the total number of circles detected after merging or removal
    num_circles = size(all_centers, 1);

    % Store the counts in the table
    counts{i+1, 1} = img_name;
    counts{i+1, 2} = num_circles;
    
    % Write counts to the text file
    fprintf(fid, '%-20s %d\n', img_name, num_circles);
end

fclose(fid); % Close the text file

disp('Counts have been saved to circle_counts.txt');

%% Function for processing a single image
function countBottles(imageNumber)

    % Generate the image filename based on the provided number
    imgFilename = sprintf('bottle_crate_images/bottle_crate_%02d.png', imageNumber);
    
    % Read the image
    img = imread(imgFilename);

    % Convert the image to grayscale if it's in color
    if ndims(img) == 3 && size(img, 3) == 3
        img_gray = rgb2gray(img);
    else
        img_gray = img;
    end
    figure;
    %subplot(3,3,1); imshow(img_gray); title("original Image")

    % Perform top-hat transform
    im_th = imtophat(img_gray, strel('disk', 95));
    imshow(im_th); title("top-hat")
    subplot()
    % Binarize the image and perform morphological operations
    im_bin = imbinarize(im_th, graythresh(im_th));
    im_closed = imclose(im_bin, strel('disk', 2));

    % Define the bounding box for the region of interest (ROI)
    bbox = [50, 50, size(im_closed, 2) - 100, size(im_closed, 1) - 100]; % [x, y, width, height]

    % Create a binary mask for the ROI
    roi_mask = zeros(size(im_closed));
    roi_mask(bbox(2):bbox(2)+bbox(4)-1, bbox(1):bbox(1)+bbox(3)-1) = 1;

    % Convert roi_mask to logical data type
    roi_mask = logical(roi_mask);

    % Apply the mask to the binary image
    im_roi = im_closed .* roi_mask;

    % Hough transform to detect circles
    [centers1, radii1, ~] = imfindcircles(im_roi, [12 23], ...
                                           'ObjectPolarity', 'bright', ...
                                           'Sensitivity', 0.92, ...
                                           'EdgeThreshold', 0.1);

    [centers2, radii2, ~] = imfindcircles(im_roi, [30 50], ...
                                           'ObjectPolarity', 'bright', ...
                                           'Sensitivity', 0.92, ...
                                           'EdgeThreshold', 0.1);

    % Combine the results from both detections
    all_centers = [centers1; centers2];
    all_radii = [radii1; radii2];

    % Post-process detected circles to remove or merge closely spaced circles
    % we have build a function for that 
    [all_centers, all_radii] = merge_or_remove_circles(all_centers, all_radii);

    % Count the total number of circles detected after merging or removal
    numCircles = size(all_centers, 1);

    % Display the circles on the original grayscale image
    imshow(img_gray);
    viscircles(all_centers, all_radii, 'EdgeColor', 'b'); % Overlay the detected circles
    text(10, 20, ['Total number of circles: ' num2str(numCircles)], 'Color', 'red', 'FontSize', 12, 'FontWeight', 'bold'); % write the total number on the image
end

%% function for detecting centers and radius; this function is used in both parts of the code
function [centers, radii] = merge_or_remove_circles(centers, radii)
    % Threshold for considering circles as closely spaced
    minDistanceThreshold = 50;

    % Initialize indices of circles to be removed
    circlesToRemove = [];

    % Loop through each pair of circles
    for i = 1:size(centers, 1)
        for j = i+1:size(centers, 1)
            % Calculate distance between circle centers
            distance = sqrt((centers(i,1) - centers(j,1))^2 + (centers(i,2) - centers(j,2))^2);

            % If the distance is less than the threshold, consider merging or removing circles
            if distance < minDistanceThreshold
                % Compare radii or other criteria to decide which circle to keep
                % For simplicity, here we remove the circle with larger radius
                if radii(i) > radii(j)
                    circlesToRemove = [circlesToRemove, i];
                else
                    circlesToRemove = [circlesToRemove, j];
                end
            end
        end
    end

    % Remove circles marked for removal
    centers(circlesToRemove, :) = [];
    radii(circlesToRemove) = [];
end

