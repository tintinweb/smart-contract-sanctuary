// SPDX-License-Identifier: MIT
import "SafeMath.sol";
import "Context.sol";
import "Ownable.sol";
import "Exchanges.sol";

pragma solidity ^ 0.7 .0;

interface IERC20 {
  function totalSupply() external view returns(uint256);

  function currentSupply() external view returns(uint256);

  function balanceOf(address account) external view returns(uint256);

  function transfer(address recipient, uint256 amount) external returns(bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

  function allowance(address owner, address spender) external view returns(uint256);

  function approve(address spender, uint256 amount) external returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function claimTokens() external returns(bool);
}

contract PION is Context, IERC20, Ownable {
  using SafeMath
  for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 public _totalSupply;
  uint256 public _currentSupply;

  string public _name;
  string public _symbol;
  uint8 public _decimals;
  Exchanges private exchanges;

  //----------------------------------------------------------
  uint public rewardPerBlock = 50000000000000000000;
  uint public maxBlocksInEra = 210000;
  uint public currentBlock = 0;
  uint public currentEra = 1;
  //----------------------------------------------------------

  constructor() {
    _name = "PION";
    _symbol = "PION";
    _decimals = 18;
    _currentSupply = 0;
    exchanges = new Exchanges(address(this));
  }
  //----------------------------------------------------------

  //--------------Start Exhanges Calls--------------------------------------------
  function isExchangeVersionAllowed(uint exchangeVersion) external view returns(bool rt) {
    return exchanges.isExchangeVersionAllowed(exchangeVersion);
  }

  function getCurrentExchangeVersion() external view returns(uint rt) {
    return exchanges.getCurrentExchangeVersion();
  }

  function getExchangeAddress(uint atExchangeVersion) public view returns(address rt) {
    return exchanges.getExchangeAddress(atExchangeVersion);
  }

  function setActiveIndexAddress(uint atExchangeVersion, address activeIndexAddress) external onlyOwner {
    exchanges.setActiveIndexAddress(atExchangeVersion, activeIndexAddress);
  }

  function depositTokenToExchange(address tokenAddress, address userAddress, uint amount) external returns(bool rt) {
    return exchanges.depositTokenToExchange(tokenAddress, userAddress, amount);
  }

  function sendTokenToUser(address tokenAddress, address userAddress, uint amount) external returns(bool rt) {
    return exchanges.sendTokenToUser(tokenAddress, userAddress, amount);
  }

  function buyPion(address forToken, address userAddress, uint priceIndex, uint amount, uint atExchangeVersion) external returns(bool rt) {
    return exchanges.buyPion(forToken, userAddress, priceIndex, amount, atExchangeVersion);
  }

  function sellPion(address forToken, address userAddress, uint priceIndex, uint amount, uint atExchangeVersion) external returns(bool rt) {
    return exchanges.sellPion(forToken, userAddress, priceIndex, amount, atExchangeVersion);
  }

  function cancelAllTradesAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) external returns(bool rt) {
    return exchanges.cancelAllTradesAtIndex(forToken, userAddress, priceIndex, atExchangeVersion);
  }

  function withdrawAllAtIndex(address forToken, address userAddress, uint priceIndex, uint atExchangeVersion) external returns(bool rt) {
    return exchanges.withdrawAllAtIndex(forToken, userAddress, priceIndex, atExchangeVersion);
  }

  function token2TokenSwap(address sellToken, address buyToken, address userAddress, uint atExchangeVersion, uint amount) external returns(bool rt) {
    return exchanges.token2TokenSwap(sellToken, buyToken, userAddress, atExchangeVersion, amount);
  }

  function getTokenPriceIndexes(uint atExchangeVersion, address userAddress, address tokenAddress, uint maxIndexes) external view returns(uint[] memory rt) {
    require(maxIndexes <= 2000);
    return exchanges.getTokenPriceIndexes(atExchangeVersion, userAddress, tokenAddress, maxIndexes);
  }

  function extraFunction(uint atExchangeVersion, address tokenAddress, address[] memory inAddress, uint[] memory inUint) external returns(bool rt) {
    return exchanges.extraFunction(atExchangeVersion, tokenAddress, inAddress, inUint);
  }
  
  function setNewExchange() external onlyOwner{
      exchanges.setNewExchange();
  }

  //--------------End Exhanges Calls----------------------------------------------


  function claimTokens() override external returns(bool) {
    claimTokensTo(msg.sender);
    return true;
  }

  function claimTokensTo(address toAddress) public returns(bool) {
    if (currentBlock >= maxBlocksInEra) {
      currentEra = currentEra.add(1);
      currentBlock = 0;
      rewardPerBlock = rewardPerBlock.div(2);
      maxBlocksInEra = maxBlocksInEra.add(maxBlocksInEra.div(2));
    } else {
      currentBlock = currentBlock.add(1);
    }
    _mint(toAddress, rewardPerBlock);

    return true;
  }
  //----------------------------------------------------------

  function mintTo(address toAddress, uint amount) external onlyOwner {
    _mint(toAddress, amount);
  }

  function burnFrom(address fromAddress, uint amount) external onlyOwner {
    _burn(fromAddress, amount);
  }

  function setRewardPerBlock(uint rewardPerBlock_) onlyOwner external{
    rewardPerBlock = rewardPerBlock_;
  }

  function setMaxBlocksInEra(uint maxBlocksInEra_) onlyOwner external {
    maxBlocksInEra = maxBlocksInEra_;
  }

  function setCurrentBlock(uint currentBlock_) onlyOwner external {
    currentBlock = currentBlock_;
  }

  function setCurrentEra(uint currentEra_) onlyOwner external {
    currentEra = currentEra_;
  }

  //----------------------------------------------------------

  function name() public view virtual returns(string memory) {
    return _name;
  }

  function symbol() public view virtual returns(string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns(uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual override returns(uint256) {
    return _totalSupply;
  }

  function currentSupply() public view virtual override returns(uint256) {
    return _currentSupply;
  }

  function balanceOf(address account) public view virtual override returns(uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns(uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns(bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns(bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0));
    require(recipient != address(0));

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0));

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _currentSupply = _currentSupply.add(amount);

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0));

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount);
    _totalSupply = _totalSupply.sub(amount);
    _currentSupply = _currentSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0));
    require(spender != address(0));

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}