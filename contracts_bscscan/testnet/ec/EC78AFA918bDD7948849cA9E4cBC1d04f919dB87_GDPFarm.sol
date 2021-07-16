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

// File: contracts/libs/goldpegas/IFARM.sol

pragma solidity 0.4.25;

contract IFARM {
  uint public startBlock;
  uint public totalLock;
  uint public totalRewarded;
  uint public citizen;
  uint public lastRewardBlock;
  uint public accRewardPerShare;
  function userInfo(address _userAddress) external view returns (address, uint, uint, uint, uint, uint, uint, uint, uint);
  function referrers(address _userAddress) external view returns (address);
}

// File: contracts/GDPFarm.sol

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;






contract GDPFarm is Auth {
  using SafeMath for uint;

  struct User {
    address userAddress;
    uint firstDepositBlock;
    uint lpTokenAmount;
    uint rewardDebt;
    uint rewardDebtAtBlock;
    uint lockAmount;
    uint lastUnlockBlock;
    uint totalReferral;
    uint referralBonus;
  }

  // TODO mainnet
//  IGDP public gdpToken = IGDP(0xe724279dCB071c3996A1D72dEFCF7124C3C45082);
//  IBEP20 public lpToken = IBEP20(0);
//  address stakingContract = 0x0;
  // TODO testnet
  IGDP public gdpToken = IGDP(0x33eb4d829a9c5224E25Eb828E2a11550308c885E);
  IBEP20 public lpToken = IBEP20(0xdE3C4E3a8B436E82c2a031525568C37393637Cb3);
  address stakingContract = 0x054e1f1B209d92369F126B6Da42313D0164c90B0;
  // TODO end testnet
  // TODO local
//  IGDP public gdpToken = IGDP(0x01997B9F1a2BB987389D81884507Ca91C8953713);
//  IBEP20 public lpToken = IBEP20(0xA5F6Ef26c57e4E17daef5EB5F54dc6C014418dF7);
//  address stakingContract = 0xa5a8Be4c28218cc21047d334D035AC59fdBaE8F8;
  // TODO end local
  IFARM oldFarm = IFARM(address(this)); // testnet

  address newContractAddress;
  address defaultAddress;
  address public devAddress;
  uint public lastRewardBlock;
  uint public accRewardPerShare;
  uint constant public farmingAllocation = 645e6 * 10e18;
  uint constant public rewardPerBlock = 20e18;
  uint constant percentLockReward = 75;
  uint constant percentLockReferral = 50;
  uint constant percentLockDev = 75;
  uint constant percentForReward = 80;
  uint constant percentForReferral = 10;
  uint constant percentForDev = 10;
//  uint constant blocksIn30Days = 864000; // TODO mainnet
//  uint constant blocksIn180Days = 5184000;
  uint constant blocksIn30Days = 100;
  uint constant blocksIn180Days = 200;
  uint public startBlock;
  uint public totalLock;
  uint public referralDeep = 3;
  uint public totalRewarded;
  uint public citizen;

  //  uint[] bonusBlockCheckpoints = [403200, 806400, 1209600, 1612800]; // TODO mainnet
  uint[] bonusBlockCheckpoints = [1200, 2400, 4800, 9600];
  uint[] rewardMultipliers = [30, 25, 20, 15];
  uint[] referralBalanceCondition = [2e21, 4e21, 6e21, 8e21, 10e21, 12e21, 14e21, 16e21, 18e21, 20e21];

  mapping(address => address) public referrers;
  mapping(address => address[]) public listF1;
  mapping(address => User) public userInfo;

  event Deposited(address indexed user, uint amount);
  event Withdrew(address indexed user, uint amount);
  event EmergencyWithdrew(address indexed user, uint amount);
  event RewardSent(address indexed user, uint amount, uint releaseAmount, uint lockedAmount);
  event Locked(address indexed user, uint amount);
  event UnLock(address indexed user, uint amount);
  event ReferralRewardSent(address indexed user, address indexed referrer, uint amount, uint lockedAmount);
  event ReferralRewardClaimed(address indexed user, uint amount);

  constructor(
    address _mainAdmin,
    address _backupAdmin,
    address _defaultAddress
  ) public Auth(_mainAdmin, _backupAdmin) {
    devAddress = msg.sender;
    defaultAddress = _defaultAddress;
    listF1[0x68706A570919a887AeD9B9860880E034E7072462] = [
      0x0146fFEC36Be5533595D8697F67d8ffed5a16693,
      0xca93DF59cb5beA5d8EB02d1aa419D6068d03C096,
      0x9C1D4580B23f3987CF1Cfe0AA2b78d2bDef88A2a,
      0x10501D8E6880dc4B9e09663a2375Bec0c804B49a,
      0xAD79322cc01B5965A009a3DB58B2a6e38589F041,
      0xA7fFA23075017E2E6280692F99A6FAE7d5f8c3Be,
      0x1bfD0B639b72A4b252d410702825d6BE7E4bc075,
      0x00fbb5Dd79aEe0E97CC7ABF3e7D78D987d1C2455,
      0xdb135B638499335b4C11193Ac8D15C28196810b0,
      0x2BcC24CC5370777864675B15ce557cA290dF1299,
      0x667B6a29aE05c69fcDee7cdA50AA9383c0888c04,
      0xA5BE3528E276500A99840339c3c577DE9180E9b6,
      0x15b0B00897c8a68D1E48bF98bfa1c490312f0F54,
      0xd3b2FD205825D972555E9A2c62d276Cd885bA303,
      0x89417E0ea44D2dFEeeaEC5d843Cc050D1c1a08a2,
      0xcF57066674ad94248a448B81f482c43b710280Cb,
      0x1507C5471Ed68100bCE11497098cc9093D988f3c,
      0xa2B5078f5FdE2782f6D453C7303aff399F596E6f,
      0xE8440e03391Cb6E4ab1bA1dcf94a8FeB86Dd1962,
      0x53068e26Bb45B112fA56aDC109E82E5c63394191,
      0x463a5B099f49367B036478e8061FfF3eC510C337,
      0xD3F462799e2c7352c161971Bc1516232692300f3,
      0xf9c91dCb790B369AA04c0e6A6324bCFbF0b01DF2,
      0x9458cC3F7158c736e4435DDFF4a8F05786b9631b,
      0xeF2631e6440dD83967D9dc8cCC5865e928040006,
      0x7673b84Cef0501d8D5E9f9b360ba560d3519dD94,
      0xc1e6071442ac87A7d1fC59946D5E9e1eFA055Df7,
      0x3f98099678Ec94314C5351d29dAd006A3C0B462A,
      0x5CfBABFD6D0717addd770ED4bBAFE09B082D3Cde,
      0x0653Bfbf733da95c167e09646BB722b94a9F4F62
    ];
  }

  // OWNER FUNCTIONS
  function setStakingContractAddress(address _newAddress) public onlyMainAdmin {
    require(_newAddress != address(0), 'GDPFarm: Staking address is invalid');

    stakingContract = _newAddress;
  }

  function setDevAddress(address _newAddress) onlyMainAdmin public {
    require(_newAddress != address(0), 'GDPFarm: Dev address is invalid');
    require(_newAddress != devAddress, 'GDPFarm: Same with old dev address');
    devAddress = _newAddress;

    User storage newDevAccount = userInfo[devAddress];
    if (newDevAccount.userAddress == address(0)) {
      newDevAccount.userAddress = devAddress;
    }
    newDevAccount.firstDepositBlock = startBlock;
  }

  function setReferralDeep(uint _referralDeep) onlyMainAdmin public {
    require(_referralDeep > 0, 'GDPFarm: referral deep is invalid');
    require(_referralDeep != referralDeep, '_referralDeep: same with old referralDeep');

    referralDeep = _referralDeep;
  }

  function setReferralCondition(uint _level, uint _amount) onlyMainAdmin public {
    require(_level > 0, 'GDPFarm: level is invalid');
    require(referralBalanceCondition[_level] != _amount, 'GDPFarm: same with old condition');

    referralBalanceCondition[_level] = _amount;
  }

  function setStakingContract(address _stakingContract) onlyMainAdmin public {
    require(_stakingContract != address(0), 'GDPFarm: stakingContract is invalid');
    require(stakingContract != _stakingContract, 'GDPFarm: same with old stakingContract');

    stakingContract = _stakingContract;
  }

  function startFarm() onlyMainAdmin public {
    require(startBlock == 0, 'GDPFarm: farm had started');
    startBlock = block.number;
    lastRewardBlock = block.number;
    _initData();
  }

  function updateMainAdmin(address _newMainAdmin) onlyBackupAdmin public {
    require(_newMainAdmin != address(0), 'GDPFarm: invalid mainAdmin address');
    mainAdmin = _newMainAdmin;
  }

  function updateBackupAdmin(address _newBackupAdmin) onlyBackupAdmin public {
    require(_newBackupAdmin != address(0), 'GDPFarm: invalid backupAdmin address');
    backupAdmin = _newBackupAdmin;
  }

  // UPGRADING FUNCTIONS

  // OLD CONTRACT

  function setNewContract(address _newContractAddress) onlyMainAdmin public {
    require(_newContractAddress != address(0), 'GDPFarm: invalid newContractAddress');
    newContractAddress = _newContractAddress;
  }

  function backupSystem1() onlyMainAdmin public {
    gdpToken.transfer(newContractAddress, gdpToken.balanceOf(this));
    lpToken.transfer(newContractAddress, lpToken.balanceOf(this));
  }

  // NEW CONTRACT

  function backupSystem2(address[] _userAddresses) onlyMainAdmin public {
    for (uint i = 0; i < _userAddresses.length; i++) {
      address _userAddress = _userAddresses[i];
      (
        address userAddress,
        uint firstDepositBlock,
        uint lpTokenAmount,
        uint rewardDebt,
        uint rewardDebtAtBlock,
        uint lockAmount,
        uint lastUnlockBlock,
        uint totalReferral,
        uint referralBonus
      ) = oldFarm.userInfo(_userAddress);

      User storage user = userInfo[_userAddress];
      user.userAddress = userAddress;
      user.firstDepositBlock = firstDepositBlock;
      user.lpTokenAmount = lpTokenAmount;
      user.rewardDebt = rewardDebt;
      user.rewardDebtAtBlock = rewardDebtAtBlock;
      user.lockAmount = lockAmount;
      user.lastUnlockBlock = lastUnlockBlock;
      user.totalReferral = totalReferral;
      user.referralBonus = referralBonus;

      referrers[_userAddress] = oldFarm.referrers(_userAddress);
    }
  }

  function backupSystem3() onlyMainAdmin public {
    startBlock = oldFarm.startBlock();
    totalLock = oldFarm.totalLock();
    totalRewarded = oldFarm.totalRewarded();
    citizen = oldFarm.citizen();
    lastRewardBlock = oldFarm.lastRewardBlock();
    accRewardPerShare = oldFarm.accRewardPerShare();
  }

  // PUBLIC FUNCTIONS

  function updatePool() public {
    if (block.number <= lastRewardBlock) {
      return;
    }
    uint lpSupply = lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      lastRewardBlock = block.number;
      return;
    }

    uint forDev;
    uint forFarmer;
    (forDev, forFarmer) = getPoolReward();

    uint lockDevAmount = forDev.mul(percentLockDev).div(100);
    if (devAddress != address(0)) {
      gdpToken.releaseFarmAllocation(devAddress, forDev.sub(lockDevAmount));
      _farmLock(devAddress, lockDevAmount);
    }
    accRewardPerShare = accRewardPerShare.add(forFarmer.mul(1e12).div(lpSupply));
    lastRewardBlock = block.number;
  }

  function getPoolReward() public view returns (uint forDev, uint forFarmer) {
    uint multiplier = getMultiplier(lastRewardBlock, block.number);
    uint rewardAmount = multiplier.mul(rewardPerBlock).div(10);
    uint maxReward = farmingAllocation.sub(totalLock);

    if (maxReward < rewardAmount) {
      forFarmer = maxReward;
      forDev = 0;
    } else {
      forFarmer = rewardAmount.mul(percentForReward + percentForReferral).div(100);
      forDev = rewardAmount.sub(forFarmer);
    }
  }

  function getMultiplier(uint _from, uint _to) public view returns (uint) {
    uint result = 0;
    uint tempStartBlock = startBlock;
    if (_from < tempStartBlock) return 0;
    if (_from > tempStartBlock + bonusBlockCheckpoints[bonusBlockCheckpoints.length - 1]) {
      return _to.sub(_from).mul(10);
    }

    for (uint i = 0; i < bonusBlockCheckpoints.length; i++) {
      uint endBlock = tempStartBlock + bonusBlockCheckpoints[i];

      if (_to <= endBlock) {
        uint multipliedBlocks = _to.sub(_from).mul(rewardMultipliers[i]);
        return result.add(multipliedBlocks);
      }

      if (_from < endBlock) {
        uint multipliedBlocks2 = endBlock.sub(_from).mul(rewardMultipliers[i]);
        _from = endBlock;
        result = result.add(multipliedBlocks2);
      }
    }

    return result;
  }

  // EXTERNAL FUNCTIONS

  function deposit(uint _amount, address _referrer) external {
    require(startBlock > 0, 'GDPFarm: farm is not started');
    require(_amount > 0, 'GDPFarm: amount must be greater than 0');

    User storage user = userInfo[msg.sender];

    updatePool();
    _harvest(user);

    lpToken.transferFrom(address(msg.sender), address(this), _amount);
    if (user.lpTokenAmount == 0) {
      user.rewardDebtAtBlock = block.number;
    }
    if (user.userAddress == address(0x0)) {
      user.userAddress = msg.sender;
    }
    user.lpTokenAmount = user.lpTokenAmount.add(_amount);
    user.rewardDebt = user.lpTokenAmount.mul(accRewardPerShare).div(1e12);

    if (referrers[msg.sender] == address(0) && _referrer != msg.sender) {
      citizen += 1;
      if (_referrer != address(0)) {
        require(userInfo[_referrer].firstDepositBlock > 0, 'GDPFarm: referrer not found');
        referrers[msg.sender] = _referrer;
        listF1[_referrer].push(msg.sender);

        _increaseInviterTotalReferral(userInfo[_referrer]);
      } else {
        referrers[msg.sender] = defaultAddress;

        listF1[defaultAddress].push(msg.sender);
        _increaseInviterTotalReferral(userInfo[defaultAddress]);
      }
    }
    if (user.firstDepositBlock == 0) {
      user.firstDepositBlock = block.number;
    }
    emit Deposited(msg.sender, _amount);
  }

  function pendingReward() external view returns (uint) {
    User storage user = userInfo[msg.sender];
    uint lpSupply = lpToken.balanceOf(address(this));
    uint tempAccRewardPerShare = accRewardPerShare;
    if (block.number > lastRewardBlock && lpSupply > 0) {
      uint forFarmer;
      (, forFarmer) = getPoolReward();
      tempAccRewardPerShare = tempAccRewardPerShare.add(forFarmer.mul(1e12).div(lpSupply));
    }

    return user.lpTokenAmount.mul(tempAccRewardPerShare).div(1e12).sub(user.rewardDebt);
  }

  function claimReward() external {
    User storage user = userInfo[msg.sender];
    require(startBlock > 0, 'GDPFarm: farm is not started');
    require(user.lpTokenAmount > 0, 'GDPFarm: not yet join farm');

    updatePool();
    _harvest(user);
  }

  function withdraw(uint _amount) external {
    User storage user = userInfo[msg.sender];
    require(user.lpTokenAmount >= _amount, 'GDPFarm: insufficient balance');

    updatePool();
    _harvest(user);

    if(_amount > 0) {
      user.lpTokenAmount = user.lpTokenAmount.sub(_amount);
      _safeTransferLPToken(address(msg.sender), _amount);
    }
    user.rewardDebt = user.lpTokenAmount.mul(accRewardPerShare).div(1e12);
    emit Withdrew(msg.sender, _amount);
  }

  function emergencyWithdraw() external {
    User storage user = userInfo[msg.sender];
    _safeTransferLPToken(address(msg.sender), user.lpTokenAmount);
    emit EmergencyWithdrew(msg.sender, user.lpTokenAmount);
    user.lpTokenAmount = 0;
    user.rewardDebt = 0;
  }

  function getRewardPerBlockWithBonus() external view returns (uint) {
    uint multiplier = getMultiplier(block.number - 1, block.number).div(10);

    return multiplier.mul(rewardPerBlock);
  }

  function myInfo() external view returns (uint, uint, uint, uint, uint, uint, uint, uint) {
    User storage user = userInfo[msg.sender];
    uint canUnlockAmount;
    (canUnlockAmount, ) = _canUnlockAmount(user);

    return (
      user.firstDepositBlock,
      user.lpTokenAmount,
      user.lockAmount,
      user.lastUnlockBlock,
      canUnlockAmount,
      user.rewardDebt,
      user.totalReferral,
      user.referralBonus
    );
  }

  function unLock() external {
    User storage user = userInfo[msg.sender];
    require(user.lockAmount > 0, 'GDPFarm: you have no locked token');
    uint canUnlockAmount;
    uint lastUnlockBlock;
    (canUnlockAmount, lastUnlockBlock) = _canUnlockAmount(user);
    if (canUnlockAmount > 0) {
      user.lockAmount = user.lockAmount.sub(canUnlockAmount);
      user.lastUnlockBlock = lastUnlockBlock;
      totalLock = totalLock.sub(canUnlockAmount);
      gdpToken.releaseFarmAllocation(msg.sender, canUnlockAmount);
      totalRewarded = totalRewarded.add(canUnlockAmount);
      emit UnLock(msg.sender, canUnlockAmount);
    }
  }

  function claimReferralBonus() external {
    User storage user = userInfo[msg.sender];
    require(user.referralBonus > 0, 'GDPFarm: you have no referral bonus');
    uint bonusAmount = user.referralBonus;
    user.referralBonus = 0;
    gdpToken.releaseFarmAllocation(msg.sender, bonusAmount);
    emit ReferralRewardClaimed(msg.sender, bonusAmount);
  }

  function myTotalF1() public view returns (uint) {
    return listF1[msg.sender].length;
  }

  // PRIVATE FUNCTIONS

  function _canUnlockAmount(User storage _user) private view returns (uint, uint) {
    bool firstTimeUnlockConditionPassed = block.number >= _user.firstDepositBlock + blocksIn180Days;
    if (block.number < _user.firstDepositBlock) {
      return (
        0,
        _user.lastUnlockBlock
      );
    } else if (firstTimeUnlockConditionPassed) {
      bool each30DayPassed = block.number - _user.lastUnlockBlock >= blocksIn30Days;
      bool neverUnlock = _user.lastUnlockBlock == 0;
      if (neverUnlock) {
        return (
          _user.lockAmount.div(10),
          _user.firstDepositBlock + blocksIn180Days
        );
      } else if (each30DayPassed) {
        return (
          _user.lockAmount.div(10),
          _user.lastUnlockBlock + blocksIn30Days
        );
      } else {
        return (
          0,
          _user.lastUnlockBlock
        );
      }
    } else {
      return (
        0,
        _user.lastUnlockBlock
      );
    }
  }

  function _harvest(User storage _user) private {
    if (_user.lpTokenAmount > 0) {
      uint pending = _user.lpTokenAmount.mul(accRewardPerShare).div(1e12).sub(_user.rewardDebt);
      uint maxReward = farmingAllocation.sub(totalLock);
      if (pending > maxReward) {
        pending = maxReward;
      }

      if(pending > 0) {
        uint referralAmount = _harvestReferral(pending);
        _harvestReward(_user, pending.sub(referralAmount));
      }

      _user.rewardDebt = _user.lpTokenAmount.mul(accRewardPerShare).div(1e12);
    }
  }

  function _harvestReferral(uint _pending) private returns (uint){
    uint referralDivider = 9;
    uint referralAmount = _pending.div(referralDivider);
    uint paidReferralAmount = _transferReferral(msg.sender, msg.sender, referralAmount, 1);
    gdpToken.releaseFarmAllocation(stakingContract, referralAmount.sub(paidReferralAmount));
    totalRewarded = totalRewarded.add(paidReferralAmount);
    return referralAmount;
  }

  function _harvestReward(User storage _user, uint _rewardAmount) private {
    uint lockRewardAmount = _rewardAmount.mul(percentLockReward).div(100);
    uint releaseAmount = _rewardAmount.sub(lockRewardAmount);
    gdpToken.releaseFarmAllocation(msg.sender, releaseAmount);
    totalRewarded = totalRewarded.add(releaseAmount);
    _farmLock(msg.sender, lockRewardAmount);
    _user.rewardDebtAtBlock = block.number;

    emit RewardSent(msg.sender, _rewardAmount, releaseAmount, lockRewardAmount);
  }

  function _farmLock(address _holder, uint _amount) private {
    require(_holder != address(0), 'BEP20: lock to the zero address');
    User storage user = userInfo[_holder];

    require(_amount <= farmingAllocation.sub(totalLock), 'ERC20: lock amount over allowed');
    user.lockAmount = user.lockAmount.add(_amount);
    totalLock = totalLock.add(_amount);

    emit Locked(_holder, _amount);
  }

  function _transferReferral(address _user, address _invitee, uint _amount, uint _level) private returns (uint paidAmount) {
    paidAmount = 0;
    address inviter = referrers[_invitee];
    if (inviter == address(0)) {
      return;
    }
    User storage inviterUser = userInfo[inviter];
    uint inviterGDPBalance = gdpToken.balanceOf(inviter);
    if (inviterGDPBalance >= referralBalanceCondition[_level]) {
      paidAmount = _amount.div(2);
      uint lockAmount = paidAmount.mul(percentLockReferral).div(100);
      uint releaseNowAmount = paidAmount.sub(lockAmount);
      inviterUser.referralBonus = inviterUser.referralBonus.add(releaseNowAmount);
      _farmLock(inviter, lockAmount);
      emit ReferralRewardSent(_user, inviter, releaseNowAmount, lockAmount);
    }
    if (_level < referralDeep) {
      uint paidHigherLevelAmount = _transferReferral(_user, inviter, _amount.div(2), _level + 1);
      paidAmount = paidAmount.add(paidHigherLevelAmount);
    }
  }

  function _safeTransferLPToken(address _to, uint _amount) private {
    uint lpBalance = lpToken.balanceOf(address(this));
    if (_amount > lpBalance) {
      lpToken.transfer(_to, lpBalance);
    } else {
      lpToken.transfer(_to, _amount);
    }
  }

  function _initData() private {
    citizen = 2;
    User storage devAccount = userInfo[devAddress];
    devAccount.firstDepositBlock = block.number;
    devAccount.userAddress = devAddress;

    User storage defaultAccount = userInfo[defaultAddress];
    defaultAccount.firstDepositBlock = block.number;
    defaultAccount.userAddress = defaultAddress;
  }

  function _increaseInviterTotalReferral(User storage _user) private {
    _user.totalReferral = _user.totalReferral.add(1);
    address inviterAddress = referrers[_user.userAddress];
    if (inviterAddress != address(0)) {
      _increaseInviterTotalReferral(userInfo[inviterAddress]);
    }
  }
}