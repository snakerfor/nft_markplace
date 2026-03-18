// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceOracle
 * @dev Chainlink 价格预言机，获取 ETH 和项目代币的 USD 价格
 * @notice 项目代币价格锚定 ETH（1:1），直接使用 ETH/USD 价格
 */
contract PriceOracle {
    /// @dev ETH/USD Price Feed 地址
    AggregatorV3Interface public ethUsdFeed;

    /**
     * @dev 构造函数
     * @param _ethUsdFeed ETH/USD Feed 地址 (Sepolia)
     */
    constructor(address _ethUsdFeed) {
        require(_ethUsdFeed != address(0), "Invalid ETH feed address");
        ethUsdFeed = AggregatorV3Interface(_ethUsdFeed);
    }

    /**
     * @dev 获取 ETH/USD 最新价格
     * @return price 价格（8位小数）
     */
    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price,,,) = ethUsdFeed.latestRoundData();
        require(price > 0, "Invalid ETH price");
        return uint256(price);
    }

    /**
     * @dev 获取项目代币/USD 最新价格
     * @notice 项目代币锚定 ETH（1:1），直接返回 ETH/USD 价格
     * @return price 价格（8位小数）
     */
    function getTokenUsdPrice() public view returns (uint256) {
        return getEthUsdPrice();
    }

    /**
     * @dev 将 ETH 数量转换为 USD
     * @param ethAmount ETH 数量 (wei)
     * @return usdValue USD 价值
     */
    function getEthValueInUsd(uint256 ethAmount) external view returns (uint256) {
        uint256 price = getEthUsdPrice();
        return (ethAmount * price) / 1e8;
    }

    /**
     * @dev 将代币数量转换为 USD
     * @param tokenAmount 代币数量
     * @return usdValue USD 价值
     * @notice 代币锚定 ETH（1:1），使用 ETH/USD 价格计算
     */
    function getTokenValueInUsd(uint256 tokenAmount) external view returns (uint256) {
        uint256 price = getTokenUsdPrice();
        return (tokenAmount * price) / 1e8;
    }

    /**
     * @dev 获取价格的 decimals
     */
    function getPriceDecimals() external view returns (uint8) {
        return ethUsdFeed.decimals();
    }
}
