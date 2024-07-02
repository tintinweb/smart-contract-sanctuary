/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-24
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



interface WePiggyPriceOracleInterface {

    function getPrice(address token) external view returns (uint);

    function setPrice(address token, uint price, bool force) external;

}


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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


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

interface PTokenInterface {
    function underlying() external view returns (address);

    function symbol() external view returns (string memory);
}

interface CompoundPriceOracleInterface {
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct CTokenConfig {
        address cToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isUniswapReversed;
    }

    function getUnderlyingPrice(address cToken) external view returns (uint);

    function getTokenConfigByUnderlying(address underlying) external view returns (CTokenConfig memory);

    function getTokenConfigBySymbol(string memory symbol) external view returns (CTokenConfig memory);
}

contract WePiggyPriceProviderV1 is Ownable {

    using SafeMath for uint256;

    enum PriceOracleType{
        ChainLink,
        Compound,
        Customer,
        ChainLinkEthBase
    }

    struct PriceOracle {
        address source;
        PriceOracleType sourceType;
        bool available;
    }

    //Config for pToken
    struct TokenConfig {
        address pToken;
        address underlying;
        string underlyingSymbol; //example: DAI
        uint256 baseUnit; //example: 1e18
        bool fixedUsd; //if true,will return 1*e36/baseUnit
    }


    mapping(address => TokenConfig) public tokenConfigs;
    mapping(address => PriceOracle[]) public oracles;
    mapping(address => address) public chainLinkTokenEthPriceFeed;

    address public ethUsdPriceFeedAddress;

    event ConfigUpdated(address pToken, address underlying, string underlyingSymbol, uint256 baseUnit, bool fixedUsd);
    event PriceOracleUpdated(address pToken, PriceOracle[] oracles);


    constructor() public {
    }


    function getUnderlyingPrice(address _pToken) external view returns (uint){

        uint256 price = 0;
        TokenConfig storage tokenConfig = tokenConfigs[_pToken];
        if (tokenConfig.fixedUsd) {//if true,will return 1*e36/baseUnit
            price = 1;
            return price.mul(1e36).div(tokenConfig.baseUnit);
        }

        PriceOracle[] storage priceOracles = oracles[_pToken];
        for (uint256 i = 0; i < priceOracles.length; i++) {
            PriceOracle storage priceOracle = priceOracles[i];
            if (priceOracle.available == true) {// check the priceOracle is available
                price = _getUnderlyingPriceInternal(_pToken, tokenConfig, priceOracle);
                if (price > 0) {
                    return price;
                }
            }
        }

        // price must bigger than 0
        require(price > 0, "price must bigger than zero");

        return 0;
    }

    function _getUnderlyingPriceInternal(address _pToken, TokenConfig memory tokenConfig, PriceOracle memory priceOracle) internal view returns (uint){

        address underlying = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        PTokenInterface pToken = PTokenInterface(_pToken);

        if (!compareStrings(pToken.symbol(), "pGLMR")) {
            underlying = address(PTokenInterface(_pToken).underlying());
        }

        PriceOracleType sourceType = priceOracle.sourceType;
        if (sourceType == PriceOracleType.ChainLink) {
            return _getChainlinkPriceInternal(priceOracle, tokenConfig);
        } else if (sourceType == PriceOracleType.Compound) {
            return _getCompoundPriceInternal(priceOracle, tokenConfig);
        } else if (sourceType == PriceOracleType.Customer) {
            return _getCustomerPriceInternal(priceOracle, tokenConfig);
        } else if (sourceType == PriceOracleType.ChainLinkEthBase) {
            return _getChainLinkEthBasePriceInternal(priceOracle, tokenConfig);
        }

        return 0;
    }


    function _getCustomerPriceInternal(PriceOracle memory priceOracle, TokenConfig memory tokenConfig) internal view returns (uint) {
        address source = priceOracle.source;
        WePiggyPriceOracleInterface customerPriceOracle = WePiggyPriceOracleInterface(source);
        uint price = customerPriceOracle.getPrice(tokenConfig.underlying);
        if (price <= 0) {
            return 0;
        } else {//return: (price / 1e8) * (1e36 / baseUnit) ==> price * 1e28 / baseUnit
            return uint(price).mul(1e28).div(tokenConfig.baseUnit);
        }
    }

    // Get price from compound oracle
    function _getCompoundPriceInternal(PriceOracle memory priceOracle, TokenConfig memory tokenConfig) internal view returns (uint) {
        address source = priceOracle.source;
        CompoundPriceOracleInterface compoundPriceOracle = CompoundPriceOracleInterface(source);
        CompoundPriceOracleInterface.CTokenConfig memory ctc = compoundPriceOracle.getTokenConfigBySymbol(tokenConfig.underlyingSymbol);
        address cTokenAddress = ctc.cToken;
        return compoundPriceOracle.getUnderlyingPrice(cTokenAddress);
    }


    // Get price from chainlink oracle
    function _getChainlinkPriceInternal(PriceOracle memory priceOracle, TokenConfig memory tokenConfig) internal view returns (uint){

        require(tokenConfig.baseUnit > 0, "baseUnit must be greater than zero");

        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceOracle.source);
        (,int price,,,) = priceFeed.latestRoundData();

        if (price <= 0) {
            return 0;
        } else {//return: (price / 1e8) * (1e36 / baseUnit) ==> price * 1e28 / baseUnit
            return uint(price).mul(1e28).div(tokenConfig.baseUnit);
        }

    }

    // base chainlink: token-ETH-USD
    function _getChainLinkEthBasePriceInternal(PriceOracle memory priceOracle, TokenConfig memory tokenConfig) internal view returns (uint){
        require(tokenConfig.baseUnit > 0, "baseUnit must be greater than zero");

        address token = tokenConfig.underlying;
        AggregatorV3Interface tokenEthPriceFeed = AggregatorV3Interface(chainLinkTokenEthPriceFeed[token]);
        (,int tokenEthPrice,,,) = tokenEthPriceFeed.latestRoundData();

        AggregatorV3Interface ethUsdPriceFeed = AggregatorV3Interface(ethUsdPriceFeedAddress);
        (,int ethUsdPrice,,,) = ethUsdPriceFeed.latestRoundData();

        if (tokenEthPrice <= 0) {
            return 0;
        } else {// tokenEthPrice/1e18 * ethUsdPrice/1e8 * 1e36 / baseUnit
            return uint(tokenEthPrice).mul(uint(ethUsdPrice)).mul(1e10).div(tokenConfig.baseUnit);
        }
    }

    function addTokenConfig(address pToken, address underlying, string memory underlyingSymbol, uint256 baseUnit, bool fixedUsd,
        address[] memory sources, PriceOracleType[] calldata sourceTypes) public onlyOwner {

        require(sources.length == sourceTypes.length, "sourceTypes.length must equal than sources.length");

        // add TokenConfig
        TokenConfig storage tokenConfig = tokenConfigs[pToken];
        require(tokenConfig.pToken == address(0), "bad params");
        tokenConfig.pToken = pToken;
        tokenConfig.underlying = underlying;
        tokenConfig.underlyingSymbol = underlyingSymbol;
        tokenConfig.baseUnit = baseUnit;
        tokenConfig.fixedUsd = fixedUsd;

        // add priceOracles
        require(oracles[pToken].length < 1, "bad params");
        for (uint i = 0; i < sources.length; i++) {
            PriceOracle[] storage list = oracles[pToken];
            list.push(PriceOracle({
            source : sources[i],
            sourceType : sourceTypes[i],
            available : true
            }));
        }

        emit ConfigUpdated(pToken, underlying, underlyingSymbol, baseUnit, fixedUsd);
        emit PriceOracleUpdated(pToken, oracles[pToken]);

    }

    function addOrUpdateTokenConfigSource(address pToken, uint256 index, address source, PriceOracleType _sourceType, bool available) public onlyOwner {

        PriceOracle[] storage list = oracles[pToken];

        if (list.length > index) {//will update
            PriceOracle storage oracle = list[index];
            oracle.source = source;
            oracle.sourceType = _sourceType;
            oracle.available = available;
        } else {//will add
            list.push(PriceOracle({
            source : source,
            sourceType : _sourceType,
            available : available
            }));
        }

    }

    function updateTokenConfigBaseUnit(address pToken, uint256 baseUnit) public onlyOwner {
        TokenConfig storage tokenConfig = tokenConfigs[pToken];
        require(tokenConfig.pToken != address(0), "bad params");
        tokenConfig.baseUnit = baseUnit;

        emit ConfigUpdated(pToken, tokenConfig.underlying, tokenConfig.underlyingSymbol, baseUnit, tokenConfig.fixedUsd);
    }

    function updateTokenConfigFixedUsd(address pToken, bool fixedUsd) public onlyOwner {
        TokenConfig storage tokenConfig = tokenConfigs[pToken];
        require(tokenConfig.pToken != address(0), "bad params");
        tokenConfig.fixedUsd = fixedUsd;

        emit ConfigUpdated(pToken, tokenConfig.underlying, tokenConfig.underlyingSymbol, tokenConfig.baseUnit, fixedUsd);
    }

    function setEthUsdPriceFeedAddress(address feedAddress) public onlyOwner {
        ethUsdPriceFeedAddress = feedAddress;
    }

    function addOrUpdateChainLinkTokenEthPriceFeed(address[] memory tokens, address[] memory chainLinkTokenEthPriceFeeds) public onlyOwner {

        require(tokens.length == chainLinkTokenEthPriceFeeds.length, "tokens.length must equal than chainLinkTokenEthPriceFeeds.length");

        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            chainLinkTokenEthPriceFeed[token] = chainLinkTokenEthPriceFeeds[i];
        }

    }


    function getOracleSourcePrice(address pToken, uint sourceIndex) public view returns (uint){

        TokenConfig storage tokenConfig = tokenConfigs[pToken];
        PriceOracle[] storage priceOracles = oracles[pToken];

        return _getUnderlyingPriceInternal(pToken, tokenConfig, priceOracles[sourceIndex]);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function oracleLength(address pToken) public view returns (uint){
        PriceOracle[] storage priceOracles = oracles[pToken];
        return priceOracles.length;
    }

}