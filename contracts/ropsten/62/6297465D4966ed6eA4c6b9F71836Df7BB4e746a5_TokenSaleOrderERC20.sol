// SPDX-License-Identifier: UNLICENSED
// TokenSaleOrderERC20 v1.0.0 by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "./TokenSaleFactory.sol";
import "./TokenSaleLib.sol";
import "./IUniswapV2Router02.sol";
import "./ITokenLock.sol";

contract TokenSaleOrderERC20
  {
   TokenSaleFactory _Factory;
   
   IERC20 public _LPToken;            // liquidity token required
   IERC20 public _rewardToken;        // reward token provided by posteBy
   IERC20 public _entranceFeeToken;   // token used for entrance fee
  
   address public _postedBy;       // who posted the order
   address public _devWallet;
   address public _uniRouter;
   address public _lockAddress;     // team.finance lock contract
   
   uint public _entranceFee;        // amount charged for staking entrance fee
   uint public _stakeFee;           // fee in LP % taken from stakers  
   uint public _numBlocks;          // end block for staking
   uint public _lastBlockCalc;      // last time balances were modified
   uint public _rewardsLeft;        // remaining reward balance for informational purposes
   uint public _rewardsPerBlock;    // total rewards per block (this is divided amongst participants)
   uint public _totalStake;         // total amount of LP being staked between all stakers
   uint public _minStake;           // minimum amount of stake
   uint public _rewardAmount;       // amount of reward when posted
   uint public _numBlocksLeft;      // amount of unrewarded blocks
  
   uint public _unlockTime;          // unix time in seconds
   uint public _liquidityPercent;    // percent of stake to add as liquidity
   bool private _initialized;
   bool public _isActive;            // contract is active
   bool public _featured;
   bool public _isDone;              // contract is completely done
   
   mapping(address => uint) public _stakeBalance;   // stake balances of stakers
   mapping(address => uint) public _rewardBalance;  // reward balances of stakers
   mapping(address => uint) public _enteredBlock;   // block at which this address entered. used to make sure nobody entered while going thrugh_Stakers list
  
   using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
   EnumerableAddressSet.AddressSet _Stakers;
   
   function initialize(TokenSaleLib.OrderVars calldata vars) external
   {
     require(!_initialized);
     _initialized = true;

     require(vars.rewardToken != address(0) && vars.LPToken != address(0));
      
     _rewardToken = IERC20(vars.rewardToken);
     _LPToken = IERC20(vars.LPToken);
     _entranceFeeToken = IERC20(vars.entranceFeeToken);

     _stakeFee = vars.stakeFee;
     _postedBy = vars.postedBy;
     _numBlocks = vars.numBlocks;
     _numBlocksLeft = vars.numBlocks;
     _Factory = TokenSaleFactory(msg.sender);
     _devWallet = vars.devWallet;
     _minStake = vars.minStake;

     _unlockTime = vars.unlockTime;
     _liquidityPercent = vars. liquidityPercent;
     
     _uniRouter = vars.uniRouter;
     _lockAddress = vars.lockAddress;
     
     _featured = vars.featured;
     
     if(_minStake < 10000)
       _minStake = 10000;
     
     _rewardAmount = vars.rewardAmount;
   }

   function startOrder() public
   {
     // only factory can start this order
     require(msg.sender == address(_Factory));
     
     uint256 allowance = _rewardToken.allowance(msg.sender, address(this));
     require(allowance >= _rewardAmount);
    
     // factory should have paid us the reward purse
     require(_rewardToken.transferFrom(msg.sender, address(this), _rewardAmount));
    
     _rewardsLeft = _rewardAmount;
     _rewardsPerBlock = _rewardAmount / _numBlocks;
    
     _lastBlockCalc = block.number;
     _isActive = true; // order is ready to start as soon as we get our first staker    
   }
  
   // update all balances when a balance has been modified
   // this makes the user staking/withdrawing pay for the updates gas
   function updateBalances() public returns(bool)
   {
     // this is important because it is dealing with users funds
     // users can enter staking while we are iterating _Stakers list
     // we have keep track of when they entered so everyone gets paid correctly
    
     if(!_isActive)
       return(true);
     
     require(_numBlocksLeft > 0);
     
     uint len = _Stakers.length();
    
     if(len > 0) // dont have to do any of this is there are no stakers
       {
	 uint blockNum = block.number;
	 uint pendingRewards = getPendingRewards();
	 uint pendingBlocks = getPendingBlocks();
	 bool calcs = false;
	 
	 // calculate and modify all balances
	 for(uint i=0;i<len;i++)
	   {
	     address staker = _Stakers.at(i);
	     if(_enteredBlock[staker] < blockNum) // prevent counting of stakers who just entered while we are iterating the list
	       {
		 uint scale = 100000;
		 uint scaledbalance = (_stakeBalance[staker] * scale);
		      
		 if(scaledbalance > _totalStake) // avoid division error
		   {
		     uint num = scaledbalance / _totalStake * pendingRewards;
      
		     if(num > scale) // avoid division error
		       {
			 _rewardBalance[staker] = _rewardBalance[staker] + (num/scale);
			 calcs = true;
		       }
		   }
	       }
	   }
       
	 if(calcs) // only do this if we actually added to any balances
	   {
	     _rewardsLeft = _rewardsLeft - pendingRewards;
	     _numBlocksLeft = _numBlocksLeft - pendingBlocks;
	   }
       }

     bool closed = false;
     if( _numBlocksLeft == 0)
       {
	 _Factory.closeOrder(address(this));
	 iclose();
	 closed = true;
       }
     
     _lastBlockCalc = block.number;
     return(closed);
   }

   // stake
   function stake(uint amount) public
   {
     require(_isActive);

     if(updateBalances())
       return;
   
     require(amount >= _minStake);
     require(_entranceFeeToken.allowance(msg.sender, address(this)) >= amount);

     // stakers pay staking fee
     uint stakefee = amount * _stakeFee / 10000; // 10 is .01%
     uint stakeAmount = amount - stakefee;
     
     // send staker fee to devwallet
     require(_entranceFeeToken.transferFrom(msg.sender, _devWallet, stakefee) == true);

     // send rest to this
     require(_entranceFeeToken.transferFrom(msg.sender, address(this), stakeAmount));
     
     uint lpAmount = stakeAmount * _liquidityPercent / 10000; // 10 is .01%     
     uint payAmount = amount - lpAmount;

     // postedBy gets remaining entranceFeeToken
     require(_entranceFeeToken.transferFrom(msg.sender, _postedBy, payAmount));
     
     // obtain lpAmount of LP tokens
     uint lpAdded = addLiquidity(lpAmount);
     
     // LP Fees are taken from locked liquidity
     uint LPfeeAmount = lpAdded * _stakeFee / 10000; // 10 is .01% - fee to send to devwallet
     uint lockAmount = lpAdded - LPfeeAmount; // amount of liquidity to lock

     // send LP fee to dev wallet
     require(_LPToken.transfer(_devWallet, LPfeeAmount) == true);
     //require(_LPToken.transferFrom(address(this), _devWallet, LPfeeAmount) == true);

     // send lockAmount of LP tokens to locker
     ITokenLock lock = ITokenLock(_lockAddress);
     require(_LPToken.approve(_lockAddress, lockAmount));
     lock.lockTokens(address(_LPToken), lockAmount, _unlockTime);
     
     // add to our stakers
     _stakeBalance[msg.sender] = _stakeBalance[msg.sender] + stakeAmount; // add just in case they have already staked before
     _totalStake = _totalStake + stakeAmount;
     
     if(!_Stakers.contains(msg.sender)) // new staker
       {
	 _Stakers.add(msg.sender);
	 _enteredBlock[msg.sender] = block.number;
       }
   }

   function addLiquidity(uint amount) internal returns(uint)
   {
     IUniswapV2Router02 uni = IUniswapV2Router02(_uniRouter);
     uint ramount = _rewardToken.balanceOf(address(this));
     
     _entranceFeeToken.approve(_uniRouter, 0);
     _entranceFeeToken.approve(_uniRouter, amount);
     
     _rewardToken.approve(address(_uniRouter), 0);
     _rewardToken.approve(address(_uniRouter), ramount);
     
     // use exact amount of payment token amount and send as many rewardtokens as needed
     (,,uint liquidity) = uni.addLiquidity(address(_entranceFeeToken), address(_rewardToken), amount, ramount, amount, 1, address(this), block.timestamp);
     return(liquidity);
   }

   // collect uncollected rewards
   function collectRewards() public 
   {
     // always update balances before we change anything
     if(updateBalances())
       return;
   
     require(_rewardBalance[msg.sender] > 0);   
   
     require(_rewardToken.transfer(msg.sender, _rewardBalance[msg.sender]));
     _rewardBalance[msg.sender] = 0;
   }
   
   function isStaker(address addr) public view returns(bool)
   {
     return(_Stakers.contains(addr));
   }   
   
   function getPendingRewards() public view returns (uint)
   {
     if(_Stakers.length() == 0) // all balances should already be correct
       return(0); 
     return(_rewardsPerBlock * getPendingBlocks());
   }

   function getPendingBlocks() public view returns(uint)
   {
     if(_Stakers.length() == 0 )
       return(0);
     if((block.number - _lastBlockCalc) >= _numBlocksLeft) // contract is done
       return _numBlocksLeft; // prevent neg number
     
     else return(block.number - _lastBlockCalc);
   }

   function withdrawUnlockedLP() internal
   {
     if(block.timestamp >= _unlockTime)
       {
	 ITokenLock lock = ITokenLock(_lockAddress);
	 uint256[] memory lockIDs = lock.getDepositsByWithdrawalAddress(address(this));
	 
	 // withdraw all the tokens
	 for(uint i=0;i<lockIDs.length;i++)
	   {
	     lock.withdrawTokens(lockIDs[i]);
	   }
       }
   }

   // allow poster to closed this order after unlockTime
   function closeUnlockedOrder() public
   {
     require(_isDone == false && _isActive == false);
     require(msg.sender == _postedBy);
     require(block.timestamp >= _unlockTime);
     
     _isDone = true;     
     // notify factory we are closing...  again
     _Factory.closeOrder(address(this));
     
     withdrawUnlockedLP();
     
     // shouldn't be any other tokens left in contract but just in case
     // there are send them all to postedBy
     uint rewardAmount = _rewardToken.balanceOf(address(this));
     uint lpAmount = _LPToken.balanceOf(address(this));
     uint eAmount = _entranceFeeToken.balanceOf(address(this));
     
     // send all remaining tokens back to poster (if any)
     if(rewardAmount > 0)
       _rewardToken.transfer(_postedBy, rewardAmount);
     if(lpAmount > 0)
       _LPToken.transfer(_postedBy, lpAmount);
     if(eAmount > 0)
       _entranceFeeToken.transfer(_postedBy, eAmount);
     
   }
   
   // close order
   function iclose() internal
   {
     require(_isActive);
       _isActive = false;
     
     // notify factory we are closing
     _Factory.closeOrder(address(this));
     
     for(uint i=0;i<_Stakers.length();i++)
       {
	 // remaining rewards to stakers
	 if(_rewardBalance[_Stakers.at(i)] > 0)
	   _rewardToken.transfer(_Stakers.at(i), _rewardBalance[_Stakers.at(i)]);
       }     
   }

   function getContractBalances() public view returns(uint, uint, uint)
   {
     return(_entranceFeeToken.balanceOf(address(this)), _rewardToken.balanceOf(address(this)), _LPToken.balanceOf(address(this)) );
   }
   
   function getStakers() public view returns(TokenSaleLib.stakeOut[] memory)
   {
     uint len = _Stakers.length();
     TokenSaleLib.stakeOut[] memory out = new TokenSaleLib.stakeOut[](len);
    
     for(uint i=0;i<len;i++)
       {
	 out[i].staker = _Stakers.at(i);
	 out[i].stake =  _stakeBalance[_Stakers.at(i)];
       }
     return out;
   }

   function getInfo(address sender) public view returns(TokenSaleLib.stakeInfo memory)
   {
     TokenSaleLib.stakeInfo memory out;
     ITokenLock lock = ITokenLock(_lockAddress);
     
     out.LPToken = address(_LPToken);          
     out.rewardToken = address(_rewardToken);
     out.entranceFeeToken = address(_entranceFeeToken);
     out.postedBy =  address(_postedBy);
     out.addr = address(this);
     
     out.stakeFee =  _stakeFee;              // fee in LP % taken from stakers  
     out.numBlocks = _numBlocks;             // end block for staking
     out.minStake = _minStake;               // minimum amount of stake
     out.rewardAmount = _rewardAmount;       // amount of reward when posted
     out.isActive = _isActive;
     out.isDone = _isDone;
     out.featured = _featured;
     out.unlockTime = _unlockTime;
     out.liquidityPercent = _liquidityPercent;
     
     out.lastBlockCalc = _lastBlockCalc;
     out.myStake = _stakeBalance[sender];
     out.myUnclaimed = _rewardBalance[sender];
     out.totalStake = _totalStake;               // total amount of LP being staked between all stakers
     out.numBlocksLeft = _numBlocksLeft;
     out.lockedTokens = lock.getTokenBalanceByAddress(address(_LPToken), address(this));
     out.stakers = getStakers();
     return(out);
   }
  }

