/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// File: contracts/libs/goldpegas/Context.sol

pragma solidity 0.4.25;

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
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/libs/goldpegas/Auth.sol

pragma solidity 0.4.25;


contract Auth is Context {

  address internal mainAdmin;
  address internal backupAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  constructor(
    address _mainAdmin,
    address _backupAdmin
  ) internal {
    mainAdmin = _mainAdmin;
    backupAdmin = _backupAdmin;
  }

  modifier onlyMainAdmin() {
    require(isMainAdmin(), 'onlyMainAdmin');
    _;
  }

  modifier onlyBackupAdmin() {
    require(isBackupAdmin(), 'onlyBackupAdmin');
    _;
  }

  function transferOwnership(address _newOwner) onlyBackupAdmin internal {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(_msgSender(), _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
    return _msgSender() == mainAdmin;
  }

  function isBackupAdmin() public view returns (bool) {
    return _msgSender() == backupAdmin;
  }
}

// File: contracts/libs/zeppelin/math/SafeMath.sol

pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
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
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
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

// File: contracts/libs/zeppelin/token/BEP20/IBEP20.sol

pragma solidity 0.4.25;

contract IBEP20 {
    function totalSupply() public view returns (uint256);
    function decimals() public view returns (uint8);
    function symbol() public view returns (string memory);
    function name() public view returns (string memory);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function allowance(address _owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/libs/zeppelin/token/BEP20/IGDP.sol

pragma solidity 0.4.25;


contract IGDP is IBEP20 {
  function burn(uint _amount) external;
  function releaseFarmAllocation(address _farmerAddress, uint256 _amount) external;
}

// File: contracts/Stake.sol

pragma solidity 0.4.25;




contract Stake is Auth {
  using SafeMath for uint;

//  IGDP public gdpToken = IGDP(0xe724279dCB071c3996A1D72dEFCF7124C3C45082); // TODO mainnet
  IGDP public gdpToken = IGDP(0x33eb4d829a9c5224E25Eb828E2a11550308c885E);

//  uint[] mapBlockPackage = [288000, 864000, 2592000, 5184000, 10368000]; // TODO mainet
  uint[] mapBlockPackage = [100, 200, 300, 400, 500];

  uint[] public interestRates = [4, 13, 45, 120, 320];
  uint public totalStaked = 0;
  uint public totalRewards = 0;

  struct UserStake {
    uint startBlock;
    uint endBlock;
    uint package;
    uint interestRate;
    uint lastReward;
    uint amount;
    bool isWithdrawn;
  }
  mapping(address => UserStake[]) users;

  event Staked(address indexed _user, uint _amount, uint _stakedIndex);
  event Claimed(address indexed _user, uint _stakedIndex, uint _amount);
  event Withdrawn(address indexed _user, uint _stakedIndex, uint _amount);

  constructor(
    address _mainAdmin,
    address _backupAdmin
  ) public Auth(_mainAdmin, _backupAdmin) {
  }

  function updateMainAdmin(address _newMainAdmin) onlyBackupAdmin public {
    require(_newMainAdmin != address(0), 'invalid mainAdmin address');
    mainAdmin = _newMainAdmin;
  }

  function updateBackupAdmin(address _newBackupAdmin) onlyBackupAdmin public {
    require(_newBackupAdmin != address(0), 'invalid backupAdmin address');
    backupAdmin = _newBackupAdmin;
  }

  function stake(uint _package, uint _amount) public {
    require(_amount > 0, 'Invalid amount');
    require(mapBlockPackage[_package] > 0, 'Invalid package');
    uint currentBlock = block.number;
    gdpToken.transferFrom(_msgSender(), address(this), _amount);

    users[_msgSender()].push(UserStake(currentBlock, currentBlock.add(mapBlockPackage[_package]), _package, interestRates[_package], currentBlock, _amount, false));
    totalStaked = totalStaked.add(_amount);
    emit Staked(_msgSender(), _amount, users[_msgSender()].length.sub(1));
  }

  function claim(uint _stakedIndex) public {
    require(_stakedIndex < users[_msgSender()].length, 'Invalid stake');
    UserStake storage userStake = users[_msgSender()][_stakedIndex];

    _claim(userStake, _stakedIndex);
  }

  function _claim(UserStake storage userStake, uint _stakedIndex) private {
    require(userStake.lastReward < userStake.endBlock, 'Claimed all');
    require(block.number > userStake.lastReward, 'Invalid block');

    uint currentBlock = block.number >= userStake.endBlock ? userStake.endBlock : block.number;
    uint blocksWillClaim = currentBlock - userStake.lastReward;

    uint totalRewardAmount = userStake.interestRate.mul(userStake.amount).div(100);
    uint rewardEachBlock = totalRewardAmount.div(mapBlockPackage[userStake.package]);
    uint claimAmount = rewardEachBlock.mul(blocksWillClaim);

    userStake.lastReward = currentBlock;
    gdpToken.transfer(_msgSender(), claimAmount);
    totalRewards = totalRewards.add(claimAmount);

    emit Claimed(_msgSender(), _stakedIndex, claimAmount);
  }

  function withdraw(uint _stakedIndex) public {
    require(_stakedIndex < users[_msgSender()].length, 'Invalid stake');
    UserStake storage userStake = users[_msgSender()][_stakedIndex];
    require(!userStake.isWithdrawn, 'Already withdraw');
    uint currentBlock = block.number;
    require(currentBlock >= userStake.endBlock, 'Too early to withdraw');

    if (userStake.lastReward < userStake.endBlock) {
      _claim(userStake, _stakedIndex);
    }

    userStake.isWithdrawn = true;
    gdpToken.transfer(_msgSender(), userStake.amount);

    emit Withdrawn(_msgSender(), _stakedIndex, userStake.amount);
  }

  function getUserStakes(uint _stakedIndex) public view returns (uint, uint, uint, uint, uint, uint, bool) {
    require(users[_msgSender()][_stakedIndex].amount > 0, 'Stake not found');
    UserStake storage userStake = users[_msgSender()][_stakedIndex];

    return (
      userStake.startBlock,
      userStake.endBlock,
      userStake.package,
      userStake.interestRate,
      userStake.lastReward,
      userStake.amount,
      userStake.isWithdrawn
    );
  }

  function getUserTotalStaked() public view returns (uint) {
    return users[_msgSender()].length;
  }

  function setInterestRate(uint[] _rate) public onlyMainAdmin() {
    require(_rate.length == 5, 'Invalid rate');

    interestRates = _rate;
  }
}