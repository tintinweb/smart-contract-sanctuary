/**
 *Submitted for verification at polygonscan.com on 2022-01-17
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

    // 获取所有产生的奖励
    function getTotalReward() view external returns(uint256) ;

    // 获取交易信号 （是否超买，是否超卖）
    function getTradeSignal() external view returns(bool,bool);

    // 执行激励
    function execute(address sender,address recipient,uint256 amount) external returns(uint256);

    function priceOverAvg() external view returns(bool);


}


interface ICore {

    function getIncentiveState() external view returns(bool);

    function getPcvState() external view returns(bool);

    function isMinter(address account) external view returns(bool);

    function isBurner(address account)  external view returns(bool);

    function executeExtra(address sender,address recipient,uint256 amount) external returns(uint256);

    // 是否可提取奖励
    function ifGetReward() external view returns(bool);

    // 获取产生的总奖励
    function getTotalReward() external view returns(uint256);

    // dp铸币
    function mint(address to,uint256 amount) external;

    // 是否超卖
    function isOverSold() external view returns(bool);

}

interface IOracle {

    function getSwapPrice(address token) external view returns (Decimal.D256 memory,uint256,uint256);

    function getReserves() external view returns (uint256 dpReserves, uint256 tokenReserves);

    function setPair(address _pair,address dp) external;

    function getFinalPrice(int256 dpAmount) external view returns(Decimal.D256 memory);

    function isPair(address account) external view returns(bool);


    event PairUpdate(address indexed _pair);


    function token() external view returns (address);

}

interface IDp is IERC20 {
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


// 激励合约
contract Incentive is Iincentive{

    address public _core;
    IOracle public _oracle;
    IDp public _dp;

    using SafeCast for int256;
    using SafeMathCopy for uint256;
    using Decimal for Decimal.D256;

    uint256 public _totalReward;

    uint256 public _totalBurn;

    uint256 public _totalOverBoughtMint;

    Decimal.D256 private _K = Decimal.from(50); // private

    uint256 private constant decimals = 10**18;

    uint256 public mLimitPercent = 10; // 单笔成交量限定百分比 默认 10%,影响铸币
    Decimal.D256 public limitAmount; //private
    uint256 public _mintPercent = 5; // 超买铸币百分比

    Decimal.D256  public _finalPrice;//交易后价格
    Decimal.D256  public _sellFinalPrice;//用于计算买时，如果是卖的交易后价格
    Decimal.D256  public oldPirce;//当下价格

    struct VolPrice {
        Decimal.D256 price; // 最新价
        uint256 vol;//累计成交量
        Decimal.D256 kv; // k值
    }
    uint256 public _perVol = 10000 * decimals;

    mapping(uint256 => VolPrice) public  pMap; // 每组累计成交量和价格，下标从0开始
    uint256 pMapLen; // 记录pMap长度
    uint256 groupNum = 10 ; //分组

    bool public isOverLimit = false; // 用来标记窗口内累计成交量是否超过限定值 private
    bool public _isOver = false; // 用来标记当前交易是否超过限定值 private

    // kdj 超买 超卖范围
    Decimal.D256  public _overboughtV = Decimal.from(90);
    Decimal.D256  public _oversoldV = Decimal.from(10);

    // 超买超卖状态
    bool public _isOverBought = false; // private
    bool public _isOverSold = false; // private

    // 均价取值成交量窗口
    Decimal.D256 public _volume;

    // 均线价格 xxx dp/TOKEN
    Decimal.D256 public _averagePrice;

    address public _owner;

    // 低价卖出燃烧金额百分比 默认10%
    uint256 public penaltyBurnPercent = 20;

    // 低价买入奖励 金额百分比 默认10%
    uint256 _incentivePercent = 20;
    // 低于均价累计成交量
    uint256 public underAvgWeight;

    Decimal.D256 public preK;

    constructor(address core,address oracle,address dp) public {
        _core = core;
        _oracle = IOracle(oracle);
        _dp = IDp(dp);
        _owner = msg.sender;
        _volume = Decimal.from(100000);
        if(_volume.greaterThan(Decimal.zero())){
            limitAmount = _volume.mul(10).div(100);
        }

        (_averagePrice,,) = _oracle.getSwapPrice(dp);
        _finalPrice = _averagePrice;

    }

    // 设置KDJ超买超卖的范围
    function setOverTrade(uint256 oversold,uint256 overbought) external onlyOwner{
        require(overbought > oversold,"overBought can not lower than oversold");
        _overboughtV = Decimal.from(overbought);
        _oversoldV = Decimal.from(oversold);
    }


    // 获取所有超买 产生的奖励
    function getTotalReward() view external override returns(uint256) {
        return _totalOverBoughtMint;
    }

    // 执行激励
    function execute(address sender,address recipient,uint256 amount) external override isCore returns(uint256) {

        uint256 newAmount = amount;
        if(!_oracle.isPair(sender) && !_oracle.isPair(recipient)){
            return newAmount;
        }

        _isOver = amount >= limitAmount.mul(decimals).asUint256();
        bool isUserSell = _oracle.isPair(sender)? false: true;

        int256 intAmount = SafeCast.toInt256(amount);
        _finalPrice = isUserSell ? _getFinalPrice(intAmount): _getFinalPrice(intAmount * -1);

        preK = _K;

        // 1.更新交易后价格
        _updateVolPrice(amount);
        // 2.更新K值
        preK = _K;
        updateK();
        // 3.更新平均价格
        _updateAveragePrice();

        // 更新奖励铸币数量
        bool preOverBought = preK.greaterThanOrEqualTo(_overboughtV);
        bool newOverBought = _K.greaterThanOrEqualTo(_overboughtV);

        uint256 mintReward = 0;
        uint256 buyIncentive = 0;
        uint256 sellPenalty = 0;
        if(preOverBought && newOverBought){
            mintReward = _isOver
            ? limitAmount.mul(_mintPercent).div(100).mul(decimals).asUint256()
            : amount.mul(_mintPercent).div(100);
            _totalOverBoughtMint += mintReward;
        }
        // 交易后低于均价
        if((_finalPrice.lessThan(_averagePrice))){
            if(isUserSell){ //卖惩罚
                uint256 penalty = getSellPenalty(amount); // 惩罚数量
                penalty = penalty.mul(penaltyBurnPercent).div(100); //在计算时候乘以这个百分比
                _dp.burnFrom(sender,penalty); // 燃烧
                _totalBurn += penalty;
                newAmount = newAmount - penalty;
                underAvgWeight = underAvgWeight.add(amount); // 低于均价卖出成交量累计
                sellPenalty = penalty;
            }else{ // 买奖励
                uint256 incentive = getBuyIncentive(amount);
                incentive = incentive.mul(_incentivePercent).div(100);
                // 比较买时奖励和卖时惩罚数量
                _sellFinalPrice = _oracle.getFinalPrice(SafeCast.toInt256(amount));
                uint256 penalty = getSellPenaltyWhenBuy(amount);
                penalty = penalty.mul(penaltyBurnPercent).div(100);
                if(incentive > penalty){
                    incentive = penalty;
                }
                _dp.mint(recipient,incentive);
                _totalReward += incentive;
                buyIncentive = incentive;
            }
        }else{
            underAvgWeight = 0; // 高于均价重置累计
        }
        emit incentiveExc(amount,_finalPrice.value,_averagePrice.value,_isOverBought,_isOverSold,
            _K.value, isUserSell,mintReward,buyIncentive,sellPenalty,oldPirce.value);
        return newAmount;
    }

    event incentiveExc(uint256 amount,uint256 newPrice, uint256 avgPrice,
        bool isOverBought, bool isOverSold,uint256 K,bool isUserSell,
        uint256 mintAmout, uint256 incentive,uint256 sellPenalty,uint256 oldPirce);

    // 设置成交量窗口
    function setVolumeWindow(uint256 volume) external onlyOwner{
        _volume = Decimal.from(volume);
        limitAmount = _volume.mul(mLimitPercent).div(100);
        _perVol = volume.div(10);
    }


    // 更新K值
    function updateK() internal{ // internal
        if(pMapLen < 10){
            return;
        }
        Decimal.D256 memory _rsv = getRSV();
        Decimal.D256 memory pk = pMap[8].kv;
        Decimal.D256 memory kvalue = pk.mul(2).div(3);
        Decimal.D256 memory rsvValue = _rsv.div(3);
        _K = kvalue.add(rsvValue);
        _isOverBought = (_K.greaterThanOrEqualTo(_overboughtV));
        _isOverSold = (_K.lessThanOrEqualTo(_oversoldV));
    }

    // 获取最高价、最低价
    function getHightAndLowPirce() internal view returns(Decimal.D256 memory hPrice, Decimal.D256 memory lPrice){
        hPrice = pMap[0].price; // 最高价
        lPrice = pMap[0].price; // 最低价
        Decimal.D256 memory price;
        for(uint256 i = 0 ;i < pMapLen ; i++){
            price = pMap[i].price;
            if(price.greaterThan(hPrice)){
                hPrice = price;}
            if(price.lessThan(lPrice)){
                lPrice = price;
            }
        }
        return (hPrice,lPrice);
    }


    // 获取KDJ值
    // @return (K,D,J)
    function getKDJ() external view  returns(Decimal.D256 memory) {
        return _K;
    }

    function getRSV() public view returns(Decimal.D256 memory rsv){
        (Decimal.D256 memory high ,Decimal.D256 memory low) = getHightAndLowPirce();

        if(low.equals(high)){
            return Decimal.zero();
        }
        Decimal.D256 memory molecular;
        Decimal.D256 memory denominator;
        denominator = high.sub(low);

        if(denominator.isZero()){
            return Decimal.zero();
        }

        molecular = _finalPrice.sub(low);

        rsv = molecular.mul(100).div(denominator);
        return rsv;
    }
    
    function _getCurrentPrice() internal view returns(Decimal.D256 memory ,uint256,uint256){
        (Decimal.D256 memory  price,uint256 dpReserve,uint256 otherReserve) = _oracle.getSwapPrice(address(_dp));
        return (price,dpReserve,otherReserve);
    }
    
    function _getFinalPrice(int256 amount) internal returns(Decimal.D256 memory){
        if(amount == 0){
            return _finalPrice;
        }
        _finalPrice = _oracle.getFinalPrice(amount);

        if(amount < 0) {amount = amount * -1;}

        return _finalPrice;
    }

    function setMlimitPercent(uint256 percent) external onlyOwner {
        require(0 <= percent && 100 >= percent,"Incentive: mLimitPercent must in 0 to 100");
        limitAmount = _volume.mul(percent).div(100);
        mLimitPercent = percent;
    }
    
    function getTradeSignal() external override view returns(bool,bool){
        return (_isOverBought,_isOverSold);
    }

    function _isOverLimit(uint256 amount) internal view returns(bool){ // internal
        uint256 _limiAmount = limitAmount.asUint256();
        bool isOver =  amount >= _limiAmount;
        return isOver;
    }
    
    function _updateVolPrice(uint256 amount) internal {
        (oldPirce,,) = _getCurrentPrice();
        for(uint256 i = 0 ;i< groupNum;i++){
            uint256 vol =  pMap[i].vol;
            if(vol >= _perVol){ 
                if(i < 9){
                    continue;
                }
            }
            uint256 newVol = vol.add(amount);
            if(newVol <= _perVol){ 
                pMap[i].vol = newVol;
                pMap[i].price = _finalPrice;
                pMap[i].kv = preK;
                pMapLen = i +1;
                return;
            }

            uint256 j = 0;
            while(newVol > _perVol ){
                pMap[i+j].vol = _perVol;
                pMap[i+j].price = oldPirce;
                pMap[i+j].kv = preK;
                newVol = newVol - _perVol;
                j++;
            }
            pMapLen = i+1+j;

            pMap[i+j].vol = newVol;
            pMap[i+j].price = _finalPrice;

            Decimal.D256 memory priceDiff;
            Decimal.D256 memory priceIncr;
            if(oldPirce.greaterThanOrEqualTo(_finalPrice)){ // USER SELL
                priceDiff = oldPirce.sub(_finalPrice);
                priceIncr = priceDiff.div(j);
                while(j > 0){
                    pMap[i+j].price = oldPirce.sub(priceIncr.mul(j));
                    pMap[i+j].kv = preK;
                    j--;
                }
            }
            if(oldPirce.lessThan(_finalPrice)){ // User buys
                priceDiff =  _finalPrice.sub(oldPirce);
                priceIncr =  priceDiff.div(j);
                while(j > 0){
                    pMap[i+j].price = oldPirce.add(priceIncr.mul(j));
                    pMap[i+j].kv = preK;
                    j--;
                }
            }
  
            if(pMapLen <= groupNum){
                break;
            }
            uint256 overLen = pMapLen - groupNum;
            for(uint256 n = 0;n < groupNum;n++){
                pMap[n].vol = pMap[n+overLen].vol;
                pMap[n].price = pMap[n+overLen].price;
                pMap[n].kv = pMap[n+overLen].kv;
            }
            for(uint256 k = pMapLen-1;k > groupNum-1;k--){
                delete pMap[k];
            }
            pMapLen = pMapLen - overLen;
            break;
        }
    }

    
    function _updateAveragePrice() internal { // internal
        Decimal.D256 memory priceAll;
        Decimal.D256 memory price;
        uint256 count = 0;

        if(pMap[0].vol < _perVol){
            _averagePrice = _finalPrice;
            return ;
        }

        for(uint256 i=0;i < groupNum ;i++){
            price = pMap[i].price;
            if(price.isZero()) break;
            priceAll = priceAll.add(price);
            count++;
        }
        _averagePrice = priceAll.div(count);
    }


    modifier isCore(){
        require(msg.sender == _core,"Incentive: caller is not core");
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
    

    event penaltyEvent(uint256 p1,uint256 p2,bool p3);
    // 获取惩罚的数量
    function getSellPenalty(uint256 amount)
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
        ) = _getPriceDeviations();

        // if trafe ends above average, it was always above average and no penalty needed
        if (finalDeviation.equals(Decimal.zero())) {
            return 0;
        }

        uint256 incentivizedAmount = amount;
        // if trade started above but ended below, only penalize amount going below average
        if (initialDeviation.equals(Decimal.zero())) {
            uint256 amountToAverage = _getAmountToAvg(reserveDp, reserveOther);
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


    function getSellPenaltyWhenBuy(uint256 amount)
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
        ) = _getPriceDeviationsWhenBuy();

        // if trafe ends above average, it was always above average and no penalty needed
        if (finalDeviation.equals(Decimal.zero())) {
            return 0;
        }

        uint256 incentivizedAmount = amount;
        // if trade started above but ended below, only penalize amount going below average
        if (initialDeviation.equals(Decimal.zero())) {
            uint256 amountToAverage = _getAmountToAvg(reserveDp, reserveOther);
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
    function _deviationBelowAvg(Decimal.D256 memory price) internal view returns (Decimal.D256 memory) {

        if(price.greaterThanOrEqualTo(_averagePrice)){
            return Decimal.zero();
        }
        Decimal.D256 memory delta = _averagePrice.sub(price, "Impossible underflow");
        return delta.div(_averagePrice);
    }



    function _getPriceDeviations()
    internal // internal
    view
    returns (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 ,
        uint256
    )
    {

        (Decimal.D256 memory price, uint256 reserveDp,uint256 reserveOther) = _getCurrentPrice();

        initialDeviation = _deviationBelowAvg(price);

        finalDeviation = _deviationBelowAvg(_finalPrice);

        return (
        initialDeviation,
        finalDeviation,
        reserveDp,
        reserveOther
        );
    }


    function _getPriceDeviationsWhenBuy()
    internal // internal
    view
    returns (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 ,
        uint256
    )
    {

        (Decimal.D256 memory price, uint256 reserveDp,uint256 reserveOther) = _getCurrentPrice();

        initialDeviation = _deviationBelowAvg(price);

        finalDeviation = _deviationBelowAvg(_sellFinalPrice);

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
        uint256 reserveOther
    ) public view returns (uint256) {  // internal
        Decimal.D256 memory  dpPirce = Decimal.one().div(_averagePrice);
        uint256 radicand = dpPirce.mul(reserveDp).mul(reserveOther).asUint256();
        uint256 root = SafeMathCopy.sqrt(radicand);
        if (root > reserveDp) {
            return (root - reserveDp).mul(1000).div(997);
        }
        return (reserveDp - root).mul(1000).div(997);
    }

    function priceOverAvg() external override view returns(bool){
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
        (_averagePrice,,) = _oracle.getSwapPrice(address(_dp));
        _finalPrice = _averagePrice;
    }


    function getBuyIncentive(uint256 amount)
    public
    view
    returns (uint256 incentive)
    {
        (
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation,
        uint256 reserveDp,
        uint256 reserveOther
        ) = _getPriceDeviations();


        if (initialDeviation.equals(Decimal.zero())) {
            return (0);
        }

        uint256 incentivizedAmount = amount;

        if (finalDeviation.equals(Decimal.zero())) {
            incentivizedAmount = _getAmountToAvg(reserveDp, reserveOther);
        }

        Decimal.D256 memory multiplier =
        _calculateBuyIncentiveMultiplier(initialDeviation, finalDeviation);
        incentive = multiplier.mul(incentivizedAmount).asUint256();
        return (incentive);
    }

    function _calculateBuyIncentiveMultiplier(
        Decimal.D256 memory initialDeviation,
        Decimal.D256 memory finalDeviation
    ) internal view returns (Decimal.D256 memory) {
        Decimal.D256 memory correspondingPenalty =
        _calculateIntegratedSellPenaltyMultiplier(finalDeviation, initialDeviation); 

        Decimal.D256 memory buyMultiplier =
        initialDeviation.mul(underAvgWeight).div(_volume);

        if (correspondingPenalty.lessThan(buyMultiplier)) { 
            return correspondingPenalty;
        }
        return buyMultiplier;
    }

    function changeOwner(address newOwner) external onlyOwner{
        require(address(newOwner) != address(0),"new owner can not be null");
        _owner = newOwner;
    }
    function setCoreContract(address core) external onlyOwner{
        require(address(core) != address(0),"new owner can not be zero address");
        _core = core;
    }

}