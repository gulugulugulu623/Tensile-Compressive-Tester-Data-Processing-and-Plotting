%% forcompress.m
% 用途：
%   1. 读取拉伸/压缩实验 CSV 文件。
%   2. 绘制同一样品的 Stress-Strain 曲线图。
%   3. 计算 Young's modulus 和 Fracture strain，并生成结果列表。
%   4. 绘制所有最优组分的 Stress-Strain 对比图。
%   5. 绘制 Young's modulus - Fracture strain 双轴柱状图。
%
% 使用方法：
%   1. 在 MATLAB 中运行本脚本。
%   2. 按命令窗口提示输入 DATA，例如 260512。
%   3. 在弹窗中选择 CSV 文件所在文件夹。
%   4. 图片会保存到 D:\raw_data\fig\DATA 文件夹。
%
% 说明：
%   本脚本故意写了较详细的注释，方便 MATLAB 初学者理解和后续修改。

%% ========== 1. 清理环境 ==========
% clear 用于清空工作区变量，close all 用于关闭旧图片窗口，clc 用于清空命令窗口。
clear;
close all;
clc;

%% ========== 2. 初始化绘图和计算参数 ==========
% 所有可调参数集中放在 params 结构体里。
% 以后如果想改颜色、线宽、图片尺寸，优先改这里。
params = initParams();

%% ========== 3. 获取用户输入路径 ==========
% DATA 是用于输出文件夹和 multi_DATA.tif 文件名的字符串。
% dataDir 是用户通过弹窗选择的 CSV 文件夹。
% outputDir 是图片输出文件夹。
[DATA, dataDir, outputDir] = getUserPaths();

%% ========== 4. 读取并整理所有 CSV 文件 ==========
% fileData 是结构体数组，每个元素对应一个 CSV 文件。
% unitInfo 保存 Strain 和 Stress 的单位，用于坐标轴标题。
[fileData, unitInfo] = readAllCsvFiles(dataDir);

%% ========== 5. 计算每条曲线的断裂终点和杨氏模量 ==========
% curveData 会在 fileData 的基础上增加：
%   X、Y              ：截取到断裂终点的有效绘图数据
%   FractureIndex    ：断裂终点在原数据中的行号
%   FractureStrain   ：断裂应变，即曲线最后一个 X 值
%   PeakStress       ：峰值应力
%   YoungModulus     ：该曲线拟合得到的 Young's modulus
%   UseExtendedLayout：是否需要采用“左上文本、右上图例、x 轴放大 1.4 倍”的布局
curveData = prepareCurveData(fileData, params);

%% ========== 6. 绘制同一样品名称的 Stress-Strain 图，并生成结果列表 ==========
% Young_modulus_Fracture_strain 是题目要求的 cell 列表。
% 第一行是表头，从第二行开始是每个样品的统计结果。
Young_modulus_Fracture_strain = plotSampleStressStrain(curveData, unitInfo, outputDir, params);

%% ========== 7. 绘制最优组分 Stress-Strain 对比图 ==========
% 这里只复用 curveData 中已经处理好的曲线数据，不再重复读取 CSV。
plotBestStressStrain(curveData, unitInfo, outputDir, DATA, params);

%% ========== 8. 绘制 Young's modulus - Fracture strain 双轴柱状图 ==========
% 如果结果列表中没有样品数据，则跳过柱状图，避免空数据报错。
if size(Young_modulus_Fracture_strain, 1) > 1
    plotBiaxialBarChart(Young_modulus_Fracture_strain, outputDir, params);
else
    warning('Young_modulus_Fracture_strain 中没有样品数据，已跳过双轴柱状图。');
end

%% ========== 9. 在命令窗口显示结果 ==========
% 这个变量会保留在工作区，方便用户查看或手动复制到其他地方。
disp('计算完成。Young_modulus_Fracture_strain 内容如下：');
disp(Young_modulus_Fracture_strain);
fprintf('所有图片已保存到：%s\n', outputDir);

%% ========================================================================
% 下面是本脚本使用的本地函数。
% MATLAB 允许在脚本末尾定义函数，这样主流程可以保持简洁。
% ========================================================================

