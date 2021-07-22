// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract BME is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    address private immutable BTCB = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address private immutable BurnAddress = address(0x000000000000000000000000000000000000dEaD);
    address public immutable BMEToken11 = address(this);

    bool private swapping;
    BMEBTCBTracking public dividendBTCBTracker;
    BMETokenTracking public dividendBMETracker;
    address public liquidityWallet;

    uint256 public maxSellTransactionAmount = 1000000 * (10**18);
    uint256 public swapTokensAtAmount = 200000 * (10**18);
    uint256 public sellFeeIncreaseFactor = 120;
    uint256 public gasForProcessing = 300000;
    uint256 public tradingEnabledTimestamp = 1625947158;
    uint256 public minimumBuyTrades = 5;
    uint256 public minimumAmountBuyTrades = 1000 * (10**18);
    uint256 public MinimumHoldingDays = 30;
    uint256 constant internal magnitude = 2**128;
    uint256 public oneDay = 120;

    uint256 private  BTCRewardsFee;
    uint256 private  TokenRewardFee;
    uint256 private  BuyliquidityFee;
    uint256 private  SellliquidityFee;
    uint256 public  BuytotalFees;
    uint256 public  SelltotalFees;
    uint256 public  claimWait;
    uint256 private  BuyFee;
    uint256 private  SellFee;

    uint256 public TotalTokensReward;
    mapping (address => uint256) public RewadPerTokens;

    mapping (address => uint256) public NumberOfBuyTrades;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    mapping (address => uint256) public antiWhaleSellAmount;
    mapping (address => uint256) public antiWhaleRestriction;
    mapping (address => uint256) public lastClaimTimes;
    uint256 private  oneDayRestriction;

    mapping (address => uint256) public HoldingDays;
    mapping (address => bool) public PassedMinimumTrades;
    mapping (address => uint256) public HoldingTime;
    mapping (address => bool) public onCycel;
    uint256 public readyHoldingDays;
    uint256 public minimumCycelTkoens = 1 * (10**6) * (10**18);

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,  uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SendBTCBDividends(uint256 tokensSwapped,uint256 BTCamount);
    event LastClaims(uint256 claims);
    event ProcessedBTCBDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);
    event ProcessedBMEDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);

    constructor() public ERC20("ccctest18", "test18") {

        claimWait = 600;
        uint256 _BTCRewardsFee = 10;
        uint256 _TokenRewardFee = 1;
        uint256 _BuyliquidityFee = 1;
        uint256 _SellLiquidityFee = 3;

        BTCRewardsFee = _BTCRewardsFee;
        TokenRewardFee = _TokenRewardFee;
        BuyliquidityFee = _BuyliquidityFee;
        SellliquidityFee = _SellLiquidityFee;


        BuytotalFees = _BTCRewardsFee.add(_BuyliquidityFee.add(_TokenRewardFee));

        SelltotalFees = _BTCRewardsFee.add(_SellLiquidityFee.add(_TokenRewardFee));

    	 dividendBTCBTracker = new BMEBTCBTracking();
        dividendBMETracker = new BMETokenTracking();

    	  IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        liquidityWallet = owner();

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving BTCB dividends
        dividendBTCBTracker.excludeFromDividends(address(dividendBTCBTracker));
        dividendBTCBTracker.excludeFromDividends(address(dividendBMETracker));
        dividendBTCBTracker.excludeFromDividends(address(this));
        dividendBTCBTracker.excludeFromDividends(owner());
        dividendBTCBTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from receiving Tokens dividends
        dividendBMETracker.excludeFromDividends(address(dividendBTCBTracker));
        dividendBMETracker.excludeFromDividends(address(dividendBMETracker));
        dividendBMETracker.excludeFromDividends(address(this));
        dividendBMETracker.excludeFromDividends(owner());
        dividendBMETracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);


        // mint just for 1 time ..
        _mint(owner(), 1 * (10**12) * (10**18));

        dividendBMETracker.setBMEToken(address(this));

    }

    receive() external payable {
            SendBMEDividends();
            CalculetHoldingDays();
  	}

    function updateMianClaimWait(uint256 newclaimWait) external onlyOwner {
        claimWait = newclaimWait;
    }

    function setSwapTokensAtAmt(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * (10**18);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BME: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendBTCBTracker.excludeFromDividends(pair);
            dividendBMETracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BME: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BME: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BME: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function burn(address account, uint256 amount) public onlyOwner {


        require(account != address(0), "BME: burn from the zero address");

        transfer(BurnAddress, amount);
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "BME: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }



    function setMaxSellTxAmount(uint256 amount) external onlyOwner{
        maxSellTransactionAmount = amount * 10**18;
    }


    function setFeesAmount(uint256 NewBTCBFee ,uint256 NewTokenRewardFee ,uint256 NewBuyLFee ,uint256 NewSellLFee) external onlyOwner{
        BTCRewardsFee = NewBTCBFee;
        TokenRewardFee = NewTokenRewardFee;
        BuyliquidityFee = NewBuyLFee;
        SellliquidityFee = NewSellLFee;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BME: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    // start  Dividend BTCB Tracker functions


    function updateDividendBTCBTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendBTCBTracker), "BME: The dividend tracker already has that address");

        BMEBTCBTracking newDividendBTCBTracker = BMEBTCBTracking(payable(newAddress));

        require(newDividendBTCBTracker.owner() == address(this), "BME: The new dividend tracker must be owned by the BME token contract");

        newDividendBTCBTracker.excludeFromDividends(address(newDividendBTCBTracker));
        newDividendBTCBTracker.excludeFromDividends(address(this));
        newDividendBTCBTracker.excludeFromDividends(owner());
        newDividendBTCBTracker.excludeFromDividends(address(uniswapV2Router));


        dividendBTCBTracker = newDividendBTCBTracker;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendBTCBTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendBTCBTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendBTCBTracker.balanceOf(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendBTCBTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendBTCBTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendBTCBTracker.process(gas);
		emit ProcessedBTCBDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendBTCBTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendBTCBTracker.getLastProcessedIndex();
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    function NewClaimTime(uint256 setNewClaimTime) external {
    	dividendBTCBTracker.NewClaimTime(msg.sender, setNewClaimTime);
    }

    function getClaimTime(address account) external view returns(uint256) {
      return dividendBTCBTracker.getClaimTime(account);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256 , uint256, uint256) {

        return ( dividendBTCBTracker.getNumberOfTokenHolders(), tokenHoldersMap.keys.length, dividendBMETracker.getNumberOfTokenHolders());
    }

    function setMinTokensToGetReward(uint256 amount) external onlyOwner{
        dividendBTCBTracker.setMinTokensToGetReward(amount);
    }

    // end  Dividend BTCB Tracker functions

    // start  Dividend BME Tracker functions

    function updateDividendBMETracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendBMETracker), "BME: The dividend tracker already has that address");

        BMETokenTracking newDividendBMETracker = BMETokenTracking(payable(newAddress));

        require(newDividendBMETracker.owner() == address(this), "BME: The new dividend tracker must be owned by the BME token contract");

        newDividendBMETracker.excludeFromDividends(address(dividendBMETracker));
        newDividendBMETracker.excludeFromDividends(address(this));
        newDividendBMETracker.excludeFromDividends(owner());
        newDividendBMETracker.excludeFromDividends(address(uniswapV2Router));


        dividendBMETracker = newDividendBMETracker;
    }

    function getClaimWaitBME() external view returns(uint256) {
        return dividendBMETracker.claimWait();
    }

    function getTotalDividendsDistributedBME() external view returns (uint256) {
        return dividendBMETracker.totalDividendsDistributed();
    }

	function dividendTokenBalanceOfBME(address account) public view returns (uint256) {
		return dividendBMETracker.balanceOf(account);
	}

	function processDividendTrackerBME(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendBMETracker.process(gas);
		emit ProcessedBMEDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function getLastProcessedIndexBME() external view returns(uint256) {
    	return dividendBMETracker.getLastProcessedIndex();
    }

    function getNumberOfTokenHoldersBME() external view returns(uint256) {
        return dividendBMETracker.getNumberOfTokenHolders();
    }

    function getStageStatus() external view returns(bool) {
        return dividendBMETracker.getStageStatus();
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 2592000, "BMETrackingToken: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BMETrackingToken: Cannot update claimWait to same value");
        claimWait = newClaimWait;
    }

    function StartSeason(uint256 newStartTime ,uint256 newEndTime ,uint256 newMinimumTokens , uint256 newClaimWait) external onlyOwner{
        minimumCycelTkoens = newMinimumTokens * (10**18);
        dividendBMETracker.updateClaimWait(newClaimWait);
        dividendBMETracker.StartSeason(newStartTime ,newEndTime);
    }

    function SeasonTime() external view returns(uint256 ,uint256 ) {
        return dividendBMETracker.SeasonTime();
    }

    function CycelTime() external view returns(uint256 ,uint256 ) {
        return dividendBMETracker.CycelTime();
    }


    function resetSeason() external onlyOwner{
        dividendBMETracker.resetSeason();
    }

    function UpdateCycel(uint256 newnumberOfTokenHolders ,uint256 newMinimumHoldingDays ,uint256 newtimeToBeOut) external onlyOwner{
        MinimumHoldingDays = newMinimumHoldingDays;
        dividendBMETracker.UpdateCycel(newnumberOfTokenHolders ,newtimeToBeOut);
    }

    function setStageOne(uint256 rewardAmount,uint256 getRewardFrom,uint256 getRewardTo) external onlyOwner{
        dividendBMETracker.setStageOne(rewardAmount,getRewardFrom,getRewardTo);
    }

    function StageOne() external view returns(uint256 ,uint256 ,uint256 ) {
        return dividendBMETracker.StageOne();
    }

    function setStageTwo(uint256 rewardAmount,uint256 getRewardFrom,uint256 getRewardTo) external onlyOwner{
        dividendBMETracker.setStageTwo(rewardAmount,getRewardFrom,getRewardTo);
    }

    function StageTwo() external view returns(uint256 ,uint256 ,uint256 ) {
        return dividendBMETracker.StageTwo();
    }

    function setStageThree(uint256 rewardAmount,uint256 getRewardFrom,uint256 getRewardTo) external onlyOwner{
        dividendBMETracker.setStageThree(rewardAmount,getRewardFrom,getRewardTo);
    }

    function StageThree() external view returns(uint256 ,uint256 ,uint256 ) {
        return dividendBMETracker.StageThree();
    }


    // end  Dividend Tokens Tracker functions


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");


        bool tradingIsEnabled = getTradingIsEnabled();

        // no one can transfer before trading Is Enabled
        // and before the public presale is over
        if(!tradingIsEnabled){
            require(_isExcludedFromFees[from], "BME: cannot send tokens when trading is disable");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }


        if(antiWhaleRestriction[from].add(oneDayRestriction) >= block.timestamp && from != liquidityWallet ){
          antiWhaleSellAmount[from] = 0;
          antiWhaleRestriction[from] = block.timestamp;
         }

        uint256 TotalDaySellAmount = antiWhaleSellAmount[from].add(amount);

        if(
        	!swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] && //no max for those excluded from fees
            !_isExcludedFromFees[from] &&
            to != liquidityWallet &&
            from != liquidityWallet
        ) {
            require(TotalDaySellAmount <= maxSellTransactionAmount, "Sell transfer total day amount exceeds the maxSellTransactionAmount.");
        }

        if(automatedMarketMakerPairs[from] && amount >= minimumAmountBuyTrades && !PassedMinimumTrades[to]){
          if(NumberOfBuyTrades[to] < minimumBuyTrades ){

            NumberOfBuyTrades[to] = NumberOfBuyTrades[to].add(1);

          }
          if(NumberOfBuyTrades[to] >= minimumBuyTrades ){
           canCalculetHoldingDays(to);
            NumberOfBuyTrades[to] = 0;

          }
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;

            // Calculet Buy Fees
            uint256 BuyFeeRewadTokens = BuyFee.mul(TokenRewardFee).div(BuytotalFees);
            uint256 BuyFeeLiquidityTokens = BuyFee.mul(BuyliquidityFee).div(BuytotalFees);
            uint256 BuyFeeBTCBTokens = BuyFee.mul(BTCRewardsFee).div(BuytotalFees);

            // Calculet Buy Fees
            uint256 SellFeeRewadTokens = SellFee.mul(TokenRewardFee).div(SelltotalFees);
            uint256 SellFeeLiquidityTokens = SellFee.mul(SellliquidityFee).div(SelltotalFees);
            uint256 SellFeeBTCBTokens = SellFee.mul(BTCRewardsFee).div(SelltotalFees);


            // Send Buyfees and Sellfees
            TotalTokensFee(
              BuyFeeRewadTokens ,
              BuyFeeLiquidityTokens ,
              BuyFeeBTCBTokens ,
              SellFeeRewadTokens ,
              SellFeeLiquidityTokens ,
              SellFeeBTCBTokens
               );

            BuyFee  = 0;
            SellFee = 0;
            swapping = false;
            
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }


        if(takeFee) {

          uint256 Fees;
          // check if sell or buy
          if( automatedMarketMakerPairs[to] ) {

           antiWhaleSellAmount[from] = antiWhaleSellAmount[from].add(amount);

           Fees = amount.mul(SelltotalFees).div(100);
           SellFee  = SellFee.add(Fees);

          }

          if( automatedMarketMakerPairs[from] ){

          Fees = amount.mul(BuytotalFees).div(100);
          BuyFee  = BuyFee.add(Fees);

          }

        amount = amount.sub(Fees);

        super._transfer(from, address(this), Fees);

        }

        super._transfer(from, to, amount);


        uint256 balanceOfFrom =  balanceOf(from);
          uint256 balanceOfTo =  balanceOf(to);
    
          if( !automatedMarketMakerPairs[from] || !_isExcludedFromFees[from] ){
    
          tokenHoldersMap.set(from, balanceOfFrom);
    
          }
    
          if( !automatedMarketMakerPairs[to] || !_isExcludedFromFees[to] ){
    
          tokenHoldersMap.set(to, balanceOfTo);
    
          }
    
          if( balanceOfFrom <= 10 * (10**18)){
          HoldingDays[from] = 0;
          tokenHoldersMap.remove(from);
    
          }

        
        try dividendBTCBTracker.setBalance(payable(from), balanceOf(from), amount) {} catch {}
        try dividendBTCBTracker.setBalance(payable(to), balanceOf(to), amount) {} catch {}

        try dividendBMETracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendBMETracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;
	    	

          try dividendBTCBTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedBTCBDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);} catch {}

    	    try dividendBMETracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedBMEDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);} catch {}
        }
    }
    
    function TotalTokensFee(
      uint256 BuyFeeRewadTokens ,
      uint256 BuyFeeLiquidityTokens ,
      uint256 BuyFeeBTCBTokens ,
      uint256 SellFeeRewadTokens ,
      uint256 SellFeeLiquidityTokens ,
      uint256 SellFeeBTCBTokens
      ) private {
        // Fee calculation
        uint256 RewadTokens = BuyFeeRewadTokens.add(SellFeeRewadTokens);
        uint256 swapTokens = BuyFeeLiquidityTokens.add(SellFeeLiquidityTokens);
        uint256 sellTokens = BuyFeeBTCBTokens.add(SellFeeBTCBTokens);
        // send it to BTCB reward , tokens reward , Liquidity
        calculetBMEDividends(RewadTokens);
        swapAndLiquify(swapTokens);
        swapAndSendBTCBDividends(sellTokens);

    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancake
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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

    function swapTokensForBTCB(uint256 tokenAmount) private {
         // generate the uniswap pair path of weth -> BTCB
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BTCB;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BTCB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );

    }

    function swapAndSendBTCBDividends(uint256 tokens) private {
        swapTokensForBTCB(tokens);
        uint256 dividends = IERC20(BTCB).balanceOf(address(this));  // chack the balance of BTCB
        bool success = IERC20(BTCB).transfer(address(dividendBTCBTracker), dividends); // transfer the balance of BTCB

        if (success) {
            dividendBTCBTracker.distributeBTCBDividends(dividends); // add the balance of BTCB to the total
            emit SendBTCBDividends(tokens, dividends); // send amount to event
        }
    }

    function calculetBMEDividends(uint256 tokens) private {

        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        TotalTokensReward = TotalTokensReward.add(tokens);
        uint256 iterations = 0;

        uint256 rewardPerToken = tokens.mul(magnitude).div(totalSupply());
            if(rewardPerToken > 0){
          while(iterations < numberOfTokenHolders) {
          iterations++;


          address account = tokenHoldersMap.keys[iterations];
          uint256 accountbalance = balanceOf(account);
          uint256 tokensForoneToken = rewardPerToken.mul(accountbalance).div(magnitude);

          RewadPerTokens[account] = RewadPerTokens[account].add(tokensForoneToken);


        }
      }
    }

    function SendBMEDividends() private onlyOwner {
        
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
        uint256 iterations = 0;


        if(TotalTokensReward > 0 ){
          while(iterations < numberOfTokenHolders) {
          iterations++;

          address account = tokenHoldersMap.keys[iterations];
          if(canAutoClaim(lastClaimTimes[account])) {
            if(processAccount(payable(account))) {
              }
            }
          }
        }
      }

        function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {

        	if(lastClaimTime > block.timestamp)  {
        		return false;
        	}
        	  return block.timestamp.sub(lastClaimTime) >= claimWait;

        }

        function processAccount(address payable account) public onlyOwner returns (bool) {
            uint256 amount = _withdrawDividendOfUser(account);

          if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            return true;
          }

          return false;
        }

        function _withdrawDividendOfUser(address payable account ) public onlyOwner returns (uint256) {


          uint256 amount = RewadPerTokens[account];
          transfer(account, amount);


             RewadPerTokens[account] = 0;
             return amount;

        }
        

        function canCalculetHoldingDays(address account) public onlyOwner {

          PassedMinimumTrades[account] = true;
          HoldingTime[account] = block.timestamp;
          readyHoldingDays = readyHoldingDays.add(1);
        }

        function CalculetHoldingDays() private onlyOwner   {

          uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

          uint256 iterations = 0;

            if(readyHoldingDays >= 1){
            while(iterations < numberOfTokenHolders) {
            iterations++;


            address account = tokenHoldersMap.keys[iterations];
            bool addOneDay = HoldingDays[account] <= MinimumHoldingDays;
            uint256 accountBalance = balanceOf(account);
            if(accountBalance == 0){
              PassedMinimumTrades[account] = false;
              HoldingDays[account] = 0;

            }
            if( addOneDay && PassedMinimumTrades[account] && accountBalance >= minimumCycelTkoens && !onCycel[account] && HoldingTime[account].add(oneDay) >= block.timestamp ){

            HoldingDays[account] = HoldingDays[account].add(1);
            HoldingTime[account] = block.timestamp;

            }

            if( HoldingDays[account] >= MinimumHoldingDays && PassedMinimumTrades[account]  && accountBalance >= minimumCycelTkoens && !onCycel[account]){
              dividendBMETracker.iscanJoinCycel(account);
              onCycel[account] = true;
            }
          }
        }
      }

}

