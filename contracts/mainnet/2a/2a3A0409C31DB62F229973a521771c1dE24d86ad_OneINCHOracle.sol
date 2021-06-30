// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../../oracle/OracleCommon.sol";
import "../../interface/IERC20Extended.sol";
import "../../_chainlink/interfaces/AggregatorV3Interface.sol";
import "../../_openzeppelin/math/SafeMath.sol";

/**
 @notice 1INCH/USD ChainLink Oracle  
 */

contract OneINCHOracle is OracleCommon {

    using SafeMath for uint256;

    uint private constant SHIFT_DECIMALS = 10 ** 10;
    AggregatorV3Interface internal priceFeed;


    /** 
     @param oneTokenFactory_ oneToken factory to bind to
     @param description_ description has no bearing on logic
     @param indexToken_ token to use for price quotes
     */
    constructor(address oneTokenFactory_, string memory description_, address indexToken_, address chainlink_)
        OracleCommon(oneTokenFactory_, description_, indexToken_) {
        priceFeed = AggregatorV3Interface(chainlink_);
    }

    /**
     @notice update is called when a oneToken wants to persist observations
     @dev there is nothing to do in this case
     */
    function update(address /* token */) external override {}

    /**
     @notice returns equivalent amount of index tokens for an amount of baseTokens and volatility metric
     // param address unused token address
     @param amountTokens quantity, token native precision
     @param amountUsd US dollar equivalentm, precision 18
     @param volatility metric for future use-cases
     */
    function read(address /* token */, uint256 amountTokens) public view override returns(uint256 amountUsd, uint256 volatility) {
        amountUsd = (amountTokens.mul(getThePrice())).div(PRECISION);
        volatility = 1;
    }

    /**
     @notice returns the tokens needed to reach a target usd value
     // param address unused token address
     @param amountUsd Usd required, precision 18
     @param amountTokens tokens required, token native precision
     @param volatility metric for future use-cases
     */
    function amountRequired(address /* token */, uint256 amountUsd) external view override returns(uint256 amountTokens, uint256 volatility) {
        amountTokens = amountUsd.mul(PRECISION).div(getThePrice());
        volatility = 1;
    }

    /**
     * Returns the latest price
     */
    function getThePrice() public view returns (uint256 price) {
        (
            , 
            int256 price_,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        require(price_ > 0); // price oracle responded 0, or negative. No event emitted because this is a view function.
        price = uint256(price_);
        price = price.mul(SHIFT_DECIMALS);  //price is natively in 8 decimals make it 18
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interface/IOracle.sol";
import "../common/ICHIModuleCommon.sol";

abstract contract OracleCommon is IOracle, ICHIModuleCommon {

    uint256 constant NORMAL = 18;
    bytes32 constant public override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 Oracle Implementation"));
    address public override indexToken;

    event OracleDeployed(address sender, string description, address indexToken);
    event OracleInitialized(address sender, address baseToken, address indexToken);
    
    /**
     @notice records the oracle description and the index that will be used for all quotes
     @dev oneToken implementations can share oracles
     @param oneTokenFactory_ oneTokenFactory to bind to
     @param description_ all modules have a description. No processing or validation
     @param indexToken_ every oracle has an index token for reporting the value of a base token
     */
    constructor(address oneTokenFactory_, string memory description_, address indexToken_) 
        ICHIModuleCommon(oneTokenFactory_, ModuleType.Oracle, description_) 
    { 
        require(indexToken_ != NULL_ADDRESS, "OracleCommon: indexToken cannot be empty");
        indexToken = indexToken_;
        emit OracleDeployed(msg.sender, description_, indexToken_);
    }

    /**
     @notice oneTokens can share Oracles. Oracles must be re-initializable. They are initialized from the Factory.
     @param baseToken oracles _can be_ multi-tenant with separately initialized baseTokens
     */
    function init(address baseToken) external onlyModuleOrFactory virtual override {
        emit OracleInitialized(msg.sender, baseToken, indexToken);
    }

    /**
     @notice converts normalized precision 18 amounts to token native precision amounts, truncates low-order values
     @param token ERC20 token contract
     @param amountNormal quantity in precision-18
     @param amountTokens quantity scaled to token decimals()
     */    
    function normalizedToTokens(address token, uint256 amountNormal) public view override returns(uint256 amountTokens) {
        IERC20Extended t = IERC20Extended(token);
        uint256 nativeDecimals = t.decimals();
        require(nativeDecimals <= 18, "OracleCommon: unsupported token precision (greater than 18)");
        if(nativeDecimals == NORMAL) return amountNormal;
        return amountNormal / ( 10 ** (NORMAL - nativeDecimals));
    }

    /**
     @notice converts token native precision amounts to normalized precision 18 amounts
     @param token ERC20 token contract
     @param amountTokens quantity scaled to token decimals
     @param amountNormal quantity in precision-18
     */  
    function tokensToNormalized(address token, uint256 amountTokens) public view override returns(uint256 amountNormal) {
        IERC20Extended t = IERC20Extended(token);
        uint256 nativeDecimals = t.decimals();
        require(nativeDecimals <= 18, "OracleCommon: unsupported token precision (greater than 18)");
        if(nativeDecimals == NORMAL) return amountTokens;
        return amountTokens * ( 10 ** (NORMAL - nativeDecimals));
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../_openzeppelin/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    
    function decimals() external view returns(uint8);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IModule.sol";

interface IOracle is IModule {

    function init(address baseToken) external;
    function update(address token) external;
    function indexToken() external view returns(address);

    /**
     @param token ERC20 token
     @param amountTokens quantity, token native precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases
     */
    function read(address token, uint amountTokens) external view returns(uint amountUsd, uint volatility);

    /**
     @param token ERC20 token
     @param amountTokens token quantity, token native precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases
     */    
    function amountRequired(address token, uint amountUsd) external view returns(uint amountTokens, uint volatility);

    /**
     @notice converts normalized precision-18 amounts to token native precision amounts, truncates low-order values
     @param token ERC20 token contract
     @param amountNormal quantity, precision 18
     @param amountTokens quantity scaled to token precision
     */    
    function normalizedToTokens(address token, uint amountNormal) external view returns(uint amountTokens);

    /**
     @notice converts token native precision amounts to normalized precision-18 amounts
     @param token ERC20 token contract
     @param amountNormal quantity, precision 18
     @param amountTokens quantity scaled to token precision
     */  
    function tokensToNormalized(address token, uint amountTokens) external view returns(uint amountNormal);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interface/IModule.sol";
import "../interface/IOneTokenFactory.sol";
import "../interface/IOneTokenV1Base.sol";
import "./ICHICommon.sol";

abstract contract ICHIModuleCommon is IModule, ICHICommon {
    
    ModuleType public immutable override moduleType;
    string public override moduleDescription;
    address public immutable override oneTokenFactory;

    event ModuleDeployed(address sender, ModuleType moduleType, string description);
    event DescriptionUpdated(address sender, string description);
   
    modifier onlyKnownToken {
        require(IOneTokenFactory(oneTokenFactory).isOneToken(msg.sender), "ICHIModuleCommon: msg.sender is not a known oneToken");
        _;
    }
    
    modifier onlyTokenOwner (address oneToken) {
        require(msg.sender == IOneTokenV1Base(oneToken).owner(), "ICHIModuleCommon: msg.sender is not oneToken owner");
        _;
    }

    modifier onlyModuleOrFactory {
        if(!IOneTokenFactory(oneTokenFactory).isModule(msg.sender)) {
            require(msg.sender == oneTokenFactory, "ICHIModuleCommon: msg.sender is not module owner, token factory or registed module");
        }
        _;
    }
    
    /**
     @notice modules are bound to the factory at deployment time
     @param oneTokenFactory_ factory to bind to
     @param moduleType_ type number helps prevent governance errors
     @param description_ human-readable, descriptive only
     */    
    constructor (address oneTokenFactory_, ModuleType moduleType_, string memory description_) {
        require(oneTokenFactory_ != NULL_ADDRESS, "ICHIModuleCommon: oneTokenFactory cannot be empty");
        require(bytes(description_).length > 0, "ICHIModuleCommon: description cannot be empty");
        oneTokenFactory = oneTokenFactory_;
        moduleType = moduleType_;
        moduleDescription = description_;
        emit ModuleDeployed(msg.sender, moduleType_, description_);
    }

    /**
     @notice set a module description
     @param description new module desciption
     */
    function updateDescription(string memory description) external onlyOwner override {
        require(bytes(description).length > 0, "ICHIModuleCommon: description cannot be empty");
        moduleDescription = description;
        emit DescriptionUpdated(msg.sender, description);
    }  
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IICHICommon.sol";
import "./InterfaceCommon.sol";

interface IModule is IICHICommon { 
       
    function oneTokenFactory() external view returns(address);
    function updateDescription(string memory description) external;
    function moduleDescription() external view returns(string memory);
    function MODULE_TYPE() external view returns(bytes32);
    function moduleType() external view returns(ModuleType);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IICHIOwnable.sol";
import "./InterfaceCommon.sol";

interface IICHICommon is IICHIOwnable, InterfaceCommon {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

interface InterfaceCommon {

    enum ModuleType { Version, Controller, Strategy, MintMaster, Oracle }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IICHIOwnable {
    
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./InterfaceCommon.sol";

interface IOneTokenFactory is InterfaceCommon {

    function oneTokenProxyAdmins(address) external returns(address);
    function deployOneTokenProxy(
        string memory name,
        string memory symbol,
        address governance, 
        address version,
        address controller,
        address mintMaster,              
        address memberToken, 
        address collateral,
        address oneTokenOracle
    ) 
        external 
        returns(address newOneTokenProxy, address proxyAdmin);

    function admitModule(address module, ModuleType moduleType, string memory name, string memory url) external;
    function updateModule(address module, string memory name, string memory url) external;
    function removeModule(address module) external;

    function admitForeignToken(address foreignToken, bool collateral, address oracle) external;
    function updateForeignToken(address foreignToken, bool collateral) external;
    function removeForeignToken(address foreignToken) external;

    function assignOracle(address foreignToken, address oracle) external;
    function removeOracle(address foreignToken, address oracle) external; 

    /**
     * View functions
     */
    
    function MODULE_TYPE() external view returns(bytes32);

    function oneTokenCount() external view returns(uint256);
    function oneTokenAtIndex(uint256 index) external view returns(address);
    function isOneToken(address oneToken) external view returns(bool);
 
    // modules

    function moduleCount() external view returns(uint256);
    function moduleAtIndex(uint256 index) external view returns(address module);
    function isModule(address module) external view returns(bool);
    function isValidModuleType(address module, ModuleType moduleType) external view returns(bool);

    // foreign tokens

    function foreignTokenCount() external view returns(uint256);
    function foreignTokenAtIndex(uint256 index) external view returns(address);
    function foreignTokenInfo(address foreignToken) external view returns(bool collateral, uint256 oracleCount);
    function foreignTokenOracleCount(address foreignToken) external view returns(uint256);
    function foreignTokenOracleAtIndex(address foreignToken, uint256 index) external view returns(address);
    function isOracle(address foreignToken, address oracle) external view returns(bool);
    function isForeignToken(address foreignToken) external view returns(bool);
    function isCollateral(address foreignToken) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IICHICommon.sol";
import "./IERC20Extended.sol";

interface IOneTokenV1Base is IICHICommon, IERC20 {
    
    function init(string memory name_, string memory symbol_, address oneTokenOracle_, address controller_,  address mintMaster_, address memberToken_, address collateral_) external;
    function changeController(address controller_) external;
    function changeMintMaster(address mintMaster_, address oneTokenOracle) external;
    function addAsset(address token, address oracle) external;
    function removeAsset(address token) external;
    function setStrategy(address token, address strategy, uint256 allowance) external;
    function executeStrategy(address token) external;
    function removeStrategy(address token) external;
    function closeStrategy(address token) external;
    function increaseStrategyAllowance(address token, uint256 amount) external;
    function decreaseStrategyAllowance(address token, uint256 amount) external;
    function setFactory(address newFactory) external;

    function MODULE_TYPE() external view returns(bytes32);
    function oneTokenFactory() external view returns(address);
    function controller() external view returns(address);
    function mintMaster() external view returns(address);
    function memberToken() external view returns(address);
    function assets(address) external view returns(address, address);
    function balances(address token) external view returns(uint256 inVault, uint256 inStrategy);
    function collateralTokenCount() external view returns(uint256);
    function collateralTokenAtIndex(uint256 index) external view returns(address);
    function isCollateral(address token) external view returns(bool);
    function otherTokenCount() external view  returns(uint256);
    function otherTokenAtIndex(uint256 index) external view returns(address); 
    function isOtherToken(address token) external view returns(bool);
    function assetCount() external view returns(uint256);
    function assetAtIndex(uint256 index) external view returns(address); 
    function isAsset(address token) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIOwnable.sol";
import "../oz_modified/ICHIInitializable.sol";
import "../interface/IERC20Extended.sol";
import "../interface/IICHICommon.sol";

contract ICHICommon is IICHICommon, ICHIOwnable, ICHIInitializable {

    uint256 constant PRECISION = 10 ** 18;
    uint256 constant INFINITE = uint256(0-1);
    address constant NULL_ADDRESS = address(0);
    
    // @dev internal fingerprints help prevent deployment-time governance errors

    bytes32 constant COMPONENT_CONTROLLER = keccak256(abi.encodePacked("ICHI V1 Controller"));
    bytes32 constant COMPONENT_VERSION = keccak256(abi.encodePacked("ICHI V1 OneToken Implementation"));
    bytes32 constant COMPONENT_STRATEGY = keccak256(abi.encodePacked("ICHI V1 Strategy Implementation"));
    bytes32 constant COMPONENT_MINTMASTER = keccak256(abi.encodePacked("ICHI V1 MintMaster Implementation"));
    bytes32 constant COMPONENT_ORACLE = keccak256(abi.encodePacked("ICHI V1 Oracle Implementation"));
    bytes32 constant COMPONENT_VOTERROLL = keccak256(abi.encodePacked("ICHI V1 VoterRoll Implementation"));
    bytes32 constant COMPONENT_FACTORY = keccak256(abi.encodePacked("ICHI OneToken Factory"));
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

/**
 * @dev Constructor visibility has been removed from the original.
 * _transferOwnership() has been added to support proxied deployments.
 * Abstract tag removed from contract block.
 * Added interface inheritance and override modifiers.
 * Changed contract identifier in require error messages.
 */

pragma solidity >=0.6.0 <0.8.0;

import "../_openzeppelin/utils/Context.sol";
import "../interface/IICHIOwnable.sol";
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
contract ICHIOwnable is IICHIOwnable, Context {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
     
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ICHIOwnable: caller is not the owner");
        _;
    }    

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * Ineffective for proxied deployed. Use initOwnable.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     @dev initialize proxied deployment
     */
    function initOwnable() internal {
        require(owner() == address(0), "ICHIOwnable: already initialized");
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev be sure to call this in the initialization stage of proxied deployment or owner will not be set
     */

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "ICHIOwnable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../_openzeppelin/utils/Address.sol";

contract ICHIInitializable {

    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "ICHIInitializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    modifier initialized {
        require(_initialized, "ICHIInitializable: contract is not initialized");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

/// @dev removed constructor visibility and relocated the file
/// @dev added initERC20 for proxied deployments

pragma solidity >=0.6.0 <0.8.0;

import "../_openzeppelin/utils/Context.sol";
import "../_openzeppelin/token/ERC20/IERC20.sol";
import "../_openzeppelin/math/SafeMath.sol";
import "./ICHIInitializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ICHIERC20 is IERC20, Context, ICHIInitializable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    /**
     * @dev this constructor is ineffective in proxy deployment. Use init().
     */

    /*
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    */

    function initERC20(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ICHIERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ICHIERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ICHIERC20: transfer from the zero address");
        require(recipient != address(0), "ICHIERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ICHIERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ICHIERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ICHIERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ICHIERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ICHIERC20: approve from the zero address");
        require(spender != address(0), "ICHIERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address /* from */, address /* to */, uint256 /* amount */) internal virtual { }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIERC20.sol";

contract Token9 is ICHIERC20 {

    constructor() {
        initERC20("Token with 9 decimals", "Token9");
        _mint(msg.sender, 10000 * 10 ** 9);
        _setupDecimals(9);
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIERC20.sol";

contract Token6 is ICHIERC20 {

    constructor() {
        initERC20("Token with 6 decimals", "Token6");
        _mint(msg.sender, 10000 * 10 ** 6);
        _setupDecimals(6);
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIERC20.sol";

contract Token18 is ICHIERC20 {

    constructor() {
        initERC20("Token with 18 decimals", "Token18");
        _mint(msg.sender, 10000 * 10 ** 18);
        _setupDecimals(18);
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIERC20.sol";

contract MemberToken is ICHIERC20 {

    constructor() {
        initERC20("Member Token", "MTTest");
        _mint(msg.sender, 100000 * 10 ** 18);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oz_modified/ICHIERC20.sol";

contract CollateralToken is ICHIERC20 {

    constructor() {
        initERC20("Collateral Token", "CTTest");
        _mint(msg.sender, 100000 * 10 ** 18);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../_openzeppelin/utils/Context.sol";
import "./ICHIERC20.sol";

/**
 * @dev Uses the modified ERC20 with Initializer.
 */
contract ICHIERC20Burnable is ICHIERC20 {
    
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ICHIERC20Burnable: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../common/ICHICommon.sol";
import "../../_openzeppelin/token/ERC20/SafeERC20.sol";
import "../../oz_modified/ICHIERC20Burnable.sol";
import "../../lib/AddressSet.sol";
import "../../interface/IOneTokenFactory.sol";
import "../../interface/IOneTokenV1Base.sol";
import "../../interface/IController.sol";
import "../../interface/IStrategy.sol";
import "../../interface/IMintMaster.sol";
import "../../interface/IOracle.sol";

contract OneTokenV1Base is IOneTokenV1Base, ICHICommon, ICHIERC20Burnable {

    using SafeERC20 for IERC20;
    using AddressSet for AddressSet.Set;

    bytes32 public constant override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 OneToken Implementation"));

    address public override oneTokenFactory;
    address public override controller;
    address public override mintMaster;
    address public override memberToken;
    AddressSet.Set collateralTokenSet;
    AddressSet.Set otherTokenSet;

    struct Asset {
        address oracle;
        address strategy;
    }

    AddressSet.Set assetSet;
    mapping(address => Asset) public override assets;

    event Initialized(address sender, string name, string symbol, address controller, address mintMaster, address memberToken, address collateral);
    event ControllerChanged(address sender, address controller);
    event MintMasterChanged(address sender, address mintMaster, address oneTokenOracle);
    event StrategySet(address sender, address token, address strategy, uint256 allowance);
    event StrategyExecuted(address indexed sender, address indexed token, address indexed strategy);
    event StrategyRemoved(address sender, address token, address strategy);
    event StrategyClosed(address sender, address token, address strategy);
    event ToStrategy(address sender, address strategy, address token, uint256 amount);
    event FromStrategy(address sender, address strategy, address token, uint256 amount);
    event StrategyAllowanceIncreased(address sender, address token, address strategy, uint256 amount);
    event StrategyAllowanceDecreased(address sender, address token, address strategy, uint256 amount);
    event AssetAdded(address sender, address token, address oracle);
    event AssetRemoved(address sender, address token);
    event NewFactory(address sender, address factory);

    modifier onlyOwnerOrController {
        if(msg.sender != owner()) {
            require(msg.sender == controller, "OTV1B: not owner or controller");
        }
        _;
    }

    /**
     @notice initializes a proxied instance of the implementation
     @dev constructors are ineffective for proxy deployments
     @param name_ ERC20 name value
     @param symbol_ ERC20 symbol value
     @param oneTokenOracle_ a deployed, compatible oracle supporting the minimum interface
     @param controller_ a deployed, compatible controller supporting the minimum interface
     @param mintMaster_ a deployed, compatible mintMaster supporting the minimum interface
     @param memberToken_ a deployed, registered (in the factory) ERC20 token supporting the minimum interface
     @param collateral_ a deployed, registered (in the factory) usd-pegged ERC20 token supporting the minimum interface
     */
    function init(
        string memory name_,
        string memory symbol_,
        address oneTokenOracle_,
        address controller_,
        address mintMaster_,
        address memberToken_,
        address collateral_
    )
        external
        initializer
        override
    {
        // transfer oneToken governance to the deployer
        initOwnable();

        oneTokenFactory = msg.sender;
        initERC20(name_, symbol_); // decimals is always 18

        // no null properties
        require(bytes(name_).length > 0 && bytes(symbol_).length > 0, "OTV1B: name and symbol are RQD");

        // Confirm the modules are known and valid
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(oneTokenOracle_, ModuleType.Oracle), "OTV1B: unknown oracle");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(controller_, ModuleType.Controller), "OTV1B: unknown controller");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(mintMaster_, ModuleType.MintMaster), "OTV1B: unknown mint master");
        require(IOneTokenFactory(oneTokenFactory).isForeignToken(memberToken_), "OTV1B: unknown MEM token");
        require(IOneTokenFactory(oneTokenFactory).isCollateral(collateral_), "OTV1B: unknown collateral");

        // register the modules
        controller = controller_;
        mintMaster = mintMaster_;

        // register the member token
        memberToken = memberToken_;

        // register the first acceptable collateral and note the existance of the member token
        collateralTokenSet.insert(collateral_, "OTV1B: ERR inserting collateral");
        otherTokenSet.insert(memberToken_, "OTV1B: ERR inserting MEM token");
        assetSet.insert(collateral_, "OTV1B: ERR inserting collateral as asset");
        assetSet.insert(memberToken_, "OTV1B: ERR inserting MEM token as asset");

        // instantiate the memberToken and collateralToken records
        Asset storage mt = assets[memberToken_];
        Asset storage ct = assets[collateral_];

        // default to the first known oracles for the memberToken and collateralToken
        // change default oracle with remove/add asset

        mt.oracle = IOneTokenFactory(oneTokenFactory).foreignTokenOracleAtIndex(memberToken_, 0);
        ct.oracle = IOneTokenFactory(oneTokenFactory).foreignTokenOracleAtIndex(collateral_, 0);

        // let the modules initialize the context if they need to
        IController(controller_).init();
        IMintMaster(mintMaster_).init(oneTokenOracle_);
       
        // force the oracles to make observations
        IOracle(oneTokenOracle_).update(address(this));
        IOracle(mt.oracle).update(memberToken);
        IOracle(ct.oracle).update(collateral_);

        emit Initialized(msg.sender, name_, symbol_, controller_, mintMaster_, memberToken_, collateral_);
    }

    /**
     @notice governance can appoint a new controller with distinct internal logic
     @dev controllers support the periodic() function which should be called occasionally to send gas to the controller
     @param controller_ a deployed controller contract supporting the minimum interface and registered with the factory
     */
    function changeController(address controller_) external onlyOwner override {
        require(IOneTokenFactory(oneTokenFactory).isModule(controller_), "OTV1B: unregistered controller");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(controller_, ModuleType.Controller), "OTV1B: unknown controller");
        IController(controller_).init();
        controller = controller_;
        emit ControllerChanged(msg.sender, controller_);
    }

    /**
     @notice change the mintMaster
     @dev controllers support the periodic() function which should be called occasionally to send gas to the controller
     @param mintMaster_ the new mintMaster implementation
     @param oneTokenOracle_ intialize the mintMaster with this oracle. Must be registed in the factory.
     */
    function changeMintMaster(address mintMaster_, address oneTokenOracle_) external onlyOwner override {
        require(IOneTokenFactory(oneTokenFactory).isModule(mintMaster_), "OTV1B: unregistered mint master");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(mintMaster_, ModuleType.MintMaster), "OTV1B: unknown mint master");
        require(IOneTokenFactory(oneTokenFactory).isOracle(address(this), oneTokenOracle_), "OTV1B: unregistered oneToken oracle");
        IOracle(oneTokenOracle_).update(address(this));
        IMintMaster(mintMaster_).init(oneTokenOracle_);
        mintMaster = mintMaster_;
        emit MintMasterChanged(msg.sender, mintMaster_, oneTokenOracle_);
    }

    /**
     @notice governance can add an asset
     @dev asset inventory helps evaluate local holdings and enables strategy assignment
     @param token ERC20 token
     @param oracle oracle to use for usd valuation. Must be registered in the factory and associated with token.
     */
    function addAsset(address token, address oracle) external onlyOwner override {
        require(IOneTokenFactory(oneTokenFactory).isOracle(token, oracle), "OTV1B: unknown oracle or token");
        (bool isCollateral_, /* uint256 oracleCount */) = IOneTokenFactory(oneTokenFactory).foreignTokenInfo(token);
        Asset storage a = assets[token];
        a.oracle = oracle;
        IOracle(oracle).update(token);
        if(isCollateral_) {
            collateralTokenSet.insert(token, "OTV1B: collateral already exists");
        } else {
            otherTokenSet.insert(token, "OTV1B: token already exists");
        }
        assetSet.insert(token, "OTV1B: ERR inserting asset");
        emit AssetAdded(msg.sender, token, oracle);
    }

    /**
     @notice governance can remove an asset from treasury and collateral value accounting
     @dev does not destroy holdings, but holdings are not accounted for
     @param token ERC20 token
     */
    function removeAsset(address token) external onlyOwner override {
        (uint256 inVault, uint256 inStrategy) = balances(token);
        require(inVault == 0, "OTV1B: can't remove token with vault balance > 0");
        require(inStrategy == 0, "OTV1B: can't remove asset with strategy balance > 0");
        require(assetSet.exists(token), "OTV1B: unknown token");
        if(collateralTokenSet.exists(token)) collateralTokenSet.remove(token, "OTV1B: ERR removing collateral token");
        if(otherTokenSet.exists(token)) otherTokenSet.remove(token, "OTV1B: ERR removing MEM token");
        assetSet.remove(token, "OTV1B: ERR removing asset");
        delete assets[token];
        emit AssetRemoved(msg.sender, token);
    }

    /**
     @notice governance optionally assigns a strategy to an asset and sets a strategy allowance
     @dev strategy must be registered with the factory
     @param token ERC20 asset
     @param strategy deployed strategy contract that is registered with the factor
     @param allowance ERC20 allowance sets a limit on funds to transfer to the strategy
     */
    function setStrategy(address token, address strategy, uint256 allowance) external onlyOwner override {

        require(assetSet.exists(token), "OTV1B: unknown token");
        require(IOneTokenFactory(oneTokenFactory).isModule(strategy), "OTV1B: unknown strategy");
        require(IOneTokenFactory(oneTokenFactory).isValidModuleType(strategy, ModuleType.Strategy), "OTV1B: unknown strategy");
        require(IStrategy(strategy).oneToken() == address(this), "OTV1B: can't assign strategy that doesn't recognize this vault");
        require(IStrategy(strategy).owner() == owner(), "OTV1B: unknown strategy owner");

        // close the old strategy, may not be possible to recover all funds, e.g. locked tokens
        // the old strategy continues to respect oneToken goverancea and controller for manual token recovery

        Asset storage a = assets[token];
        closeStrategy(token);

        // initialize the new strategy
        IStrategy(strategy).init();
        IERC20(token).safeApprove(strategy, allowance);

        // appoint the new strategy
        a.strategy = strategy;
        emit StrategySet(msg.sender, token, strategy, allowance);
    }

    /**
     @notice governance can remove a strategy
     @dev closes the strategy and requires that all funds in the strategy are returned to the vault
     @param token the token strategy to remove. There are 0-1 strategys per asset
     */
    function removeStrategy(address token) external onlyOwner override {
        Asset storage a = assets[token];
        closeStrategy(token);
        address strategy = a.strategy;
        a.strategy = NULL_ADDRESS;
        emit StrategyRemoved(msg.sender, token, strategy);
    }

    /**
     @notice governance can close a strategy
     @dev strategy remains assigned the asset with allowance set to 0.
     @param token ERC20 asset with a strategy to close. 
     */
    function closeStrategy(address token) public override onlyOwnerOrController {
        require(assetSet.exists(token), "OTV1B:cs: unknown token");
        Asset storage a = assets[token];
        address oldStrategy = a.strategy;
        if(oldStrategy != NULL_ADDRESS) IERC20(token).safeApprove(oldStrategy, 0);
        emit StrategyClosed(msg.sender, token, oldStrategy);
    }

    /**
     @notice governance can execute a strategy to trigger innner logic within the strategy
     @dev normally used by the controller
     @param token the token strategy to execute
     */
    function executeStrategy(address token) external onlyOwnerOrController override {
        require(assetSet.exists(token), "OTV1B:es: unknown token");
        Asset storage a = assets[token];
        address strategy = a.strategy;
        IStrategy(strategy).execute();
        emit StrategyExecuted(msg.sender, token, strategy);
    }

    /**
     @notice governance can transfer assets from the vault to a strategy
     @dev works independently of strategy allowance
     @param strategy receiving address must match the assigned strategy
     @param token ERC20 asset
     @param amount amount to send
     */
    function toStrategy(address strategy, address token, uint256 amount) external onlyOwnerOrController {
        Asset storage a = assets[token];
        require(a.strategy == strategy, "OTV1B: not the token strategy");
        IERC20(token).safeTransfer(strategy, amount);
        emit ToStrategy(msg.sender, strategy, token, amount);
    }

    /**
     @notice governance can transfer assets from the strategy to this vault
     @param strategy receiving address must match the assigned strategy
     @param token ERC20 asset
     @param amount amount to draw from the strategy
     */
    function fromStrategy(address strategy, address token, uint256 amount) external onlyOwnerOrController {
        Asset storage a = assets[token];
        require(a.strategy == strategy, "OTV1B: not the token strategy");
        IStrategy(strategy).toVault(token, amount);
        emit FromStrategy(msg.sender, strategy, token, amount);
    }

    /**
     @notice governance can manage an allowance for a token strategy
     @dev adjusts the remaining allowance for automated transfers executed by the controller
     @param token ERC20 asset
     @param amount allowance increase
     */
    function increaseStrategyAllowance(address token, uint256 amount) external onlyOwnerOrController override {
        Asset storage a = assets[token];
        address strategy = a.strategy;
        require(a.strategy != NULL_ADDRESS, "OTV1B: no strategy");
        IERC20(token).safeIncreaseAllowance(strategy, amount);
        emit StrategyAllowanceIncreased(msg.sender, token, strategy, amount);
    }

    /**
     @notice governance can manage an allowance for a token strategy
     @dev adjusts the remaining allowance for automated transfers executed by the controller
     @param token ERC20 asset
     @param amount allowance decrease
     */    
    function decreaseStrategyAllowance(address token, uint256 amount) external onlyOwnerOrController override {
        Asset storage a = assets[token];
        address strategy = a.strategy;
        require(a.strategy != NULL_ADDRESS, "OTV1B: no strategy");
        IERC20(token).safeDecreaseAllowance(strategy, amount);
        emit StrategyAllowanceDecreased(msg.sender, token, strategy, amount);
    }

    /**
     @notice adopt a new factory
     @dev accomodates factory upgrades
     @param newFactory address of the new factory
     */
    function setFactory(address newFactory) external override onlyOwner {
        require(IOneTokenFactory(newFactory).MODULE_TYPE() == COMPONENT_FACTORY, "OTV1B: new factory doesn't emit factory fingerprint");
        oneTokenFactory = newFactory;
        emit NewFactory(msg.sender, newFactory);
    }

    /**
     * View functions
     */

    /**
     @notice returns the local balance and funds held in the assigned strategy, if any
     @param token to inspect
     */
    function balances(address token) public view override returns(uint256 inVault, uint256 inStrategy) {
        IERC20 asset = IERC20(token);
        inVault = asset.balanceOf(address(this));
        address strategy = assets[token].strategy;
        if(strategy != NULL_ADDRESS) inStrategy = asset.balanceOf(strategy);
    }

    /**point
     @notice returns the number of acceptable collateral token contracts
     */
    function collateralTokenCount() external view override returns(uint256) {
        return collateralTokenSet.count();
    }

    /**
     @notice returns the address of an ERC20 token collateral contract at the index
     @param index row to inspect
     */
    function collateralTokenAtIndex(uint256 index) external view override returns(address) {
        return collateralTokenSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the token contract is recognized collateral
     @param token token to inspect
     */
    function isCollateral(address token) public view override returns(bool) {
        return collateralTokenSet.exists(token);
    }

    /**
     @notice returns the count of registered ERC20 asset contracts that not collateral
     */
    function otherTokenCount() external view override returns(uint256) {
        return otherTokenSet.count();
    }

    /**
     @notice returns the non-collateral token contract at the index
     @param index row to inspect
     */
    function otherTokenAtIndex(uint256 index) external view override returns(address) {
        return otherTokenSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the token contract is registered and is not collateral
     @param token token to inspect
     */
    function isOtherToken(address token) external view override returns(bool) {
        return otherTokenSet.exists(token);
    }

    /**
     @notice returns the sum of collateral and non-collateral ERC20 token contracts
     */
    function assetCount() external view override returns(uint256) {
        return assetSet.count();
    }

    /**
     @notice returns the ERC20 contract address at the index
     @param index row to inspect
     */
    function assetAtIndex(uint256 index) external view override returns(address) {
        return assetSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the token contract is a registered asset of either type
     @param token token to inspect
     */
    function isAsset(address token) external view override returns(bool) {
        return assetSet.exists(token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random access
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced. 
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a 
 * fixed gas cost at any scale, O(1). 
 */

library AddressSet {
    
    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    /**
     @notice insert a key. 
     @dev duplicate keys are not permitted.
     @param self storage pointer to a Set. 
     @param key value to insert.
     */    
    function insert(Set storage self, address key, string memory errorMessage) internal {
        require(!exists(self, key), errorMessage);
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length-1;
    }

    /**
     @notice remove a key.
     @dev key to remove must exist. 
     @param self storage pointer to a Set.
     @param key value to remove.
     */    
    function remove(Set storage self, address key, string memory errorMessage) internal {
        require(exists(self, key), errorMessage);
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        address keyToMove = self.keyList[last];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     @notice count the keys.
     @param self storage pointer to a Set. 
     */       
    function count(Set storage self) internal view returns(uint256) {
        return(self.keyList.length);
    }

    /**
     @notice check if a key is in the Set.
     @param self storage pointer to a Set.
     @param key value to check. Version
     @return bool true: Set member, false: not a Set member.
     */  
    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     @notice fetch a key by row (enumerate).
     @param self storage pointer to a Set.
     @param index row to enumerate. Must be < count() - 1.
     */      
    function keyAtIndex(Set storage self, uint256 index) internal view returns(address) {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface IController {
    
    function oneTokenFactory() external returns(address);
    function description() external returns(string memory);
    function init() external;
    function periodic() external;
    function MODULE_TYPE() external view returns(bytes32);    
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IModule.sol";

interface IStrategy is IModule {
    
    function init() external;
    function execute() external;
    function setAllowance(address token, uint256 amount) external;
    function toVault(address token, uint256 amount) external;
    function fromVault(address token, uint256 amount) external;
    function closeAllPositions() external returns(bool);
    function closePositions(address token) external returns(bool success);
    function oneToken() external view returns(address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IModule.sol";

interface IMintMaster is IModule {
    
    function oneTokenOracles(address) external view returns(address);
    function init(address oneTokenOracle) external;
    function updateMintingRatio(address collateralToken) external returns(uint256 ratio, uint256 maxOrderVolume);
    function getMintingRatio(address collateral) external view returns(uint256 ratio, uint256 maxOrderVolume);
    function getMintingRatio2(address oneToken, address collateralToken) external view returns(uint256 ratio, uint256 maxOrderVolume);  
    function getMintingRatio4(address oneToken, address oneTokenOracle, address collateralToken, address collateralOracle) external view returns(uint256 ratio, uint256 maxOrderVolume); 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../mintMaster/MintMasterCommon.sol";
import "../interface/IOneTokenV1.sol";
import "../interface/IOracle.sol";

/**
 * @notice Separate ownable instances can be managed by separate governing authorities.
 * Immutable windowSize and granularity changes require a new oracle contract. 
 */

contract TestMintMaster is MintMasterCommon {
    
    uint256 constant DEFAULT_RATIO = 10 ** 18; // 100%
    uint256 constant DEFAULT_STEP_SIZE = 0;
    uint256 constant MAX_VOLUME = 1000;

    struct Parameters {
        bool set;
        uint256 minRatio;
        uint256 maxRatio;
        uint256 stepSize;
        uint256 lastRatio;      
    }

    mapping(address => Parameters) public parameters;

    event Deployed(address sender, string description);
    event Initialized(address sender, address oneTokenOracle);
    event OneTokenOracleChanged(address sender, address oneToken, address oracle);
    event SetParams(address sender, address oneToken, uint256 minRatio, uint256 maxRatio, uint256 stepSize, uint256 initialRatio);
    event UpdateMintingRatio(address sender, uint256 volatility, uint256 newRatio, uint256 maxOrderVolume);
    event StepSizeSet(address sender, uint256 stepSize);
    event MinRatioSet(address sender, uint256 minRatio);
    event MaxRatioSet(address sender, uint256 maxRatio);
    event RatioSet(address sender, uint256 ratio);
   
    constructor(address oneTokenFactory_, string memory description_) 
        MintMasterCommon(oneTokenFactory_, description_)
    {
        emit Deployed(msg.sender, description_);
    }

    /**
     @notice initializes the common interface 
     @dev A single instance can be shared by n oneToken implementations. Initialize from each instance. 
     @param oneTokenOracle gets the exchange rate of the oneToken
     */
    function init(address oneTokenOracle) external override {
        _setParams(msg.sender, DEFAULT_RATIO, DEFAULT_RATIO, DEFAULT_STEP_SIZE, DEFAULT_RATIO);
        _initMintMaster(msg.sender, oneTokenOracle);
        emit Initialized(msg.sender, oneTokenOracle);
   
    }

    /**
     @notice changes the oracle used to assess the oneTokens' value in relation to the peg
     @dev may use the peggedOracle (efficient but not informative) or an active oracle 
     @param oneToken oneToken vault (also ERC20 token)
     @param oracle oracle contract must be registered in the factory
     */
    function changeOracle(address oneToken, address oracle) external onlyTokenOwner(oneToken) {
        _initMintMaster(oneToken, oracle);
        emit OneTokenOracleChanged(msg.sender, oneToken, oracle);
    }

    /**
     @notice updates parameters for a given oneToken that uses this module
     @dev inspects the oneToken implementation to establish authority
     @param oneToken token context for parameters
     @param minRatio minimum minting ratio that will be set
     @param maxRatio maximum minting ratio that will be set
     @param stepSize adjustment size iteration
     @param initialRatio unadjusted starting minting ratio
     */
    function setParams(
        address oneToken, 
        uint256 minRatio, 
        uint256 maxRatio, 
        uint256 stepSize, 
        uint256 initialRatio
    ) 
        external
        onlyTokenOwner(oneToken)
    {
        _setParams(oneToken, minRatio, maxRatio, stepSize, initialRatio);
    }

    function _setParams(
        address oneToken, 
        uint256 minRatio, 
        uint256 maxRatio, 
        uint256 stepSize, 
        uint256 initialRatio
    ) 
        private
    {
        Parameters storage p = parameters[oneToken];
        require(minRatio <= maxRatio, "Incremental: minRatio must be <= maxRatio");
        require(maxRatio <= PRECISION, "Incremental: maxRatio must be <= 10 ** 18");
        // Can be zero to prevent movement
        // require(stepSize > 0, "Incremental: stepSize must be > 0");
        require(stepSize < maxRatio - minRatio || stepSize == 0, "Incremental: stepSize must be < (max - min) or zero.");
        require(initialRatio >= minRatio, "Incremental: initial ratio must be >= min ratio.");
        require(initialRatio <= maxRatio, "Incremental: initial ratio must be <= max ratio.");
        p.minRatio = minRatio;
        p.maxRatio = maxRatio;
        p.stepSize = stepSize;
        p.lastRatio = initialRatio;
        p.set = true;
        emit SetParams(msg.sender, oneToken, minRatio, maxRatio, stepSize, initialRatio);
    }
 
    /**
     @notice returns an adjusted minting ratio
     @dev oneToken contracts call this to get their own minting ratio
     */
    function getMintingRatio(address /* collateralToken */) external view override returns(uint256 ratio, uint256 maxOrderVolume) {
        return getMintingRatio2(msg.sender, NULL_ADDRESS);
    }

    /**
     @notice returns an adjusted minting ratio. OneTokens use this function and it relies on initialization to select the oracle
     @dev anyone calls this to inspect any oneToken minting ratio
     @param oneToken oneToken implementation to inspect
     */    
    function getMintingRatio2(address oneToken, address /* collateralToken */) public view override returns(uint256 ratio, uint256 maxOrderValue) {
        address oracle = oneTokenOracles[oneToken];
        return getMintingRatio4(oneToken, oracle, NULL_ADDRESS, NULL_ADDRESS);
    }

    /**
     @notice returns an adjusted minting ratio
     @dev anyone calls this to inspect any oneToken minting ratio
     @param oneToken oneToken implementation to inspect
     @param oneTokenOracle explicit oracle selection
     */   
    function getMintingRatio4(address oneToken, address oneTokenOracle, address /* collateral */, address /* collateralOracle */) public override view returns(uint256 ratio, uint256 maxOrderVolume) {       
        Parameters storage p = parameters[oneToken];
        require(p.set, "Incremental: mintmaster is not initialized");
        (uint256 quote, /* uint256 volatility */ ) = IOracle(oneTokenOracle).read(oneToken, PRECISION);
        ratio = p.lastRatio;        
        if(quote == PRECISION) return(ratio, MAX_VOLUME);
        uint256 stepSize = p.stepSize;
        maxOrderVolume = MAX_VOLUME;
        if(quote < PRECISION && ratio + stepSize <= p.maxRatio) {
            ratio += stepSize;
        }
        if(quote > PRECISION && ratio - stepSize >= p.minRatio) {
            ratio -= stepSize;
        }
    }

    /**
     @notice records and returns an adjusted minting ratio for a oneToken implemtation
     @dev oneToken implementations calls this periodically, e.g. in the minting process
     */
    function updateMintingRatio(address /* collateralToken */) external override returns(uint256 ratio, uint256 maxOrderVolume) {
        return _updateMintingRatio(msg.sender, NULL_ADDRESS);
    }

    /**
     @notice records and returns an adjusted minting ratio for a oneToken implemtation
     @dev internal use only
     @param oneToken the oneToken implementation to evaluate
     */    
    function _updateMintingRatio(address oneToken, address /* collateralToken */) private returns(uint256 ratio, uint256 maxOrderVolume) {
        Parameters storage p = parameters[oneToken];
        address o = oneTokenOracles[oneToken];
        IOracle(o).update(oneToken);
        (ratio, maxOrderVolume) = getMintingRatio2(oneToken, NULL_ADDRESS);
        p.lastRatio = ratio;
        /// @notice no event is emitted to save gas
        // emit UpdateMintingRatio(msg.sender, volatility, ratio, maxOrderVolume);
    }

    /**
     * Governance functions
     */

    /**
     @notice adjusts the rate of minting ratio change
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     @param oneToken the implementation to work with
     @param stepSize the step size must be smaller than the difference of min and max
     */
    function setStepSize(address oneToken, uint256 stepSize) public onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(stepSize < p.maxRatio - p.minRatio, "Incremental: stepSize must be < max - min.");
        p.stepSize = stepSize;
        emit StepSizeSet(msg.sender, stepSize);
    }

    /**
     @notice sets the minimum minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     if the new minimum is higher than current minting ratio, the current ratio will be adjusted to minRatio
     @param oneToken the implementation to work with
     @param minRatio the new lower bound for the minting ratio
     */    
    function setMinRatio(address oneToken, uint256 minRatio) public onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(minRatio <= p.maxRatio, "Incremental: minRatio must be <= maxRatio");
        p.minRatio = minRatio;
        if(minRatio > p.lastRatio) setRatio(oneToken, minRatio);
        emit MinRatioSet(msg.sender, minRatio);
    }

    /**
     @notice sets the maximum minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     if the new maximum is lower is than current minting ratio, the current ratio will be set to maxRatio
     @param oneToken the implementation to work with
     @param maxRatio the new upper bound for the minting ratio
     */ 
    function setMaxRatio(address oneToken, uint256 maxRatio) public onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(maxRatio > p.minRatio, "Incremental: maxRatio must be > minRatio");
        require(maxRatio <= PRECISION, "Incremental: maxRatio must <= 100%");
        p.maxRatio = maxRatio;
        if(maxRatio < p.lastRatio) setRatio(oneToken, maxRatio);
        emit MaxRatioSet(msg.sender, maxRatio);
    }

    /**
     @notice sets the current minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     @param oneToken the implementation to work with
     @param ratio must be in the min-max range
     */
    function setRatio(address oneToken, uint256 ratio) public onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(ratio > 0, "Incremental: ratio must be > 0");
        require(ratio <= PRECISION, "Incremental: ratio must be <= 100%");
        require(ratio >= p.minRatio, "Incremental: ratio must be >= minRatio");
        require(ratio <= p.maxRatio, "Incremental: ratio must be <= maxRatio");
        p.lastRatio = ratio;
        emit RatioSet(msg.sender, ratio);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../common/ICHIModuleCommon.sol";
import "../interface/IMintMaster.sol";
import "../interface/IOneTokenV1Base.sol";
import "../interface/IOneTokenFactory.sol";

abstract contract MintMasterCommon is IMintMaster, ICHIModuleCommon{

    bytes32 constant public override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 MintMaster Implementation"));
    mapping(address => address) public override oneTokenOracles;

    event MintMasterDeployed(address sender, address oneTokenFactory, string description);
    event MintMasterInitialized(address sender, address oneToken, address oneTokenOracle);

    /**
     @notice controllers are bound to factories at deployment time
     @param oneTokenFactory_ factory to bind to
     @param description_ human-readable, descriptive only
     */ 
    constructor(address oneTokenFactory_, string memory description_) 
        ICHIModuleCommon(oneTokenFactory_, ModuleType.MintMaster, description_) 
    { 
        emit MintMasterDeployed(msg.sender, oneTokenFactory_, description_);
    }

    /**
     @notice initializes the common interface with parameters managed by msg.sender, usually a oneToken.
     @dev Initialize from each instance. Re-initialization is acceptabe.
     @param oneTokenOracle gets the exchange rate of the oneToken
     */
    function init(address oneTokenOracle) external onlyKnownToken virtual override {
        emit MintMasterInitialized(msg.sender, msg.sender, oneTokenOracle);
    }

    /**
     @notice sets up the common interface
     @dev only called when msg.sender is the oneToken or the oneToken governance
     @param oneToken the oneToken context for the multi-tenant MintMaster implementation
     @param oneTokenOracle proposed oracle for the oneToken that intializes the mintMaster
     */
    function _initMintMaster(address oneToken, address oneTokenOracle) internal {
        require(IOneTokenFactory(IOneTokenV1Base(oneToken).oneTokenFactory()).isModule(oneTokenOracle), "MintMasterCommon: unknown oracle");
        require(IOneTokenFactory(IOneTokenV1Base(oneToken).oneTokenFactory()).isValidModuleType(oneTokenOracle, ModuleType.Oracle), "MintMasterCommon: given oracle is not valid for oneToken (msg.sender)");
        oneTokenOracles[oneToken] = oneTokenOracle;
        emit MintMasterInitialized(msg.sender, oneToken, oneTokenOracle);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IOneTokenV1Base.sol";

interface IOneTokenV1 is IOneTokenV1Base {

    function mintingFee() external view returns(uint);
    function redemptionFee() external view returns(uint);
    function mint(address collateral, uint oneTokens) external;
    function redeem(address collateral, uint amount) external;
    function setMintingFee(uint fee) external;
    function setRedemptionFee(uint fee) external;
    function updateMintingRatio(address collateralToken) external returns(uint ratio, uint maxOrderVolume);
    function getMintingRatio(address collateralToken) external view returns(uint ratio, uint maxOrderVolume);
    function getHoldings(address token) external view returns(uint vaultBalance, uint strategyBalance);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../../interface/IOneTokenV1.sol";
import "../../_openzeppelin/token/ERC20/SafeERC20.sol";
import "./OneTokenV1Base.sol";

contract OneTokenV1 is IOneTokenV1, OneTokenV1Base {

    using AddressSet for AddressSet.Set;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public override mintingFee; // defaults to 0%
    uint256 public override redemptionFee; // defaults to 0%

    /**
     @notice sum of userBalances for each collateral token are not counted in treasury valuations
     @dev token => liability
     */
    mapping(address => uint256) public liabilities;
  
    event Minted(address indexed sender, address indexed collateral, uint256 oneTokens, uint256 memberTokens, uint256 collateralTokens);
    event Redeemed(address indexed sender, address indexed collateral, uint256 amount);
    event NewMintingFee(address sender, uint256 fee);
    event NewRedemptionFee(address sender, uint256 fee);
    
    /// @dev there is no constructor for proxy deployment. Use init()

    /**
     @notice convert member tokens and collateral tokens into oneTokens. requires sufficient allowances for both tokens
     @dev takes the lessor of memberTokens allowance or the maximum allowed by the minting ratio and the balance in collateral
     @param collateralToken a registered ERC20 collateral token contract
     @param oneTokens exact number of oneTokens to receive
     */
    function mint(address collateralToken, uint256 oneTokens) external initialized override {
        require(collateralTokenSet.exists(collateralToken), "OTV1: offer a collateral token");
        require(oneTokens > 0, "OTV1: order must be > 0");
        
        // update collateral and memberToken oracles
        IOracle(assets[collateralToken].oracle).update(collateralToken);
        IOracle(assets[memberToken].oracle).update(memberToken);
        
        // update oneToken oracle and evaluate
        (uint256 mintingRatio, uint256 maxOrderVolume) = updateMintingRatio(collateralToken);

        // future mintmasters may return a maximum order volume to tamp down on possible manipulation
        require(oneTokens <= maxOrderVolume, "OTV1: order exceeds limit");

        // compute the member token value and collateral value requirement
        uint256 collateralUSDValue = oneTokens.mul(mintingRatio).div(PRECISION);
        uint256 memberTokensUSDValue = oneTokens.sub(collateralUSDValue);
        collateralUSDValue = collateralUSDValue.add(oneTokens.mul(mintingFee).div(PRECISION));

        // compute the member tokens required
        (uint256 memberTokensReq, /* volatility */) = IOracle(assets[memberToken].oracle).amountRequired(memberToken, memberTokensUSDValue);

        // check the memberToken allowance - the maximum we can draw from the user
        uint256 memberTokenAllowance = IERC20(memberToken).allowance(msg.sender, address(this));

        // increase collateral required if the memberToken allowance is too low
        if(memberTokensReq > memberTokenAllowance) {
            uint256 memberTokenRate = memberTokensUSDValue.mul(PRECISION).div(memberTokensReq);
            memberTokensReq = memberTokenAllowance;
            // re-evaluate the memberToken value and collateral value required using the oracle rate already obtained
            memberTokensUSDValue = memberTokenRate.mul(memberTokensReq).div(PRECISION);
            collateralUSDValue = oneTokens.sub(memberTokensUSDValue);
            collateralUSDValue = collateralUSDValue.add(oneTokens.mul(mintingFee).div(PRECISION));
        }

        require(IERC20(memberToken).balanceOf(msg.sender) >= memberTokensReq, "OTV1: NSF: member token");

        // compute actual collateral tokens required in case of imperfect collateral pegs
        // a pegged oracle can be used to reduce the cost of this step but it will not account for price differences
        (uint256 collateralTokensReq, /* volatility */) = IOracle(assets[collateralToken].oracle).amountRequired(collateralToken, collateralUSDValue);

        require(IERC20(collateralToken).balanceOf(msg.sender) >= collateralTokensReq, "OTV1: NSF: collateral token");
        require(collateralTokensReq > 0, "OTV1: order too small");

        // transfer tokens in
        IERC20(memberToken).safeTransferFrom(msg.sender, address(this), memberTokensReq);
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateralTokensReq);
        
        // mint oneTokens
        _mint(msg.sender, oneTokens);

        emit Minted(msg.sender, collateralToken, oneTokens, memberTokensReq, collateralTokensReq);
    }

    /**
     @notice redeem oneTokens for collateral tokens at 1:1 - applies fee %
     @dev first grant allowances, then redeem. Consider infinite collateral allowance and a sufficient memberToken allowance. Updates ratio and triggers controller.
     @param collateral form of ERC20 stable token to receive
     @param amount oneTokens to redeem equals collateral tokens to receive
     */
    function redeem(address collateral, uint256 amount) external override {
        require(isCollateral(collateral), "OTV1: unknown collateral");
        require(amount > 0, "OTV1: amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "OTV1: NSF: oneToken");
        IOracle co = IOracle(assets[collateral].oracle);
        co.update(collateral);

        // implied transfer approval and allowance
        _burn(msg.sender, amount);

        uint256 netUsd = amount.sub(amount.mul(redemptionFee).div(PRECISION));
        (uint256 netTokens, /* uint256 volatility */)  = co.amountRequired(collateral, netUsd);

        IERC20(collateral).safeTransfer(msg.sender, netTokens);
        emit Redeemed(msg.sender, collateral, amount);
        
        // updates the oneToken oracle price history
        updateMintingRatio(collateral);

        // periodic automated processes
        IController(controller).periodic();
    }

    /**
     @notice governance sets the adjustable fee
     @param fee fee, 18 decimals, e.g. 2% = 20000000000000000
     */
    function setMintingFee(uint256 fee) external onlyOwner override {
        require(fee <= PRECISION, "OTV1: fee must be <= 100%");
        mintingFee = fee;
        emit NewMintingFee(msg.sender, fee);
    }

    /**
     @notice governance sets the adjustable fee
     @param fee fee, 18 decimals, e.g. 2% = 20000000000000000
     */
    function setRedemptionFee(uint256 fee) external onlyOwner override {
        require(fee <= PRECISION, "OTV1: fee must be <= 100%");
        redemptionFee = fee;
        emit NewRedemptionFee(msg.sender, fee);
    }    

    /**
     @notice adjust the minting ratio
     @dev acceptable for gas-paying external actors to call this function
     @param collateralToken token to use for ratio calculation
     @param ratio minting ratio
     @param maxOrderVolume maximum order size
     */
    function updateMintingRatio(address collateralToken) public override returns(uint256 ratio, uint256 maxOrderVolume) {
        return IMintMaster(mintMaster).updateMintingRatio(collateralToken);
    }

    /**
     @notice read the minting ratio and maximum order volume prescribed by the mintMaster
     @param collateralToken token to use for ratio calculation
     @param ratio minting ratio
     @param maxOrderVolume maximum order size
     */
    function getMintingRatio(address collateralToken) external view override returns(uint256 ratio, uint256 maxOrderVolume) {
        return IMintMaster(mintMaster).getMintingRatio(collateralToken);
    }

    /**
     @notice read the vault balance and strategy balance of a given token
     @dev not restricted to registered assets
     @param token ERC20 asset to report
     @param vaultBalance tokens held in this vault
     @param strategyBalance tokens in assigned strategy
     */
    function getHoldings(address token) external view override returns(uint256 vaultBalance, uint256 strategyBalance) {   
        IERC20 t = IERC20(token);
        vaultBalance = t.balanceOf(address(this));
        Asset storage a = assets[token];
        if(a.strategy != NULL_ADDRESS) strategyBalance = t.balanceOf(a.strategy);
    } 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interface/IOneTokenFactory.sol";
import "../interface/IStrategy.sol";
import "../interface/IOneTokenV1Base.sol";
import "../_openzeppelin/token/ERC20/IERC20.sol";
import "../_openzeppelin/token/ERC20/SafeERC20.sol";
import "../common/ICHIModuleCommon.sol";

abstract contract StrategyCommon is IStrategy, ICHIModuleCommon {

    using SafeERC20 for IERC20;

    address public override oneToken;
    bytes32 constant public override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 Strategy Implementation"));

    event StrategyDeployed(address sender, address oneTokenFactory, address oneToken_, string description);
    event StrategyInitialized(address sender);
    event StrategyExecuted(address indexed sender, address indexed token);
    event VaultAllowance(address indexed sender, address indexed token, uint256 amount);
    event FromVault(address indexed sender, address indexed token, uint256 amount);
    event ToVault(address indexed sender, address indexed token, uint256 amount);

    modifier onlyToken {
        require(msg.sender == oneToken, "StrategyCommon: initialize from oneToken instance");
        _;
    }
    
    /**
     @dev oneToken governance has privileges that may be delegated to a controller
     */
    modifier strategyOwnerTokenOrController {
        if(msg.sender != oneToken) {
            if(msg.sender != IOneTokenV1Base(oneToken).controller()) {
                require(msg.sender == IOneTokenV1Base(oneToken).owner(), "StrategyCommon: not token controller or owner.");
            }
        }
        _;
    }

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param oneTokenFactory_ bind this instance to oneTokenFactory instance
     @param oneToken_ bind this instance to one oneToken vault
     @param description_ metadata has no impact on logic
     */
    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        ICHIModuleCommon(oneTokenFactory_, ModuleType.Strategy, description_)
    {
        require(oneToken_ != NULL_ADDRESS, "StrategyCommon: oneToken cannot be NULL");
        require(IOneTokenFactory(IOneTokenV1Base(oneToken_).oneTokenFactory()).isOneToken(oneToken_), "StrategyCommon: oneToken is unknown");
        oneToken = oneToken_;
        emit StrategyDeployed(msg.sender, oneTokenFactory_, oneToken_, description_);
    }

    /**
     @notice a strategy is dedicated to exactly one oneToken instance and must be re-initializable
     */
    function init() external onlyToken virtual override {
        IERC20(oneToken).safeApprove(oneToken, 0);
        IERC20(oneToken).safeApprove(oneToken, INFINITE);
        emit StrategyInitialized(oneToken);
    }

    /**
     @notice a controller invokes execute() to trigger automated logic within the strategy.
     @dev called from oneToken governance or the active controller. Overriding function should emit the event. 
     */  
    function execute() external virtual strategyOwnerTokenOrController override {
        // emit StrategyExecuted(msg.sender, oneToken);
    }  
        
    /**
     @notice gives the oneToken control of tokens deposited in the strategy
     @dev called from oneToken governance or the active controller
     @param token the asset
     @param amount the allowance. 0 = infinte
     */
    function setAllowance(address token, uint256 amount) external strategyOwnerTokenOrController override {
        if(amount == 0) amount = INFINITE;
        IERC20(token).safeApprove(oneToken, 0);
        IERC20(token).safeApprove(oneToken, amount);
        emit VaultAllowance(msg.sender, token, amount);
    }

    /**
     @notice closes all positions and returns the funds to the oneToken vault
     @dev override this function to withdraw funds from external contracts. Return false if any funds are unrecovered.
     */
    function closeAllPositions() external virtual strategyOwnerTokenOrController override returns(bool success) {
        success = _closeAllPositions();
    }

    /**
     @notice closes all positions and returns the funds to the oneToken vault
     @dev override this function to withdraw funds from external contracts. Return false if any funds are unrecovered.
     */
    function _closeAllPositions() internal virtual returns(bool success) {
        uint256 assetCount;
        success = true;
        assetCount = IOneTokenV1Base(oneToken).assetCount();
        for(uint256 i=0; i < assetCount; i++) {
            address thisAsset = IOneTokenV1Base(oneToken).assetAtIndex(i);
            closePositions(thisAsset);
        }
    }

    /**
     @notice closes token positions and returns the funds to the oneToken vault
     @dev override this function to redeem and withdraw related funds from external contracts. Return false if any funds are unrecovered. 
     @param token asset to recover
     @param success true, complete success, false, 1 or more failed operations
     */
    function closePositions(address token) public strategyOwnerTokenOrController override virtual returns(bool success) {
        // this naive process returns funds on hand.
        // override this to explicitly close external positions and return false if 1 or more positions cannot be closed at this time.
        success = true;
        uint256 strategyBalance = IERC20(token).balanceOf(address(this));
        if(strategyBalance > 0) {
            _toVault(token, strategyBalance);
        }
    }

    /**
     @notice let's the oneToken controller instance send funds to the oneToken vault
     @dev implementations must close external positions and return all related assets to the vault
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function toVault(address token, uint256 amount) external strategyOwnerTokenOrController override {
        _toVault(token, amount);
    }

    /**
     @notice close external positions send all related funds to the oneToken vault
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function _toVault(address token, uint256 amount) internal {
        IERC20(token).safeTransfer(oneToken, amount);
        emit ToVault(msg.sender, token, amount);
    }

    /**
     @notice let's the oneToken controller instance draw funds from the oneToken vault allowance
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function fromVault(address token, uint256 amount) external strategyOwnerTokenOrController override {
        _fromVault(token, amount);
    }

    /**
     @notice draw funds from the oneToken vault
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function _fromVault(address token, uint256 amount) internal {
        IERC20(token).safeTransferFrom(oneToken, address(this), amount);
        emit FromVault(msg.sender, token, amount);
    }
}

// SPDX-License-Identifier: MIT

import "../StrategyCommon.sol";

pragma solidity 0.7.6;

contract NullStrategy is StrategyCommon {

    /**
     * @notice Supports the minimum interface but does nothing with funds committed to the strategy
     */

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param oneTokenFactory_ bind this instance to oneTokenFactory instance
     @param oneToken_ bind this instance to one oneToken vault
     @param description_ metadata has no impact on logic
     */

    constructor(address oneTokenFactory_, address oneToken_, string memory description_) 
        StrategyCommon(oneTokenFactory_, oneToken_, description_)
    {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../oracle/OracleCommon.sol";
import "../interface/IERC20Extended.sol";

/**
 * @notice Separate ownable instances can be managed by separate governing authorities.
 * Immutable windowSize and granularity changes require a new oracle contract. 
 */

contract TestOracle is OracleCommon {

    event Deployed(address sender);
    event Initialized(address sender, address baseToken, address indexToken);
    event Updated(address sender);
    
    /**
    @dev should the oracle get off center up or down
     */
    bool private adjustUp;

    constructor(address oneTokenFactory_, string memory description_, address indexToken_) 
        OracleCommon(oneTokenFactory_, description_, indexToken_) 
    {
        adjustUp = false;
        emit Deployed(msg.sender);
    }

    /**
     @notice update is adjust up/down flag
     */
    function setAdjustUp(bool _adjustUp) external {
        adjustUp = _adjustUp;
    }

    /**
     @notice intialization is called when a oneToken appoints an Oracle
     @dev there is nothing to do in this case
     */
    function init(address /* baseToken */) external override {}

    /**
     @notice update is called when a oneToken wants to persist observations
     @dev there is nothing to do in this case
     */
    function update(address /* token */) external override {
        emit Updated(msg.sender);
    }

    /**
     @notice returns equivalent amount of index tokens for an amount of baseTokens and volatility metric
     @dev token:usdToken is always 1:1 and valatility is always 0
     */
    function read(address /* token */, uint256 amount) public view override returns(uint256 amountOut, uint256 volatility) {
        /// @notice it is always 1:1 with no volatility
        this; // silence mutability warning
        if (adjustUp) {
            amountOut = amount + 2 * 10 ** 16;
        } else {
            amountOut = amount - 2 * 10 ** 16;
        }
        volatility = 1;
    }

    /**
     @notice returns the tokens needed to reach a target usd value
     @dev token:usdToken is always 1:1 and valatility is always 0
     */
    function amountRequired(address /* token */, uint256 amountUsd) external view override returns(uint256 tokens, uint256 volatility) {
        /// @notice it is always 1:1 with no volatility
        this; // silence visbility warning
        tokens = amountUsd;
        volatility = 1;      
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../OracleCommon.sol";
import "../../interface/IERC20Extended.sol";

/**
 @notice Returns 1:1, scaled to 18 
 */

contract ICHIPeggedOracle is OracleCommon {

    /** 
     @param oneTokenFactory_ oneToken factory to bind to
     @param description_ description has no bearing on logic
     @param indexToken_ token to use for price quotes
     */
    constructor(address oneTokenFactory_, string memory description_, address indexToken_)
        OracleCommon(oneTokenFactory_, description_, indexToken_) {}

    /**
     @notice update is called when a oneToken wants to persist observations
     @dev there is nothing to do in this case
     */
    function update(address /* token */) external override {}

    /**
     @notice returns equivalent amount of index tokens for an amount of baseTokens and volatility metric
     @dev amountTokens:amountUsd is always 1:1, adjusted for normalized scale, and volatility is always 0
     @param token base token
     @param amountTokens quantity, token native precision
     @param amountUsd US dollar equivalentm, precision 18
     @param volatility metric for future use-cases
     */
    function read(address token, uint256 amountTokens) external view override returns(uint256 amountUsd, uint256 volatility) {
        amountUsd = tokensToNormalized(token, amountTokens);
        volatility = 1;
    }

    /**
     @notice returns the tokens needed to reach a target usd value
     @dev token:usdToken is always 1:1 and volatility is always 1
     @param token base token
     @param amountUsd Usd required, precision 18
     @param amountTokens tokens required, token native precision
     @param volatility metric for future use-cases
     */
    function amountRequired(address token, uint256 amountUsd) external view override returns(uint256 amountTokens, uint256 volatility) {
        amountTokens = normalizedToTokens(token, amountUsd);
        volatility = 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../OracleCommon.sol";
import "../../interface/IERC20Extended.sol";
import "../../_openzeppelin/math/SafeMath.sol";

/**
 @notice Relies on external Oracles using any price quote methodology.
 */

contract ICHICompositeOracle is OracleCommon {

    using SafeMath for uint256;
    
    address[] public oracleContracts;
    address[] public interimTokens;

    /**
     @notice addresses and oracles define a chain of currency conversions (e.g. X:ETH, ETH:BTC: BTC:USDC => X:USDC) that will be executed in order of declaration
     @dev output of oracles is used as input for the next oracle. 
     @param description_ human-readable name has no bearing on internal logic
     @param indexToken_ a registered usdToken to use for quote indexed
     @param interimTokens_ a sequential list of base tokens to query the oracles, starting with the base token for the composite oracle, e.g. X
     @param oracles_ a sequential list of unregisted contracts that support the IOracle interface, ending with a collateral token, e.g. USDC
     */
    constructor(address oneTokenFactory_, string memory description_, address indexToken_, address[] memory interimTokens_, address[] memory oracles_)
        OracleCommon(oneTokenFactory_, description_, indexToken_)
    {
        require(interimTokens_.length == oracles_.length, 'ICHICompositeOracle: unequal interimTokens and Oracles list lengths');
        oracleContracts = oracles_;
        interimTokens = interimTokens_;
        indexToken = indexToken_;
    }

    /**
     @notice intialization is called when the factory assigns an oracle to an asset
     @dev there is nothing to do. Deploy separate instances configured for distinct baseTokens
     */
    function init(address baseToken) external onlyModuleOrFactory override {
        for(uint256 i=0; i<oracleContracts.length; i++) {
            IOracle(oracleContracts[i]).init(interimTokens[i]);
        }
        emit OracleInitialized(msg.sender, baseToken, indexToken);
    }

    /**
     @notice update is called when a oneToken wants to persist observations
     @dev chain length is constrained by gas
     //param token composite oracles are always single-tenant, The token context is ignored.
     */
    function update(address /* token */) external override {
        for(uint256 i=0; i<oracleContracts.length; i++) {
            IOracle(oracleContracts[i]).update(interimTokens[i]);
        }
    }

    /**
     @notice returns equivalent amount of index tokens for an amount of baseTokens and volatility metric
     @dev volatility is the product of interim volatility measurements
     //param token composite oracles are always single-tenant, The token context is ignored.
     @param amountTokens quantity of tokens, token precision
     @param amountUsd index tokens required, precision 18
     @param volatility overall volatility metric - for future use-caeses
     */
    function read(address /* token */ , uint256 amountTokens) public view override returns(uint256 amountUsd, uint256 volatility) {
        uint256 compoundedVolatility;
        uint256 amount = tokensToNormalized(interimTokens[0], amountTokens);
        volatility = 1;
        for(uint256 i=0; i<oracleContracts.length; i++) {
            ( amount, compoundedVolatility ) = IOracle(oracleContracts[i]).read(interimTokens[i], normalizedToTokens(interimTokens[i], amount));
            volatility = volatility.mul(compoundedVolatility);
        }
        amountUsd = amount;
    }

    /**
     @notice returns the tokens needed to reach a target usd value
     //param token composite oracles are always single-tenant, The token context is ignored.     
     @param amountUsd Usd required in 10**18 precision
     @param amountTokens tokens required in tokens native precision
     @param volatility metric for future use-cases
     */
    function amountRequired(address /* token */, uint256 amountUsd) external view override returns(uint256 amountTokens, uint256 volatility) {
        uint256 tokenToUsd;
        (tokenToUsd, volatility) = read(NULL_ADDRESS, normalizedToTokens(indexToken, PRECISION)); 
        amountTokens = PRECISION.mul(amountUsd).div(tokenToUsd);
        amountTokens = normalizedToTokens(indexToken, amountTokens);
        volatility = 1;
    }

    /**
     * extended functionality 
     */

    /**
     @param count number of interim oracles
     */
    function oracleCount() external view returns(uint256 count) {
        return oracleContracts.length;
    }

    /**
     @param index oracle contract to retrieve
     @param oracle interim token oracle address
     @param token interim token address     
     */

    function oracleAtIndex(uint256 index) external view returns(address oracle, address token) {
        return(oracleContracts[index], interimTokens[index]);
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../controller/ControllerCommon.sol";
import "../interface/IOneTokenV1Base.sol";
import "../interface/IStrategy.sol";

contract TestController is ControllerCommon {


    /**
     @notice this controller implementation supports the interface and add functions needed for testings
     @dev the controller implementation can be extended but must implement the minimum interface
     */

    constructor(address oneTokenFactory_)
       ControllerCommon(oneTokenFactory_, "Test Controller")
     {} 

    function executeStrategy(address oneToken, address token) external {
        IOneTokenV1Base(oneToken).executeStrategy(token);
    }

    function testDirectExecute(address strategy) external {
        IStrategy(strategy).execute();
    }
      
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interface/IController.sol";
import "../interface/IOneTokenFactory.sol";

abstract contract ControllerCommon is IController {

    bytes32 constant public override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 Controller"));

    address public override oneTokenFactory;
    string public override description;

    event ControllerDeployed(address sender, address oneTokenFactory, string description);
    event ControllerInitialized(address sender);
    event ControllerPeriodic(address sender);

    modifier onlyKnownToken {
        require(IOneTokenFactory(oneTokenFactory).isOneToken(msg.sender), "ICHIModuleCommon: msg.sender is not a known oneToken");
        _;
    }

    /**
     @notice Controllers rebalance funds and may execute strategies periodically.
     */
    
    /**
     @notice controllers are bound to factories at deployment time
     @param oneTokenFactory_ factory to bind to
     @param description_ human-readable, description only
     */ 
    constructor(address oneTokenFactory_, string memory description_) {
        oneTokenFactory = oneTokenFactory_;
        description = description_;
        emit ControllerDeployed(msg.sender, oneTokenFactory_, description);
    }    
    
    /**
     @notice oneTokens invoke periodic() to trigger periodic processes. Can be trigger externally.
     @dev Acceptable access control will vary by implementation. 
     */  
    function periodic() external virtual override {
        emit ControllerPeriodic(msg.sender);
    }  
        
    /**
     @notice OneTokenBase (msg.sender) calls this when the controller is assigned. Must be re-initializeable.
     */
    function init() external onlyKnownToken virtual override {
        emit ControllerInitialized(msg.sender);
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../mintMaster/MintMasterCommon.sol";
import "../interface/IOneTokenV1.sol";
import "../interface/IOracle.sol";

/**
 * @notice Separate ownable instances can be managed by separate governing authorities.
 * Immutable windowSize and granularity changes require a new oracle contract. 
 */

contract DummyMintMaster is MintMasterCommon {
    
    uint256 constant DEFAULT_RATIO = 10 ** 18; // 100%
    uint256 constant MAX_VOLUME = 1000;

    event Deployed(address sender, string description);
    event Initialized(address sender, address oneTokenOracle);
    event OneTokenOracleChanged(address sender, address oneToken, address oracle);
    event SetParams(address sender, address oneToken, uint256 minRatio, uint256 maxRatio, uint256 stepSize, uint256 initialRatio);
    event UpdateMintingRatio(address sender, uint256 volatility, uint256 newRatio, uint256 maxOrderVolume);
    event StepSizeSet(address sender, uint256 stepSize);
    event MinRatioSet(address sender, uint256 minRatio);
    event MaxRatioSet(address sender, uint256 maxRatio);
    event RatioSet(address sender, uint256 ratio);
   
    constructor(address oneTokenFactory_, string memory description_) 
        MintMasterCommon(oneTokenFactory_, description_)
    {
        emit Deployed(msg.sender, description_);
    }

    /**
     @notice changes the oracle used to assess the oneTokens' value in relation to the peg
     @dev may use the peggedOracle (efficient but not informative) or an active oracle 
     @param oneToken oneToken vault (also ERC20 token)
     @param oracle oracle contract must be registered in the factory
     */
    function changeOracle(address oneToken, address oracle) external onlyTokenOwner(oneToken) {
        _initMintMaster(oneToken, oracle);
        emit OneTokenOracleChanged(msg.sender, oneToken, oracle);
    }

    /**
     @notice updates parameters for a given oneToken that uses this module
     @dev inspects the oneToken implementation to establish authority
     @param oneToken token context for parameters
     @param minRatio minimum minting ratio that will be set
     @param maxRatio maximum minting ratio that will be set
     @param stepSize adjustment size iteration
     @param initialRatio unadjusted starting minting ratio
     */
    function setParams(
        address oneToken, 
        uint256 minRatio, 
        uint256 maxRatio, 
        uint256 stepSize, 
        uint256 initialRatio
    ) 
        external
        onlyTokenOwner(oneToken)
    {
        emit SetParams(msg.sender, oneToken, minRatio, maxRatio, stepSize, initialRatio);
    }

    /**
     @notice returns an adjusted minting ratio
     @dev oneToken contracts call this to get their own minting ratio
     */
    function getMintingRatio(address /* collateralToken */) external view override returns(uint256 ratio, uint256 maxOrderVolume) {
        return getMintingRatio2(msg.sender, NULL_ADDRESS);
    }

    /**
     @notice returns an adjusted minting ratio. OneTokens use this function and it relies on initialization to select the oracle
     @dev anyone calls this to inspect any oneToken minting ratio
     @param oneToken oneToken implementation to inspect
     */    
    function getMintingRatio2(address oneToken, address /* collateralToken */) public view override returns(uint256 ratio, uint256 maxOrderValue) {
        address oracle = oneTokenOracles[oneToken];
        return getMintingRatio4(oneToken, oracle, NULL_ADDRESS, NULL_ADDRESS);
    }

    /**
     @notice returns an adjusted minting ratio
     @dev anyone calls this to inspect any oneToken minting ratio
     */   
    function getMintingRatio4(address /* oneToken */, address /* oneTokenOracle */, address /* collateral */, address /* collateralOracle */) public override view returns(uint256 ratio, uint256 maxOrderVolume) {       
        this; // suppress state mutability warning
        return(DEFAULT_RATIO, MAX_VOLUME);
    }

    /**
     @notice records and returns an adjusted minting ratio for a oneToken implemtation
     @dev oneToken implementations calls this periodically, e.g. in the minting process
     */
    function updateMintingRatio(address collateralToken) external override returns(uint256 ratio, uint256 maxOrderVolume) {
    }

    /**
     * Governance functions
     */

    /**
     @notice adjusts the rate of minting ratio change
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     @param oneToken the implementation to work with
     @param stepSize the step size must be smaller than the difference of min and max
     */
    function setStepSize(address oneToken, uint256 stepSize) public onlyTokenOwner(oneToken) {
        emit StepSizeSet(msg.sender, stepSize);
    }

    /**
     @notice sets the minimum minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     if the new minimum is higher than current minting ratio, the current ratio will be adjusted to minRatio
     @param oneToken the implementation to work with
     @param minRatio the new lower bound for the minting ratio
     */    
    function setMinRatio(address oneToken, uint256 minRatio) public onlyTokenOwner(oneToken) {
        emit MinRatioSet(msg.sender, minRatio);
    }

    /**
     @notice sets the maximum minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     if the new maximum is lower is than current minting ratio, the current ratio will be set to maxRatio
     @param oneToken the implementation to work with
     @param maxRatio the new upper bound for the minting ratio
     */ 
    function setMaxRatio(address oneToken, uint256 maxRatio) public onlyTokenOwner(oneToken) {
        emit MaxRatioSet(msg.sender, maxRatio);
    }

    /**
     @notice sets the current minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     @param oneToken the implementation to work with
     @param ratio must be in the min-max range
     */
    function setRatio(address oneToken, uint256 ratio) public onlyTokenOwner(oneToken) {
        emit RatioSet(msg.sender, ratio);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./common/ICHICommon.sol";
import "./OneTokenProxy.sol";
import "./OneTokenProxyAdmin.sol";
import "./lib/AddressSet.sol";
import "./interface/IOneTokenFactory.sol";
import "./interface/IOneTokenV1.sol";
import "./interface/IOracle.sol";
import "./_openzeppelin/access/Ownable.sol";

contract OneTokenFactory is IOneTokenFactory, ICHICommon {

    using AddressSet for AddressSet.Set;
    bytes32 public constant override MODULE_TYPE = keccak256(abi.encodePacked("ICHI OneToken Factory"));
    bytes constant NULL_DATA = "";

    AddressSet.Set oneTokenSet;
    mapping(address => address) public override oneTokenProxyAdmins;

    struct Module {
        string name;
        string url;
        ModuleType moduleType;
    }

    AddressSet.Set moduleSet;
    mapping(address => Module) public modules;

    /**
     @dev a foreign token can be a collateral token, member token or other, e.g. LP token.
     This whitelist ensures that no unapproved token contracts are interacted with. Only recognized
     foreign tokens are included in internal treasury valuations. Foreign tokens must
     have at least one oracle and each oneToken instance must select exactly one approved oracle.
     */

    struct ForeignToken {
        bool isCollateral;
        AddressSet.Set oracleSet;
    }

    AddressSet.Set foreignTokenSet;
    mapping(address => ForeignToken) foreignTokens;

    /**
     * Events
     */

    event OneTokenDeployed(address sender, address newOneTokenProxy, string name, string symbol, address governance, address version, address controller, address mintMaster, address oneTokenOracle, address memberToken, address collateral);
    event OneTokenAdmin(address sender, address newOneTokenProxy, address proxyAdmin);
    event ModuleAdmitted(address sender, address module, ModuleType moduleType, string name, string url);
    event ModuleUpdated(address sender, address module, string name, string url);
    event ModuleRemoved(address sender, address module);
    event ForeignTokenAdmitted(address sender, address foreignToken, bool isCollateral, address oracle);
    event ForeignTokenUpdated(address sender, address foreignToken, bool isCollateral);
    event ForeignTokenRemoved(address sender, address foreignToken);
    event AddOracle(address sender, address foreignToken, address oracle);
    event RemoveOracle(address sender, address foreignToken, address oracle);

    /**
     @notice factory governance can deploy a oneToken instance via new proxy using existing deployed implementation
     @dev the new uninitialized instance has a finalized deployment address and is owned by the factory
     @param name ERC20 token name
     @param symbol ERC20 token symbol
     @param governance address that will control admin functions in the oneToken instance
     @param version address of a oneToken deployed implementation that emits the expected fingerprint
     @param controller deployed controller must be registered
     @param mintMaster deployed mintMaster must be registered
     @param oneTokenOracle deployed oracle must be registered and will be used to check the oneToken peg     
     @param memberToken deployed ERC20 contract must be registered with at least one associated oracle
     @param collateral deployed ERC20 contract must be registered with at least one associated oracle
     */
    function deployOneTokenProxy(
        string memory name,
        string memory symbol,
        address governance,
        address version,
        address controller,
        address mintMaster,
        address oneTokenOracle,
        address memberToken,
        address collateral
    )
        external
        onlyOwner
        override
        returns(address newOneTokenProxy, address proxyAdmin)
    {
        // no null values
        require(bytes(name).length > 0, "OneTokenFactory: token name is required");
        require(bytes(symbol).length > 0, "OneTokenfactory: token symbol is required");
        require(governance != NULL_ADDRESS, "OneTokenFactory: governance address is required");

        // confirm the modules are compatible and approved
        require(isModule(version), "OneTokenFactory: version is not approved");
        require(isModule(controller), "OneTokenFactory: controller is not approved");
        require(isModule(mintMaster), "OneTokenFactory: mintMaster is not approved");
        require(isModule(oneTokenOracle), "OneTokenFactory: oneTokenOracle is not approved");
        require(isValidModuleType(version, ModuleType.Version), "OneTokenFactory: version, wrong MODULE_TYPE");
        require(isValidModuleType(controller, InterfaceCommon.ModuleType.Controller), "OneTokenFactory: controller, wrong MODULE_TYPE");
        require(isValidModuleType(mintMaster, InterfaceCommon.ModuleType.MintMaster), "OneTokenFactory: mintMaster, wrong MODULE_TYPE");
        require(isValidModuleType(oneTokenOracle, ModuleType.Oracle), "OneTokenFactory: oneTokenOracle, wrong MODULE_TYPE");

        // confirm the tokens are compatible and approved
        require(foreignTokenSet.exists(memberToken), "OneTokenFactory: unknown member token");
        require(foreignTokenSet.exists(collateral), "OneTokenFactory: unknown collateral");
        require(foreignTokens[collateral].isCollateral, "OneTokenFactory: specified token is not recognized as collateral");
        require(IERC20Extended(collateral).decimals() <= 18, "OneTokenFactory: collateral with +18 decimals precision is not supported");

        // deploy a proxy admin and assign ownership to governance
        OneTokenProxyAdmin _admin = new OneTokenProxyAdmin();
        _admin.transferOwnership(governance);
        proxyAdmin = address(_admin);

        // deploy a proxy that delegates to the version
        OneTokenProxy _proxy = new OneTokenProxy(version, address(_admin), NULL_DATA);
        newOneTokenProxy = address(_proxy);

        // record the proxyAdmin for the oneToken proxy
        oneTokenProxyAdmins[newOneTokenProxy] = address(proxyAdmin);

        // admit the oneToken so it has permission to run the needed initializations
        admitForeignToken(newOneTokenProxy, true, oneTokenOracle);
        oneTokenSet.insert(newOneTokenProxy, "OneTokenFactory: Internal error registering initialized oneToken.");

        // initialize the implementation
        IOneTokenV1 oneToken = IOneTokenV1(newOneTokenProxy);
        oneToken.init(name, symbol, oneTokenOracle, controller, mintMaster, memberToken, collateral);

        // transfer oneToken ownership to governance
        oneToken.transferOwnership(governance);

        emitDeploymentEvent(newOneTokenProxy, name, symbol, governance, version, controller, mintMaster, oneTokenOracle, memberToken, collateral);
        emit OneTokenAdmin(msg.sender, newOneTokenProxy, proxyAdmin);
    }

    function emitDeploymentEvent(
        address proxy, string memory name, string memory symbol, address governance, address version, address controller, address mintMaster, address oneTokenOracle, address memberToken, address collateral) private {
        emit OneTokenDeployed(msg.sender, proxy, name, symbol, governance, version, controller, mintMaster, oneTokenOracle, memberToken, collateral);
    }

    /**
     * Govern Modules
     */

    /**
     @notice factory governance can register a module
     @param module deployed module must not be registered and must emit the expected fingerprint
     @param moduleType the type number of the module type
     @param name descriptive module information has no bearing on logic
     @param url optionally point to human-readable operational description
     */
    function admitModule(address module, ModuleType moduleType, string memory name, string memory url) external onlyOwner override {
        require(isValidModuleType(module, moduleType), "OneTokenFactory: invalid fingerprint for module type");
        if(moduleType != ModuleType.Version) {
            require(IModule(module).oneTokenFactory() == address(this), "OneTokenFactory: module is not bound to this factory.");
        }
        moduleSet.insert(module, "OneTokenFactory, Set: module is already admitted.");
        updateModule(module, name, url);
        modules[module].moduleType = moduleType;
        emit ModuleAdmitted(msg.sender, module, moduleType, name, url);
    }

    /**
     @notice factory governance can update module metadata
     @param module deployed module must be registered. moduleType cannot be changed
     @param name descriptive module information has no bearing on logic
     @param url optionally point to human-readable operational description
     */
    function updateModule(address module, string memory name, string memory url) public onlyOwner override {
        require(moduleSet.exists(module), "OneTokenFactory, Set: unknown module");
        modules[module].name = name;
        modules[module].url = url;
        emit ModuleUpdated(msg.sender, module, name, url);
    }

    /**
     @notice factory governance can de-register a module
     @dev de-registering has no effect on oneTokens that use the module
     @param module deployed module must be registered
     */
    function removeModule(address module) external onlyOwner override  {
        require(moduleSet.exists(module), "OneTokenFactory, Set: unknown module");
        delete modules[module];
        moduleSet.remove(module, "OneTokenFactory, Set: unknown module");
        emit ModuleRemoved(msg.sender, module);
    }

    /**
     * Govern foreign tokens
     */

    /**
     @notice factory governance can add a foreign token to the inventory
     @param foreignToken ERC20 contract must not be registered
     @param collateral set true if the asset is considered a collateral token
     @param oracle must be at least one USD oracle for every asset so supply the first one for the new asset
     */
    function admitForeignToken(address foreignToken, bool collateral, address oracle) public onlyOwner override {
        require(isModule(oracle), "OneTokenFactory: oracle is not registered.");
        require(isValidModuleType(oracle, ModuleType.Oracle), "OneTokenFactory, Set: unknown oracle");
        IOracle o = IOracle(oracle);
        o.init(foreignToken);
        o.update(foreignToken);
        foreignTokenSet.insert(foreignToken, "OneTokenFactory: foreign token is already admitted");
        ForeignToken storage f = foreignTokens[foreignToken];
        f.isCollateral = collateral;
        f.oracleSet.insert(oracle, "OneTokenFactory, Set: Internal error inserting oracle.");
        emit ForeignTokenAdmitted(msg.sender, foreignToken, collateral, oracle);
    }

    /**
     @notice factory governance can update asset metadata
     @dev changes do not affect classification in existing oneToken instances
     @param foreignToken ERC20 address, asset to update
     @param collateral set to true to include in collateral
     */
    function updateForeignToken(address foreignToken, bool collateral) external onlyOwner override {
        require(foreignTokenSet.exists(foreignToken), "OneTokenFactory, Set: unknown foreign token");
        ForeignToken storage f = foreignTokens[foreignToken];
        f.isCollateral = collateral;
        emit ForeignTokenUpdated(msg.sender, foreignToken, collateral);
    }

    /**
     @notice factory governance can de-register a foreignToken
     @dev de-registering prevents future assignment but has no effect on existing oneToken instances that rely on the foreignToken
    @param foreignToken the ERC20 contract address to de-register
     */
    function removeForeignToken(address foreignToken) external onlyOwner override {
        require(foreignTokenSet.exists(foreignToken), "OneTokenFactory, Set: unknown foreign token");
        delete foreignTokens[foreignToken];
        foreignTokenSet.remove(foreignToken, "OneTokenfactory, Set: internal error removing foreign token");
        emit ForeignTokenRemoved(msg.sender, foreignToken);
    }

    /**
     @notice factory governance can assign an oracle to foreign token
     @dev foreign tokens have 1-n registered oracle options which are selected by oneToken instance governance
     @param foreignToken ERC20 contract address must be registered already
     @param oracle USD oracle must be registered. Oracle must return quote in a registered collateral (USD) token.
     */
    function assignOracle(address foreignToken, address oracle) external onlyOwner override {
        require(foreignTokenSet.exists(foreignToken), "OneTokenFactory: unknown foreign token");
        require(isModule(oracle), "OneTokenFactory: oracle is not registered.");
        require(isValidModuleType(oracle, ModuleType.Oracle), "OneTokenFactory: Internal error checking oracle");
        IOracle o = IOracle(oracle);
        o.init(foreignToken);
        o.update(foreignToken);
        require(foreignTokens[o.indexToken()].isCollateral, "OneTokenFactory: Oracle Index Token is not registered collateral");
        foreignTokens[foreignToken].oracleSet.insert(oracle, "OneTokenFactory, Set: oracle is already assigned to foreign token.");
        emit AddOracle(msg.sender, foreignToken, oracle);
    }

    /**
     @notice factory can decommission an oracle associated with a particular asset
     @dev unassociating the oracle with a given asset prevents assignment but does not affect oneToken instances that use it
     @param foreignToken the ERC20 contract to disassociate with the oracle
     @param oracle the oracle to remove from the foreignToken
     */
    function removeOracle(address foreignToken, address oracle) external onlyOwner override {
        foreignTokens[foreignToken].oracleSet.remove(oracle, "OneTokenFactory, Set: oracle is not assigned to foreign token or unknown foreign token.");
        emit RemoveOracle(msg.sender, foreignToken, oracle);
    }

    /**
     * View functions
     */

    /**
     @notice returns the count of deployed and initialized oneToken instances
     */
    function oneTokenCount() external view override returns(uint256) {
        return oneTokenSet.count();
    }

    /**
     @notice returns the address of the deployed/initialized oneToken instance at the index
     @param index row to inspect
     */
    function oneTokenAtIndex(uint256 index) external view override returns(address) {
        return oneTokenSet.keyAtIndex(index);
    }

    /**
     @notice return true if given address is a deployed and initialized oneToken instance
     @param oneToken oneToken to inspect
     */
    function isOneToken(address oneToken) external view override returns(bool) {
        return oneTokenSet.exists(oneToken);
    }

    // modules

    /**
     @notice returns the count of the registered modules
     */
    function moduleCount() external view override returns(uint256) {
        return moduleSet.count();
    }

    /**
     @notice returns the address of the registered module at the index
     @param index row to inspect
     */
    function moduleAtIndex(uint256 index) external view override returns(address module) {
        return moduleSet.keyAtIndex(index);
    }

    /**
     @notice returns true the given address is a registered module
     @param module module to inspect     
     */
    function isModule(address module) public view override returns(bool) {
        return moduleSet.exists(module);
    }

    /**
     @notice returns true the address given is a registered module of the expected type
     @param module module to inspect  
     @param moduleType module type to confirm
     */
    function isValidModuleType(address module, ModuleType moduleType) public view override returns(bool) {
        IModule m = IModule(module);
        bytes32 candidateSelfDeclaredType = m.MODULE_TYPE();

        // Does the implementation claim to match the expected type?

        if(moduleType == ModuleType.Version) {
            if(candidateSelfDeclaredType == COMPONENT_VERSION) return true;
        }
        if(moduleType == ModuleType.Controller) {
            if(candidateSelfDeclaredType == COMPONENT_CONTROLLER) return true;
        }
        if(moduleType == ModuleType.Strategy) {
            if(candidateSelfDeclaredType == COMPONENT_STRATEGY) return true;
        }
        if(moduleType == ModuleType.MintMaster) {
            if(candidateSelfDeclaredType == COMPONENT_MINTMASTER) return true;
        }
        if(moduleType == ModuleType.Oracle) {
            if(candidateSelfDeclaredType == COMPONENT_ORACLE) return true;
        }
        return false;
    }

    // foreign tokens

    /**
     @notice returns count of foreignTokens registered with the factory
     @dev includes memberTokens, otherTokens and collateral tokens but not oneTokens
     */
    function foreignTokenCount() external view override returns(uint256) {
        return foreignTokenSet.count();
    }

    /**
     @notice returns the address of the foreignToken at the index
     @param index row to inspect
     */
    function foreignTokenAtIndex(uint256 index) external view override returns(address) {
        return foreignTokenSet.keyAtIndex(index);
    }

    /**
     @notice returns foreignToken metadata for the given foreignToken
     @param foreignToken token to inspect
     */
    function foreignTokenInfo(address foreignToken) external view override returns(bool collateral, uint256 oracleCount) {
        ForeignToken storage f = foreignTokens[foreignToken];
        collateral = f.isCollateral;
        oracleCount = f.oracleSet.count();
    }

    /**
     @notice returns the count of oracles registered for the given foreignToken
     @param foreignToken token to inspect
     */
    function foreignTokenOracleCount(address foreignToken) external view override returns(uint256) {
        return foreignTokens[foreignToken].oracleSet.count();
    }

    /**
     @notice returns the foreignToken oracle address at the index
     @param foreignToken token to inspect
     @param index oracle row to inspect     
     */
    function foreignTokenOracleAtIndex(address foreignToken, uint256 index) external view override returns(address) {
        return foreignTokens[foreignToken].oracleSet.keyAtIndex(index);
    }

    /**
     @notice returns true if the given oracle address is associated with the foreignToken
     @param foreignToken token to inspect
     @param oracle oracle to inspect
     */
    function isOracle(address foreignToken, address oracle) external view override returns(bool) {
        return foreignTokens[foreignToken].oracleSet.exists(oracle);
    }

    /**
     @notice returns true if the given foreignToken is registered in the factory
     @param foreignToken token to inspect     
     */
    function isForeignToken(address foreignToken) external view override returns(bool) {
        return foreignTokenSet.exists(foreignToken);
    }

    /**
     @notice returns true if the given foreignToken is marked collateral
     @param foreignToken token to inspect     
     */
    function isCollateral(address foreignToken) external view override returns(bool) {
        return foreignTokens[foreignToken].isCollateral;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./_openzeppelin/proxy/TransparentUpgradeableProxy.sol";

contract OneTokenProxy is TransparentUpgradeableProxy {

    constructor (address _logic, address admin_, bytes memory _data) 
        TransparentUpgradeableProxy(_logic, admin_, _data) {
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./_openzeppelin/proxy/ProxyAdmin.sol";

contract OneTokenProxyAdmin is ProxyAdmin {}

// SPDX-License-Identifier: MIT

/**
 * @dev Constructor visibility has been removed from the original
 */

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

/**
 * @dev Constructor visibility has been removed from the original
 */

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

/**
 * @dev Constructor visibility has been removed from the original
 */


pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

/**
 @notice for library testing only
 @dev this is not part of the production system and can (should be) removed.
 */

import "../lib/AddressSet.sol";

contract SetTest {

    using AddressSet for AddressSet.Set;
    AddressSet.Set set;

    function count() public view returns(uint256) {
        return set.count();
    }

    function insert(address a, string memory errorMsg) public {
        set.insert(a, errorMsg);
    }

    function remove(address a, string memory errorMsg) public {
        set.remove(a, errorMsg);
    }

    function keyAtIndex(uint256 i) public view returns(address) {
        return set.keyAtIndex(i);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../ControllerCommon.sol";

contract NullController is ControllerCommon {

    /**
     @notice this controller implementation supports the interface but does not intervene in any way
     @dev the controller implementation can be extended but must implement the minimum interface
     */
    constructor(address oneTokenFactory_)
       ControllerCommon(oneTokenFactory_, "Null Controller")
     {} 

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../MintMasterCommon.sol";
import "../../interface/IOneTokenV1.sol";
import "../../interface/IOracle.sol";

/**
 * @notice Multi-tenant implementation with parameters managed by separate governing authorities.
 */

contract Incremental is MintMasterCommon {
    
    uint256 constant DEFAULT_RATIO = 10 ** 18; // 100%
    uint256 constant DEFAULT_STEP_SIZE = 0;
    uint256 constant DEFAULT_MAX_ORDER_VOLUME = INFINITE;

    struct Parameters {
        bool set;
        uint256 minRatio;
        uint256 maxRatio;
        uint256 stepSize;
        uint256 lastRatio;  
        uint256 maxOrderVolume;    
    }

    uint256 lastUpdatedBlock;

    mapping(address => Parameters) public parameters;

    event OneTokenOracleChanged(address sender, address oneToken, address oracle);
    event SetParams(address sender, address oneToken, uint256 minRatio, uint256 maxRatio, uint256 stepSize, uint256 initialRatio, uint256 maxOrderVolume);
    event UpdateMintingRatio(address sender, address oneToken, uint256 newRatio, uint256 maxOrderVolume);
    event StepSizeSet(address sender, address oneToken, uint256 stepSize);
    event MinRatioSet(address sender, address oneToken, uint256 minRatio);
    event MaxRatioSet(address sender, address oneToken, uint256 maxRatio);
    event RatioSet(address sender, address oneToken, uint256 ratio);
   
    constructor(address oneTokenFactory_, string memory description_) 
        MintMasterCommon(oneTokenFactory_, description_) {}

    /**
     @notice initializes the common interface with parameters managed by msg.sender, usually a oneToken.
     @dev A single instance can be shared by n oneToken implementations. Initialize from each instance. Re-initialization is acceptabe.
     @param oneTokenOracle gets the exchange rate of the oneToken
     */
    function init(address oneTokenOracle) external onlyKnownToken override {
        _setParams(msg.sender, DEFAULT_RATIO, DEFAULT_RATIO, DEFAULT_STEP_SIZE, DEFAULT_RATIO, DEFAULT_MAX_ORDER_VOLUME);
        _initMintMaster(msg.sender, oneTokenOracle);
        lastUpdatedBlock = block.number;
        emit MintMasterInitialized(msg.sender, msg.sender, oneTokenOracle);
    }

    /**
     @notice changes the oracle used to assess the oneTokens' value in relation to the peg
     @dev may use the peggedOracle (efficient but not informative) or an active oracle 
     @param oneToken oneToken vault (also ERC20 token)
     @param oracle oracle contract must be registered in the factory
     */
    function changeOracle(address oneToken, address oracle) external onlyTokenOwner(oneToken) {
        require(IOneTokenFactory(oneTokenFactory).isOracle(oneToken, oracle), "Incremental: oracle is not approved for oneToken");
        _initMintMaster(oneToken, oracle);      
        emit OneTokenOracleChanged(msg.sender, oneToken, oracle);
    }

    /**
     @notice updates parameters for a given oneToken that uses this module
     @dev inspects the oneToken implementation to establish authority
     @param oneToken token context for parameters
     @param minRatio minimum minting ratio that will be set
     @param maxRatio maximum minting ratio that will be set
     @param stepSize adjustment size iteration
     @param initialRatio unadjusted starting minting ratio
     */
    function setParams(
        address oneToken, 
        uint256 minRatio, 
        uint256 maxRatio, 
        uint256 stepSize, 
        uint256 initialRatio,
        uint256 maxOrderVolume
    ) 
        external
        onlyTokenOwner(oneToken)
    {
        _setParams(oneToken, minRatio, maxRatio, stepSize, initialRatio, maxOrderVolume);
    }

    function _setParams(
        address oneToken, 
        uint256 minRatio, 
        uint256 maxRatio, 
        uint256 stepSize, 
        uint256 initialRatio,
        uint256 maxOrderVolume
    ) 
        private
    {
        Parameters storage p = parameters[oneToken];
        require(minRatio <= maxRatio, "Incremental: minRatio must be <= maxRatio");
        require(maxRatio <= PRECISION, "Incremental: maxRatio must be <= 10 ** 18");
        // Can be zero to prevent movement
        // require(stepSize > 0, "Incremental: stepSize must be > 0");
        require(stepSize < maxRatio - minRatio || stepSize == 0, "Incremental: stepSize must be < (max - min) or zero.");
        require(initialRatio >= minRatio, "Incremental: initial ratio must be >= min ratio.");
        require(initialRatio <= maxRatio, "Incremental: initial ratio must be <= max ratio.");
        p.minRatio = minRatio;
        p.maxRatio = maxRatio;
        p.stepSize = stepSize;
        p.lastRatio = initialRatio;
        p.maxOrderVolume = maxOrderVolume;
        p.set = true;
        emit SetParams(msg.sender, oneToken, minRatio, maxRatio, stepSize, initialRatio, maxOrderVolume);
    }
 
    /**
     @notice returns an adjusted minting ratio
     @dev oneToken contracts call this to get their own minting ratio
     // collateralToken argument in the interface supports future-use cases
     @param ratio the minting ratio
     @param maxOrderVolume recommended maximum order size, specified by governance. Defaults to unlimited
     */
    function getMintingRatio(address /* collateralToken */) external view override returns(uint256 ratio, uint256 maxOrderVolume) {
        return getMintingRatio2(msg.sender, NULL_ADDRESS);
    }

    /**
     @notice returns an adjusted minting ratio. OneTokens use this function and it relies on initialization to select the oracle
     @dev anyone calls this to inspect any oneToken minting ratio based on the oracle chosen at initialization
     @param oneToken oneToken implementation to inspect
     // collateralToken argument in the interface supports future-use cases
     @param ratio the minting ratio
     @param maxOrderVolume recommended maximum order size, specified by governance. Defaults to unlimited     
     */    

    function getMintingRatio2(address oneToken, address /* collateralToken */) public view override returns(uint256 ratio, uint256 maxOrderVolume) {
        address oracle = oneTokenOracles[oneToken];
        return getMintingRatio4(oneToken, oracle, NULL_ADDRESS, NULL_ADDRESS);
    }

    /**
     @notice returns an adjusted minting ratio
     @dev anyone calls this to inspect any oneToken minting ratio based on arbitry oracles
     @param oneToken oneToken implementation to inspect
     @param oneTokenOracle explicit oracle selection
     // collateralToken argument in the interface supports future-use cases
     @param ratio the minting ratio
     @param maxOrderVolume recommended maximum order size, specified by governance. Defaults to unlimited     
     */   
    function getMintingRatio4(address oneToken, address oneTokenOracle, address /* collateralToken */, address /* collateralOracle */) public override view returns(uint256 ratio, uint256 maxOrderVolume) {
        Parameters storage p = parameters[oneToken];
        require(p.set, "Incremental: mintmaster is not initialized");
        
        // Both OneToken and oracle response are in precision 18. No conversion is necessary.
        (uint256 quote, /* uint256 volatility */ ) = IOracle(oneTokenOracle).read(oneToken, PRECISION);
        ratio = p.lastRatio;        
        if(quote == PRECISION) return(ratio, p.maxOrderVolume);
        uint256 stepSize = p.stepSize;
        maxOrderVolume = p.maxOrderVolume;
        if(quote < PRECISION && ratio < p.maxRatio) {
            ratio += stepSize;
            if (ratio > p.maxRatio) {
                ratio = p.maxRatio;
            }
        }
        if(quote > PRECISION && ratio > p.minRatio) {
            ratio -= stepSize;
            if (ratio < p.minRatio) {
                ratio = p.minRatio;
            }
        }
    }

    /**
     @notice records and returns an adjusted minting ratio for a oneToken implemtation
     @dev oneToken implementations calls this periodically, e.g. in the minting process
     // collateralToken argument in the interface supports future-use cases
     @param ratio the minting ratio
     @param maxOrderVolume recommended maximum order size, specified by governance. Defaults to unlimited
     */
    function updateMintingRatio(address /* collateralToken */) external override returns(uint256 ratio, uint256 maxOrderVolume) {
        if (lastUpdatedBlock >= block.number) {
            (ratio, maxOrderVolume) = getMintingRatio2(msg.sender, NULL_ADDRESS);
        } else {
            lastUpdatedBlock = block.number;
            return _updateMintingRatio(msg.sender, NULL_ADDRESS);
        }
    }

    /**
     @notice records and returns an adjusted minting ratio for a oneToken implemtation
     @dev internal use only
     @param oneToken the oneToken implementation to evaluate
     // collateralToken argument in the interface supports future-use cases
     @param ratio the minting ratio
     @param maxOrderVolume recommended maximum order size, specified by governance. Defaults to unlimited
     */    
    function _updateMintingRatio(address oneToken, address /* collateralToken */) private returns(uint256 ratio, uint256 maxOrderVolume) {
        Parameters storage p = parameters[oneToken];
        require(p.set, "Incremental: mintmaster is not initialized");
        address o = oneTokenOracles[oneToken];
        IOracle(o).update(oneToken);
        (ratio, maxOrderVolume) = getMintingRatio2(oneToken, NULL_ADDRESS);
        p.lastRatio = ratio;
        emit UpdateMintingRatio(msg.sender, oneToken, ratio, maxOrderVolume);
    }

    /**
     * Governance functions
     */

    /**
     @notice adjusts the rate of minting ratio change
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     @param oneToken the implementation to work with
     @param stepSize the step size must be smaller than the difference of min and max
     */
    function setStepSize(address oneToken, uint256 stepSize) external onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(stepSize < p.maxRatio - p.minRatio || stepSize == 0, "Incremental: stepSize must be < (max - min) or zero.");
        p.stepSize = stepSize;
        emit StepSizeSet(msg.sender, oneToken, stepSize);
    }

    /**
     @notice sets the minimum minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     if the new minimum is higher than current minting ratio, the current ratio will be adjusted to minRatio
     @param oneToken the implementation to work with
     @param minRatio the new lower bound for the minting ratio
     */    
    function setMinRatio(address oneToken, uint256 minRatio) external onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(minRatio <= p.maxRatio, "Incremental: minRatio must be <= maxRatio");
        require(p.stepSize < p.maxRatio - minRatio || p.stepSize == 0, "Incremental: stepSize must be < (max - min) or zero.");
        p.minRatio = minRatio;
        if(minRatio > p.lastRatio) setRatio(oneToken, minRatio);
        emit MinRatioSet(msg.sender, oneToken, minRatio);
    }

    /**
     @notice sets the maximum minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     if the new maximum is lower is than current minting ratio, the current ratio will be set to maxRatio
     @param oneToken the implementation to work with
     @param maxRatio the new upper bound for the minting ratio
     */ 
    function setMaxRatio(address oneToken, uint256 maxRatio) external onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(maxRatio >= p.minRatio, "Incremental: maxRatio must be >= minRatio");
        require(maxRatio <= PRECISION, "Incremental: maxRatio must <= 100%");
        require(p.stepSize < maxRatio - p.minRatio || p.stepSize == 0, "Incremental: stepSize must be < (max - min) or zero.");
        p.maxRatio = maxRatio;
        if(maxRatio < p.lastRatio) setRatio(oneToken, maxRatio);
        emit MaxRatioSet(msg.sender, oneToken, maxRatio);
    }

    /**
     @notice sets the current minting ratio
     @dev only the governance that owns the token implentation can adjust the mintMaster's parameters
     @param oneToken the implementation to work with
     @param ratio must be in the min-max range
     */
    function setRatio(address oneToken, uint256 ratio) public onlyTokenOwner(oneToken) {
        Parameters storage p = parameters[oneToken];
        require(ratio > 0, "Incremental: ratio must be > 0");
        require(ratio <= PRECISION, "Incremental: ratio must be <= 100%");
        require(ratio >= p.minRatio, "Incremental: ratio must be >= minRatio");
        require(ratio <= p.maxRatio, "Incremental: ratio must be <= maxRatio");
        p.lastRatio = ratio;
        emit RatioSet(msg.sender, oneToken, ratio);
    }

}

// SPDX-License-Identifier: ISC

pragma solidity =0.7.6;

import './libraries/UQ112x112.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import "./libraries/UniSafeMath.sol";
import "../../../_openzeppelin/token/ERC20/IERC20.sol";

contract UniswapV2Pair is IUniswapV2Pair {
    using UniSafeMath  for uint256;
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public _token0;
    address public _token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public _price0CumulativeLast;
    uint256 public _price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address __token0, address __token1) override external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN');
        // sufficient check
        _token0 = __token0;
        _token1 = __token1;
    }

    function getReserves() override public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function token0() override external view returns (address){
        return _token0;
    }
    function token1() override external view returns (address){
        return _token1;
    }

    function price0CumulativeLast() override external view returns (uint256){
        return _price0CumulativeLast;
    }
    function price1CumulativeLast() override external view returns (uint256){
        return _price1CumulativeLast;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            _price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            _price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // force reserves to match balances
    function sync() override external {
        _update(IERC20(_token0).balanceOf(address(this)), IERC20(_token1).balanceOf(address(this)), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity =0.7.6;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: GNU

pragma solidity =0.7.6;

interface IUniswapV2Pair {
//    event Approval(address indexed owner, address indexed spender, uint256 value);
//    event Transfer(address indexed from, address indexed to, uint256 value);

//    function name() external pure returns (string memory);
//    function symbol() external pure returns (string memory);
//    function decimals() external pure returns (uint8);
//    function totalSupply() external view returns (uint256);
//    function balanceOf(address owner) external view returns (uint256);
//    function allowance(address owner, address spender) external view returns (uint256);
//
//    function approve(address spender, uint256 value) external returns (bool);
//    function transfer(address to, uint256 value) external returns (bool);
//    function transferFrom(address from, address to, uint256 value) external returns (bool);

//    function DOMAIN_SEPARATOR() external view returns (bytes32);
//    function PERMIT_TYPEHASH() external pure returns (bytes32);
//    function nonces(address owner) external view returns (uint256);
//
//    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
//
//    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
//    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
//    event Swap(
//        address indexed sender,
//        uint256 amount0In,
//        uint256 amount1In,
//        uint256 amount0Out,
//        uint256 amount1Out,
//        address indexed to
//    );
    event Sync(uint112 reserve0, uint112 reserve1);

//    function MINIMUM_LIQUIDITY() external pure returns (uint256);
//    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
//    function kLast() external view returns (uint256);
//
//    function mint(address to) external returns (uint256 liquidity);
//    function burn(address to) external returns (uint256 amount0, uint256 amount1);
//    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
//    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GNU

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
//    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

//    function feeTo() external view returns (address);
//    function feeToSetter() external view returns (address);
//
//    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: ISC

pragma solidity =0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library UniSafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GNU

pragma solidity 0.7.6;

import '../../../v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../../../v2-core/contracts/UniswapV2Pair.sol';

import "./UniswapSafeMath.sol";

library UniswapV2Library {
    using UniswapSafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function getInitHash() public pure returns (bytes32){
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                getInitHash()
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GNU

/**
 * @dev this contract is renamed to prevent conflict with oz while avoiding significant changes 
 */

pragma solidity 0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library UniswapSafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GNU

/// @notice adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

pragma solidity 0.7.6;

import "../OracleCommon.sol";
import "../../_openzeppelin/math/SafeMath.sol";
import '../../_uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '../../_uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../../_uniswap/lib/contracts/libraries/FixedPoint.sol';
import '../../_uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol';
import '../../_uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';

/**
 @notice A fixed-window oracle that recomputes the average price for the entire period once every period,
 Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period,
 Periodicity is fixed at deployment time. Index (usually USD) token is fixed at deployment time.
 A single deployment can be shared by multiple oneToken clients and can observe multiple base tokens.
 Non-USD index tokens are possible. Such deployments can used as interim oracles in Composite Oracles. They should
 NOT be registered because they are not, by definition, valid sources of USD quotes.
 */

contract UniswapOracleSimple is OracleCommon {
    using FixedPoint for *;
    using SafeMath for uint256;

    uint256 public immutable PERIOD;
    address public immutable uniswapFactory;

    struct Pair {
        address token0;
        address token1;
        uint256    price0CumulativeLast;
        uint256    price1CumulativeLast;
        uint32  blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    mapping(address => Pair) pairs;

    /**
     @notice the indexToken (index token), averaging period and uniswapfactory cannot be changed post-deployment
     @dev deploy multiple instances to support different configurations
     @param oneTokenFactory_ oneToken factory to bind to
     @param uniswapFactory_ external factory contract needed by the uniswap library
     @param indexToken_ the index token to use for valuations. If not a usd collateral token then the Oracle should not be registered in the factory but it can be used by CompositeOracles.
     @param period_ the averaging period to use for price smoothing
     */
    constructor(address oneTokenFactory_, address uniswapFactory_, address indexToken_, uint256 period_)
        OracleCommon(oneTokenFactory_, "ICHI Simple Uniswap Oracle", indexToken_)
    {
        require(uniswapFactory_ != NULL_ADDRESS, "UniswapOracleSimple: uniswapFactory cannot be empty");
        require(period_ > 0, "UniswapOracleSimple: period must be > 0");
        uniswapFactory = uniswapFactory_;
        PERIOD = period_;
        indexToken = indexToken_;
    }

    /**
     @notice configures parameters for a pair, token versus indexToken
     @dev initializes the first time, then does no work. Initialized from the Factory when assigned to an asset.
     @param token the base token. index is established at deployment time and cannot be changed
     */
    function init(address token) external onlyModuleOrFactory override {
        require(token != NULL_ADDRESS, "UniswapOracleSimple: token cannot be null");
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        // this condition should never be false
        require(address(_pair) != NULL_ADDRESS, "UniswapOracleSimple: unknown pair");
        Pair storage p = pairs[address(_pair)];
        if(p.token0 == NULL_ADDRESS) {
            p.token0 = _pair.token0();
            p.token1 = _pair.token1();
            p.price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
            p.price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
            uint112 reserve0;
            uint112 reserve1;
            (reserve0, reserve1, p.blockTimestampLast) = _pair.getReserves();
            require(reserve0 != 0 && reserve1 != 0, 'UniswapOracleSimple: NO_RESERVES'); // ensure that there's liquidity in the pair
            emit OracleInitialized(msg.sender, token, indexToken);
        }
    }

    /**
     @notice returns equivalent indexTokens for amountIn, token
     @dev index token is established at deployment time
     @param token ERC20 token
     @param amountTokens quantity, token precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases 
     */
    function read(address token, uint256 amountTokens) external view override returns(uint256 amountUsd, uint256 volatility) {
        amountUsd = tokensToNormalized(indexToken, consult(token, amountTokens));
        volatility = 1;
    }

    /**
     @notice returns equivalent baseTokens for amountUsd, indexToken
     @dev index token is established at deployment time
     @param token ERC20 token
     @param amountTokens quantity, token precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases
     */
    function amountRequired(address token, uint256 amountUsd) external view override returns(uint256 amountTokens, uint256 volatility) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p = pairs[address(_pair)];
        require(token == p.token0 || token == p.token1, 'UniswapOracleSimple: INVALID_TOKEN');
        require(p.price0CumulativeLast > 0, "UniswapOracleSimple: Gathering history. Try again later");
        amountUsd = normalizedToTokens(indexToken, amountUsd);
        amountTokens = (token == p.token0 ? p.price0Average : p.price1Average).reciprocal().mul(amountUsd).decode144();
        volatility = 1;
    }

    /**
     @notice updates price observation history, if necessary
     @dev it is permissible for anyone to supply gas and update the oracle's price history.
     @param token baseToken to update
     */
    function update(address token) external override {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p = pairs[address(_pair)];
        if(p.token0 != NULL_ADDRESS) {
            (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
                UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
            uint32 timeElapsed = blockTimestamp - p.blockTimestampLast; // overflow is desired

            // ensure that at least one full period has passed since the last update
            ///@ dev require() was dropped in favor of if() to make this safe to call when unsure about elapsed time

            if(timeElapsed >= PERIOD) {
                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                p.price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - p.price0CumulativeLast) / timeElapsed));
                p.price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - p.price1CumulativeLast) / timeElapsed));

                p.price0CumulativeLast = price0Cumulative;
                p.price1CumulativeLast = price1Cumulative;
                p.blockTimestampLast = blockTimestamp;
            }
            // No event emitter to save gas
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    // this will return an average over a long period of time unless someone calls the update() function.
    
    /**
     @notice returns equivalent indexTokens for amountIn, token
     @dev always returns 0 before update(token) has been called successfully for the first time.
     @param token baseToken to update
     @param amountTokens amount in token native precision
     @param amountOut anount in tokens, reciprocal token
     */
    function consult(address token, uint256 amountTokens) public view returns (uint256 amountOut) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p = pairs[address(_pair)];
        require(token == p.token0 || token == p.token1, 'UniswapOracleSimple: INVALID_TOKEN');
        require(p.price0CumulativeLast > 0, "UniswapOracleSimple: Gathering history. Try again later");
        amountOut = (token == p.token0 ? p.price0Average : p.price1Average).mul(amountTokens).decode144();
    }

    /**
     @notice discoverable internal state
     @param token baseToken to inspect
     */
    function pairInfo(address token)
        external
        view
        returns
    (
        address token0,
        address token1,
        uint256    price0CumulativeLast,
        uint256    price1CumulativeLast,
        uint256    price0Average,
        uint256    price1Average,
        uint32  blockTimestampLast
    )
    {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p = pairs[address(_pair)];
        return(
            p.token0,
            p.token1,
            p.price0CumulativeLast,
            p.price1CumulativeLast,
            p.price0Average.mul(PRECISION).decode144(),
            p.price1Average.mul(PRECISION).decode144(),
            p.blockTimestampLast
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;

import './FullMath.sol';
import './Babylonian.sol';
import './BitMath.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint256, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: GNU

pragma solidity 0.7.6;

import "./UniswapV2Library.sol";
import '../../../lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
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
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity =0.7.6;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() override external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) override external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) override external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) override external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../StrategyCommon.sol";

contract Arbitrary is StrategyCommon {

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param oneTokenFactory_ bind this instance to oneTokenFactory instance
     @param oneToken_ bind this instance to one oneToken vault
     @param description_ metadata has no impact on logic
     */

    constructor(address oneTokenFactory_, address oneToken_, string memory description_) 
        StrategyCommon(oneTokenFactory_, oneToken_, description_)
    {}


    /**
    @notice Governance can work with collateral and treasury assets. Can swap assets.
    @param target address/smart contract you are interacting with
    @param value msg.value (amount of eth in WEI you are sending. Most of the time it is 0)
    @param signature the function signature
    @param data abi-encodeded bytecode of the parameter values to send
    */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data) external onlyOwner returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, "OneTokenV1::executeTransaction: Transaction execution reverted.");
        return returnData;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}