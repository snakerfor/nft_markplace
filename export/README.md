# NFT Marketplace 合约接口文档

## 概述

本文档描述了 NFT Marketplace 项目中所有智能合约的接口，供 Golang 后端项目集成使用。

---

## 网络配置

| 网络 | RPC URL |
|------|---------|
| Sepolia (测试网) | `https://sepolia.infura.io/v3/26ec931fe0c741e7b0aed6cadf090562` |

---

## 合约地址

| 合约 | 地址 | 说明 |
|------|------|------|
| **PaymentTokenV1** | `0x8a19c7A1c0562384D2f70477Ed73ff0a5AA4Da1F` | ERC20 支付代币合约 |
| **NFTCollectionV1** | `0x2AcDaea289b8eBbdb88444ead37784eC61781848` | ERC721 NFT 合约 |
| **NFTMarketplaceV1** | `0x8b63afE7dF2c987844d1D1feDd4770B794A93169` | NFT 交易市场合约 |
| **PriceOracle** | `0x09fde04e563e02f912558c280e0dd38eef237dfb` | Chainlink 价格预言机 |
| **ETH/USD Feed** | `0x694AA1769357215DE4FAC081bf1f309aDC325306` | Chainlink ETH/USD 价格源 |

---

## ABI 文件

ABI 文件位于本目录（`export/`），文件名与合约名对应：

- `PaymentTokenV1.json` - 支付代币 ABI
- `NFTCollectionV1.json` - NFT 合约 ABI
- `NFTMarketplaceV1.json` - 交易市场 ABI
- `PriceOracle.json` - 价格预言机 ABI

### 生成 Go 绑定

```bash
# 安装 abigen (需要先安装 go-ethereum)
go install github.com/ethereum/go-ethereum@latest

# 在你的 Golang 项目中执行
cd your-golang-project

abigen --abi=export/PaymentTokenV1.json --pkg=token --out=contracts/token.go
abigen --abi=export/NFTCollectionV1.json --pkg=nft --out=contracts/nft.go
abigen --abi=export/NFTMarketplaceV1.json --pkg=marketplace --out=contracts/marketplace.go
abigen --abi=export/PriceOracle.json --pkg=oracle --out=contracts/oracle.go
```

---

## PaymentTokenV1 (ERC20 代币)

### 合约信息

- 类型：ERC20 代币
- 特性：UUPS 可升级
- 初始供应量：1,000,000 STK

### 函数详情

#### 自定义函数

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `initialize(string name, string symbol, uint256 initialSupply, address recipient)` | public | No | 初始化合约（仅调用一次） |
| `mint(address to, uint256 amount)` | public | No | 铸造代币（onlyOwner） |
| `burn(address from, uint256 amount)` | public | No | 销毁代币（onlyOwner） |

**initialize 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `name` | string | 代币名称 |
| `symbol` | string | 代币符号 |
| `initialSupply` | uint256 | 初始供应量（需要考虑 decimals） |
| `recipient` | address | 初始代币接收地址 |

**mint 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `to` | address | 接收代币的地址 |
| `amount` | uint256 | 铸造的代币数量 |

**burn 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `from` | address | 销毁代币的地址 |
| `amount` | uint256 | 销毁的代币数量 |

#### 标准 ERC20 函数

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `name()` | public | No | 返回代币名称 |
| `symbol()` | public | No | 返回代币符号 |
| `decimals()` | public | No | 返回精度（18） |
| `totalSupply()` | public | No | 返回总供应量 |
| `balanceOf(address account)` | public | No | 查询地址余额 |
| `transfer(address to, uint256 value)` | public | No | 转账 |
| `allowance(address owner, address spender)` | public | No | 查询授权额度 |
| `approve(address spender, uint256 value)` | public | No | 授权 |
| `transferFrom(address from, address to, uint256 value)` | public | No | 从他人账户转账 |

**transfer 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `to` | address | 接收方地址 |
| `value` | uint256 | 转账金额 |

**allowance 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `owner` | address | 代币持有者地址 |
| `spender` | address | 被授权地址 |

