// SPDX-License-Identifier: UNLICENSED
// StakeOrderERC20 by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "./StakeOrderFactory.sol";
import "./StakeOrderLib.sol";

contract LPStakeOrderERC20
  {
   StakeOrderFactory _Factory;
   
   IERC20 public _LPToken;            // liquidity token required
   IERC20 public _rewardToken;        // reward token provided by posteBy
   IERC20 public _entranceFeeToken;   // token used for entrance fee
   IERC20 public _premiumToken;       // token required to be hodling to enter staking
  
   address public _postedBy;       // who posted the order
   address public _devWallet;
  
   uint public _premiumAmount;      // min amount hodling premium token to stake
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
  
   bool private _initialized;
   bool public _isActive;
  
   mapping(address => uint) public _stakeBalance;   // stake balances of stakers
   mapping(address => uint) public _rewardBalance;  // reward balances of stakers
   mapping(address => uint) public _enteredBlock;   // block at which this address entered. used to make sure nobody entered while going thrugh_Stakers list
  
   using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
   EnumerableAddressSet.AddressSet _Stakers;

   function initialize(StakeOrderLib.OrderVars calldata vars) external
   {
     require(!_initialized);
     _initialized = true;

     require(vars.rewardToken != address(0) && vars.LPToken != address(0));
      
     _rewardToken = IERC20(vars.rewardToken);
     _LPToken = IERC20(vars.LPToken);
     _entranceFeeToken = IERC20(vars.entranceFeeToken);
     _premiumToken = IERC20(vars.premiumToken);
     _premiumAmount = vars.premiumAmount;

     _stakeFee = vars.stakeFee;
     _postedBy = vars.postedBy;
     _numBlocks = vars.numBlocks;
     _numBlocksLeft = vars.numBlocks;
     _entranceFee = vars.entranceFee;
     _Factory = StakeOrderFactory(msg.sender);
     _devWallet = vars.devWallet;
     _minStake = vars.minStake;
     
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
    
     require(_isActive);
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
     require(amount >= _minStake);
     
     // premium orders are required to be holding a minimum amount of premium token
     if(address(_premiumToken) != address(0) && _premiumAmount > 0)
       require(_premiumToken.balanceOf(msg.sender) >= _premiumAmount);

     if(updateBalances())
       return;
   
     // entry fee orders require an antry fee to be paid 
     if(address(_entranceFeeToken) != address(0) && _entranceFee > 0)
       {
	 require(_entranceFeeToken.allowance(msg.sender, address(this)) >= _entranceFee);
	 require(_entranceFeeToken.transferFrom(msg.sender, _devWallet, _entranceFee));
       }
   
     require(_LPToken.allowance(msg.sender, address(this)) >= amount);

     uint fee = amount * _stakeFee / 10000; // 10 is .01%
     
     uint stakeAmount = amount - fee;
   
     // send fee to dev wallet
     require(_LPToken.transferFrom(msg.sender, address(this), amount));
     require(_LPToken.transfer(_devWallet, fee) == true);

     // always update balances before we change anything

     _stakeBalance[msg.sender] = _stakeBalance[msg.sender] + stakeAmount; // add just in case they have already staked before
     _totalStake = _totalStake + stakeAmount;
     
     if(!_Stakers.contains(msg.sender)) // new staker
       {
	 _Stakers.add(msg.sender);
	 _enteredBlock[msg.sender] = block.number;
       }
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

   // withdraw all stakes and stop staking
   function withdraw() public
   {
     // always update balances before we change anything
     if(updateBalances())
       return;
   
     require(_stakeBalance[msg.sender] > 0);
   
     require(_LPToken.transfer(msg.sender, _stakeBalance[msg.sender]));
     require(_rewardToken.transfer(msg.sender, _rewardBalance[msg.sender]));
     _totalStake = _totalStake - _stakeBalance[msg.sender];
     _stakeBalance[msg.sender] = 0;
     _rewardBalance[msg.sender] = 0;
      
     _Stakers.remove(msg.sender);
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

   function close() public
   {
     require(msg.sender == address(_Factory));
     updateBalances();
     iclose();
   }
 
   // close order
   function iclose() internal
   {
     _isActive = false;
     // return all LP tokens and rewards to stakera
     for(uint i=0;i<_Stakers.length();i++)
       {
	 if(_stakeBalance[_Stakers.at(i)] > 0)
	   _LPToken.transfer(_Stakers.at(i), _stakeBalance[_Stakers.at(i)]);
	 if(_rewardBalance[_Stakers.at(i)] > 0)
	   _rewardToken.transfer(_Stakers.at(i), _rewardBalance[_Stakers.at(i)]);
       }

     uint rewardAmount = _rewardToken.balanceOf(address(this));
   
     // send all unused reward tokens back to poster
     if(rewardAmount > 0)
       _rewardToken.transfer(_postedBy, rewardAmount);

     // if for some reason any lptoken left give it to devwallet
     uint amount = _LPToken.balanceOf(address(this));     
     if(amount > 0)
       _LPToken.transfer(_devWallet, amount);
   }

   function getContractBalances() public view returns(uint, uint)
   {
     return(_rewardToken.balanceOf(address(this)), _LPToken.balanceOf(address(this)));
   }
   
   function getStakers() public view returns(StakeOrderLib.stakeOut[] memory)
   {
     uint len = _Stakers.length();
     StakeOrderLib.stakeOut[] memory out = new StakeOrderLib.stakeOut[](len);
    
     for(uint i=0;i<len;i++)
       {
	 out[i].staker = _Stakers.at(i);
	 out[i].stake =  _stakeBalance[_Stakers.at(i)];
       }
     return out;
   }

   function getInfo(address sender) public view returns(StakeOrderLib.stakeInfo memory)
   {
     StakeOrderLib.stakeInfo memory out;
     out.LPToken = address(_LPToken);          
     out.rewardToken = address(_rewardToken);
     out.entranceFeeToken = address(_entranceFeeToken);
     out.premiumToken =  address(_premiumToken);
     out.postedBy =  address(_postedBy);
     out.addr = address(this);
     
     out.premiumAmount =  _premiumAmount;    // min amount hodling premium token to stake
     out.entranceFee = _entranceFee;         // amount charged for staking entrance fee
     out.stakeFee =  _stakeFee;              // fee in LP % taken from stakers  
     out.numBlocks = _numBlocks;             // end block for staking
     out.minStake = _minStake;               // minimum amount of stake
     out.rewardAmount = _rewardAmount;       // amount of reward when posted
     out.isActive = _isActive;

     out.lastBlockCalc = _lastBlockCalc;
     out.myStake = _stakeBalance[sender];
     out.myUnclaimed = _rewardBalance[sender];
     out.totalStake = _totalStake;               // total amount of LP being staked between all stakers
     out.numBlocksLeft = _numBlocksLeft;
     
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
// StakeOrderFactory by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./LPStakeOrderERC20.sol";
import "./StakeOrderLib.sol";

contract StakeOrderFactory
{
  IERC20 public _homeToken;  
  address public _devWallet;
  uint public _featureFee;  
  bool private _initialized;
  bool public _isActive;
  
  using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
  EnumerableAddressSet.AddressSet _openOrders;
  EnumerableAddressSet.AddressSet _closedOrders;

  uint public  _stakingFeeLPERC20; // divide by 10000 (10 is .1%, or .001)
  
  mapping(address => bool) public _owners;  
  mapping(address => bool) public _featured;
  mapping(uint => uint) public _tiers;
  mapping(uint => uint) public _tierFees; // all fees in _homeToken
  
  function initialize(uint stakeFee, uint featureFee) public
  {
    require(!_initialized);
    _initialized = true;
    _owners[msg.sender] = true;
    _devWallet = msg.sender;
    _stakingFeeLPERC20 = stakeFee;
    _featureFee = featureFee;
    _tiers[0] = 0;
    _tiers[1] = 50000000000000000000;
    _tiers[2] = 100000000000000000000;
    _tiers[3] = 500000000000000000000;
    _tiers[4] = 2500000000000000000000;
    _tiers[5] = 5000000000000000000000;
  }
  
  function deployERC20Staking(address LPToken, address rewardToken, uint rewardAmount, uint numBlocks, uint stakingFee, uint entranceFee, address entranceFeeToken, address premiumToken, uint premiumAmount, uint minStake, bool featured, uint tier) public returns(address)
  {
    require(_isActive);
    StakeOrderLib.OrderVars memory vars;
    
    // the public
    vars.LPToken = LPToken;
    vars.rewardToken = rewardToken;
    vars.rewardAmount = rewardAmount;
    vars.postedBy = msg.sender;
    vars.numBlocks = numBlocks;
    vars.stakeFee = _stakingFeeLPERC20;
    vars.entranceFee  = 0;
    vars.entranceFeeToken = address(0);
    vars.premiumAmount = 0;
    vars.minStake = minStake;
    vars.devWallet = _devWallet;
    
    if (address(_homeToken) != address(0))
      {
	vars.premiumToken = address(_homeToken);
	vars.tier = tier;
	vars.featured = featured;
      }
    
    // owners can set nore options
    if(_owners[msg.sender])
      {
	vars.stakeFee = stakingFee;
	vars.entranceFee = entranceFee;
	vars.entranceFeeToken = entranceFeeToken;
	vars.premiumToken = premiumToken;
	vars.premiumAmount = premiumAmount;
      }
	    
    return(deploy(vars));
  }

  function deploy(StakeOrderLib.OrderVars memory vars) internal returns(address)
  {
    require(vars.rewardAmount >= vars.numBlocks); 
    if(!_owners[vars.postedBy] && address(_homeToken) != address(0)) // featureFee is paid with homeToken
      {
	uint256 allowance = _homeToken.allowance(vars.postedBy, address(this));
	uint256 amountDue = 0;
	if(vars.featured)
	  amountDue += _featureFee;
	
	amountDue += _tierFees[vars.tier];
	
	if(amountDue > 0)
	  require(allowance >= amountDue && _homeToken.transferFrom(vars.postedBy, _devWallet, amountDue));
     }
    
    vars.premiumAmount = _tiers[vars.tier];
    
    IERC20 token = IERC20(vars.rewardToken);
    IUniswapV2Pair lptoken = IUniswapV2Pair(vars.LPToken);
    
    require(lptoken.MINIMUM_LIQUIDITY() > 0, "invalid LP token");
        
    LPStakeOrderERC20 stakeOrder = new LPStakeOrderERC20();
    require(token.allowance(vars.postedBy, address(this)) >= vars.rewardAmount &&
	    token.transferFrom(vars.postedBy, address(this), vars.rewardAmount) &&
	    token.approve(address(stakeOrder), vars.rewardAmount));
    
    _openOrders.add(address(stakeOrder));
    _featured[address(stakeOrder)] = vars.featured;
    stakeOrder.initialize(vars);
    stakeOrder.startOrder();
    return(address(stakeOrder));
  }
  
  function setTier(uint tier, uint amount) public
  {
    require(_owners[msg.sender]);
    _tiers[tier] = amount;
  }
  
  function setTierFee(uint tier, uint amount) public
  {
    require(_owners[msg.sender]);
    _tierFees[tier] = amount;
  }
  
  function addressSetToArray(EnumerableAddressSet.AddressSet storage _set) internal view returns(address[] memory)
  {
    uint size = _set.length();
    address[] memory out = new address[](size);
    for(uint i=0;i<size;i++)
      out[i] = _set.at(i);
    return out;
  }
  
  function getOpenOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_openOrders));
  } 
  
  function getClosedOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_closedOrders));
  }

  function isFeatured(address addr) public view returns(bool)
  {
    return(_featured[addr]);
  }
  
  function closeOrder(address addr) public
  {
    if(_openOrders.contains(addr) && (addr == msg.sender || _owners[msg.sender])) // owners or the contract itself
      {
	_closedOrders.add(addr);
	_openOrders.remove(addr);
      }

    // if contract is not closing itself we need to initiate close command
    if(_owners[msg.sender])
      {
	LPStakeOrderERC20 order = LPStakeOrderERC20(addr);
	order.close();
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
    _tierFees[0] = 5000000000000000000000;
    _tierFees[1] = 2500000000000000000000;
    _tierFees[2] = 500000000000000000000;
    _tierFees[3] = 100000000000000000000;
    _tierFees[4] = 50000000000000000000;
    _tierFees[5] = 0; // tier 5 orders are free

  }
  
  function setFeatured(address addr, bool a) public
  {
    if(_owners[msg.sender])
      {
	_featured[addr] = a;
      }
    else if(address(_homeToken) != address(0))
      {
	LPStakeOrderERC20 order = LPStakeOrderERC20(addr);
	if(msg.sender == order._postedBy() && a == true) // featureFee is paid with homeToken
	  {
	    uint256 allowance = _homeToken.allowance(order._postedBy(), address(this));
	    require(allowance >= _featureFee && _homeToken.transferFrom(order._postedBy(), _devWallet, _featureFee));
	    _featured[addr] = true;
	  }
      } 
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
    _stakingFeeLPERC20 = percent;
  }

  function setDevWallet(address addr) public
  {
    require(_owners[msg.sender]);
    _devWallet = addr;
  }
}

