// SPDX-License-Identifier: MIT
import "SafeMath.sol";
import "Context.sol";
import "Ownable.sol";
import "Exchanges.sol";
import "Registration.sol";

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
  Registration private registration;

  //----------------------------------------------------------
  uint public rewardPerBlock = 50000000000000000000;
  uint public maxBlocksInEra = 210000;
  uint public currentBlock = 0;
  uint public currentEra = 1;
  //----------------------------------------------------------

  constructor() {
    _name = "wmndnqoqwqrenf"; //TODO CHANGE !
    _symbol = "wmndnq"; //TODO CHANGE !
    _decimals = 18;
    _currentSupply = 0;
    exchanges = new Exchanges(address(this));
    registration = new Registration(address(this));
  }
  //----------------------------------------------------------

  //--------------Start Exhanges Calls--------------------------------------------
  function isExchangeVersionAllowed(uint exchangeVersion) external view returns(bool rt) {
    return exchanges.isExchangeVersionAllowed(exchangeVersion);
  }

  function getCurrentExchangeVersion() external view returns(uint rt) {
    return exchanges.getCurrentExchangeVersion();
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

  //--------------End Exhanges Calls----------------------------------------------
  //--------------Start Registration Calls--------------------------------------------

  function addTokenAddress(address tokenAddress) external returns(bool) {
    return registration.addTokenAddress(tokenAddress);
  }

  function getAddressId(address tokenAddress) external view returns(uint) {
    return registration.getAddressId(tokenAddress);
  }

  function getIdAddress(uint id) external view returns(address) {
    return registration.getIdAddress(id);
  }

  function getId() external view returns(uint) {
    return registration.getId();
  }

  function changeTokenName(address tokenAddress, string memory tokenName_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeTokenName(tokenAddress, tokenName_);
  }

  function changeTokenSymbol(address tokenAddress, string memory tokenSymbol_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeTokenSymbol(tokenAddress, tokenSymbol_);
  }

  function changeTokenLogo(address tokenAddress, string memory logoURL_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeTokenLogo(tokenAddress, logoURL_);
  }

  function changeTokenWeb(address tokenAddress, string memory webURL_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeTokenWeb(tokenAddress, webURL_);
  }

  function changeTokenSocial(address tokenAddress, string memory socialURL_) external returns(bool) {
    return registration.changeTokenSocial(tokenAddress, socialURL_);
  }

  function changeTokenWhitepaper(address tokenAddress, string memory whitePaperURL_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeTokenWhitepaper(tokenAddress, whitePaperURL_);
  }

  function changeTokenDescription(address tokenAddress, string memory description_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeTokenDescription(tokenAddress, description_);
  }

  function changeExtra1(address tokenAddress, string memory extra) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeExtra1(tokenAddress, extra);
  }

  function changeExtra2(address tokenAddress, string memory extra) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.changeExtra2(tokenAddress, extra);
  }

  function changeExtra3(address tokenAddress, string memory extra) external returns(bool) {
    return registration.changeExtra3(tokenAddress, extra);
  }

  function registerToken(address tokenAddress, string memory tokenName_, string memory tokenSymbol_, string memory logoURL_, string memory webURL_,
    string memory socialURL_, string memory whitePaperURL_, string memory description_) external returns(bool) {
    requireContractOwner(tokenAddress);
    return registration.registerToken(tokenAddress, tokenName_, tokenSymbol_, logoURL_, webURL_, socialURL_, whitePaperURL_, description_);
  }

  function getContractOwner(address tokenAddress) public view returns(address rt) {
    return registration.getContractOwner(tokenAddress);
  }

  function requireContractOwner(address tokenAddress) private view {
    require(msg.sender == getContractOwner(tokenAddress));
  }

  //--------------End Registration Calls--------------------------------------------

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

  function mintTo(address toAddress, uint amount) external onlyOwner returns(bool) {
    _mint(toAddress, amount);
    return true;
  }

  function burnFrom(address fromAddress, uint amount) external onlyOwner returns(bool) {
    _burn(fromAddress, amount);
    return true;
  }

  function setRewardPerBlock(uint rewardPerBlock_) onlyOwner external returns(bool rt) {
    rewardPerBlock = rewardPerBlock_;
    return true;
  }

  function setMaxBlocksInEra(uint maxBlocksInEra_) onlyOwner external returns(bool rt) {
    maxBlocksInEra = maxBlocksInEra_;
    return true;
  }

  function setCurrentBlock(uint currentBlock_) onlyOwner external returns(bool rt) {
    currentBlock = currentBlock_;
    return true;
  }

  function setCurrentEra(uint currentEra_) onlyOwner external returns(bool rt) {
    currentEra = currentEra_;
    return true;
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
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _currentSupply = _currentSupply.add(amount);

    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    _currentSupply = _currentSupply.sub(amount);

    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}