**approve 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `spender` | address | 被授权地址 |
| `value` | uint256 | 授权金额 |

**transferFrom 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `from` | address | 转出方地址 |
| `to` | address | 接收方地址 |
| `value` | uint256 | 转账金额 |

#### Ownable & UUPS 函数

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `owner()` | public | No | 返回合约所有者 |
| `renounceOwnership()` | public | No | 放弃所有权 |
| `transferOwnership(address newOwner)` | public | No | 转移所有权 |
| `proxiableUUID()` | public | No | UUPS 升级代理 UUID |
| `upgradeToAndCall(address newImplementation, bytes data)` | public | Yes | 升级并调用 |

### 事件详情

| 事件名 | 索引字段 | 非索引字段 | 说明 |
|--------|----------|------------|------|
| `Transfer(address indexed from, address indexed to, uint256 indexed tokenId)` | from, to, tokenId | - | 转账事件 |
| `Approval(address indexed owner, address indexed spender, uint256 value)` | owner, spender | value | 授权事件 |
| `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)` | previousOwner, newOwner | - | 所有权转移事件 |
| `Initialized(uint64 version)` | - | version | 初始化事件 |
| `Upgraded(address indexed implementation)` | implementation | - | 升级事件 |

---

## NFTCollectionV1 (ERC721 NFT)

### 合约信息

- 类型：ERC721 NFT
- 特性：UUPS 可升级，支持 ERC2981 版税
- 最大供应量：10,000
- 铸造价格：0.01 ETH

### 函数详情

#### 自定义函数

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `initialize(string name, string symbol, address royaltyReceiver_, uint96 royaltyBps_)` | public | No | 初始化合约 |
| `mint(string uri)` | public | Yes | 铸造 NFT |
| `royaltyInfo(uint256, uint256 salePrice)` | public | No | 查询版税信息 |
| `setRoyaltyInfo(address receiver, uint96 bps)` | external | No | 设置版税（onlyOwner） |
| `getRoyaltyReceiver()` | external | No | 查询版税接收地址 |
| `getRoyaltyBps()` | external | No | 查询版税比例 |
| `totalSupply()` | public | No | 查询已铸造数量 |
| `withdraw()` | public | No | 提取合约余额（onlyOwner） |

**initialize 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `name` | string | NFT 名称 |
| `symbol` | string | NFT 符号 |
| `royaltyReceiver_` | address | 版税接收地址 |
| `royaltyBps_` | uint96 | 版税比例（基点，1000 = 10%） |

**mint 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `uri` | string | Token URI（元数据） |

**royaltyInfo 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| (第一个参数) | uint256 | Token ID（未使用） |
| `salePrice` | uint256 | 售价 |

**royaltyInfo 返回值：**

| 返回值名 | 类型 | 说明 |
|----------|------|------|
| `receiver` | address | 版税接收地址 |
| `royaltyAmount` | uint256 | 版税金额 |

**setRoyaltyInfo 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `receiver` | address | 新的版税接收地址 |
| `bps` | uint96 | 新的版税比例（基点） |

#### 标准 ERC721 函数

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `name()` | public | No | 返回 NFT 名称 |
| `symbol()` | public | No | 返回 NFT 符号 |
| `ownerOf(uint256 tokenId)` | public | No | 查询 NFT 所有者 |
| `tokenURI(uint256 tokenId)` | public | No | 查询 Token URI |
| `balanceOf(address owner)` | public | No | 查询地址持有的 NFT 数量 |
| `approve(address to, uint256 tokenId)` | public | No | 授权单个 NFT |
| `getApproved(uint256 tokenId)` | public | No | 查询 NFT 授权地址 |
| `setApprovalForAll(address operator, bool approved)` | public | No | 批量授权 |
| `isApprovedForAll(address owner, address operator)` | public | No | 查询批量授权状态 |
| `transferFrom(address from, address to, uint256 tokenId)` | public | No | 转账 NFT |
| `safeTransferFrom(address from, address to, uint256 tokenId)` | public | No | 安全转账 |
| `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)` | public | No | 带数据的安全转账 |
| `supportsInterface(bytes4 interfaceId)` | public | No | 检查接口支持 |

