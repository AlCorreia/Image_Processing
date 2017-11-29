clear all

pic = imread('banana.jpg');
pic_gray = rgb2gray(pic);
pic_hsv = rgb2hsv(pic);
h_pic = pic_hsv(:,:,1);
s_pic = pic_hsv(:,:,2);
v_pic = pic_hsv(:,:,3);

hueThresholdLow = 0.10;
hueThresholdHigh = 0.14;
saturationThresholdLow = 0.4;
saturationThresholdHigh = 1;
valueThresholdLow = 0.7;
valueThresholdHigh = 1.0;

smallestAcceptableArea=500;

hueMask = (h_pic >= hueThresholdLow) & (h_pic <= hueThresholdHigh);
saturationMask = (s_pic >= saturationThresholdLow) & (s_pic <= saturationThresholdHigh);
valueMask = (v_pic >= valueThresholdLow) & (v_pic <= valueThresholdHigh);

coloredObjectsMask = uint8(hueMask & saturationMask & valueMask);

% Get rid of small objects.  Note: bwareaopen returns a logical.
coloredObjectsMask = uint8(bwareaopen(coloredObjectsMask, smallestAcceptableArea));
% subplot(3, 3, 1);
% imshow(coloredObjectsMask, []);
% fontSize = 13;
% caption = sprintf('bwareaopen() removed objects\nsmaller than %d pixels', smallestAcceptableArea);
% title(caption, 'FontSize', fontSize);

% Smooth the border using a morphological closing operation, imclose().
structuringElement = strel('disk', 4);
coloredObjectsMask = imclose(coloredObjectsMask, structuringElement);
% subplot(3, 3, 2);
% imshow(coloredObjectsMask, []);
% fontSize = 16;
% title('Border smoothed', 'FontSize', fontSize);

% Fill in any holes in the regions, since they are most likely red also.
coloredObjectsMask = imfill(logical(coloredObjectsMask), 'holes');
% subplot(3, 3, 3);
% % imshow(coloredObjectsMask, []);
% title('Regions Filled', 'FontSize', fontSize);

filtered_image = uint8(double(pic_gray).*double(coloredObjectsMask));
sobel_mask = imcomplement(edge(filtered_image, 'sobel', 0.07));

structuringElement = strel('disk', 9);
sobel_mask = imerode(sobel_mask, structuringElement);
structuringElement = strel('disk', 4);
sobel_mask = imdilate(sobel_mask, structuringElement);

coloredObjectsMask = uint8(hueMask & saturationMask & valueMask & sobel_mask);

% Get rid of small objects.  Note: bwareaopen returns a logical.
coloredObjectsMask = uint8(bwareaopen(coloredObjectsMask, smallestAcceptableArea));
% subplot(3, 3, 1);
% imshow(coloredObjectsMask, []);
% fontSize = 13;
% caption = sprintf('bwareaopen() removed objects\nsmaller than %d pixels', smallestAcceptableArea);
% title(caption, 'FontSize', fontSize);

% Smooth the border using a morphological closing operation, imclose().
structuringElement = strel('disk', 2);
coloredObjectsMask = imclose(coloredObjectsMask, structuringElement);
% subplot(3, 3, 2);
% imshow(coloredObjectsMask, []);
% fontSize = 16;
% title('Border smoothed', 'FontSize', fontSize);

% Fill in any holes in the regions, since they are most likely red also.
coloredObjectsMask = imfill(logical(coloredObjectsMask), 'holes');
% subplot(3, 3, 3);
% % imshow(coloredObjectsMask, []);
% title('Regions Filled', 'FontSize', fontSize);


coloredObjectsMask = uint8(coloredObjectsMask & sobel_mask);


[meanHSV, areas, numberOfBlobs] = MeasureBlobs(coloredObjectsMask, h_pic, s_pic, v_pic);

function [meanHSV, areas, numberOfBlobs] = MeasureBlobs(maskImage, hImage, sImage, vImage)
try
	[labeledImage, numberOfBlobs] = bwlabel(maskImage, 8);     % Label each blob so we can make measurements of it
    coloredLabels = label2rgb(labeledImage, 'hsv', 'k', 'shuffle');
    imshow(coloredLabels);
	if numberOfBlobs == 0
		% Didn't detect any blobs of the specified color in this image.
		meanHSV = [0 0 0];
		areas = 0;
		return;
	end
	% Get all the blob properties.  Can only pass in originalImage in version R2008a and later.
	blobMeasurementsHue = regionprops(labeledImage, hImage, 'area', 'MeanIntensity');
	blobMeasurementsSat = regionprops(labeledImage, sImage, 'area', 'MeanIntensity');
	blobMeasurementsValue = regionprops(labeledImage, vImage, 'area', 'MeanIntensity');
	
	meanHSV = zeros(numberOfBlobs, 3);  % One row for each blob.  One column for each color.
	meanHSV(:,1) = [blobMeasurementsHue.MeanIntensity]';
	meanHSV(:,2) = [blobMeasurementsSat.MeanIntensity]';
	meanHSV(:,3) = [blobMeasurementsValue.MeanIntensity]';
	
	% Now assign the areas.
	areas = zeros(numberOfBlobs, 3);  % One row for each blob.  One column for each color.
	areas(:,1) = [blobMeasurementsHue.Area]';
	areas(:,2) = [blobMeasurementsSat.Area]';
	areas(:,3) = [blobMeasurementsValue.Area]';
catch ME
	errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
		ME.stack(1).name, ME.stack(1).line, ME.message);
	fprintf(1, '%s\n', errorMessage);
	uiwait(warndlg(errorMessage));
end
return; % from MeasureBlobs()
end
	
