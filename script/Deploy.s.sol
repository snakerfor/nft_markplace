// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { Upgrades } from "@openzeppelin-foundry-upgrades/Upgrades.sol";
import { MyTokenV1 } from "../src/token/MyTokenV1.sol";
import { MyNFTV1 } from "../src/nft/MyNFTV1.sol";
import { NFTMarketplaceV1 } from "../src/marketplace/NFTMarketplaceV1.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address royaltyReceiver = vm.envOr("ROYALTY_RECEIVER", deployer);
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);

        string memory erc20Name = vm.envOr("ERC20_NAME", string("MyToken"));
        string memory erc20Symbol = vm.envOr("ERC20_SYMBOL", string("MTK"));
        uint256 erc20Supply = vm.envOr("ERC20_SUPPLY", uint256(1000000 ether));

        console.log("Deployer address:", deployer);
        console.log("Royalty receiver:", royaltyReceiver);
        console.log("Fee recipient:", feeRecipient);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 MyToken (UUPS Proxy)
        address tokenProxy = Upgrades.deployUUPSProxy(
            "src/token/MyTokenV1.sol:MyTokenV1",
            abi.encodeCall(MyTokenV1.initialize, (erc20Name, erc20Symbol, erc20Supply, deployer))
        );
        console.log("MyToken Proxy deployed at:", tokenProxy);

        // 2. 部署 MyNFT (UUPS Proxy)
        address nftProxy = Upgrades.deployUUPSProxy(
            "src/nft/MyNFTV1.sol:MyNFTV1",
            abi.encodeCall(MyNFTV1.initialize, ("MyNFT", "MNFT", royaltyReceiver, 1000))
        );
        console.log("MyNFT Proxy deployed at:", nftProxy);

        // 3. 部署 NFTMarketplace (UUPS Proxy)
        address marketplaceProxy = Upgrades.deployUUPSProxy(
            "src/marketplace/NFTMarketplaceV1.sol:NFTMarketplaceV1",
            abi.encodeCall(NFTMarketplaceV1.initialize, (feeRecipient))
        );
        console.log("NFTMarketplace Proxy deployed at:", marketplaceProxy);

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Token Proxy:", tokenProxy);
        console.log("NFT Proxy:", nftProxy);
        console.log("Marketplace Proxy:", marketplaceProxy);
        console.log("Deployer:", deployer);
    }
}
