/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

/**
 *Submitted for verification at BscScan.com on whenever we felt like it.
*/

/*
THIS IS JUST A TEST           THIS IS JUST A TEST           THIS IS JUST A TEST
                                                                               
                                ,,,,,,,,,                                      
                               //   ' ' \\                                     
                               || __  __-|                                     
                               ( (__''__))                                     
                                \   __  /                                      
                                 |  __ /                                       
                        _____ ___/'\__/|____ _____                             
                       /    //  \ \____/    \\    \                            
                      /____/(    \ \_        )\____\                           
                      /___/\\\    \//___    ///___/                            
                      |     \_____ ('   '--__/    |                            
                  |\   \_  -------\/==\-   -----  |   /|                       
                  | \    \__________==/ `'-______/   / |                       
                   \ \     ___/   ._||_.   \___     / /                        
                    \ '-__/ /       ||       \ \__-' /                         
                     '-__/  |\_     ||     _/|  \__-'                          
                |\       '\  \O\    ||    /O/  /'       /|                     
                \ ''--____/     _   ||   _     \____--'' /                     
                 '''--___|_    |n\  ||  /n|    _|___--'''                      
                          /\        ||        /\                               
                         / /'\  \---||---/  /'\ \                              
                        ( (    \  Wv\/vW  /    ) )                             
                         \\     \        /     //                              
                          \|    |        |    |/                               
                                 \ |MM| /                                      
                      _ _   _     '-__-'          _____      _                 
      /\/\   __ _  __| | |_| | ___  _   _ ___  __/__   \___ | | _____ _ __     
     /    \ / _` |/ _` | '_  |/ _ \| | | / __|/ _ \/ /\/ _ \| |/ / _ \ '_ \    
    / /\/\ \ (_| | (_| | | | | (_) | |_| \__ \  __/ / | (_) |   <  __/ | | \   
    \/    \/\__,_|\__,_|_| |_|\___/ \__,_|___/\___\/   \___/|_|\_\___|_| |_|   

Contract by Madhouse Team - optimized based on others previous work  
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }
  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode
    // see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

interface IERC20 {
  function totalSupply()
    external view returns (uint256);
  function balanceOf(address account)
    external view returns (uint256);
  function transfer(address recipient, uint256 amount)
    external returns (bool);
  function allowance(address owner, address spender)
    external view returns (uint256);
  function approve(address spender, uint256 amount)
    external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

  function sub(uint256 a, uint256 b, string memory errorMessage)
  internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiply overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage)
  internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage)
  internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Address {

  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created
    // accounts and
    // 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
    // is returned for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash =
      0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Addr: insufficient balance");
    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Addr: sendValue fail, reverted?");
  }

  function functionCall(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return functionCall(target, data, "Addr: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value,
      "Addr: low-lvl with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value,
      "Addr: insuf balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  )private returns (bytes memory) {
    require(isContract(target), "Addr: call to non-contract");
    (bool success, bytes memory returndata) =
      target.call{ value: weiValue }(data);
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner,
  address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0),
    "Ownable: new owner is zero addr");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  function getTime() public view returns (uint256) {
    return block.timestamp;
  }

  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  function unlock() public virtual {
    require(_previousOwner == msg.sender,
    "Permission to unlock denied.");
    require(block.timestamp > _lockTime ,
    "Cannot unlock contract yet.");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }

}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint
  );

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function getPair(address tokenA, address tokenB)
    external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB)
    external returns (address pair);

  function setFeeTo(address) external;
  function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender)
    external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value)
    external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  event Burn(
    address indexed sender,
    uint amount0,
    uint amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
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
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
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
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

contract MadhouseTestTokens is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

/*   address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD; */
  mapping (address => uint256) private _rOwned;
  mapping (address => mapping (address => uint256)) private _allowances;

  string private _name = "Madhouse Test Tokens";
  string private _symbol = "MMHT";
  uint8 private _decimals = 9;
  uint256 private _tTotal = 1e18; //1,000,000,000.000000000

  uint256 public _buyTaxFee = 3*10**(_decimals-2); //  3%
  uint256 public _buyLppFee = 1*10**(_decimals-2); //  1%

  uint256 public _sellTaxFee = 20*10**(_decimals-2); // 20%
  uint256 public _sellLppFee = 5*10**(_decimals-2); //  5%

  uint256 private constant MAX = ~uint256(0);
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;
  
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  event Burn(address indexed burner, uint256 amount);

  constructor () {

    _rOwned[_msgSender()] = _rTotal; //All tokens initially go to creator

    // Pancake Router Testnet v1
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02
      (0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
/*
    // Pancake Router v2 - Not present on Testnet
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02
      (0x10ED43C718714eb63d5aA57B78B54704E256024E);
*/
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;

    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    require(_rOwned[account]<=_rTotal,"Amount over total reflections");
    //return _rOwned[account].div( _rTotal.div(_tTotal) );
    // Since x/(y/z)=z(x/y) to avoid rounding errors if tTotal gets small
    return _tTotal.mul( _rOwned[account]).div( _rTotal ) ;
  }

  function ratioBalanceOf(address account) public view returns (uint256) {
    require(_rOwned[account]<=_rTotal,"Amount over total reflections");
    //return _rOwned[account].div( _rTotal.div(_tTotal) );
    // Since x/(y/z)=z(x/y) to avoid rounding errors if tTotal gets small
    return _rOwned[account] ;
  }

  function ratioDenominator() public view returns (uint256) {
    return _rTotal ;
  }

  function transfer(address recipient, uint256 amount)
  public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
  public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
  public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount)
  public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "Transfer exceeds allowance")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
  public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
  public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "Decreased allowance below zero"
      )
    );
    return true;
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function deliver(uint256 tAmount) external {
    address sender = _msgSender();
    uint256 rAmount = tAmount.mul(_rTotal.div(_tTotal));
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "ERC20: approve from zero addr");
    require(spender != address(0), "ERC20: approve to zero addr");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != to, "Transfer to/from same addr");
    require(from != address(0), "ERC20: transfer from zero addr");
    require(to != address(0), "ERC20: transfer to zero addr");
    require(amount > 0, "Transfer amount less than zero");

    uint256 rAmount = amount.mul(_rTotal.div(_tTotal));
    if(from != uniswapV2Pair && to != uniswapV2Pair){
      // Since this is not a Buy and Not a Sell , it is a direct transfer
      _rOwned[from] = _rOwned[from].sub(rAmount);
      _rOwned[to] = _rOwned[to].add(rAmount);
      emit Transfer(from, to, amount);
      //The direct transfer is complete, we don't need to calculate fee values.
      //Skip the motions of taking zero tax and adding zero liquidity.
      return;
    }
    //Buys and Sells may incur tax, so prepare token transfer values
    uint256 tFee;
    uint256 tLpp;
    uint256 currentRate = _rTotal.div(_tTotal);
    if(from == uniswapV2Pair){ // Buy
      tFee = amount.mul(_buyTaxFee).div(10**_decimals);
      tLpp = amount.mul(_buyLppFee).div(10**_decimals);
    } else { // Sell (would have already returned, if not direct and not a buy)
      tFee = amount.mul(_sellTaxFee).div(10**_decimals);
      tLpp = amount.mul(_sellLppFee).div(10**_decimals);
    }
    uint256 tTransferAmount = amount.sub(tFee).sub(tLpp);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLpp = tLpp.mul(currentRate);

    _rOwned[from] = _rOwned[from].sub(rAmount);
    _rOwned[to] = _rOwned[to].add(rAmount.sub(rFee).sub(rLpp));
