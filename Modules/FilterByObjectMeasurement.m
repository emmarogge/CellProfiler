function handles = FilterByObjectMeasurement(handles)

% Help for the Filter Objects by Measurement module: 
% Category: Object Processing
%
% This module applies a filter using measurements produced by either
% MeasureObjectAreaShape, MeasureObjectIntensity, or MeasureObjectTexture
% modules. All objects outside of the specified parameters will be
% discarded.
%
% Feature Number:
% The feature number is the parameter from the chosen module (AreaShape,
% Intensity, Texture) which will be used for the filter. The following
% tables provide the feature numbers for each measurement made by the three
% modules:
%
% Area Shape:               Feature Number:
% Area                    |       1
% Eccentricity            |       2
% Solidity                |       3
% Extent                  |       4
% Euler Number            |       5
% Perimeter               |       6
% Form factor             |       7
% MajorAxisLength         |       8
% MinorAxisLength         |       9
%
% Intensity:                Feature Number:
% IntegratedIntensity     |       1
% MeanIntensity           |       2
% StdIntensity            |       3
% MinIntensity            |       4
% MaxIntensity            |       5
% IntegratedIntensityEdge |       6
% MeanIntensityEdge       |       7
% StdIntensityEdge        |       8
% MinIntensityEdge        |       9
% MaxIntensityEdge        |      10
% MassDisplacement        |      11
%
% Texture:                  Feature Number:
% AngularSecondMoment     |       1
% Contrast                |       2
% Correlation             |       3
% Variance                |       4
% InverseDifferenceMoment |       5
% SumAverage              |       6
% SumVariance             |       7
% SumEntropy              |       8
% Entropy                 |       9
% DifferenceVariance      |      10
% DifferenceEntropy       |      11
% InformationMeasure      |      12
% InformationMeasure2     |      13
% Gabor1x                 |      14
% Gabor1y                 |      15
% Gabor2x                 |      16
% Gabor2y                 |      17
% Gabor3x                 |      18
% Gabor3y                 |      19
%
% See also MEASUREOBJECTAREASHAPE, MEASUREOBJECTINTENSITY,
% MEASUREOBJECTTEXTURE

CurrentModule = handles.Current.CurrentModuleNumber;
CurrentModuleNum = str2double(CurrentModule);
ModuleName = handles.Settings.ModuleNames(CurrentModuleNum);

%textVAR01 = What did you call the original image?
%infotypeVAR01 = imagegroup
%inputtypeVAR01 = popupmenu
ImageName = char(handles.Settings.VariableValues{CurrentModuleNum,1});

%textVAR02 = What did you call the objects you want to process?
%infotypeVAR02 = objectgroup
%inputtypeVAR02 = popupmenu
ObjectName = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = What do you want to call the filtered objects?
%defaultVAR03 = FilteredNuclei
%infotypeVAR03 = objectgroup indep
TargetName = char(handles.Settings.VariableValues{CurrentModuleNum,3});

%textVAR04 = What measurement do you want to filter by?
%choiceVAR04 = AreaShape
%choiceVAR04 = Intensity
%choiceVAR04 = Texture
%inputtypeVAR04 = popupmenu
MeasureChoice = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = What feature number do you want to  use as a filter? Please run this module after MeasureObject module.
%defaultVAR05 = 1
FeatureNum = char(handles.Settings.VariableValues{CurrentModuleNum,5});
FeatureNum = str2num(FeatureNum);

%textVAR06 = Minimum value required:
%choiceVAR06 = 0.5
%choiceVAR06 = Do not use
%inputtypeVAR06 = popupmenu custom
MinValue1 = char(handles.Settings.VariableValues{CurrentModuleNum,6});

%textVAR07 = Maximum value allowed:
%choiceVAR07 = Do not use
%inputtypeVAR07 = popupmenu custom
MaxValue1 = char(handles.Settings.VariableValues{CurrentModuleNum,7});

%textVAR08 = What do you want to call the image of the colored objects?
%choiceVAR08 = Do not save
%infotypeVAR08 = imagegroup indep
%inputtypeVAR08 = popupmenu custom
SaveColored = char(handles.Settings.VariableValues{CurrentModuleNum,8});

%textVAR09 = What do you want to call the image of the outlines of the objects?
%choiceVAR09 = Do not save
%infortypeVAR09 = imagegroup indep
%inputtypeVAR09 = popupmenu custom
SaveOutlined = char(handles.Settings.VariableValues{CurrentModuleNum,9});

%%%VariableRevisionNumber = 1

OrigImage = handles.Pipeline.(ImageName);
LabelMatrixImage = handles.Pipeline.(['Segmented' ObjectName]);

