function makeOrbitVideo(varargin)
%MAKEORBITVIDEO  リアル調 LEO 相対運動の可視化動画を生成
%
%   makeOrbitVideo()                既定設定 (config_video.m) で MP4 を生成
%   makeOrbitVideo('previewOnly',true)   数フレームのみ PNG プレビュー保存
%   makeOrbitVideo(cfg)             設定構造体を直接渡す
%
%   左 : 地球を周回する観測衛星(chief)中心の ECI ヒーロー視点
%   右 : 観測衛星から見た目標衛星(deputy)の RTN 相対運動
%
%   依存: yoshimuLibrary (oe2rv, roe2rtn, dcmI2RTN, orbitConst, readSC ...)

%% ---------- 設定 ----------
if nargin == 1 && isstruct(varargin{1})
    cfg = varargin{1};
else
    cfg = config_video();
    for i = 1:2:numel(varargin)
        cfg.(varargin{i}) = varargin{i+1};
    end
end

addpath(genpath(cfg.libRoot));
const = orbitConst();

%% ---------- 軌道計算 ----------
fprintf('軌道を計算中 ...\n');
S = computeScene(cfg, const);
N = numel(S.t);

% 太陽方向(固定・正規化)。[] のときは初期フレームの昼側がカメラを向くよう設定
if isempty(cfg.sunDirEci)
    R0 = S.dcmI2RTN(:,:,1);
    rad0 = R0(1,:); alo0 = R0(2,:); cro0 = R0(3,:);
    sunDir = 0.85*rad0 + 0.50*alo0 + 0.18*cro0;   % 3/4 ライティング
    sunDir = sunDir / norm(sunDir);
else
    sunDir = cfg.sunDirEci(:)' / norm(cfg.sunDirEci);
end
sunPosKm = sunDir * const.AU;     % 食判定用に遠方へ配置

% 食フラグ(0:umbra .. 1:sunlit)
nuLit = shadow(S.rChief, repmat(sunPosKm, N, 1), const.RS, const.RE);

%% ---------- 衛星モデル読み込み ----------
fprintf('衛星モデルを読み込み中 ...\n');
satC = readSC(cfg.chiefObj);    % 観測衛星
satD = readSC(cfg.deputyObj);   % 目標衛星
satC = centerModel(satC);
satD = centerModel(satD);

%% ---------- 図とシーンの構築 ----------
fprintf('シーンを構築中 ...\n');
fig = figure('Color','k','Units','pixels', ...
    'Position',[60 60 cfg.width cfg.height], ...
    'GraphicsSmoothing','on','Renderer','opengl','Visible','on');

% --- 左: chief 追従・慣性固定カメラ(ECI, chief 原点) ---
axL = axes('Parent',fig,'Position',[0.0 0.0 0.56 1.0],'Color','k');
hold(axL,'on'); axis(axL,'vis3d'); axis(axL,'off');
axL.Clipping = 'off';
set(axL,'Projection','perspective');

% 背景の星空(遠方・慣性固定)
Rstar = 6 * S.a;
if cfg.showStars
    rng(7);
    vv = randn(cfg.nStars,3); vv = vv ./ vecnorm(vv,2,2);
    Pst = Rstar * vv;
    ssz = 1 + 7*rand(cfg.nStars,1).^3;   % 多くは小さく、少数だけ大きい
    hStars = scatter3(axL, Pst(:,1),Pst(:,2),Pst(:,3), ssz, 'w', 'filled', ...
        'MarkerEdgeColor','none', 'Clipping','off');
    hStars.MarkerFaceAlpha = 0.85;
end

% 地球(実スケール, 慣性。hgtransform で自転 + chief 原点へ平行移動)
hEarth = drawEarthECI(axL, const, cfg.earthTex, cfg.earthAmbient);
% 太陽光(無限遠 = 平行光, 慣性固定方向)
light(axL,'Style','infinite','Position', sunDir);

% 観測衛星の周回軌道(青線, chief 原点へ平行移動)
hOrbit  = plot3(axL, nan, nan, nan, '-', 'Color',[cfg.orbitColor 0.9], 'LineWidth',2.0, 'Clipping','off');
% deputy 相対トレイル
trailVis = 'on'; if isfield(cfg,'showDeputyTrail') && ~cfg.showDeputyTrail; trailVis = 'off'; end
hTrailD = plot3(axL, nan, nan, nan, '-', 'Color',[cfg.deputyColor 0.9], 'LineWidth',2.6, ...
    'Clipping','off', 'Visible', trailVis);

