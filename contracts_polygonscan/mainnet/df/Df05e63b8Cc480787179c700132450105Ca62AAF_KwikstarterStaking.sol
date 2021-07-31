/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

// File contracts/interfaces/IRBAC.sol

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

pragma solidity ^0.7.6;

interface IRBAC {
  function isAdmin(address user) external view returns (bool);
}

// File contracts/libraries/SafeMath.sol

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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

pragma solidity ^0.7.6;

contract KwikstarterStaking is ReentrancyGuard, Ownable {
  // Using SafeMath library for mathematical operations over uint256
  using SafeMath for uint256;
//   using SafeERC20 for ERC20;

  /// Representing stake structure
  struct Stake {
    address user;
    uint256 amount;
    uint256 timestamp;
    uint256 unlockingTime;
    uint256 userReward;
    uint256 withdrawReward;
    bool isWithdrawn;
  }

  // Pointer to admin contract
  IRBAC public admin;

  // Array holding all stakes
  Stake[] public stakes;
  
  // Registeration Days StakingPool
  uint256 public registerationDays;

  // Token being staked
  IERC20 public token;
  
  
    // Token being rewarded
  IERC20 public rewardToken;

  // Mapping user to his stakes
  mapping(address => uint256[]) userToHisStakeIds;

  // Total amount staked at the moment
  uint256 public totalStaked;
  
  // Total amount staked at the moment
  uint256 public APY = 12;
  
  uint256 public oneYear = 365 days;
  
  uint public oneDay = 1 days;

  // Minimal time to stake in order to get eligible to participate in private sales
  uint256 public minimalTimeToStake;

  // Minimal amount staked
  uint256 public minimalAmountToStake;

  // Initially set token address and admin wallet address
  constructor(address _token, address _admin, address _rewardToken) {
    token = IERC20(_token);
    admin = IRBAC(_admin);
    rewardToken = IERC20(_rewardToken);
  }
    
     
  // Function which can be called only by admin
  function setStakingRules(
    uint256 _minimalTimeToStake,
    uint256 _minimalAmountToStake
  ) public {
    // Only admin can call this
    require(admin.isAdmin(msg.sender) == true);
    // Set minimal time to stake
    minimalTimeToStake = _minimalTimeToStake;
    // Set minimal amount to stake
    minimalAmountToStake = _minimalAmountToStake;
  }
  
  //function to update the Registeration days
  function updateRegisterationDays(uint256 _daysTime) onlyOwner public returns(uint256){
      uint Days = _daysTime;
       registerationDays = Days/86400;
       return registerationDays;
  }

  // Function to deposit tokens (create stake)
  function depositTokens(uint256 amount) public {
    // Require that user is meeting requirement for minimal stake amount
    require(amount >= minimalAmountToStake);
    // Allow only direct calls from EOA (Externally owner wallets - flashloan prevention)
    require(msg.sender == tx.origin);
    // Compute the ID of the stake
    uint256 stakeId = stakes.length;
    // Create new stake object
    Stake memory s =
      Stake({
        user: msg.sender,
        amount: amount,
        timestamp: block.timestamp,
        unlockingTime: block.timestamp.add(minimalTimeToStake),
        userReward: 0,
        withdrawReward:0,
        isWithdrawn: false
      });
    // Take tokens from the user
    token.transferFrom(msg.sender, address(this), amount);
    // Push stake to array of all stakes
    stakes.push(s);
    // Add stakeId to array of users stake ids
    userToHisStakeIds[msg.sender].push(stakeId);
    // Increase how much is staked in total
    totalStaked = totalStaked.add(amount);
  }
  
  function getRewardToken() public view returns(uint256){
      return rewardToken.balanceOf(address(this));
  }

  // Function where user can withdraw all his stakes
  function withdrawAllStakes() public {
    uint256 totalToWithdraw = 0;

    for (uint256 i = 0; i < userToHisStakeIds[msg.sender].length; i++) {
      uint256 stakeId = userToHisStakeIds[msg.sender][i];
      uint256 amountToWithdraw = withdrawStakeInternal(stakeId);
      totalToWithdraw = totalToWithdraw.add(amountToWithdraw);
    }

    if (totalToWithdraw > 0) {
      token.transfer(msg.sender, totalToWithdraw);
    }
  }

  function withdrawStake(uint256 stakeId) public {
    uint256 amount = withdrawStakeInternal(stakeId);
    require(amount > 0);
    token.transfer(msg.sender, amount);
  }
  
  //function for calculating total reward
  function calculateReward(uint _stakeId) public view returns (uint256) {
    require(userToHisStakeIds[msg.sender].length >= 0, "No stake found");
        Stake memory s = stakes[_stakeId];
        uint256 stakingDays =  (block.timestamp-s.timestamp).div(oneDay);
        uint256 rewardPerDay = ((s.amount.mul(APY)).div(oneYear)).div(100);
        uint256 rewardAmount = ((rewardPerDay.mul(stakingDays)).sub(s.withdrawReward));
    return rewardAmount;
  }
    

  function claimReward(address _user, uint256 _stakeId) public returns(bool){
      require(msg.sender == _user);
      uint256 amountToWithdraw = calculateReward(_stakeId);
      bool result = rewardToken.transfer(_user, amountToWithdraw);
      Stake storage s = stakes[_stakeId];
      s.withdrawReward = amountToWithdraw;
      return result;
  }

  function withdrawStakeInternal(uint256 stakeId) internal returns (uint256) {
    Stake storage s = stakes[stakeId];
    // Only user can withdraw his stakes
    require(s.user == msg.sender);
    // Stake can't be withdrawn more than once and time has to expire in order to make stake able to withdraw
    if (s.isWithdrawn == true || block.timestamp < s.unlockingTime) {
      return 0;
    } else {
      // Mark stake that it's withdrawn
      s.isWithdrawn = true;
      // Reduce total amount staked
      totalStaked = totalStaked.sub(s.amount);
      // Transfer back tokens to user
      return s.amount;
    }
  }
  
  function getAllUsersStaked() public view returns(uint256){
      return stakes.length;
  }

  // Function to get all stake ids for specific user
  function getUserStakeIds(address user)public view returns (uint256[] memory){
    return userToHisStakeIds[user];
  }

  function getHowManyStakesUserHas(address user) public view returns (uint256) {
    return userToHisStakeIds[user].length;
  }
  
  function withdrawRewardTokens(uint _amount) public onlyOwner returns(bool){
      return rewardToken.transfer(msg.sender, _amount);
      
  }

  function getAllUserStakes(address user) public view returns (uint256[] memory,uint256[] memory,uint256[] memory,bool[] memory){
    uint256 length = getHowManyStakesUserHas(user);

    uint256[] memory amountsStaked = new uint256[](length);
    uint256[] memory timestamps = new uint256[](length);
    uint256[] memory unlockingTime = new uint256[](length);
    bool[] memory isStakeWithdrawn = new bool[](length);

    for (uint256 i = 0; i < length; i++) {
      uint256 stakeId = userToHisStakeIds[user][i];
      Stake memory s = stakes[stakeId];

      amountsStaked[i] = s.amount;
      timestamps[i] = s.timestamp;
      unlockingTime[i] = s.unlockingTime;
      isStakeWithdrawn[i] = s.isWithdrawn;
    }

    return (amountsStaked, timestamps, unlockingTime, isStakeWithdrawn);
  }

  // Function to get total amount user staked in the contract
  function getTotalAmountUserStaked(address user)
    public
    view
    returns (uint256)
  {
    uint256[] memory userStakeIds = userToHisStakeIds[user];

    uint256 totalUserStaked = 0;

    for (uint256 i = 0; i < userStakeIds.length; i++) {
      uint256 stakeId = userStakeIds[i];
      Stake memory s = stakes[stakeId];
      // Counts only active stakes
      if (!s.isWithdrawn) {
        totalUserStaked = totalUserStaked.add(s.amount);
      }
    }

    return totalUserStaked;
  }
  
  function addRewardToken(uint256 _amount) public onlyOwner returns(bool){
      bool result = rewardToken.transfer(address(this), _amount);
      return result;
  }
  
  function register(uint256 _stakeId) public returns(uint256){
      Stake storage s = stakes[_stakeId];
      s.unlockingTime = s.unlockingTime.add(registerationDays);
      return s.unlockingTime;
  }

  // Compute weight of the user
  function computeUserWeight(address user) public view returns (uint256) {
    uint256 totalUserStaked = getTotalAmountUserStaked(user);
    return totalUserStaked.mul(10**18).div(totalStaked);
  }
}