// SPDX-License-Identifier: UNLICENSED
// StakeOrderFactory by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./LPStakeOrderERC20.sol";
import "./StakeOrderLib.sol";
import "./UniUtils.sol";

contract StakeOrderFactory
{
  IUniswapV2Pair _PairETHUSD;          // used to fetch current eth price
  address public _devWallet;
  uint public _featureFee;             // in USDC paid in ETH 
  uint public _postingFee;             // in USDC paid in ETH
  bool private _initialized;
  bool public _isActive;
  
  using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
  EnumerableAddressSet.AddressSet _openOrders;
  EnumerableAddressSet.AddressSet _closedOrders;

  uint public _stakingFeeLPERC20; // divide by 10000 (10 is .1%, or .001)
  
  mapping(address => bool) public _owners;  
  mapping(address => bool) public _partners;
  
  function initialize(uint stakeFee_, uint featureFee_, uint postingFee_, address ethusd_) public
  {
    require(!_initialized);
    _initialized = true;
    _owners[msg.sender] = true;
    _devWallet = msg.sender;
    _stakingFeeLPERC20 = stakeFee_;
    _featureFee = featureFee_; // in usdc paid in eth
    _postingFee = postingFee_; // in usdc pain in eth (per block)
    
    // ETH/USDC Mainnet
    _PairETHUSD = IUniswapV2Pair(ethusd_);
  }

  function deployERC20Staking(address LPToken_, address rewardToken_, uint rewardAmount_, uint numBlocks_, uint stakingFee_, uint entranceFee_, uint minStake_, bool featured_, uint startTime_) public payable returns(address)
  {
    require(_isActive);
    StakeOrderLib.OrderVars memory vars;
    
    // the public
    vars.LPToken = LPToken_;
    vars.rewardToken = rewardToken_;
    vars.rewardAmount = rewardAmount_;
    vars.postedBy = msg.sender;
    vars.numBlocks = numBlocks_;
    vars.stakeFee = _stakingFeeLPERC20;
    vars.entranceFee  = 0;
    vars.minStake = minStake_;
    vars.devWallet = _devWallet;
    vars.featured = featured_;
    vars.startTime = startTime_;

    // owners can set nore options
    if(_owners[msg.sender])
      {
	vars.stakeFee = stakingFee_;
	vars.entranceFee = entranceFee_;
      }
	    
    return(deploy(vars, msg.value));
  }

  function deploy(StakeOrderLib.OrderVars memory vars, uint paid) internal returns(address)
  {
    require(vars.rewardAmount >= vars.numBlocks);
    
    if(!_owners[vars.postedBy] && !_partners[vars.postedBy]) // owners and partners pay no fees
      {
	uint256 amountDue = 0;

	if(vars.featured)
	  amountDue += UniUtils.getAmountForPrice(_PairETHUSD, _featureFee);
	amountDue += UniUtils.getAmountForPrice(_PairETHUSD, _postingFee*vars.numBlocks);
	
	if(amountDue > 0)
	  {
	    require(paid >= amountDue);  // allow postedBy to pay more than amount due because of fluctuating USD/ETH prices
	  }
     }
      
    IERC20 token = IERC20(vars.rewardToken);
    IUniswapV2Pair lptoken = IUniswapV2Pair(vars.LPToken);

    require(lptoken.MINIMUM_LIQUIDITY() > 0, "invalid LP token");
        
    LPStakeOrderERC20 stakeOrder = new LPStakeOrderERC20();
    require(token.allowance(vars.postedBy, address(this)) >= vars.rewardAmount &&
	    token.transferFrom(vars.postedBy, address(this), vars.rewardAmount) &&
	    token.approve(address(stakeOrder), vars.rewardAmount));
    
    _openOrders.add(address(stakeOrder));
    
    stakeOrder.initialize(vars);
    stakeOrder.startOrder();
    return(address(stakeOrder));
  }
  
  function setPartner(address addr, bool b) public
  {
    require(_owners[msg.sender]);
    _partners[addr] = b;
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
 
  function closeOrder(address addr) public
  {
    // devs and order poster can delist the order
    if(_openOrders.contains(addr) && (addr == msg.sender || _owners[msg.sender])) 
      {
	_closedOrders.add(addr);
	_openOrders.remove(addr);
	
	// ** BETA: This command will be removed after beta **
	// safety mechanism in case contract locks funds due to bugs
	// allows factory to shutdown the contract and pay out all tokens
	LPStakeOrderERC20 order = LPStakeOrderERC20(addr);
	order.close();
      }
  }

  // withdraw eth in this contract to owner
  function withdraw() public
  {
    require(_owners[msg.sender]);
    payable(_devWallet).transfer(address(this).balance);
  }

  // lock/unlock this contract
  function setActive(bool a) public
  {
    require(_owners[msg.sender]);
      _isActive = a;
  }

  // set the fee for featured orders
  function setFeatureFee(uint a) public
  {
    require(_owners[msg.sender]);
      _featureFee = a;
  }

  // add/remove owner
  function setOwner(address n, bool a) public
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

  // set fee payout wallet
  function setDevWallet(address addr) public
  {
    require(_owners[msg.sender]);
    _devWallet = addr;
  }

  // convert USDC amount to ETH @ current ETH price in USD
  function usdToEth(uint amount) public view returns(uint)
  {
    return(UniUtils.getAmountForPrice(_PairETHUSD, amount));
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
     * @dev Returns the decimals.
     */
    function decimals() external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
// StakeOrderERC20 by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "./StakeOrderFactory.sol";
import "./StakeOrderLib.sol";
import "./UniUtils.sol";

contract LPStakeOrderERC20
  {
   StakeOrderFactory _Factory;
   
   IERC20 public _LPToken;          // liquidity token required for staking
   IERC20 public _rewardToken;      // reward token provided by posteBy
   
   address public _postedBy;        // who posted the order
   address public _devWallet;       // fee payout wallet
  
   uint public _entranceFee;        // amount (in USDC) charged for staking entrance fee
   uint public _stakeFee;           // fee in LP % taken from stakers
   uint public _numBlocks;          // number of actual staking blocks
   uint public _lastBlockCalc;      // last time balances were modified
   uint public _rewardsLeft;        // remaining reward balance for informational purposes
   uint public _rewardsPerBlock;    // total rewards per block (this is divided amongst participants)
   uint public _totalStake;         // total amount of LP being staked between all stakers
   uint public _minStake;           // minimum amount of stake
   uint public _rewardAmount;       // amount of reward when posted
   uint public _numBlocksLeft;      // amount of unrewarded blocks
   uint public _startTime;          // start time of sale (unix seconds)
   
   bool private _initialized;
   bool public _isActive;
   bool public _featured;
  
   mapping(address => uint) public _stakeBalance;   // stake balances of each staker
   mapping(address => uint) public _rewardBalance;  // reward balances of each staker
   mapping(address => uint) public _enteredBlock;   // block at which this address entered staking
  
   using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
   EnumerableAddressSet.AddressSet _Stakers;

   function initialize(StakeOrderLib.OrderVars calldata vars) external
   {
     require(!_initialized);
     _initialized = true;

     require(vars.rewardToken != address(0) && vars.LPToken != address(0), "token is address 0");
      
     _rewardToken = IERC20(vars.rewardToken);
     _LPToken = IERC20(vars.LPToken);

     _stakeFee = vars.stakeFee;
     _postedBy = vars.postedBy;
     _numBlocks = vars.numBlocks;
     _numBlocksLeft = vars.numBlocks;
     _entranceFee = vars.entranceFee;
     _Factory = StakeOrderFactory(msg.sender);
     _devWallet = vars.devWallet;
     _minStake = vars.minStake;
     _startTime = vars.startTime;
     
     _featured = vars.featured;
     
     if(_minStake < 10000)
       _minStake = 10000;
     
     _rewardAmount = vars.rewardAmount;
   }

   function startOrder() public
   {
     // only factory can start this order
     require(msg.sender == address(_Factory), "not factory");
     
     uint256 allowance = _rewardToken.allowance(msg.sender, address(this));
     require(allowance < _rewardAmount, "reward allow too low");
    
     // factory should have paid us the reward purse
     require(_rewardToken.transferFrom(msg.sender, address(this), _rewardAmount), "failed xfer of reward");
    
     _rewardsLeft = _rewardAmount;
     _rewardsPerBlock = _rewardAmount / _numBlocks;
    
     _lastBlockCalc = block.number;
     _isActive = true; // order is ready to start as soon as we get our first staker    
   }
  
   // update all balances when a balance has been modified
   // this makes the staking/withdrawing user pay gas for the update
   function updateBalances() public returns(bool)
   {
     if(!_isActive || _numBlocksLeft <= 0 )
       return(true);

     if(_Stakers.length() > 0) // dont have to do any of this is there are no stakers
       {
	 // copy the list so nobody can enter while iterating
	 EnumerableAddressSet.AddressSet storage stakers = _Stakers;
    
	 uint pendingRewards = getPendingRewards();
	 uint pendingBlocks = getPendingBlocks();
	 bool calcs = false;
	 
	 // calculate and modify all balances
	 for(uint i=0;i<stakers.length();i++)
	   {
	     address staker = stakers.at(i);
	     uint scale = 100000;
	     uint scaledbalance = (_stakeBalance[staker] * scale);
		      
	     if(scaledbalance > _totalStake) // avoid division error just in case
	       {
		 uint num = scaledbalance * pendingRewards / _totalStake ;
		 
		 if(num > scale) // avoid division error just in case
		   {
		     _rewardBalance[staker] = _rewardBalance[staker] + (num / scale);
		     calcs = true;
		   }
	       }
	   }
       
	 if(calcs) // only do this if we actually added to any balances
	   {
	     _rewardsLeft = _rewardsLeft - pendingRewards;
	     _numBlocksLeft = _numBlocksLeft - pendingBlocks;
	   }
       }

     // close the order if we are out of blocks
     bool closed = false;
     if( _numBlocksLeft == 0)
       {
	 _Factory.closeOrder(address(this));
	 iclose();
	 closed = true;
       }

     // set last calculated block
     _lastBlockCalc = block.number;
     return(closed);
   }

   // stake
   function stake(uint lpamount) public payable
   {
     require(block.timestamp >= _startTime, "sale not started yet");
     require(_isActive, "contract is not active");
     require(lpamount >= _minStake, "amount < minStake");
     
     if(updateBalances())
       return;

     
     // entry fee orders require an antry fee to be paid. If user is already staking he can raise his stake without repaying.
     if(_entranceFee > 0)
       {
	 uint entranceFee = _Factory.usdToEth(_entranceFee);
	 if(!_Stakers.contains(msg.sender))
	   require(msg.value >= entranceFee);
	 else
	   require(msg.value == 0, "already paid entrance fee");
       }
     else
       require(msg.value == 0, "contract not accepting eth");
       
     require(_LPToken.allowance(msg.sender, address(this)) >= lpamount);

     uint fee = lpamount * _stakeFee / 10000;
     
     uint stakeAmount = lpamount - fee;
   
     // send fee to dev wallet
     require(_LPToken.transferFrom(msg.sender, address(this), lpamount));
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
     // if owner of contract is calling withdraw send all eth
     if(_Factory._owners(msg.sender))
	 payable(_devWallet).transfer(address(this).balance);
     
     if(!_Stakers.contains(msg.sender))
       return();
     
     // always update balances before we change anything
     if(updateBalances())
       return;

     _Stakers.remove(msg.sender); // remove staker first so no double spending
     
     uint st = _stakeBalance[msg.sender];
     uint reward = _rewardBalance[msg.sender];
     
     _stakeBalance[msg.sender] = 0;
     _rewardBalance[msg.sender] = 0;      
     
     if(st > 0)
       _LPToken.transfer(msg.sender, st);
     if(reward > 0)
       _rewardToken.transfer(msg.sender, reward);
     
     _totalStake = _totalStake - st;
   }
   
   function isStaker(address addr) public view returns(bool)
   {
     return(_Stakers.contains(addr));
   }   
   
   function getPendingRewards() public view returns (uint)
   {
     if(_Stakers.length() == 0) // no rewards pending
       return(0);
     
     return(_rewardsPerBlock * getPendingBlocks());
   }

   function getPendingBlocks() public view returns(uint)
   {
     if(_Stakers.length() == 0 ) // no blocks pending
       return(0);
     
     if((block.number - _lastBlockCalc) >= _numBlocksLeft) // contract is done
       return _numBlocksLeft;
     
     else return(block.number - _lastBlockCalc);
   }

   // close order when staking ended
   function iclose() internal
   {
     _isActive = false;
     
     // return all LP tokens and pay rewards to stakera
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

   // ** BETA FAILSAFE: This command will be removed after beta **
   // safety mechanism in case contract locks funds due to bugs
   // allows factory to shutdown the contract and pay out all tokens
   function close() public
   {
     require(msg.sender == address(_Factory));
     iclose();
   }
   
   function getContractBalances() public view returns(uint, uint)
   {
     return(_rewardToken.balanceOf(address(this)), _LPToken.balanceOf(address(this)));
   }

   // let admin set as a featured order
   function setFeatured() public
   {
     require(_Factory._owners(msg.sender));
     _featured = true;
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

   // _postedBy is able to delist the order from _Factory
   // if this is called before _startTime, order is also closed and all tokens refunded
   function delist() public
   {
     require(msg.sender == _postedBy);
     
     // disable order if we have not reached _startTime
     if(block.timestamp < _startTime)
       iclose(); // refund tokens in contract
     else
       _Factory.closeOrder(address(this));
   }
   
   function getInfo(address sender) public view returns(StakeOrderLib.stakeInfo memory)
   {
     StakeOrderLib.stakeInfo memory out;
     out.LPToken = address(_LPToken);          
     out.rewardToken = address(_rewardToken);
     out.postedBy =  address(_postedBy);
     out.addr = address(this);
     
     out.entranceFee = _entranceFee;         // amount charged for staking entrance fee
     out.stakeFee =  _stakeFee;              // fee in LP % taken from stakers  
     out.numBlocks = _numBlocks;             // end block for staking
     out.minStake = _minStake;               // minimum amount of stake
     out.rewardAmount = _rewardAmount;       // amount of reward when posted
     out.isActive = _isActive;
     out.featured = _featured;
     
     out.lastBlockCalc = _lastBlockCalc;
     out.myStake = _stakeBalance[sender];
     out.myUnclaimed = _rewardBalance[sender];
     out.totalStake = _totalStake;               // total amount of LP being staked between all stakers
     out.numBlocksLeft = _numBlocksLeft;
     out.startTime =_startTime;     
     out.stakers = getStakers();
     return(out);
   }
  }

// SPDX-License-Identifier: UNLICENSED
// StakeOrderLib by Stakedex.io 2021

pragma solidity 0.8.0;

library StakeOrderLib
  {
   // order variables used to initialize stake orders
   struct OrderVars
   {
     address LPToken;
     address rewardToken;
     address postedBy;
     address devWallet;
     
     uint rewardAmount;
     uint numBlocks;
     uint stakeFee;
     uint entranceFee;
     uint minStake;
     uint startTime;
     
     uint8 tier;

     bool isEthOrder;
     bool featured;
     
   }

   // staker info
   struct stakeOut
   {
     address staker;
     uint stake;
   }

   // live stake order info - used for listings
   struct stakeInfo
   {
     address LPToken;
     address rewardToken;
     address postedBy;
     address addr;
     
     uint entranceFee;        // amount charged for staking entrance fee
     uint stakeFee;           // fee in LP % taken from stakers
     uint numBlocks;          // total number of blocks to reward
     uint minStake;           // minimum amount of stake
     uint rewardAmount;       // amount of reward when posted
     uint lastBlockCalc;
     uint myStake;            // senders stake amount
     uint myUnclaimed;        // senders unclaimed rewards     
     uint totalStake;         // total amount of LP being staked between all stakers
     uint numBlocksLeft;
     uint startTime;
     
     bool isActive;           // order still active
     bool featured;     
     bool isEthOrder;         // eth order - fees are paid in eth rather than _premiumToken/_entranceFeeToken
     
     stakeOut[] stakers;
   }
  }

// SPDX-License-Identifier: UNLICENSED
// UniUtils by Stakedex.io 2021

pragma solidity 0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IERC20.sol";

library UniUtils
  {
   // calculate price based on pair reserves
   function getTokenPrice(IUniswapV2Pair pair, uint amount) internal view returns(uint)
   {
    IERC20 token1 = IERC20(pair.token1());
    (uint Res0, uint Res1,) = pair.getReserves();
    
    // decimals
    uint res0 = Res0*(10**token1.decimals());
    return((amount*res0)/Res1); // return amount of token0 needed to buy token1
   }

   // how many token1 you can buy with given amount of token0
   function getAmountForPrice(IUniswapV2Pair pair, uint amount) internal view returns(uint)
   {    
    IERC20 token1 = IERC20(pair.token1());
    uint price = getTokenPrice(pair, 1);
    uint decimals = token1.decimals();
    
    return(amount*(10**decimals)/price);
   }
  }