% 観測衛星 -> 目標衛星 の細いオレンジ矢印
arrowVis = 'on'; if isfield(cfg,'showArrow') && ~cfg.showArrow; arrowVis = 'off'; end
hArrow = quiver3(axL, 0,0,0, 0,0,1, 'Color',cfg.arrowColor, 'LineWidth',1.2, ...
    'AutoScale','off', 'MaxHeadSize',0.4, 'Clipping','off', 'Visible',arrowVis);

% 衛星パッチ(chief 原点ローカル [km], 誇張サイズ)
hSatC = patch(axL,'Faces',satC.faces,'Vertices',satC.vertices, ...
    'FaceColor',[0.72 0.72 0.74],'EdgeColor','none', ...
    'FaceLighting','gouraud','BackFaceLighting','reverselit', ...
    'AmbientStrength',0.28,'DiffuseStrength',0.9,'SpecularStrength',0.55,'SpecularExponent',12, ...
    'Clipping','off');
hSatD = patch(axL,'Faces',satD.faces,'Vertices',satD.vertices, ...
    'FaceColor',[0.78 0.74 0.66],'EdgeColor','none', ...
    'FaceLighting','gouraud','BackFaceLighting','reverselit', ...
    'AmbientStrength',0.28,'DiffuseStrength',0.9,'SpecularStrength',0.55,'SpecularExponent',12, ...
    'Clipping','off');

% Chief / Deputy ラベル
labelVis = 'on'; if isfield(cfg,'showLabels') && ~cfg.showLabels; labelVis = 'off'; end
hLblC = text(axL, 0,0,0, 'Chief', 'Color',cfg.chiefColor, 'FontSize',13, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','top', ...
    'Clipping','off', 'Visible',labelVis);
hLblD = text(axL, 0,0,0, 'Deputy', 'Color',cfg.arrowColor, 'FontSize',13, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'Clipping','off', 'Visible',labelVis);

% 軌道・星空が収まる軸範囲
limL = 1.05 * Rstar;
set(axL,'XLim',[-limL limL],'YLim',[-limL limL],'ZLim',[-limL limL], ...
    'DataAspectRatio',[1 1 1]);

% --- 右: RTN 相対運動 ---
axR = axes('Parent',fig,'Position',[0.62 0.10 0.35 0.80],'Color','k');
hold(axR,'on'); grid(axR,'on'); box(axR,'on');
axR.GridColor = [0.5 0.55 0.6]; axR.GridAlpha = 0.35;
axR.XColor = [0.8 0.85 0.9]; axR.YColor = [0.8 0.85 0.9]; axR.ZColor = [0.8 0.85 0.9];
xlabel(axR,'T  (Along-track) [km]'); ylabel(axR,'R  (Radial) [km]'); zlabel(axR,'N  (Cross-track) [km]');
view(axR,[-37 22]); axis(axR,'equal');
% RTN: x=T, y=R, z=N
Tt = S.xRTN(:,2); Rr = S.xRTN(:,1); Nn = S.xRTN(:,3);
pad = 0.12;
xlim(axR, rngPad([Tt;0],pad)); ylim(axR, rngPad([Rr;0],pad)); zlim(axR, rngPad([Nn;0],pad));
% chief(観測衛星) = 原点を青点で表示
plot3(axR,0,0,0,'o','MarkerFaceColor',cfg.chiefColor,'MarkerEdgeColor','w','MarkerSize',11);
% 軌跡(開始時刻から現在まで累積する太線)
hRtnTrail = plot3(axR, nan,nan,nan, '-', 'Color',[cfg.deputyColor 1.0], 'LineWidth',2.2);
hRtnPt    = plot3(axR, nan,nan,nan, 'o', 'MarkerFaceColor',cfg.deputyColor, ...
    'MarkerEdgeColor','w','MarkerSize',8);
% ラベル(Chief は原点に静的、Deputy は現在位置に追従)
rtnLblVis = 'on'; if isfield(cfg,'showLabels') && ~cfg.showLabels; rtnLblVis = 'off'; end
rtnLblOff = 0.05 * (max(Nn)-min(Nn)) + 2;   % km
text(axR, 0,0,-rtnLblOff, 'Chief', 'Color',cfg.chiefColor, 'FontSize',12, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','top', ...
    'Clipping','off', 'Visible',rtnLblVis);
hRtnLblD = text(axR, nan,nan,nan, 'Deputy', 'Color',cfg.deputyColor, 'FontSize',12, ...
    'FontWeight','bold', 'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
    'Clipping','off', 'Visible',rtnLblVis);

