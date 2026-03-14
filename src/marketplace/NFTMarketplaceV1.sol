// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title NFTMarketplaceV1
 * @dev 可升级的NFT交易市场合约，支持上架、购买、版税和拍卖功能
 * @notice 使用简单的重入保护修饰符
 */
contract NFTMarketplaceV1 is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    /**
     * @dev 挂单结构体
     */
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    /**
     * @dev 拍卖结构体
     */
    struct Auction {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool active;
    }

    // 挂单映射
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    // 拍卖映射
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCounter;

    // 待退款映射（用于拍卖）
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;

    // 平台手续费（基点，10000 = 100%）
    uint256 public platformFee = 250; // 2.5%

    // 手续费接收地址
    address public feeRecipient;

    /**
     * @dev NFT上架事件
     */
    event NFTListed(
        uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price
    );

    /**
     * @dev NFT下架事件
     */
    event NFTDelisted(uint256 indexed listingId);

    /**
     * @dev 价格更新事件
     */
    event PriceUpdated(uint256 indexed listingId, uint256 newPrice);

    /**
     * @dev NFT售出事件
     */
    event NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 price);

    /**
     * @dev 拍卖创建事件
     */
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 endTime
    );

    /**
     * @dev 出价事件
     */
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);

    /**
     * @dev 拍卖结束事件
     */
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 finalPrice);

    /// @custom:oz-upgrades-constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化函数
     * @param _feeRecipient 手续费接收地址
     */
    function initialize(address _feeRecipient) public initializer {
        require(_feeRecipient != address(0), "Invalid fee recipient");

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        feeRecipient = _feeRecipient;
    }

    /**
     * @dev 上架NFT
     * @param nftContract NFT合约地址
     * @param tokenId Token ID
     * @param price 售价（wei）
     * @return listingId 挂单ID
     */
    function listNft(address nftContract, uint256 tokenId, uint256 price) external returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(nftContract != address(0), "Invalid NFT contract");

        IERC721 nft = IERC721(nftContract);

        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        listingCounter++;
        listings[listingCounter] =
            Listing({seller: msg.sender, nftContract: nftContract, tokenId: tokenId, price: price, active: true});

        emit NFTListed(listingCounter, msg.sender, nftContract, tokenId, price);

        return listingCounter;
    }

    /**
     * @dev 下架NFT
     * @param listingId 挂单ID
     */
    function delistNft(uint256 listingId) external {
        Listing storage listing = listings[listingId];

        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;

        emit NFTDelisted(listingId);
    }

    /**
     * @dev 更新挂单价格
     * @param listingId 挂单ID
     * @param newPrice 新价格（wei）
     */
    function updatePrice(uint256 listingId, uint256 newPrice) external {
        require(newPrice > 0, "Price must be greater than 0");

        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.price = newPrice;

        emit PriceUpdated(listingId, newPrice);
    }

    /**
     * @dev 购买NFT
     * @param listingId 挂单ID
     */
    function buyNft(uint256 listingId) external payable nonReentrant {
        Listing storage listing = listings[listingId];

        require(listing.active, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");

        listing.active = false;

        uint256 fee = (listing.price * platformFee) / 10000;

        (address royaltyReceiver, uint256 royaltyAmount) =
            _getRoyaltyInfo(listing.nftContract, listing.tokenId, listing.price);

        uint256 sellerAmount = listing.price - fee - royaltyAmount;

        IERC721(listing.nftContract).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            (bool successRoyalty,) = royaltyReceiver.call{value: royaltyAmount}("");
            require(successRoyalty, "Royalty transfer failed");
        }

        (bool successSeller,) = listing.seller.call{value: sellerAmount}("");
        require(successSeller, "Transfer to seller failed");

        (bool successFee,) = feeRecipient.call{value: fee}("");
        require(successFee, "Transfer fee failed");

        if (msg.value > listing.price) {
            (bool successRefund,) = msg.sender.call{value: msg.value - listing.price}("");
            require(successRefund, "Refund failed");
        }

        emit NFTSold(listingId, msg.sender, listing.seller, listing.price);
    }

    /**
     * @dev 创建拍卖
     * @param nftContract NFT合约地址
     * @param tokenId Token ID
     * @param startPrice 起拍价（wei）
     * @param durationHours 拍卖时长（小时）
     * @return auctionId 拍卖ID
     */
    function createAuction(address nftContract, uint256 tokenId, uint256 startPrice, uint256 durationHours)
        external
        returns (uint256)
    {
        require(startPrice > 0, "Start price must be greater than 0");
        require(durationHours >= 1, "Duration must be at least 1 hour");
        require(nftContract != address(0), "Invalid NFT contract");

        IERC721 nft = IERC721(nftContract);

        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "Marketplace not approved"
        );

        auctionCounter++;
        auctions[auctionCounter] = Auction({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            startPrice: startPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + (durationHours * 1 hours),
            active: true
        });

        emit AuctionCreated(
            auctionCounter, msg.sender, nftContract, tokenId, startPrice, auctions[auctionCounter].endTime
        );

        return auctionCounter;
    }

    /**
     * @dev 出价
     * @param auctionId 拍卖ID
     */
    function placeBid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];

        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.sender != auction.seller, "Seller cannot bid");

        uint256 minBid;
        if (auction.highestBid == 0) {
            minBid = auction.startPrice;
        } else {
            minBid = auction.highestBid + (auction.highestBid * 5 / 100);
        }

        require(msg.value >= minBid, "Bid too low");

        if (auction.highestBidder != address(0)) {
            pendingReturns[auctionId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    /**
     * @dev 提取出价退款
     * @param auctionId 拍卖ID
     */
    function withdrawBid(uint256 auctionId) external nonReentrant {
        uint256 amount = pendingReturns[auctionId][msg.sender];
        require(amount > 0, "No pending return");

        pendingReturns[auctionId][msg.sender] = 0;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev 结束拍卖
     * @param auctionId 拍卖ID
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];

        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            uint256 fee = (auction.highestBid * platformFee) / 10000;

            (address royaltyReceiver, uint256 royaltyAmount) =
                _getRoyaltyInfo(auction.nftContract, auction.tokenId, auction.highestBid);

            uint256 sellerAmount = auction.highestBid - fee - royaltyAmount;

            IERC721(auction.nftContract).safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);

            if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
                (bool successRoyalty,) = royaltyReceiver.call{value: royaltyAmount}("");
                require(successRoyalty, "Royalty transfer failed");
            }

            (bool successSeller,) = auction.seller.call{value: sellerAmount}("");
            require(successSeller, "Transfer to seller failed");

            (bool successFee,) = feeRecipient.call{value: fee}("");
            require(successFee, "Transfer fee failed");

            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }

    /**
     * @dev 获取版税信息
     * @param nftContract NFT合约地址
     * @param tokenId Token ID
     * @param salePrice 售价
     * @return receiver 版税接收地址
     * @return royaltyAmount 版税金额
     */
    function _getRoyaltyInfo(address nftContract, uint256 tokenId, uint256 salePrice)
        internal
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (IERC165(nftContract).supportsInterface(type(IERC2981).interfaceId)) {
            (receiver, royaltyAmount) = IERC2981(nftContract).royaltyInfo(tokenId, salePrice);
        } else {
            receiver = address(0);
            royaltyAmount = 0;
        }
    }

    /**
     * @dev 查询挂单信息
     * @param listingId 挂单ID
     */
    function getListing(uint256 listingId)
        external
        view
        returns (address seller, address nftContract, uint256 tokenId, uint256 price, bool active)
    {
        Listing memory listing = listings[listingId];
        return (listing.seller, listing.nftContract, listing.tokenId, listing.price, listing.active);
    }

    /**
     * @dev 查询拍卖信息
     * @param auctionId 拍卖ID
     */
    function getAuction(uint256 auctionId)
        external
        view
        returns (
            address seller,
            address nftContract,
            uint256 tokenId,
            uint256 startPrice,
            uint256 highestBid,
            address highestBidder,
            uint256 endTime,
            bool active
        )
    {
        Auction memory auction = auctions[auctionId];
        return (
            auction.seller,
            auction.nftContract,
            auction.tokenId,
            auction.startPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.active
        );
    }

    /**
     * @dev 设置平台手续费
     * @param newFee 新的手续费（基点）
     */
    function setPlatformFee(uint256 newFee) external {
        require(msg.sender == feeRecipient, "Not fee recipient");
        require(newFee <= 1000, "Fee too high");
        platformFee = newFee;
    }

    /**
     * @dev 更新手续费接收地址
     * @param newRecipient 新的接收地址
     */
    function updateFeeRecipient(address newRecipient) external {
        require(msg.sender == feeRecipient, "Not fee recipient");
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
    }

    /**
     * @dev UUPS 升级授权
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
