/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

// File:  (3)/remixbackup/contracts/RBX(NEW).sol

pragma solidity ^0.5.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Rubix is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  
  
   event depositToPool(address indexed user, uint256 value);
   event claimed(address indexed user);
   event emergencyWithdrawn(address indexed user, uint256 value);

    mapping(address => uint256) private _stakingBalance;

    mapping(address => InvestorData) private _InvestorData;

    mapping(uint => PoolData) private _PoolData;
    

    
    struct InvestorData{
        uint rTime;
        uint EarnedRbx;
        uint poolID;
        uint _index;
    }

    struct PoolData{
        uint startTime;
        uint endTime;
        uint RbxStaked;
        uint PoolRewards;
    }
    
     
  uint private currentPool; 
  uint private index;
  uint internal poolDuration = 4233600;
  uint internal depositFee = 50000 * 10**9;
  address private feeAddress;
  
  IBEP20 internal _oldRBX;
  
  uint256 internal FirstLaneVestingTimestamp;
  
  bool internal added;
  
  bool internal isClaimable;
  
  uint256 internal flowCounter;
  
  uint256 internal secondLaneTimestamp;
  
  uint256 internal thirdLaneTimestap;
  
  mapping (address => bool) private metadata;
  
  mapping (address => bool) private FirstLaneMetadata;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(IBEP20 oldRbx) public {
    _name = "Rubix";
    _symbol = "RUBIX";
    _decimals = 18;
    _totalSupply = 5000000000 * 10**9;
    _balances[msg.sender] = _totalSupply;
    _oldRBX = oldRbx;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }
  
  // Start Swap Functions
  
  function addtoMetadata(address[] memory _users) public onlyOwner{
      require(added != true, "Addresses are already added");
        for (uint i = 0; i < _users.length; i++) {
            metadata[_users[i]] = true;
        }
    }
    
    function addtoFirstLaneMetadata(address[] memory _users) public onlyOwner{
      require(added != true, "Addresses are already added");
        for (uint i = 0; i < _users.length; i++) {
            FirstLaneMetadata[_users[i]] = true;
        }
    }
    
    function addressesAdded() public onlyOwner {
        added = true;
    }

  function PCSListed() public onlyOwner{
      require(isClaimable != true, "You can't redo");
      FirstLaneVestingTimestamp = now.add(259200); //Adds 3 days from the moment of listing 
      secondLaneTimestamp = now.add(7890000); //Adds 3 months from the moment of listing 
      thirdLaneTimestap = now.add(15780000); //Adds 6 months from the moment of listing
      isClaimable = true;
  }
  
  
  function SwapFirstLane(address _user) public {
      require(msg.sender == _user, "Not a holder!");
      require(FirstLaneMetadata[_user] != false, "Fail!");
      require(FirstLaneVestingTimestamp <= now && isClaimable != false, "You can't swap yet!");
      
      uint256 _SwapableBalance = SwapableBalance(msg.sender);
      
      uint256 priorityBonus = _SwapableBalance.mul(1500).div(100000);

     _balances[address(1)] = _balances[address(1)].add(_SwapableBalance.add(priorityBonus));
      emit Transfer(
            address(1),
            address(1),
            (_SwapableBalance.add(priorityBonus))
        );
        
      _balances[address(1)] = _balances[address(1)].sub(_SwapableBalance.add(priorityBonus));
      
      _balances[_user] = _balances[_user].add(_SwapableBalance.add(priorityBonus));
      
      emit Transfer(
            address(1),
            msg.sender,
            (_SwapableBalance.add(priorityBonus))
        );
        
        _totalSupply = _totalSupply.add(_SwapableBalance.add(priorityBonus));
       
      FirstLaneMetadata[_user] = false;  
      metadata[_user] = false;
  }
  
  function swapSecondLane(address _user) public {
      require(msg.sender == _user, "Not a holder!");
      require(metadata[_user] != false, "Fail!");
      require(flowCounter <= 150, "Wait for third flow");
      require(secondLaneTimestamp <= now && isClaimable != false, "You can't swap yet!");
      
      uint256 _SwapableBalance = SwapableBalance(msg.sender);
      
       _balances[address(1)] = _balances[address(1)].add(_SwapableBalance);
      emit Transfer(
            address(1),
            address(1),
            (_SwapableBalance)
        );
        
      _balances[address(1)] = _balances[address(1)].sub(_SwapableBalance);
      
      _balances[_user] = _balances[_user].add(_SwapableBalance);
      
      emit Transfer(
            address(1),
            msg.sender,
            (_SwapableBalance)
        );
        
        flowCounter++;
        
        _totalSupply = _totalSupply.add(_SwapableBalance);
       
        metadata[_user] = false;
      
  }
  
  function swapThirdLane(address _user) public {
      require(msg.sender == _user, "Not a holder!");
      require(metadata[_user] != false, "Fail!");
      require(flowCounter >= 149, "Claim from second flow");
      require(secondLaneTimestamp <= now && isClaimable != false, "You can't swap yet!");
      
      uint256 _SwapableBalance = SwapableBalance(msg.sender);
      
       _balances[address(1)] = _balances[address(1)].add(_SwapableBalance);
      emit Transfer(
            address(1),
            address(1),
            (_SwapableBalance)
        );
        
      _balances[address(1)] = _balances[address(1)].sub(_SwapableBalance);
      
      _balances[_user] = _balances[_user].add(_SwapableBalance);
      
      emit Transfer(
            address(1),
            msg.sender,
            (_SwapableBalance)
        );
        
        flowCounter++;
        
        _totalSupply = _totalSupply.add(_SwapableBalance);
       
        metadata[_user] = false;
  }
  
  
    function SwapableBalance(address _user) public view returns(uint256 balance) {
        uint256 eighteenToNineDecimals = _oldRBX.balanceOf(_user).div(1e18).mul(1e18);
        uint256 newBalance = eighteenToNineDecimals.mul(1000);
        if(metadata[_user] == true || FirstLaneMetadata[_user] == true) {
            return newBalance;
        } else return 0;
        
  }
  
  function firstLaneAddress(address _user) public view returns(bool) {
      return FirstLaneMetadata[_user];
  }
  
  function addressSwapable(address _user) public view returns(bool) {
      return metadata[_user];
  }
  
  
    
    function isAddable() public view returns(bool){
        if(added == true) {
            return false;
        } else {
            return true; 
    }}
    
    function _flowCounter() public view returns(uint) {
        return flowCounter;
    }
    
    function LaneTimestamps() public view returns(uint256 firstLane, uint256 secondLane, uint256 thirdLane) {
        uint256 _firstLaneTS = FirstLaneVestingTimestamp;
        uint256 _secondLaneTS = secondLaneTimestamp;
        uint256 _thirdLaneTS = thirdLaneTimestap;
        return(_firstLaneTS, _secondLaneTS, _thirdLaneTS);
    }
  
  // End Swap functions
  
    
  function changefeeAddress(address _newAddress) public onlyOwner {
      feeAddress = _newAddress;
  }
  
  

  function Deposit(uint256 _amount) external {
        require(_balances[msg.sender] >= _amount.add(50000 * 10**9), "Balance too low");
        require(_totalSupply <= 10000000000 * 10**9, "Max supply reached!");
        
        if(_stakingBalance[msg.sender] != 0) {
            claim();
            
        }
        
        if(_PoolData[currentPool].endTime < now) {
            currentPool++;
            _PoolData[currentPool].startTime = now;
            _PoolData[currentPool].endTime = now.add(poolDuration);
            _balances[address(1)] = _balances[address(1)].add(1000000 * 10**9);
            _PoolData[currentPool].PoolRewards = _PoolData[currentPool].PoolRewards.add(1000000 * 10**9);
            
            emit Transfer(
            address(1),
            address(1),
            1000000 * 10**9
        );
        }
        
        if(_PoolData[currentPool].RbxStaked >= 100000000 * 10**9) {
            _balances[address(1)] = _balances[address(1)].add(10500000 * 10**9);
            _PoolData[currentPool].PoolRewards = _PoolData[currentPool].PoolRewards.add(10500000 * 10**9);
            emit Transfer(
            address(1),
            address(1),
            10500000 * 10**9
        );
        }
        
        if(_PoolData[currentPool].RbxStaked >= 200000000 * 10**9) {
            _balances[address(1)] = _balances[address(1)].add(21000000 * 10**9);
            _PoolData[currentPool].PoolRewards = _PoolData[currentPool].PoolRewards.add(21000000 * 10**9);
            emit Transfer(
            address(1),
            address(1),
            21000000 * 10**9
        );
        }
        
        if(_PoolData[currentPool].RbxStaked >= 500000000 * 10**9) {
            _balances[address(1)] = _balances[address(1)].add(60000000 * 10**9);
            _PoolData[currentPool].PoolRewards = _PoolData[currentPool].PoolRewards.add(60000000 * 10**9);
            emit Transfer(
            address(1),
            address(1),
            60000000 * 10**9
        );
        }
        emit Transfer(
            _msgSender(),
            address(1),
            _amount
        );
        emit Transfer(
            _msgSender(),
            feeAddress,
            depositFee
        );
        
        emit Transfer(
            address(1),
            address(1),
            _amount.mul(7000).div(100000)
        );
        //Substract the balance from stakeholder's account
        _balances[msg.sender] = _balances[msg.sender].sub(_amount.add(depositFee));
        
        //Add balance to BlackHole address
        _balances[address(1)] = _balances[address(1)].add(_amount.add(_amount.mul(7000).div(100000)));
        

        _balances[feeAddress] = _balances[feeAddress].add(depositFee);
        
        //Add amount to the staking pool
        _PoolData[currentPool].RbxStaked = _PoolData[currentPool].RbxStaked.add(_amount);
        
        //Substract staked amount from total supply
        _totalSupply = _totalSupply.sub(_amount);
        
        //Adds Stakings balance
        _stakingBalance[msg.sender] = _stakingBalance[msg.sender].add(_amount);
        
        //Adds Pool Rewards
        _PoolData[currentPool].PoolRewards = _PoolData[currentPool].PoolRewards.add(_amount.mul(7000).div(100000));
        
        _InvestorData[msg.sender].rTime = now;
        _InvestorData[msg.sender].poolID = currentPool;
        _InvestorData[msg.sender]._index = index;
        index++;
        
        emit depositToPool(msg.sender, _amount);
    }
    
