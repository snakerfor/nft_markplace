// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {
    ERC721URIStorageUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/**
 * @title MyNFTV1
 * @dev 可升级的支持ERC2981版税标准的NFT合约
 */
contract NFTCollectionV1 is
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable
{
    uint256 private _tokenIdCounter;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public mintPrice = 0.01 ether;

    // 版税接收地址
    address private _royaltyReceiver;

    // 版税比例（基点，10000 = 100%）
    uint96 private _royaltyBps = 1000; // 10%

    event NFTMinted(address indexed minter, uint256 indexed tokenId, string uri);

    /// @custom:oz-upgrades-constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化函数
     * @param name NFT名称
     * @param symbol NFT符号
     * @param royaltyReceiver_ 版税接收地址
     * @param royaltyBps_ 版税比例（基点）
     */
    function initialize(string memory name, string memory symbol, address royaltyReceiver_, uint96 royaltyBps_)
        public
        initializer
    {
        require(royaltyReceiver_ != address(0), "Invalid royalty receiver");
        require(royaltyBps_ <= 1000, "Royalty too high");

        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Ownable_init(msg.sender);

        _royaltyReceiver = royaltyReceiver_;
        _royaltyBps = royaltyBps_;
    }

    /**
     * @dev 铸造NFT
     */
    function mint(string memory uri) public payable returns (uint256) {
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient payment");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);

        emit NFTMinted(msg.sender, newTokenId, uri);

        return newTokenId;
    }

    /**
     * @dev 实现ERC2981标准：获取版税信息
     * @param salePrice 售价
     * @return receiver 版税接收地址
     * @return royaltyAmount 版税金额
     */
    function royaltyInfo(uint256, uint256 salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyReceiver;
        royaltyAmount = (salePrice * _royaltyBps) / 10000;
    }

    /**
     * @dev 设置版税信息
     * @param receiver 新的版税接收地址
     * @param bps 新的版税比例（基点）
     */
    function setRoyaltyInfo(address receiver, uint96 bps) external onlyOwner {
        require(receiver != address(0), "Invalid receiver");
        require(bps <= 1000, "Royalty too high");

        _royaltyReceiver = receiver;
        _royaltyBps = bps;
    }

    /**
     * @dev 查询版税接收地址
     */
    function getRoyaltyReceiver() external view returns (address) {
        return _royaltyReceiver;
    }

    /**
     * @dev 查询版税比例
     */
    function getRoyaltyBps() external view returns (uint96) {
        return _royaltyBps;
    }

    /**
     * @dev 重写tokenURI函数
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 检查接口支持
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev 查询总供应量
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev 提取铸造费用
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev UUPS 升级授权
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