function params = initParams()
    % initParams
    % 功能：
    %   集中保存脚本中常用的绘图参数、颜色参数和计算参数。
    % 输出：
    %   params - 参数结构体。

    % 题目指定的曲线颜色池。
    % 注意：最新版 MATLAB 可以直接使用 '#RRGGBB' 形式的颜色，不需要转换为 RGB。
    params.curveColors = {'#c93735', '#F8AB61', '#78A9CD', '#c2bdde', '#333a8c'};

    % 字体、坐标轴和普通文字使用深灰色，避免使用纯黑色。
    % 误差棒按题目要求会单独使用黑色。
    params.textColor = '#4A4A4A';

    % 图片尺寸，单位是 inch。
    params.figureWidth = 2;
    params.figureHeight = 1.4;

    % 导出图片分辨率。
    params.resolution = 600;

    % Stress-Strain 图的线宽。
    params.curveLineWidth = 1.0;

    % 坐标轴线宽，参考原始脚本中的 axis_line_width。
    params.axisLineWidth = 1.2;

    % 所有字体统一为 Arial 7 号。
    params.fontName = 'Arial';
    params.fontSize = 7;

    % 断裂点判定参数：
    % 峰值后某点低于峰值的 20%，或者绝对值低于 0.5，即认为到达断裂附近。
    params.peakRatio = 0.2;
    params.absThreshold = 0.5;

    % 找到断裂附近点以后，取其后第 10 个数据点作为实际绘图终点。
    params.pointsAfterBreak = 10;

    % Young's modulus 两点斜率位置：
    % 取断裂应变的 0.33 倍和 0.66 倍这两个 x 位置。
    params.modulusStartRatio = 0.33;
    params.modulusEndRatio = 0.66;

    % 双轴柱状图参数。
    params.barWidth = 0.4;
    params.barEdgeLineWidth = 0.8;
    params.errorBarCapSize = 4;

    % 柱状图颜色。
    params.modulusFaceColor = '#fa8878';
    params.modulusEdgeColor = '#EB5038';
    params.strainFaceColor = '#82afda';
    params.strainEdgeColor = '#3888D8';

    % 图例短线宽度。MATLAB 的 IconColumnWidth 单位不是 inch，
    % 这里保留为一个可调数值，后续想让图例短线更长/更短可以改它。
    params.legendIconWidth = 5;

    % 让随机颜色每次运行都重新随机。
    rng('shuffle');
end

function [DATA, dataDir, outputDir] = getUserPaths()
    % getUserPaths
    % 功能：
    %   获取用户输入的 DATA，弹窗选择 CSV 文件夹，并创建输出文件夹。
    % 输出：
    %   DATA      - 用户输入的字符串，用于命名输出文件夹和 multi_DATA.tif。
    %   dataDir   - CSV 文件所在文件夹。
    %   outputDir - 图片输出文件夹，固定为 D:\raw_data\fig\DATA。

    % DATA 用字符串读取，避免输入 001 这类编号时前导 0 丢失。
    DATA = input('请输入 DATA（例如 260512，用于输出文件夹和文件名）：', 's');

    % 如果用户直接按回车，则使用当前日期时间作为备用名称。
    if strlength(string(DATA)) == 0
        DATA = char(datetime("now", "Format", "yyMMdd_HHmmss"));
        fprintf('未输入 DATA，自动使用：%s\n', DATA);
    end

    % 弹窗选择 CSV 文件夹。
    dataDir = uigetdir(pwd, '请选择包含 CSV 文件的文件夹');

    % 如果用户在弹窗中点击取消，uigetdir 会返回数字 0。
    if isequal(dataDir, 0)
        error('未选择 CSV 文件夹，脚本已停止。');
    end

    % 输出路径按题目要求固定到 D:\raw_data\fig\DATA。
    outputDir = fullfile('D:', 'raw_data', 'fig', DATA);

    % 如果输出文件夹不存在，就自动创建。
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end
end

