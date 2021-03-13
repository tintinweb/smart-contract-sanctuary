/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

// File contracts/ERC20/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}


// File contracts/interfaces/IOracle.sol

pragma solidity ^0.8.0;

interface IOracle {
    function getPriceUSD(address _asset) external view returns (uint256 price);
}


// File contracts/interfaces/IFactory.sol

pragma solidity ^0.8.0;

interface IFactory {
    function pool_count() external view returns (uint256);
    function pool_list(uint256 i) external view returns (address);
    function get_coins(address pool) external view returns (address[] memory);
    function get_underlying_coins(address pool) external view returns (address[] memory);
    function get_decimals(address pool) external view returns (uint256[] memory);
    function get_underlying_decimals(address pool) external view returns (uint256[] memory);
    function get_balances(address pool) external view returns (uint256[] memory);
    function get_underlying_balances(address pool) external view returns (uint256[] memory);
}


// File contracts/utils/Context.sol

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/utils/Ownable.sol

pragma solidity ^0.8.0;
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File contracts/MultiCall.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract MultiCall is Ownable {
    struct TokenData {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        uint256 price;
        uint256 balance;
    }

    struct PoolData {
        address poolAddress;
        address[] coins;
        address[] underlyingCoins;
        uint256[] decimals;
        uint256[] underlyingDecimals;
        uint256[] balances;
        uint256[] underlyingBalances;
    }

    IOracle public oracle = IOracle(0x1447Db893bC4f6767460AD72359deAd840339c6a);
    IFactory public factory = IFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);

    function getTokens(IERC20[] calldata _assets, bool[] calldata _getPrice, address _account) external view returns (TokenData[] memory data) {
        data = new TokenData[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            data[i] = getToken(_assets[i], _getPrice[i], _account);
        }
    }

    function getPools() external view returns (PoolData[] memory data) {
        uint256 poolCount = factory.pool_count();
        data = new PoolData[](poolCount);
        for (uint256 i = 0; i < poolCount; i++) {
            address poolAddress = factory.pool_list(i);
            data[i] = getPool(poolAddress);
        }
    }

    function setOracle(IOracle _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setFactory(IFactory _factory) external onlyOwner {
        factory = _factory;
    }

    function getToken(IERC20 _asset, bool _getPrice, address _account) public view returns (TokenData memory) {
        string memory _name = _asset.name();
        string memory _symbol = _asset.symbol();
        uint8 _decimals = _asset.decimals();
        uint256 _totalSupply = _asset.totalSupply();
        uint256 _balance = _asset.balanceOf(_account);
        uint256 _price = _getPrice && address(oracle) != address(0) ? oracle.getPriceUSD(address(_asset)) : 0;
        return TokenData({
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            totalSupply: _totalSupply,
            price: _price,
            balance: _balance
        });
    }

    function getPool(address pool) public view returns (PoolData memory) {
        address[] memory _coins = factory.get_coins(pool);
        address[] memory _underlyingCoins = factory.get_underlying_coins(pool);
        uint256[] memory _decimals = factory.get_decimals(pool);
        uint256[] memory _underlyingDecimals = factory.get_underlying_decimals(pool);
        uint256[] memory _balances = factory.get_balances(pool);
        uint256[] memory _underlyingBalances = factory.get_underlying_balances(pool);
        
        return PoolData({
            poolAddress: pool,
            coins: _coins,
            underlyingCoins: _underlyingCoins,
            decimals: _decimals,
            underlyingDecimals: _underlyingDecimals,
            balances: _balances,
            underlyingBalances: _underlyingBalances
        });
    }
}