%% ---------- 出力準備 ----------
if cfg.previewOnly
    outDir = fullfile(fileparts(mfilename('fullpath')),'output');
    if ~exist(outDir,'dir'); mkdir(outDir); end
    idxPrev = round(linspace(1, N, 4));
    for j = 1:numel(idxPrev)
        renderFrame(idxPrev(j));
        drawnow;
        fr = getframe(fig);
        imwrite(fr.cdata, fullfile(outDir, sprintf('preview_%02d.png', j)));
    end
    fprintf('プレビュー PNG を output/ に保存しました。\n');
    return;
end

outDir = fileparts(cfg.outFile);
if ~exist(outDir,'dir'); mkdir(outDir); end
vw = VideoWriter(cfg.outFile,'MPEG-4');
vw.FrameRate = cfg.fps; vw.Quality = 100;
open(vw);

fprintf('レンダリング中 (%d フレーム) ...\n', N);
for k = 1:N
    renderFrame(k);
    drawnow;
    fr = getframe(fig);
    img = fr.cdata;
    if size(img,1) ~= cfg.height || size(img,2) ~= cfg.width
        img = imresize(img, [cfg.height cfg.width]);
    end
    writeVideo(vw, img);
    if mod(k,30)==0; fprintf('  %d / %d\n', k, N); end
end
close(vw);
fprintf('完了: %s\n', cfg.outFile);

%% ================= ネスト関数 =================
    function renderFrame(k)
        % 左ビュー: chief 原点(画面中央)・慣性固定姿勢の追従カメラ。
        % 地球と周回軌道(青)が背景で回り込み、周回の様子が見える。

        R   = S.dcmI2RTN(:,:,k);     % I->RTN, 行 = [radial; along; cross]
        rad = R(1,:); alo = R(2,:); cro = R(3,:);
        rC  = S.rChief(k,:);

        % --- deputy 表示位置(慣性相対, 誇張縮尺) ---
        relI   = (R' * S.xRTN(k,:)')';            % 実慣性相対 [km]
        pDep   = cfg.relScale * relI;
        midLoc = 0.5 * pDep;

        % --- 姿勢 (body->inertial) ---
        Cb2i_C = [alo; cro; -rad]';               % chief: x=along, z=nadir
        ang = 2*pi * (k-1)/N * 3;                 % 目標機の緩やかな回転
        Cb2i_D = Cb2i_C * axang2dcm([0.3 1 0.4], ang);

        % --- 衛星メッシュ(chief 原点ローカル) ---
        Vc = (cfg.modelScale * satC.vertices) * Cb2i_C';
        Vd = (cfg.modelScale * satD.vertices) * Cb2i_D' + pDep;
        set(hSatC,'Vertices',Vc);
        set(hSatD,'Vertices',Vd);

        % --- 日陰減光 ---
        dim = cfg.eclipseDim + (1-cfg.eclipseDim)*nuLit(k);
        set(hSatC,'AmbientStrength',0.28*dim,'DiffuseStrength',0.9*dim);
        set(hSatD,'AmbientStrength',0.28*dim,'DiffuseStrength',0.9*dim);

        % --- 地球(慣性, 自転 + chief 原点へ平行移動) ---
        M = makehgtform('translate', -rC) * makehgtform('zrotate', S.gmst(k));
        set(hEarth.tf, 'Matrix', M);

        % --- 観測衛星の周回軌道(青, chief 原点へ平行移動) ---
        orb = S.rOrbit - rC;
        set(hOrbit,'XData',orb(:,1),'YData',orb(:,2),'ZData',orb(:,3));

        % --- deputy 相対トレイル(慣性, 誇張) ---
        w  = max(2, round(cfg.trailFrac * (S.T/(S.t(2)-S.t(1)))));
        i0 = max(1, k-w);
        trailD = cfg.relScale * relEciSeg(i0, k);
        set(hTrailD,'XData',trailD(:,1),'YData',trailD(:,2),'ZData',trailD(:,3));

        % --- 観測衛星 -> 目標衛星 の矢印 ---
        set(hArrow,'XData',0,'YData',0,'ZData',0, ...
                   'UData',pDep(1),'VData',pDep(2),'WData',pDep(3));

        % --- Chief / Deputy ラベル(Chief は下、Deputy は上に分離) ---
        lblOff = 0.10 * norm(pDep) + 800;   % km
        set(hLblC,'Position',[0 0 -lblOff]);
        set(hLblD,'Position',pDep + [0 0 lblOff]);

        % --- カメラ(慣性固定方位・仰角, chief を画面中央に固定) ---
        % 注視点=chief(原点), カメラ位置=慣性固定。地球・軌道が背景で回り込む。
        el = deg2rad(cfg.camElevDeg); az = deg2rad(cfg.camAzDeg);
        dCam = [cos(el)*cos(az), cos(el)*sin(az), sin(el)];
        camtarget(axL, [0 0 0]);
        campos(axL, cfg.camDistKm * dCam);
        camup(axL, [0 0 1]);
        camva(axL, cfg.camFovDeg);

        % --- RTN パネル更新(開始時刻から現在まで累積) ---
        set(hRtnTrail,'XData',Tt(1:k),'YData',Rr(1:k),'ZData',Nn(1:k));
        set(hRtnPt,'XData',Tt(k),'YData',Rr(k),'ZData',Nn(k));
        set(hRtnLblD,'Position',[Tt(k), Rr(k), Nn(k)+rtnLblOff]);
    end

    function seg = relEciSeg(i0,k)
        % 区間 i0:k の実慣性相対ベクトル [km] (Mx3)
        m = k - i0 + 1; seg = zeros(m,3); c = 0;
        for kk = i0:k
            c = c+1;
            Rk = S.dcmI2RTN(:,:,kk);
            seg(c,:) = (Rk' * S.xRTN(kk,:)')';
        end
    end