function [fileData, unitInfo] = readAllCsvFiles(dataDir)
    % readAllCsvFiles
    % 功能：
    %   读取文件夹中的所有 CSV 文件，并整理成结构体数组。
    % 输入：
    %   dataDir - CSV 文件所在文件夹。
    % 输出：
    %   fileData - 每个 CSV 文件对应一个结构体，保存文件名、样品名、数据等信息。
    %   unitInfo - 坐标轴单位信息，来自 CSV 第 2 行第 4、5 列。

    % 找到当前文件夹下所有 CSV 文件。
    csvFiles = dir(fullfile(dataDir, '*.csv'));

    % 如果没有 CSV 文件，直接报错，提醒用户检查路径。
    if isempty(csvFiles)
        error('在文件夹中没有找到 CSV 文件：%s', dataDir);
    end

    % 按文件名排序，让处理顺序稳定，方便复查结果。
    [~, sortIndex] = sort({csvFiles.name});
    csvFiles = csvFiles(sortIndex);

    % 初始化单位信息。后面读取第一个有效 CSV 时会填入真实单位。
    unitInfo.strainUnit = '';
    unitInfo.stressUnit = '';

    % 预先定义空结构体数组。这样后面 fileData(end+1) 会更稳定。
    fileData = struct( ...
        'OriginalName', {}, ...
        'FullSampleName', {}, ...
        'FilePath', {}, ...
        'SampleName', {}, ...
        'GroupName', {}, ...
        'TestType', {}, ...
        'TestLabel', {}, ...
        'IsBest', {}, ...
        'Strain', {}, ...
        'Stress', {}, ...
        'StrainUnit', {}, ...
        'StressUnit', {});

    % 逐个读取 CSV 文件。
    for i = 1:numel(csvFiles)
        filePath = fullfile(csvFiles(i).folder, csvFiles(i).name);
        [~, baseName, ~] = fileparts(csvFiles(i).name);

        % 从文件名中解析测试方法、样品名、分组名、是否最优。
        nameInfo = parseFileName(baseName);

        % 读取 CSV 第 2 行单位。
        [strainUnit, stressUnit] = readUnitsFromCsv(filePath);

        % 如果全局单位还没有记录，就使用当前文件的单位。
        if isempty(unitInfo.strainUnit) && ~isempty(strainUnit)
            unitInfo.strainUnit = strainUnit;
        end
        if isempty(unitInfo.stressUnit) && ~isempty(stressUnit)
            unitInfo.stressUnit = stressUnit;
        end

        % readmatrix 从第 3 行开始读取数值数据。
        % CSV 第 1 行是数据名称，第 2 行是单位，所以这里跳过 2 行。
        numericData = readmatrix(filePath, 'NumHeaderLines', 2);

        % 检查列数是否满足题目要求。
        if size(numericData, 2) < 5
            warning('文件 %s 少于 5 列，已跳过。', csvFiles(i).name);
            continue;
        end

        % 第 4 列是 Strain，第 5 列是 Stress。
        strain = numericData(:, 4);
        stress = numericData(:, 5);

        % 删除 Strain 或 Stress 为 NaN/Inf 的行，避免后续拟合和绘图报错。
        validRows = isfinite(strain) & isfinite(stress);
        strain = strain(validRows);
        stress = stress(validRows);

        % 如果有效数据不足 2 个点，无法绘图和拟合，跳过该文件。
        if numel(strain) < 2
            warning('文件 %s 有效数据点不足 2 个，已跳过。', csvFiles(i).name);
            continue;
        end

        % 将当前文件的信息加入结构体数组。
        fileData(end+1).OriginalName = baseName; %#ok<AGROW>
        fileData(end).FullSampleName = nameInfo.fullSampleName;
        fileData(end).FilePath = filePath;
        fileData(end).SampleName = nameInfo.sampleName;
        fileData(end).GroupName = nameInfo.groupName;
        fileData(end).TestType = nameInfo.testType;
        fileData(end).TestLabel = nameInfo.testLabel;
        fileData(end).IsBest = nameInfo.isBest;
        fileData(end).Strain = strain;
        fileData(end).Stress = stress;
        fileData(end).StrainUnit = strainUnit;
        fileData(end).StressUnit = stressUnit;
    end

    % 如果所有文件都没有读到单位，就使用题目中常见单位作为备用。
    if isempty(unitInfo.strainUnit)
        unitInfo.strainUnit = '(mm/mm)';
    end
    if isempty(unitInfo.stressUnit)
        unitInfo.stressUnit = '(kPa)';
    end

    if isempty(fileData)
        error('没有成功读取任何有效 CSV 数据。');
    end
end

function nameInfo = parseFileName(baseName)
    % parseFileName
    % 功能：
    %   根据 CSV 文件名解析样品信息、分组名称和最优标记。
    % 输入：
    %   baseName - 不含扩展名的文件名，例如 15mMPH7_1_b 或 15mMPH7_2。
    % 输出：
    %   nameInfo - 保存解析结果的结构体。
    %
    % 文件名规则：
    %   1. 不再读取第一个“测试方法”字段。
    %   2. 文件名按 [样品信息]_[分组]_[最优标记] 解析。
    %   3. 最优标记可以没有内容，例如 15mMPH7_2.csv。
    %   4. 如果最后一段是 b，则认为该文件是最优数据。

    parts = split(string(baseName), "_");
    parts = cellstr(parts);

    % 至少需要有样品信息这一段，否则无法继续处理。
    if isempty(parts) || isempty(parts{1})
        error('文件名格式无法解析：%s', baseName);
    end

    % 第一段是样品信息，也是同一样品分组绘图和结果列表使用的名称。
    sampleName = parts{1};

    % 只要最后一段是 b，就认为它是最优标记。
    isBest = strcmpi(parts{end}, 'b');

    % 第二段是分组。若文件名只有样品信息，没有分组，则分组记为空。
    if numel(parts) >= 2
        groupName = parts{2};
    else
        groupName = '';
    end

    % fullSampleName 保存完整的 [样品信息]_[分组]_[最优标记] 文本。
    % 例如 15mMPH7_1_b.csv 保存为 15mMPH7_1_b；
    % 例如 15mMPH7_2.csv 保存为 15mMPH7_2。
    if numel(parts) >= 3 || isBest
        fullSampleName = baseName;
    elseif numel(parts) == 2
        fullSampleName = strjoin(parts(1:2), '_');
    else
        fullSampleName = sampleName;
    end

    % 现在文件名不再提供测试方法。为了保留原有图中的文本框，
    % 这里默认显示 compression；如果以后需要拉伸图，可以在这里手动改成 tension。
    testType = 'c';
    testLabel = 'compression';

    nameInfo.fullSampleName = fullSampleName;
    nameInfo.testType = testType;
    nameInfo.sampleName = sampleName;
    nameInfo.groupName = groupName;
    nameInfo.isBest = isBest;
    nameInfo.testLabel = testLabel;
end

