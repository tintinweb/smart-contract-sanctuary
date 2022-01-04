/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: Unlicensed


contract Context {
  constructor () { }
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }
  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function isContractAddress(address addr) internal view returns(bool) {
    return addr.code.length != 0;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  modifier onlyContract() {
    require(_msgSender() == address(this), "Contract: caller is not the contract");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
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

contract BEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _lastClaimDate; 
  mapping (address => uint256) private _lastSaleDate;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromInterest;
  mapping (address => bool) private _isExcludedFromTax;
  mapping (address => uint256) private _accruedInterest;

  uint private _minutesBeforeInterest =  1;     //28 * 24 * 60;   // Representing as minutes to make testing easier.
  uint256 private _maximumAccruedInterestDays = 366;
  uint256 private _interestRate = 12;
  uint256 private _contractDeploymentDate;
  uint256 private _yearInMinutes = 366 * 24 * 60;
  uint256 private _balanceBeforeSwap = 1000000 * _decimalPointsCalc;
  
  address payable private _burnAddress = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
  address payable private _taxStorageDestination;
  address payable private _testPancakeswapContract;
  address payable private _productionPancakeswapContract;
  address payable private _pancakeswapRouterContract;

  uint8 private _devPercentage = 1;
  uint8 private _liquidityPercentage = 1; 
  uint8 private _burnPercentage = 1;
  uint256 private _totalSupply;
  uint8 private constant _decimals = 18;
  string private constant _symbol = "TSWIFTY16";
  string private _name = _symbol;
  uint256 private constant _billion = 1000000000;
  uint256 private _decimalPointsCalc = 10 ** uint256(_decimals);
  
  address TestnetRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

  IUniswapV2Router02 private _pancakeswapV2Router; // The address of the PancakeSwap V2 Router
  address private _pancakeswapV2LiquidityPair;

  bool currentlySwapping;

  event Claim(address indexed claimAddress, uint256 interestClaimed);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);

  constructor() {

    _totalSupply = 10 * _billion * _decimalPointsCalc;
    _balances[msg.sender] = _totalSupply;
    
    _isExcludedFromInterest[owner()] = true;
    _isExcludedFromTax[owner()] = true;
    _isExcludedFromTax[address(this)] = true;
    _isExcludedFromTax[address(0x0000000000000000000000000000000000000000)] = true;

    _taxStorageDestination = payable(this);
    _testPancakeswapContract = payable(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    _productionPancakeswapContract = payable(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    _pancakeswapRouterContract = _testPancakeswapContract;  // Change this before production deployment

    setRouterAddress(_pancakeswapRouterContract);

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  receive() external payable {}

  function setRouterAddress(address router) public onlyOwner() {
      // Connect to the new router
      IUniswapV2Router02 newPancakeSwapRouter = IUniswapV2Router02(router);
      
      // Grab an existing pair, or create one if it doesnt exist
      address newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).getPair(address(this), newPancakeSwapRouter.WETH());
      if(newPair == address(0)){
          newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).createPair(address(this), newPancakeSwapRouter.WETH());
      }
      _pancakeswapV2LiquidityPair = newPair;

      _pancakeswapV2Router = newPancakeSwapRouter;
  }

  function swapAndWithdrawBnb(address receiverOfBnb, uint256 tokenAmount) external onlyOwner returns (bool) {

      currentlySwapping = true;
      address[] memory tradingPair = new address[](2);
      tradingPair[0] = address(this); // this contracts tokens
      tradingPair[1] = address(_pancakeswapV2Router.WETH());

      _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

      _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0,
          tradingPair,
          receiverOfBnb,
          block.timestamp.add(300));

      currentlySwapping = false;

      return true;
  }

  function getTaxStorageDestination() external view returns (address payable) {
      return payable(_taxStorageDestination);
  }

  function getOwner() override external view returns (address) {
    return owner();
  }

  function decimals() override external pure returns (uint8) {
    return _decimals;
  }

  function symbol() override external pure returns (string memory) {
    return _symbol;
  }

  function name() override external view returns (string memory) {
    return _name;
  }

  function totalSupply() override external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) override external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) override external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function setDevTaxAddress(address payable taxStorageDestination) external onlyOwner returns(bool) {
    _taxStorageDestination = taxStorageDestination;
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function mint(uint256 amount) private onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    uint256 transferAmount = amount;
    uint256 taxAmount;

    if(!currentlySwapping)
    {
      accrueInterest(sender);
      accrueInterest(recipient);

      if(_isExcludedFromTax[sender] || sender == _taxStorageDestination || recipient == _taxStorageDestination)
      {
        taxAmount = 0;
      }
      else
      {
        taxAmount = handleTaxes(sender, amount);
      }

      transferAmount = amount.sub(taxAmount);
    }

    _balances[recipient] = _balances[recipient].add(transferAmount);
    emit Transfer(sender, recipient, transferAmount);
  }

  function caimInterest() public returns(uint256) {
  
    require(!isContractAddress(msg.sender), "BEP20: contracts cannot earn interest.");
    require(msg.sender != address(0), "BEP20: zero address not allowed");
    
    accrueInterest(msg.sender);

    uint256 addressesInterest = _accruedInterest[msg.sender];

    if(addressesInterest != 0)
    {
      _balances[msg.sender] += addressesInterest;
      _totalSupply += addressesInterest;

      _mint(msg.sender, addressesInterest); // mint the interest earned

      emit Claim(msg.sender, addressesInterest);
    }

    _lastClaimDate[msg.sender] = block.timestamp;

    require(addressesInterest > 0, "BEP20: no interest available to claim."); 

    return addressesInterest;
  }

  function accrueInterest(address addr) private {

    require(addr != address(0), "BEP20: zero address not allowed");

    if(_isExcludedFromInterest[addr])
      return;

    if(_lastClaimDate[addr] == 0)
    {
      _lastClaimDate[addr] = block.timestamp;
      return; // This will only happen for the 1st transaction on an address. 
    }

    uint validMinutes = (block.timestamp - _lastClaimDate[addr]) / 60;  // The number of minutes that they are elegible for interest.

    if(validMinutes > _maximumAccruedInterestDays * 24 * 60)
    {
      validMinutes = _maximumAccruedInterestDays * 24 * 60;
    }

    uint256 accruedInterest;

    // calculates the interest due prorated over the number of minutes that the balance has been valid for.

    if(validMinutes >= _minutesBeforeInterest)
    {
      accruedInterest = (_balances[addr].mul(_interestRate).div(_yearInMinutes) / 100).mul(validMinutes);
      _accruedInterest[addr] = accruedInterest;
      _lastClaimDate[addr] = block.timestamp;
    }
  }

  function getInterestDue(address addr) public view returns(uint256) {

    if(_isExcludedFromInterest[addr])
      return 0;   // I dont allow contracts to earn interest. This includes the liquidity contracts and any tokens held by this contract.

    if(_lastClaimDate[addr] == 0)
      return 0; // This will only happen for addresses that have never received tokens so no interest can be earned. 

    uint validMinutes = (block.timestamp - _lastClaimDate[addr]) / 60;  // The number of minutes that they are elegible for interest.

    if(validMinutes > _maximumAccruedInterestDays * 24 * 60)
    {
      validMinutes = _maximumAccruedInterestDays * 24 * 60;
    }

    // calculates the interest due prorated over the number of minutes that the balance has been valid for.

    if(validMinutes >= _minutesBeforeInterest)
      return (_balances[addr].mul(_interestRate).div(_yearInMinutes) / 100).mul(validMinutes) + _accruedInterest[addr];
    else
      return 0;
  }

  function handleTaxes(address sender, uint256 totalRequestedSpendAmount) private returns (uint256) {

    uint256 devTaxTotal = totalRequestedSpendAmount.div(100).mul(_devPercentage + _liquidityPercentage);
    uint256 burnTaxTotal = totalRequestedSpendAmount.div(100).mul(_burnPercentage);
    
    _balances[_burnAddress] = _balances[_burnAddress].add(burnTaxTotal);
    emit Transfer(sender, _burnAddress, burnTaxTotal);

    _balances[_taxStorageDestination] += devTaxTotal;
    emit Transfer(sender, _taxStorageDestination, devTaxTotal);

    return devTaxTotal + burnTaxTotal;
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }


}   // end of contract


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
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    // Solidity only automatically asserts when dividing by 0
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

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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

// IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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

// IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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
        address[] calldata tradingPair,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata tradingPair,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata tradingPair, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata tradingPair, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata tradingPair, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata tradingPair, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata tradingPair) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata tradingPair) external view returns (uint[] memory amounts);
}

// IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol 
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
        address[] calldata tradingPair,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata tradingPair,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata tradingPair,
        address to,
        uint deadline
    ) external;
}