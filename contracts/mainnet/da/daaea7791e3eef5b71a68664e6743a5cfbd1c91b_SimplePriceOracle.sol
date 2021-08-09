/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// File: contracts/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;


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
    constructor () internal {
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

// File: contracts/SimplePriceOracle.sol


pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;


contract SimplePriceOracle is Ownable{

    /// @dev Describe how to interpret the fixedPrice in the TokenConfig.
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    struct TokenConfig {
        address slToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
    }

    /// @notice The number of wei in 1 ETH
    uint public constant ethBaseUnit = 1e18;

    /// @notice Official prices by slTokne address
    mapping(address => uint) public prices;
    /// @notice slToken => TokenConfig
    mapping(address => TokenConfig) public tokenConfigs;
    /// @notice symbol hash => slToken
    mapping(bytes32 => address) public slTokens;

    /// @notice The event emitted when the stored price is updated
    event PriceUpdated(string symbol, uint price);


    bytes32 constant ethHash = keccak256(abi.encodePacked("ETH"));

    constructor(TokenConfig[] memory configs) public {
        for(uint i = 0; i < configs.length; i++){
            tokenConfigs[configs[i].slToken] = configs[i];
            slTokens[configs[i].symbolHash] = configs[i].slToken;
        }
    }

    function price(string memory symbol) external view returns (uint) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return priceInternal(config);
    }

    function priceInternal(TokenConfig memory config) internal view returns (uint) {
        if (config.priceSource == PriceSource.REPORTER) return prices[config.slToken];
        if (config.priceSource == PriceSource.FIXED_USD) return config.fixedPrice;
        if (config.priceSource == PriceSource.FIXED_ETH) {
            uint usdPerEth = prices[slTokens[ethHash]];
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
            return mul(usdPerEth, config.fixedPrice) / ethBaseUnit;
        }
    }

    /**
     * @notice Get the underlying price of a slToken
     * @dev Implements the PriceOracle interface for Compound v2.
     * @param slToken The slToken address for price retrieval
     * @return Price denominated in USD, with 18 decimals, for the given slToken address
     */
    function getUnderlyingPrice(address slToken) external view returns (uint) {
        TokenConfig memory config = tokenConfigs[slToken];
         // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
         // Since the prices in this view have 6 decimals, we must scale them by 1e(36 - 6 - baseUnit)
        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    function postPrices(string[] calldata symbols, uint[] calldata priceArr) external onlyOwner{
        require(symbols.length == priceArr.length, "symbols and prices must be 1:1");

        TokenConfig memory config;
        // Try to update the view storage
        for (uint i = 0; i < symbols.length; i++) {
            config = getTokenConfigBySymbol(symbols[i]);
            require(config.priceSource == PriceSource.REPORTER, "only reporter prices get posted");

            prices[config.slToken] = priceArr[i];
            emit PriceUpdated(symbols[i], priceArr[i]);
        }
    }

    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory){
        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        return tokenConfigs[slTokens[symbolHash]];
    }

    /// @dev Overflow proof multiplication
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}