pragma solidity >=0.6.0;

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

pragma solidity >=0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableAddressSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        address[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (address => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, address value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, address value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            address lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, address value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (address) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return _at(set._inner, index);
    }
}

// SPDX-License-Identifier: UNLICENSED
// TokenSaleFactory v1.0.0 by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./TokenSaleOrderERC20.sol";
import "./TokenSaleLib.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract TokenSaleFactory
{
  IERC20 public _homeToken;  
  address public _devWallet;
  address public _lockAddress;
  
  uint public _featureFee;  
  bool private _initialized;
  bool public _isActive;
  address public _uniRouter;
  address public _uniFactory;
  
  using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
  EnumerableAddressSet.AddressSet _openOrders;
  EnumerableAddressSet.AddressSet _lockedOrders; // order that are closed but still locked
  EnumerableAddressSet.AddressSet _closedOrders; // closed and unlocked
  EnumerableAddressSet.AddressSet _bannedOrders;

  uint public  _stakingFee; // divide by 10000 (10 is .1%, or .001)
  
  mapping(address => bool) public _owners;  
  
  function initialize(uint stakeFee, uint featureFee, address homeToken) public
  {
    require(!_initialized);
    _initialized = true;
    _owners[msg.sender] = true;
    _devWallet = msg.sender;
    _stakingFee = stakeFee;
    _featureFee = featureFee;
    _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    _uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    _homeToken = IERC20(homeToken);    
    // team.finance lock contract
    _lockAddress = 0x7f207D66240fBe8db3f764f6056B6BE8725CC90a; //ropsten
  }
  
  function deployERC20Staking(address rewardToken, uint rewardAmount, uint numBlocks, uint stakingFee, address entranceFeeToken, uint minStake, bool featured, uint unlockTime, uint liquidityPercent) public returns(address)
  {
    require(_isActive, 'not active');
    require(unlockTime > block.timestamp, 'unlock time must be in future');
    require(unlockTime < 10000000000, 'Enter an unix timestamp in seconds, not miliseconds');
    require(rewardToken != address(0) && entranceFeeToken != address(0) && entranceFeeToken != rewardToken, 'invalid token');
    
    TokenSaleLib.OrderVars memory vars;
    
    // the public
    vars.LPToken = address(0);
    vars.rewardToken = rewardToken;
    vars.rewardAmount = rewardAmount;
    vars.postedBy = msg.sender;
    vars.numBlocks = numBlocks;
    vars.stakeFee = _stakingFee;
    vars.entranceFeeToken = entranceFeeToken;
    vars.minStake = minStake;
    vars.devWallet = _devWallet;
    vars.unlockTime = unlockTime;
    vars.liquidityPercent = liquidityPercent;
    vars.uniRouter = _uniRouter;
    vars.lockAddress = _lockAddress;
    
    if (address(_homeToken) != address(0))
      {
	vars.featured = featured;
      }
    
    // owners can set nore options
    if(_owners[msg.sender])
      {
	vars.stakeFee = stakingFee;
      }
	    
    return(deploy(vars));
  }

  function deploy(TokenSaleLib.OrderVars memory vars) internal returns(address)
  {
    require(vars.rewardAmount >= vars.numBlocks, 'reward too low'); 
    if(!_owners[vars.postedBy] && address(_homeToken) != address(0)) // featureFee is paid with homeToken
      {
	uint256 allowance = _homeToken.allowance(vars.postedBy, address(this));
	uint256 amountDue = 0;
	
	if(vars.featured)
	  amountDue += _featureFee;
	
	if(amountDue > 0)
	  require(allowance >= amountDue && _homeToken.transferFrom(vars.postedBy, _devWallet, amountDue), 'failed amountdue');
     }

    address lptoken = getUniPair(vars.entranceFeeToken, vars.rewardToken);
    require(lptoken != address(0), 'invalid lptoken');
    vars.LPToken = lptoken;
    
    IERC20 token = IERC20(vars.rewardToken);
    TokenSaleOrderERC20 saleOrder = new TokenSaleOrderERC20();    
    
    require(token.allowance(vars.postedBy, address(this)) >= vars.rewardAmount, 'reward allowance');
    require(token.transferFrom(vars.postedBy, address(this), vars.rewardAmount), 'reward xfer');
    require(token.approve(address(saleOrder), vars.rewardAmount), 'reward approve');
    
    saleOrder.initialize(vars);
    saleOrder.startOrder();
    _openOrders.add(address(saleOrder));
    return(address(saleOrder));
  }
  
  function addressSetToArray(EnumerableAddressSet.AddressSet storage _set) internal view returns(address[] memory)
  {
    uint size = _set.length();
    address[] memory out = new address[](size);
    for(uint i=0;i<size;i++)
      out[i] = _set.at(i);
    return out;
  }
  
  function getUniPair(address tokenA, address tokenB) public view returns (address) {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    IUniswapV2Factory uniFactory = IUniswapV2Factory(_uniFactory);    
    return(uniFactory.getPair(token0,token1));
  }
  
  function getOpenOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_openOrders));
  } 
  
  function getLockedOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_lockedOrders));
  }
 
  function getClosedOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_closedOrders));
  }
 
  function getBannedOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_bannedOrders));
  }
 
  function closeOrder(address addr) public
  {
    if(_openOrders.contains(addr) && addr == msg.sender) // contract closing itself
      {	
	_lockedOrders.add(addr);
	_openOrders.remove(addr);
      }
    else if(_lockedOrders.contains(addr) && addr == msg.sender)
      {	
	_lockedOrders.remove(addr);
	_closedOrders.add(addr);
      }
    
    // devs can delist an order and ban it from the site
    if(_owners[msg.sender])
      {
	if(_openOrders.contains(addr))
	  {	
	    _openOrders.remove(addr);
	    _bannedOrders.add(addr);
	  }
	else if(_lockedOrders.contains(addr))
	  {	
	    _lockedOrders.remove(addr);
	    _bannedOrders.add(addr);
	  }
      }
  }

  // owner functions
  function setActive(bool a) public
  {
    require(_owners[msg.sender]);
      _isActive = a;
  }

  // stakedex token for featured / premium fees
  function setHomeToken(address a) public
  {
    require(_owners[msg.sender]);
    _homeToken = IERC20(a);
  }

  function setLockContract(address a) public
  {
    require(_owners[msg.sender]);
    _lockAddress = a;
  }
  
  function setFeatureFee(uint a) public
  {
    require(_owners[msg.sender]);
      _featureFee = a;
  }
  
  function setController(address n, bool a) public
  {
    require(_owners[msg.sender]);
    _owners[n] = a;
  }

  // set amount stakers pay in LP
  function setStakingFee(uint percent) public
  {
    require(_owners[msg.sender]);
    _stakingFee = percent;
  }

  function setDevWallet(address addr) public
  {
    require(_owners[msg.sender]);
    _devWallet = addr;
  }
}

