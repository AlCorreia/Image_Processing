clear all
fontSize = 9;

% Read the image file as RGB
pic = imread('images/banana13.jpg');
% Calculate the number of pixels to correct erode and dilation kernel sizes
[num_pixels_1, num_pixels_2, xxx] = size(pic);
num_pixels = (num_pixels_1 * num_pixels_2);
coeff = sqrt(num_pixels/250000);

% Convert the image to hsv
pic_gray = rgb2gray(pic);
pic_hsv = rgb2hsv(pic);
h_pic = pic_hsv(:,:,1);
s_pic = pic_hsv(:,:,2);
v_pic = pic_hsv(:,:,3);

% Define the thresholds that define the color yellow
% Those are larger than what is strictily defined as yellow so as to not
% risk missing any pixel. A second mask is applied later on to remove any
% other colors.
hueThresholdLow = 0.10;
hueThresholdHigh = 0.14;
saturationThresholdLow = 0.4;
saturationThresholdHigh = 1;
valueThresholdLow = 0.6;
valueThresholdHigh = 1.0;

% Define the size of the smallest acceptable area. 
% Smaller areas will be removed.
smallestAcceptableArea=round(1000*coeff);

% Define a mask for each hsv component with the thresholds.
hueMask = (h_pic >= hueThresholdLow) & (h_pic <= hueThresholdHigh);
saturationMask = (s_pic >= saturationThresholdLow) & (s_pic <= saturationThresholdHigh);
valueMask = (v_pic >= valueThresholdLow) & (v_pic <= valueThresholdHigh);
% The final mask is a the intersection of the three above
coloredObjectsMask = uint8(hueMask & saturationMask & valueMask);

% Remove small objects.
coloredObjectsMask = uint8(bwareaopen(coloredObjectsMask, smallestAcceptableArea));
subplot(3, 3, 1);
imshow(coloredObjectsMask, []);
caption = sprintf('Objects of %d Pixels Removed', smallestAcceptableArea);
title(caption, 'FontSize', fontSize);
fontSize = 13;

% Close holes with imclose() to obtain a smoother image.
structuringElement = strel('disk', round(11*coeff));
coloredObjectsMask = imclose(coloredObjectsMask, structuringElement);
subplot(3, 3, 2);
imshow(coloredObjectsMask, []);
title('Border smoothed', 'FontSize', fontSize);

% Fill in any holes, since they are also likely to be yellow.
coloredObjectsMask = imfill(logical(coloredObjectsMask), 'holes');
subplot(3, 3, 3);
imshow(coloredObjectsMask, []);
title('Regions Filled', 'FontSize', fontSize);

% Filter the original image in gray scale
filtered_image = uint8(double(pic_gray).*double(coloredObjectsMask));
% Apply Sobel border detection with low sensitivity
out_border = edge(coloredObjectsMask, 'sobel');
filtered_image = localcontrast(filtered_image);
subplot(3, 3, 4);
imshow(filtered_image, []);
title('First Filtering', 'FontSize', fontSize);

% Apply Sobel border detection with high sensitivity
sobel_mask = (edge(filtered_image, 'sobel', 0.04));
subplot(3, 3, 5);
imshow(sobel_mask, []);
title('Sobel Mask', 'FontSize', fontSize);

% Detect and Label the blobs
[labeledImage, numberOfBlobs] = bwlabel(sobel_mask, 8); 
blobMeasurements = regionprops(labeledImage, filtered_image);
delete = labeledImage*0;

% Remove small dots
for i =1:numel(blobMeasurements)
    square = blobMeasurements(i).BoundingBox;
    ratio = blobMeasurements(i).Area/(square(3)*square(4));
    max_dim = max(square(3:4));
    min_dim = min(square(3:4));
    cte=5;
    if max_dim<=4 || (ratio<(1/min_dim)*cte&& ratio>(1-1/min_dim)/cte) %0.2 0.8
    delete = delete+(labeledImage==i);
    end
end

% Redefine the borders by summing
sobel_mask = max(sobel_mask-delete,0);
sobel_mask = imcomplement(min(sobel_mask+out_border,1));

subplot(3, 3, 6);
imshow(delete)
title('Pixels to delete')

% Calculate the intersection between the masks and the sobel
coloredObjectsMask = uint8(coloredObjectsMask & sobel_mask);

% Apply erosion
structuringElement = strel('disk', round(11*coeff));
coloredObjectsMask = imerode(coloredObjectsMask, structuringElement);
subplot(3, 3, 7);
imshow(coloredObjectsMask, []);
title('After Erode', 'FontSize', fontSize);

% Apply dilation
structuringElement = strel('disk', round(5*coeff));
coloredObjectsMask = imdilate(coloredObjectsMask, structuringElement);
subplot(3, 3, 8);
imshow(coloredObjectsMask, []);
title('After Dilate', 'FontSize', fontSize);