function [strainUnit, stressUnit] = readUnitsFromCsv(filePath)
    % readUnitsFromCsv
    % 功能：
    %   从 CSV 第 2 行读取第 4 列和第 5 列的单位文本。
    % 输入：
    %   filePath - CSV 文件完整路径。
    % 输出：
    %   strainUnit - Strain 单位，例如 (mm/mm)。
    %   stressUnit - Stress 单位，例如 (kPa)。

    strainUnit = '';
    stressUnit = '';

    fid = fopen(filePath, 'r');
    if fid < 0
        warning('无法打开文件读取单位：%s', filePath);
        return;
    end

    % 第 1 行是名称，第 2 行是单位。
    fgetl(fid);
    unitLine = fgetl(fid);
    fclose(fid);

    % 如果第 2 行不存在，直接返回空单位。
    if ~ischar(unitLine) && ~isstring(unitLine)
        return;
    end

    unitParts = split(string(unitLine), ",");

    % 第 4 列和第 5 列分别对应 Strain 和 Stress。
    if numel(unitParts) >= 5
        strainUnit = char(strtrim(unitParts(4)));
        stressUnit = char(strtrim(unitParts(5)));
    end
end

function curveData = prepareCurveData(fileData, params)
    % prepareCurveData
    % 功能：
    %   对每个 CSV 文件的数据进行断裂点判断和杨氏模量计算。
    % 输入：
%   fileData - readAllCsvFiles 读取到的原始曲线数据。
%   params   - 参数结构体，包含断裂点判断和拟合区间设置。
    % 输出：
    %   curveData - 增加了截取后曲线、断裂应变、峰值、杨氏模量等结果。

    curveData = fileData;

    for i = 1:numel(curveData)
        strain = curveData(i).Strain;
        stress = curveData(i).Stress;

        % 按题目规则找到绘图终点。
        endIndex = findFractureEndIndex(stress, params);

        % 截取到断裂终点，用于后续绘图和计算。
        x = strain(1:endIndex);
        y = stress(1:endIndex);

        % 峰值用于判断布局。
        [peakStress, ~] = max(stress);

        % 断裂应变就是截取后曲线的最后一个 x 值。
        fractureStrain = x(end);

        % 计算 Young's modulus。
        youngModulus = calcYoungModulus(x, y, fractureStrain, params);

        % 判断布局：
        % 在 x = 0.2 * 断裂应变处，比较对应 y 和 0.5 * 峰值。
        refX = 0.2 * fractureStrain;
        refY = getYAtX(x, y, refX);
        useExtendedLayout = refY > 0.5 * peakStress;

        % 保存所有计算结果。
        curveData(i).X = x;
        curveData(i).Y = y;
        curveData(i).FractureIndex = endIndex;
        curveData(i).FractureStrain = fractureStrain;
        curveData(i).PeakStress = peakStress;
        curveData(i).YoungModulus = youngModulus;
        curveData(i).UseExtendedLayout = useExtendedLayout;
    end
end

function endIndex = findFractureEndIndex(stress, params)
    % findFractureEndIndex
    % 功能：
    %   根据题目规则找到一条曲线的绘图终点。
    % 输入：
    %   stress - 应力数据，也就是 CSV 第 5 列。
    %   params - 参数结构体，包含断裂判断阈值。
    % 输出：
    %   endIndex - 绘图终点所在的数据行号。

    % 先找到应力峰值和峰值所在位置。
    [peakStress, peakIndex] = max(stress);

    % 默认终点是最后一个数据点。
    % 如果峰值后没有找到满足条件的点，就会使用这个默认值。
    endIndex = numel(stress);

    % 从峰值后一个点开始查找下降点。
    for j = (peakIndex + 1):numel(stress)
        % 条件 1：该点应力低于峰值的 20%。
        isBelowPeakRatio = stress(j) < peakStress * params.peakRatio;

        % 条件 2：该点应力绝对值低于 0.5。
        isBelowAbsThreshold = abs(stress(j)) < params.absThreshold;

        % 题目要求两个条件满足任意一个即可。
        if isBelowPeakRatio || isBelowAbsThreshold
            % 找到下降点后，取它后面第 10 个点作为绘图终点。
            % 如果后面不足 10 个点，就取最后一个点。
            endIndex = min(j + params.pointsAfterBreak, numel(stress));
            break;
        end
    end
end

function youngModulus = calcYoungModulus(strain, stress, fractureStrain, params)
    % calcYoungModulus
    % 功能：
    %   取断裂应变 0.33 倍和 0.66 倍处的两个点。
    %   用这两个点构成的直线斜率作为该曲线的 Young's modulus。
    % 输入：
    %   strain         - 截取后的 Strain 数据。
    %   stress         - 截取后的 Stress 数据。
    %   fractureStrain - 断裂应变，即该曲线最后一个 x 值。
    %   params         - 参数结构体，包含拟合范围比例。
    % 输出：
    %   youngModulus   - 两点直线斜率。如果两个 x 重合，则返回 NaN。

    xStart = params.modulusStartRatio * fractureStrain;
    xEnd = params.modulusEndRatio * fractureStrain;

    % 如果两个 x 值相同，斜率分母为 0，无法计算。
    if xEnd == xStart
        youngModulus = NaN;
        return;
    end

    % 通过插值获取 xStart 和 xEnd 对应的 y 值。
    % getYAtX 会处理实验数据中 x 重复的问题。
    yStart = getYAtX(strain, stress, xStart);
    yEnd = getYAtX(strain, stress, xEnd);

    % 两点式斜率：(y2 - y1) / (x2 - x1)。
    youngModulus = (yEnd - yStart) / (xEnd - xStart);
