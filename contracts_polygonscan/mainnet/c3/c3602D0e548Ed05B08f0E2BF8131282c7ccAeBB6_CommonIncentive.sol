/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-09-26
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.6;


pragma experimental ABIEncoderV2;


library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}
/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMathCopy for uint256;

    // ============ Constants ============

    uint256 private constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

library SafeMathCopy { // To avoid namespace collision between openzeppelin safemath and uniswap safemath
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

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

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

interface Iincentive {

    // Get all the rewards generated
    function getTotalReward(address token) view external returns(uint256) ;

    // Get trading signals (whether overbought or oversold)
    function getTradeSignal(address token) external view returns(bool,bool);

    // Executive incentive
    function execute(address sender,address recipient,uint256 amount,address token) external returns(uint256);

    function priceOverAvg(address token) external view returns(bool);

}


interface ICore {

    function getIncentiveState() external view returns(bool);

    function getPcvState() external view returns(bool);

    function isMinter(address account) external view returns(bool);

    function isBurner(address account)  external view returns(bool);

    function executeExtra(address sender,address recipient,uint256 amount) external returns(uint256);

    // Can the reward be withdrawn
    function ifGetReward() external view returns(bool);

    // Get the total rewards generated
    function getTotalReward() external view returns(uint256);
    
    function mint(address to,uint256 amount) external;
    
    function isOverSold() external view returns(bool);

    function getTokenPair(address token) external view returns(address);

}

interface IOracle {

    function getSwapPrice(address token,address pair) external view returns (Decimal.D256 memory,uint256,uint256);

    function getReserves() external view returns (uint256 dpReserves, uint256 tokenReserves);

    function setPair(address _pair,address dp) external;

    function getFinalPrice(int256 dpAmount,address token,address tokenPair) external view returns(Decimal.D256 memory);

    event PairUpdate(address indexed _pair);


    function token() external view returns (address);

}

interface ICommonToken is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

}


