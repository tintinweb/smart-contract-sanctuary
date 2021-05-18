/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: CollateralStakingState.sol
*
* Latest source (may be newer): https://github.com/Synthetixio/synthetix/blob/master/contracts/CollateralStakingState.sol
* Docs: https://docs.synthetix.io/contracts/CollateralStakingState
*
* Contract Dependencies: 
*	- ICollateralStakingState
*	- Owned
*	- State
* Libraries: 
*	- DataTypesLib
*	- SafeDecimalMath
*	- SafeMath
*
* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;


// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// Inheritance


// https://docs.synthetix.io/contracts/source/contracts/state
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Libraries


// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


pragma experimental ABIEncoderV2;

library DataTypesLib {
    struct Loan {
        //  Acccount that created the loan
        address account;
        //  Amount of collateral deposited
        uint collateral;
        //  Amount of synths borrowed
        uint amount;
    }

    struct Fund {
        uint debt;
        uint donation;
    }

    struct Staking {
        //V1 + V2
        uint lastCollaterals;
        uint lastRewardPerToken;
        //V2
        uint collaterals;
        uint round;
        //奖励
        uint rewards;
    }

    //aave
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }
}


interface ICollateralStakingState {
    function token() external view returns (address);

    function interestPool() external view returns (address);

    function canStaking() external view returns (bool);

    function totalCollateral() external view returns (uint);

    function getStaking(address account) external view returns (DataTypesLib.Staking memory);

    function surplus() external view returns (uint);

    function earned(uint total, address account) external view returns (uint);

    function calExtract(uint collateral, uint reward) external returns (uint);

    function extractUpdate(
        address account,
        uint amount,
        uint reward
    ) external returns (uint, uint);

    function pledgeUpdate(
        address account,
        uint collateral,
        uint reward
    ) external;

    function updateLastRecord(uint total) external;

    function updateLastBlockAndRewardPerToken(uint total) external;

    function savingsUpdate() external;
}


// Inheritance