**ownerOf 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `tokenId` | uint256 | Token ID |

**tokenURI 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `tokenId` | uint256 | Token ID |

**balanceOf 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `owner` | address | 地址 |

**approve 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `to` | address | 授权地址 |
| `tokenId` | uint256 | Token ID |

**getApproved 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `tokenId` | uint256 | Token ID |

**setApprovalForAll 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `operator` | address | 被授权操作者地址 |
| `approved` | bool | 是否授权 |

**isApprovedForAll 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `owner` | address | NFT 持有者地址 |
| `operator` | address | 操作者地址 |

**transferFrom / safeTransferFrom 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `from` | address | 转出方地址 |
| `to` | address | 接收方地址 |
| `tokenId` | uint256 | Token ID |
| `data` | bytes | 附加数据（仅 safeTransferFrom 带数据版本） |

### 事件详情

| 事件名 | 索引字段 | 非索引字段 | 说明 |
|--------|----------|------------|------|
| `Transfer(address indexed from, address indexed to, uint256 indexed tokenId)` | from, to, tokenId | - | 转账事件 |
| `Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)` | owner, approved, tokenId | - | 授权事件 |
| `ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved)` | owner, operator, approved | - | 批量授权事件 |
| `NFTMinted(address indexed minter, uint256 indexed tokenId, string uri)` | minter, tokenId | uri | NFT 铸造事件 |
| `RoyaltyInfoUpdated(address indexed receiver, uint96 bps)` | receiver | bps | 版税更新事件 |
| `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)` | previousOwner, newOwner | - | 所有权转移事件 |
| `Initialized(uint64 version)` | - | version | 初始化事件 |
| `MetadataUpdate(uint256 _tokenId)` | - | _tokenId | 元数据更新事件 |
| `BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)` | - | _fromTokenId, _toTokenId | 批量元数据更新事件 |

---

## NFTMarketplaceV1 (NFT 交易市场)

### 合约信息

- 类型：交易市场
- 特性：UUPS 可升级，支持挂单和拍卖
- 平台手续费：2.5%

### 函数详情

#### 挂单相关

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `listNft(address nftContract, uint256 tokenId, uint256 price)` | external | No | 上架 NFT |
| `delistNft(uint256 listingId)` | external | No | 下架 NFT |
| `updatePrice(uint256 listingId, uint256 newPrice)` | external | No | 更新挂单价格 |
| `buyNft(uint256 listingId)` | external | Yes | 购买 NFT |
| `getListing(uint256 listingId)` | external | No | 查询挂单详情 |

**listNft 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `nftContract` | address | NFT 合约地址 |
| `tokenId` | uint256 | Token ID |
| `price` | uint256 | 售价（wei） |

**listNft 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint256 | 挂单 ID（listingId） |

**delistNft 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `listingId` | uint256 | 挂单 ID |

**updatePrice 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `listingId` | uint256 | 挂单 ID |
| `newPrice` | uint256 | 新价格（wei） |

**buyNft 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `listingId` | uint256 | 挂单 ID |

**getListing 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `listingId` | uint256 | 挂单 ID |

**getListing 返回值：**

| 返回值名 | 类型 | 说明 |
|----------|------|------|
| `seller` | address | 卖家地址 |
| `nftContract` | address | NFT 合约地址 |
| `tokenId` | uint256 | Token ID |
| `price` | uint256 | 价格（wei） |
| `active` | bool | 是否有效 |

#### 拍卖相关

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `createAuction(address nftContract, uint256 tokenId, uint256 startPrice, uint256 durationHours)` | external | No | 创建拍卖 |
| `placeBid(uint256 auctionId)` | external | Yes | 出价 |
| `withdrawBid(uint256 auctionId)` | external | No | 提取出价退款 |
| `endAuction(uint256 auctionId)` | external | No | 结束拍卖 |
| `getAuction(uint256 auctionId)` | external | No | 查询拍卖详情 |
| `getHighestBidUsdValue(uint256 auctionId)` | external | No | 获取最高出价 USD 价值 |

