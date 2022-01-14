// SPDX-License-Identifier: MIT License
// BUSD Reward ~ https://t.me/shibaprincessv2official
// Fair Launch 01/14/2022 15:00 CST

import "./SIPTokenDividendTracker.sol";
import "./DividendPayingToken.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapRouter.sol";
import "./IUniswapV2Factory.sol";
import "./ERC20.sol";

pragma solidity ^0.8.6;

contract SIP is ERC20, Ownable {
  using SafeMath for uint256;
  // Events Declarations

  event EnableTrading(uint256 indexed blockNumber);

  event UpdateDividendTracker(
    address indexed newAddress,
    address indexed oldAddress
  );
  event UpdateUniswapV2Router(
    address indexed newAddress,
    address indexed oldAddress
  );
  event UpdateMarketingWallet(
    address indexed newWallet,
    address indexed oldWallet
  );
  event UpdateBuybackWallet(
    address indexed newWallet,
    address indexed oldWallet
  );
  event UpdatePresaleWallet(
    address indexed newWallet,
    address indexed oldWallet
  );
  event UpdateGasForProcessing(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );

  event UpdateMarketingFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateBuybackFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateLiquidityFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateRewardsFee(uint256 indexed newValue, uint256 indexed oldValue);
  event UpdateSellFee(uint256 indexed newValue, uint256 indexed oldValue);

  event UpdateMaxBuyTransactionAmount(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );
  event UpdateMaxSellTransactionAmount(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );
  event UpdateSwapTokensAtAmount(
    uint256 indexed newValue,
    uint256 indexed oldValue
  );
  event UpdateSwapAndLiquify(bool enabled);

  event WhitelistAccount(address indexed account, bool isWhitelisted);
  event ExcludeFromFees(address indexed account, bool isExcluded);
  event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  event SendDividends(uint256 tokensSwapped, uint256 amount);
  event SendRaffle(uint256 tokensSwapped, uint256 amount);

  event ProcessedDividendTracker(
    uint256 iterations,
    uint256 claims,
    uint256 lastProcessedIndex,
    bool indexed automatic,
    uint256 gas,
    address indexed processor
  );

  event TransferETHToMarketingWallet(address indexed wallet, uint256 amount);
  event TransferETHToDevWallet(address indexed wallet, uint256 amount);
  event TransferTokensToMarketingWallet(address indexed wallet, uint256 amount);
  event TransferTokensToDevWallet(address indexed wallet, uint256 amount);
  event TransferETHToBuybackWallet(address indexed wallet, uint256 amount);
  event TransferTokensToBuybackWallet(address indexed wallet, uint256 amount);
  event ExcludeAccountFromDividends(address indexed account);
  event ExcludeFromMaxWallet(address indexed account, bool isExcluded);

  //
  IUniswapV2Router02 public uniswapV2Router;
  address public immutable uniswapV2Pair;

  bool private swapping;
  bool public swapAndLiquifyEnabled = true;

  SIPTokenDividendTracker public dividendTracker;

  uint256 public immutable MIN_BUY_TRANSACTION_AMOUNT = 0 * (10**18); // 0 of supply
  uint256 public immutable MAX_BUY_TRANSACTION_AMOUNT = 2000000 * (10**18); // 2% of supply
  uint256 public immutable MIN_SELL_TRANSACTION_AMOUNT = 0 * (10**18); // 0 of total supply
  uint256 public immutable MAX_SELL_TRANSACTION_AMOUNT =
    2000000 * (10**18); // 2% of total supply
  uint256 public immutable MIN_SWAP_TOKENS_AT_AMOUNT = 200 * (10**18);
  uint256 public immutable MAX_SWAP_TOKENS_AT_AMOUNT = 2000000 * (10**18); // 2% of total supply

  uint256 public maxBuyTransactionAmount = 2000000 * (10**18); // 2% of supply
  uint256 public maxSellTransactionAmount = 2000000 * (10**18); // 2% of supply
  uint256 public swapTokensAtAmount = 2000000 * (10**18); // 2% of supply
  uint256 public maxWallet = 2000000 * (10**18); // 2% of supply

  uint256 public immutable MAX_MARKETING_FEE = 15;
  uint256 public immutable MAX_DEV_FEE = 15;
  uint256 public immutable MAX_BUYBACK_FEE = 15;
  uint256 public immutable MAX_REWARDS_FEE = 15;
  uint256 public immutable MAX_LIQUIDITY_FEE = 5;
  uint256 public immutable MAX_TOTAL_FEES = 20;
  uint256 public immutable MAX_SELL_FEE = 30;

  uint256 public marketingFee = 90; // for trapping
  uint256 public devFee = 10;
  uint256 public buyBackFee = 0;
  uint256 public rewardsFee = 0;
  uint256 public liquidityFee = 0;
  uint256 public sellFee = 0; // fees are increased for sells

  // it can only be enabled, not disabled. Used so that contract can be deployed / liq added
  // without bots interfering.
  // SIPGuard is active on default
  // bool internal SIPGuardOffline = true;

  address payable public marketingWallet =
    payable(0xA1Ed6Ad3B452d964Df1ae6C711efAab9802c8336);
  address payable public devWallet =
    payable(0x4eC8Aa7f7A7a37C958aAaDD0cB940d95de0Df563);
  address payable public buyBackWallet =
    payable(0xA1Ed6Ad3B452d964Df1ae6C711efAab9802c8336);

  // BUSD Token
  address public rewardToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // mainnet BUSD

  // use by default 300,000 gas to process auto-claiming dividends
  uint256 public gasForProcessing = 300000;

  // Absolute max gas amount for processing dividends
  uint256 public immutable MAX_GAS_FOR_PROCESSING = 5000000;

  // exclude from fees
  mapping(address => bool) private _isExcludedFromFees;

  // exclude from max wallet
  mapping(address => bool) private _isExcludedFromMaxWallet;

  // Can add LP before trading is enabled
  mapping(address => bool) public isWhitelisted;

  uint256 public totalFeesCollected;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public automatedMarketMakerPairs;

  constructor() ERC20("SIPv2", "ShibaInuPrincessv2") {
    dividendTracker = new SIPTokenDividendTracker();
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x10ED43C718714eb63d5aA57B78B54704E256024E // mainnet
      //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 // testnet
    );

    // Create a uniswap pair for this new token
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    // exclude from receiving dividends. We purposely don't exclude
    // the marketing wallet from dividends since we're going to use
    // those dividends for things like giveaways and marketing. These
    // dividends are more useful than tokens in some cases since selling
    // them doesnt impact token price.
    dividendTracker.excludeFromDividends(address(dividendTracker));
    dividendTracker.excludeFromDividends(address(this));
    dividendTracker.excludeFromDividends(address(_uniswapV2Router));
    dividendTracker.excludeFromDividends(address(0xdEaD));
    dividendTracker.excludeFromDividends(address(0));
    dividendTracker.excludeFromDividends(owner());

    // exclude from paying fees or having max transaction amount
    excludeFromFees(address(this), true);
    excludeFromFees(marketingWallet, true);
    excludeFromFees(devWallet, true);
    excludeFromFees(owner(), true);
    excludeFromFees(address(0xdEaD), true);
    excludeFromFees(address(0), true);

    //exclude from max wallet
    excludeFromMaxWallet(address(dividendTracker), true);
    excludeFromMaxWallet(address(this), true);
    excludeFromMaxWallet(marketingWallet, true);
    excludeFromMaxWallet(devWallet, true);
    excludeFromMaxWallet(owner(), true);
    excludeFromMaxWallet(address(0xdEaD), true);
    excludeFromMaxWallet(address(0), true);
    excludeFromMaxWallet(address(uniswapV2Router), true);

    // Whitelist accounts so they can transfer tokens before trading is enabled
    whitelistAccount(address(this), true);
    whitelistAccount(owner(), true);
    whitelistAccount(devWallet, true);
    whitelistAccount(address(uniswapV2Router), true);

    /*
    _mint is an internal function in ERC20.sol that is only called here,
    and CANNOT be called ever again
    */
    _mint(owner(), 100000000 * (10**18)); // 100,000,000
  }

  receive() external payable {}

  function updateSwapAndLiquify(bool enabled) external onlyOwner {
    swapAndLiquifyEnabled = enabled;
    emit UpdateSwapAndLiquify(enabled);
  }

  // function is SIPGuardEnabled() public view returns (bool) {
  //   return SIPGuardOffline;
  // }

  function whitelistAccount(address account, bool whitelisted)
    public
    onlyOwner
  {
    isWhitelisted[account] = whitelisted;
  }

  function registerAsTeam(address account) external onlyOwner {
    excludeFromFees(account, true);
    excludeFromMaxWallet(account, true);
    whitelistAccount(account, true);
  }

  function isWhitelistedAccount(address account) public view returns (bool) {
    return isWhitelisted[account];
  }

  // function shutdownSIPGuard() external onlyOwner {
  //   require(!SIPGuardOffline, "SIP guard is already offline");
  //   SIPGuardOffline = true;
  // }

  function getTotalFees() public view returns (uint256) {
    return
      marketingFee.add(liquidityFee).add(rewardsFee).add(devFee).add(
        buyBackFee
      );
  }

  function updateMarketingWallet(address payable newAddress)
    external
    onlyOwner
  {
    require(marketingWallet != newAddress, "new address required");
    address oldWallet = marketingWallet;
    marketingWallet = newAddress;
    excludeFromFees(newAddress, true);
    emit UpdateMarketingWallet(marketingWallet, oldWallet);
  }

  function updateDividendTracker(address newAddress) public onlyOwner {
    require(
      newAddress != address(dividendTracker),
      "RewardToken: The dividend tracker already has that address"
    );

    SIPTokenDividendTracker newDividendTracker = SIPTokenDividendTracker(
      payable(newAddress)
    );

    require(
      newDividendTracker.owner() == address(this),
      "RewardToken: The new dividend tracker must be owned by the Dividend token contract"
    );

    newDividendTracker.excludeFromDividends(address(newDividendTracker));
    newDividendTracker.excludeFromDividends(address(this));
    newDividendTracker.excludeFromDividends(address(uniswapV2Router));
    newDividendTracker.excludeFromDividends(address(0xdEaD));
    newDividendTracker.excludeFromDividends(address(0));
    newDividendTracker.excludeFromDividends(owner());

    emit UpdateDividendTracker(newAddress, address(dividendTracker));

    dividendTracker = newDividendTracker;
  }

  function updateUniswapV2Router(address newAddress) public onlyOwner {
    require(
      newAddress != address(uniswapV2Router),
      "RewardToken: The router already has that address"
    );
    emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
    uniswapV2Router = IUniswapV2Router02(newAddress);
  }

  function excludeAccountFromDividends(address account) public onlyOwner {
    dividendTracker.excludeFromDividends(account);
    emit ExcludeAccountFromDividends(account);
  }

  function isExcludedFromDividends(address account) public view returns (bool) {
    return dividendTracker.isExcludedFromDividends(account);
  }

  function excludeFromMaxWallet(address account, bool excluded)
    public
    onlyOwner
  {
    _isExcludedFromMaxWallet[account] = excluded;
  }

  function updateMaxWallet(uint256 newValue) external onlyOwner {
    maxWallet = newValue * (10**18);
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
  }

  function excludeMultipleAccountsFromFees(
    address[] calldata accounts,
    bool excluded
  ) public onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) {
      _isExcludedFromFees[accounts[i]] = excluded;
    }

    emit ExcludeMultipleAccountsFromFees(accounts, excluded);
  }

  function setAutomatedMarketMakerPair(address pair, bool value)
    public
    onlyOwner
  {
    require(
      pair != uniswapV2Pair,
      "RewardToken: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
    );

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(
      automatedMarketMakerPairs[pair] != value,
      "RewardToken: Automated market maker pair is already set to that value"
    );
    automatedMarketMakerPairs[pair] = value;

    if (value) {
      dividendTracker.excludeFromDividends(pair);
    }

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function _validateFees() private view {
    require(getTotalFees() <= MAX_TOTAL_FEES, "total fees too high");
  }

  function launch() external onlyOwner {
    marketingFee = 9; // normalize the marketing fee
    maxBuyTransactionAmount = 2000000 * (10**18); // 2 of supply
    maxSellTransactionAmount = 2000000 * (10**18); // 2% of supply
    maxWallet = 2000000 * (10**18); // 3% of supply
  }

  function noLimit() external onlyOwner {
    maxBuyTransactionAmount = 2000000 * (10**18);
    maxSellTransactionAmount = 2000000 * (10**18);
    maxWallet = 2000000 * (10**18);
  }

  function updateMarketingFee(uint256 newFee) external onlyOwner {
    require(marketingFee != newFee, "new fee required");
    uint256 oldFee = marketingFee;
    marketingFee = newFee;
    _validateFees();
    emit UpdateMarketingFee(newFee, oldFee);
  }

  function updateBuybackFee(uint256 newFee) external onlyOwner {
    require(buyBackFee != newFee, "new fee required");
    require(newFee <= MAX_BUYBACK_FEE, "new fee too high");
    buyBackFee = newFee;
    _validateFees();
  }

  function updateLiquidityFee(uint256 newFee) external onlyOwner {
    require(liquidityFee != newFee, "new fee required");
    require(newFee <= MAX_LIQUIDITY_FEE, "new fee too high");
    uint256 oldFee = liquidityFee;
    liquidityFee = newFee;
    _validateFees();
    emit UpdateLiquidityFee(newFee, oldFee);
  }

  function updateRewardsFee(uint256 newFee) external onlyOwner {
    require(rewardsFee != newFee, "new fee required");
    require(newFee <= MAX_REWARDS_FEE, "new fee too high");
    uint256 oldFee = rewardsFee;
    rewardsFee = newFee;
    _validateFees();
    emit UpdateRewardsFee(newFee, oldFee);
  }

  function updateSellFee(uint256 newFee) external onlyOwner {
    require(sellFee != newFee, "new fee required");
    require(newFee <= MAX_SELL_FEE, "new fee too high");
    uint256 oldFee = sellFee;
    sellFee = newFee;
    emit UpdateSellFee(newFee, oldFee);
  }

  function updateMaxBuyTransactionAmount(uint256 newValue) external onlyOwner {
    require(maxBuyTransactionAmount != newValue, "new value required");
    require(
      newValue >= MIN_BUY_TRANSACTION_AMOUNT &&
        newValue <= MAX_BUY_TRANSACTION_AMOUNT,
      "new value must be >= MIN_BUY_TRANSACTION_AMOUNT and <= MAX_BUY_TRANSACTION_AMOUNT"
    );
    uint256 oldValue = maxBuyTransactionAmount;
    maxBuyTransactionAmount = newValue;
    emit UpdateMaxBuyTransactionAmount(newValue, oldValue);
  }

  function updateMaxSellTransactionAmount(uint256 newValue) external onlyOwner {
    require(maxSellTransactionAmount != newValue, "new value required");
    require(
      newValue >= MIN_SELL_TRANSACTION_AMOUNT &&
        newValue <= MAX_SELL_TRANSACTION_AMOUNT,
      "new value must be >= MIN_SELL_TRANSACTION_AMOUNT and <= MAX_SELL_TRANSACTION_AMOUNT"
    );
    uint256 oldValue = maxSellTransactionAmount;
    maxSellTransactionAmount = newValue;
    emit UpdateMaxSellTransactionAmount(newValue, oldValue);
  }

  function updateSwapTokensAtAmount(uint256 newValue) external onlyOwner {
    require(swapTokensAtAmount != newValue, "new value required");
    require(
      newValue >= MIN_SWAP_TOKENS_AT_AMOUNT &&
        newValue <= MAX_SWAP_TOKENS_AT_AMOUNT,
      "new value must be >= MIN_SWAP_TOKENS_AT_AMOUNT and <= MAX_SWAP_TOKENS_AT_AMOUNT"
    );
    uint256 oldValue = swapTokensAtAmount;
    swapTokensAtAmount = newValue;
    emit UpdateSwapTokensAtAmount(newValue, oldValue);
  }

  function updateGasForProcessing(uint256 newValue) public onlyOwner {
    require(
      newValue >= 200000 && newValue <= MAX_GAS_FOR_PROCESSING,
      "RewardToken: gasForProcessing must be between 200,000 and MAX_GAS_FOR_PROCESSING"
    );
    require(
      newValue != gasForProcessing,
      "RewardToken: Cannot update gasForProcessing to same value"
    );
    emit UpdateGasForProcessing(newValue, gasForProcessing);
    gasForProcessing = newValue;
  }

  function updateClaimWait(uint256 claimWait) external onlyOwner {
    dividendTracker.updateClaimWait(claimWait);
  }

  function getClaimWait() external view returns (uint256) {
    return dividendTracker.claimWait();
  }

  function getTotalDividendsDistributed() external view returns (uint256) {
    return dividendTracker.totalDividendsDistributed();
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function processDividendTracker(uint256 gas) external onlyOwner {
    (
      uint256 iterations,
      uint256 claims,
      uint256 lastProcessedIndex
    ) = dividendTracker.process(gas);
    emit ProcessedDividendTracker(
      iterations,
      claims,
      lastProcessedIndex,
      false,
      gas,
      tx.origin
    );
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    // max wallet
    if (
      to != uniswapV2Pair &&
      to != address(0xdead) &&
      (!_isExcludedFromMaxWallet[to] || !_isExcludedFromMaxWallet[from])
    ) {
      require(
        super.balanceOf(to) + amount <= maxWallet,
        "Transfer amount exceeds wallet"
      );
    }

    // Prohibit buys/sells before trading is enabled. This is useful for fair launches for obvious reasons
    // if (from == uniswapV2Pair) {
    //   require(
    //     SIPGuardOffline || isWhitelisted[to],
    //     "trading isnt enabled or account isnt whitelisted"
    //   );
    // } else if (to == uniswapV2Pair) {
    //   require(
    //     SIPGuardOffline || isWhitelisted[from],
    //     "trading isnt enabled or account isnt whitelisted"
    //   );
    // }

    // Enforce max buy
    if (
      automatedMarketMakerPairs[from] &&
      // No max buy when removing liq
      to != address(uniswapV2Router)
    ) {
      require(
        amount <= maxBuyTransactionAmount,
        "Transfer amount exceeds the maxTxAmount."
      );
    }

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    // Enforce max sell
    if (
      !swapping && automatedMarketMakerPairs[to] // sells only by detecting transfer to automated market maker pair
    ) {
      require(
        amount <= maxSellTransactionAmount,
        "Sell transfer amount exceeds the maxSellTransactionAmount."
      );
    }

    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = (contractTokenBalance >= swapTokensAtAmount) &&
      swapAndLiquifyEnabled;
    uint256 totalFees = getTotalFees();

    // Swap and liq for sells
    if (canSwap && !swapping && automatedMarketMakerPairs[to]) {
      swapping = true;
      uint256 liquidityAndTeamTokens = contractTokenBalance
        .mul(liquidityFee.add(marketingFee).add(devFee).add(buyBackFee))
        .div(totalFees);
      swapAndLiquifyAndFundTeam(liquidityAndTeamTokens);
      uint256 rewardTokens = balanceOf(address(this));
      swapAndSendDividends(rewardTokens);

      swapping = false;
    }

    // Only take taxes for buys/sells (and obviously dont take taxes during swap and liquify)
    bool takeFee = !swapping &&
      (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    if (takeFee) {
      uint256 fees = amount.mul(totalFees).div(100);

      // If sell, add extra fee
      if (automatedMarketMakerPairs[to]) {
        fees += amount.mul(sellFee).div(100);
      }

      totalFeesCollected += fees;

      amount = amount.sub(fees);

      super._transfer(from, address(this), fees);
    }

    super._transfer(from, to, amount);

    // Trigger dividends to be paid out
    try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
    try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

    if (!swapping) {
      uint256 gas = gasForProcessing;

      try dividendTracker.process(gas) returns (
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex
      ) {
        emit ProcessedDividendTracker(
          iterations,
          claims,
          lastProcessedIndex,
          true,
          gas,
          tx.origin
        );
      } catch {}
    }
  }

  function DoKENRewardAddress() external view returns (address) {
    return rewardToken;
  }

  function DoKENDividendTrackerAddress() external view returns (address) {
    return address(dividendTracker);
  }

  function DoKENRewardOnPool() external view returns (uint256) {
    return IERC20(rewardToken).balanceOf(address(dividendTracker));
  }

  function DoKENTokenFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      getTotalFees(),
      rewardsFee,
      liquidityFee,
      marketingFee,
      devFee,
      sellFee
    );
  }

  function DoKENRewardDistributed() external view returns (uint256) {
    return dividendTracker.getTotalDividendsDistributed();
  }

  function DoKENGetAccountDividendsInfo(address account)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccount(account);
  }

  function DoKENGetAccountDividendsInfoAtIndex(uint256 index)
    public
    view
    returns (
      address,
      int256,
      int256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return dividendTracker.getAccountAtIndex(index);
  }

  function DoKENRewardPaid(address holder) external view returns (uint256) {
    (, , , , uint256 paidAmount, , , , ) = DoKENGetAccountDividendsInfo(
      holder
    );
    return paidAmount;
  }


  function DoKENRewardUnPaid(address holder)
    external
    view
    returns (uint256)
  {
    (, , , uint256 unpaidAmount, , , , , ) = DoKENGetAccountDividendsInfo(
            holder
    );
    return unpaidAmount;
  }

  function DoKENRewardClaim() external {
    dividendTracker.processAccount(payable(msg.sender), false);
  }

  function DividendLastProcessedIndex() external view returns (uint256) {
    return dividendTracker.getLastProcessedIndex();
  }

  function DoKENNumberOfDividendTokenHolders()
    external
    view
    returns (uint256)
  {
    return dividendTracker.getNumberOfTokenHolders();
  }

  function DividendDividendBalanceOf(address account)
    public
    view
    returns (uint256)
  {
    return dividendTracker.balanceOf(account);
  }

  function swapAndLiquifyAndFundTeam(uint256 tokens) private {
    uint256 totalFees = marketingFee.add(liquidityFee).add(devFee);
    // calculate token for liquidity
    uint256 liquidityTokens = tokens.mul(liquidityFee).div(totalFees);
    uint256 tokensForLiquidity = liquidityTokens.div(2); // half each
    // now do swap first
    uint256 balanceBeforeLiq = address(this).balance;
    swapTokensForEth(tokensForLiquidity);
    uint256 balanceAfterLiq = address(this).balance.sub(balanceBeforeLiq);

    // add liquidity to uniswap (really PCS, duh)
    addLiquidity(tokensForLiquidity, balanceAfterLiq);
    emit SwapAndLiquify(tokensForLiquidity, balanceAfterLiq, balanceAfterLiq);

    uint256 otherHalf = tokens.sub(liquidityTokens);

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(otherHalf); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance.sub(initialBalance);

    //uint256 marketingTokens = half.mul(marketingFee).div(totalFees);
    uint256 mktAndDevAndBuyback = marketingFee.add(devFee).add(buyBackFee);

    uint256 marketingETH = newBalance.mul(marketingFee).div(
      mktAndDevAndBuyback
    );
    uint256 buyBackETH = (newBalance.mul(buyBackFee).div(mktAndDevAndBuyback))
      .div(2);

    uint256 devETH = (newBalance.mul(devFee).div(mktAndDevAndBuyback)).add(
      buyBackETH
    );

    marketingWallet.transfer(marketingETH);
    buyBackWallet.transfer(buyBackETH);
    devWallet.transfer(devETH);
  }

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
      block.timestamp
    );
  }

  function swapTokensForETH(uint256 tokenAmount, address recipient) private {
    // generate the uniswap pair path of tokens -> WETH
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETH(
      tokenAmount,
      0, // accept any amount of the reward token
      path,
      recipient,
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this), // lock LP tokens in this contract forever - no rugpull, SAFU!!
      block.timestamp
    );
  }

  function swapTokensForRewards(uint256 tokenAmount, address recipient)
    private
  {
    // generate the uniswap pair path of weth -> reward token
    address[] memory path = new address[](3);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    path[2] = rewardToken;

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of the reward token
      path,
      recipient,
      block.timestamp
    );
  }

  function sendDividends() private returns (bool, uint256) {
    uint256 dividends = IERC20(rewardToken).balanceOf(address(this));
    bool success = IERC20(rewardToken).transfer(
      address(dividendTracker),
      dividends
    );

    if (success) {
      dividendTracker.distributeRewardTokenDividends(dividends);
    }

    return (success, dividends);
  }

  function swapAndSendDividends(uint256 tokens) private {
    // Locks the LP tokens in this contract forever
    swapTokensForRewards(tokens, address(this));
    (bool success, uint256 dividends) = sendDividends();
    if (success) {
      emit SendDividends(tokens, dividends);
    }
  }

  // For withdrawing ETH accidentally sent to the contract so senders can be refunded
  function getETHBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function flushStuckBalance() external {
    address payable to = devWallet;
    to.transfer(getETHBalance());
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private {
    bytes4 SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(SELECTOR, to, value)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TRANSFER_FAILED"
    );
  }
}