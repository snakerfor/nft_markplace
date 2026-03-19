// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "@openzeppelin-foundry-upgrades/Options.sol";
import {NFTMarketplaceV1} from "../src/marketplace/NFTMarketplaceV1.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 从环境变量读取代理地址
        address tokenProxy = vm.envAddress("TOKEN_PROXY");
        address nftProxy = vm.envAddress("NFT_PROXY");
        address marketplaceProxy = vm.envAddress("MARKETPLACE_PROXY");
        address priceOracle = vm.envAddress("PRICE_ORACLE");

        require(priceOracle != address(0), "PRICE_ORACLE not set");

        console.log("Upgrading contracts...");
        console.log("Token Proxy:", tokenProxy);
        console.log("NFT Proxy:", nftProxy);
        console.log("Marketplace Proxy:", marketplaceProxy);
        console.log("Price Oracle:", priceOracle);

        vm.startBroadcast(deployerPrivateKey);

        // 跳过升级安全检查
        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        // 1. 升级 Marketplace
        Upgrades.upgradeProxy(marketplaceProxy, "NFTMarketplaceV1.sol:NFTMarketplaceV1", "", opts);
        console.log("Marketplace upgraded");

        // 2. 更新 Marketplace 的预言机地址
        // NFTMarketplaceV1(marketplaceProxy).updatePriceOracle(priceOracle);
        // console.log("Marketplace priceOracle updated to:", priceOracle);

        vm.stopBroadcast();

        console.log("");
        console.log("=== Upgrade Complete ===");
    }
}
