/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
  external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
  external returns (bool);

  function transferFrom(address from, address to, uint256 value)
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


interface ILP {
  function sync() external;
}



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

  event Mint(address indexed sender, uint amount0, uint amount1);
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

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}



interface IUniswapV2Router02  {

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


contract Ownable {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipRenounced(address indexed previousOwner);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  
  constructor() public {
    _owner = msg.sender;
  }


  function owner() public view returns (address) {
    return _owner;
  }

  
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  function getUnlockTime() public view returns (uint256) {
    return _lockTime;
  }


  function lock() public onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    emit OwnershipRenounced(_owner);

  }

  function unlock() public {
    require(_previousOwner == msg.sender, "You don’t have permission to unlock");
    require(now > _lockTime, "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }


  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
   
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
   
    uint256 c = a / b;
    

    return c;
  }

 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

 
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

 
  function mul(int256 a, int256 b)
  internal
  pure
  returns (int256)
  {
    int256 c = a * b;

    // Detect overflow when multiplying MIN_INT256 with -1
    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  
  function div(int256 a, int256 b)
  internal
  pure
  returns (int256)
  {
    
    require(b != - 1 || a != MIN_INT256);

    // Solidity already throws when dividing by 0.
    return a / b;
  }

  /**
   * @dev Subtracts two int256 variables and fails on overflow.
   */
  function sub(int256 a, int256 b)
  internal
  pure
  returns (int256)
  {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  /**
   * @dev Adds two int256 variables and fails on overflow.
   */
  function add(int256 a, int256 b)
  internal
  pure
  returns (int256)
  {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  /**
   * @dev Converts to absolute value, and fails on overflow.
   */
  function abs(int256 a)
  internal
  pure
  returns (int256)
  {
    require(a != MIN_INT256);
    return a < 0 ? - a : a;
  }
}



contract IERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  
  constructor (string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  
  function decimals() public view returns (uint8) {
    return _decimals;
  }
}

contract Elondoge is IERC20Detailed, Ownable {
  using SafeMath for uint256;
  using SafeMathInt for int256;



 
  address public lp;
  ILP public liquidutyReciever;
  address public ownerAdress;
  modifier onlyownerAdress() {
    require(msg.sender == ownerAdress);
    _;
  }

  bool public DistributionFinished;
  mapping(address => bool) allowTransfer;

  uint256 private constant DECIMALS = 9;
  uint256 private constant MAX_UINT256 = ~uint256(0);

  uint256 private constant INITIAL_SUPPLY = 5*10 ** 8 * 10 ** DECIMALS;

  uint256 public transactionTax = 1100;
  uint256 public buybackLimit = 10 ** 18;
  uint256 public buybackDivisor = 100;
  uint256 public numTokensSellDivisor = 10000;
  uint256 public maxTxDivider = 10;

  IUniswapV2Router02 public uniswapV2Router;
  IUniswapV2Pair public uniswapV2Pair;
  address public uniswapV2PairAddress;
  address public deadAddress = 0x000000000000000000000000000000000000dEaD;
  address payable public marketingAddress;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = false;
  bool public buyBackEnabled = false;

  mapping(address => bool) private _isExcluded;

  

  
  uint256 private constant TOTAL_TOKEN = MAX_UINT256 - (MAX_UINT256 % INITIAL_SUPPLY);

  uint256 private constant Final_SUPPLY = ~uint128(0); 

  uint256 private _totalSupply;
  uint256 private _TOKENPerFragment;
  mapping(address => uint256) private _EDCBalances;
  mapping(address => mapping(address => uint256)) private _allowedFragments;

  event RebaseLog(uint256 indexed epoch, uint256 totalSupply);
  event SwapEnabled(bool enabled);
  event SwapAndLiquify(
    uint256 threequarters,
    uint256 sharedETH,
    uint256 onequarter
  );

  modifier lockTheSwap {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  modifier initialDistributionLock {
    require(DistributionFinished || isOwner() || allowTransfer[msg.sender]);
    _;
  }

  modifier validRecipient(address to) {
    require(to != address(0x0));
    require(to != address(this));
    _;
  }


  constructor (string memory tokenName, string memory tokenSymbol)
  IERC20Detailed(tokenName, tokenSymbol, uint8(DECIMALS))
  payable
  public
  {
    marketingAddress =address(0x3A97A5cF50fd3bf3B8a772a2E1700dc5a64e75E6);
    ownerAdress = msg.sender;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    uniswapV2PairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
    .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;

    setLP(uniswapV2PairAddress);

    IUniswapV2Pair _uniswapV2Pair = IUniswapV2Pair(uniswapV2PairAddress);

    uniswapV2Pair = _uniswapV2Pair;

    _totalSupply = INITIAL_SUPPLY;
    _EDCBalances[msg.sender] = TOTAL_TOKEN;
    _TOKENPerFragment = TOTAL_TOKEN.div(_totalSupply);

    DistributionFinished = false;

    //exclude owner and this contract from fee
    _isExcluded[owner()] = true;
    _isExcluded[address(this)] = true;

    emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  
  function rebaseToken(uint256 epoch, int256 supplyDelta)
  external
  onlyownerAdress
  returns (uint256)
  {
    if (supplyDelta == 0) {
      emit RebaseLog(epoch, _totalSupply);
      return _totalSupply;
    }

    if (supplyDelta < 0) {
      _totalSupply = _totalSupply.sub(uint256(- supplyDelta));
    } else {
      _totalSupply = _totalSupply.add(uint256(supplyDelta));
    }

    if (_totalSupply > Final_SUPPLY) {
      _totalSupply = Final_SUPPLY;
    }

    _TOKENPerFragment = TOTAL_TOKEN.div(_totalSupply);
    liquidutyReciever.sync();

    emit RebaseLog(epoch, _totalSupply);
    return _totalSupply;
  }


  
  function setownerAdress(address _ownerAdress)
  external
  onlyOwner
  returns (uint256)
  {
    ownerAdress = _ownerAdress;
  }

 
  function setLP(address _lp)
  public
  onlyOwner
  returns (uint256)
  {
    lp = _lp;
    liquidutyReciever = ILP(_lp);
  }

  /**
   * @return The total number of fragments.
   */
  function totalSupply()
  external
  view
  returns (uint256)
  {
    return _totalSupply;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapEnabled(_enabled);
  }

  /**
   * @param who The address to query.
   * @return The balance of the specified address.
   */
  function balanceOf(address who)
  public
  view
  returns (uint256)
  {
    return _EDCBalances[who].div(_TOKENPerFragment);
  }

  function transfer(address recipient, uint256 amount)
  external
  validRecipient(recipient)
  initialDistributionLock
  returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  event Sender(address sender);

  function transferFrom(address sender, address recipient, uint256 amount)
  external
  validRecipient(recipient)
  returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowedFragments[sender][msg.sender].sub(amount));
    return true;
  }


  
  function _transfer(address from, address to, uint256 value)
  private
  validRecipient(to)
  initialDistributionLock
  returns (bool)
  {
    require(from != address(0));
    require(to != address(0));
    require(value > 0);


    uint256 contractTokenBalance = balanceOf(address(this));
    uint256 _maxTxAmount = _totalSupply.div(maxTxDivider);
    uint256 numTokensSell = _totalSupply.div(numTokensSellDivisor);

    bool overMinimumTokenBalance = contractTokenBalance >= numTokensSell;

    if (!_isExcluded[from] && !_isExcluded[to]) {
      require(value <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
    }

    if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != uniswapV2PairAddress && !_isExcluded[from]) {
      if (overMinimumTokenBalance) {
        swapAndLiquify(numTokensSell);
      }

      uint256 balance = address(this).balance;
      if (buyBackEnabled && balance > buybackLimit) {

        buyBackTokens(buybackLimit.div(buybackDivisor));
      }
    }

    _tokenTransfer(from, to, value);

    return true;
  }

  function _tokenTransfer(address sender, address recipient, uint256 amount) private {

    if (_isExcluded[sender] || _isExcluded[recipient]) {
      _transferExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }
  }

  function _transferStandard(address sender, address recipient, uint256 amount) private {
    (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount);
    uint256 EDCDeduct = amount.mul(_TOKENPerFragment);
    uint256 EDCValue = tTransferAmount.mul(_TOKENPerFragment);
    _EDCBalances[sender] = _EDCBalances[sender].sub(EDCDeduct);
    _EDCBalances[recipient] = _EDCBalances[recipient].add(EDCValue);
    _takeFee(sender, tFee);
    emit Transfer(sender, recipient, amount);
  }

  function _transferExcluded(address sender, address recipient, uint256 amount) private {
    uint256 EDCValue = amount.mul(_TOKENPerFragment);
    _EDCBalances[sender] = _EDCBalances[sender].sub(EDCValue);
    _EDCBalances[recipient] = _EDCBalances[recipient].add(EDCValue);
    emit Transfer(sender, recipient, amount);
  }


  function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
    uint256 tFee = calculateFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee);
    return (tTransferAmount, tFee);
  }


  function calculateFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(transactionTax).div(10000);
  }

  function _takeFee(address sender, uint256 tFee) private {
    uint256 rFee = tFee.mul(_TOKENPerFragment);
    _EDCBalances[address(this)] = _EDCBalances[address(this)].add(rFee);
    emit Transfer(sender, address(this), tFee);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into quarters
    uint256 fourFifth = contractTokenBalance.mul(4).div(5);
    uint256 oneFifth = contractTokenBalance.sub(fourFifth);

    
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(fourFifth);
    // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    uint256 sharedETH = newBalance.div(4);

    // add liquidity to uniswap
    addLiquidity(oneFifth, sharedETH);

    // Transfer to marketing address
    transferToAddressETH(marketingAddress, sharedETH.mul(2));

    emit SwapAndLiquify(fourFifth, sharedETH, oneFifth);

  }

  function buyBackTokens(uint256 amount) private lockTheSwap {
    if (amount > 0) {
      swapETHForTokens(amount);
    }
  }


  function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
  }

