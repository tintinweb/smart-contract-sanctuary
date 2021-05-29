// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

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

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

// Ref: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library KineMath{
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) pure internal returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./PriceConfig.sol";
import "./IUniswapV2Pair.sol";

/// @title Kine Protocol Oracle V2
/// @author Kine Technology
contract KineOracleV2 is PriceConfig {
    /// @notice The latest mcd update time
    uint public mcdLastUpdatedAt;

    /// @notice The scale constant
    uint public constant priceScale = 1e36;

    /// @notice The kaptain address allowed to operate oracle prices
    address public kaptain;

    /// @notice The symbol hash of the string "MCD"
    bytes32 public constant mcdHash = keccak256(abi.encodePacked("MCD"));

    /// @notice The kaptain prices mapped by symbol hash
    mapping(bytes32 => uint) public prices;

    /// @notice Kaptain post price event
    event PriceUpdated(string symbol, uint price);

    /// @notice The event emitted when Kaptain is updated
    event KaptainUpdated(address fromAddress, address toAddress);

    /// @notice Only kaptain can update kaptain price and mcd price
    modifier onlyKaptain(){
        require(kaptain == _msgSender(), "caller is not Kaptain");
        _;
    }

    constructor(address kaptain_, KTokenConfig[] memory configs) public {
        kaptain = kaptain_;
        for (uint i = 0; i < configs.length; i++) {
            KTokenConfig memory config = configs[i];
            _pushConfig(config);
        }
    }

    /*********************************************************************************************
     * Price controller needs
     * Pc = priceControllerNeeds                        Pr * 1e36
     * Pr = realPricePerToken                 Pc  =  ---------------
     * Up = priceUnit                                    Up * Ub
     * Ub = baseUnit
     *********************************************************************************************/
    /**
     * @notice Get the underlying price of a kToken
     * @param kToken The kToken address for price retrieval
     * @return Price denominated in USD
     */
    function getUnderlyingPrice(address kToken) public view returns (uint){
        KTokenConfig memory config = getKConfigByKToken(kToken);
        uint price;
        if (config.priceSource == PriceSource.CHAINLINK) {
            price = _calcPrice(_getChainlinkPrice(config), config);
        }else if (config.priceSource == PriceSource.KAPTAIN) {
            price = _calcPrice(_getKaptainPrice(config), config);
        }else if (config.priceSource == PriceSource.LP){
            price = _calcLpPrice(config);
        }else{
            revert("invalid price source");
        }

        require(price != 0, "invalid price 0");

        return price;
    }

    /**
     * @notice Get the underlying price with a token symbol
     * @param symbol The token symbol for price retrieval
     * @return Price denominated in USD
     */
    function getUnderlyingPriceBySymbol(string memory symbol) external view returns (uint){
        KTokenConfig memory config = getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
        return getUnderlyingPrice(config.kToken);
    }

    /*********************************************************************************************
     * Pc = priceControllerNeeds
     * Pr = realPricePerToken                                    Pr * 1e36
     * Up = priceUnit                                   Pc  =  -------------
     * Ub = baseUnit                                                PM
     * PM = Up * Ub
     *********************************************************************************************/
    /**
     * @notice Calculate the price to fit the price Kine controller needs
     * @param price The price from price source such as chainlink
     * @param config The kToken configuration
     * @return Price denominated in USD
     */
    function _calcPrice(uint price, KTokenConfig memory config) internal pure returns (uint){
        return price.mul(priceScale).div(config.priceMantissa);
    }

    /*********************************************************************************************
     *  Pl = lpPrice
     *  p0 = token0_PriceFromPriceSource
     *  p1 = token1_PriceFromPriceSource
     *  r0 = reserve0                                 2 * sqrt(p0 * r0) * sqrt(p1 * r1) * 1e36
     *  r1 = reserve1                          Pl = --------------------------------------------
     *  PM0 = Token0_PriceMantissa                         totalSupply * sqrt(PM0 * PM1)
     *  PM1 = Token1_PriceMantissa
     *  totalSupply = LP totalSupply
     *  PriceMantissa = priceUnit * baseUnit
     *********************************************************************************************/
    function _calcLpPrice(KTokenConfig memory config) internal view returns (uint){
        uint numerator;
        uint denominator;
        KTokenConfig memory config0;
        KTokenConfig memory config1;

        {
            address token0 = IUniswapV2Pair(config.underlying).token0();
            address token1 = IUniswapV2Pair(config.underlying).token1();
            config0 = getKConfigByUnderlying(token0);
            config1 = getKConfigByUnderlying(token1);
        }

        {
            (uint r0, uint r1, ) = IUniswapV2Pair(config.underlying).getReserves();
            numerator = (_getSourcePrice(config0).mul(r0).sqrt())
                            .mul(_getSourcePrice(config1).mul(r1).sqrt())
                            .mul(2).mul(priceScale);
        }

        {
            uint totalSupply = IUniswapV2Pair(config.underlying).totalSupply();
            uint pmMultiplier = config0.priceMantissa.mul(config1.priceMantissa);
            denominator = totalSupply.mul(pmMultiplier.sqrt());
        }

        return numerator.div(denominator);
    }

    function _getSourcePrice(KTokenConfig memory config) internal view returns (uint){
        if (config.priceSource == PriceSource.CHAINLINK) {
            return _getChainlinkPrice(config);
        }
        if (config.priceSource == PriceSource.KAPTAIN) {
            return _getKaptainPrice(config);
        }

        revert("invalid config");
    }

    function _getChainlinkPrice(KTokenConfig memory config) internal view returns (uint){
        // Check aggregator address
        AggregatorV3Interface agg = aggregators[config.symbolHash];
        require(address(agg) != address(0), "aggregator address not found");
        (, int price, , ,) = agg.latestRoundData();
        return uint(price);
    }

    function _getKaptainPrice(KTokenConfig memory config) internal view returns (uint){
        return prices[config.symbolHash];
    }

    /// @notice Only Kaptain allowed to operate prices
    function postPrices(string[] calldata symbolArray, uint[] calldata priceArray) external onlyKaptain {
        require(symbolArray.length == priceArray.length, "length mismatch");
        // iterate and set
        for (uint i = 0; i < symbolArray.length; i++) {
            KTokenConfig memory config = getKConfigBySymbolHash(keccak256(abi.encodePacked(symbolArray[i])));
            require(config.priceSource == PriceSource.KAPTAIN, "can only post kaptain price");
            require(config.symbolHash != mcdHash, "cannot post mcd price here");
            require(priceArray[i] != 0, "price cannot be 0");
            prices[config.symbolHash] = priceArray[i];
        }
    }

    /// @notice Kaptain call to set the latest mcd price
    function postMcdPrice(uint mcdPrice) external onlyKaptain {
        require(mcdPrice != 0, "MCD price cannot be 0");
        mcdLastUpdatedAt = block.timestamp;
        prices[mcdHash] = mcdPrice;
        emit PriceUpdated("MCD", mcdPrice);
    }

    function changeKaptain(address kaptain_) external onlyOwner {
        require(kaptain != kaptain_, "same kaptain");
        address oldKaptain = kaptain;
        kaptain = kaptain_;
        emit KaptainUpdated(oldKaptain, kaptain);
    }

    function addConfig(address kToken_, address underlying_, bytes32 symbolHash_, uint baseUnit_, uint priceUnit_,
        PriceSource priceSource_) external onlyOwner {
        KTokenConfig memory config = KTokenConfig({
        kToken : kToken_,
        underlying : underlying_,
        symbolHash : symbolHash_,
        baseUnit : baseUnit_,
        priceUnit : priceUnit_,
        priceMantissa: baseUnit_.mul(priceUnit_),
        priceSource : priceSource_
        });

        _pushConfig(config);
    }

    function removeConfigByKToken(address kToken) external onlyOwner {
        KTokenConfig memory configToDelete = _deleteConfigByKToken(kToken);
        // remove all token related information
        delete prices[configToDelete.symbolHash];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./KineOracleV2.sol";

contract OracleHelper {
    function getPriceScale36(address oracle, string memory symbol) public view returns(uint, string memory, uint){
        KineOracleV2 oracleInstance = KineOracleV2(oracle);
        PriceConfig.KTokenConfig memory config = oracleInstance.getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
        uint price = oracleInstance.getUnderlyingPrice(config.kToken);
        return (oracleInstance.mcdLastUpdatedAt(), symbol, price * config.baseUnit);
    }

    function getConfigBySymbol(address oracle, string memory symbol) public view
    returns (address, address, uint, uint, PriceConfig.PriceSource){
        KineOracleV2 oracleInstance = KineOracleV2(oracle);
        PriceConfig.KTokenConfig memory config = oracleInstance.getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
        return  (config.kToken, config.underlying, config.baseUnit, config.priceUnit, config.priceSource);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./KineMath.sol";
import "./IERC20.sol";

contract PriceConfig is Ownable {
    using KineMath for uint;

    enum PriceSource {
        CHAINLINK, // Price from chainlink, priceUnit is aggregator decimals, baseUnit depends on underlying
        KAPTAIN,   // Price posted by kaptain
        LP         // LP baseUnit is 1e18, priceUnit is 1e18
    }

    struct KTokenConfig {
        address kToken;
        address underlying;
        bytes32 symbolHash;
        uint baseUnit;      // baseUnit: underlying decimal
        uint priceUnit;     // priceUnit: price decimal
        uint priceMantissa; // priceMantissa = priceUnit * baseUnit
        PriceSource priceSource;
    }

    // Chainlink aggregator map, bytes32 => AggregatorV3Interface
    mapping(bytes32 => AggregatorV3Interface) public aggregators;

    KTokenConfig[] public kTokenConfigs;

    /// @notice New chainlink aggregator
    event AggregatorUpdated(string symbol, address source);

    /// @notice Configuration added event
    event TokenConfigAdded(address kToken, address underlying, bytes32 symbolHash,
        uint baseUnit, uint priceUnit, uint PriceMantissa, PriceSource priceSource);

    /// @notice Configuration removed event
    event TokenConfigRemoved(address kToken, address underlying, bytes32 symbolHash,
        uint baseUnit, uint priceUnit, uint PriceMantissa, PriceSource priceSource);

    function _pushConfig(KTokenConfig memory config) internal {
        require(config.priceMantissa == config.baseUnit.mul(config.priceUnit), "invalid priceMantissa");

        // check baseUnit
        IERC20 underlying = IERC20(config.underlying);
        uint tokenDecimals = uint(underlying.decimals());
        require(10**tokenDecimals == config.baseUnit, "mismatched baseUnit");

        kTokenConfigs.push(config);
        emit TokenConfigAdded(config.kToken, config.underlying, config.symbolHash,
            config.baseUnit, config.priceUnit, config.priceMantissa, config.priceSource);
    }

    // must be called after you add chainlink sourced config
    function setAggregators(string[] calldata symbols, address[] calldata sources) public onlyOwner {
        require(symbols.length == sources.length, "mismatched input");
        for (uint i = 0; i < symbols.length; i++) {
            KTokenConfig memory config = getKConfigBySymbolHash(keccak256(abi.encodePacked(symbols[i])));
            AggregatorV3Interface agg = AggregatorV3Interface(sources[i]);
            aggregators[config.symbolHash] = agg;
            uint priceDecimals = uint(agg.decimals());
            require(10**priceDecimals == config.priceUnit, "mismatched priceUnit");
            emit AggregatorUpdated(symbols[i], sources[i]);
        }
    }

    function _deleteConfigByKToken(address kToken) internal returns(KTokenConfig memory){
        uint index = getKConfigIndexByKToken(kToken);
        KTokenConfig memory configToDelete = kTokenConfigs[index];
        kTokenConfigs[index] = kTokenConfigs[kTokenConfigs.length - 1];

        // If chainlink price source, remove its aggregator
        if (configToDelete.priceSource == PriceSource.CHAINLINK) {
            delete aggregators[configToDelete.symbolHash];
        }
        kTokenConfigs.pop();

        emit TokenConfigRemoved(configToDelete.kToken, configToDelete.underlying,
            configToDelete.symbolHash, configToDelete.baseUnit, configToDelete.priceUnit,
            configToDelete.priceMantissa, configToDelete.priceSource);

        return configToDelete;
    }

    function getKConfigIndexByKToken(address kToken) public view returns (uint){
        for (uint i = 0; i < kTokenConfigs.length; i++) {
            KTokenConfig memory config = kTokenConfigs[i];
            if (config.kToken == kToken) {
                return i;
            }
        }
        return uint(-1);
    }

    function getKConfigIndexByUnderlying(address underlying) public view returns (uint){
        for (uint i = 0; i < kTokenConfigs.length; i++) {
            KTokenConfig memory config = kTokenConfigs[i];
            if (config.underlying == underlying) {
                return i;
            }
        }
        return uint(-1);
    }

    function getKConfigIndexBySymbolHash(bytes32 symbolHash) public view returns (uint){
        for (uint i = 0; i < kTokenConfigs.length; i++) {
            KTokenConfig memory config = kTokenConfigs[i];
            if (config.symbolHash == symbolHash) {
                return i;
            }
        }
        return uint(-1);
    }

    // if not found should revert
    function getKConfigByKToken(address kToken) public view returns (KTokenConfig memory) {
        uint index = getKConfigIndexByKToken(kToken);
        if (index != uint(-1)) {
            return kTokenConfigs[index];
        }
        revert("token config not found");
    }

    function getKConfigBySymbolHash(bytes32 symbolHash) public view returns (KTokenConfig memory) {
        uint index = getKConfigIndexBySymbolHash(symbolHash);
        if (index != uint(-1)) {
            return kTokenConfigs[index];
        }
        revert("token config not found");
    }

    function getKConfigBySymbol(string memory symbol) external view returns (KTokenConfig memory) {
        return getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    function getKConfigByUnderlying(address underlying) public view returns (KTokenConfig memory) {
        uint index = getKConfigIndexByUnderlying(underlying);
        if (index != uint(-1)) {
            return kTokenConfigs[index];
        }
        revert("token config not found");
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}