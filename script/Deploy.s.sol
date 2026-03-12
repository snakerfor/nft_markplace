// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyERC20} from "../src/MyERC20.sol";
import {MyNFTWithRoyalty} from "../src/MyNFTWithRoyalty.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // 可选：通过环境变量自定义，或使用默认的 deployer
        address royaltyReceiver = vm.envOr("ROYALTY_RECEIVER", deployer);
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);

        // 可选：ERC20 部署参数
        string memory erc20Name = vm.envOr("ERC20_NAME", string("MyToken"));
        string memory erc20Symbol = vm.envOr("ERC20_SYMBOL", string("MTK"));
        uint256 erc20Supply = vm.envOr("ERC20_SUPPLY", uint256(1000000 ether));

        console.log("Deployer address:", deployer);
        console.log("Royalty receiver:", royaltyReceiver);
        console.log("Fee recipient:", feeRecipient);

        // 通过环境变量获取已部署地址，如果为 address(0) 则重新部署
        address erc20Address = vm.envOr("ERC20_ADDRESS", address(0));
        address nftAddress = vm.envOr("NFT_ADDRESS", address(0));
        address marketplaceAddress = vm.envOr("MARKETPLACE_ADDRESS", address(0));

        MyERC20 erc20;
        MyNFTWithRoyalty nft;
        NFTMarketplace marketplace;

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署或加载 MyERC20
        if (erc20Address == address(0)) {
            erc20 = new MyERC20(erc20Name, erc20Symbol, erc20Supply, deployer);
            console.log("MyERC20 deployed at:", address(erc20));
        } else {
            erc20 = MyERC20(erc20Address);
            console.log("Using existing MyERC20 at:", erc20Address);
        }

        // 2. 部署或加载 MyNFTWithRoyalty
        if (nftAddress == address(0)) {
            nft = new MyNFTWithRoyalty(royaltyReceiver, 1000);
            console.log("MyNFTWithRoyalty deployed at:", address(nft));
        } else {
            nft = MyNFTWithRoyalty(nftAddress);
            console.log("Using existing MyNFTWithRoyalty at:", nftAddress);
        }

        // 3. 部署或加载 NFTMarketplace
        if (marketplaceAddress == address(0)) {
            marketplace = new NFTMarketplace(feeRecipient);
            console.log("NFTMarketplace deployed at:", address(marketplace));
        } else {
            marketplace = NFTMarketplace(marketplaceAddress);
            console.log("Using existing NFTMarketplace at:", marketplaceAddress);
        }

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("ERC20 Contract:", address(erc20));
        console.log("NFT Contract:", address(nft));
        console.log("Marketplace Contract:", address(marketplace));
        console.log("Deployer:", deployer);
    }
}
