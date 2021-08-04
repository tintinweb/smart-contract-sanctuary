/**
 *Submitted for verification at BscScan.com on 2021-08-04
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Contract: Approve Function Failed');
    }
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Contract: Transfer Function Failed');
    }
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Contract: Transfer From Function Failed');
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
        require(set._values.length > index, "EnumerableSet: Index out of bounds");
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
        require(_status != _ENTERED, "Contract: Re Entrant Call");
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

interface IST20 {
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

contract ST_MdexSwap_v2_Liquidity_Vault is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  IUniFactory public DexSwapFactory;
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
    IST20 secondaryFeeToken;
    uint256 secondaryTokenFee;
    uint256 secondaryTokenDiscount;
    uint256 liquidityFee;
    uint256 referralPercent;
    IST20 referralToken;
    uint256 referralHold;
    uint256 referralDiscount;
  }
  FeeStruct public gFees;
  EnumerableSet.AddressSet private feeWhitelist;
  address payable devaddr;
  IMigrator migrator;
  event onDeposit(address lpToken, address user, uint256 amount, uint256 lockDate, uint256 unlockDate);
  event onWithdraw(address lpToken, uint256 amount);
  constructor(IUniFactory SwapFactoryAddress) public {
    devaddr = msg.sender;
    gFees.ethFee = 10000000000000000;
    gFees.secondaryTokenFee = 1100000000000000000000;
    gFees.secondaryTokenDiscount = 0;
    gFees.liquidityFee = 1;
    gFees.referralHold = 0;
    gFees.referralDiscount = 0;
    DexSwapFactory = SwapFactoryAddress;
  }
  function setDevAddress(address payable _devaddr) public onlyOwner {
    devaddr = _devaddr;
  }
  function setMigratorAddress(IMigrator _migrator) public onlyOwner {
    migrator = _migrator;
  }
  function setSecondaryFeeToken(address _secondaryFeeToken) public onlyOwner {
    gFees.secondaryFeeToken = IST20(_secondaryFeeToken);
  }
  function setReferralTokenAndHold(IST20 ReferralAddressToken, uint256 _hold) public onlyOwner {
    gFees.referralToken = ReferralAddressToken;
    gFees.referralHold = _hold;
  }
  function setVaultFees(uint256 ReferralAddressPercent, uint256 ReferralAddressDiscount, uint256 _ethFee, uint256 _secondaryTokenFee, uint256 _secondaryTokenDiscount, uint256 _liquidityFee) public onlyOwner {
    gFees.referralPercent = ReferralAddressPercent;
    gFees.referralDiscount = ReferralAddressDiscount;
    gFees.ethFee = _ethFee;
    gFees.secondaryTokenFee = _secondaryTokenFee;
    gFees.secondaryTokenDiscount = _secondaryTokenDiscount;
    gFees.liquidityFee = _liquidityFee;
  }
  function setWhitelistAddress(address _user, bool _add) public onlyOwner {
    if (_add) {
      feeWhitelist.add(_user);
    } else {
      feeWhitelist.remove(_user);
    }
  }
  function LockLiquidityPoolTokens (address LiquidityPoolTokenAddress, uint256 _amount, uint256 LiquidityPoolTokenUnlockDate, address payable ReferralAddress, bool IsFeeInETH, address payable _withdrawer) external payable nonReentrant {
    require(LiquidityPoolTokenUnlockDate < 10000000000, 'Contract: Invalid UNIX Timestamp');
    require(_amount > 0, 'Contract: Incorrect Price');
    IUniswapV2Pair lpair = IUniswapV2Pair(address(LiquidityPoolTokenAddress));
    address factoryPairAddress = DexSwapFactory.getPair(lpair.token0(), lpair.token1());
    require(factoryPairAddress == address(LiquidityPoolTokenAddress), 'Contract: Incorrect Swap Factory Address');
    TransferHelper.safeTransferFrom(LiquidityPoolTokenAddress, address(msg.sender), address(this), _amount);
    if (ReferralAddress != address(0) && address(gFees.referralToken) != address(0)) {
      require(gFees.referralToken.balanceOf(ReferralAddress) >= gFees.referralHold, 'Contract: Inadequate Balance');
    }
    if (!feeWhitelist.contains(msg.sender)) {
      if (IsFeeInETH) {
        uint256 ethFee = gFees.ethFee;
        if (ReferralAddress != address(0)) {
          ethFee = ethFee.mul(100 - gFees.referralDiscount).div(100);
        }
        require(msg.value == ethFee, 'Contract: Incorrect Price');
        uint256 devFee = ethFee;
        if (ethFee != 0 && ReferralAddress != address(0)) {
          uint256 referralFee = devFee.mul(gFees.referralPercent).div(100);
          ReferralAddress.transfer(referralFee);
          devFee = devFee.sub(referralFee);
        }
        devaddr.transfer(devFee);
      } else {
        uint256 burnFee = gFees.secondaryTokenFee;
        if (ReferralAddress != address(0)) {
          burnFee = burnFee.mul(100 - gFees.referralDiscount).div(100);
        }
        TransferHelper.safeTransferFrom(address(gFees.secondaryFeeToken), address(msg.sender), address(this), burnFee);
        if (gFees.referralPercent != 0 && ReferralAddress != address(0)) {
          uint256 referralFee = burnFee.mul(gFees.referralPercent).div(100);
          TransferHelper.safeApprove(address(gFees.secondaryFeeToken), ReferralAddress, referralFee);
          TransferHelper.safeTransfer(address(gFees.secondaryFeeToken), ReferralAddress, referralFee);
          burnFee = burnFee.sub(referralFee);
        }
        gFees.secondaryFeeToken.burn(burnFee);
      }
    } else if (msg.value > 0){
      msg.sender.transfer(msg.value);
    }
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(100);
    if (!IsFeeInETH && !feeWhitelist.contains(msg.sender)) {
      liquidityFee = liquidityFee.mul(100 - gFees.secondaryTokenDiscount).div(100);
    }
    TransferHelper.safeTransfer(LiquidityPoolTokenAddress, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);
    TokenLock memory token_lock;
    token_lock.lockDate = block.timestamp;
    token_lock.amount = amountLocked;
    token_lock.initialAmount = amountLocked;
    token_lock.unlockDate = LiquidityPoolTokenUnlockDate;
    token_lock.lockID = tokenLocks[LiquidityPoolTokenAddress].length;
    token_lock.owner = _withdrawer;
    tokenLocks[LiquidityPoolTokenAddress].push(token_lock);
    lockedTokens.add(LiquidityPoolTokenAddress);
    UserInfo storage user = users[_withdrawer];
    user.lockedTokens.add(LiquidityPoolTokenAddress);
    uint256[] storage user_locks = user.locksForToken[LiquidityPoolTokenAddress];
    user_locks.push(token_lock.lockID);
    emit onDeposit(LiquidityPoolTokenAddress, msg.sender, token_lock.amount, token_lock.lockDate, token_lock.unlockDate);
  }
  function ReockLiquidityPoolTokens (address LiquidityPoolTokenAddress, uint256 _index, uint256 UniqueLockID, uint256 LiquidityPoolTokenUnlockDate) external nonReentrant {
    require(LiquidityPoolTokenUnlockDate < 10000000000, 'Contract: Invalid UNIX Timestamp');
    uint256 lockID = users[msg.sender].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage userLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
    require(lockID == UniqueLockID && userLock.owner == msg.sender, 'Contract: Wrong Lock ID');
    require(userLock.unlockDate < LiquidityPoolTokenUnlockDate, 'Contract: Premature Unlock Date');
    uint256 liquidityFee = userLock.amount.mul(gFees.liquidityFee).div(100);
    uint256 amountLocked = userLock.amount.sub(liquidityFee);
    userLock.amount = amountLocked;
    userLock.unlockDate = LiquidityPoolTokenUnlockDate;
    TransferHelper.safeTransfer(LiquidityPoolTokenAddress, devaddr, liquidityFee);
  }
  function WithdrawLiquidityPoolTokens (address LiquidityPoolTokenAddress, uint256 _index, uint256 UniqueLockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'Contract: Liquidity Pool Tokens value should be more than Zero');
    uint256 lockID = users[msg.sender].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage userLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
    require(lockID == UniqueLockID && userLock.owner == msg.sender, 'Contract: Wrong Lock ID');
    require(userLock.unlockDate < block.timestamp, 'Contract: Premature Unlock Date');
    userLock.amount = userLock.amount.sub(_amount);
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[LiquidityPoolTokenAddress];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(LiquidityPoolTokenAddress);
      }
    }
    TransferHelper.safeTransfer(LiquidityPoolTokenAddress, msg.sender, _amount);
    emit onWithdraw(LiquidityPoolTokenAddress, _amount);
  }
  function IncrementalLiquidityPoolTokens (address LiquidityPoolTokenAddress, uint256 _index, uint256 UniqueLockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'Contract: Liquidity Pool Tokens value should be more than Zero');
    uint256 lockID = users[msg.sender].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage userLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
    require(lockID == UniqueLockID && userLock.owner == msg.sender, 'Contract: Wrong Lock ID');
    TransferHelper.safeTransferFrom(LiquidityPoolTokenAddress, address(msg.sender), address(this), _amount);
    uint256 liquidityFee = _amount.mul(gFees.liquidityFee).div(100);
    TransferHelper.safeTransfer(LiquidityPoolTokenAddress, devaddr, liquidityFee);
    uint256 amountLocked = _amount.sub(liquidityFee);
    userLock.amount = userLock.amount.add(amountLocked);
    emit onDeposit(LiquidityPoolTokenAddress, msg.sender, amountLocked, userLock.lockDate, userLock.unlockDate);
  }
  function SplitLiquidityPoolTokens (address LiquidityPoolTokenAddress, uint256 _index, uint256 UniqueLockID, uint256 _amount) external payable nonReentrant {
    require(_amount > 0, 'Contract: Liquidity Pool Tokens value should be more than Zero');
    uint256 lockID = users[msg.sender].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage userLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
    require(lockID == UniqueLockID && userLock.owner == msg.sender, 'Contract: Wrong Lock ID');
    require(msg.value == gFees.ethFee, 'Contract: Incorrect Price');
    devaddr.transfer(gFees.ethFee);
    userLock.amount = userLock.amount.sub(_amount);
    TokenLock memory token_lock;
    token_lock.lockDate = userLock.lockDate;
    token_lock.amount = _amount;
    token_lock.initialAmount = _amount;
    token_lock.unlockDate = userLock.unlockDate;
    token_lock.lockID = tokenLocks[LiquidityPoolTokenAddress].length;
    token_lock.owner = msg.sender;
    tokenLocks[LiquidityPoolTokenAddress].push(token_lock);
    UserInfo storage user = users[msg.sender];
    uint256[] storage user_locks = user.locksForToken[LiquidityPoolTokenAddress];
    user_locks.push(token_lock.lockID);
  }
  function TransferLockOwnership (address LiquidityPoolTokenAddress, uint256 _index, uint256 UniqueLockID, address payable _newOwner) external {
    require(msg.sender != _newOwner, 'Contract: caller is not the owner');
    uint256 lockID = users[msg.sender].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage transferredLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
    require(lockID == UniqueLockID && transferredLock.owner == msg.sender, 'Contract: Wrong Lock ID');
    UserInfo storage user = users[_newOwner];
    user.lockedTokens.add(LiquidityPoolTokenAddress);
    uint256[] storage user_locks = user.locksForToken[LiquidityPoolTokenAddress];
    user_locks.push(transferredLock.lockID);
    uint256[] storage userLocks = users[msg.sender].locksForToken[LiquidityPoolTokenAddress];
    userLocks[_index] = userLocks[userLocks.length-1];
    userLocks.pop();
    if (userLocks.length == 0) {
      users[msg.sender].lockedTokens.remove(LiquidityPoolTokenAddress);
    }
    transferredLock.owner = _newOwner;
  }
  function MigrateLiquidityPoolTokens (address LiquidityPoolTokenAddress, uint256 _index, uint256 UniqueLockID, uint256 _amount) external nonReentrant {
    require(address(migrator) != address(0), "Contract: Migrator address should not be Zero address");
    require(_amount > 0, 'Contract: Liquidity Pool Tokens value should be more than Zero');
    uint256 lockID = users[msg.sender].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage userLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
    require(lockID == UniqueLockID && userLock.owner == msg.sender, 'Contract: Wrong Lock ID');
    userLock.amount = userLock.amount.sub(_amount);
    if (userLock.amount == 0) {
      uint256[] storage userLocks = users[msg.sender].locksForToken[LiquidityPoolTokenAddress];
      userLocks[_index] = userLocks[userLocks.length-1];
      userLocks.pop();
      if (userLocks.length == 0) {
        users[msg.sender].lockedTokens.remove(LiquidityPoolTokenAddress);
      }
    }
    TransferHelper.safeApprove(LiquidityPoolTokenAddress, address(migrator), _amount);
    migrator.migrate(LiquidityPoolTokenAddress, _amount, userLock.unlockDate, msg.sender);
  }
  function getNumLocksForToken (address LiquidityPoolTokenAddress) external view returns (uint256) {
    return tokenLocks[LiquidityPoolTokenAddress].length;
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
  function getUserNumLocksForToken (address _user, address LiquidityPoolTokenAddress) external view returns (uint256) {
    UserInfo storage user = users[_user];
    return user.locksForToken[LiquidityPoolTokenAddress].length;
  }
  function getUserLockForTokenAtIndex (address _user, address LiquidityPoolTokenAddress, uint256 _index) external view 
  returns (uint256, uint256, uint256, uint256, uint256, address) {
    uint256 lockID = users[_user].locksForToken[LiquidityPoolTokenAddress][_index];
    TokenLock storage tokenLock = tokenLocks[LiquidityPoolTokenAddress][lockID];
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