# LEO/GEO 相対運動 可視化動画 (MATLAB)

静止衛星(GEO)を周回する**観測衛星(Chief)**と**目標衛星(Deputy)**の相対運動を、リアル調に可視化する MATLAB プロジェクトです。研究室紹介・一般向けの「かっこいいビジュアル」を目的としています。

## デモ動画

<!-- VIDEO_PLACEHOLDER -->
動画: [`output/GEO_relative_motion.mp4`](output/GEO_relative_motion.mp4)

## 画面構成

- **左**: 星空を背景に、地球を周回する観測衛星(Chief)を画面中央に固定追従。青い周回軌道(静止軌道)、目標衛星(Deputy)、両機を結ぶオレンジの矢印を表示。
- **右**: 観測衛星から見た目標衛星の相対運動を RTN 座標系で 3D プロット(左と同時刻で同期)。
  - **R (Radial)**: 半径方向、**T (Along-track)**: 軌道進行方向、**N (Cross-track)**: 軌道面法線方向

## 軌道・相対運動の設定

- 基準軌道: 静止軌道 (高度約 35,786 km, 傾斜角 0°)
- 相対軌道要素 ROE [km]: `[a·δa, a·δλ, a·δe_x, a·δe_y, a·δi_x, a·δi_y] = [1, 30, 10, 0, 30, 0]`
- 相対運動は ROE 線形伝播

## ファイル構成

```
.
├── config_video.m     # 全パラメータ(軌道/ROE/カメラ/動画仕様 等)
├── computeScene.m     # Chief/Deputy の ECI・RTN 時系列計算
├── makeOrbitVideo.m   # 描画・アニメーション・MP4 書き出し
├── output/            # 出力(mp4)。プレビューPNGは .gitignore 対象
└── README.md
```

## 実行方法

MATLAB R2024a 以降 (本プロジェクトは R2025b で確認)。

```matlab
% 設定確認用のプレビュー(数フレームを PNG 保存)
makeOrbitVideo('previewOnly', true)

% 本番(1080p / 30fps の MP4 を output/ に書き出し)
makeOrbitVideo()
```

主要パラメータは `config_video.m` で調整できます。

- `roeKm`: 相対軌道要素 [km]
- `relScale`: 左ビューでの両機の見かけの間隔(誇張表示)
- `modelScale` / `camDistKm` / `camFovDeg`: 衛星サイズ・カメラ距離・画角
- `speedFactor`: 再生速度倍率
- `showStars` / `showArrow` / `showLabels`: 星空・矢印・ラベルの表示切替

## 依存ライブラリ

軌道伝播・座標変換・地球/衛星モデルは Yoshimu Library を参照しています。`config_video.m` の `cfg.libRoot` にパスを設定してください。

## ライセンス

研究・教育用途を想定しています。