**createAuction 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `nftContract` | address | NFT 合约地址 |
| `tokenId` | uint256 | Token ID |
| `startPrice` | uint256 | 起拍价（wei） |
| `durationHours` | uint256 | 拍卖时长（小时，最小 1） |

**createAuction 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint256 | 拍卖 ID（auctionId） |

**placeBid 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `auctionId` | uint256 | 拍卖 ID |

**withdrawBid 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `auctionId` | uint256 | 拍卖 ID |

**endAuction 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `auctionId` | uint256 | 拍卖 ID |

**getAuction 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `auctionId` | uint256 | 拍卖 ID |

**getAuction 返回值：**

| 返回值名 | 类型 | 说明 |
|----------|------|------|
| `seller` | address | 卖家地址 |
| `nftContract` | address | NFT 合约地址 |
| `tokenId` | uint256 | Token ID |
| `startPrice` | uint256 | 起拍价（wei） |
| `highestBid` | uint256 | 最高出价（wei） |
| `highestBidder` | address | 最高出价者地址 |
| `endTime` | uint256 | 结束时间（Unix 时间戳） |
| `active` | bool | 是否有效 |

**getHighestBidUsdValue 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `auctionId` | uint256 | 拍卖 ID |

#### 管理方法

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `setPlatformFee(uint256 newFee)` | external | No | 设置平台手续费 |
| `updateFeeRecipient(address newRecipient)` | external | No | 更新手续费接收地址 |
| `updatePriceOracle(address newOracle)` | external | No | 更新预言机地址 |

**setPlatformFee 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `newFee` | uint256 | 新手续费（基点，最大 1000 = 10%） |

**updateFeeRecipient 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `newRecipient` | address | 新的手续费接收地址 |

**updatePriceOracle 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `newOracle` | address | 新的预言机地址 |

#### 状态变量读取

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `listingCounter()` | external | No | 获取挂单计数器 |
| `auctionCounter()` | external | No | 获取拍卖计数器 |
| `platformFee()` | public | No | 获取平台手续费比例 |
| `feeRecipient()` | public | No | 获取手续费接收地址 |
| `priceOracle()` | public | No | 获取预言机地址 |
| `listings(uint256)` | public | No | 获取挂单详情（映射） |
| `auctions(uint256)` | public | No | 获取拍卖详情（映射） |
| `pendingReturns(uint256, address)` | public | No | 获取待退款金额（映射） |

#### Ownable & UUPS 函数

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `owner()` | public | No | 返回合约所有者 |
| `renounceOwnership()` | public | No | 放弃所有权 |
| `transferOwnership(address newOwner)` | public | No | 转移所有权 |
| `proxiableUUID()` | public | No | UUPS 升级代理 UUID |
| `upgradeToAndCall(address newImplementation, bytes data)` | public | Yes | 升级并调用 |

### 数据结构

#### Listing（挂单）

```solidity
struct Listing {
    address seller;       // 卖家地址
    address nftContract; // NFT 合约地址
    uint256 tokenId;      // Token ID
    uint256 price;        // 价格（wei）
    bool active;          // 是否有效
}
```

#### Auction（拍卖）

```solidity
struct Auction {
    address seller;        // 卖家地址
    address nftContract;  // NFT 合约地址
    uint256 tokenId;       // Token ID
    uint256 startPrice;    // 起拍价（wei）
    uint256 highestBid;    // 最高出价
    address highestBidder; // 最高出价者
    uint256 endTime;       // 结束时间
    bool active;           // 是否有效
}
```

### 事件详情

