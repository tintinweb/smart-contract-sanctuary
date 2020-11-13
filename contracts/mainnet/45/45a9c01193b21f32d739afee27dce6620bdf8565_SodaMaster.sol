// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/SodaMaster.sol

/*

Here we have a list of constants. In order to get access to an address
managed by SodaMaster, the calling contract should copy and define
some of these constants and use them as keys.

Keys themselves are immutable. Addresses can be immutable or mutable.

a) Vault addresses are immutable once set, and the list may grow:

K_VAULT_WETH = 0;
K_VAULT_USDT_ETH_SUSHI_LP = 1;
K_VAULT_SOETH_ETH_UNI_V2_LP = 2;
K_VAULT_SODA_ETH_UNI_V2_LP = 3;
K_VAULT_GT = 4;
K_VAULT_GT_ETH_UNI_V2_LP = 5;


b) SodaMade token addresses are immutable once set, and the list may grow:

K_MADE_SOETH = 0;


c) Strategy addresses are mutable:

K_STRATEGY_CREATE_SODA = 0;
K_STRATEGY_EAT_SUSHI = 1;
K_STRATEGY_SHARE_REVENUE = 2;


d) Calculator addresses are mutable:

K_CALCULATOR_WETH = 0;

Solidity doesn't allow me to define global constants, so please
always make sure the key name and key value are copied as the same
in different contracts.

*/

// SodaMaster manages the addresses all the other contracts of the system.
// This contract is owned by Timelock.
contract SodaMaster is Ownable {

    address public pool;
    address public bank;
    address public revenue;
    address public dev;

    address public soda;
    address public wETH;
    address public usdt;

    address public uniswapV2Factory;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isSodaMade;
    mapping(uint256 => address) public sodaMadeByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;

    mapping(address => bool) public isCalculator;
    mapping(uint256 => address) public calculatorByKey;

    // Immutable once set.
    function setPool(address _pool) external onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }

    // Immutable once set.
    // Bank owns all the SodaMade tokens.
    function setBank(address _bank) external onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }

    // Mutable in case we want to upgrade this module.
    function setRevenue(address _revenue) external onlyOwner {
        revenue = _revenue;
    }

    // Mutable in case we want to upgrade this module.
    function setDev(address _dev) external onlyOwner {
        dev = _dev;
    }

    // Mutable, in case Uniswap has changed or we want to switch to sushi.
    // The core systems, Pool and Bank, don't rely on Uniswap, so there is no risk.
    function setUniswapV2Factory(address _uniswapV2Factory) external onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }

    // Immutable once set.
    function setWETH(address _wETH) external onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }

    // Immutable once set. Hopefully Tether is reliable.
    // Even if it fails, not a big deal, we only used USDT to estimate APY.
    function setUSDT(address _usdt) external onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }
 
    // Immutable once set.
    function setSoda(address _soda) external onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }

    // Immutable once added, and you can always add more.
    function addVault(uint256 _key, address _vault) external onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }

    // Immutable once added, and you can always add more.
    function addSodaMade(uint256 _key, address _sodaMade) external onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }

    // Mutable and removable.
    function addStrategy(uint256 _key, address _strategy) external onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) external onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    // Mutable and removable.
    function addCalculator(uint256 _key, address _calculator) external onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) external onlyOwner {
        isCalculator[calculatorByKey[_key]] = false;
        delete calculatorByKey[_key];
    }
}