end

%% ================= ローカル関数 =================
function sat = centerModel(sat)
% 重心まわりに中心化
c = mean(sat.vertices, 1);
sat.vertices = sat.vertices - c;
end

function h = drawEarthECI(ax, const, texFile, ambient)
% 実スケールの地球(慣性)。hgtransform で自転 + chief 原点への平行移動を行う。
nP = 120;
[x,y,z] = ellipsoid(0,0,0,const.RE,const.RE,const.RE,nP);
tf = hgtransform('Parent',ax);
s = surf(ax, x, y, z, 'Parent', tf, ...
    'FaceColor','texturemap','EdgeColor','none', ...
    'FaceLighting','gouraud','BackFaceLighting','unlit', ...
    'AmbientStrength',ambient,'DiffuseStrength',1.0, ...
    'SpecularStrength',0.12,'SpecularExponent',8, 'Clipping','off');
cdata = flipud(imread(texFile));
set(s,'CData', cdata);
h.surf = s; h.tf = tf;
end

function h = drawEarthHorizon(ax, const, texFile, ambient, visDist, altKm) %#ok<DEFNU>
% 水平線用の視覚地球(chief 原点・nadir 方向)。深度精度のため距離を圧縮。
sinRho = const.RE / (const.RE + altKm);
rVis   = visDist * sinRho;
nP = 120;
[x,y,z] = sphere(nP);
h.X0 = x; h.Y0 = y; h.Z0 = z;
ctr = [0 0 -visDist];
s = surf(ax, x*rVis+ctr(1), y*rVis+ctr(2), z*rVis+ctr(3), ...
    'FaceColor','texturemap','EdgeColor','none', ...
    'FaceLighting','gouraud','BackFaceLighting','unlit', ...
    'AmbientStrength',ambient,'DiffuseStrength',1.0, ...
    'SpecularStrength',0.15,'SpecularExponent',10, 'Clipping','off');
cdata = flipud(imread(texFile));
set(s,'CData', cdata);
h.surf = s;
end

function h = drawEarth2K(ax, const, texFile, ambient)
% (旧) 地心座標地球 — 未使用だが互換のため残置
nP = 180;
[x,y,z] = ellipsoid(0,0,0,const.RE,const.RE,const.RE,nP);
tf = hgtransform('Parent',ax);
s = surf(ax, x, y, z, 'Parent', tf, ...
    'FaceColor','texturemap','EdgeColor','none', ...
    'FaceLighting','gouraud','BackFaceLighting','unlit', ...
    'AmbientStrength',ambient,'DiffuseStrength',1.0, ...
    'SpecularStrength',0.12,'SpecularExponent',8);
cdata = flipud(imread(texFile));
set(s,'CData', cdata);
h.surf = s; h.tf = tf;
end

function r = rngPad(v, frac)
lo = min(v); hi = max(v); d = hi-lo;
if d < eps; d = max(abs(hi),1); end
r = [lo - frac*d, hi + frac*d];
end

function C = axang2dcm(axis, ang)
% 軸角 -> DCM (body->something), ロドリゲス
k = axis(:)/norm(axis);
K = [0 -k(3) k(2); k(3) 0 -k(1); -k(2) k(1) 0];
C = eye(3) + sin(ang)*K + (1-cos(ang))*(K*K);
end