if strcmp(MeasureChoice,'Intensity')
    fieldname = ['Intensity_',ImageName];
    MeasureInfo = handles.Measurements.(ObjectName).(fieldname){handles.Current.SetBeingAnalyzed}(:,FeatureNum);
elseif strcmp(MeasureChoice,'AreaShape')
    MeasureInfo = handles.Measurements.(ObjectName).AreaShape{handles.Current.SetBeingAnalyzed}(:,FeatureNum);
elseif strcmp(MeasureChoice,'Texture')
    fieldname = ['Texture_',ImageName];
    MeasureInfo = handles.Measurements.(ObjectName).(fieldname){handles.Current.SetBeingAnalyzed}(:,FeatureNum);
end

if strcmp(MinValue1, 'Do not use')
    MinValue1 = -Inf;
else
    MinValue1 = str2double(MinValue1);
end

if strcmp(MaxValue1, 'Do not use')
    MaxValue1 = Inf;
else
    MaxValue1 = str2double(MaxValue1);
end

Filter = find((MeasureInfo < MinValue1) | (MeasureInfo > MaxValue1));
FinalLabelMatrixImage = LabelMatrixImage;
for i=1:numel(Filter)
    FinalLabelMatrixImage(FinalLabelMatrixImage == Filter(i)) = 0;
end

FinalLabelMatrixImage = bwlabel(FinalLabelMatrixImage);

%%% Calculates the object outlines, which are overlaid on the original
%%% image and displayed in figure subplot (2,2,4).
%%% Creates the structuring element that will be used for dilation.
StructuringElement = strel('square',3);
%%% Converts the FinalLabelMatrixImage to binary.
FinalBinaryImage = im2bw(FinalLabelMatrixImage,.1);
%%% Dilates the FinalBinaryImage by one pixel (8 neighborhood).
DilatedBinaryImage = imdilate(FinalBinaryImage, StructuringElement);
%%% Subtracts the FinalBinaryImage from the DilatedBinaryImage,
%%% which leaves the PrimaryObjectOutlines.
PrimaryObjectOutlines = DilatedBinaryImage - FinalBinaryImage;
%%% Overlays the object outlines on the original image.
ObjectOutlinesOnOrigImage = OrigImage;
%%% Determines the grayscale intensity to use for the cell outlines.
LineIntensity = max(OrigImage(:));
ObjectOutlinesOnOrigImage(PrimaryObjectOutlines == 1) = LineIntensity;

%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow 

fieldname = ['FigureNumberForModule',CurrentModule];
ThisModuleFigureNumber = handles.Current.(fieldname);
if any(findobj == ThisModuleFigureNumber) == 1
    drawnow
    CPfigure(handles,ThisModuleFigureNumber);
    %%% A subplot of the figure window is set to display the original image.
    subplot(2,2,1); imagesc(OrigImage);
    title(['Input Image, Image Set # ',num2str(handles.Current.SetBeingAnalyzed)]);
    %%% A subplot of the figure window is set to display the colored label
    %%% matrix image.
    subplot(2,2,3); imagesc(LabelMatrixImage); title(['Segmented ',ObjectName]);
    %%% A subplot of the figure window is set to display the Overlaid image,
    %%% where the maxima are imposed on the inverted original image
    try
        ColoredLabelMatrixImage = CPlabel2rgb(handles,FinalLabelMatrixImage);
    catch
        ColoredLabelMatrixImage = FinalLabelMatrixImage;
    end
    subplot(2,2,2); imagesc(ColoredLabelMatrixImage); title(['Filtered ' ObjectName]);
    %%% A subplot of the figure window is set to display the inverted original
    %%% image with watershed lines drawn to divide up clusters of objects.
    subplot(2,2,4); imagesc(ObjectOutlinesOnOrigImage); title([TargetName, ' Outlines on Input Image']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

handles.Pipeline.(['Segmented' TargetName]) = FinalLabelMatrixImage;

if ~strcmp(SaveColored,'Do not save')
    try handles.Pipeline.(SaveColored) = ColoredLabelMatrixImage;
    catch
        errordlg(['The colored image was not calculated by the ', ModuleName, ' module so these images were not saved to the handles structure. Image processing is still in progress, but the Save Images module will fail if you attempted to save these images.'])
    end
end
if ~strcmp(SaveOutlined,'Do not save')
    try handles.Pipeline.(SaveOutlined) = PrimaryObjectOutlines;
    catch
        errordlg(['The object outlines were not calculated by the ', ModuleName, ' module so these images were not saved to the handles structure. Image processing is still in progress, but the Save Images module will fail if you attempted to save these images.'])
    end
end