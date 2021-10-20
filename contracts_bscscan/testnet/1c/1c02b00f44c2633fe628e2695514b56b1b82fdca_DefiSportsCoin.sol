// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./BEP20.sol";
import "./IDEX.sol";

contract DefiSportsCoin is BEP20 {
  using EnumerableSet for EnumerableSet.AddressSet;

  address public constant MARKETING = 0xc08adaFf0e9EA1cD0ac2A1E5A3a0960AB96d9025;
  address constant LOCKER = 0x0AEf731630716D9A5c2c5C3e5E37a07d59300A97; // to update after locker deployment

  uint256 private timeFrame = 7 minutes; // 1 year in minutes
  uint256 private startTime = block.timestamp;

  uint256 public swapThreshold = 300000 * 10**18;
  bool public swapEnabled = true;
  bool public tradingEnabled;
  bool _sniperTax = true;
  bool _inSwap;

  uint256 public liquidityFee = 500;
  uint256 public marketingFee = 500;
  uint256 _totalFee = 1000;
  uint256 constant FEE_DENOMINATOR = 10000;

  IDexRouter public constant ROUTER = IDexRouter(0xBBe737384C2A26B15E23a181BDfBd9Ec49E00248); 
    //0xD99D1c33F9fC3444f8101754aBC46c52416550D1 testnet router
        //0x10ED43C718714eb63d5aA57B78B54704E256024E mainnet router
        //pinkswap router 0xBBe737384C2A26B15E23a181BDfBd9Ec49E00248
  address public immutable pair;
  uint256 public transferGas = 25000;

  mapping (address => bool) public isWhitelisted;
  mapping (address => bool) public isFeeExempt;
  mapping (address => bool) public isBaseFeeExempt;
  mapping (address => bool) public isMarketMaker;

  event SetIsWhitelisted(address indexed account, bool indexed status);
  event SetBaseFeeExempt(address indexed account, bool indexed exempt);
  event SetFeeExempt(address indexed account, bool indexed exempt);
  event SetMarketMaker(address indexed account, bool indexed isMM);
  event SetSwapBackSettings(bool indexed enabled, uint256 amount);
  event SetFees(uint256 liquidity, uint256 marketing);
  event AutoLiquidity(uint256 pair, uint256 tokens);
  event UpdateTransferGas(uint256 gas);
  event Recover(uint256 amount);
  event TriggerSwapBack();
  event EnableTrading();

  // Vesting

  // Helper to determine vesting logic with O(1) complexity
  // Can't be used in enumeration as the ordering can't be guaranteed
  EnumerableSet.AddressSet vesting;
  uint256[5][5] leftX;
  address[5] allWallets = [
    0xDc271B68e559Bcfb8304421CA193206C9a4E93eD, // Wallet for Ambassadors
    0xbBa5D96D3588238E560e71ccCa973429765988f6, // Wallet for Associations
    0x850bCd23a20E36140b45C6B4dFc3285d61Ff3863, // Wallet for The BitcoinManTM
    0xAC2a8d02ff977c1c3BfEd6648f84cb786714E045, // Wallet for Advisors
    0xfeD7e1F6c2534FF1c05CAE1Bc7BA35B37e053a4a // Wallet for Team
  ];


  modifier swapping() { 
    _inSwap = true;
    _;
    _inSwap = false;
  }

  modifier onlyOwner() {
    require(msg.sender == getOwner());
    _;
  }

  constructor() BEP20() {
    pair = IDexFactory(ROUTER.factory()).createPair(ROUTER.WETH(), address(this));
    _approve(address(this), address(ROUTER), type(uint256).max);
    isMarketMaker[pair] = true;

    _initVesting();

    isWhitelisted[getOwner()] = true;
    isWhitelisted[MARKETING] = true;
    isWhitelisted[address(this)] = true;

    isBaseFeeExempt[0xDc271B68e559Bcfb8304421CA193206C9a4E93eD] = true;
    isBaseFeeExempt[0xbBa5D96D3588238E560e71ccCa973429765988f6] = true;
    isBaseFeeExempt[0x850bCd23a20E36140b45C6B4dFc3285d61Ff3863] = true;
    isBaseFeeExempt[0xAC2a8d02ff977c1c3BfEd6648f84cb786714E045] = true;
    isBaseFeeExempt[0xfeD7e1F6c2534FF1c05CAE1Bc7BA35B37e053a4a] = true;


    isFeeExempt[0xDc271B68e559Bcfb8304421CA193206C9a4E93eD] = true;
    isFeeExempt[0xbBa5D96D3588238E560e71ccCa973429765988f6] = true;
    isFeeExempt[0x850bCd23a20E36140b45C6B4dFc3285d61Ff3863] = true;
    isFeeExempt[0xAC2a8d02ff977c1c3BfEd6648f84cb786714E045] = true;
    isFeeExempt[0xfeD7e1F6c2534FF1c05CAE1Bc7BA35B37e053a4a] = true;

    vesting.add(0xDc271B68e559Bcfb8304421CA193206C9a4E93eD);
    vesting.add(0xbBa5D96D3588238E560e71ccCa973429765988f6);
    vesting.add(0x850bCd23a20E36140b45C6B4dFc3285d61Ff3863);
    vesting.add(0xAC2a8d02ff977c1c3BfEd6648f84cb786714E045);
    vesting.add(0xfeD7e1F6c2534FF1c05CAE1Bc7BA35B37e053a4a);
  }

  // Override

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    if (isWhitelisted[sender] || isWhitelisted[recipient]) { super._transfer(sender, recipient, amount); return; }
    require(tradingEnabled, "Trading is disabled");

    if (_shouldSwapBack(recipient)) { _swapBack(); }
    uint256 amountAfterFees = _takeFee(sender, recipient, amount);

    uint256 timePeriod = (block.timestamp - startTime) / timeFrame;
    if (vesting.contains(sender) && timePeriod < 5) { _validateVesting(sender, amount, timePeriod); }

    super._transfer(sender, recipient, amountAfterFees);
  }

  // Public

  function getTotalFee() public view returns (uint256) {
    if (_sniperTax) { return FEE_DENOMINATOR - 200; }
    return _totalFee;
  }

  receive() external payable {}

  // Private

  function _takeFee(address sender, address recipient, uint256 amount) private returns (uint256) {
    if (amount > 0) {
      uint256 baseFeeAmount;
      if (!isBaseFeeExempt[sender] && !isBaseFeeExempt[recipient]) {
        baseFeeAmount = amount / 100;
        super._transfer(sender, MARKETING, baseFeeAmount);
      }

      uint256 feeAmount;
      if (!isFeeExempt[sender] && !isFeeExempt[recipient] && (isMarketMaker[recipient] || isMarketMaker[sender])) {
        feeAmount = amount * getTotalFee() / FEE_DENOMINATOR;
        super._transfer(sender, address(this), feeAmount);
      }

      return amount - baseFeeAmount - feeAmount;
    } else {
      return amount;
    }
  }

  function _validateVesting(address sender, uint256 amount, uint256 timePeriod) private view {
    for (uint256 i = 0; i < 5; i++) {
      if (sender == allWallets[i]) {
        require(balanceOf(sender) - amount >= leftX[i][timePeriod], "Amount requested larger than allowed, Please refer to the release plan");
        break;
      }
    }
  }

  function _initVesting() private {
       // The amount of token should be left in each wallet in every timePeriod
    // wallets for Ambassadors, Associations, Advisors will be released at the beginning of each year
    // becasue DefiSports company needs to distribute tokens to Ambassadors, Associations and Advisors.
    // Other wallets will be released at the completion of each year.
    
    leftX[0] = [16*10**8*10**18, 12*10**8*10**18, 8*10**8*10**18, 4*10**8*10**18, 0]; //Ambassadors (4% will be released at the beginning of each year)
    leftX[1] = [8*10**8*10**18, 6*10**8*10**18, 4*10**8*10**18, 2*10**8*10**18, 0]; //Associations (2% will be released at the beginning of each year)
    leftX[2] = [5*10**8*10**18, 3*10**8*10**18, 1*10**8*10**18, 0, 0];//BitcoinManTM
    leftX[3] = [4*10**8*10**18, 3*10**8*10**18, 2*10**8*10**18, 1*10**8*10**18, 0]; //Advisors (1% will be released at the beginning of each year)
    leftX[4] = [15*10**8*10**18, 12*10**8*10**18, 9*10**8*10**18, 6*10**8*10**18, 3*10**8*10**18];//Team wallet
  }

  function _shouldSwapBack(address recipient) private view returns (bool) {
    return isMarketMaker[recipient] // TODO: test swap logic with custom market maker "sell"
    && !_inSwap
    && swapEnabled
    && balanceOf(address(this)) >= swapThreshold;
  }

  function _swapBack() private swapping {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = ROUTER.WETH();

    uint256 liquidityTokens = swapThreshold * liquidityFee / _totalFee / 2;
    uint256 amountToSwap = swapThreshold - liquidityTokens;
    uint256 balanceBefore = address(this).balance;

    ROUTER.swapExactTokensForETH(
      amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 amountBNB = address(this).balance - balanceBefore;
    uint256 totalBNBFee = _totalFee - liquidityFee / 2;

    uint256 amountBNBLiquidity = amountBNB * liquidityFee / totalBNBFee / 2;
    uint256 amountBNBMarketing = amountBNB * marketingFee / totalBNBFee;
    payable(MARKETING).call{value: amountBNBMarketing, gas: transferGas}("");

    if (liquidityTokens > 0) {
      ROUTER.addLiquidityETH{value: amountBNBLiquidity}(
        address(this),
        liquidityTokens,
        0,
        0,
        LOCKER,
        block.timestamp
      );

      emit AutoLiquidity(amountBNBLiquidity, liquidityTokens);
    }
  }

  // Owner

  function removeSniperTax() external onlyOwner {
    _sniperTax = false;
  }

  function enableTrading() external onlyOwner {
    tradingEnabled = true;
    emit EnableTrading();
  }

  function setIsWhitelisted(address account, bool status) external onlyOwner {
    require(account != getOwner() && !isMarketMaker[account]);
    isWhitelisted[account] = status;
    emit SetIsWhitelisted(account, status);
  }

  function setIsBaseFeeExempt(address account, bool exempt) external onlyOwner {
    require(account != getOwner() && account != MARKETING && !isMarketMaker[account]);
    isBaseFeeExempt[account] = exempt;
    emit SetBaseFeeExempt(account, exempt);
  }

  function setIsFeeExempt(address account, bool exempt) external onlyOwner {
    require(account != getOwner() && account != MARKETING && !isMarketMaker[account]);
    isFeeExempt[account] = exempt;
    emit SetFeeExempt(account, exempt);
  }

  function setIsMarketMaker(address account, bool isMM) external onlyOwner {
    require(account != pair);
    isMarketMaker[account] = isMM;
    emit SetMarketMaker(account, isMM);
  }

  function setFees(uint256 newLiquidityFee, uint256 newMarketingFee) external onlyOwner {
    liquidityFee = newLiquidityFee;
    marketingFee = newMarketingFee;
    _totalFee = liquidityFee + marketingFee;
    require(_totalFee <= 1500);

    emit SetFees(liquidityFee, marketingFee);
  }

  function setSwapBackSettings(bool enabled, uint256 amount) external onlyOwner {
    uint256 tokenAmount = amount * 10**decimals();
    swapEnabled = enabled;
    swapThreshold = tokenAmount;
    emit SetSwapBackSettings(enabled, amount);
  }

  function updateTransferGas(uint256 newGas) external onlyOwner {
    require(newGas >= 21000 && newGas <= 100000);
    transferGas = newGas;
    emit UpdateTransferGas(newGas);
  }

  function triggerSwapBack() external onlyOwner {
    _swapBack();
    emit TriggerSwapBack();
  }

  function recover() external onlyOwner {
    uint256 amount = address(this).balance;
    (bool sent,) = payable(MARKETING).call{value: amount, gas: transferGas}("");
    require(sent, "Tx failed");
    emit Recover(amount);
  }
}