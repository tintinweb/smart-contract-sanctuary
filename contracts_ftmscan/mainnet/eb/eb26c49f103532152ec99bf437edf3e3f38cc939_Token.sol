/**
 *Submitted for verification at FtmScan.com on 2021-12-26
*/

/**
 *Submitted for verification at FtmScan.com on 2021-12-26
*/

/**
 *Submitted for verification at FtmScan.com on 2021-12-26
*/

/**
 *Submitted for verification at FtmScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library IterableMapping {
  struct Map {
    address[] keys;
    mapping(address => uint) values;
    mapping(address => uint) indexOf;
    mapping(address => bool) inserted;
  }

  function get(Map storage map, address key) public view returns (uint) {
    return map.values[key];
  }

  function getIndexOfKey(Map storage map, address key) public view returns (int) {
    if(!map.inserted[key]) {
      return -1;
    }

    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
    return map.keys[index];
  }

  function size(Map storage map) public view returns (uint) {
    return map.keys.length;
  }

  function set(Map storage map, address key, uint val) public {
    if (map.inserted[key]) {
      map.values[key] = val;
    } else {
      map.inserted[key] = true;
      map.values[key] = val;
      map.indexOf[key] = map.keys.length;
      map.keys.push(key);
    }
  }

  function remove(Map storage map, address key) public {
    if (!map.inserted[key]) {
      return;
    }

    delete map.inserted[key];
    delete map.values[key];

    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];

    map.indexOf[lastKey] = index;
    delete map.indexOf[key];

    map.keys[index] = lastKey;
    map.keys.pop();
  }
}

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

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

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

interface IDividendToken {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;
  event TransactionGasLimitSet(uint256 indexed newGas, uint256 indexed oldGas);
  event DividendsDistributed(address indexed from, uint256 weiAmount);
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface IDividendTokenOptional {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
}

contract ERC20 is Context, IERC20, IERC20Metadata {

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  uint8 private constant tokenDecimals = 18;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = tokenDecimals;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return tokenDecimals;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply + amount;
    _balances[account] = _balances[account] + amount;
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account] - amount;
    _totalSupply = _totalSupply - amount;
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
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
}

contract DividendToken is ERC20, Ownable, IDividendToken, IDividendTokenOptional {

  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;
  uint256 public transactionGasLimit = 1e5; // Use by default 100,000 gas for transactions

  event DistributionMessageValue(uint256 amount);
  event TotalSupplyHeyo(uint256 amount);

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare + ((msg.value) * magnitude / totalSupply());

      emit DividendsDistributed(msg.sender, msg.value);
      totalDividendsDistributed = totalDividendsDistributed + msg.value;
    }
  }

  function setTransactionGasLimit(uint256 newGas) external onlyOwner {
    require(newGas != transactionGasLimit, "Token: The transaction gas is already set to this value.");
    emit TransactionGasLimitSet(newGas, transactionGasLimit);

    transactionGasLimit = newGas;
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 withdrawableDividend = withdrawableDividendOf(user);

    if (withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user] + withdrawableDividend;

      emit DividendWithdrawn(user, withdrawableDividend);
      (bool success,) = user.call{value: withdrawableDividend, gas: transactionGasLimit}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user] - withdrawableDividend;
        return 0;
      }

      return withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
  }

  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    int256 result = int256((magnifiedDividendPerShare * balanceOf(_owner))) + magnifiedDividendCorrections[_owner];
    require(result >= 0, "Cannot accumulate negative dividend amounts.");

    return uint256(result) / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = int256(magnifiedDividendPerShare * value);
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from] + _magCorrection;
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to] - _magCorrection;
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] - int256(magnifiedDividendPerShare * value);
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] + int256(magnifiedDividendPerShare * value);
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance - currentBalance;
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance - newBalance;
      _burn(account, burnAmount);
    }
  }

  receive() external payable {
    distributeDividends();
  }
}

contract RewardsTracker is DividendToken {
  using IterableMapping for IterableMapping.Map;

  IterableMapping.Map private tokenHoldersMap;

  string public constant tokenName = "Dark Doge Rewards Tracker";
  string public constant tokenSymbol = "DARK_REWARDS";

  uint256 public constant tokenDecimals = 1e18;

  uint256 public lastProcessedIndex;

  mapping (address => bool) public isExcludedFromRewards;
  mapping (address => uint256) public lastClaimTimes;

  uint256 public claimWait = 3600;
  uint256 public minimumTokenBalanceForRewards = 200000 * (tokenDecimals);

  event ExcludedFromRewards(address indexed account);
  event ClaimWaitSet(uint256 indexed newClaimWait, uint256 indexed oldClaimWait);
  event Claimed(address indexed account, uint256 amount, bool indexed automatic);

  constructor() DividendToken(tokenName, tokenSymbol) {}

  function _transfer(address, address, uint256) internal pure override {
    require(false, "RewardsTracker: No transfers allowed");
  }

  function withdrawDividend() public pure override {
    require(false, "RewardsTracker: withdrawDividend disabled. Use the 'processAccount' instead.");
  }

  function excludeFromRewards(address account) external onlyOwner {
    require(!isExcludedFromRewards[account], "RewardsTracker: This address is already excluded from rewards.");
    isExcludedFromRewards[account] = true;

    _setBalance(account, 0);
    tokenHoldersMap.remove(account);

    emit ExcludedFromRewards(account);
  }

  function setMinimumTokenBalanceForRewards(uint256 newAmount) external onlyOwner {
    uint256 desiredMinimumTokenBalanceForRewards = newAmount * (tokenDecimals);

    require(
      desiredMinimumTokenBalanceForRewards != minimumTokenBalanceForRewards,
      "RewardsTracker: The minimum token balance amount for rewards is already set to this amount."
    );

    require(
      desiredMinimumTokenBalanceForRewards > 0,
      "RewardsTracker: The minimum token balance amount for rewards must be greater than zero."
    );

    minimumTokenBalanceForRewards = desiredMinimumTokenBalanceForRewards;
  }

  function setClaimWait(uint256 newClaimWait) external onlyOwner {
    uint256 minClaimWait = 3600; // 1 Hour
    uint256 maxClaimWait = 86400; // 24 Hours

    require(newClaimWait != claimWait, "RewardsTracker: claimWait is already set to this value.");

    require(
      newClaimWait >= minClaimWait && newClaimWait <= maxClaimWait,
      "RewardsTracker: claimWait must be set to a value that is between 1 and 24 hours."
    );

    emit ClaimWaitSet(newClaimWait, claimWait);

    claimWait = newClaimWait;
  }

  function getLastProcessedIndex() external view returns(uint256) {
    return lastProcessedIndex;
  }

  function getTokenHolders() external view returns(uint256) {
    return tokenHoldersMap.keys.length;
  }

  function getAccount(address _account) public view
  returns (
    address account,
    int256 index,
    int256 iterationsUntilProcessed,
    uint256 withdrawableDividends,
    uint256 totalDividends,
    uint256 lastClaimTime,
    uint256 nextClaimTime,
    uint256 secondsUntilAutoClaimAvailable
  ) {
    account = _account;

    index = tokenHoldersMap.getIndexOfKey(account);

    iterationsUntilProcessed = -1;

    if(index >= 0) {
      if (uint256(index) > lastProcessedIndex) {
        iterationsUntilProcessed = index - int256(lastProcessedIndex);
      } else {
        uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length - lastProcessedIndex : 0;

        iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
      }
    }

    withdrawableDividends = withdrawableDividendOf(account);
    totalDividends = accumulativeDividendOf(account);
    lastClaimTime = lastClaimTimes[account];
    nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
    secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
  }

  function getAccountAtIndex(uint256 index) public view
  returns (
    address,
    int256,
    int256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256
  ) {
    if(index >= tokenHoldersMap.size()) {
      return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    }

    address account = tokenHoldersMap.getKeyAtIndex(index);

    return getAccount(account);
  }

  function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    if(lastClaimTime > block.timestamp)  {
      return false;
    }

    return block.timestamp - lastClaimTime >= claimWait;
  }

  function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    if(isExcludedFromRewards[account]) {
      return;
    }

    if(newBalance >= minimumTokenBalanceForRewards) {
      _setBalance(account, newBalance);
      tokenHoldersMap.set(account, newBalance);
    } else {
      _setBalance(account, 0);
      tokenHoldersMap.remove(account);
    }

    processAccount(account, true);
  }

  function process(uint256 gas) public returns (uint256, uint256, uint256) {
    uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    if(numberOfTokenHolders == 0) {
      return (0, 0, lastProcessedIndex);
    }

    uint256 _lastProcessedIndex = lastProcessedIndex;
    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();
    uint256 iterations = 0;
    uint256 claims = 0;

    while(gasUsed < gas && iterations < numberOfTokenHolders) {
      _lastProcessedIndex++;

      if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
        _lastProcessedIndex = 0;
      }

      address account = tokenHoldersMap.keys[_lastProcessedIndex];

      if(canAutoClaim(lastClaimTimes[account])) {
        if(processAccount(payable(account), true)) {
          claims++;
        }
      }

      iterations++;

      uint256 newGasLeft = gasleft();

      if(gasLeft > newGasLeft) {
        gasUsed = gasUsed + gasLeft - newGasLeft;
      }

      gasLeft = newGasLeft;
    }

    lastProcessedIndex = _lastProcessedIndex;

    return (iterations, claims, lastProcessedIndex);
  }

  function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
    uint256 amount = _withdrawDividendOfUser(account);

    if(amount > 0) {
      lastClaimTimes[account] = block.timestamp;

      emit Claimed(account, amount, automatic);

      return true;
    }

    return false;
  }
}

contract Token is ERC20, Ownable {

  RewardsTracker public tracker;

  IUniswapV2Router public uniswapV2Router;
  address public immutable uniswapV2Pair;

  string public constant tokenName = "Dark Doge";
  string public constant tokenSymbol = "DARK";

  uint256 public constant tokenSupply = 1e11; // 100 B supply
  uint256 public constant tokenDecimals = 1e18;

  address public constant zeroAddress = address(0x0000000000000000000000000000000000000000);
  address public constant deadAddress = address(0x000000000000000000000000000000000000dEaD);
  address public teamAddress = address(0x8462F4Cc23be77aB70732325f0B67e0A500294f1);
  address public marketingAddress = address(0x875479D786CEfe2Df3E1243b6E7a29ff99C526B3);
  address public burnAddress = address(0xD9CFF085Fdc9beF2ba83F12eC9a31f3e90d10E0C);
  address public growthAddress = address(0xAB884b629baD19148576d75F12faa2965001eB39);

  // Mainnet
  address public constant rewardToken = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

  // Testnet
  // address public constant rewardToken = address(0x157CDf8e4Eb06247bb64C01781A88Efd8C5b0c9B);

  // Mainnet
  address public constant routerAddress = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

  // Testnet
  // address public constant routerAddress = address(0xa5cb68702B9B77bdb665ee4818B2FF6cA4224f9a);

  uint256 public teamFee = 3;
  uint256 public marketingFee = 2;
  uint256 public rewardsFee = 5;
  uint256 public totalFees = teamFee + marketingFee + rewardsFee;

  uint256 public swapTokensAtAmount = 2000000 * (tokenDecimals);
  uint256 public processingGasLimit = 5e5; // Use by default 500,000 gas to process auto-claiming rewards
  uint256 public transactionGasLimit = 1e5; // Use by default 100,000 gas for transactions
  uint256 public amountAirdropped = 0; // Used to keep track of how much of supply has currently been airdropped

  bool private swapping;

  mapping (address => bool) private blacklisted;
  mapping (address => bool) private excludedFromFees;
  mapping (address => bool) public automatedMarketMakerPairs;

  event FeesSet(uint256 indexed teamFee, uint256 indexed marketingFee, uint256 indexed rewardsFee);
  event TrackerSet(address indexed newAddress, address indexed oldAddress);
  event TeamAddressSet(address indexed newAddress, address indexed oldAddress);
  event MarketingAddressSet(address indexed newAddress, address indexed oldAddress);
  event BurnAddressSet(address indexed newAddress, address indexed oldAddress);
  event GrowthAddressSet(address indexed newAddress, address indexed oldAddress);
  event UniswapV2RouterSet(address indexed newAddress, address indexed oldAddress);
  event FeesExclusionSet(address indexed account, bool isExcluded);
  event SwapTokensAtAmountSet(uint256 indexed swapTokensAtAmount);
  event AutomatedMarketMakerPairSet(address indexed pair, bool indexed value);
  event ProcessingGasLimitSet(uint256 indexed newGas, uint256 indexed oldGas);
  event TransactionGasLimitSet(uint256 indexed newGas, uint256 indexed oldGas);
  event RewardsSent(uint256 amount);

  event RewardsProcessed(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  constructor() ERC20(tokenName, tokenSymbol) {

    tracker = new RewardsTracker();

    IUniswapV2Router _uniswapV2Router = IUniswapV2Router(routerAddress);

    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    setFeesExclusion(zeroAddress, true);
    setFeesExclusion(deadAddress, true);
    setFeesExclusion(teamAddress, true);
    setFeesExclusion(marketingAddress, true);
    setFeesExclusion(burnAddress, true);
    setFeesExclusion(growthAddress, true);
    setFeesExclusion(address(this), true);
    setFeesExclusion(owner(), true);

    setupRewardsExclusions();

    /*
      _mint is an internal function in ERC20.sol that is only called here,
      and CANNOT be called ever again
    */
    _mint(owner(), tokenSupply * (tokenDecimals));
  }

  function airdrop(address account, uint256 amount) public onlyOwner {
    uint256 amountToAirdrop = amount * (tokenDecimals);

    require(amountToAirdrop > 0, "Token: The specified airdrop amount is invalid.");

    require(account != owner(), "Token: You cannot airdrop the Token contract owner.");
    require(account != address(0), "Token: You cannot airdrop the zero address.");
    require(account != address(this), "Token: You cannot airdrop the Token contract.");
    require(account != address(tracker), "Token: You cannot airdrop the Rewards Tracker.");
    require(account != address(uniswapV2Router), "Token: You cannot airdrop the router.");
    require(account != routerAddress, "Token: You cannot airdrop the router address.");
    require(account != marketingAddress, "Token: You cannot airdrop the marketing address.");
    require(account != rewardToken, "Token: You cannot airdrop the reward token address.");
    require(!blacklisted[account], 'Token: You cannot airdrop a token that is blacklisted.');

    transfer(account, amountToAirdrop);
    amountAirdropped += amountToAirdrop;

    // We don't need to keep track of the sender's rewards here because the sender is the owner since we can only airdrop from the owner's account. And since the owner's account doesn't receive any rewards, there's no need to keep track of their reward's balances.
    try tracker.setBalance(payable(account), balanceOf(account)) {} catch {}
  }

  function batchAirdrop(address[] memory recipients, uint256 amount) public onlyOwner {
    uint256 intendedAirdropAmount = amount * (tokenDecimals);

    require(intendedAirdropAmount > 0, "Token: The specified airdrop amount is invalid.");

    uint256 recipientAirdropAmount = amount / recipients.length;

    for(uint i = 0; i < recipients.length; i++) {
      airdrop(recipients[i], recipientAirdropAmount);
    }
  }

  function setupRewardsExclusions() private {
    tracker.excludeFromRewards(address(this));
    tracker.excludeFromRewards(address(tracker));
    tracker.excludeFromRewards(address(teamAddress));
    tracker.excludeFromRewards(address(marketingAddress));
    tracker.excludeFromRewards(address(burnAddress));
    tracker.excludeFromRewards(address(growthAddress));
    tracker.excludeFromRewards(address(uniswapV2Router));
    tracker.excludeFromRewards(owner());
    tracker.excludeFromRewards(zeroAddress);
    tracker.excludeFromRewards(deadAddress);
  }

  function setTracker(address account) public onlyOwner {
    require(address(tracker) != address(account), "Token: The tracker is already set to this address.");

    RewardsTracker newTracker = RewardsTracker(payable(account));

    require(newTracker.owner() == address(this), "Token: The new tracker must be owned by the Token contract.");

    emit TrackerSet(address(newTracker), address(tracker));

    tracker = newTracker;

    setupRewardsExclusions();
  }

  function setUniswapV2Router(address account) public onlyOwner {
    require(address(uniswapV2Router) != address(account), "Token: The router is already set to this address.");
    emit UniswapV2RouterSet(address(account), address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router(address(account));
  }

  function setFeesExclusion(address account, bool value) public onlyOwner {
    require(excludedFromFees[account] != value, "Token: This address is already excluded from fees.");
    excludedFromFees[account] = value;

    emit FeesExclusionSet(account, value);
  }

  function setRewardsExclusion(address account) public onlyOwner {
    tracker.excludeFromRewards(account);
  }

  function setTeamAddress(address payable newAddress) external onlyOwner {
    require(address(teamAddress) != address(newAddress), "Token: The team address is already set to this address.");

    setFeesExclusion(newAddress, true);
    tracker.excludeFromRewards(newAddress);

    emit TeamAddressSet(newAddress, teamAddress);

    teamAddress = newAddress;
  }

  function setMarketingAddress(address payable newAddress) external onlyOwner {
    require(address(marketingAddress) != address(newAddress), "Token: The marketing address is already set to this address.");

    setFeesExclusion(newAddress, true);
    tracker.excludeFromRewards(newAddress);

    emit MarketingAddressSet(newAddress, marketingAddress);

    marketingAddress = newAddress;
  }

  function setBurnAddress(address payable newAddress) external onlyOwner {
    require(address(burnAddress) != address(newAddress), "Token: The burn address is already set to this address.");

    setFeesExclusion(newAddress, true);
    tracker.excludeFromRewards(newAddress);

    emit BurnAddressSet(newAddress, burnAddress);

    burnAddress = newAddress;
  }

  function setGrowthAddress(address payable newAddress) external onlyOwner {
    require(address(growthAddress) != address(newAddress), "Token: The growth address is already set to this address.");

    setFeesExclusion(newAddress, true);
    tracker.excludeFromRewards(newAddress);

    emit GrowthAddressSet(newAddress, growthAddress);

    growthAddress = newAddress;
  }

  function setFees(uint256 newTeamFee, uint256 newMarketingFee, uint256 newRewardsFee) external onlyOwner {
    require(newTeamFee >= 0 && newTeamFee <= 10, "Requested team fee not within acceptable range");
    require(newMarketingFee >= 0 && newMarketingFee <= 10, "Requested marketing fee not within acceptable range");
    require(newRewardsFee >= 0 && newRewardsFee <= 10, "Requested rewards fee not within acceptable range");

    teamFee = newTeamFee;
    marketingFee = newMarketingFee;
    rewardsFee = newRewardsFee;

    totalFees = teamFee + marketingFee + rewardsFee;

    emit FeesSet(teamFee, marketingFee, rewardsFee);
  }

  function setSwapTokensAtAmount(uint256 newSwapTokensAtAmount) public onlyOwner{
    uint256 desiredSwapTokensAtAmount = newSwapTokensAtAmount * (tokenDecimals);
    uint256 minSwapTokensAtAmount = 100000 * (tokenDecimals); // 10,000

    require(desiredSwapTokensAtAmount >= minSwapTokensAtAmount, "Requested contract swap amount out of acceptable range.");

    swapTokensAtAmount = desiredSwapTokensAtAmount;

    emit SwapTokensAtAmountSet(desiredSwapTokensAtAmount);
  }

  function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
    require(automatedMarketMakerPairs[pair] != value, "Token: The Automated Market Maker pair is already set to this address.");

    automatedMarketMakerPairs[pair] = value;

    if(value) {
      tracker.excludeFromRewards(pair);
    }

    emit AutomatedMarketMakerPairSet(pair, value);
  }

  function setProcessingGasLimit(uint256 newGas) public onlyOwner {
    require(newGas != processingGasLimit, "Token: The processing gas is already set to this value.");
    emit ProcessingGasLimitSet(newGas, processingGasLimit);

    processingGasLimit = newGas;
  }

  function setTransactionGasLimit(uint256 newGas) public onlyOwner {
    require(newGas != transactionGasLimit, "Token: The transaction gas is already set to this value.");
    emit TransactionGasLimitSet(newGas, transactionGasLimit);

    transactionGasLimit = newGas;
  }

  function blacklistAddress(address account, bool value) external onlyOwner {
    require(blacklisted[account] != value, "Token: This address is already blacklisted.");
    blacklisted[account] = value;
  }

  function isExcludedFromFees(address account) public view returns(bool) {
    return excludedFromFees[account];
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), "ERC20: You cannot transfer from the zero address.");
    require(to != address(0), "ERC20: You cannot transfer to the zero address.");
    require(!blacklisted[from] && !blacklisted[to], 'Token: This address is blacklisted.');

    if(amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    bool takeFee = !swapping;

    if(excludedFromFees[from] || excludedFromFees[to]) {
      takeFee = false;
    }

    if(takeFee) {
      uint256 fees = amount * totalFees / 100;

      amount = amount - fees;

      super._transfer(from, address(this), fees);
    }

    if (shouldSwap(from, to)) {
      swapping = true;
      swapTokens();
      swapping = false;
    }

    super._transfer(from, to, amount);

    try tracker.setBalance(payable(from), balanceOf(from)) {} catch {}
    try tracker.setBalance(payable(to), balanceOf(to)) {} catch {}

    if(!swapping) {
      try tracker.process(processingGasLimit) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
        emit RewardsProcessed(iterations, claims, lastProcessedIndex, true, processingGasLimit, tx.origin);
      } catch {}
    }
  }

  function shouldSwap(address from, address to) private view returns (bool) {
    bool isNotDeadAddress = (to != deadAddress && to != zeroAddress);

    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    return isNotDeadAddress && canSwap && !swapping && !automatedMarketMakerPairs[from];
  }

  function swapTokens() private {
    // capture the contract's current ETH balance, so that we can capture exactly the amount of ETH that the swap creates, and not make the swap event include any ETH that has been manually sent to the contract.
    uint256 initialBalance = address(this).balance;
    swapTokensFor(swapTokensAtAmount);
    uint256 newBalance = address(this).balance - initialBalance;

    uint256 rewardsForTeam = newBalance * teamFee / totalFees;
    (bool tempOne,) = payable(teamAddress).call{value: rewardsForTeam, gas: transactionGasLimit}("");
    tempOne; // warning-suppression

    uint256 rewardsForMarketing = newBalance * marketingFee / totalFees;
    (bool tempTwo,) = payable(marketingAddress).call{value: rewardsForMarketing, gas: transactionGasLimit}("");
    tempTwo; // warning-suppression

    uint256 rewardsForHolders = address(this).balance;
    (bool success,) = payable(tracker).call{value: rewardsForHolders, gas: transactionGasLimit}("");

    if (success) {
      emit RewardsSent(rewardsForHolders);
    }
  }

  function swapTokensFor(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }

  function setClaimWait(uint256 claimWait) external onlyOwner {
    tracker.setClaimWait(claimWait);
  }

  function setMinimumTokenBalanceForRewards(uint256 newAmount) external onlyOwner {
    tracker.setMinimumTokenBalanceForRewards(newAmount);
  }

  function setRewardsTransactionGasLimit(uint256 newGas) external onlyOwner {
    tracker.setTransactionGasLimit(newGas);
  }

  function getClaimWait() external view returns(uint256) {
    return tracker.claimWait();
  }

  function getMinimumTokenBalanceForRewards() external view returns(uint256) {
    return tracker.minimumTokenBalanceForRewards();
  }

  function getRewardsTransactionGasLimit() external view returns(uint256) {
    return tracker.transactionGasLimit();
  }

  function getTotalRewardsDistributed() external view returns (uint256) {
    return tracker.totalDividendsDistributed();
  }

  function getWithdrawableRewardsOf(address account) public view returns(uint256) {
    return tracker.withdrawableDividendOf(account);
  }

  function getRewardsBalanceOf(address account) public view returns (uint256) {
    return tracker.balanceOf(account);
  }

  function getRewardsInfo(address account) external view
  returns (
    address,
    int256,
    int256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256
  ) {
    return tracker.getAccount(account);
  }

  function getRewardsInfoAtIndex(uint256 index) external view
  returns (
    address,
    int256,
    int256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256
  ) {
    return tracker.getAccountAtIndex(index);
  }

  function getLastProcessedIndex() external view returns(uint256) {
    return tracker.getLastProcessedIndex();
  }

  function getRewardsHolders() external view returns(uint256) {
    return tracker.getTokenHolders();
  }

  function processRewardsTracker(uint256 gas) external {
    (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = tracker.process(gas);
    emit RewardsProcessed(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
  }

  function claimRewards() external {
    tracker.processAccount(payable(msg.sender), false);
  }

  receive() external payable {}
}