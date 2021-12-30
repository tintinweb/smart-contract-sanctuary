/**
 *Submitted for verification at BscScan.com on 2021-12-29
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
    return addr.code.length == 0;
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

contract StorageContract {
  using SafeMath for uint256;

  mapping (address => uint256) public _lastClaimDate;  // maps address to the last date address sold.

  function getLastClaimDate(address addr) public view returns(uint256) {

    return _lastClaimDate[addr];
  }

  function setLastClaimDate(address addr) external returns(bool) {

    _lastClaimDate[addr] = block.timestamp;

    return true;
  }
}


contract BEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  StorageContract DataStorage = new StorageContract();

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromInterest;
  mapping (address => bool) private _isExcludedFromTax;

  uint private _minutesBeforeInterest =  1;     //28 * 24 * 60;   // Representing as minutes to make testing easier.
  uint256 private _maximumAccruedInterestDays = 366;
  uint256 private _interestRate = 12;
  uint256 private _contractDeploymentDate;
  uint256 private _yearInMinutes = 366 * 24 * 60;

  address payable private _burnAddress = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
  address payable private _taxStorageDestination;
  address payable private _testPancakeswapContract;
  address payable private _productionPancakeswapContract;
  address private _pancakeswapRouterContract;

  uint8 private _devPercentage = 1;
  uint8 private _liquidityPercentage = 1; 
  uint8 private _burnPercentage = 1;
  uint256 private _totalSupply;
  uint8 private constant _decimals = 18;
  string private constant _symbol = "TSWIFTY";
  string private _name = "TswiftyTest004";
  uint256 private constant _billion = 1000000000;
  uint256 private _decimalPointsCalc = 10 ** uint256(_decimals);
  
  address TestnetRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
  address TestWBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
  IDEXRouter public router;
  address pair;

  bool currentlySwapping;

  modifier lockSwapping {
      currentlySwapping = true;
      _;
      currentlySwapping = false;
  }

  event Claim(address indexed claimAddress, uint256 interestClaimed);

  constructor() {

    router = IDEXRouter(TestnetRouter);
    IDEXFactory factory = IDEXFactory(router.factory());
    pair = factory.createPair(address(this), TestWBNB);

    _allowances[address(this)][address(router)] = ~uint256(0);

    _totalSupply = 10 * _billion * _decimalPointsCalc;
    _balances[msg.sender] = _totalSupply;

    _isExcludedFromInterest[owner()] = true;
    _isExcludedFromTax[owner()] = true;
    _isExcludedFromTax[address(this)] = true;
    _isExcludedFromTax[address(0x0000000000000000000000000000000000000000)] = true;

    _taxStorageDestination = payable(owner());
    _testPancakeswapContract = payable(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    _productionPancakeswapContract = payable(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    _pancakeswapRouterContract = _testPancakeswapContract;  // Change this before production deployment

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  receive() external payable {}

  function swapTokensForBNB(uint256 tokenAmount) private lockSwapping {
      // Generate the Pancakeswap pair for DHT/WBNB
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = router.WETH(); // WETH = WBNB on BSC

      _approve(address(this), address(router), tokenAmount);

      // Execute the swap
      router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // Accept any amount of BNB
          path,
          address(this),
          block.timestamp.add(300)
      );
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

  function setDevTaxAddress(address payable taxStorageDestination) public onlyOwner returns(bool) {
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

    claimInterestInternal(sender);
    claimInterestInternal(recipient);

    uint256 taxAmount = handleTaxes(sender, amount);

    uint256 transferAmount = amount.sub(taxAmount);
    _balances[recipient] = _balances[recipient].add(transferAmount);
    
    emit Transfer(sender, recipient, transferAmount);
  }

  function caimInterest() public {
  
    require(!isContractAddress(msg.sender), "BEP20: contracts cannot earn interest.");

    uint256 claimedInterest = claimInterestInternal(msg.sender);

    require(claimedInterest > 0, "BEP20: no interest available to claim."); 
  }

  function claimInterestInternal(address addr) private returns (uint256) {

    require(addr != address(0), "BEP20: zero address not allowed");
    
    if(isContractAddress(addr))
      return 0;   // Contract holders cannot earn interest

    uint256 addressesInterest = interestDue(addr);

    if(addressesInterest != 0)
    {
      _balances[addr] += addressesInterest;
      _totalSupply += addressesInterest;

      _mint(addr, addressesInterest); // mint the interest earned

      emit Claim(addr, addressesInterest);
    }

    DataStorage.setLastClaimDate(addr);

    return addressesInterest;
  }

  function interestDuePublic(address addr) public view returns(uint256) {

    return interestDue(addr);
  }

  function interestDue(address addr) internal view returns(uint256) {

    if(_isExcludedFromInterest[addr])
      return 0;

    uint256 setLastClaimDate = DataStorage.getLastClaimDate(addr);

    if(setLastClaimDate == 0)
      return 0; // This will only happen for the 1st transaction on an address. 

    uint validMinutes = (block.timestamp - setLastClaimDate) / 60;  // The number of minutes that they are elegible for interest.

    if(validMinutes > _maximumAccruedInterestDays * 24 * 60)
    {
      validMinutes = _maximumAccruedInterestDays * 24 * 60;
    }

    return calculatePotentialInterestEarned(validMinutes, _balances[addr]);
  }

  function calculatePotentialInterestEarned(uint256 validMinutes, uint256 balance) internal view returns(uint256) {

    // calculates the interest due prorated over the number of minutes that the balance has been valid for.

    if(validMinutes >= _minutesBeforeInterest)
      return (balance.mul(_interestRate).div(_yearInMinutes) / 100).mul(validMinutes);
    else
      return 0;
  }

  function handleTaxes(address sender, uint256 totalRequestedSpendAmount) private returns (uint256) {

    if(_isExcludedFromTax[sender])
    {
      return 0;
    }

    uint256 devTaxTotal = handleDevTax(sender, totalRequestedSpendAmount);
    uint256 liquidityTaxTotal = handleLiquidityTax(sender, totalRequestedSpendAmount);
    uint256 burnTaxTotal = handleBurnTax(sender, totalRequestedSpendAmount);
 
    return devTaxTotal + liquidityTaxTotal + burnTaxTotal;
  }

  function handleDevTax(address sender, uint totalRequestedSpendAmount) private returns (uint256) {

    uint256 taxAmount = 0;

    if(_taxStorageDestination != address(0))
    {
        taxAmount = totalRequestedSpendAmount.div(100).mul(_devPercentage);
        _balances[_taxStorageDestination] += taxAmount;
        emit Transfer(sender, _taxStorageDestination, taxAmount);
    }

    return taxAmount;
  }

  function handleLiquidityTax(address sender, uint totalRequestedSpendAmount) private returns (uint256) {

    uint256 taxAmount = 0;

    if(_taxStorageDestination != address(0))
    {
        taxAmount = totalRequestedSpendAmount.div(100).mul(_liquidityPercentage);
        _balances[_taxStorageDestination] += taxAmount;
        emit Transfer(sender, _taxStorageDestination, taxAmount);   // need to interact with the pancakeswap router

        if(!currentlySwapping)
          swapTokensForBNB(taxAmount);
    }

    return taxAmount;
  }

  function handleBurnTax(address sender, uint totalRequestedSpendAmount) private returns (uint256) {

    uint256 taxAmount = 0;

    taxAmount = totalRequestedSpendAmount.div(100).mul(_burnPercentage);
    _balances[_burnAddress] += taxAmount;
    emit Transfer(sender, _burnAddress, taxAmount);   // need to interact with the pancakeswap router

    return taxAmount;

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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