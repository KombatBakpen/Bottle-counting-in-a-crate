%% Developed by Bakpen Kombat 
%{
%% Discription 
 Introduction
The purpose of this algorithm is to detect and count the number of bottles present in an image of a bottle crate.
The algorithm utilizes image processing techniques to isolate and identify circular objects representing bottles.
2 Image Preprocessing Step
• The algorithm begins by reading the input image of the bottle crate.
• If the image is in color, it is converted to grayscale for easier processing.
• Top-hat transform is applied to enhance the contrast of the grayscale image, particularly emphasizing bright
regions against a relatively dark background.
• The enhanced grayscale image is binarized using Otsu’s thresholding method to segment objects from the
background.
• Morphological closing operation is performed to smooth the binary image and fill in small gaps or holes within
the objects.
• A bounding box is defined to specify the region of interest (ROI) within the bottle crate area.
• A binary mask is created based on the bounding box to isolate the ROI from the rest of the image.
• The binary mask is applied to the binary image obtained from the previous step to extract the ROI.
3 Circle Detection using Hough Transform
• Hough transform is applied to detect circular objects within the ROI.
• Two separate rounds of circle detection are performed with different radius ranges:
– Detect the bottle cap.
– Detect the bottle bottom.
• Detected circle centers and radii are obtained from the Hough transform.
4 Post-processing
Detected circles are subjected to a post-processing step to remove or merge closely spaced circles, which may
represent overlapping circles or artifacts.
• A custom function merge or remove circles is implemented for this purpose.
• The function iterates through pairs of detected circles, calculates the distance between their centers, and
compares their radii.
• If the distance between two circles is below a predefined threshold, the circle with the larger radius is removed.
• This step helps in eliminating false detections and ensuring accurate counting.
5 Counting and Visualization
• The total number of circles (representing bottles) after post-processing is counted.
• Detected circles along with their counts are overlaid on the original grayscale image for visualization.
• The total count is displayed as text on the image for easy interpretation.
6 Conclusion
The algorithm effectively detects and counts the number of bottles present in the input image of a bottle crate.
By employing a combination of image preprocessing, circle detection using Hough transform, and post-processing
techniques, it achieves accurate and reliable bottle counting results. Additionally, the algorithm is flexible and
can be adapted to different bottle crate images with minor adjustments to parameters and thresholds
%}

%% Main project || link to the dataset: https://drive.google.com/drive/folders/14s4-DZgKeZunv0BSfogwnphJaVM50i60 
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