contract BMEBTCBTracking is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;
    mapping (address => uint256) public ClaimTime;

    uint256 public lastProcessedIndex;
    uint256 public claimWait1Hour;
    uint256 public claimWait6Hours;
    uint256 public claimWait12Hours;
    uint256 public claimWait24Hours;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("BMETrackingBTCB", "BMETB") {
    	// User options for receiving Dividends
      claimWait1Hour = 600;
      claimWait6Hours = 700;
      claimWait12Hours = 800;
      claimWait24Hours = 900;

      minimumTokenBalanceForDividends = 5 * (10**7) * (10**18);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BMETrackingBTCB: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "BMETrackingBTCB: withdrawDividend disabled. Use the 'claim' function on the main BME contract.");
    }

    function setMinTokensToGetReward(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function NewClaimTime(address account, uint256 setNewClaimTime) external  {
      if(setNewClaimTime == 1 || setNewClaimTime == 2 || setNewClaimTime == 3 || setNewClaimTime == 4 ){
		    ClaimTime[account] = setNewClaimTime;
      }else{
          ClaimTime[account] = 4;

      }
    }

    function getClaimTime(address account) external view returns(uint256) {
      return ClaimTime[account];
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {

        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];


        if(ClaimTime[account] == 1){

          nextClaimTime = lastClaimTime > 0 ?
                                      lastClaimTime.add(claimWait1Hour) :
                                      0;

        }else

        if(ClaimTime[account] == 2){

          nextClaimTime = lastClaimTime > 0 ?
                                      lastClaimTime.add(claimWait6Hours) :
                                      0;

        }else

        if(ClaimTime[account] == 3){

          nextClaimTime = lastClaimTime > 0 ?
                                      lastClaimTime.add(claimWait12Hours) :
                                      0;

        }else

        if(ClaimTime[account] == 4){

          nextClaimTime = lastClaimTime > 0 ?
                                      lastClaimTime.add(claimWait24Hours) :
                                      0;

        }

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime , uint256 checkClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

      if(checkClaimTime == 1){

    	   return block.timestamp.sub(lastClaimTime) >= claimWait1Hour;

      }else

      if(checkClaimTime == 2){

        return block.timestamp.sub(lastClaimTime) >= claimWait6Hours;

      }else

      if(checkClaimTime == 3){

        return block.timestamp.sub(lastClaimTime) >= claimWait12Hours;

      }else

      if(checkClaimTime == 4){

        return block.timestamp.sub(lastClaimTime) >= claimWait24Hours;

      }

    }

    function setBalance(address payable account, uint256 newBalance,uint256 amount) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}


      if(newBalance.sub(amount) == 0){

        ClaimTime[account] = 1;

      }

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
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

    		if(canAutoClaim(lastClaimTimes[account],ClaimTime[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
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
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

contract BMETokenTracking is DividendPayingTokenBME, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    uint256 public MinimumHoldingDays;
    uint256 public StartTime;
    uint256 public EndTime;
    uint256 public StartCycelTime;
    uint256 public EndCycelTime;
    uint256 public maxmumCycelmembers;
    uint256 public timeToBeOut;
    bool public stageRewardStatus;


    uint256 public stageOneReward;
    uint256 public stageOneRewardFrom;
    uint256 public stageOneRewardTo;

    uint256 public stageTwoReward;
    uint256 public stageTwoRewardFrom;
    uint256 public stageTwoRewardTo;

    uint256 public stageThreeReward;
    uint256 public stageThreeRewardFrom;
    uint256 public stageThreeRewardTo;

    mapping (address => uint256) public withdrawnDividendstouser;
    mapping (address => bool) public canJoinCycel;
    mapping (address => bool) public JoinedCycel;
    uint256 public MembersOnSeason;

    address public  BMEToken;

    event ExcludeFromDividends(address indexed account);


    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingTokenBME("BMETrackingToken", "BMETT") {
      claimWait = 86400; // time to get tokens rewards
      minimumTokenBalanceForDividends = 1000 * (10**18); // minimum tokens to register in cycel
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BMETrackingToken: No transfers allowed");
    }


    function setMinTokensToGetReward(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount * (10**18);
    }

    function setBMEToken(address newaddress) external onlyOwner{
        BMEToken = newaddress;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function notExcludeFromCycel(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = false;
    }

    function iscanJoinCycel(address member) external onlyOwner {
      canJoinCycel[member] = true;
    }

    function cantJoinCycel(address account) external onlyOwner {
      canJoinCycel[account] = false;
    }

    function ExcludeFromCycel(address account) external onlyOwner {
      require(excludedFromDividends[account]);
      excludedFromDividends[account] = false;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 2592000, "BMETrackingToken: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "BMETrackingToken: Cannot update claimWait to same value");
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }



    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getStageStatus() external view returns(bool) {
        return stageRewardStatus;
    }

    function StartSeason(uint256 newStartTime ,uint256 newEndTime ) external onlyOwner{
        require(newStartTime > newEndTime, "BMETrackingToken: Time is not right ");
        StartTime = newStartTime;
        EndTime = newEndTime;
    }

    function SeasonTime() public view returns(uint256 ,uint256 ){

        return (StartTime ,EndTime );
    }

    function StartCycel(uint256 newStartTime ,uint256 newEndTime ) external onlyOwner{
        require(newStartTime > newEndTime, "BMETrackingToken: Time is not right ");
        StartCycelTime = newStartTime;
        EndCycelTime = newEndTime;
    }

    function CycelTime() public view returns(uint256 ,uint256 ){

        return (StartCycelTime ,EndCycelTime );
    }

    function StartCycel(uint256 newStartTime ,uint256 newEndTime ,uint256 newMinimumTokens ) external onlyOwner{
        require(newStartTime > newEndTime, "BMETrackingToken: Time is not right ");
        StartTime = newStartTime;
        EndTime = newEndTime;
        minimumTokenBalanceForDividends = newMinimumTokens;
    }



    function resetSeason() external onlyOwner returns (uint256) {
      uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
      MembersOnSeason = 0;
      if(numberOfTokenHolders == 0) {
        return 0;
      }

      while( 0 < numberOfTokenHolders) {
      uint256	deleteMember = tokenHoldersMap.keys.length;



        address account = tokenHoldersMap.keys[deleteMember];
        JoinedCycel[account] = false;
        tokenHoldersMap.remove(account);
        excludedFromDividends[account] = false;

    }
    return numberOfTokenHolders;
  }

    function UpdateCycel(uint256 newmaxmumCycelmembers,uint256 newtimeToBeOut) external onlyOwner{

        maxmumCycelmembers = newmaxmumCycelmembers;
        
        timeToBeOut = newtimeToBeOut;
    }

    function setStageOne(uint256 rewardAmount ,uint256 getRewardFrom ,uint256 getRewardTo ) external onlyOwner{
        require(getRewardTo >= getRewardFrom.add(rewardAmount), "BMETrackingToken: getRewardTo  must be higher than getRewardFrom with rewardAmount");
        stageOneReward = rewardAmount.div(1000);
        stageOneRewardFrom = getRewardFrom * (10**18);
        stageOneRewardTo = getRewardTo * (10**18);
    }
    function StageOne() public view returns (uint256 ,uint256 ,uint256 ){
        return (stageOneReward , stageOneRewardFrom ,stageOneRewardTo );
    }

    function setStageTwo(uint256 rewardAmount,uint256 getRewardFrom,uint256 getRewardTo) external onlyOwner{
        require(getRewardTo >= getRewardFrom.add(rewardAmount), "BMETrackingToken: getRewardTo  must be higher than getRewardFrom with rewardAmount");
        stageTwoReward = rewardAmount.div(1000);
        stageTwoRewardFrom = getRewardFrom * (10**18);
        stageTwoRewardTo = getRewardTo * (10**18);
    }
    function StageTwo() public view returns (uint256 ,uint256 ,uint256 ){
        return (stageTwoReward , stageTwoRewardFrom ,stageTwoRewardTo );
    }

    function setStageThree(uint256 rewardAmount ,uint256 getRewardFrom ,uint256 getRewardTo ) external onlyOwner{
        require(getRewardTo >= getRewardFrom.add(rewardAmount), "BMETrackingToken: getRewardTo  must be higher than getRewardFrom with rewardAmount");
        stageThreeReward = rewardAmount.div(1000);
        stageThreeRewardFrom = getRewardFrom * (10**18);
        stageThreeRewardTo = getRewardTo * (10**18);
    }

    function StageThree() public view returns (uint256 ,uint256 ,uint256 ){
        return (stageThreeReward , stageThreeRewardFrom ,stageThreeRewardTo );
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}
    	processAccount(account, true);

      if( StartTime <= block.timestamp && block.timestamp >= EndTime && newBalance >= minimumTokenBalanceForDividends){
      if( MembersOnSeason < maxmumCycelmembers ){
        MembersOnSeason = MembersOnSeason.add(1);
        JoinedCycel[account] = true;
        lastClaimTimes[account] = block.timestamp;

        }
      }
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
    		
    	if( StartTime >= block.timestamp && block.timestamp <= EndTime ){
    	    lastClaimTimes[account] = block.timestamp;
    	}	
    		
        if(JoinedCycel[account]){
        if(lastClaimTimes[account] < block.timestamp.add(timeToBeOut)) {
        if( !excludedFromDividends[account] ) {
    		if( canAutoClaim(lastClaimTimes[account]) ) {
    			if( processAccount(payable(account), true) ) {
    				claims++;
          			}
            
        		}
          }
        }
      }
      if( lastClaimTimes[account] > block.timestamp.add(timeToBeOut) ){
          excludedFromDividends[account] = true;
      }

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
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
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }


  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOfaccount(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividendstouser[user] = withdrawnDividends[user].add(_withdrawableDividend);
      bool success = IERC20(BMEToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function withdrawableDividendOfaccount(address account) public view returns(uint256) {
    int256 index = tokenHoldersMap.getIndexOfKey(account);

    if(index > 0){
    if( StartTime <= block.timestamp && block.timestamp >= EndTime ){
    if(lastClaimTimes[account].add(timeToBeOut) < block.timestamp){
    return  0;
    }

    if(stageOneRewardFrom <= balanceOf(account)  && balanceOf(account) >= stageOneRewardTo){

    return stageOneRewardFrom.mul(stageOneReward);

    }

    if(stageTwoRewardFrom <= balanceOf(account) && balanceOf(account) >= stageTwoRewardTo){

    return stageTwoRewardFrom.mul(stageTwoReward);

    }

    if(stageThreeRewardFrom <= balanceOf(account) && balanceOf(account) >= stageThreeRewardTo){

    return stageThreeRewardFrom.mul(stageThreeReward);

    }


    return  0;
      }
    }
  }

}