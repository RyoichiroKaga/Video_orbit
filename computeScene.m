function S = computeScene(cfg, const)
%COMPUTESCENE  chief / deputy の ECI・RTN 時系列を計算(ROE 線形)
%   出力 S:
%     S.t        : 時刻ベクトル [s]            (1xN)
%     S.rChief   : chief ECI 位置 [km]         (Nx3)
%     S.rDepReal : deputy ECI 位置(実スケール)[km] (Nx3)
%     S.xRTN     : deputy 相対位置 @RTN [km]   (Nx3) [R T N]
%     S.dcmI2RTN : 各時刻の I->RTN DCM          (3x3xN)
%     S.gmst     : 地球回転角 [rad]            (1xN)
%     S.T        : 周期 [s]
%     S.n        : 平均運動 [rad/s]

mu  = const.GE;             % km^3/s^2
RE  = const.RE;             % km
a   = RE + cfg.altKm;       % km
e   = cfg.ecc;
inc = deg2rad(cfg.incDeg);
raan= deg2rad(cfg.raanDeg);
w   = deg2rad(cfg.argpDeg);
M0  = deg2rad(cfg.M0Deg);

n = sqrt(mu / a^3);
T = 2*pi / n;

% 再生速度倍率: 同じ運動(nOrbits)をフレーム間引きで速く再生
spd = 1.0;
if isfield(cfg,'speedFactor') && ~isempty(cfg.speedFactor); spd = cfg.speedFactor; end
nFrames = max(2, round(cfg.durationSec * cfg.fps / spd));
tEnd    = cfg.nOrbits * T;
t       = linspace(0, tEnd, nFrames);

% ROE [km] -> 無次元 δ
delta0 = cfg.roeKm(:)' / a;     % 1x6

rChief   = zeros(nFrames, 3);
rDepReal = zeros(nFrames, 3);
xRTN     = zeros(nFrames, 3);
dcmStack = zeros(3, 3, nFrames);

for k = 1:nFrames
    M = M0 + n * t(k);
    f = M;                      % e=0 のとき真近点角 = 平均近点角
    chiefOE = [a, e, inc, raan, w, f];

    [rC, ~] = oe2rv(chiefOE, 1, mu);
    rChief(k,:) = rC(:)';

    % along-track ドリフト: δλ(t) = δλ0 - 1.5 n δa t
    deltaT    = delta0;
    deltaT(2) = delta0(2) - 1.5 * n * delta0(1) * t(k);

    [xr, ~] = roe2rtn(deltaT, chiefOE, 1, mu);   % km, [R T N]
    xRTN(k,:) = xr;

    R = dcmI2RTN(raan, inc, w, f);  % I->RTN
    dcmStack(:,:,k) = R;
    rDepReal(k,:) = rC(:)' + (R' * xr(:))';
end

% 観測衛星の周回軌道(青線用, 1周分の閉曲線)
thF = linspace(0, 2*pi, 721)';
rOrbit = zeros(721, 3);
for i = 1:721
    [rr, ~] = oe2rv([a, e, inc, raan, w, thF(i)], 1, mu);
    rOrbit(i,:) = rr(:)';
end
S.rOrbit = rOrbit;

S.t        = t;
S.rChief   = rChief;
S.rDepReal = rDepReal;
S.xRTN     = xRTN;
S.dcmI2RTN = dcmStack;
S.gmst     = mod(const.WE * t, 2*pi);
S.T        = T;
S.n        = n;
S.a        = a;

end
