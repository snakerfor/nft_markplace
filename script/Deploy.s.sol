// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "@openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "@openzeppelin-foundry-upgrades/Options.sol";
import {PaymentTokenV1} from "../src/token/PaymentTokenV1.sol";
import {NFTCollectionV1} from "../src/nft/NFTCollectionV1.sol";
import {NFTMarketplaceV1} from "../src/marketplace/NFTMarketplaceV1.sol";
import {PriceOracle} from "../src/oracle/PriceOracle.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("ETH_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address royaltyReceiver = vm.envOr("ROYALTY_RECEIVER", deployer);
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);

        string memory erc20Name = vm.envOr("ERC20_NAME", string("MyToken"));
        string memory erc20Symbol = vm.envOr("ERC20_SYMBOL", string("MTK"));
        uint256 erc20Supply = vm.envOr("ERC20_SUPPLY", uint256(1000000 ether));

        // Chainlink ETH/USD Feed 地址 (Sepolia)
        address ethUsdFeed = vm.envOr("PRICE_ORACLE_ETH_FEED", address(0));
        require(ethUsdFeed != address(0), "PRICE_ORACLE_ETH_FEED not set");

        console.log("Deployer address:", deployer);
        console.log("Royalty receiver:", royaltyReceiver);
        console.log("Fee recipient:", feeRecipient);
        console.log("ETH/USD Feed:", ethUsdFeed);

        // 代理地址（升级时使用）
        address tokenProxyAddress = vm.envOr("TOKEN_PROXY", address(0));
        address nftProxyAddress = vm.envOr("NFT_PROXY", address(0));
        address marketplaceProxyAddress = vm.envOr("MARKETPLACE_PROXY", address(0));
        address priceOracleAddress = vm.envOr("PRICE_ORACLE", address(0));

        // 部署结果
        address tokenProxy;
        address nftProxy;
        address marketplaceProxy;
        address priceOracle;

        vm.startBroadcast(deployerPrivateKey);

        // 跳过升级安全检查的选项
        Options memory opts;
        opts.unsafeSkipAllChecks = true;

        // 1. 部署 PriceOracle（Chainlink 预言机）
        if (priceOracleAddress != address(0)) {
            console.log("PriceOracle already deployed at:", priceOracleAddress);
            priceOracle = priceOracleAddress;
        } else {
            PriceOracle oracle = new PriceOracle(ethUsdFeed);
            priceOracle = address(oracle);
            console.log("PriceOracle deployed at:", priceOracle);
        }

        // 2. 部署 MyToken (UUPS Proxy)
        if (tokenProxyAddress != address(0)) {
            console.log("Token Proxy already deployed at:", tokenProxyAddress);
            tokenProxy = tokenProxyAddress;
        } else {
            tokenProxy = Upgrades.deployUUPSProxy(
                "PaymentTokenV1.sol:PaymentTokenV1",
                abi.encodeCall(PaymentTokenV1.initialize, (erc20Name, erc20Symbol, erc20Supply, deployer)),
                opts
            );
            console.log("MyToken Proxy deployed at:", tokenProxy);
        }

        // 3. 部署 MyNFT (UUPS Proxy)
        if (nftProxyAddress != address(0)) {
            console.log("NFT Proxy already deployed at:", nftProxyAddress);
            nftProxy = nftProxyAddress;
        } else {
            nftProxy = Upgrades.deployUUPSProxy(
                "NFTCollectionV1.sol:NFTCollectionV1",
                abi.encodeCall(NFTCollectionV1.initialize, ("MyNFT", "MNFT", royaltyReceiver, 1000)),
                opts
            );
            console.log("MyNFT Proxy deployed at:", nftProxy);
        }

        // 4. 部署 NFTMarketplace (UUPS Proxy)，绑定 PriceOracle
        if (marketplaceProxyAddress != address(0)) {
            console.log("Marketplace Proxy already deployed at:", marketplaceProxyAddress);
            marketplaceProxy = marketplaceProxyAddress;
        } else {
            marketplaceProxy = Upgrades.deployUUPSProxy(
                "NFTMarketplaceV1.sol:NFTMarketplaceV1",
                abi.encodeWithSelector(NFTMarketplaceV1.initialize.selector, feeRecipient, priceOracle),
                opts
            );
            console.log("NFTMarketplace Proxy deployed at:", marketplaceProxy);
        }

        vm.stopBroadcast();

        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("PriceOracle:", priceOracle);
        console.log("Token Proxy:", tokenProxy);
        console.log("NFT Proxy:", nftProxy);
        console.log("Marketplace Proxy:", marketplaceProxy);
        console.log("Deployer:", deployer);
    }
}