/*
     //_takeLiquidity(tLiquidity):
    //Collect the liquidity tax tokens to the contract address
    // to be sold at a loss to the project then re-inserted to LP
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
*/
    //Deflationary LPP:
    //As long as lppFee<taxFee evaporation combined with reflections
    // below should not result in a net loss to address balances
    // TODO: VERIFY THIS MATH A COUPLE MORE WAYS
    _tTotal = _tTotal.sub(tLpp);

    //_reflectFee(rFee, tFee):
    // Reduce the denominator rTotal in tTotal(rOwned/rTotal) to distribute tax
    // as reflections proportionally to all accounts.
    _rTotal = _rTotal.sub(rFee); 
    _tFeeTotal = _tFeeTotal.add(tFee);

    emit Transfer(from, to, tTransferAmount);

  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // Approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // Add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // Slippage is unavoidable
      0, // Slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  function burn(uint256 tokenAmount) external {
    require(tokenAmount<=_tTotal, "Burn amount exceeds supply.");
    _burn(msg.sender, tokenAmount);
  }

  function _burn(address burner, uint256 amount) internal {
    uint256 rBurn = amount.mul(_rTotal.div(_tTotal));
    require(rBurn <= _rOwned[burner],
      "Balance less than burn amount.");
    _rOwned[burner] = _rOwned[burner].sub(rBurn);
    _tTotal = _tTotal.sub(amount);
    emit Burn(burner, amount);
    emit Transfer(burner, address(0), amount);
  }

  function setBuyLppFee(uint256 lppFee) external onlyOwner {
    // Liquidity protection exceeding reflection would cause held balances loss
    require( lppFee <= _buyTaxFee,
      "LP protection exceeds reflection tax." );
    _buyLppFee = lppFee;
  }

  function setBuyReflectFee(uint256 taxFee) external onlyOwner {
    // Liquidity protection exceeding reflection would cause held balances loss
    require( _buyLppFee <= taxFee,
      "LP protection exceeds reflection tax." );
    require( taxFee < 50*10**(_decimals-2),
      "Reflection tax cannot exceed 50%." );
    _buyTaxFee = taxFee;
  }

  function setSellLppFee(uint256 lppFee) external onlyOwner {
    // Liquidity protection exceeding reflection would cause held balances loss
    require( lppFee <= _sellTaxFee,
      "LP protection exceeds reflection tax." );
    _sellLppFee = lppFee;
  }

  function setSellReflectFee(uint256 taxFee) external onlyOwner {
    // Liquidity protection exceeding reflection would cause held balances loss
    require( _sellLppFee <= taxFee,
      "LP protection exceeds reflection tax." );
    require( taxFee < 50*10**(_decimals-2),
      "Reflection tax cannot exceed 50%." );
    _sellTaxFee = taxFee;
  }



  function transferToAddressETH(address payable recipient, uint256 amount)
  private {
    recipient.transfer(amount);
  }

  function changeRouterVersion(address _router)
  public onlyOwner returns(address _pair) {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

    _pair = IUniswapV2Factory(
      _uniswapV2Router.factory()).getPair(address(this),
      _uniswapV2Router.WETH());
    if(_pair == address(0)){
      // Pair doesn't exist
      _pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());
    }
    uniswapV2Pair = _pair;

    // Set the router of the contract variables
    uniswapV2Router = _uniswapV2Router;
  }

   // To recieve ETH from uniswapV2Router when swapping
  receive() external payable {}

  function transferForeignToken(address _token, address _to)
  public onlyOwner returns(bool _sent){
    require(_token != address(this), "Native token transfer denied");
    uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
    _sent = IERC20(_token).transfer(_to, _contractBalance);
  }

}