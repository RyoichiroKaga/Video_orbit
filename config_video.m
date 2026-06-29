function cfg = config_video()
%CONFIG_VIDEO  リアル調 LEO 相対運動可視化動画の設定
%   ここのパラメータを変えるだけで動画の挙動・見栄えを調整できます。

%% ---- 外部ライブラリ / アセット ----
cfg.libRoot     = '/Users/ryoichiro.kssdl/Reserch/AON_project/yoshimuLibrary';
cfg.earthTex    = fullfile(cfg.libRoot, 'object', 'earth2K.jpg'); % 2K テクスチャ
cfg.chiefObj    = fullfile(cfg.libRoot, 'object', 'oneweb.obj');  % 観測衛星モデル
cfg.deputyObj   = fullfile(cfg.libRoot, 'examples', 'attitudeEstLightCurve', 'geoSat.obj'); % 目標衛星モデル

%% ---- 出力 ----
cfg.outFile   = fullfile(fileparts(mfilename('fullpath')), 'output', 'GEO_relative_motion.mp4');
cfg.width     = 1920;
cfg.height    = 1080;
cfg.fps       = 30;
cfg.durationSec = 25;          % 動画長さ [s](等速基準)
cfg.speedFactor = 1.5;         % 再生速度倍率(1.5=1.5倍速, フレーム間引き)
cfg.previewOnly = false;       % true: 数フレームだけ PNG 保存して終了

%% ---- 基準(観測=chief)軌道: 静止軌道 GEO ----
cfg.altKm   = 35786;           % 高度 [km] (静止軌道, a≈42164km)
cfg.ecc     = 0;               % 離心率(近円)
cfg.incDeg  = 0;               % 傾斜角 [deg] (赤道面)
cfg.raanDeg = 0;               % 昇交点赤経 [deg]
cfg.argpDeg = 0;               % 近地点引数 [deg]
cfg.M0Deg   = 0;               % 初期平均近点角 [deg]
cfg.nOrbits = 1.5;             % 動画で見せる周回数(シミュレーション内)

%% ---- 相対軌道要素 ROE [km]  ([a*da, a*dl, a*dex, a*dey, a*dix, a*diy]) ----
cfg.roeKm = [1, 30, 10, 0, 30, 0];

%% ---- 左ビュー: chief 追従・慣性固定カメラ(軌道スケール) ----
% chief を画面中央に置き、地球と周回軌道(青)が背景で回り込む co-moving カメラ。
% GEO スケールでは実寸の衛星(数十m)は不可視のため、modelScale/relScale で誇張表示。
cfg.relScale   = 85;     % 相対変位の表示倍率(誇張)
cfg.showLabels = true;   % Chief/Deputy ラベル表示
cfg.modelScale = 900;    % 衛星モデル表示倍率 [km/(model unit)]
cfg.camDistKm  = 120000; % chief からカメラまでの距離 [km]
cfg.showDeputyTrail = false; % 目標衛星の相対トレイル(オレンジ)表示

%% ---- 背景の星空 ----
cfg.showStars = true;    % 星空背景の表示
cfg.nStars    = 1600;    % 星の数

%% ---- 観測衛星→目標衛星の矢印 ----
cfg.showArrow  = true;            % 細いオレンジ矢印の表示
cfg.arrowColor = [1.0 0.5 0.15];  % 矢印の色(オレンジ)
cfg.camElevDeg = 45;     % 軌道面からのカメラ仰角(慣性固定) [deg]
cfg.camAzDeg   = 25;     % カメラの慣性方位(固定) [deg]
cfg.camFovDeg  = 40;     % 視野角
cfg.orbitColor = [0.30 0.65 1.00]; % 観測衛星の周回軌道(青)

%% ---- ライティング(固定光源) ----
% sunDirEci を [] にすると初期フレームの昼側がカメラを向くよう自動設定(食判定用)。
cfg.sunDirEci  = [];               % 太陽方向(ECI)。[]=自動(食判定に使用)
cfg.sunDirView = [0.55 0.5 0.35];  % 左ビュー固定光源方向 (X=R,Y=T,Z=N)
cfg.eclipseDim = 0.22;             % 日陰時の衛星明るさ係数
cfg.earthAmbient = 0.10;           % 地球の環境光(夜側の明るさ)

%% ---- 軌道リボン(トレイル) ----
cfg.trailFrac   = 0.55;   % トレイル長(周期に対する割合)
cfg.chiefColor  = [0.30 0.65 1.00];   % 観測衛星トレイル色(青)
cfg.deputyColor = [1.00 0.45 0.30];   % 目標衛星トレイル色(赤橙)

%% ---- 右ビュー(RTN) ----
cfg.rtnTrailFrac = 1.0;   % RTN トレイル長(周期割合)

end
