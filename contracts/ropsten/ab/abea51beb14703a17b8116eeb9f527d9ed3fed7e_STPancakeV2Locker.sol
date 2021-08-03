/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () internal {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IMigrator {
    function migrate(address lpToken, uint256 amount, uint256 unlockDate, address owner) external returns (bool);
}

contract STPancakeV2Locker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  IUniFactory public uniswapFactory;
  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens;
    mapping(address => uint256[]) locksForToken;
  }
  struct TokenLock {
    uint256 lockDate;
    uint256 amount;
    uint256 initialAmount;
    uint256 unlockDate;
    uint256 lockID;
    address owner;
  }
  mapping(address => UserInfo) private users;
  EnumerableSet.AddressSet private lockedTokens;
  mapping(address => TokenLock[]) public tokenLocks;
  struct FeeStruct {
    uint256 ethFee;
    IERCBurn secondaryFeeToken;
    uint256 secondaryTokenFee;
    uint256 secondaryTokenDiscount;
    uint256 liquidityFee;
    uint256 referralPercent;
    IERCBurn referralToken;
    uint256 referralHold;
    uint256 referralDiscount;
  }
  FeeStruct public gFees;
  EnumerableSet.AddressSet private feeWhitelist;
  address payable devaddr;
  IMigrator migrator;
  event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
  event onWithdraw(address lpToken, uint256 amount);
  constructor(IUniFactory _uniswapFactory) public {
    devaddr = msg.sender;
    gFees.referralPercent = 250;
    gFees.ethFee = 1e18;
    gFees.secondaryTokenFee = 100e18;
    gFees.secondaryTokenDiscount = 200;
    gFees.liquidityFee = 10;
    gFees.referralHold = 10e18;
    gFees.referralDiscount = 100;
    uniswapFactory = _uniswapFactory;
  }
  function setDev(address payable _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }
  function setMigrator(IMigrator _migrator) public onlyOwner {
    migrator = _migrator;
  }
  function setSecondaryFeeToken(address _secondaryFeeToken) public onlyOwner {
    gFees.secondaryFeeToken = IERCBurn(_secondaryFeeToken);
  }
  function setReferralTokenAndHold(IERCBurn _referralToken, uint256 _hold) public onlyOwner {
    gFees.referralToken = _referralToken;
    gFees.referralHold = _hold;
  }
  function setFees(uint256 _referralPercent, uint256 _referralDiscount, uint256 _ethFee, uint256 _secondaryTokenFee, uint256 _secondaryTokenDiscount, uint256 _liquidityFee) public onlyOwner {
    gFees.referralPercent = _referralPercent;
    gFees.referralDiscount = _referralDiscount;
    gFees.ethFee = _ethFee;
    gFees.secondaryTokenFee = _secondaryTokenFee;
    gFees.secondaryTokenDiscount = _secondaryTokenDiscount;
    gFees.liquidityFee = _liquidityFee;
  }
  function whitelistFeeAccount(address _user, bool _add) public onlyOwner {
    if (_add) {
      feeWhitelist.add(_user);
    } else {
      feeWhitelist.remove(_user);
    }
  }
  function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer) external payable nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID');
    require(_amount > 0, 'INSUFFICIENT');
    IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
    address factoryPairAddress = uniswapFactory.getPair(lpair.token0(), lpair.token1());
    require(factoryPairAddress == address(_lpToken), 'NOT UNIV2');
    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    if (_referral != address(0) && address(gFees.referralToken) != address(0)) {
      require(gFees.referralToken.balanceOf(_referral) >= gFees.referralHold, 'INADEQUATE BALANCE');
    }
    if (!feeWhitelist.contains(msg.sender)) {
      if (_fee_in_eth) {
        uint256 ethFee = gFees.ethFee;
        if (_referral != address(0)) {
          ethFee = ethFee.mul(1000 - gFees.referralDiscount).div(1000);
        }
        require(msg.value == ethFee, 'FEE NOT MET');
        uint256 devFee = ethFee;
        if (ethFee != 0 && _referral != address(0)) {
          uint256 referralFee = devFee.mul(gFees.referralPercent).div(1000);
          _referral.transfer(referralFee);
          devFee = devFee.sub(referralFee);
        }
        devaddr.transfer(devFee);
      } else {
        uint256 burnFee = gFees.secondaryTokenFee;
        if (_referral != address(0)) {
          burnFee = burnFee.mul(1000 - gFees.referralDiscount).div(1000);
        }
        TransferHelper.safeTransferFrom(address(gFees.secondaryFeeToken), address(msg.sender), address(this), burnFee);
        if (gFees.referralPercent != 0 && _referral != address(0)) {
          uint256 referralFee = burnFee.mul(gFees.referralPercent).div(1000);
          TransferHelper.safeApprove(address(gFees.secondaryFeeToken), _referral, referralFee);
          TransferHelper.safeTransfer(address(gFees.secondaryFeeToken), _referral, referralFee);
          burnFee = burnFee.sub(referralFee);
        }
        gFees.secondaryFeeToken.burn(burnFee);
      }
    } else if (msg.value > 0){
      msg.sender.transfer(msg.value);
    }
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
    if (!_fee_in_eth && !feeWhitelist.contains(msg.sender)) {
      liquidityFee = liquidityFee.mul(1000 - gFees.secondaryTokenDiscount).div(1000);
    }
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);
    TokenLock memory token_lock;
    token_lock.lockDate = block.timestamp;
    token_lock.amount = amountLocked;
    token_lock.initialAmount = amountLocked;
    token_lock.unlockDate = _unlock_date;
    token_lock.lockID = tokenLocks[_lpToken].length;
    token_lock.owner = _withdrawer;
    tokenLocks[_lpToken].push(token_lock);
    lockedTokens.add(_lpToken);
    UserInfo storage user = users[_withdrawer];
    user.lockedTokens.add(_lpToken);
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(token_lock.lockID);
    emit onDeposit(_lpToken, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
  }
  function relock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _unlock_date) external nonReentrant {
    require(_unlock_date < 10000000000, 'TIMESTAMP INVALID');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH');
    require(userLock.unlockDate < _unlock_date, 'UNLOCK BEFORE');
    uint256 liquidityFee = userLock.amount.mul(gFees.liquidityFee).div(1000);
    uint256 amountLocked = userLock.amount.sub(liquidityFee);
    userLock.amount = amountLocked;
    userLock.unlockDate = _unlock_date;
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
  }
  function withdraw (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO WITHDRAWL');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH');
    require(userLock.unlockDate < block.timestamp, 'NOT YET');
    userLock.amount = userLock.amount.sub(_amount);
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(_lpToken);
      }
    }
    TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
    emit onWithdraw(_lpToken, _amount);
  }
  function incrementLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH');
    TransferHelper.safeTransferFrom(_lpToken, address(msg.sender), address(this), _amount);
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(1000);
    TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);
    userLock.amount = userLock.amount.add(amountLocked);
    emit onDeposit(_lpToken, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
  }
  function splitLock (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external payable nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH');
    require(msg.value == gFees.ethFee, 'FEE NOT MET');
    devaddr.transfer(gFees.ethFee);
    userLock.amount = userLock.amount.sub(_amount);
    TokenLock memory token_lock;
    token_lock.lockDate = userLock.lockDate;
    token_lock.amount = _amount;
    token_lock.initialAmount = _amount;
    token_lock.unlockDate = userLock.unlockDate;
    token_lock.lockID = tokenLocks[_lpToken].length;
    token_lock.owner = msg.sender;
    tokenLocks[_lpToken].push(token_lock);
    UserInfo storage user = users[msg.sender];
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(token_lock.lockID);
  }
  function transferLockOwnership (address _lpToken, uint256 _index, uint256 _lockID, address payable _newOwner) external {
    require(msg.sender != _newOwner, 'OWNER');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && transferredLock.owner == msg.sender, 'LOCK MISMATCH');
    UserInfo storage user = users[_newOwner];
    user.lockedTokens.add(_lpToken);
    uint256[] storage user_locks = user.locksForToken[_lpToken];
    user_locks.push(transferredLock.lockID);
    uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
    userLocks[_index] = userLocks[userLocks.length-1];
    userLocks.pop();
    if (userLocks.length == 0) {
      users[msg.sender].lockedTokens.remove(_lpToken);
    }
    transferredLock.owner = _newOwner;
  }
  function migrate (address _lpToken, uint256 _index, uint256 _lockID, uint256 _amount) external nonReentrant {
    require(address(migrator) != address(0), "NOT SET");
    require(_amount > 0, 'ZERO MIGRATION');
    uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
    TokenLock storage userLock = tokenLocks[_lpToken][lockID];
    require(lockID == _lockID && userLock.owner == msg.sender, 'LOCK MISMATCH'); // ensures correct lock is affected
    userLock.amount = userLock.amount.sub(_amount);
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[_lpToken];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(_lpToken);
      }
    }
    TransferHelper.safeApprove(_lpToken, address(migrator), _amount);
    migrator.migrate(_lpToken, _amount, userLock.unlockDate, msg.sender);
  }
  function getNumLocksForToken (address _lpToken) external view returns (uint256) {
    return tokenLocks[_lpToken].length;
  }
  function getNumLockedTokens () external view returns (uint256) {
    return lockedTokens.length();
  }
  function getLockedTokenAtIndex (uint256 _index) external view returns (address) {
    return lockedTokens.at(_index);
  }
  function getUserNumLockedTokens (address _user) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.lockedTokens.length();
  }
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    UserInfo storage user = users[_user];
    return user.lockedTokens.at(_index);
  }
  function getUserNumLocksForToken (address _user, address _lpToken) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.locksForToken[_lpToken].length;
  }
  function getUserLockForTokenAtIndex (address _user, address _lpToken, uint256 _index) external view 
  returns (uint256, uint256, uint256, uint256, uint256, address) {
    uint256 lockID = users[_user].locksForToken[_lpToken][_index];
    TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
    return (tokenLock.lockDate, tokenLock.amount, tokenLock.initialAmount, tokenLock.unlockDate, tokenLock.lockID, tokenLock.owner);
  }
  function getWhitelistedUsersLength () external view returns (uint256) {
    return feeWhitelist.length();
  }
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return feeWhitelist.at(_index);
  }
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return feeWhitelist.contains(_user);
  }
}