end

function yValue = getYAtX(x, y, targetX)
    % getYAtX
    % 功能：
    %   获取曲线在指定 x 位置附近的 y 值，用于布局判断。
    % 输入：
    %   x       - Strain 数据。
    %   y       - Stress 数据。
    %   targetX - 目标 x 值。
    % 输出：
    %   yValue  - targetX 对应的 y 值。
    %
    % 说明：
    %   有些实验数据开头会出现重复 x 值，例如多个 0。
    %   interp1 遇到重复 x 时容易报错，所以这里先去重。

    % 去掉重复的 x，只保留第一次出现的数据点。
    [uniqueX, uniqueIndex] = unique(x, 'stable');
    uniqueY = y(uniqueIndex);

    if numel(uniqueX) >= 2 && targetX >= min(uniqueX) && targetX <= max(uniqueX)
        % 在范围内时使用线性插值。
        yValue = interp1(uniqueX, uniqueY, targetX, 'linear');
    else
        % 如果 targetX 超出范围，则取距离 targetX 最近的数据点。
        [~, nearestIndex] = min(abs(x - targetX));
        yValue = y(nearestIndex);
    end
end

function resultList = plotSampleStressStrain(curveData, unitInfo, outputDir, params)
    % plotSampleStressStrain
    % 功能：
    %   按样品名称分组，为每个样品绘制一张 Stress-Strain 多曲线图。
    %   同时计算该样品的 Young's modulus 和 Fracture strain 统计结果。
    % 输入：
    %   curveData - 已经处理好断裂点和杨氏模量的曲线数据。
    %   unitInfo  - 坐标轴单位信息。
    %   outputDir - 图片输出文件夹。
    %   params    - 绘图参数。
    % 输出：
    %   resultList - 题目要求的 Young_modulus_Fracture_strain cell 列表。

    % 先创建题目要求的表头。
    resultList = { ...
        'concentration', ...
        'Young''s modulus(kPa)', ...
        'modulus SD', ...
        'Fracture strain(mm/mm)', ...
        'strain SD'};

    % 获取所有样品名，并保持第一次出现的顺序。
    sampleNames = {curveData.SampleName};
    uniqueSamples = unique(sampleNames, 'stable');

    for s = 1:numel(uniqueSamples)
        sampleName = uniqueSamples{s};

        % 找到当前样品对应的所有曲线。
        sampleMask = strcmp(sampleNames, sampleName);
        sampleCurves = curveData(sampleMask);

        % 一个图内颜色不能重复，所以曲线数不能超过颜色池数量。
        checkColorCount(numel(sampleCurves), params);
        colors = pickRandomColors(numel(sampleCurves), params);

        % 创建 2 inch × 1.4 inch 的图片。
        fig = createSmallFigure(params);
        ax = axes('Parent', fig);
        hold(ax, 'on');

        % 逐条绘制当前样品的曲线。
        for k = 1:numel(sampleCurves)
            plot(ax, sampleCurves(k).X, sampleCurves(k).Y, ...
                'Color', colors{k}, ...
                'LineWidth', params.curveLineWidth, ...
                'HandleVisibility', 'off');
        end

        % 当前样品图不需要图例，只需要文本框。
        applyStressStrainStyle(ax, sampleCurves, unitInfo, params);
        addTestLabel(ax, sampleCurves, params);
        addTopRightAxes(fig, ax, params);

        % 导出图片，文件名就是样品名称。
        exportPath = fullfile(outputDir, [sampleName, '.tif']);
        exportTifFigure(fig, exportPath, params);
        close(fig);

        % 计算当前样品的统计值，并加入结果列表。
        resultRow = calcSampleStatistics(sampleCurves, sampleName);
        resultList = [resultList; resultRow]; %#ok<AGROW>
    end
end

