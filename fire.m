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
valueThresholdLow = 0.8;
valueThresholdHigh = 1.0;

hueMask = (h_pic >= hueThresholdLow) & (h_pic <= hueThresholdHigh);
saturationMask = (s_pic >= saturationThresholdLow) & (s_pic <= saturationThresholdHigh);
valueMask = (v_pic >= valueThresholdLow) & (v_pic <= valueThresholdHigh);

coloredObjectsMask = uint8(hueMask & saturationMask & valueMask);

[meanHSV, areas, numberOfBlobs] = MeasureBlobs(coloredObjectsMask, h_pic, s_pic, v_pic);

function [meanHSV, areas, numberOfBlobs] = MeasureBlobs(maskImage, hImage, sImage, vImage)
try
	[labeledImage, numberOfBlobs] = bwlabel(maskImage, 8);     % Label each blob so we can make measurements of it
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
	