% Filter small regions
coloredObjectsMask = uint8(bwareaopen(coloredObjectsMask, smallestAcceptableArea));

% Apply Blobify to define the final blobs and extract properties
[meanHSV, areas, numberOfBlobs, labeledImage] = Blobify(coloredObjectsMask, h_pic, s_pic, v_pic, coeff);
final_figure=figure;
labeledImage2 = labeledImage>0;
edges_new = imdilate(edge(labeledImage2,'sobel'), strel('disk', round(3*coeff)))*255;
filt_m = pic;
filt_m(:,:,1) = uint8(max(double(pic(:,:,1))-double(edges_new),0));
filt_m(:,:,2) = uint8(max(double(pic(:,:,2))-double(edges_new),0));
filt_m(:,:,3) = uint8(max(double(pic(:,:,3))-double(edges_new),0));
imshow(filt_m)
properties_reg = regionprops(labeledImage);
sizefig = size(pic);
index_lin = repmat([1:sizefig(1)]',[1,sizefig(2)]);
index_col = repmat([1:sizefig(2)],[sizefig(1),1]);

for i =1:numberOfBlobs
    % Add the name of the centroid
    txt1 = '\leftarrow sin(\pi) = 0';
    Centroid = properties_reg(i).Centroid;
    tx = text(Centroid(1),Centroid(2),['B',int2str(i)]);
    tx.FontSize = 16;
    tx.FontWeight = 'bold'; 
    tx.Color = [1.0,0,0];
    hold on
    % Select blob i and calculate its moment inertia to extract the
    % principal directions
    fig_blob = labeledImage==i;
    mass = sum(sum(fig_blob));
    fig_blob_lin = sum(sum((fig_blob.*(index_lin-Centroid(2))).^2));
    fig_blob_col = sum(sum((fig_blob.*(index_col-Centroid(1))).^2));
    fig_blob_lincol = -sum(sum((fig_blob.*(index_lin-Centroid(2))).*(fig_blob.*(index_col-Centroid(1)))));
    mat = [fig_blob_lin, fig_blob_lincol; fig_blob_lincol, fig_blob_col];
    [a,b] = eig(mat);
    % Plot the principal directions on each blob
    quiver(Centroid(1),Centroid(2),a(1,2)*60,a(2,2)*60,0,'lineWidth',2,'Color','b','MaxHeadSize',14)
    quiver(Centroid(1),Centroid(2),a(1,1)*60,a(2,1)*60,0,'lineWidth',2,'Color','r','MaxHeadSize',14)
end

function [meanHSV, areas, numberOfBlobs, labeledImage] = Blobify(maskImage, hImage, sImage, vImage, coeff)
try
    % Label each blob to allow for further measurements
	[labeledImage, numberOfBlobs] = bwlabel(maskImage, 8);
    
	if numberOfBlobs == 0
		% Didn't detect anything on this image.
		meanHSV = [0 0 0];
		areas = 0;
		return;
    end
    
    % Apply imclose to each blob individually.
    matrizref = 0*labeledImage;
    for i=1:numberOfBlobs
        structuringElement = strel('disk', round(21*coeff));
        matrizref = matrizref + imclose(labeledImage==i, structuringElement);
    end
    
    % Recalculate the blobs.
    [labeledImage, numberOfBlobs] = bwlabel(matrizref, 8);
    
    % Get all the blob properties.
	blobMeasurementsHue = regionprops(labeledImage, hImage, 'area', 'MeanIntensity');
	blobMeasurementsSat = regionprops(labeledImage, sImage, 'area', 'MeanIntensity');
	blobMeasurementsValue = regionprops(labeledImage, vImage, 'area', 'MeanIntensity');
    
    % Assign the areas.
    % One row for each blob. One column for each color.
	areas = zeros(numberOfBlobs, 3);  
	areas(:,1) = [blobMeasurementsHue.Area]';
	areas(:,2) = [blobMeasurementsSat.Area]';
	areas(:,3) = [blobMeasurementsValue.Area]';
    
    % Assign mean hsv values
    meanHSV = zeros(numberOfBlobs, 3);
	meanHSV(:,1) = [blobMeasurementsHue.MeanIntensity]';
	meanHSV(:,2) = [blobMeasurementsSat.MeanIntensity]';
	meanHSV(:,3) = [blobMeasurementsValue.MeanIntensity]';
    
    % Assign a different color to each blob and plot them all
    coloredLabels = label2rgb(labeledImage, 'hsv', 'k', 'shuffle');
    subplot(3, 3, 9);
    imshow(coloredLabels, []);
	title('Final Blobs', 'FontSize', 13);

catch ME
	errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
		ME.stack(1).name, ME.stack(1).line, ME.message);
	fprintf(1, '%s\n', errorMessage);
	uiwait(warndlg(errorMessage));
end
return; % from Blobify()
end
	