function plotBestStressStrain(curveData, unitInfo, outputDir, DATA, params)
    % plotBestStressStrain
    % 功能：
    %   绘制所有最优组分的 Stress-Strain 对比图。
    % 输入：
    %   curveData - 已经处理过的曲线数据。
    %   unitInfo  - 坐标轴单位信息。
    %   outputDir - 图片输出文件夹。
    %   DATA      - 用户输入的 DATA，用于文件名 multi_DATA.tif。
    %   params    - 绘图参数。

    bestMask = [curveData.IsBest];

    % 如果没有最优数据，就给出警告并跳过。
    if ~any(bestMask)
        warning('没有找到文件名最后一段为 b 的最优数据，已跳过 multi 图。');
        return;
    end

    bestCurves = curveData(bestMask);

    % 题目要求单个图内曲线颜色不可重复。
    checkColorCount(numel(bestCurves), params);
    colors = pickRandomColors(numel(bestCurves), params);

    fig = createSmallFigure(params);
    ax = axes('Parent', fig);
    hold(ax, 'on');

    % 保存每条曲线的句柄，用于生成正确图例。
    plotHandles = gobjects(numel(bestCurves), 1);
    legendNames = cell(numel(bestCurves), 1);

    for k = 1:numel(bestCurves)
        plotHandles(k) = plot(ax, bestCurves(k).X, bestCurves(k).Y, ...
            'Color', colors{k}, ...
            'LineWidth', params.curveLineWidth, ...
            'DisplayName', bestCurves(k).SampleName);

        legendNames{k} = bestCurves(k).SampleName;
    end

    % 根据曲线趋势设置坐标轴、文本框位置等。
    layoutInfo = applyStressStrainStyle(ax, bestCurves, unitInfo, params);
    addTestLabel(ax, bestCurves, params);
    addTopRightAxes(fig, ax, params);

    % 最优组图需要图例。
    legendHandle = legend(ax, plotHandles, legendNames, ...
        'Location', layoutInfo.legendLocation, ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'TextColor', params.textColor, ...
        'Box', 'off', ...
        'Color', 'none', ...
        'Interpreter', 'none');
    legendHandle.IconColumnWidth = params.legendIconWidth;

    % 导出文件名为 multi_DATA.tif。
    exportPath = fullfile(outputDir, ['multi_', DATA, '.tif']);
    exportTifFigure(fig, exportPath, params);
    close(fig);
end

function resultRow = calcSampleStatistics(sampleCurves, sampleName)
    % calcSampleStatistics
    % 功能：
    %   计算一个样品的 Young's modulus 和 Fracture strain 的均值与标准差。
    % 输入：
    %   sampleCurves - 同一样品的多条曲线。
    %   sampleName   - 样品名称。
    % 输出：
    %   resultRow    - 一个 1×5 cell 行，准备加入结果列表。

    youngValues = [sampleCurves.YoungModulus];
    strainValues = [sampleCurves.FractureStrain];

    % 去掉 Young's modulus 为 NaN 的曲线。
    % NaN 通常说明拟合区间内数据点不足 2 个。
    validYoung = isfinite(youngValues);
    youngValues = youngValues(validYoung);
    strainValuesForYoung = strainValues(validYoung);

    if isempty(youngValues)
        warning('样品 %s 没有可用于计算 Young''s modulus 的有效曲线。', sampleName);
        resultRow = {sampleName, NaN, NaN, NaN, NaN};
        return;
    end

    % 题目描述通常是三条曲线。
    % 如果超过三条，按读取顺序使用前三条。
    % 如果少于三条，用已有曲线计算，并给出提醒。
    if numel(youngValues) >= 3
        useIndex = 1:3;
    else
        warning('样品 %s 有效曲线少于 3 条，将使用已有 %d 条曲线计算统计值。', sampleName, numel(youngValues));
        useIndex = 1:numel(youngValues);
    end

    selectedYoung = youngValues(useIndex);
    selectedStrain = strainValuesForYoung(useIndex);

    youngMean = mean(selectedYoung);
    youngStd = std(selectedYoung);
    strainMean = mean(selectedStrain);
    strainStd = std(selectedStrain);

    resultRow = {sampleName, youngMean, youngStd, strainMean, strainStd};
end

function layoutInfo = applyStressStrainStyle(ax, curves, unitInfo, params)
    % applyStressStrainStyle
    % 功能：
    %   统一设置 Stress-Strain 图的坐标轴范围、坐标轴标题和基础样式。
    % 输入：
    %   ax       - 当前坐标轴句柄。
    %   curves   - 当前图中要绘制的曲线数据。
    %   unitInfo - 坐标轴单位信息。
    %   params   - 绘图参数。
    % 输出：
    %   layoutInfo - 文本框位置和图例位置等布局信息。

    % 只要任意曲线需要扩展布局，整张图就采用扩展布局。
    useExtendedLayout = any([curves.UseExtendedLayout]);

    % 找到所有曲线中最大的断裂应变，用于设置 x 轴上限。
    maxFractureStrain = max([curves.FractureStrain]);

    if useExtendedLayout
        xMax = maxFractureStrain * 1.4;
        layoutInfo.textX = 0.05;
        layoutInfo.textAlign = 'left';
        layoutInfo.legendLocation = 'northeast';
    else
        xMax = maxFractureStrain * 1.05;
        layoutInfo.textX = 0.95;
        layoutInfo.textAlign = 'right';
        layoutInfo.legendLocation = 'northwest';
    end
    layoutInfo.textY = 0.99;

    % 汇总所有 y 数据，用于设置 y 轴范围。
    allY = [];
    for i = 1:numel(curves)
        allY = [allY; curves(i).Y(:)]; %#ok<AGROW>
    end

    yMin = 0;
    if min(allY) < 0
        % 如果有少量负值，给 y 轴下方留一点空间。
        yMin = floor(min(allY));
    end

    yMax = nextMultipleOfFive(max(allY) * 1.2);
    if yMax <= yMin
        yMax = yMin + 5;
    end

    xlim(ax, [0, xMax]);
    ylim(ax, [yMin, yMax]);

    % 坐标轴标题：题目要求标题为 Strain/Stress 后接单位。
    xlabel(ax, ['Strain ', unitInfo.strainUnit], ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'Color', params.textColor);
    ylabel(ax, ['Stress ', unitInfo.stressUnit], ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'Color', params.textColor);

    % 坐标轴基础样式，参考原始脚本。
    set(ax, ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'XColor', params.textColor, ...
        'YColor', params.textColor, ...
        'LineWidth', params.axisLineWidth, ...
        'TickDir', 'out', ...
        'Box', 'off', ...
        'Layer', 'top');
    grid(ax, 'off');
