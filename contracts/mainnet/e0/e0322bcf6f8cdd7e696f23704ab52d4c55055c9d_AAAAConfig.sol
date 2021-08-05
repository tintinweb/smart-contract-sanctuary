/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// Dependency file: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Dependency file: contracts/modules/ConfigNames.sol

// pragma solidity >=0.5.16;

library ConfigNames {
    //GOVERNANCE
    bytes32 public constant PROPOSAL_VOTE_DURATION = bytes32('PROPOSAL_VOTE_DURATION');
    bytes32 public constant PROPOSAL_EXECUTE_DURATION = bytes32('PROPOSAL_EXECUTE_DURATION');
    bytes32 public constant PROPOSAL_CREATE_COST = bytes32('PROPOSAL_CREATE_COST');
    bytes32 public constant STAKE_LOCK_TIME = bytes32('STAKE_LOCK_TIME');
    bytes32 public constant MINT_AMOUNT_PER_BLOCK =  bytes32('MINT_AMOUNT_PER_BLOCK');
    bytes32 public constant INTEREST_PLATFORM_SHARE =  bytes32('INTEREST_PLATFORM_SHARE');
    bytes32 public constant CHANGE_PRICE_DURATION =  bytes32('CHANGE_PRICE_DURATION');
    bytes32 public constant CHANGE_PRICE_PERCENT =  bytes32('CHANGE_PRICE_PERCENT');

    // POOL
    bytes32 public constant POOL_BASE_INTERESTS = bytes32('POOL_BASE_INTERESTS');
    bytes32 public constant POOL_MARKET_FRENZY = bytes32('POOL_MARKET_FRENZY');
    bytes32 public constant POOL_PLEDGE_RATE = bytes32('POOL_PLEDGE_RATE');
    bytes32 public constant POOL_LIQUIDATION_RATE = bytes32('POOL_LIQUIDATION_RATE');
    bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32('POOL_MINT_BORROW_PERCENT');
    bytes32 public constant POOL_MINT_POWER = bytes32('POOL_MINT_POWER');
    
    //NOT GOVERNANCE
    bytes32 public constant AAAA_USER_MINT = bytes32('AAAA_USER_MINT');
    bytes32 public constant AAAA_TEAM_MINT = bytes32('AAAA_TEAM_MINT');
    bytes32 public constant AAAA_REWAED_MINT = bytes32('AAAA_REWAED_MINT');
    bytes32 public constant DEPOSIT_ENABLE = bytes32('DEPOSIT_ENABLE');
    bytes32 public constant WITHDRAW_ENABLE = bytes32('WITHDRAW_ENABLE');
    bytes32 public constant BORROW_ENABLE = bytes32('BORROW_ENABLE');
    bytes32 public constant REPAY_ENABLE = bytes32('REPAY_ENABLE');
    bytes32 public constant LIQUIDATION_ENABLE = bytes32('LIQUIDATION_ENABLE');
    bytes32 public constant REINVEST_ENABLE = bytes32('REINVEST_ENABLE');
    bytes32 public constant INTEREST_BUYBACK_SHARE =  bytes32('INTEREST_BUYBACK_SHARE');

    //POOL
    bytes32 public constant POOL_PRICE = bytes32('POOL_PRICE');

    //wallet
    bytes32 public constant TEAM = bytes32('team'); 
    bytes32 public constant SPARE = bytes32('spare');
    bytes32 public constant REWARD = bytes32('reward');
}

// Root file: contracts/AAAAConfig.sol

pragma solidity >=0.5.16;
// import "contracts/libraries/SafeMath.sol";
// import 'contracts/modules/ConfigNames.sol';

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function decimals() external view returns (uint8);
}

interface IAAAAPool {
    function collateralToken() external view returns(address);
}

