# UUPS Proxy 合约验证指南

## 背景知识

UUPS Proxy 模式下，存在两个合约：

| 合约类型 | 说明 |
|---------|------|
| **Proxy 合约** | 入口，保存着指向实现合约的指针，所有调用通过 `delegatecall` 转发 |
| **Implementation 合约** | 真正的业务逻辑（字节码） |

部署时，Proxy 地址（如 `0x2AcDaea...`）是用户交互的入口，但真正的逻辑在 Implementation 地址（如 `0x68c92F...`）。

---

## 核心概念

### EIP-1967 Storage Slot

Proxy 合约通过 EIP-1967 标准的 storage slot 存储 implementation 地址：

```
Slot: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

计算方式：

```
keccak256("eip1967.proxy.implementation") - 1
```

这个 slot 由 OpenZeppelin 的 UUPS Proxy 实现使用，任何 UUPS Proxy 都用这个位置存储 implementation 地址。

**为什么需要这个？**

- 读取 slot → 知道当前用的是哪个 implementation
- 写入 slot → 升级到新的 implementation（UUPS 的升级机制）

---

## 验证步骤

### 第一步：获取 Implementation 地址

Proxy 合约的 storage slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` 存储了 implementation 地址：

```bash
cast storage <PROXY地址> 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url <RPC_URL>
```

**示例（Sepolia）：**

```bash
cast storage 0x2AcDaea289b8eBbdb88444ead37784eC61781848 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url https://sepolia.infura.io/v3/<YOUR_API_KEY>
```

返回：`0x68c92ff62fbdaec587ced849e3ac6339865bc74e`（Implementation 地址）

### 第二步：验证 Implementation 合约

使用 Foundry 的 `forge verify-contract` 命令验证 Implementation 合约：

```bash
forge verify-contract --chain sepolia \
  --constructor-args $(cast abi-encode "initialize(string,string,address,uint256)" "MyNFT" "MNFT" "0x..." 1000) \
  --compiler-version 0.8.24 \
  <IMPLEMENTATION地址> \
  src/nft/NFTCollectionV1.sol:NFTCollectionV1
```

**参数说明：**

| 参数 | 说明 |
|------|------|
| `--chain sepolia` | 目标网络（主网用 `mainnet`） |
| `--constructor-args` | 部署时传给 `initialize` 函数的参数 |
| `--compiler-version` | solc 编译器版本（从 foundry.toml 的 `solc` 字段获取） |
| 最后一个地址 | Implementation 合约地址 |
| 最后字符串 | 合约标识符，格式为 `文件路径:合约名` |

**示例：**

```bash
forge verify-contract --chain sepolia \
  --constructor-args $(cast abi-encode "initialize(string,string,address,uint256)" "MyNFT" "MNFT" "0xC7D080A394829BCc94178fF2E80ab1113DEFCfA9" 1000) \
  --compiler-version 0.8.24 \
  0x68c92ff62fbdaec587ced849e3ac6339865bc74e \
  src/nft/NFTCollectionV1.sol:NFTCollectionV1
```

### 第三步：检查验证状态

```bash
forge verify-check --chain sepolia <GUID>
```

**示例：**

```bash
forge verify-check --chain sepolia rvbjyht3brns8s6jdbjqirbweexhdcbjhrgn2i9yufqkvexpjm
```

### 第四步：关联 Proxy（可选）

验证通过后，在 Etherscan 的 Implementation 合约页面，会提示你填入 **Proxy 地址**，完成关联。

### 第五步：验证 Proxy 合约（可选）

Proxy 地址本身也可以单独验证，选择与 Implementation 相同的编译器版本即可。

---

## 常见问题

### 1. "Unable to find matching Contract Bytecode" 错误

**原因：** 尝试直接验证 Proxy 地址，而不是 Implementation 地址。

**解决：** 先读取 EIP-1967 slot 获取 Implementation 地址，再验证 Implementation。

### 2. 字节码不匹配

**可能原因：**
- 编译器版本选择错误
- 优化器设置（runs 数）与部署时不一致
- `via_ir` 设置不匹配
- 构造函数的参数不正确

**解决：** 检查 foundry.toml 配置，确保与部署时完全一致。

### 3. Etherscan 上看不到 "Read Contract" 按钮

**原因：** 合约代码未验证。

**解决：** 按照上述步骤完成验证。

---

## Foundry 配置参考

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 200
build_info = true
extra_output = ["storageLayout"]
via_ir = true
```

**验证时需要匹配的关键配置：**
- `solc` → Compiler Version
- `optimizer = true` → Optimization: Yes
- `optimizer_runs = 200` → Runs: 200
- `via_ir = true` → EVM Version 需支持（如 istanbul）

---

## 相关命令速查

```bash
# 1. 获取 Implementation 地址
cast storage <PROXY地址> 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url <RPC_URL>

# 2. 验证 Implementation 合约
forge verify-contract --chain sepolia --constructor-args $(cast abi-encode "initialize(string,string,address,uint256)" "MyNFT" "MNFT" "0x..." 1000) --compiler-version 0.8.24 <IMPLEMENTATION地址> <合约路径>

# 3. 检查验证状态
forge verify-check --chain sepolia <GUID>

# 4. 调用合约验证（验证后测试）
cast call <合约地址> "name()(string)" --rpc-url <RPC_URL>
cast call <合约地址> "tokenURI(uint256)(string)" 1 --rpc-url <RPC_URL>
```

---

## 参考资料

- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [OpenZeppelin UUPS Proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable)
- [Foundry Forge Verify](https://book.getfoundry.sh/forge/deploying#verifying-contracts)