end

function addTestLabel(ax, curves, params)
    % addTestLabel
    % 功能：
    %   在 Stress-Strain 图中添加 compression 或 tension 文本。
    % 输入：
    %   ax     - 当前坐标轴句柄。
    %   curves - 当前图中的曲线数据。
    %   params - 绘图参数。

    % 当前图通常只有一种测试方法。若混合出现，则显示 mixed。
    labels = unique({curves.TestLabel}, 'stable');
    if isscalar(labels)
        labelText = labels{1};
    else
        labelText = 'mixed';
    end

    % 布局位置与 applyStressStrainStyle 中的判断保持一致。
    useExtendedLayout = any([curves.UseExtendedLayout]);
    if useExtendedLayout
        textX = 0.05;
        horizontalAlign = 'left';
    else
        textX = 0.95;
        horizontalAlign = 'right';
    end

    text(ax, textX, 0.99, labelText, ...
        'Units', 'normalized', ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'Color', params.textColor, ...
        'VerticalAlignment', 'top', ...
        'HorizontalAlignment', horizontalAlign, ...
        'Interpreter', 'none');
end

function plotBiaxialBarChart(resultList, outputDir, params)
    % plotBiaxialBarChart
    % 功能：
    %   根据 Young_modulus_Fracture_strain 列表绘制双轴柱状图。
    % 输入：
    %   resultList - 第一行为表头、第二行开始为数据的 cell 列表。
    %   outputDir  - 图片输出文件夹。
    %   params     - 绘图参数。

    % 从 cell 列表中提取数据。
    sampleLabels = resultList(2:end, 1);
    modulusValues = cell2mat(resultList(2:end, 2));
    modulusError = cell2mat(resultList(2:end, 3));
    strainValues = cell2mat(resultList(2:end, 4));
    strainError = cell2mat(resultList(2:end, 5));

    n = numel(sampleLabels);
    barWidth = params.barWidth;

    % 计算柱的位置。
    % 每组两个柱子都宽 0.4，并且中间刚好紧贴。
    % 不同横坐标的组之间留 0.5 个柱宽。
    groupGap = 0.5 * barWidth;
    groupStep = 2 * barWidth + groupGap;
    groupCenter = 1 + (0:n-1) * groupStep;
    xModulus = groupCenter - barWidth / 2;
    xStrain = groupCenter + barWidth / 2;

    fig = createSmallFigure(params);
    ax = axes('Parent', fig);
    hold(ax, 'on');

    % 左侧 y 轴：Young's modulus。
    yyaxis(ax, 'left');
    barModulus = bar(ax, xModulus, modulusValues, barWidth, ...
        'FaceColor', params.modulusFaceColor, ...
        'EdgeColor', params.modulusEdgeColor, ...
        'LineWidth', params.barEdgeLineWidth);
    hold(ax, 'on');
    errorbar(ax, xModulus, modulusValues, modulusError, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', '#000000', ...
        'CapSize', params.errorBarCapSize, ...
        'HandleVisibility', 'off');
    ylabel(ax, 'Young''s modulus(kPa)', ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'Color', params.textColor);
    ylim(ax, [0, nextMultipleOfFive(max(modulusValues + modulusError))]);
    ax.YColor = params.textColor;

    % 右侧 y 轴：Fracture strain。
    yyaxis(ax, 'right');
    barStrain = bar(ax, xStrain, strainValues, barWidth, ...
        'FaceColor', params.strainFaceColor, ...
        'EdgeColor', params.strainEdgeColor, ...
        'LineWidth', params.barEdgeLineWidth);
    hold(ax, 'on');
    errorbar(ax, xStrain, strainValues, strainError, ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'Color', '#000000', ...
        'CapSize', params.errorBarCapSize, ...
        'HandleVisibility', 'off');
    ylabel(ax, 'Fracture strain(mm/mm)', ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'Color', params.textColor);
    ylim(ax, [0, 1]);
    ax.YColor = params.textColor;

    % 设置 x 轴标签。题目要求 x 轴无标题，所以不调用 xlabel。
    ax.XTick = groupCenter;
    ax.XTickLabel = sampleLabels;
    ax.TickLabelInterpreter = 'none';

    % 让坐标轴始终显示在柱子上方，避免被柱覆盖。
    ax.Layer = 'top';
    ax.Box = 'on';
    ax.FontName = params.fontName;
    ax.FontSize = params.fontSize;
    ax.XColor = params.textColor;
    ax.LineWidth = params.axisLineWidth;
    ax.TickDir = 'out';

    % 给 x 轴两边留一点空间，避免最左/最右的柱贴边。
    xMin = min(xModulus) - barWidth;
    xMax = max(xStrain) + barWidth;
    xlim(ax, [xMin, xMax]);

    % 只用两个 bar 对象生成图例，误差棒不会进入图例。
    legendHandle = legend(ax, [barModulus, barStrain], ...
        {'Young''s modulus', 'Fracture strain'}, ...
        'Location', 'northwest', ...
        'FontName', params.fontName, ...
        'FontSize', params.fontSize, ...
        'TextColor', params.textColor, ...
        'Box', 'off', ...
        'Color', 'none');
    legendHandle.IconColumnWidth = params.legendIconWidth;

    exportPath = fullfile(outputDir, 'modulus.tif');
    exportTifFigure(fig, exportPath, params);
    close(fig);
