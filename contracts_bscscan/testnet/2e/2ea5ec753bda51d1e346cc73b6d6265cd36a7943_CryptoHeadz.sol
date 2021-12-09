// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract CryptoHeadz is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;
	 bool public swapAndLiquifyEnabled = true;

    CHDZDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
	address payable public marketingWalletAddress = 0x2B47bD4E92d24233A0D2c8b410578FFEA0151f9E;
	address payable public developmentWalletAddress = 0xfa0A51256d0A2436e62B3e0E8561FCfEE93aeEE6;
    address public BUSD = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); //BUSD

    uint256 public swapTokensAtAmount = 100000000000 * (10**4);
	uint256 public maxTxAmount = 10000000000000 * (10**4);
	uint256 public maxWalletAmount = 30000000000000 * (10**4);
	
	uint256[] public BUSDRewardsFee;
	uint256[] public liquidityFee;
	uint256[] public marketingFee;
	uint256[] public developmentFee;
	
	uint256 private tokenToSwap;
	uint256 private tokenToMarketing;
	uint256 private tokenToDevelopment;
	uint256 private tokenToLiqudity;
	uint256 private tokenToReward;
	uint256 private tokenToLiqudityHalf;
	
	uint256 public BUSDRewardsFeeTotal;
	uint256 public liquidityFeeTotal;
	uint256 public marketingFeeTotal;
	uint256 public developmentFeeTotal;
	
    bool public hotelCaliforniaMode = false;
	bool public tradingOpen = false;
	
    uint256 public deadBlocks = 8;
    uint256 public launchedAt = 0;
	
	uint256 public maxRoomRent = 8000000000;
    uint256 public gasForProcessing = 300000;

    mapping (address => bool) private _isExcludedFromFees;
	mapping (address => bool) public isExcludedFromMaxWalletToken;
	mapping (address => bool) public isHouseguest;
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public canTransferBeforeTradingIsEnabled;

    event CaliforniaCheckin(address guest, uint256 rentPaid);
	event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor() public ERC20("CryptoHeadz", "CHDZ") {

    	dividendTracker = new CHDZDividendTracker();
		
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
		
		isExcludedFromMaxWalletToken[_uniswapV2Pair] = true;
		isExcludedFromMaxWalletToken[address(this)] = true;
		isExcludedFromMaxWalletToken[owner()] = true;

        excludeFromFees(owner(), true);
        excludeFromFees(marketingWalletAddress, true);
        excludeFromFees(address(this), true);
		
		canTransferBeforeTradingIsEnabled[owner()] = true;
		
		BUSDRewardsFee.push(500);
		BUSDRewardsFee.push(500);
		BUSDRewardsFee.push(500);
		
		liquidityFee.push(300);
		liquidityFee.push(300);
		liquidityFee.push(300);
		
		marketingFee.push(500);
		marketingFee.push(500);
		marketingFee.push(500);
		
		developmentFee.push(200);
		developmentFee.push(200);
		developmentFee.push(200);
		
        _mint(owner(), 1000000000000000 * (10**4));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "CHDZ: The dividend tracker already has that address");
        CHDZDividendTracker newDividendTracker = CHDZDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "CHDZ: The new dividend tracker must be owned by the CHDZ token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "CHDZ: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "CHDZ: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        marketingWalletAddress = wallet;
    }
	
	function setDevelopmentWallet(address payable wallet) external onlyOwner{
        developmentWalletAddress = wallet;
    }

    function setBUSDRewardsFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        BUSDRewardsFee[0] = buy;
		BUSDRewardsFee[0] = sell;
		BUSDRewardsFee[0] = p2p;
    }
	
    function setLiquiditFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        liquidityFee[0] = buy;
		liquidityFee[0] = sell;
		liquidityFee[0] = p2p;
    }
	
    function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        marketingFee[0] = buy;
		marketingFee[0] = sell;
		marketingFee[0] = p2p;
    }
	
	function setDevelopmentFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner{
        developmentFee[0] = buy;
		developmentFee[0] = sell;
		developmentFee[0] = p2p;
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "CHDZ: The PanCakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "CHDZ: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "CHDZ: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "CHDZ: Cannot update gasForProcessing to same value");
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
	
	function excludeFromMaxWalletToken(address account, bool excluded) public onlyOwner {
        require(isExcludedFromMaxWalletToken[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromMaxWalletToken[account] = excluded;
    }
	
	function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
    }
	
	function setMaxTxAmount(uint256 amount) external onlyOwner() {
		maxTxAmount = amount;
	}
	
	function setMaxWalletAmount(uint256 amount) public onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		maxWalletAmount = amount;
	}
	
	function updateHotelCaliforniaMode(bool enabled) public onlyOwner {
        hotelCaliforniaMode = enabled;
    }
	
	function updateMaxRoomRent(uint256 newRent) public onlyOwner {
        maxRoomRent = newRent;
    }
	
	function updateHouseGuests(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isHouseguest[addresses[i]] = status;
        }
    }
	
    function tradingStatus(bool enabled) public onlyOwner {
        tradingOpen = enabled;
        if(tradingOpen && launchedAt == 0){
            launchedAt = block.number;
        }
    }
	
	function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(canTransferBeforeTradingIsEnabled[account] != allowed, "Pre trading is already the value of 'excluded'");
        canTransferBeforeTradingIsEnabled[account] = allowed;
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
	
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		
		if(!tradingOpen) 
		{
		    require(canTransferBeforeTradingIsEnabled[from] && canTransferBeforeTradingIsEnabled[to], "Trading not open yet");
		}
		
		if(from != owner() && to != owner()) {
		   require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		}
		
		if(!isExcludedFromMaxWalletToken[to] && !automatedMarketMakerPairs[to]) {
            uint256 balanceRecepient = balanceOf(to);
            require(balanceRecepient + amount <= maxWalletAmount, "Exceeds maximum wallet token amount");
        }
		
		if(hotelCaliforniaMode){
            require(!isHouseguest[from],"Bots cant sell");
            if(tx.gasprice > maxRoomRent && automatedMarketMakerPairs[from]){
                isHouseguest[to] = true;
                emit CaliforniaCheckin(to, tx.gasprice);
            }
        }
		
		uint256 contractTokenBalance = balanceOf(address(this));
		if(contractTokenBalance >= maxTxAmount) 
		{
			contractTokenBalance = maxTxAmount;
		}
		
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if( canSwap && !swapping && automatedMarketMakerPairs[to] && swapAndLiquifyEnabled) {
            swapping = true;
			tokenToSwap;
            tokenToMarketing    = marketingFeeTotal;
			tokenToDevelopment  = developmentFeeTotal;
			tokenToLiqudity     = liquidityFeeTotal;
			tokenToReward       = BUSDRewardsFeeTotal;
			tokenToLiqudityHalf = tokenToLiqudity.div(2);
			
			tokenToSwap = tokenToMarketing.add(tokenToDevelopment).add(tokenToReward).add(tokenToLiqudityHalf);
			
			uint256 initialBalance = address(this).balance;
			swapTokensForBNB(swapTokensAtAmount);
			uint256 newBalance = address(this).balance.sub(initialBalance);
			
			uint256 marketingPart   = newBalance.mul(tokenToMarketing).div(tokenToSwap);
			uint256 developmentPart = newBalance.mul(tokenToDevelopment).div(tokenToSwap);
			uint256 liqudityPart    = newBalance.mul(tokenToLiqudityHalf).div(tokenToSwap);
			uint256 rewardPart      = newBalance.sub(marketingPart).sub(developmentPart).sub(liqudityPart);

			if(marketingPart > 0) {
			   payable(marketingWalletAddress).transfer(marketingPart);
			}
			
			if(developmentPart > 0) {
			   payable(developmentWalletAddress).transfer(developmentPart);
			}
			
			if(liqudityPart > 0) {
			    addLiquidity(swapTokensAtAmount.mul(tokenToLiqudityHalf).div(tokenToSwap), liqudityPart);
			}
			
			if(rewardPart > 0) {
			    swapAndSendDividends(rewardPart);
			}
			marketingFeeTotal   = marketingFeeTotal.sub(swapTokensAtAmount.mul(tokenToMarketing).div(tokenToSwap));
		    developmentFeeTotal = developmentFeeTotal.sub(swapTokensAtAmount.mul(tokenToDevelopment).div(tokenToSwap));
		    liquidityFeeTotal   = liquidityFeeTotal.sub((swapTokensAtAmount.mul(tokenToLiqudityHalf).div(tokenToSwap)).mul(2));
		    BUSDRewardsFeeTotal = BUSDRewardsFeeTotal.sub(swapTokensAtAmount.mul(tokenToReward).div(tokenToSwap));
            swapping = false;
        }
		
        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) 
		{
            takeFee = false;
        }
		
		if(takeFee) 
		{
		    if(!automatedMarketMakerPairs[to] && (launchedAt + deadBlocks) > block.number)
			{
			    uint256 fees = amount.mul(99).div(100);
			    if(!automatedMarketMakerPairs[from])
				{
				    uint256 totalFee = BUSDRewardsFee[2].add(liquidityFee[2]).add(marketingFee[2]).add(developmentFee[2]);
					
					uint256 rewardFeeNew = fees.mul(BUSDRewardsFee[2]).div(totalFee);
					BUSDRewardsFeeTotal = BUSDRewardsFeeTotal.add(rewardFeeNew);
					
					uint256 liquidityFeeNew = fees.mul(liquidityFee[2]).div(totalFee);
					liquidityFeeTotal = liquidityFeeTotal.add(liquidityFeeNew);
					
					uint256 marketingFeeNew = fees.mul(marketingFee[2]).div(totalFee);
					marketingFeeTotal = marketingFeeTotal.add(marketingFeeNew);
					
					uint256 developmentFeeNew = fees.mul(developmentFee[2]).div(totalFee);
					developmentFeeTotal = developmentFeeTotal.add(developmentFeeNew);
				}
				else
				{
				    uint256 totalFee = BUSDRewardsFee[0].add(liquidityFee[0]).add(marketingFee[0]).add(developmentFee[0]);
					
					uint256 rewardFeeNew = fees.mul(BUSDRewardsFee[0]).div(totalFee);
					BUSDRewardsFeeTotal = BUSDRewardsFeeTotal.add(rewardFeeNew);
					
					uint256 liquidityFeeNew = fees.mul(liquidityFee[0]).div(totalFee);
					liquidityFeeTotal = liquidityFeeTotal.add(liquidityFeeNew);
					
					uint256 marketingFeeNew = fees.mul(marketingFee[0]).div(totalFee);
					marketingFeeTotal = marketingFeeTotal.add(marketingFeeNew);
					
					uint256 developmentFeeNew = fees.mul(developmentFee[0]).div(totalFee);
					developmentFeeTotal = developmentFeeTotal.add(developmentFeeNew);
				}
				amount = amount.sub(fees);
				super._transfer(from, address(this), fees);
			}
			else
			{
			    uint256 allfee;
				allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
				super._transfer(from, address(this), allfee);
				amount = amount.sub(allfee);
			}
		}
		
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
		
        if(!swapping) 
		{
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) 
			{
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch 
			{

	    	}
        }
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 totalFee;
		
        uint256 rewardFeeNew = amount.mul(p2p ? BUSDRewardsFee[2] : sell ? BUSDRewardsFee[1] : BUSDRewardsFee[0]).div(10000);
		BUSDRewardsFeeTotal = BUSDRewardsFeeTotal.add(rewardFeeNew);
		
		uint256 liquidityFeeNew = amount.mul(p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]).div(10000);
		liquidityFeeTotal = liquidityFeeTotal.add(liquidityFeeNew);
		
		uint256 marketingFeeNew = amount.mul(p2p ? marketingFee[2] : sell ? marketingFee[1] : marketingFee[0]).div(10000);
		marketingFeeTotal = marketingFeeTotal.add(marketingFeeNew);
		
		uint256 developmentFeeNew = amount.mul(p2p ? developmentFee[2] : sell ? developmentFee[1] : developmentFee[0]).div(10000);
		developmentFeeTotal = developmentFeeTotal.add(developmentFeeNew);
		
		totalFee = rewardFeeNew.add(liquidityFeeNew).add(marketingFeeNew).add(developmentFeeNew);
        return totalFee;
    }
	
    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
	
    function swapBNBForBUSD(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BUSD;
        _approve(address(this), address(uniswapV2Router), bnbAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(bnbAmount, 0, path, address(this), block.timestamp);
    }
	
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }
	
    function swapAndSendDividends(uint256 bnb) private{
        swapBNBForBUSD(bnb);
        uint256 dividends = IERC20(BUSD).balanceOf(address(this));
        bool success = IERC20(BUSD).transfer(address(dividendTracker), dividends);
        if (success) {
            dividendTracker.distributeBUSDDividends(dividends);
        }
    }
	
	function migrateBNB(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }
}

contract CHDZDividendTracker is Ownable, DividendPayingToken {
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

    constructor() public DividendPayingToken("CHDZ_Dividen_Tracker", "CHDZ_Dividend_Tracker") {
    	claimWait = 3600;
        minimumTokenBalanceForDividends = 1000000 * (10**4); //must hold 1000000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "CHDZ_Dividend_Tracker: No transfers allowed");
    }
	
    function withdrawDividend() public override {
        require(false, "CHDZ_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main CHDZ contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "CHDZ_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "CHDZ_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
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
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
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