contract CollateralStakingState is Owned, State, ICollateralStakingState {
    using SafeMath for uint;

    //抵押物地址
    address public token;
    //生息池
    address public interestPool;
    //是否开启staking
    bool public canStaking;
    //总抵押物
    uint public totalCollateral;
    //上一次全局每一个token对应的奖励记录
    uint private lastRewardPerTokenStored;
    //上次更新的块高度
    uint private lastUpdateBlock;
    //上一次抵押+奖励记录
    uint private lastRecord;
    //已抵押但未存款资产
    uint private unsecured;
    //
    uint private withdrawReward;
    //当前轮次
    uint private round;
    //每一轮次的奖励份额
    mapping(uint => uint) private roundRewardPerToken;
    //用户的staking信息
    mapping(address => DataTypesLib.Staking) public staking;

    constructor(
        address _owner,
        address _associatedContract,
        address _token,
        bool _canStaking,
        address _interestPool
    ) public Owned(_owner) State(_associatedContract) {
        token = _token;
        canStaking = _canStaking;
        interestPool = _interestPool;
    }

    /*
     * @notion 获取上次操作后累计的奖励
     *
     */
    function lastReward(uint total) internal view returns (uint) {
        //如果余额为0，未抵押，没有奖励
        if (total == 0) {
            return 0;
        }
        //若上一次记录为0，默认取总抵押数量
        uint lastTotal = lastRecord;
        if (lastTotal == 0) {
            lastTotal = totalCollateral;
        }
        return total.sub(lastTotal);
    }

    /*
     * @notion 计算每一个token对应的奖励数量
     *
     */
    function rewardPerToken(uint total) internal view returns (uint) {
        //抵押为0，或者同一个块内多次操作，返回上一次计算的值
        if (totalCollateral == 0 || block.number <= lastUpdateBlock) {
            return lastRewardPerTokenStored;
        }
        //当前token对应奖励 = 上一次token对应奖励 + (新一轮奖励 / 总token)
        return lastRewardPerTokenStored.add(lastReward(total).mul(1e18).div(totalCollateral));
    }

    function earned(uint total, address account) public view returns (uint) {
        DataTypesLib.Staking memory s = staking[account];
        uint currentRewardPerToken = rewardPerToken(total);
        if (currentRewardPerToken == 0 || currentRewardPerToken <= s.lastRewardPerToken) {
            return s.rewards;
        }
        uint lastRewards =
            s.lastCollaterals == 0
                ? s.rewards
                : s.lastCollaterals.mul(currentRewardPerToken.sub(s.lastRewardPerToken)).div(1e18).add(s.rewards);
        //同一轮次内多次抵押
        if (s.round > 0 && roundRewardPerToken[s.round] == 0) {
            return lastRewards;
        }
        //第一轮round=0时，一个地址存储多次，此时currentRewardPerToken为0
        return s.collaterals.mul(currentRewardPerToken.sub(roundRewardPerToken[s.round])).div(1e18).add(lastRewards);
    }

    function updateLastBlockAndRewardPerToken(uint total) public onlyAssociatedContract {
        lastRewardPerTokenStored = rewardPerToken(total);
        lastUpdateBlock = block.number;
    }

    function updateLastRecord(uint total) public onlyAssociatedContract {
        lastRecord = total;
    }

    /**
     * V2模式(精确分配利息)
     * 用户抵押到本合约时，计算以前抵押物的利息，并更新以前抵押物的rewardPerToken，同时记录当前抵押的数量和当前的轮次round
     * 调用批量存款方法，计算当前rewardPerToken，记录当前轮次的rewardPerToken，轮次加1
     * 若用户有抵押物未被存款到aave，计算利息时根据当前轮次，不计算未被存款的抵押物的利息
     * 若用户当前轮次的抵押物已被存款到aave，计算利息时需要计算当前轮次的利息，如果此时用户存款或提现，需要把当前轮次中的抵押物加入以前的总抵押物中
     */

    /**
     * unsecured: 未抵押生息的数量
     * totalCollateral: 总抵押生息的数量
     * collateral: 用户要提现抵押物的数量
     * reward: 当前要提现的奖励
     * totalWithdraw: 提现抵押物 + 提现奖励
     * 1. unsecured足够，提现unsecured中的抵押物
     *  totalCollateral:1000 | unsecured:2000 | collateral:1000 | reward:100 | totalWithdraw:(总提现:collateral+reward):1100
     *   |---> unsecured足够，直接扣除unsecured中1100，其中1000为抵押，100为奖励
     *
     * 2. unsecured不足，但是不需要从总抵押中提现
     *  totalCollateral:1000 | unsecured:900 | collateral:1000 | reward:100 | totalWithdraw(总提现:collateral+reward):1100
     *   |---> 需要提现1100，unsecured不足，先扣unsecured中900，剩余200，需要从totalCollateral存款中提现
     *   |---> 剩余200中，100是抵押物，需要在totalCollateral中扣除100，totalCollateral剩余900
     *
     * 3. unsecured不足，需要从总抵押中提现
     *  totalCollateral:50 | unsecured:1100 | collateral:1000 | reward:200 | totalWithdraw:(总提现:collateral+reward):1200
     *   |---> 需要提现1200，unsecured不足，先扣unsecured中1100，其中1000为抵押，100为奖励，剩余100
     *   |---> 剩余100是奖励，不需要在totalCollateral中扣除
     */
    function calExtract(uint collateral, uint reward) public onlyAssociatedContract returns (uint) {
        //总提现数量
        uint totalWithdraw = collateral.add(reward);
        //1. unsecured足够，提现unsecured中的抵押物
        if (unsecured >= totalWithdraw) {
            unsecured = unsecured.sub(collateral);
            //当未存款抵押足够时，提现数量中包含利息，此时要记录利息，在下一次存款时减去利息部分
            withdrawReward = withdrawReward.add(reward);
            return 0;
        }
        //2. unsecured不足，但是不需要从总抵押中提现
        if (unsecured >= collateral) {
            totalWithdraw = totalWithdraw.sub(unsecured);
            unsecured = unsecured.sub(collateral);
        } else {
            //3. unsecured不足，需要从总抵押中提现
            totalCollateral = totalCollateral.sub(collateral.sub(unsecured));
            totalWithdraw = totalWithdraw.sub(unsecured);
            unsecured = 0;
        }
        return totalWithdraw;
    }

    function pledgeUpdate(
        address account,
        uint collateral,
        uint reward
    ) public onlyAssociatedContract {
        DataTypesLib.Staking storage s = staking[account];
        //计算收益
        s.rewards = reward;
        //更新数据
        s.lastRewardPerToken = lastRewardPerTokenStored;
        //s.round==0 && round==0 ----> 第一个地址第一轮第一次存款
        //s.round==0 && round>0 && s.collaterals==0 ----> 某一个地址某一轮第一次存款
        //s.round>0 && s.round==round ----> 某一个地址某一轮第n次存款
        if ((s.round == 0 && (round == 0 || (round > 0 && s.collaterals == 0))) || (s.round > 0 && s.round == round)) {
            s.collaterals = s.collaterals.add(collateral);
        } else {
            s.lastCollaterals = s.lastCollaterals.add(s.collaterals);
            s.collaterals = collateral;
        }
        s.round = round;
        //统计当前未存款的抵押物
        unsecured = unsecured.add(collateral);
    }

    function extractUpdate(
        address account,
        uint amount,
        uint reward
    ) public onlyAssociatedContract returns (uint, uint) {
        DataTypesLib.Staking storage s = staking[account];
        //计算收益
        s.rewards = reward;
        //当提取全部抵押物时，需要提取抵押物，其他情况默认不提取
        reward = 0;
        //更新数据
        uint userCollateral = s.lastCollaterals.add(s.collaterals);
        if (amount >= userCollateral) {
            //全部提取出来
            reward = s.rewards;
            //全部提取时，奖励也要提取
            amount = userCollateral;
            delete staking[account];
        } else {
            //落后当前轮次时，需要把轮次中的抵押数量加到以前的抵押数量中
            if (s.round < round) {
                s.lastCollaterals = s.lastCollaterals.add(s.collaterals);
                s.collaterals = 0;
            }
            //部分提取出来
            if (s.collaterals > amount) {
                //全部从未抵押中提取
                s.collaterals = s.collaterals.sub(amount);
            } else {
                //已抵押中提现部分，未抵押全部提现
                s.lastCollaterals = s.lastCollaterals.sub(amount.sub(s.collaterals));
                s.collaterals = 0;
            }
            s.lastRewardPerToken = lastRewardPerTokenStored;
        }
        return (amount, reward);
    }

    function surplus() public view returns (uint) {
        return unsecured.sub(withdrawReward);
    }

    function savingsUpdate() public onlyAssociatedContract {
        //实际存款中减去利息部分，但是总抵押要加上真正的存款数量
        totalCollateral = totalCollateral.add(unsecured);
        //更新未存款金额
        unsecured = 0;
        withdrawReward = 0;
        //更新轮次
        roundRewardPerToken[round] = lastRewardPerTokenStored;
        round = round.add(1);
    }

    function getStaking(address account) external view returns (DataTypesLib.Staking memory) {
        DataTypesLib.Staking memory s = staking[account];
        return s;
    }
}