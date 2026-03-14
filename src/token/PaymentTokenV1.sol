// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title MyTokenV1
 * @dev 可升级的 ERC20 代币合约
 */
contract PaymentTokenV1 is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev 初始化函数
     * @param name 代币名称
     * @param symbol 代币符号
     * @param initialSupply 初始供应量
     * @param recipient 初始代币接收地址
     */
    function initialize(string memory name, string memory symbol, uint256 initialSupply, address recipient)
        public
        initializer
    {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        _mint(recipient, initialSupply);
    }

    /**
     * @dev 铸造新代币
     * @param to 接收代币的地址
     * @param amount 铸造的代币数量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev 销毁代币
     * @param from 销毁代币的地址
     * @param amount 销毁的代币数量
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    /**
     * @dev UUPS 升级授权
     * @param newImplementation 新实现合约地址
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
