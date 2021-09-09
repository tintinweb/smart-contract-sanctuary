// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract BeTest is ERC20, Ownable {
    using SafeMath for uint256;

	bool public tradingEnabled = false;
    bool private swapping;

	//Limits
    uint256 public maxTransactionAmount = 1 * 10**14 * (10**9); // 10% for Testing. Set to 0.2% for live 2 * 10**9 * (10**9)
    uint256 public swapTokensAtAmount = 1 * 10**9 * (10**9); //0.01% - threshold balance

	//set fees
    uint256 public BNBRewardsFee = 7;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 2;
    uint256 public BuyBackAndBurnFee = 2;
    uint256 public fundraisingFee = 2;
    
    uint256 public totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee).add(BuyBackAndBurnFee).add(fundraisingFee);

	//Set Addresses.
    address public _marketingWallet = 0xE47C4294d995612593d0bf4A378A3d7E19058141;
    address public _fundraiseWallet = 0x28b832c4bf78Eb812755D439617f820c5B51BbEf;
	address public _deadWallet = 0x000000000000000000000000000000000000dEaD;

	//Liquidity
	bool public _enableLiquidity = false; // Controls whether the contract will swap tokens
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

	//Buy Back
    bool    public _buybackEnabled        = false; 				// Disabled on deployment
    uint256 public _buybackBNBThreshold  = 1 * 10**18; 			// 1 BNB will be required to be inside the contract before a buyback will be performed
    uint256 public _buybackUpperLimit    = 1 * 10**9 * 10**9;	// 1 billion will be used to buy at maximum in any one trade TODO: This might have to be 1**18 <- check. Also check BNB.
    uint256 public _buybackBNBPercentage = 1; 					// 1% of BNB is used to buyback tokens
	uint256 private boughtBack = 0; // block number, prevent multiple autobuybacks in one block
	uint256 public _autoBuybackBlockPeriod;

    BTv1DividendTracker public dividendTracker;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

	// addresses that can make transfers before trading is enabled
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

	// address that are blacklisted. Add known bots to this list prior to presale finalise.
    mapping(address => bool) public _isBlacklisted;

    event UpdateTradingStatus(bool status);
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() public ERC20("BeTest", "BTv1") {

    	dividendTracker = new BTv1DividendTracker();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //https://pancake.kiemtienonline360.com/#/swap //0x10ED43C718714eb63d5aA57B78B54704E256024E
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(_deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWallet, true);
		excludeFromFees(_fundraiseWallet, true);
        excludeFromFees(address(this), true);
		
		canTransferBeforeTradingIsEnabled[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000000000 * (10**9));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "DivTrack: already has address");

        BTv1DividendTracker newDividendTracker = BTv1DividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "DivTrack: must be owned by Rama4 contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "DivTrack: The router has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setSwapTokensAtAmount(uint256 _newAmount) public onlyOwner {
        swapTokensAtAmount = _newAmount;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "DivTrack: Account is already excluded");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    
    function setMaxTransactionAmount(uint256 maxTxAmount) external onlyOwner() {
        maxTransactionAmount = maxTxAmount;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWallet = wallet;
    }

    function setFundraisingWallet(address payable wallet) external onlyOwner{
        _fundraiseWallet = wallet;
    }

    function setCanTransferBeforeTradingIsEnabled(address account, bool status) external onlyOwner {
        canTransferBeforeTradingIsEnabled[account] = status;
    }

    function setBNBRewardsFee(uint256 value) external onlyOwner{
        BNBRewardsFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee).add(BuyBackAndBurnFee).add(fundraisingFee);
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee).add(BuyBackAndBurnFee).add(fundraisingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee).add(BuyBackAndBurnFee).add(fundraisingFee);

    }
    
    function setFundraisingFee(uint256 value) external onlyOwner{
        fundraisingFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee).add(BuyBackAndBurnFee).add(fundraisingFee);

    }
    
    function setBuyBackAndBurnFee(uint256 value) external onlyOwner{
        BuyBackAndBurnFee = value;
        totalFees = BNBRewardsFee.add(liquidityFee).add(marketingFee).add(BuyBackAndBurnFee).add(fundraisingFee);

    }

	//supporting BuyBack functions
	function setBuybackEnabled(bool value) external onlyOwner() {
        _buybackEnabled = value;
    }
    
    function setBuybackBNBThreshold(uint256 bnbAmount) external onlyOwner() {
        _buybackBNBThreshold = bnbAmount;
    }
    
    function setBuybackUpperLimit(uint256 buybackLimit) external onlyOwner() {
        _buybackUpperLimit = buybackLimit;
    }
    
	function set_BuybackBlockPeriod(uint256 buyBackBlockPeriod) external onlyOwner() {
        _autoBuybackBlockPeriod = buyBackBlockPeriod;
    }
	
	
    function setBuybackBNBPercentage(uint256 percentage) external onlyOwner() {
        _buybackBNBPercentage = percentage;
    }
	//end supporting buybacks

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "DivTrack: can't remove PS pair from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "DivTrack: Automatedmarketmakerpair already that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 900000, "DivTrack: gasForProcessing 200,000 >< 500,000");
        require(newValue != gasForProcessing, "DivTrack: Cannot update gasForProcessing to same");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
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
        return dividendTracker.getAccount(account);
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
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setTradingIsEnabled(bool status) external onlyOwner {
        tradingEnabled = status;
        emit UpdateTradingStatus(status);
    }


    function _transfer( address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
		require(amount > 0, "Transfer amount must be greater than zero");
		        
		// Only the owner of this contract can bypass the max transfer amount
        if(from != owner() && to != owner()) {
            require(amount <= maxTransactionAmount, "Transfer exceeds maxTxAmount.");
        }

        if(!tradingEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "BTv1: This account cannot send tokens until trading is enabled");
        }

		//Get contract Balance
		uint256 contractTokenBalance = balanceOf(address(this));

		//confirm able to swap
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

		if( 
			canSwap &&
			!swapping && //not already in auto swap
			!automatedMarketMakerPairs[from] && //SELLING (not buys) to == uniswapV2Pair
			from != owner() && to != owner() &&
			to != _deadWallet			
			) {
            
			swapping = true;

			//SELL: swap to marketing
            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFeeAddress(_marketingWallet, marketingTokens);
            
			//SELL: swap to fundraisi
            uint256 FundraisingTokens = contractTokenBalance.mul(fundraisingFee).div(totalFees);
            swapAndSendToFeeAddress(_fundraiseWallet, FundraisingTokens);
			
			//SELL - Add to liquidity
            if (_enableLiquidity) {
				uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
				swapAndLiquify(swapTokens);
			}

    		//SELL - Dividend tracker recieves coins for holder rewards
    		uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);
			
			//SELL - Contract receives bnb for BuyBack
			uint256 bbTokens = contractTokenBalance.mul(BuyBackAndBurnFee).div(totalFees);
			swapTokensForEth(bbTokens);

            swapping = false;

			// BuyBack and Burn
			if (_buybackEnabled && !swapping  && boughtBack + _autoBuybackBlockPeriod <= block.number) {
				uint256 balance = address(this).balance;
				
				// Only execute a buyback when the contract has more than 1.0 BNB
				if (balance > _buybackBNBThreshold) {
					if (balance >= _buybackUpperLimit) {
						balance = _buybackUpperLimit;
					}
					
					// Buy back tokens with 1% of the BNB inside the contract
					buyBackTokens(balance.mul(_buybackBNBPercentage).div(100));
					
					boughtBack = block.number; // prevent flash attack buyback drain
				}
			}		
		}

        bool takeFee = !swapping;
		
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if(takeFee) {
		
        	uint256 fees = amount.mul(totalFees).div(100);
			
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).div(100);
        	}
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

		//no fees
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFeeAddress(address receiver, uint256 tokens) private {

        uint256 initialBNBBalance = address(this).balance;

        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialBNBBalance);
        payable(receiver).transfer(newBalance);
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
        swapTokensForEth(half); 

		// how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

		// add liquidity to uniswap
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 dividends = (address(this).balance).sub(initialBalance);
		if (dividends > 0) {
        // sends the dividends to distributor contract
        (bool success,) = address(dividendTracker).call{value: dividends}("");
 
        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
        }

    }
     
    //Buys tokens using the contract balance   
    function buyBackTokens(uint256 amount) private {
    	if (amount > 0) {
    	    swapBNBForTokens(amount);
			boughtBack = block.number;
	    }
    }
	
	// Swaps BNB for tokens and immedietely burns them
    function swapBNBForTokens(uint256 amount) private {
		// generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of RAMA4
            path,
            _deadWallet, // Burn address
            block.timestamp.add(300)
        );
    }
	
	//No purpose other than dealing with people who have sent non BTv1 tokens.
	function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    
    //Manual buyback and burn. Typically used when buyback turned off, but not enforced.
    function FeedTheBeast(uint256 amount) external onlyOwner {
        buyBackTokens(amount);
    }
	
	//enable liquidity on off
	function setLiquidity(bool value) external onlyOwner() {
        _enableLiquidity = value;
    }
	
    
}

contract BTv1DividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("BTv1_Dividen_Tracker", "BTv1_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**9); //must hold 200000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "BTv1_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "DivTrack: withdrawDividend disabled. Use the 'claim' function on main contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DivTrack: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "DivTrack: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }


    function WithdrawStuckBalance(uint256 amountPercentage, address Receiver) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(Receiver).transfer(amountBNB * amountPercentage / 100);
    }
    
    function WithdrawStuckERC20Token(uint256 amountPercentage, address TokenAddress, address Receiver) external onlyOwner{
        uint256 amountERC20 = IERC20(TokenAddress).balanceOf(address(this));
        IERC20(TokenAddress).transfer(Receiver, amountERC20 * amountPercentage / 100);
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

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

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