contract CommonIncentive is Iincentive{

    ICore public _core;
    IOracle public _oracle;

    using SafeCast for int256;
    using SafeMathCopy for uint256;
    using Decimal for Decimal.D256;

    uint256 public _totalReward;
    mapping(address => uint256) public _totalRewardMap;

    uint256 public _totalBurn;
    mapping(address => uint256) public _totalBurnMap;

    mapping(address => uint256) public _totalOverBoughtMintMap;

    mapping(address => Decimal.D256) private _KMap; // private

    uint256 private constant decimals = 10**18;

    uint256 public mLimitPercent = 10;
    Decimal.D256 public limitAmount; //private
    uint256 public  _mintPercent = 5;

    mapping(address => Decimal.D256)  public _finalPriceMap;

    mapping(address => Decimal.D256)  public _sellFinalPriceMap;

    mapping(address => Decimal.D256)  public oldPriceMap;

    struct VolPrice {
        Decimal.D256 price;
        uint256 vol;
        Decimal.D256 kv;
    }
    uint256 public _perVol = 10000 * decimals;

    uint256 groupNum = 10 ;

    mapping( address => mapping(uint256 => VolPrice)) public  tokenPriceMap;
    mapping(address => uint256) public tokenPriceMapLen;

    bool public isOverLimit = false;

    Decimal.D256  public _overboughtV = Decimal.from(90);
    Decimal.D256  public _oversoldV = Decimal.from(10);

    mapping(address => bool) _isOverBoughtMap; // private
    mapping(address => bool) _isOverSoldMap; // private

    Decimal.D256 public _volume;

    mapping(address => Decimal.D256) _averagePriceMap;

    address public _owner;

    uint256 public penaltyBurnPercent = 20;

    uint256 _incentivePercent = 20;

    mapping(address => uint256) public underAvgWeightMap;

    mapping(address => Decimal.D256) public preKMap;

    address public _router;

    constructor(address core,address oracle) public {
        _core = ICore(core);
        _oracle = IOracle(oracle);
        _owner = msg.sender;
        _volume = Decimal.from(100000);
        if(_volume.greaterThan(Decimal.zero())){
            limitAmount = _volume.mul(10).div(100);
        }
    }

    struct LogParam{
        uint256 amount;
        uint256 finalPrice;
        uint256 avgPrice;
        bool isOverBought;
        bool isOverSold;
        uint256 kValue;
        bool isUserSell;
        uint256 mintReward;
        uint256 buyIncentive;
        uint256 sellPenalty;
        uint256 oldPrice;
        address token;
    }

    function execute(address sender,address recipient,uint256 amount,address token) external override returns(uint256) {
        uint256 newAmount = amount;

        address pair = getTokenPair(token);

        isFirstIncentive(token,pair);

        if(pair == address(0)){
            return newAmount;
        }

        if(sender != pair && recipient != pair){
            return newAmount;
        }

        LogParam memory logParam;

        bool isUserSell = recipient == pair ? true: false;

        int256 intAmount = SafeCast.toInt256(amount);

        _finalPriceMap[token] = isUserSell ? _getFinalPrice(intAmount,token,pair): _getFinalPrice(intAmount * -1,token,pair);
        preKMap[token] = _KMap[token];

        // 1.更新交易后价格
        _updateVolPrice(amount,token,pair);

        // 2.更新K值
        Decimal.D256 memory preK = preKMap[token];
        updateK(token);

        // 3.更新平均价格
        _updateAveragePrice(token);


        // 更新奖励铸币数量
        bool preOverBought = preK.greaterThanOrEqualTo(_overboughtV);
        bool newOverBought = _KMap[token].greaterThanOrEqualTo(_overboughtV);

        if(preOverBought && newOverBought){
            logParam.mintReward =  amount.mul(_mintPercent).div(100);
            _totalOverBoughtMintMap[token] += logParam.mintReward;
        }

        // 交易后低于均价
        if(_finalPriceMap[token].lessThan(_averagePriceMap[token])){
            ICommonToken _token = ICommonToken(token);
            if(isUserSell){ //卖惩罚
                logParam.sellPenalty = getSellPenalty(amount,token,pair); // 惩罚数量
                logParam.sellPenalty = logParam.sellPenalty.mul(penaltyBurnPercent).div(100); //在计算时候乘以这个百分比
                _token.burnFrom(sender,logParam.sellPenalty); // 燃烧
                _totalBurnMap[token] += logParam.sellPenalty;
                newAmount = newAmount - logParam.sellPenalty;
                underAvgWeightMap[token] = underAvgWeightMap[token].add(amount); // 低于均价卖出成交量累计
            }else{ // 买奖励
                logParam.buyIncentive = getBuyIncentive(amount,token,pair);
                logParam.buyIncentive = logParam.buyIncentive.mul(_incentivePercent).div(100);
                // 比较买时奖励和卖时惩罚数量
                _sellFinalPriceMap[token] = _oracle.getFinalPrice(SafeCast.toInt256(amount),token,pair);
                logParam.sellPenalty = getSellPenaltyWhenBuy(amount,token);
                logParam.sellPenalty = logParam.sellPenalty.mul(penaltyBurnPercent).div(100);
                if(logParam.buyIncentive > logParam.sellPenalty){
                    logParam.buyIncentive = logParam.sellPenalty;
                }
                _token.mint(recipient,logParam.buyIncentive);
                _totalRewardMap[token] += logParam.buyIncentive;
            }
        }else{
            underAvgWeightMap[token] = 0; // 高于均价重置累计
        }

        logParam.finalPrice = _finalPriceMap[token].value;
        logParam.avgPrice = _averagePriceMap[token].value;
        logParam.isOverBought =  _isOverBoughtMap[token];
        logParam.isOverSold =  _isOverSoldMap[token];
        logParam.kValue = _KMap[token].value;
        logParam.token = token;
        logParam.oldPrice = oldPriceMap[token].value;
        logParam.amount = amount;
        logParam.isUserSell = isUserSell;
        outputLog(logParam);

        return newAmount;
    }

    function outputLog(LogParam memory logParam) internal{
        emit incentiveExc(logParam.amount,
            logParam.finalPrice,
            logParam.avgPrice,
            logParam.isOverBought,
            logParam.isOverSold,
            logParam.kValue,
            logParam.isUserSell,
            logParam.mintReward,
            logParam.buyIncentive,
            logParam.sellPenalty,
            logParam.oldPrice,
            logParam.token);
    }
    event incentiveExc(uint256 amount,
        uint256 newPrice,
        uint256 avgPrice,
        bool isOverBought,
        bool isOverSold,
        uint256 K,
        bool isUserSell,
        uint256 mintAmout,
        uint256 incentive,
        uint256 sellPenalty,
        uint256 oldPirce,
        address token);

    // Set the range of KDJ overbought and oversold
    function setOverTrade(uint256 oversold,uint256 overbought) external onlyOwner{
        require(overbought > oversold,"overBought can not lower than oversold");
        _overboughtV = Decimal.from(overbought);
        _oversoldV = Decimal.from(oversold);
    }

    // Get all the rewards generated by overbought
    function getTotalReward(address token) view external override returns(uint256) {
        return _totalOverBoughtMintMap[token];
    }


    // Set volume window
    function setVolumeWindow(uint256 volume) external onlyOwner{
        _volume = Decimal.from(volume);
        limitAmount = _volume.mul(mLimitPercent).div(100);
        _perVol = volume.div(10);
    }

    // Update K value
    function updateK(address token) internal{ // internal
        uint256 pMapLen = tokenPriceMapLen[token];
        if(pMapLen < 10){
            return;
        }
        Decimal.D256 memory _rsv = getRSV(token);
        Decimal.D256 memory pk = tokenPriceMap[token][8].kv;
        Decimal.D256 memory kvalue = pk.mul(2).div(3);
        Decimal.D256 memory rsvValue = _rsv.div(3);
        _KMap[token] = kvalue.add(rsvValue);
        _isOverBoughtMap[token] = (_KMap[token].greaterThanOrEqualTo(_overboughtV));
        _isOverSoldMap[token] = (_KMap[token].lessThanOrEqualTo(_oversoldV));
    }

    // Get the highest price and lowest price
    function getHightAndLowPirce(address token) internal view returns(Decimal.D256 memory hPrice, Decimal.D256 memory lPrice){
        hPrice = tokenPriceMap[token][0].price; // Highest price
        lPrice = tokenPriceMap[token][0].price; // Lowest price
        uint256 pMapLen = tokenPriceMapLen[token];
        Decimal.D256 memory price;
        for(uint256 i = 0 ;i < pMapLen ; i++){
            price = tokenPriceMap[token][i].price;
            if(price.greaterThan(hPrice)){
                hPrice = price;}
            if(price.lessThan(lPrice)){
                lPrice = price;
            }
        }
        return (hPrice,lPrice);
    }

    
    // @return (K,D,J)
    function getKDJ(address token) external view  returns(Decimal.D256 memory) {
        return _KMap[token];
    }

    function getRSV(address token) public view returns(Decimal.D256 memory rsv){
        (Decimal.D256 memory high ,Decimal.D256 memory low) = getHightAndLowPirce(token);

        if(low.equals(high)){
            return Decimal.zero();
        }
        Decimal.D256 memory molecular;
        Decimal.D256 memory denominator;
        denominator = high.sub(low);

        if(denominator.isZero()){
            return Decimal.zero();
        }

        molecular = _finalPriceMap[token].sub(low);

        rsv = molecular.mul(100).div(denominator);
        return rsv;
    }

    // Get the current uniswap price
    function _getCurrentPrice(address token,address pair) internal view returns(Decimal.D256 memory ,uint256,uint256){
        (Decimal.D256 memory  price,uint256 dpReserve,uint256 otherReserve) = _oracle.getSwapPrice(token,pair);
        return (price,dpReserve,otherReserve);
    }

    // Get the current price after the transaction
    function _getFinalPrice(int256 amount,address token,address pair) public view returns(Decimal.D256 memory){
        if(amount == 0){
            return _finalPriceMap[token];
        }
        return _oracle.getFinalPrice(amount,token,pair);
    }

    function setMlimitPercent(uint256 percent) external onlyOwner {
        require(0 <= percent && 100 >= percent,"Incentive: mLimitPercent must in 0 to 100");
        limitAmount = _volume.mul(percent).div(100);
        mLimitPercent = percent;
    }

    // Provide external access to overbought and oversold status
    function getTradeSignal(address token) external override view returns(bool,bool){
        return (_isOverBoughtMap[token],_isOverSoldMap[token]);
    }

    function _isOverLimit(uint256 amount) internal view returns(bool){ // internal
        uint256 _limiAmount = limitAmount.asUint256();
        bool isOver =  amount >= _limiAmount;
        return isOver;
    }


    // Update the price after the transaction to the array
    function _updateVolPrice(uint256 amount,address token,address pair) internal {
        (oldPriceMap[token],,) = _getCurrentPrice(token,pair);
        // Decimal.D256 memory oldPrice = oldPriceMap[token];
        uint256  pMapLen = tokenPriceMapLen[token];
        Decimal.D256 memory _finalPrice = _finalPriceMap[token];
        Decimal.D256 memory preK = preKMap[token];
        mapping(uint256 => VolPrice) storage tokenPirce = tokenPriceMap[token];

        for(uint256 i = 0 ;i< groupNum;i++){
            uint256 vol =  tokenPirce[i].vol;
            if(vol >= _perVol){ // This set of accumulated trading volume is full of the set value
                if(i < 9){
                    continue;
                }
            }
            uint256 newVol = vol.add(amount);
            if(newVol <= _perVol){ // After adding the new volume, it still does not exceed the set value
                tokenPirce[i].vol = newVol;
                tokenPirce[i].price = _finalPrice;
                tokenPirce[i].kv = preK; // This k value is only correct when it is the closing price
                pMapLen = i +1;
                tokenPriceMapLen[token] = pMapLen;
                return;
            }
            // Exceed the set value after adding the new volume
            uint256 j = 0;
            while(newVol > _perVol ){
                tokenPirce[i+j].vol = _perVol;
                tokenPirce[i+j].price = oldPriceMap[token];
                tokenPirce[i+j].kv = preK;
                newVol = newVol - _perVol;
                j++;
            }
            pMapLen = i+1+j;
            tokenPriceMapLen[token] = pMapLen;

            // The last set of cumulative trading volume
            tokenPirce[i+j].vol = newVol;
            tokenPirce[i+j].price = _finalPrice;

            // There is a span, the median price is the difference
            Decimal.D256 memory priceDiff;
            Decimal.D256 memory priceIncr;
            if(oldPriceMap[token].greaterThanOrEqualTo(_finalPrice)){ // User sells
                priceDiff = oldPriceMap[token].sub(_finalPrice);
                priceIncr = priceDiff.div(j);

                while(j > 0){
                    tokenPirce[i+j].price = oldPriceMap[token].sub(priceIncr.mul(j));
                    tokenPirce[i+j].kv = preK;
                    j--;
                }
            }
            if(oldPriceMap[token].lessThan(_finalPrice)){ // User buys
                priceDiff =  _finalPrice.sub(oldPriceMap[token]);
                priceIncr =  priceDiff.div(j);
                while(j > 0){
                    tokenPirce[i+j].price = oldPriceMap[token].add(priceIncr.mul(j));
                    tokenPirce[i+j].kv = preK;
                    j--;
                }
            }
            // If there are more than 10 sets of data, the old data will be removed and the new data will move forward
            if(pMapLen <= groupNum){
                break;
            }
            uint256 overLen = pMapLen - groupNum;
            for(uint256 n = 0;n < groupNum;n++){
                tokenPirce[n].vol = tokenPirce[n+overLen].vol;
                tokenPirce[n].price = tokenPirce[n+overLen].price;
                tokenPirce[n].kv = tokenPirce[n+overLen].kv;
            }
            for(uint256 k = pMapLen-1;k > groupNum-1;k--){
                delete tokenPirce[k];
            }

            tokenPriceMapLen[token] = pMapLen - overLen;
            break;
        }
    }


    // Update average price
    function _updateAveragePrice(address token) internal { // internal

        // When there is only 1 set of data
        if(tokenPriceMap[token][0].vol < _perVol){
            _averagePriceMap[token] = _finalPriceMap[token];
            return ;
        }

        Decimal.D256 memory priceAll;
        uint256 count = 0;
        Decimal.D256 memory price;

        for(uint256 i=0;i < groupNum ;i++){
            price =  tokenPriceMap[token][i].price;
            if(price.isZero()) break;
            priceAll = priceAll.add(price);
            count++;
        }
        _averagePriceMap[token] = priceAll.div(count);
    }

    modifier isCore(){
        require(msg.sender == address(_core),"Incentive: caller is not core");
        _;
    }

    modifier isRouter(){
        require(msg.sender == _router,"Incentive: caller is not router");
        _;
    }

    function setPenaltyBurnPercent(uint256 burnPercent) external onlyOwner{
        bool isTrue = (0 <= burnPercent) && (burnPercent <= 100);
        require( isTrue,"Incentive: param must between 0 and 100");
        penaltyBurnPercent = burnPercent;
    }

    function setIncentivePercent(uint256 incentivePercent) external onlyOwner{
        bool isTrue = (0 <= incentivePercent) && (incentivePercent <= 100);
        require( isTrue,"Incentive: param must between 0 and 100");
        _incentivePercent = incentivePercent;
    }


    // ------------------- Penalty below the moving average ------------------

    event penaltyEvent(uint256 p1,uint256 p2,bool p3);
    // Number of penalties obtained
    function getSellPenalty(uint256 amount,address token,address pair)
    internal // internal
    view
    returns (
        uint256 penalty
    )
    {

        (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 reserveDp,
        uint256 reserveOther
        ) = _getPriceDeviations(token,pair);

        // if trafe ends above average, it was always above average and no penalty needed
        if (finalDeviation.equals(Decimal.zero())) {
            return 0;
        }

        uint256 incentivizedAmount = amount;
        // if trade started above but ended below, only penalize amount going below average
        if (initialDeviation.equals(Decimal.zero())) {
            uint256 amountToAverage = _getAmountToAvg(reserveDp, reserveOther,token);
            incentivizedAmount = amount.sub(
                amountToAverage,
                "UniswapIncentive: Underflow"
            );
        }

        Decimal.D256 memory multiplier =
        _calculateIntegratedSellPenaltyMultiplier(initialDeviation, finalDeviation);
        penalty = multiplier.mul(incentivizedAmount).asUint256();
        return (penalty);
    }


    // Number of penalties obtained
    function getSellPenaltyWhenBuy(uint256 amount,address token)
    internal // internal
    view
    returns (
        uint256 penalty
    )
    {

        (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 reserveDp,
        uint256 reserveOther
        ) = _getPriceDeviationsWhenBuy(token);

        // if trafe ends above average, it was always above average and no penalty needed
        if (finalDeviation.equals(Decimal.zero())) {
            return 0;
        }

        uint256 incentivizedAmount = amount;
        // if trade started above but ended below, only penalize amount going below average
        if (initialDeviation.equals(Decimal.zero())) {
            uint256 amountToAverage = _getAmountToAvg(reserveDp, reserveOther,token);
            incentivizedAmount = amount.sub(
                amountToAverage,
                "UniswapIncentive: Underflow"
            );
        }

        Decimal.D256 memory multiplier =
        _calculateIntegratedSellPenaltyMultiplier(initialDeviation, finalDeviation);
        penalty = multiplier.mul(incentivizedAmount).asUint256();
        return (penalty);
    }


    /// @notice get deviation from Avg as a percent given price
    /// @dev will return Decimal.zero() if above Avg
    function _deviationBelowAvg(Decimal.D256 memory price,address token) internal view returns (Decimal.D256 memory) {
        Decimal.D256 memory _averagePrice = _averagePriceMap[token];
        if(price.greaterThanOrEqualTo(_averagePrice)){
            return Decimal.zero();
        }
        Decimal.D256 memory delta = _averagePrice.sub(price, "Impossible underflow");
        return delta.div(_averagePrice);
    }


    // Returns the percentage distance from the peg before and after the hypothetical transaction
    function _getPriceDeviations(address token,address pair)
    internal // internal
    view
    returns (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 ,
        uint256
    )
    {
        (Decimal.D256 memory price, uint256 reserveDp,uint256 reserveOther) = _getCurrentPrice(token,pair);
        Decimal.D256 memory _finalPrice = _finalPriceMap[token];

        initialDeviation = _deviationBelowAvg(price,token);

        finalDeviation = _deviationBelowAvg(_finalPrice,token);

        return (
        initialDeviation,
        finalDeviation,
        reserveDp,
        reserveOther
        );
    }

    // Returns the percentage distance from the peg before and after the hypothetical transaction
    function _getPriceDeviationsWhenBuy(address token)
    internal // internal
    view
    returns (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 ,
        uint256
    )
    {
        address pair = getTokenPair(token);
        (Decimal.D256 memory price, uint256 reserveDp,uint256 reserveOther) = _getCurrentPrice(token,pair);

        initialDeviation = _deviationBelowAvg(price,token);

        finalDeviation = _deviationBelowAvg(_sellFinalPriceMap[token],token);

        return (
        initialDeviation,
        finalDeviation,
        reserveDp,
        reserveOther
        );
    }


    // The sell penalty smoothed over the curve
    function _calculateIntegratedSellPenaltyMultiplier(Decimal.D256 memory initialDeviation, Decimal.D256 memory finalDeviation)
    internal
    pure
    returns (Decimal.D256 memory)
    {
        if (initialDeviation.equals(finalDeviation)) {
            return _calculateSellPenaltyMultiplier(initialDeviation);
        }
        Decimal.D256 memory numerator = _sellPenaltyBound(finalDeviation).sub(_sellPenaltyBound(initialDeviation));
        Decimal.D256 memory denominator = finalDeviation.sub(initialDeviation);

        Decimal.D256 memory multiplier = numerator.div(denominator);
        if (multiplier.greaterThan(Decimal.one())) {
            return Decimal.one();
        }
        return multiplier;
    }

    function _calculateSellPenaltyMultiplier(Decimal.D256 memory deviation)
    internal
    pure
    returns (Decimal.D256 memory)
    {
        Decimal.D256 memory multiplier = deviation.mul(deviation).mul(100); // m^2 * 100
        if (multiplier.greaterThan(Decimal.one())) {
            return Decimal.one();
        }
        return multiplier;
    }

    function _sellPenaltyBound(Decimal.D256 memory deviation)
    internal
    pure
    returns (Decimal.D256 memory)
    {
        return deviation.pow(3).mul(11);
    }


    function _getAmountToAvg(
        uint256 reserveDp,
        uint256 reserveOther,
        address token
    ) public view returns (uint256) {  // internal
        Decimal.D256 memory  dpPirce = Decimal.one().div(_averagePriceMap[token]);
        uint256 radicand = dpPirce.mul(reserveDp).mul(reserveOther).asUint256();
        uint256 root = SafeMathCopy.sqrt(radicand);
        if (root > reserveDp) {
            return (root - reserveDp).mul(1000).div(997);
        }
        return (reserveDp - root).mul(1000).div(997);
    }

    function priceOverAvg(address token) external override view returns(bool){
        Decimal.D256 memory _finalPrice = _finalPriceMap[token];
        Decimal.D256 memory _averagePrice = _averagePriceMap[token];
        return _finalPrice.greaterThanOrEqualTo(_averagePrice);
    }

    modifier onlyOwner(){
        require(msg.sender == _owner,"Icentive: caller not contract owner");
        _;
    }

    function setMintPercentOnOverBought(uint256 mintPercent) external onlyOwner{
        _mintPercent  = mintPercent;
    }

    function setOracle(address uniOracle) external onlyOwner {
        require(address(0) != uniOracle,"Incentive: oracle address is 0");
        _oracle = IOracle(uniOracle);
    }

    function getBuyIncentive(uint256 amount,address token,address pair)
    public
    view
    returns (uint256 incentive)
    {
        (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 reserveDp,
        uint256 reserveOther
        ) = _getPriceDeviations(token,pair);

        // Purchase starts above the peg
        if (initialDeviation.equals(Decimal.zero())) {
            return (0);
        }

        uint256 incentivizedAmount = amount;
        // If the end of the purchase is higher than the peg, only the part below the average price will be incentivized
        if (finalDeviation.equals(Decimal.zero())) {
            incentivizedAmount = _getAmountToAvg(reserveDp, reserveOther,token);
        }

        Decimal.D256 memory multiplier =
        _calculateBuyIncentiveMultiplier(initialDeviation, finalDeviation,token);
        incentive = multiplier.mul(incentivizedAmount).asUint256();
        return (incentive);
    }

    function _calculateBuyIncentiveMultiplier(
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        address token
    ) internal view returns (Decimal.D256 memory) {
        Decimal.D256 memory correspondingPenalty =
        _calculateIntegratedSellPenaltyMultiplier(finalDeviation, initialDeviation); // Flip direction

        uint256 underAvgWeight = underAvgWeightMap[token];
        Decimal.D256 memory buyMultiplier =
        initialDeviation.mul(underAvgWeight).div(_volume);

        if (correspondingPenalty.lessThan(buyMultiplier)) { // Maximum reward = amount of penalty
            return correspondingPenalty;
        }
        return buyMultiplier;
    }

    function changeOwner(address newOwner) external onlyOwner{
        require(address(newOwner) != address(0),"new owner can not be null");
        _owner = newOwner;
    }

    function getTokenPair(address token) internal view returns(address){
        return _core.getTokenPair(token);
    }

    // The first incentive token, initial price
    function isFirstIncentive(address token,address pair) internal { // inernal
        Decimal.D256 memory price = tokenPriceMap[token][0].price;
        if(!price.isZero()){
            return;
        }
        (Decimal.D256 memory newPrice,,) = _getCurrentPrice(token,pair);
        _finalPriceMap[token] = newPrice;
        _averagePriceMap[token] = newPrice;
        _KMap[token] = Decimal.from(50);
    }

    function setCoreContract(address coreContract) external onlyOwner{
        _core = ICore(coreContract);
    }

}