// SPDX-License-Identifier: UNLICENSED
// StakeOrderLib by Stakedex.io 2021

pragma solidity 0.8.0;

library StakeOrderLib
  {
   struct OrderVars
   {
     address LPToken;
     address rewardToken;
     uint rewardAmount;
     address postedBy;
     uint numBlocks;
     uint stakeFee;
     uint entranceFee;
     address entranceFeeToken;
     address premiumToken;
     uint premiumAmount;
     address devWallet;
     uint minStake;
     bool featured;
     uint tier;
   }

   struct stakeOut
   {
     address staker;
     uint stake;
   }

   // unchanging stake order info
   struct stakeInfo
   {
     address LPToken;
     address rewardToken;
     address entranceFeeToken;
     address premiumToken;
     address postedBy;
     address addr;
     
     uint premiumAmount;      // min amount hodling premium token to stake
     uint entranceFee;        // amount charged for staking entrance fee
     uint stakeFee;           // fee in LP % taken from stakers
     uint numBlocks;          // total number of blocks to reward
     uint minStake;           // minimum amount of stake
     uint rewardAmount;       // amount of reward when posted
     bool isActive;           // order still active
     bool featured;

     uint lastBlockCalc;
     uint myStake;            // senders stake amount
     uint myUnclaimed;        // senders unclaimed rewards     
     uint totalStake;         // total amount of LP being staked between all stakers
     uint numBlocksLeft;
     
     stakeOut[] stakers;
   }
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