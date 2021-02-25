//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract StakBank is Ownable {
    using SafeMath for uint;
    IERC20 public token;

    mapping(address => uint) private _staking;
    
    uint public periodTime;
    uint public feeUnit;
    uint public minAmountToStake;
    uint public lastDis;
    uint public decimal;
    uint public minEthNeededToReward; // 0.0006 eth =  600000000000000 wei = (10^9 / 0.0001) * 60(second | minute) -> pool can hold max 1 billion JST
    uint public ethRewardedNotWithdraw;
    uint public totalStaked;

    uint private unitCoinToDivide; // 1e14 = 100000000000000 = 0.0001 JST | Number of staked (JST) coin to be rewarded = 0.0001 * N
    uint private _cummEth;
    uint private _totalStakedBeforeLastDis;

    struct Transaction {
        address staker;
        uint timestamp;
        uint coinToCalcReward;
        uint detailId;
    }

    Transaction[] private stakingTrans;
    
    struct Detail {
        uint stakedAmount;
        uint coinToCalcReward;
        uint ethFirstReward;
        uint cummEthLastWithdraw;
        bool isOldCoin;
        bool isUnstaked;

        uint timestamp;
    }

    mapping(address => Detail[]) private _eStaker;
    
    event UserStaked(address indexed user, uint amount, uint timestamp);
    event UserUnstakedWithId(address indexed user, uint indexed detailId, uint rewardAmount);
    event UserUnstakedAll(address indexed user);
    event AdminDistributeReward(uint ethToReward, uint ethRewardedInThisDis);
    event UserWithdrawedReward(address indexed user, uint rewardAmount);
    event StakBankConfigurationChanged(address indexed changer, uint timestamp);

    constructor(address _tokenAddress, uint _periodTime, uint _feeUnit, uint _decimal) {
        token = IERC20(_tokenAddress);
        periodTime = _periodTime;
        feeUnit = _feeUnit;
        minAmountToStake = 100000000000000;
        lastDis = block.timestamp;
        decimal = _decimal;
        minEthNeededToReward = 600000000000000;
        totalStaked = 0;

        unitCoinToDivide = 100000000000000;
        ethRewardedNotWithdraw = 0;
        _cummEth = 0;
        _totalStakedBeforeLastDis = 0;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    //------------------ setter func-------------------/
    function setPeriodTime(uint value) external onlyOwner {
        require(value > 0, "Minimum time to next distribution must be positive number");

        periodTime = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setFeeUnit(uint value) external onlyOwner {
        feeUnit = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setDecimal(uint value) external onlyOwner {
        decimal = value;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setMinAmountToStake(uint value) external onlyOwner {
        require(value >= unitCoinToDivide, "Lower than 0.0001 JST");

        minAmountToStake = value;
        
        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    //-------------------helper public func-------------------/
    
    function nextDistribution() public view returns (uint) {
        uint cur = block.timestamp;
        if (cur >= lastDis + periodTime) return 0;
        return (periodTime - (cur - lastDis));
    }

    function numEthToReward() public view returns (uint) {
        return ((address(this).balance) - ethRewardedNotWithdraw);
    }

    function feeCalculator(uint amount) public view returns (uint) {
        uint remainder = amount % unitCoinToDivide;
        amount = amount.sub(remainder);
        uint platformFee = amount.mul(feeUnit).div(10 ** decimal);
        return platformFee;
    }

    //-------------------staking--------------------/
    function stake(uint stakedAmount) public payable {
        require(msg.sender != owner, "Owner cannot stake");
        require(stakedAmount >= minAmountToStake, "Need to stake more token");
        require(totalStaked + stakedAmount <= (10 ** 27), "Reached limit coin in pool");

        uint platformFee = feeCalculator(stakedAmount);

        require(msg.value >= platformFee);
        require(_deliverTokensFrom(msg.sender, address(this), stakedAmount), "Failed to transfer from staker to StakBank");
        
        uint current = block.timestamp;

        _staking[msg.sender] = _staking[msg.sender].add(stakedAmount);
        totalStaked = totalStaked.add(stakedAmount);

        uint remainder = stakedAmount % unitCoinToDivide;
        uint coinToCalcReward = stakedAmount - remainder;

        _createNewTransaction(msg.sender, current, stakedAmount, coinToCalcReward);

        address payable admin = address(uint(address(owner)));
        admin.transfer(platformFee);

        emit UserStaked(msg.sender, stakedAmount, current);
    }

    function stakingOf(address user) public view returns (uint) {
        return (_staking[user]);
    }

    function unstakeId(address sender, uint idStake) private {
        Detail memory detail = _eStaker[sender][idStake - 1];
        uint coinNum = detail.stakedAmount;

        _deliverTokens(sender, coinNum);

        _staking[sender] = _staking[sender].sub(coinNum);

        _eStaker[sender][idStake - 1].isUnstaked = true;

        totalStaked = totalStaked.sub(coinNum);
    }

    function unstakeWithId(uint idStake) public {
        require(_isHolder(msg.sender), "Not a Staker");
        require(_eStaker[msg.sender].length > 1, "Cannot unstake the last with this method");
        require(!_isUnstaked(msg.sender, idStake), "idStake unstaked");

        Detail memory detail = _eStaker[msg.sender][idStake - 1];
        uint reward = 0;

        if (detail.isOldCoin) {
            _totalStakedBeforeLastDis = _totalStakedBeforeLastDis.sub(detail.coinToCalcReward);
            reward = _cummEth.sub(detail.cummEthLastWithdraw);

            uint numUnitCoin = (detail.coinToCalcReward).div(unitCoinToDivide);
            reward = reward.mul(numUnitCoin);
            reward = reward.add(detail.ethFirstReward);

            address payable staker = address(uint160(address(msg.sender)));
            staker.transfer(reward);

            ethRewardedNotWithdraw = ethRewardedNotWithdraw.sub(reward);
        }

        unstakeId(msg.sender, idStake);

        emit UserUnstakedWithId(msg.sender, idStake, reward);
    }

    function unstakeAll() public {
        require(_isHolder(msg.sender), "Not a Staker");

        withdrawReward();

        for(uint i = 0; i < _eStaker[msg.sender].length; i++) {
            if (!_isUnstaked(msg.sender, i + 1)) {
                unstakeId(msg.sender, i + 1);
            }
        }

        delete _eStaker[msg.sender];

        emit UserUnstakedAll(msg.sender);
    }

    //-------------------reward-------------------/
    function rewardDistribution() public onlyOwner {
        uint current = block.timestamp;
        uint timelast = current.sub(lastDis);
        
        require(timelast >= periodTime, "Too soon to trigger reward distribution");

        uint ethToReward = numEthToReward();

        if (ethToReward < minEthNeededToReward) { // --> not distribution when too few eth
            _notEnoughEthToReward();
            return;
        }
        
        uint unitTime;
        (timelast, unitTime) = _changeToAnotherUnitTime(timelast);
        
        uint UnitCoinNumberBeforeLastDis = _totalStakedBeforeLastDis.div(unitCoinToDivide);
        uint totalTime = timelast.mul(UnitCoinNumberBeforeLastDis);

        for(uint i = 0; i < stakingTrans.length; i++) {
            Transaction memory transaction = stakingTrans[i];

            if (!_isHolder(transaction.staker) || _isUnstaked(transaction.staker, transaction.detailId)) {
                continue;
            }

            uint numTimeWithStandardUnit = (current.sub(transaction.timestamp)).div(unitTime);
            uint numUnitCoin = (transaction.coinToCalcReward).div(unitCoinToDivide);

            totalTime = totalTime.add(numUnitCoin.mul(numTimeWithStandardUnit));
        }

        uint ethRewardedInThisDis = 0;

        if (totalTime > 0) {
            uint unitValue = ethToReward.div(totalTime);
            _cummEth = _cummEth.add(unitValue.mul(timelast));

            for(uint i = 0; i < stakingTrans.length; i++) {
                Transaction memory transaction = stakingTrans[i];

                if (!_isHolder(transaction.staker) || _isUnstaked(transaction.staker, transaction.detailId)) {
                    continue;
                }

                uint idStake = transaction.detailId;
                _eStaker[ transaction.staker ][ idStake - 1 ].cummEthLastWithdraw = _cummEth;
                
                uint numTimeWithStandardUnit = (current.sub(transaction.timestamp)).div(unitTime);
                uint numUnitCoin = (transaction.coinToCalcReward).div(unitCoinToDivide);

                _eStaker[ transaction.staker ][ idStake - 1 ].ethFirstReward = unitValue.mul(numUnitCoin).mul(numTimeWithStandardUnit);
 
                _totalStakedBeforeLastDis = _totalStakedBeforeLastDis.add(transaction.coinToCalcReward);
                _eStaker[ transaction.staker ][ idStake - 1 ].isOldCoin = true;
            }

            delete stakingTrans;
            ethRewardedInThisDis = unitValue.mul(totalTime);
            ethRewardedNotWithdraw = ethRewardedNotWithdraw.add(ethRewardedInThisDis);
        }

        lastDis = block.timestamp;

        emit AdminDistributeReward(ethToReward, ethRewardedInThisDis);
    }

    function withdrawReward() public {
        require(_isHolder(msg.sender), "Not a Staker");

        uint userReward = 0;

        for(uint i = 0; i < _eStaker[msg.sender].length; i++) {
            Detail memory detail = _eStaker[msg.sender][i];

            if (!detail.isOldCoin || detail.isUnstaked) {
                continue;
            }

            uint numUnitCoin = (detail.coinToCalcReward).div(unitCoinToDivide);

            uint addEth = (numUnitCoin).mul(_cummEth.sub(detail.cummEthLastWithdraw));
            addEth = addEth.add(detail.ethFirstReward);
            userReward = userReward.add(addEth);

            _eStaker[msg.sender][i].ethFirstReward = 0;
            _eStaker[msg.sender][i].cummEthLastWithdraw = _cummEth;
        }

        address payable staker = address(uint(address(msg.sender)));

        staker.transfer(userReward);

        ethRewardedNotWithdraw = ethRewardedNotWithdraw.sub(userReward);

        emit UserWithdrawedReward(msg.sender, userReward);
    }

    //---------------------------------------------------------------------------

    function _createNewTransaction(address user, uint current, uint stakedAmount, uint coinToCalcReward) private {
        Detail memory detail = Detail(stakedAmount, coinToCalcReward, 0, 0, false, false, current);
        _eStaker[user].push(detail);

        Transaction memory t = Transaction(user, current, coinToCalcReward, _eStaker[user].length);
        stakingTrans.push(t);
    }

    function _isHolder(address holder) private view returns (bool) {
        return (_staking[holder] != 0);
    }

    function _isUnstaked(address user, uint idStake) private view returns (bool) {
        if ((idStake < 1) || (idStake > _eStaker[user].length)) {
            return true;
        }
        return (_eStaker[user][idStake - 1].isUnstaked);
    }

    function _deliverTokensFrom(address from, address to, uint amount) private returns (bool) {
        IERC20(token).transferFrom(from, to, amount);
        return true;    
    }

    function _deliverTokens(address to, uint amount) private returns (bool) {
        IERC20(token).transfer(to, amount);
        return true;
    }

    function _changeToAnotherUnitTime(uint second) private pure returns (uint, uint) {
        uint unitTime = 1;
        if (second <= 60) return (second, 1);

        unitTime = unitTime.mul(60);
        uint minute = second / unitTime;
        if (minute <= 60) return (minute, unitTime);

        unitTime = unitTime.mul(60);
        uint hour = second / unitTime;
        if (hour <= 24) return (hour, unitTime);

        unitTime = unitTime.mul(24);
        uint day = second / unitTime;
        if (day <= 30) return (day, unitTime);

        unitTime = unitTime.mul(30);
        uint month = second / unitTime;
        if (month <= 12) return (month, unitTime);

        unitTime = unitTime.mul(12);
        uint year = second / unitTime;
        if (year > 50) year = 50;
        return (year, unitTime);
    } 

    function sendAllEthToAdmin() external onlyOwner {
        address payable admin = address(uint160(address(owner)));
        admin.transfer(address(this).balance);
    }

    function _notEnoughEthToReward() private {
        for(uint i = 0; i < stakingTrans.length; i++) {
            Transaction memory transaction = stakingTrans[i];

            if (!_isHolder(transaction.staker) || _isUnstaked(transaction.staker, transaction.detailId)) {
                continue;
            }

            uint idStake = transaction.detailId;
            _eStaker[ transaction.staker ][ idStake - 1 ].cummEthLastWithdraw = _cummEth;

            _totalStakedBeforeLastDis = _totalStakedBeforeLastDis.add(transaction.coinToCalcReward);
            _eStaker[ transaction.staker ][ idStake - 1 ].isOldCoin = true;
        }

        delete stakingTrans;
    }

    function timeStakedTransaction(uint idStake) public view returns (uint) {
        if (idStake < 1 || idStake > _eStaker[msg.sender].length) return 0;
        return _eStaker[msg.sender][idStake - 1].timestamp;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
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
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
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