// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { Upgrades } from "@openzeppelin-foundry-upgrades/Upgrades.sol";
import { MyTokenV1 } from "../src/token/MyTokenV1.sol";
import { MyNFTV1 } from "../src/nft/MyNFTV1.sol";
import { NFTMarketplaceV1 } from "../src/marketplace/NFTMarketplaceV1.sol";

// 升级时需要修改这些地址
contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // 从环境变量读取代理地址
        address tokenProxy = vm.envAddress("TOKEN_PROXY");
        address nftProxy = vm.envAddress("NFT_PROXY");
        address marketplaceProxy = vm.envAddress("MARKETPLACE_PROXY");

        console.log("Upgrading contracts...");
        console.log("Token Proxy:", tokenProxy);
        console.log("NFT Proxy:", nftProxy);
        console.log("Marketplace Proxy:", marketplaceProxy);

        vm.startBroadcast(deployerPrivateKey);

        // 升级 Token
        Upgrades.upgradeProxy(
            tokenProxy,
            "src/token/MyTokenV1.sol:MyTokenV1",
            ""
        );
        console.log("Token upgraded");

        // 升级 NFT
        Upgrades.upgradeProxy(
            nftProxy,
            "src/nft/MyNFTV1.sol:MyNFTV1",
            ""
        );
        console.log("NFT upgraded");

        // 升级 Marketplace
        Upgrades.upgradeProxy(
            marketplaceProxy,
            "src/marketplace/NFTMarketplaceV1.sol:NFTMarketplaceV1",
            ""
        );
        console.log("Marketplace upgraded");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Upgrade Complete ===");
    }
}
