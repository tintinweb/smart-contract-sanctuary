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

// Root file: contracts/AAAAQuery2.sol

pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

// import "contracts/libraries/SafeMath.sol";
// import 'contracts/modules/ConfigNames.sol';

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function wallet() external view returns (address);
    function base() external view returns (address);
    function share() external view returns (address);
    function params(bytes32 key) external view returns(uint);
    function setParameter(uint[] calldata _keys, uint[] calldata _values) external;
    function setPoolParameter(address _pool, bytes32 _key, uint _value) external;
    function getValue(bytes32 _key) external view returns (uint);
    function getPoolValue(address _pool, bytes32 _key) external view returns (uint);
    function getParams(bytes32 _key) external view returns (uint, uint, uint, uint);
    function getPoolParams(address _pool, bytes32 _key) external view returns (uint, uint, uint, uint);
}

interface IAAAAFactory {
    function countPools() external view returns(uint);
    function countBallots() external view returns(uint);
    function allBallots(uint index) external view returns(address);
    function allPools(uint index) external view returns(address);
    function isPool(address addr) external view returns(bool);
    function getPool(address lend, address collateral) external view returns(address);
}

interface IAAAAPool {
    function supplyToken() external view returns(address);
    function collateralToken() external view returns(address);
    function totalBorrow() external view returns(uint);
    function totalPledge() external view returns(uint);
    function remainSupply() external view returns(uint);
    function getInterests() external view returns(uint);
    function numberBorrowers() external view returns(uint);
    function borrowerList(uint index) external view returns(address);
    function borrows(address user) external view returns(uint,uint,uint,uint,uint);
    function getRepayAmount(uint amountCollateral, address from) external view returns(uint);
    function liquidationHistory(address user, uint index) external view returns(uint,uint,uint);
    function liquidationHistoryLength(address user) external view returns(uint);
    function getMaximumBorrowAmount(uint amountCollateral) external view returns(uint amountBorrow);
    function interestPerBorrow() external view returns(uint);
    function lastInterestUpdate() external view returns(uint);
    function interestPerSupply() external view returns(uint);
    function supplys(address user) external view returns(uint,uint,uint,uint,uint);
}

interface IAAAAMint {
    function maxSupply() external view returns(uint);
    function mintCumulation() external view returns(uint);
    function takeLendWithAddress(address user) external view returns (uint);
    function takeBorrowWithAddress(address user) external view returns (uint);
}

interface ISwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IAAAABallot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal 0 YES, 1 NO
        bool claimed; // already claimed reward
    }
    function name() external view returns(bytes32);
    function subject() external view returns(string memory);
    function content() external view returns(string memory);
    function createdBlock() external view returns(uint);
    function createdTime() external view returns(uint);
    function creator() external view returns(address);
    function proposals(uint index) external view returns(uint);
    function end() external view returns (bool);
    function pass() external view returns (bool);
    function expire() external view returns (bool);
    function pool() external view returns (address);
    function value() external view returns (uint);
    function total() external view returns (uint);
    function reward() external view returns (uint);
    function voters(address user) external view returns (Voter memory);
}