end

function fig = createSmallFigure(params)
    % createSmallFigure
    % 功能：
    %   创建固定尺寸的 figure。
    % 输入：
    %   params - 绘图参数。
    % 输出：
    %   fig    - figure 句柄。

    fig = figure( ...
        'Units', 'inches', ...
        'Position', [2, 2, params.figureWidth, params.figureHeight], ...
        'Color', 'white');

    % 设置 PaperUnits/PaperPosition 可以帮助某些 MATLAB 版本稳定导出尺寸。
    fig.PaperUnits = 'inches';
    fig.PaperPosition = [0, 0, params.figureWidth, params.figureHeight];
end

function addTopRightAxes(fig, ax, params)
    % addTopRightAxes
    % 功能：
    %   参考原始脚本，在图的顶部和右侧添加辅助坐标轴线。
    %   这个辅助坐标轴不显示刻度，只用于形成完整边框效果。
    % 输入：
    %   fig    - 当前 figure。
    %   ax     - 主坐标轴。
    %   params - 绘图参数。

    axTop = axes('Parent', fig, ...
        'Position', ax.Position, ...
        'XAxisLocation', 'top', ...
        'YAxisLocation', 'right', ...
        'Color', 'none', ...
        'XColor', params.textColor, ...
        'YColor', params.textColor, ...
        'XTick', [], ...
        'YTick', [], ...
        'LineWidth', params.axisLineWidth, ...
        'Box', 'off');

    % 让辅助坐标轴和主坐标轴的位置保持一致。
    linkObject = linkprop([ax, axTop], 'Position');

    % 保存 linkObject，防止 MATLAB 自动清理导致链接失效。
    setappdata(fig, 'TopRightAxesPositionLink', linkObject);
end

function exportTifFigure(fig, exportPath, params)
    % exportTifFigure
    % 功能：
    %   按统一格式导出 tif 图片。
    % 输入：
    %   fig        - 要导出的 figure。
    %   exportPath - 输出文件完整路径。
    %   params     - 绘图参数。

    exportgraphics(fig, exportPath, ...
        'Resolution', params.resolution, ...
        'ContentType', 'image', ...
        'BackgroundColor', 'white');

    fprintf('已保存图片：%s\n', exportPath);
end

function colors = pickRandomColors(n, params)
    % pickRandomColors
    % 功能：
    %   从题目指定颜色池中随机选择 n 个不重复颜色。
    % 输入：
    %   n      - 需要的颜色数量。
    %   params - 参数结构体，包含颜色池。
    % 输出：
    %   colors - 1×n cell，每个元素是一个颜色字符串。

    colorIndex = randperm(numel(params.curveColors), n);
    colors = params.curveColors(colorIndex);
end

function checkColorCount(n, params)
    % checkColorCount
    % 功能：
    %   检查单张图中的曲线数量是否超过颜色池数量。
    % 输入：
    %   n      - 当前图要绘制的曲线数量。
    %   params - 参数结构体，包含颜色池。

    if n > numel(params.curveColors)
        error('单张图需要绘制 %d 条曲线，但颜色池只有 %d 种颜色，无法保证颜色不重复。', ...
            n, numel(params.curveColors));
    end
end

function value = nextMultipleOfFive(rawValue)
    % nextMultipleOfFive
    % 功能：
    %   计算“大于数据最大值的第一个 5 的倍数”。
    % 输入：
    %   rawValue - 数据最大值。
    % 输出：
    %   value    - 比 rawValue 大的第一个 5 的倍数。

    if ~isfinite(rawValue) || rawValue <= 0
        value = 5;
        return;
    end

    value = ceil(rawValue / 5) * 5;

    % 题目写的是“大于”数据最大值。
    % 如果 rawValue 本身刚好是 5 的倍数，就再加 5。
    if value <= rawValue
        value = value + 5;
    end
end