| 事件名 | 索引字段 | 非索引字段 | 说明 |
|--------|----------|------------|------|
| `NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price)` | listingId, seller, nftContract | tokenId, price | NFT 上架事件 |
| `NFTDelisted(uint256 indexed listingId)` | listingId | - | NFT 下架事件 |
| `PriceUpdated(uint256 indexed listingId, uint256 newPrice)` | listingId | newPrice | 价格更新事件 |
| `NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 price)` | listingId, buyer, seller | price | NFT 售出事件 |
| `AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 startPrice, uint256 endTime)` | auctionId, seller, nftContract | tokenId, startPrice, endTime | 拍卖创建事件 |
| `BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 usdValue)` | auctionId, bidder | amount, usdValue | 出价事件 |
| `AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 finalPrice)` | auctionId, winner | finalPrice | 拍卖结束事件 |
| `BidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 amount)` | auctionId, bidder | amount | 出价退款事件 |
| `FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient)` | oldRecipient, newRecipient | - | 手续费接收地址更新事件 |
| `PlatformFeeUpdated(address indexed setter, uint256 oldFee, uint256 newFee)` | setter | oldFee, newFee | 平台手续费更新事件 |
| `PriceOracleUpdated(address indexed oldOracle, address indexed newOracle)` | oldOracle, newOracle | - | 预言机地址更新事件 |
| `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)` | previousOwner, newOwner | - | 所有权转移事件 |
| `Initialized(uint64 version)` | - | version | 初始化事件 |
| `Upgraded(address indexed implementation)` | implementation | - | 升级事件 |

---

## PriceOracle (Chainlink 价格预言机)

### 合约信息

- 类型：价格预言机
- 数据源：Chainlink ETH/USD Feed
- 特性：代币价格锚定 ETH（1:1）

### 构造函数

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `_ethUsdFeed` | address | Chainlink ETH/USD Feed 地址 |

### 函数详情

| 方法签名 | 可见性 | payable | 说明 |
|----------|--------|---------|------|
| `ethUsdFeed()` | public | No | 获取 ETH/USD Feed 地址 |
| `getEthUsdPrice()` | public | No | 获取 ETH/USD 最新价格 |
| `getPriceDecimals()` | public | No | 获取价格小数位数 |
| `getTokenUsdPrice()` | public | No | 获取代币/USD 价格 |
| `getEthValueInUsd(uint256 ethAmount)` | public | No | 将 ETH 转换为 USD |
| `getTokenValueInUsd(uint256 tokenAmount)` | public | No | 将代币转换为 USD |

**getEthValueInUsd 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `ethAmount` | uint256 | ETH 数量（wei） |

**getEthValueInUsd 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint256 | USD 价值（8 位小数） |

**getTokenValueInUsd 参数：**

| 参数名 | 类型 | 说明 |
|--------|------|------|
| `tokenAmount` | uint256 | 代币数量 |

**getTokenValueInUsd 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint256 | USD 价值（8 位小数） |

**getEthUsdPrice 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint256 | ETH/USD 价格（8 位小数） |

**getTokenUsdPrice 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint256 | 代币/USD 价格（= ETH/USD，8 位小数） |

**getPriceDecimals 返回值：**

| 返回值 | 类型 | 说明 |
|--------|------|------|
| (return) | uint8 | 价格小数位数 |

---

## Golang 调用示例

