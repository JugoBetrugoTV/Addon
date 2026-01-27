const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const commonConfig = {
  mode: 'production',
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
  },
};

const mainConfig = {
  ...commonConfig,
  entry: './src/main.ts',
  target: 'electron-main',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, 'dist'),
  },
};

const preloadConfig = {
  ...commonConfig,
  entry: './src/preload.ts',
  target: 'electron-preload',
  output: {
    filename: 'preload.js',
    path: path.resolve(__dirname, 'dist'),
  },
};

const rendererConfig = {
  ...commonConfig,
  entry: './src/renderer/app.ts',
  devtool: 'source-map',
  target: 'web',
  output: {
    filename: 'renderer.js',
    path: path.resolve(__dirname, 'dist'),
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './src/index.html',
      filename: 'index.html',
    }),
  ],
};

module.exports = [mainConfig, preloadConfig, rendererConfig];