contract AAAAConfig {
    using SafeMath for uint;
    using SafeMath for uint8;
    address public owner;
    address public factory;
    address public platform;
    address public developer;
    address public mint;
    address public token;
    address public share;
    address public base;
    address public governor;
    address public WETH;

    address[] public mintTokenList;

    uint public lastPriceBlock;

    uint public DAY = 6400;
    uint public HOUR = 267;
    
    struct ConfigItem {
        uint min;
        uint max;
        uint span;
        uint value;
    }
    
    mapping (address => mapping (bytes32 => ConfigItem)) public poolParams;
    mapping (bytes32 => ConfigItem) public params;
    mapping (bytes32 => address) public wallets;
    mapping (address => uint) public prices;

    event PriceChange(address token, uint value);
    event ParameterChange(bytes32 key, uint value);
    event PoolParameterChange(address pool, bytes32 key, uint value);
    
    constructor() public {
        owner = msg.sender;
        developer = msg.sender;
        uint id;
        assembly {
            id := chainid()
        }
        if(id != 1) {
            DAY = 28800;
            HOUR = 1200;
        }
    }
    
    function initialize (address _platform, address _factory, address _mint, address _token, address _share, address _governor, address _base, address _WETH) external {
        require(msg.sender == owner || msg.sender == developer, "AAAA: Config FORBIDDEN");
        mint        = _mint;
        platform    = _platform;
        factory     = _factory;
        token       = _token;
        share       = _share;
        governor    = _governor;
        base        = _base;
        WETH        = _WETH;
    }

    function addMintToken(address _token) external {
        require(msg.sender == owner || msg.sender == developer, "AAAA: Config FORBIDDEN");
        mintTokenList.push(_token);
    }

    function isMintToken(address _token) public view returns (bool)  {
        for(uint i = 0;i < mintTokenList.length;i++) {
            if(_token == mintTokenList[i]) {
                return true;
            }
        }
        return false;
    }


    function changeDeveloper(address _developer) external {
        require(msg.sender == owner || msg.sender == developer, "AAAA: Config FORBIDDEN");
        developer = _developer;
    }

    function setWallets(bytes32[] calldata _names, address[] calldata _wallets) external {
        require(msg.sender == owner || msg.sender == developer, "AAAA: ONLY DEVELOPER");
        require(_names.length == _wallets.length ,"AAAA: WALLETS LENGTH MISMATCH");
        for(uint i = 0; i < _names.length; i ++)
        {
            wallets[_names[i]] = _wallets[i];
        }
    }

    function initParameter() external {
        require(msg.sender == owner || msg.sender == developer, "AAAA: Config FORBIDDEN");
        _setParams(ConfigNames.PROPOSAL_VOTE_DURATION ,   1*DAY,  7*DAY , 1*DAY,  1*DAY);
        _setParams(ConfigNames.PROPOSAL_EXECUTE_DURATION, 1*HOUR, 48*HOUR, 1*HOUR, 1*HOUR);
        _setParams(ConfigNames.PROPOSAL_CREATE_COST, 0, 10000 * 1e18, 100 * 1e18, 0);
        _setParams(ConfigNames.STAKE_LOCK_TIME, 0, 7*DAY, 1*DAY, 0);
        _setParams(ConfigNames.MINT_AMOUNT_PER_BLOCK, 0, 10000 * 1e18, 1e17, 1e17);
        _setParams(ConfigNames.INTEREST_PLATFORM_SHARE, 0, 1e18, 1e17, 1e17);
        _setParams(ConfigNames.INTEREST_BUYBACK_SHARE, 10000, 10000, 0, 10000);
        _setParams(ConfigNames.CHANGE_PRICE_DURATION, 0, 500, 100, 0);
        _setParams(ConfigNames.CHANGE_PRICE_PERCENT, 1, 100, 1, 20);

        _setParams(ConfigNames.AAAA_USER_MINT, 0, 0, 0, 3000);
        _setParams(ConfigNames.AAAA_TEAM_MINT, 0, 0, 0, 7142);
        _setParams(ConfigNames.AAAA_REWAED_MINT, 0, 0, 0, 5000);
        _setParams(ConfigNames.DEPOSIT_ENABLE, 0, 0, 0, 1);
        _setParams(ConfigNames.WITHDRAW_ENABLE, 0, 0, 0, 1);
        _setParams(ConfigNames.BORROW_ENABLE, 0, 0, 0, 1);
        _setParams(ConfigNames.REPAY_ENABLE, 0, 0, 0, 1);
        _setParams(ConfigNames.LIQUIDATION_ENABLE, 0, 0, 0, 1);
        _setParams(ConfigNames.REINVEST_ENABLE, 0, 0, 0, 1);
    }

    function initPoolParams(address _pool) external {
        require(msg.sender == factory, "Config FORBIDDEN");
        _setPoolParams(_pool, ConfigNames.POOL_BASE_INTERESTS, 0, 1e18, 1e16, 2e17);
        _setPoolParams(_pool, ConfigNames.POOL_MARKET_FRENZY, 0, 1e18, 1e16, 2e17);
        _setPoolParams(_pool, ConfigNames.POOL_PLEDGE_RATE, 0, 1e18, 1e16, 6e17);
        _setPoolParams(_pool, ConfigNames.POOL_LIQUIDATION_RATE, 0, 1e18, 1e16, 9e17);
        _setPoolParams(_pool, ConfigNames.POOL_MINT_POWER, 0, 0, 0, 10000);
        _setPoolParams(_pool, ConfigNames.POOL_MINT_BORROW_PERCENT, 0, 10000, 1000, 5000);
    }

    function _setPoolValue(address _pool, bytes32 _key, uint _value) internal {
        poolParams[_pool][_key].value = _value;
        emit PoolParameterChange(_pool, _key, _value);
    }

    function _setParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) internal {
        params[_key] = ConfigItem(_min, _max, _span, _value);
        emit ParameterChange(_key, _value);
    }

    function _setPoolParams(address _pool, bytes32 _key, uint _min, uint _max, uint _span, uint _value) internal {
        poolParams[_pool][_key] = ConfigItem(_min, _max, _span, _value);
        emit PoolParameterChange(_pool, _key, _value);
    }

    function _setPrice(address _token, uint _value) internal {
        prices[_token] = _value;
        emit PriceChange(_token, _value);
    }

    function setTokenPrice(address[] calldata _tokens, uint[] calldata _prices) external {
        uint duration = params[ConfigNames.CHANGE_PRICE_DURATION].value;
        uint maxPercent = params[ConfigNames.CHANGE_PRICE_PERCENT].value;
        require(block.number >= lastPriceBlock.add(duration), "AAAA: Price Duration");
        require(msg.sender == wallets[bytes32("price")], "AAAA: Config FORBIDDEN");
        require(_tokens.length == _prices.length ,"AAAA: PRICES LENGTH MISMATCH");

        for(uint i = 0; i < _tokens.length; i++)
        {
            if(prices[_tokens[i]] == 0) {
                _setPrice(_tokens[i], _prices[i]);
            } else {
                uint currentPrice = prices[_tokens[i]];
                if(_prices[i] > currentPrice) {
                    uint maxPrice = currentPrice.add(currentPrice.mul(maxPercent).div(10000));
                    _setPrice(_tokens[i], _prices[i] > maxPrice ? maxPrice: _prices[i]);
                } else {
                    uint minPrice = currentPrice.sub(currentPrice.mul(maxPercent).div(10000));
                    _setPrice(_tokens[i], _prices[i] < minPrice ? minPrice: _prices[i]);
                }
            } 
        }

        lastPriceBlock = block.number;
    }
    
    function setValue(bytes32 _key, uint _value) external {
        require(msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer, "AAAA: ONLY DEVELOPER");
        params[_key].value = _value;
        emit ParameterChange(_key, _value);
    }
    
    function setPoolValue(address _pool, bytes32 _key, uint _value) external {
        require(msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer, "AAAA: FORBIDDEN");
        _setPoolValue(_pool, _key, _value);
    }
    
    function getValue(bytes32 _key) external view returns (uint){
        return params[_key].value;
    }
    
    function getPoolValue(address _pool, bytes32 _key) external view returns (uint) {
        return poolParams[_pool][_key].value;
    } 

    function setParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external {
        require(msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer, "AAAA: FORBIDDEN");
        _setParams(_key, _min, _max, _span, _value);
    }

    function setPoolParams(address _pool, bytes32 _key, uint _min, uint _max, uint _span, uint _value) external {
        require(msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer, "AAAA: FORBIDDEN");
        _setPoolParams(_pool, _key, _min, _max, _span, _value);
    }

    function getParams(bytes32 _key) external view returns (uint, uint, uint, uint) {
        ConfigItem memory item = params[_key];
        return (item.min, item.max, item.span, item.value);
    }

    function getPoolParams(address _pool, bytes32 _key) external view returns (uint, uint, uint, uint) {
        ConfigItem memory item = poolParams[_pool][_key];
        return (item.min, item.max, item.span, item.value);
    }

    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns(uint toAmount) {
        uint fromPrice = prices[_fromToken];
        uint toPrice = prices[_toToken];
        uint8 fromDecimals = IERC20(_fromToken).decimals();
        uint8 toDecimals = IERC20(_toToken).decimals();
        toAmount = _fromAmount.mul(fromPrice).div(toPrice);
        if(fromDecimals > toDecimals) {
            toAmount = toAmount.div(10 ** (fromDecimals.sub(toDecimals)));
        } else if(toDecimals > fromDecimals) {
            toAmount = toAmount.mul(10 ** (toDecimals.sub(fromDecimals)));
        }
    }
}