contract AAAAQuery2 {
    address public owner;
    address public config;
    using SafeMath for uint;

    struct ConfigCommonStruct {
        uint PROPOSAL_VOTE_DURATION;
        uint PROPOSAL_EXECUTE_DURATION;
        uint PROPOSAL_CREATE_COST;
        uint STAKE_LOCK_TIME;
        uint MINT_AMOUNT_PER_BLOCK;
        uint INTEREST_PLATFORM_SHARE;
        uint INTEREST_BUYBACK_SHARE;
        uint CHANGE_PRICE_DURATION;
        uint CHANGE_PRICE_PERCENT;
    }

    struct ConfigValueStruct {
        uint min;
        uint max;
        uint span;
        uint value;
        address pair;
        bytes32 key;
        string name;
    }

    struct ConfigPoolStruct {
        address pair;
        address supplyToken;
        address collateralToken;
        uint POOL_BASE_INTERESTS;
        uint POOL_MARKET_FRENZY;
        uint POOL_PLEDGE_RATE;
        uint POOL_LIQUIDATION_RATE;
        uint POOL_MINT_BORROW_PERCENT;
        uint POOL_MINT_POWER;
        address lpToken0;
        address lpToken1;
        string lpToken0Symbol;
        string lpToken1Symbol;
        string supplyTokenSymbol;
        string collateralTokenSymbol;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig (address _config) external {
        require(msg.sender == owner, "FORBIDDEN");
        config = _config;
    }

    function getConfigCommon() public view returns (ConfigCommonStruct memory info){
        info.PROPOSAL_VOTE_DURATION = IConfig(config).getValue(ConfigNames.PROPOSAL_VOTE_DURATION);
        info.PROPOSAL_EXECUTE_DURATION = IConfig(config).getValue(ConfigNames.PROPOSAL_EXECUTE_DURATION);
        info.PROPOSAL_CREATE_COST = IConfig(config).getValue(ConfigNames.PROPOSAL_CREATE_COST);
        info.STAKE_LOCK_TIME = IConfig(config).getValue(ConfigNames.STAKE_LOCK_TIME);
        info.MINT_AMOUNT_PER_BLOCK = IConfig(config).getValue(ConfigNames.MINT_AMOUNT_PER_BLOCK);
        info.INTEREST_PLATFORM_SHARE = IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE);
        info.INTEREST_BUYBACK_SHARE = IConfig(config).getValue(ConfigNames.INTEREST_BUYBACK_SHARE);
        info.CHANGE_PRICE_DURATION = IConfig(config).getValue(ConfigNames.CHANGE_PRICE_DURATION);
        info.CHANGE_PRICE_PERCENT = IConfig(config).getValue(ConfigNames.CHANGE_PRICE_PERCENT);
        return info;
    }

    function getConfigPool(address _pair) public view returns (ConfigPoolStruct memory info){
        info.pair = _pair;
        info.supplyToken = IAAAAPool(_pair).supplyToken();
        info.collateralToken = IAAAAPool(_pair).collateralToken();
        info.supplyTokenSymbol = IERC20(info.supplyToken).symbol();
        info.collateralTokenSymbol = IERC20(info.collateralToken).symbol();
        info.POOL_BASE_INTERESTS = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_BASE_INTERESTS);
        info.POOL_MARKET_FRENZY = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_MARKET_FRENZY);
        info.POOL_PLEDGE_RATE = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_PLEDGE_RATE);
        info.POOL_LIQUIDATION_RATE = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_LIQUIDATION_RATE);
        info.POOL_MINT_BORROW_PERCENT = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_MINT_BORROW_PERCENT);
        info.POOL_MINT_POWER = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_MINT_POWER);
        info.lpToken0 = ISwapPair(info.collateralToken).token0();
        info.lpToken1 = ISwapPair(info.collateralToken).token1();
        info.lpToken0Symbol = IERC20(info.lpToken0).symbol();
        info.lpToken1Symbol = IERC20(info.lpToken1).symbol();
        return info;
    }

    function getConfigPools() public view returns (ConfigPoolStruct[] memory list){
        uint count = IAAAAFactory(IConfig(config).factory()).countPools();
        list = new ConfigPoolStruct[](count);
        if(count > 0) {
            for(uint i = 0; i < count; i++) {
                address pair = IAAAAFactory(IConfig(config).factory()).allPools(i);
                list[i] = getConfigPool(pair);
            }
        }
        return list;
    }

    function countConfig() public view returns (uint) {
        return 10 + IAAAAFactory(IConfig(config).factory()).countPools() * 4;
    }

    function getConfigValue(address _pair, bytes32 _key, string memory _name) public view returns (ConfigValueStruct memory info){
        info.pair = _pair;
        info.key = _key;
        info.name = _name;
        if(_pair != address(0)) {
            (info.min, info.max, info.span, info.value) = IConfig(config).getPoolParams(_pair, _key);
        } else {
            (info.min, info.max, info.span, info.value) = IConfig(config).getParams(_key);
        }

        if(info.value > info.min + info.span) {
            info.min = info.value - info.span;
        }

        if(info.max > info.value + info.span) {
            info.max = info.value + info.span;
        }

        return info;
    }

    function getConfigCommonValue(bytes32 _key, string memory _name) public view returns (ConfigValueStruct memory info){
        return getConfigValue(address(0), _key, _name);
    }

    function getConfigCommonValues() public view returns (ConfigValueStruct[] memory list){
        list = new ConfigValueStruct[](9);
        list[0] = getConfigCommonValue(ConfigNames.PROPOSAL_VOTE_DURATION, 'PROPOSAL_VOTE_DURATION');
        list[1] = getConfigCommonValue(ConfigNames.PROPOSAL_EXECUTE_DURATION, 'PROPOSAL_EXECUTE_DURATION');
        list[2] = getConfigCommonValue(ConfigNames.PROPOSAL_CREATE_COST, 'PROPOSAL_CREATE_COST');
        list[3] = getConfigCommonValue(ConfigNames.STAKE_LOCK_TIME, 'STAKE_LOCK_TIME');
        list[4] = getConfigCommonValue(ConfigNames.MINT_AMOUNT_PER_BLOCK, 'MINT_AMOUNT_PER_BLOCK');
        list[5] = getConfigCommonValue(ConfigNames.INTEREST_PLATFORM_SHARE, 'INTEREST_PLATFORM_SHARE');
        list[6] = getConfigCommonValue(ConfigNames.INTEREST_BUYBACK_SHARE, 'INTEREST_BUYBACK_SHARE');
        list[7] = getConfigCommonValue(ConfigNames.CHANGE_PRICE_DURATION, 'CHANGE_PRICE_DURATION');
        list[8] = getConfigCommonValue(ConfigNames.CHANGE_PRICE_PERCENT, 'CHANGE_PRICE_PERCENT');
        return list;
    }

    function getConfigPoolValues(address _pair) public view returns (ConfigValueStruct[] memory list){
        list = new ConfigValueStruct[](6);
        list[0] = getConfigValue(_pair, ConfigNames.POOL_BASE_INTERESTS, 'POOL_BASE_INTERESTS');
        list[1] = getConfigValue(_pair, ConfigNames.POOL_MARKET_FRENZY, 'POOL_MARKET_FRENZY');
        list[2] = getConfigValue(_pair, ConfigNames.POOL_PLEDGE_RATE, 'POOL_PLEDGE_RATE');
        list[3] = getConfigValue(_pair, ConfigNames.POOL_LIQUIDATION_RATE, 'POOL_LIQUIDATION_RATE');
        list[4] = getConfigValue(_pair, ConfigNames.POOL_MINT_BORROW_PERCENT, 'POOL_MINT_BORROW_PERCENT');
        list[5] = getConfigValue(_pair, ConfigNames.POOL_MINT_POWER, 'POOL_MINT_POWER');
        return list;
    }
}