```go
package main

import (
    "context"
    "fmt"
    "math/big"

    "github.com/ethereum/go-ethereum/accounts/abi/bind"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // 连接 Sepolia 网络
    client, err := ethclient.Dial("https://sepolia.infura.io/v3/26ec931fe0c741e7b0aed6cadf090562")
    if err != nil {
        panic(err)
    }

    // ========== Marketplace 合约示例 ==========
    marketplaceAddr := common.HexToAddress("0x8b63afE7dF2c987844d1D1feDd4770B794A93169")
    marketplace, err := NewNFTMarketplace(marketplaceAddr, client)
    if err != nil {
        panic(err)
    }

    // 查询手续费接收地址
    feeRecipient, err := marketplace.FeeRecipient(&bind.CallOpts{})
    if err != nil {
        panic(err)
    }
    fmt.Println("Fee Recipient:", feeRecipient.Hex())

    // 查询平台手续费
    platformFee, err := marketplace.PlatformFee(&bind.CallOpts{})
    if err != nil {
        panic(err)
    }
    fmt.Println("Platform Fee:", platformFee, "bps (2.5% = 250)")

    // 上架 NFT
    nftContract := common.HexToAddress("0x2AcDaea289b8eBbdb88444ead37784eC61781848")
    tokenId := big.NewInt(1)
    price := big.NewInt(1000000000000000000) // 1 ETH

    tx, err := marketplace.ListNft(&bind.TransactOpts{
        From:  yourAddress,
        Value: big.NewInt(0),
    }, nftContract, tokenId, price)
    if err != nil {
        panic(err)
    }
    fmt.Println("List NFT Tx Hash:", tx.Hash().Hex())

    // 购买 NFT
    listingId := big.NewInt(1)
    tx, err = marketplace.BuyNft(&bind.TransactOpts{
        From:  buyerAddress,
        Value: big.NewInt(1000000000000000000), // 1 ETH
    }, listingId)
    if err != nil {
        panic(err)
    }
    fmt.Println("Buy NFT Tx Hash:", tx.Hash().Hex())

    // ========== NFT 合约示例 ==========
    nftAddr := common.HexToAddress("0x2AcDaea289b8eBbdb88444ead37784eC61781848")
    nft, err := NewNFTCollection(nftAddr, client)
    if err != nil {
        panic(err)
    }

    // 查询 NFT 所有者
    owner, err := nft.OwnerOf(&bind.CallOpts{}, big.NewInt(1))
    if err != nil {
        panic(err)
    }
    fmt.Println("NFT #1 Owner:", owner.Hex())

    // 查询版税信息
    receiver, royaltyAmount, err := nft.RoyaltyInfo(&bind.CallOpts{}, big.NewInt(1), big.NewInt(1000000000000000000))
    if err != nil {
        panic(err)
    }
    fmt.Println("Royalty Receiver:", receiver.Hex())
    fmt.Println("Royalty Amount:", royaltyAmount.String())

    // ========== Token 合约示例 ==========
    tokenAddr := common.HexToAddress("0x8a19c7A1c0562384D2f70477Ed73ff0a5AA4Da1F")
    token, err := NewPaymentToken(tokenAddr, client)
    if err != nil {
        panic(err)
    }

    // 查询余额
    balance, err := token.BalanceOf(&bind.CallOpts{}, userAddress)
    if err != nil {
        panic(err)
    }
    fmt.Println("Token Balance:", balance.String())

    // ========== PriceOracle 合约示例 ==========
    oracleAddr := common.HexToAddress("0x09fde04e563e02f912558c280e0dd38eef237dfb")
    oracle, err := NewPriceOracle(oracleAddr, client)
    if err != nil {
        panic(err)
    }

    // 查询 ETH/USD 价格
    price, err := oracle.GetEthUsdPrice(&bind.CallOpts{})
    if err != nil {
        panic(err)
    }
    fmt.Println("ETH/USD Price:", price.String())

    // ETH 转 USD
    ethAmount := big.NewInt(1000000000000000000) // 1 ETH
    usdValue, err := oracle.GetEthValueInUsd(&bind.CallOpts{}, ethAmount)
    if err != nil {
        panic(err)
    }
    fmt.Println("1 ETH in USD:", usdValue.String())
}
```

---

## 注意事项

1. **UUPS 代理合约**：这些合约都是通过 UUPS 代理部署的，调用时使用代理地址
2. **初始化**：代理合约部署后需要调用 `initialize` 方法进行初始化（已由部署脚本完成）
3. **Approve 授权**：在挂单或拍卖前，需要先授权 marketplace 合约操作你的 NFT
4. **ETH 支付**：购买 NFT 和出价需要支付 ETH
5. **版税**：NFTCollectionV1 支持 ERC2981 版税标准， marketplace 会自动处理版税支付
6. **payable 方法**：标记为 `payable` 的方法需要发送 ETH value
7. **时间戳**：`endTime` 返回的是 Unix 时间戳（uint256）