function getStakingBalance(address _stakeholder) public view returns(uint256) {
    return _stakingBalance[_stakeholder];
}

  function getCurrentPoolId() public view returns(uint) {
      return currentPool;
  }
    
 function _poolShare(address _stakeholder) public view returns(uint256) {
        uint _userStakingBalance = _stakingBalance[_stakeholder];
        uint _totalRbxStaked = _PoolData[_InvestorData[_stakeholder].poolID].RbxStaked;
        return _userStakingBalance.mul(1e18).div(_totalRbxStaked);
    } 
    
    
  function _pendingBalance(address _stakeholder) public view returns(uint256) {
      uint totalAlloc = _PoolData[_InvestorData[_stakeholder].poolID].PoolRewards.mul(_poolShare(_stakeholder)).div(1e18);
      uint rewardPerSec = totalAlloc.div(poolDuration);
      if(_PoolData[currentPool].endTime < now) {
        uint timeHeld = _PoolData[currentPool].endTime.sub(_InvestorData[_stakeholder].rTime);  
        return timeHeld.mul(rewardPerSec);
      } else {
      uint timeHeld = now.sub(_InvestorData[_stakeholder].rTime); 
        return timeHeld.mul(rewardPerSec);
      }
      
      
  } 
  
  function emergencyWithdraw() public {
      require(_stakingBalance[msg.sender] != 0, "Nothing to withdraw");
      
      uint256 balance = _stakingBalance[msg.sender];
      
      uint256 withdrawFee = _stakingBalance[msg.sender].mul(3500).div(100000);
      
      //Transfer Staking balance to the requester
      _balances[address(1)] = _balances[address(1)].sub(_stakingBalance[msg.sender].sub(withdrawFee));
      _balances[msg.sender] = _balances[msg.sender].add(_stakingBalance[msg.sender].sub(withdrawFee));
     
      emit Transfer(
            address(1),
            msg.sender,
            (_stakingBalance[msg.sender].sub(withdrawFee))
        );
      _balances[address(1)] = _balances[address(1)].sub(withdrawFee);
      _balances[owner()] = _balances[owner()].add(withdrawFee);
      emit Transfer(
            address(1),
            owner(),
            withdrawFee
        );
        _totalSupply = _totalSupply.add(_stakingBalance[msg.sender]);
        
        _stakingBalance[msg.sender] = 0;
        
        _PoolData[_InvestorData[msg.sender].poolID].RbxStaked = _PoolData[_InvestorData[msg.sender].poolID].RbxStaked.sub(balance);
        
        emit emergencyWithdrawn(msg.sender, balance);
        
  }
  

  
  function claim() public {
      require(_pendingBalance(msg.sender) != 0, "No rewards pending");
      require(_stakingBalance[msg.sender] != 0, "No rewards pending");
      
      if(_PoolData[currentPool].endTime > now) {
          
      _balances[address(1)] = _balances[address(1)].sub(_pendingBalance(msg.sender));
      _balances[msg.sender] = _balances[msg.sender].add(_pendingBalance(msg.sender));
      
      emit Transfer(
            address(1),
            msg.sender,
            _pendingBalance(msg.sender)
        );
        
      _totalSupply = _totalSupply.add(_pendingBalance(msg.sender));
      _InvestorData[msg.sender].EarnedRbx = _InvestorData[msg.sender].EarnedRbx.add(_pendingBalance(msg.sender));
      _InvestorData[msg.sender].rTime = now; }
      
      else if(_PoolData[currentPool].endTime < now){
      _balances[address(1)] = _balances[address(1)].sub(_pendingBalance(msg.sender).add(_stakingBalance[msg.sender]));
      _balances[msg.sender] = _balances[msg.sender].add(_pendingBalance(msg.sender).add(_stakingBalance[msg.sender]));
      emit Transfer(
            address(1),
            msg.sender,
            (_pendingBalance(msg.sender).add(_stakingBalance[msg.sender]))
        );
      _totalSupply = _totalSupply.add(_pendingBalance(msg.sender).add(_stakingBalance[msg.sender]));
      _InvestorData[msg.sender].EarnedRbx = _InvestorData[msg.sender].EarnedRbx.add(_pendingBalance(msg.sender));
      _stakingBalance[msg.sender] = 0;
      }
      emit claimed(msg.sender);
  }
  
  function weeklyRate() public view returns(uint256) {
    return _PoolData[currentPool].PoolRewards.div(7);
  }
  
  function estimatedApr(uint256 _amount) public view returns(uint) {
      uint _shareOfthePool = _amount.mul(100000).div(_PoolData[currentPool].RbxStaked.add(_amount));
      uint _aprFromDeposit = _amount.mul(7000).div(100000);
      uint _poolApr = _PoolData[currentPool].PoolRewards.mul(_shareOfthePool).div(100000);
      uint _totalEstRewards = _aprFromDeposit.add(_poolApr);
      
      //Rewards multiplied for simplifying purposes
      uint _MulRewards = _totalEstRewards.mul(100000);
      return _MulRewards.div(_amount);
  }
  
  

  
  
  
  
  function getPoolData(uint256 poolID) public view returns(uint256 _pooledRewards, uint256 totalStaked, uint256 startTimeStamp, uint256 endTimeStamp) {
      return (_PoolData[poolID].PoolRewards,
      _PoolData[poolID].RbxStaked,
      _PoolData[poolID].startTime,
      _PoolData[poolID].endTime);
  }
  
  function getInvestorData(address _user) public view returns(uint256 _earnedRBX, uint256 _poolID, uint256 poolShare) {
      return(_InvestorData[_user].EarnedRbx, _InvestorData[_user].poolID, _poolShare(_user));
  }
   
  
  
  

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}