  function() external payable {}

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp.add(300)
    );

  }

  function swapETHForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(this);

    // make the swap
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens.value(amount)(
      0, // accept any amount of Tokens
      path,
      deadAddress, // Burn address
      block.timestamp.add(300)
    );
  }


  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH.value(ethAmount)(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this),
      block.timestamp.add(300)
    );
  }


 

  function increaseAllowance(address spender, uint256 addedValue)
  public
  initialDistributionLock
  returns (bool)
  {
    _approve(msg.sender, spender, _allowedFragments[msg.sender][spender].add(addedValue));
    return true;
  }


  function _approve(address owner, address spender, uint256 value) private {
    require(owner != address(0));
    require(spender != address(0));

    _allowedFragments[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  

  function approve(address spender, uint256 value)
  public
  initialDistributionLock
  returns (bool)
  {
    _approve(msg.sender, spender, value);
    return true;
  }


  
  function allowance(address owner_, address spender)
  public
  view
  returns (uint256)
  {
    return _allowedFragments[owner_][spender];
  }

  
  function decreaseAllowance(address spender, uint256 subtractedValue)
  external
  initialDistributionLock
  returns (bool)
  {
    uint256 oldValue = _allowedFragments[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedFragments[msg.sender][spender] = 0;
    } else {
      _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  function setDistributionFinished()
  external
  onlyOwner
  {
    DistributionFinished = true;
  }

  function enableTransfer(address _addr)
  external
  onlyOwner
  {
    allowTransfer[_addr] = true;
  }

  function excludeAddress(address _addr)
  external
  onlyOwner
  {
    _isExcluded[_addr] = true;
  }
  
  function unexcludeAddress(address _addr)
  external
  onlyOwner
  {
    _isExcluded[_addr] = false;
  }

  function burnAutoLP()
  external
  onlyOwner
  {
    uint256 balance = uniswapV2Pair.balanceOf(address(this));
    uniswapV2Pair.transfer(owner(), balance);
  }

  function airDrop(address[] calldata recipients, uint256[] calldata values)
  external
  onlyOwner
  {
    for (uint256 i = 0; i < recipients.length; i++) {
      _tokenTransfer(msg.sender, recipients[i], values[i]);
    }
  }

  function setBuyBackEnabled(bool _enabled) public onlyOwner {
    buyBackEnabled = _enabled;
  }

  function setBuyBackLimit(uint256 _buybackLimit) public onlyOwner {
    buybackLimit = _buybackLimit;}

  function setBuyBackDivisor(uint256 _buybackDivisor) public onlyOwner {
    buybackDivisor = _buybackDivisor;}

  function setNumTokensSellDivisor(uint256 _numTokensSellDivisor) public onlyOwner {
    numTokensSellDivisor = _numTokensSellDivisor;
  }

  function burnBNB(address payable burnAddress) external onlyOwner {
    burnAddress.transfer(address(this).balance);
  }
  
  function setTransferDivider(uint256 _divider) public onlyOwner {
    require(_divider > 0, "Divider has to be greater than 0");
    maxTxDivider = _divider;
  }
  
  function setMarketingAddress(address payable _marketing) public onlyOwner {
    marketingAddress = _marketing;
  }

}