// SPDX-License-Identifier: UNLICENSED
// TokenSaleLib v1.0.0 by Stakedex.io 2021

pragma solidity 0.8.0;

library TokenSaleLib
  {
   struct OrderVars
   {
     address LPToken;      // liquidity token for liquidity add
     address rewardToken;  // token being rewarded
     address entranceFeeToken; // token used to enter
     address feeToken;     // token used to pay fees (by order poster)
     address devWallet;    // fee wallet
     address postedBy;
     
     uint rewardAmount;    // total amount being rewarded
     uint numBlocks;       // length of token sale
     uint stakeFee;        // fee to dev wallet (percent)
     uint minStake;        // minimum total stake
     
     uint unlockTime;      // unix time in seconds
     uint liquidityPercent;// percent of stake to use for liquidity
     
     bool featured;        // featured token sale

     address uniRouter;
     address lockAddress;  // address of team.finance lock contract
   }

   // staker data
   struct stakeOut
   {
     address staker;       // address of staker
     uint stake;           // amount of stake
   }

   // unchanging stake order info
   struct stakeInfo
   {
     address LPToken;
     address rewardToken;
     address entranceFeeToken;
     address feeToken;
     address postedBy;
     address addr;            // address of this order
     
     uint rewardAmount;       // amount of reward when posted
     uint numBlocks;          // total number of blocks to reward
     uint stakeFee;           // fee in LP % taken from stakers
     uint minStake;           // minimum amount of stake
     
     uint unlockTime;         // unix timestamp in seconds
     uint liquidityPercent;   // percent of entranceFee used for liquidity
     uint lockedTokens;       // balance of locked LP Tokens
     bool featured;
     bool isActive;           // order still active
     bool isDone;             // order completely empty and done
     
     uint lastBlockCalc;
     uint myStake;            // senders stake amount
     uint myUnclaimed;        // senders unclaimed rewards     
     uint totalStake;         // total amount of LP being staked between all stakers
     uint numBlocksLeft;
     
     stakeOut[] stakers;
   }
  }

pragma solidity >=0.8.0;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.0;

interface ITokenLock {
function lockTokens(
	 address _tokenAddress,
	 uint256 _amount,
	 uint256 _unlockTime
	 ) external returns (uint256 _id);
function withdrawTokens(uint256 _id) external;
function getDepositsByWithdrawalAddress(address _withdrawalAddress) view external returns (uint256[] memory);
function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view external returns (uint256);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}