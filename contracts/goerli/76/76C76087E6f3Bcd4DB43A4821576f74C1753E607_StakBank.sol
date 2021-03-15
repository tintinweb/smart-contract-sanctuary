//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./SafeERC20.sol";

contract StakBank is Ownable, Pausable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public token;
    address public usdt;

    mapping(address => uint) private _staking;
    
    uint public periodTime;
    uint public feePerDecimal;
    uint public decimal;
    uint public minAmountToStake;
    uint public lastDis;
    uint public totalStaked;
    uint public numberDistribution;

    uint private _hardcoin;
    uint private _softcoin;
    uint private _rewardedEth;
    uint private _rewardedUsdt;
    uint private _totalSoftcoinxTime;
    uint private MAXN;

    struct Request {
        uint timestamp;
        uint stakedAmount;
        uint firstDistId;
        uint lastWithdrawDistId;
        bool isUnstaked;
    }
    mapping(address => Request[]) private _eStaker;

    address[] stakeHolder;
    mapping(address => uint) stakeHolderPosInArray;

    struct DetailDistribution {
        uint timestamp;
        uint stdTime;
        uint virtualEthUnitValue;
        uint virtualUsdtUnitValue;
        uint cummVirtualEthUnitValuexTime;
        uint cummvirtualUsdtUnitValuexTime;
    }
    mapping (uint => DetailDistribution) private _detailDistribution;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    event UserStaked(address indexed user, uint amount, uint timestamp);
    event UserUnstakedWithId(address indexed user, uint indexed requestId, uint ethReward, uint usdtReward);
    event UserUnstakedAll(address indexed user);
    event AdminDistributeReward(uint ethToReward, uint usdtToReward);
    event UserWithdrawedReward(address indexed user, uint ethReward, uint usdtReward);
    event StakBankConfigurationChanged(address indexed changer, uint timestamp);

    constructor(address _tokenAddress, address _usdt, uint _periodTime, uint _feePerDecimal, uint _decimal) {
        token = IERC20(_tokenAddress);
        usdt = _usdt;
        
        periodTime = _periodTime;
        feePerDecimal = _feePerDecimal;
        decimal = _decimal;
        minAmountToStake = 100;
        lastDis = block.timestamp;
        totalStaked = 0;
        numberDistribution = 0;

        _hardcoin = 0;
        _softcoin = 0;
        _rewardedEth = 0;
        _rewardedUsdt = 0;
        _totalSoftcoinxTime = 0;

        MAXN = 10 ** 30;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    // setter function

    function setPeriodTime(uint _periodTime) external onlyOwner whenNotPaused {
        require(_periodTime > 0, "Minimum time to next distribution must be positive number");

        periodTime = _periodTime;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setFeePerDecimal(uint _feePerDecimal) external onlyOwner whenNotPaused {
        feePerDecimal = _feePerDecimal;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setDecimal(uint _decimal) external onlyOwner whenNotPaused {
        require(_decimal <= 20, "Too large");
        decimal = _decimal;

        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    function setMinAmountToStake(uint _minAmountToStake) external onlyOwner whenNotPaused {
        minAmountToStake = _minAmountToStake;
        
        emit StakBankConfigurationChanged(msg.sender, block.timestamp);
    }

    // view data func

    function countdownToNextDistribution() public view returns (uint) {
        uint cur = block.timestamp;
        if (cur >= lastDis + periodTime) return 0;
        return (periodTime - (cur - lastDis));
    }

    function estimateNextDistribution() public view returns (uint) {
        return (lastDis.add(periodTime));
    }

    function numEthToReward() public view returns (uint) {
        return ((address(this).balance) - _rewardedEth);
    }

    function numUsdtToReward() public view returns (uint) {
        return (_usdtBalanceOf(address(this)) - _rewardedUsdt);
    }

    function numberOfStakeHolder() public view returns (uint) {
        return stakeHolder.length;
    } 

    function feeCalculator(uint amount) public view returns (uint) {
        uint platformFee = amount.mul(feePerDecimal).div(10 ** decimal);
        return platformFee;
    }

    function stakingOf(address user) public view returns (uint) {
        return (_staking[user]);
    }

    function checkDetailStakingRequest(address user, uint idStake) 
        public view 
        returns (uint timestamp, uint stakedAmount, uint ethReward, uint usdtReward, bool isUnstaked) 
    {
        require(_isHolder(user));
        require((idStake > 0) && (idStake <= _eStaker[user].length), "Invalid idStake");

        Request memory request = _eStaker[user][idStake - 1];

        timestamp = request.timestamp;
        stakedAmount = request.stakedAmount;
        isUnstaked = request.isUnstaked;

        if (isUnstaked) {
            ethReward = 0;
            usdtReward = 0;    
        } else {
            ethReward = _calcEthReward(user, idStake);
            usdtReward = _calcUsdtReward(user, idStake);
        }

        return (timestamp, stakedAmount, ethReward, usdtReward, isUnstaked);
    }

    // staking func

    function stake(uint stakedAmount) public payable whenNotPaused {
        require(msg.sender != owner, "Owner cannot stake");
        require(stakedAmount >= minAmountToStake, "Need to stake more token");
        require(totalStaked + stakedAmount <= (10 ** 28), "Reach limit of pool");

        uint platformFee = feeCalculator(stakedAmount);

        require(msg.value >= platformFee);
        require(_deliverTokensFrom(msg.sender, address(this), stakedAmount), "Failed to transfer from staker to StakBank");

        uint current = block.timestamp;

        if (!_isHolder(msg.sender)) {
            stakeHolder.push(msg.sender);
            stakeHolderPosInArray[msg.sender] = stakeHolder.length;
        }

        _createNewRequest(msg.sender, current, stakedAmount);

        address payable admin = address(uint160(address(owner)));
        admin.transfer(platformFee);

        emit UserStaked(msg.sender, stakedAmount, current);
    }

    function unstakeWithId(uint idStake) public whenNotPaused {
        // idStake count from 1
        require(_isHolder(msg.sender), "Not a Staker");

        require(!_isUnstaked(msg.sender, idStake), "idStake unstaked");

        Request memory request = _eStaker[msg.sender][idStake - 1];
        
        uint ethReward = _calcEthReward(msg.sender, idStake);
        uint usdtReward = _calcUsdtReward(msg.sender, idStake);

        if (ethReward != 0) {
            address payable staker = address(uint160(address(msg.sender)));
            staker.transfer(ethReward);
        }

        if (usdtReward != 0) {
            _transferUSDT(msg.sender, usdtReward);
        }

        _rewardedEth = _rewardedEth.sub(ethReward);
        _rewardedUsdt = _rewardedUsdt.sub(usdtReward);

        _unstakeId(msg.sender, idStake);
        _deliverTokens(msg.sender, request.stakedAmount);

        if (stakingOf(msg.sender) == 0) {
            _deleteStaker(msg.sender);
        }

        emit UserUnstakedWithId(msg.sender, idStake, ethReward, usdtReward);
    }

    function unstakeAll() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        _unstakeAll(msg.sender);
    }

    function withdrawReward() public whenNotPaused {
        require(_isHolder(msg.sender), "Not a Staker");
        _withdrawReward(msg.sender);
    }

    function rewardDistribution() public onlyOwner whenNotPaused {
        require(countdownToNextDistribution() == 0, "Wait more time to trigger function");
        require(totalStaked != 0, "0 JST in pool");

        uint current = block.timestamp;
        uint ethToReward = numEthToReward();
        uint usdtToReward = numUsdtToReward();


        (uint pTime, uint stdTime) = _changeToAnotherUnitTime(periodTime);
        uint totalUnit = _hardcoin.mul(pTime);

        uint addUnitSoftcoin = (_softcoin.mul(current)).sub(_totalSoftcoinxTime);
        addUnitSoftcoin = addUnitSoftcoin.div(stdTime);

        totalUnit = totalUnit.add(addUnitSoftcoin);

        uint virtualEthUnitValue = (ethToReward.mul(MAXN)).div(totalUnit);
        uint virtualUsdtUnitValue = ((usdtToReward.mul(MAXN)).div(totalUnit));

        DetailDistribution memory lastDetail = _detailDistribution[ numberDistribution ];

        numberDistribution ++;

        _detailDistribution[ numberDistribution ] = DetailDistribution(current, stdTime, virtualEthUnitValue, virtualUsdtUnitValue,
                                                                    virtualEthUnitValue.mul(pTime) + lastDetail.cummVirtualEthUnitValuexTime, 
                                                                    virtualUsdtUnitValue.mul(pTime) + lastDetail.cummvirtualUsdtUnitValuexTime);

        // reset
        lastDis = block.timestamp;
        _hardcoin = _hardcoin.add(_softcoin);
        _softcoin = 0;
        _totalSoftcoinxTime = 0;

        _rewardedEth = address(this).balance;
        _rewardedUsdt = _usdtBalanceOf(address(this));

        emit AdminDistributeReward(ethToReward, usdtToReward);
    }

    // private staking func

    function _unstakeId(address user, uint idStake) private {
        Request memory request = _eStaker[user][idStake - 1];
        uint stakedAmount = request.stakedAmount;

        _staking[user] = _staking[user].sub(stakedAmount);
        _eStaker[user][idStake - 1].isUnstaked = true;
        
        totalStaked = totalStaked.sub(stakedAmount);
        if (numberDistribution < request.firstDistId) {
            _softcoin = _softcoin.sub(stakedAmount);
            _totalSoftcoinxTime = _totalSoftcoinxTime.sub(stakedAmount.mul(request.timestamp));
        } else {
            _hardcoin = _hardcoin.sub(stakedAmount);
        }
    }

    function _unstakeAll(address user) private {
        _withdrawReward(user);

        uint totalStakedAmount = stakingOf(user);

        for(uint i = 0; i < _eStaker[user].length; i++) {
            if (!_isUnstaked(user, i + 1)) {
                _unstakeId(user, i + 1);
            }
        }

        _deliverTokens(user, totalStakedAmount);
        _deleteStaker(user);
        
        emit UserUnstakedAll(user);
    }

    function _withdrawReward(address user) private {
        uint ethReward = 0;
        uint usdtReward = 0;

        for(uint i = 0; i < _eStaker[user].length; i++) {
            Request memory request = _eStaker[user][i];

            if (request.isUnstaked) {
                continue;
            }

            ethReward = ethReward.add( _calcEthReward(user, i + 1) );
            usdtReward = usdtReward.add( _calcUsdtReward(user, i + 1) );

            _eStaker[user][i].firstDistId = 0;
            _eStaker[user][i].lastWithdrawDistId = numberDistribution;
        }

        if (ethReward != 0) {
            address payable staker = address(uint160(address(user)));
            staker.transfer(ethReward);

            _rewardedEth = _rewardedEth.sub(ethReward);
        }

        if (usdtReward != 0) {
            _transferUSDT(user, usdtReward);

            _rewardedUsdt = _rewardedUsdt.sub(usdtReward);
        }

        emit UserWithdrawedReward(user, ethReward, usdtReward);
    }
    
    // helper func

    function _createNewRequest(address user, uint current, uint stakedAmount) private {
        _staking[user] = _staking[user].add(stakedAmount);
        totalStaked = totalStaked.add(stakedAmount);
        _softcoin = _softcoin.add(stakedAmount);
        _totalSoftcoinxTime = _totalSoftcoinxTime.add(stakedAmount.mul(current));

        Request memory request = Request(current, stakedAmount, numberDistribution + 1, numberDistribution + 1, false);
        _eStaker[user].push(request);
    }

    function _deleteStaker(address user) private {
        uint posInArray = stakeHolderPosInArray[user];
        stakeHolder[posInArray - 1] = stakeHolder[ stakeHolder.length - 1 ];
        stakeHolderPosInArray[ stakeHolder[posInArray - 1] ] = posInArray;
        stakeHolder.pop();

        delete _eStaker[user];
        delete stakeHolderPosInArray[user];

        // use remain money to reward in next distribution
        if (totalStaked == 0) {
            _rewardedEth = 0;
            _rewardedUsdt = 0;
        }
    }

    function _calcEthReward(address user, uint idStake) private view returns (uint) {
        Request memory request = _eStaker[user][idStake - 1];
        
        uint stakedAmount = request.stakedAmount;
        uint firstDisId = request.firstDistId;
        uint lastWithdrawDistId = request.lastWithdrawDistId;

        uint _cummVirtual = _detailDistribution[numberDistribution].cummVirtualEthUnitValuexTime
                                - _detailDistribution[lastWithdrawDistId].cummVirtualEthUnitValuexTime;

        uint money = stakedAmount.mul(_cummVirtual);

        if (firstDisId != 0) {
            // calc firstDis
            uint virtualFirst = _detailDistribution[firstDisId].virtualEthUnitValue; 

            uint time = ((_detailDistribution[firstDisId].timestamp).sub(request.timestamp));

            virtualFirst = virtualFirst.mul(time).div(_detailDistribution[firstDisId].stdTime);

            money = money.add(stakedAmount.mul(virtualFirst));
        }

        money = money.div(MAXN);
        return money;
    }

    function _calcUsdtReward(address user, uint idStake) private view returns (uint) {
        Request memory request = _eStaker[user][idStake - 1];
        
        uint stakedAmount = request.stakedAmount;
        uint firstDisId = request.firstDistId;
        uint lastWithdrawDistId = request.lastWithdrawDistId;

        uint _cummVirtual = _detailDistribution[numberDistribution].cummvirtualUsdtUnitValuexTime
                                - _detailDistribution[lastWithdrawDistId].cummvirtualUsdtUnitValuexTime;

        uint money = stakedAmount.mul(_cummVirtual);

        if (firstDisId != 0) {
            // calc firstDis
            uint virtualFirst = _detailDistribution[firstDisId].virtualUsdtUnitValue; 

            uint time = ((_detailDistribution[firstDisId].timestamp).sub(request.timestamp));

            virtualFirst = virtualFirst.mul(time).div(_detailDistribution[firstDisId].stdTime);

            money = money.add(stakedAmount.mul(virtualFirst));
        }

        money = money.div(MAXN);
        return money;
    }


    function _deliverTokensFrom(address from, address to, uint amount) private returns (bool) {
        IERC20(token).transferFrom(from, to, amount);
        return true;    
    }

    function _deliverTokens(address to, uint amount) private returns (bool) {
        IERC20(token).transfer(to, amount);
        return true;
    }

    function _safeTransfer(address _token, address to, uint value) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function _transferUSDT(address to, uint value) private {
        _safeTransfer(usdt, to, value);
    }

    // private view

    function _isHolder(address holder) private view returns (bool) {
        return (_staking[holder] != 0);
    }

    function _isUnstaked(address user, uint idStake) private view returns (bool) {
        require((idStake > 0) && (idStake <= _eStaker[user].length), "Invalid idStake");
        return (_eStaker[user][idStake - 1].isUnstaked);
    }

    function _usdtBalanceOf(address user) private view returns (uint) {
        IERC20 USDT = IERC20(usdt);
        return USDT.balanceOf(user);
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

    // close stakbank

    function closeStakBank(uint number) public onlyOwner whenNotPaused {
        require(number <= numberOfStakeHolder(), "larger than number staker in the pool");

        require(numberOfStakeHolder() != 0, "no have any staker in the pool");

        for (uint i = number - 1; i >= 0; i--) {
            _unstakeAll(stakeHolder[i]);
        }
        
        if (numberOfStakeHolder() == 0) {
            address payable admin = address(uint160(address(owner)));
            admin.transfer(address(this).balance);

            _transferUSDT(owner, _usdtBalanceOf(address(this)));
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

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
pragma solidity >=0.7.0 <0.8.0;


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

pragma solidity >=0.7.0 <0.8.0;

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

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.8.0;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

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