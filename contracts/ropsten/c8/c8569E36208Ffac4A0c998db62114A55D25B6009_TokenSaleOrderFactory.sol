// SPDX-License-Identifier: UNLICENSED
// StakeOrderFactory by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
//import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./TokenSaleOrderERC20.sol";
import "./TokenSaleOrderLib.sol";

contract TokenSaleOrderFactory
{
  IERC20 public _homeToken;  
  address public _devWallet;
  IUniswapV2Router02 _uniRouter;
  
  uint public _featureFee;  
  bool private _initialized;
  bool public _isActive;
  
  using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
  EnumerableAddressSet.AddressSet _openOrders;
  EnumerableAddressSet.AddressSet _lockedOrders;
  EnumerableAddressSet.AddressSet _closedOrders;

  uint public  _stakingFee; // divide by 10000 (10 is .1%, or .001)
  
  mapping(address => bool) public _owners;  
  mapping(address => bool) public _featured;
  
  function initialize(uint stakeFee, uint featureFee, address uniRouter) public
  {
    require(!_initialized);
    _initialized = true;
    _owners[msg.sender] = true;
    _devWallet = msg.sender;
    _stakingFee = stakeFee;
    _featureFee = featureFee;
    _uniRouter = IUniswapV2Router02(uniRouter);
  }

  function deployERC20Staking(address rewardToken, uint rewardAmount, uint numBlocks, uint stakingFee, uint entranceFee, address entranceFeeToken, address premiumToken, uint premiumAmount, bool featured, uint lockPercent, uint unlockBlock) public returns(address)
  {
    require(_isActive);
    TokenSaleOrderLib.OrderVars memory vars;
    
    // the public
    vars.rewardToken = rewardToken;
    vars.rewardAmount = rewardAmount;
    vars.postedBy = msg.sender;
    vars.numBlocks = numBlocks;
    vars.stakeFee = _stakingFee;
    vars.entranceFee  = entranceFee;
    vars.entranceFeeToken = entranceFeeToken;

    // TODO replace this with poster pricing tiers
    vars.premiumToken = address(0);
    vars.premiumAmount = 0;
    
    vars.devWallet = _devWallet;
    
    vars.lockPercent = lockPercent;
    vars.unlockBlock = unlockBlock;
    
    vars.uniRouter = address(_uniRouter);
    
    if (address(_homeToken) != address(0))
      vars.featured = featured;

    // owners can set nore options
    if(_owners[msg.sender])
      {
	vars.stakeFee = stakingFee;
	vars.premiumToken = premiumToken;
	vars.premiumAmount = premiumAmount;
      }
    return(deploy(vars));
  }

  function uniswapPair(address tokenA, address tokenB) internal view returns(address)
  {
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    IUniswapV2Factory uniFactory = IUniswapV2Factory(_uniRouter.factory());

    address paddress = uniFactory.getPair(token0,token1);
    require(paddress != address(0), "Liquidity pair does not exist"); // make sure pair exists
     return(paddress);
  }

  function deploy(TokenSaleOrderLib.OrderVars memory vars) internal returns(address)
  {
    require(vars.rewardAmount >= vars.numBlocks); 
    vars.LPToken = uniswapPair(vars.entranceFeeToken, vars.rewardToken);
    
    if(!_owners[vars.postedBy] && vars.featured) // featureFee is paid with homeToken
      {
	uint256 allowance = _homeToken.allowance(vars.postedBy, address(this));
	require(allowance >= _featureFee && _homeToken.transferFrom(vars.postedBy, _devWallet, _featureFee));
      }
    
    IERC20 token = IERC20(vars.rewardToken);

    TokenSaleOrderERC20 tokenSaleOrder = new TokenSaleOrderERC20();
    require(token.allowance(vars.postedBy, address(this)) >= vars.rewardAmount &&
	    token.transferFrom(vars.postedBy, address(this), vars.rewardAmount) &&
	    token.approve(address(tokenSaleOrder), vars.rewardAmount));
    
    _openOrders.add(address(tokenSaleOrder));
    _featured[address(tokenSaleOrder)] = vars.featured;
    tokenSaleOrder.initialize(vars);
    tokenSaleOrder.startOrder();
    return(address(tokenSaleOrder));
  }
  
  function setUniRouter(address addr) public
  {
    require(_owners[msg.sender]);
    _uniRouter = IUniswapV2Router02(addr);

    uint len = _openOrders.length();
    for(uint i=0;i<len;i++)
      TokenSaleOrderERC20(_openOrders.at(i)).setUniRouter(addr);
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
  
  function getLockedOrders() public view returns(address[] memory)
  {
    return(addressSetToArray(_lockedOrders));
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
    TokenSaleOrderERC20 order = TokenSaleOrderERC20(addr);
    if(addr == msg.sender) // contract closing itself
      {
	if(block.number < order._unlockBlock())
	  {
	    // order is closed but still locked
	    if(_openOrders.contains(addr))
	      {
		_lockedOrders.add(addr);
		_openOrders.remove(addr);
	      }
	  }
	else
	  {
	    // order is not locked
	    if(_openOrders.contains(addr))
	      _openOrders.remove(addr);
	    if(_lockedOrders.contains(addr))
	      _lockedOrders.remove(addr);
	    _closedOrders.add(addr);
	  }
      }

    // dev is emergency closing the order. This can happen to scam tokens, fraudulent listings, etc.
    // owners of stakedex cannot cancel their own order. This is to comfort users that stakedex cannot rug a token sale.
    if(_owners[msg.sender])
      {
	if(!_owners[order._postedBy()])  // owners of Stakedex cannot cancel official stakedex orders
	  {
	    if(_openOrders.contains(addr))
	      _openOrders.remove(addr);
	    if(_lockedOrders.contains(addr))
	      _lockedOrders.remove(addr);
	    _closedOrders.add(addr);
	    order.close();
	  }
      }
  }

  // owner functions
  function setActive(bool a) public
  {
    require(_owners[msg.sender]);
      _isActive = a;
  }

  // stakedex token for featured fee
  function setHomeToken(address a) public
  {
    require(_owners[msg.sender]);
    _homeToken = IERC20(a);
  }
  
  function setFeatured(address addr, bool a) public
  {
    TokenSaleOrderERC20 order = TokenSaleOrderERC20(addr);
    address postedBy = order._postedBy();
    if(_owners[msg.sender]) // owners pay no fees
      _featured[addr] = a;
    else if(address(_homeToken) != address(0) && msg.sender == postedBy && a == true) // featureFee is paid with homeToken
      {
	uint256 allowance = _homeToken.allowance(postedBy, address(this));
	require(allowance >= _featureFee && _homeToken.transferFrom(postedBy, _devWallet, _featureFee));
	_featured[addr] = true;
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
    _stakingFee = percent;
  }

  function setDevWallet(address addr) public
  {
    require(_owners[msg.sender]);
    _devWallet = addr;
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

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: UNLICENSED
// TokenSaleOrderERC20 by Stakedex.io 2021

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./EnumerableAddressSet.sol";
import "./TokenSaleOrderFactory.sol";
import "./TokenSaleOrderLib.sol";
import "./IUniswapV2Router02.sol";

contract TokenSaleOrderERC20
  {
   TokenSaleOrderFactory _Factory;
   
   IERC20 public _LPToken;            // liquidity token required
   IERC20 public _rewardToken;        // reward token provided by posteBy
   IERC20 public _entranceFeeToken;   // token used for entrance fee
   IERC20 public _premiumToken;       // token required to be hodling to enter staking
  
   address public _postedBy;          // who posted the order
   address public _devWallet;
   IUniswapV2Router02 _uniRouter;
   
   uint public _premiumAmount;      // min amount hodling premium token to stake
   uint public _entranceFee;        // amount charged for staking entrance fee
   uint public _stakeFee;           // fee in LP % taken from stakers  
   uint public _numBlocks;          // end block for staking
   uint public _lastBlockCalc;      // last time balances were modified
   uint public _rewardsLeft;        // remaining reward balance for informational purposes
   uint public _rewardsPerBlock;    // total rewards per block (this is divided amongst participants)
   uint public _totalStake;         // total amount of LP being staked between all stakers
   uint public _rewardAmount;       // amount of reward when posted
   uint public _numBlocksLeft;      // amount of unrewarded blocks
   uint public _lockPercent;        // percent ofpayment held in locked liquidity
   uint public _unlockBlock;        // block number to unlock liquidity
   
   bool private _initialized;
   bool public _isActive;
  
   mapping(address => uint) public _stakeBalance;   // stake balances of stakers
   mapping(address => uint) public _rewardBalance;  // reward balances of stakers
   mapping(address => uint) public _enteredBlock;   // block at which this address entered. used to make sure nobody entered while going thrugh_Stakers list
  
   using EnumerableAddressSet for EnumerableAddressSet.AddressSet;
   EnumerableAddressSet.AddressSet _Stakers;

   function initialize(TokenSaleOrderLib.OrderVars calldata vars) external
   {
     require(!_initialized);
     _initialized = true;

     require(vars.rewardToken != address(0) && vars.LPToken != address(0));
      
     _rewardToken = IERC20(vars.rewardToken);
     _entranceFeeToken = IERC20(vars.entranceFeeToken);
     _LPToken = IERC20(vars.LPToken);
     _premiumToken = IERC20(vars.premiumToken);
     _premiumAmount = vars.premiumAmount;
     _uniRouter = IUniswapV2Router02(vars.uniRouter);      // this should already be vetted by factory
     _stakeFee = vars.stakeFee;
     _postedBy = vars.postedBy;
     _numBlocks = vars.numBlocks;
     _numBlocksLeft = vars.numBlocks;
     _entranceFee = vars.entranceFee;
     _Factory = TokenSaleOrderFactory(msg.sender);
     _devWallet = vars.devWallet;
 
     _lockPercent = vars.lockPercent;
     _unlockBlock = vars.unlockBlock;
     
     if(_entranceFee < 10000)
       _entranceFee = 10000;
     
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

   function _setUniRouter(address addr) internal
   {
     _uniRouter = IUniswapV2Router02(addr);
   }

   function setUniRouter(address addr) public
   {
     require(msg.sender == address(_Factory));
     _setUniRouter(addr);
   }

   function addLiquidity(uint amount) internal returns(uint)
   {
     uint ramount = _rewardToken.balanceOf(address(this));
     _entranceFeeToken.approve(address(_uniRouter), 0);
     _entranceFeeToken.approve(address(_uniRouter), amount);
     _rewardToken.approve(address(_uniRouter), 0);
     _rewardToken.approve(address(_uniRouter), ramount);
     // use exact amount of payment token amount and send as many rewardtokens as needed
     (,,uint liquidity) = _uniRouter.addLiquidity(address(_entranceFeeToken), address(_rewardToken), amount, ramount, amount, 1, address(this), block.timestamp);
     return(liquidity);
   }

   function uniswapPair(address tokenA, address tokenB) internal view returns(address)
   {
     (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
     IUniswapV2Factory uniFactory = IUniswapV2Factory(_uniRouter.factory());
  
     address paddress = uniFactory.getPair(token0,token1);
     require(paddress != address(0), "Liquidity pair does not exist"); // make sure pair exists
     return(paddress);
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

   // buyStake
   function buyStake(uint amount) public
   {
     require(_isActive);
     require(amount >= _entranceFee);
     
     // premium orders are required to be holding a minimum amount of premium token
     if(address(_premiumToken) != address(0) && _premiumAmount > 0)
       require(_premiumToken.balanceOf(msg.sender) >= _premiumAmount);

     if(updateBalances())
       return;
   
     uint fee = amount * _stakeFee / 10000; // 10 is .01%     
     uint payAmount = amount - fee;
     uint lockAmount = payAmount * _lockPercent / 10000;
     uint unlockAmount = payAmount - lockAmount;

   
     require(_entranceFeeToken.allowance(msg.sender, address(this)) >= amount);
     require(_entranceFeeToken.transferFrom(msg.sender, _devWallet, fee));     // send fee to dev wallet
     // send unlocked % to seller
     require(_entranceFeeToken.transferFrom(msg.sender, _postedBy, unlockAmount));
     // remaining stake is locked in contract
     require(_entranceFeeToken.transferFrom(msg.sender, address(this), lockAmount));

     _stakeBalance[msg.sender] = _stakeBalance[msg.sender] + payAmount; // add just in case they have already paid before
     _totalStake = _totalStake + payAmount;

     // create liquidity with % of staked amount
     uint lpamount = addLiquidity(lockAmount);
     require(lpamount > 0);
     
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

   // contract poster may withdraw liquidity after unlockBlock has been reached
   function withdraw(uint amount) public
   {
     if(msg.sender == _postedBy && block.number >= _unlockBlock)
       {
	 uint lpBalance = _LPToken.balanceOf(address(this));
	 
	 // only close order if all liquidity is removed
	 if(amount >= lpBalance)
	   {
	     iclose();
	     amount = lpBalance;
	   }
	 
	 require(_LPToken.transfer(msg.sender, amount));
       }
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
     
     // pay out all rewards to stakera
     for(uint i=0;i<_Stakers.length();i++)
	 if(_rewardBalance[_Stakers.at(i)] > 0)
	   _rewardToken.transfer(_Stakers.at(i), _rewardBalance[_Stakers.at(i)]);

     uint rewardAmount = _rewardToken.balanceOf(address(this));
   
     // send all unused reward tokens back to poster
     if(rewardAmount > 0)
       _rewardToken.transfer(_postedBy, rewardAmount);

     // emergency close order by admin. This is a safeguard against scam orders
     // note that it cannot refund all payment, only locked liquidity tokens
     // note that stakedex owners cannot close official stakedex tokensales (see TokenSaleOrderFactory.sol)
     if(msg.sender == address(_Factory))
       {
	 // refund all stakers their share of liquidity tokens
	 uint lpBalance = _LPToken.balanceOf(address(this));
	 for(uint i=0;i<_Stakers.length();i++)
	   {
	     address staker = _Stakers.at(i);
	     uint scale = 100000;
	     uint scaledbalance = (_stakeBalance[staker] * scale);
		      
	     if(scaledbalance > _totalStake) // avoid division error
	       {
		 uint amount = scaledbalance / _totalStake * lpBalance;
 
		 if(amount > scale)  // avoid division error
		   _LPToken.transfer(staker, amount / scale);
	       }
	   }
       }	 
   }
     
   function getContractBalances() public view returns(uint, uint, uint)
   {
     return(_entranceFeeToken.balanceOf(address(this)), _rewardToken.balanceOf(address(this)), _LPToken.balanceOf(address(this)));
   }
   
   function getStakers() public view returns(TokenSaleOrderLib.StakeOut[] memory)
   {
     uint len = _Stakers.length();
     TokenSaleOrderLib.StakeOut[] memory out = new TokenSaleOrderLib.StakeOut[](len);
    
     for(uint i=0;i<len;i++)
       {
	 out[i].staker = _Stakers.at(i);
	 out[i].stake =  _stakeBalance[_Stakers.at(i)];
       }
     return out;
   }

   function getInfo(address sender) public view returns(TokenSaleOrderLib.OrderInfo memory)
   {
     TokenSaleOrderLib.OrderInfo memory out;
     out.LPToken = address(_LPToken);          
     out.rewardToken = address(_rewardToken);
     out.entranceFeeToken = address(_entranceFeeToken);
     out.premiumToken =  address(_premiumToken);
     out.postedBy =  address(_postedBy);
     out.addr = address(this);
     
     out.premiumAmount =  _premiumAmount;
     out.entranceFee = _entranceFee;
     out.stakeFee =  _stakeFee;
     out.numBlocks = _numBlocks;
     out.rewardAmount = _rewardAmount;
     out.isActive = _isActive;

     out.lastBlockCalc = _lastBlockCalc;
     out.myStake = _stakeBalance[sender];
     out.myUnclaimed = _rewardBalance[sender];
     out.totalStake = _totalStake;
     out.numBlocksLeft = _numBlocksLeft;
     
     out.lockPercent = _lockPercent;
     out.unlockBlock = _unlockBlock;
     
     out.stakers = getStakers();
     return(out);
   }
  }

// SPDX-License-Identifier: UNLICENSED
// TokenSaleOrderLib by Stakedex.io 2021

pragma solidity 0.8.0;

library TokenSaleOrderLib
  {
   struct OrderVars
   {
     address LPToken;
     address rewardToken;
     address uniRouter;
     uint rewardAmount;
     address postedBy;
     uint numBlocks;
     uint stakeFee;
     uint entranceFee;
     address entranceFeeToken;
     address premiumToken;
     uint premiumAmount;
     address devWallet;
     bool featured;
     uint lockPercent;
     uint unlockBlock;
   }

   struct StakeOut
   {
     address staker;          // address of staker
     uint stake;              // amount of stake
   }

   struct OrderInfo
   {
     address LPToken;         // Liquidity token of reward/fee token
     address rewardToken;     // token being sold
     address entranceFeeToken;// token used for payment
     address premiumToken;    // token for premium membership
     address postedBy;        // user who posted the order
     address addr;            // address of token sale contract
     
     uint premiumAmount;      // min amount hodling premium token to stake
     uint entranceFee;        // amount charged for staking entrance fee
     uint stakeFee;           // fee in payment token % taken from stakers
     uint numBlocks;          // total number of blocks to reward
     uint minStake;           // minimum amount of stake
     uint rewardAmount;       // total amount of reward when posted
     bool isActive;           // order still active
     bool featured;           // featured listing

     uint lastBlockCalc;      // last balanaces update block
     uint myStake;            // senders stake amount
     uint myUnclaimed;        // senders unclaimed rewards     
     uint totalStake;         // total amount of token paid
     uint numBlocksLeft;      // blocks left in contract
     
     uint lockPercent;         // percent of entranceFee to be used in liquidity
     uint unlockBlock;         // block number at which to unlock liquidity
     
     StakeOut[] stakers;       // list of stakers { address, amount }
   }
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