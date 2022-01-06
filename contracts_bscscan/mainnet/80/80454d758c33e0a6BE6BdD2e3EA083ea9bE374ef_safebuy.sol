// SPDX-License-Identifier: MIT
// o/
/*
  ______              ______            _______                      
 /      \            /      \          |       \                     
|  $$$$$$\  ______  |  $$$$$$\ ______  | $$$$$$$\ __    __  __    __ 
| $$___\$$ |      \ | $$_  \$$/      \ | $$__/ $$|  \  |  \|  \  |  \
 \$$    \   \$$$$$$\| $$ \   |  $$$$$$\| $$    $$| $$  | $$| $$  | $$
 _\$$$$$$\ /      $$| $$$$   | $$    $$| $$$$$$$\| $$  | $$| $$  | $$
|  \__| $$|  $$$$$$$| $$     | $$$$$$$$| $$__/ $$| $$__/ $$| $$__/ $$
 \$$    $$ \$$    $$| $$      \$$     \| $$    $$ \$$    $$ \$$    $$
  \$$$$$$   \$$$$$$$ \$$       \$$$$$$$ \$$$$$$$   \$$$$$$  _\$$$$$$$
                                                           |  \__| $$
                                                            \$$    $$
                                                             \$$$$$$ 
                                                              by Katowice(@Katerina_978)
                                                                    
*/
pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract safebuy is ERC20, Ownable {
//libs
    using SafeMath for uint256;
//custom
    IUniswapV2Router02 public uniswapV2Router;
    SafebuyDividendTracker public dividendTracker;
//address
    address public marketingWallet = 0xfc65d528038748500dad0BA5D5138e3DdFBC02D5;
    address public liquidityWallet = 0xBEDa307E861b94AB6506F1Fc0cb684B619eB00c7;
    address public developmentWallet = 0xBE2bf5FD18FC2c25B9e7C3f5EBD18Afe1ED2E7D6;


    address public uniswapV2Pair;
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
//bool
    bool public holdersSwapSendActive = true;
    bool public marketingSwapSendActive = true;
    bool public liquiditySwapSendActive = true;
    bool public developmentSwapSendActive = true;
    bool public swapAndLiquifyEnabled = true;
    bool public ProcessDividendStatus = true;
    bool public marketActive = false;
    bool public blockMultiBuys = true;
    bool public blockMultiSells = true;
    bool public limitSells = true;
    bool public limitBuys = true;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool public blacklistActive = true;
    bool public ProcessDividendSwap = true;
    bool private isInternalTransaction = false;
    bool private distribuited = false;
//uint256
    uint256 public buySecondsLimit = 3;
    uint256 public SellSecondsLimit = 5;
    uint256 public minimumWeiForTokenomics = 1 * 10**16; // 0.01 bnb
    uint256 public maxBuyTxAmount; 
    uint256 public maxSellTxAmount;
    uint256 public minimumTokensBeforeSwap = 20*10**13;
    uint256 public TokensToSwap = minimumTokensBeforeSwap;
    uint256 public intervalSecondsForSwap = 300;
    uint256 public BNBRewardsBuyFee = 2;
    uint256 public BNBRewardsSellFee = 4;
    uint256 public developmentBuyFee = 4;
    uint256 public developmentSellFee = 4;    
    uint256 public liquidityBuyFee = 2;
    uint256 public liquiditySellFee = 3;
    uint256 public marketingBuyFee = 4;
    uint256 public marketingSellFee = 4;
    uint256 public totalBuyFees = BNBRewardsBuyFee.add(liquidityBuyFee).add(marketingBuyFee).add(developmentBuyFee);
    uint256 public totalSellFees = BNBRewardsSellFee.add(liquiditySellFee).add(marketingSellFee).add(developmentSellFee);
    uint256 public gasForProcessing = 250000;
    uint256 private startTimeForSwap;
    uint256 private MarketActiveAt;
    
//struct
    struct userData {
        uint lastBuyTime;
        uint lastSellTime;
        uint totalSellAmount;
    }
//mapping
    mapping (address => bool) public blacklistAddress;
    mapping (address => bool) public premarketUser;
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => userData) public userLastTradeData;
//event
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped,uint256 amount);
    event ProcessedDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
//constructor
    constructor() public ERC20("Safebuy", "SBF") {
        uint256 _total_supply = 10000 * (10**15); //10000000000
    	dividendTracker = new SafebuyDividendTracker();
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        edit_excludeFromFees(owner(), true);
        edit_excludeFromFees(marketingWallet, true);
        edit_excludeFromFees(developmentWallet, true);
        edit_excludeFromFees(liquidityWallet, true);
        edit_excludeFromFees(address(this), true);
        premarketUser[owner()] = true;
        premarketUser[marketingWallet] = true;
        premarketUser[liquidityWallet] = true;
        premarketUser[developmentWallet] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), _total_supply);
        maxSellTxAmount = _total_supply / 500; // 0.2%
        maxBuyTxAmount = _total_supply / 50; // 2%
    }

    receive() external payable {

  	}

    function setSwapAndLiquify(bool _state, uint _intervalSecondsForSwap, uint _minimumTokensBeforeSwap, uint _tokenToSwap) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        intervalSecondsForSwap = _intervalSecondsForSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        TokensToSwap = _tokenToSwap;
    }
    function setSwapSend(bool _holders, bool _marketing, bool _liquidity, bool _dev) external onlyOwner {
        holdersSwapSendActive = _holders;
        marketingSwapSendActive = _marketing;
        liquiditySwapSendActive = _liquidity;
        developmentSwapSendActive = _dev;

    }
    function setProcessDividendStatus(bool _value1, bool _value2) external onlyOwner {
        ProcessDividendStatus = _value1;
        ProcessDividendSwap = _value2;
    }
    function setMultiBlock(bool buy, bool sell) external onlyOwner {
        blockMultiBuys = buy;
        blockMultiSells = sell;
    }
    function setFeesDetails(bool _feeStatus, bool _buyFeeStatus, bool _sellFeeStatus) external onlyOwner {
        feeStatus = _feeStatus;
        buyFeeStatus = _buyFeeStatus;
        sellFeeStatus = _sellFeeStatus;
    }
    function setMaxTxAmount(uint _buy, uint _sell) external onlyOwner {
        maxBuyTxAmount = _buy;
        maxSellTxAmount = _sell;
    }
    function setSecondLimits(uint buy, uint sell) external onlyOwner {
        buySecondsLimit = buy;
        SellSecondsLimit = sell;
    }
    function activateMarket(bool active) external onlyOwner {
        marketActive = active;
        if (marketActive) {
            MarketActiveAt = block.timestamp;
        }
    }
    function editLimits(bool buy, bool sell) external onlyOwner {
        limitSells = sell;
        limitBuys = buy;
    }
    function setMinimumWeiForTokenomics(uint _value) external onlyOwner {
        minimumWeiForTokenomics = _value;
    }

    function editPreMarketUser(address _address, bool active) external onlyOwner {
        premarketUser[_address] = active;
    }
    
    function transferForeignToken(address _token, address _to, uint256 _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        }
        _sent = IERC20(_token).transfer(_to, _value);
    }
   
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "Safebuy: The dividend tracker already has that address");

        SafebuyDividendTracker newDividendTracker = SafebuyDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "Safebuy: The new dividend tracker must be owned by the Safebuy token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Safebuy: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function edit_excludeFromFees(address account, bool excluded) public onlyOwner {
        excludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            excludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    function blacklistMultipleAccounts(address[] calldata accounts, bool _state) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            blacklistAddress[accounts[i]] = _state;
        }
    }

    function transferDividendOwnership(address _new) external onlyOwner {
        dividendTracker.transferOwnership(_new);
    }

    function disableBlacklistState() external onlyOwner {
        // there is no coming back after disabling blacklist.
        blacklistActive = false;
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        marketingWallet = wallet;
    }

    function setLiquidityWallet(address newWallet) external onlyOwner{
        liquidityWallet = newWallet;
    }
    function setDevelopmentWallet(address newWallet) external onlyOwner{
        developmentWallet = newWallet;
    }

    function setMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner{
        dividendTracker.setMinimumTokenBalanceForDividends(amount);
    }

    function setFees(uint256 _reward_buy, uint256 _liquidity_buy, uint256 _marketing_buy,
        uint256 _reward_sell,uint256 _liquidity_sell,uint256 _marketing_sell, uint _development_buy, uint _development_sell) external onlyOwner {
        BNBRewardsBuyFee = _reward_buy;
        BNBRewardsSellFee = _reward_sell;
        liquidityBuyFee = _liquidity_buy;
        liquiditySellFee = _liquidity_sell;
        developmentSellFee = _development_buy;
        developmentBuyFee = _development_sell;
        marketingBuyFee = _marketing_buy;
        marketingSellFee = _marketing_sell;
        totalBuyFees = BNBRewardsBuyFee.add(liquidityBuyFee).add(marketingBuyFee).add(developmentBuyFee);
        totalSellFees = BNBRewardsSellFee.add(liquiditySellFee).add(marketingSellFee).add(developmentSellFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Safebuy: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Safebuy: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Safebuy: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Safebuy: Cannot update gasForProcessing to same value");
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
        return excludedFromFees[account];
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
// operational functions
    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function swapTokens(uint256 tokensToSwap) private {
        isInternalTransaction = true;
        swapTokensForBNB(tokensToSwap);
        isInternalTransaction = false;
    }
    function sendDividends(uint256 rewardTokensToSwap, uint256 bnbForRewards) private{
        (bool success,) = address(dividendTracker).call{value: bnbForRewards}("");
        if(success) {
   	 		 emit SendDividends(rewardTokensToSwap, bnbForRewards);
        }
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
    //tx utility vars
        //uint
        uint256 trade_type = 0;
		uint256 contractTokenBalance = balanceOf(address(this));
		//bool
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
    // market status flag
        if(!marketActive) {
            require(premarketUser[from],"cannot trade before the market opening");
        }
    // normal transaction
        if(!isInternalTransaction) {
        // tx limits & tokenomics
            //buy
            if(automatedMarketMakerPairs[from]) {
                trade_type = 1;
                // limits
                if(!excludedFromFees[to]) {
                    // tx limit
                    if(limitBuys) {
                        require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                    }
                    // multi-buy limit
                    if(blockMultiBuys) {
                        require(MarketActiveAt + 3 < block.timestamp,"You cannot buy at launch.");
                        require(userLastTradeData[to].lastBuyTime + buySecondsLimit <= block.timestamp,"You cannot do multi-buy orders.");
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
            //sell
            else if(automatedMarketMakerPairs[to]) {
                trade_type = 2;
                // liquidity generator for tokenomics
                if (swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0) {
                    if (overMinimumTokenBalance && startTimeForSwap + intervalSecondsForSwap <= block.timestamp) {
                        startTimeForSwap = block.timestamp;
                        // sell to bnb
                        swapTokens(TokensToSwap);
                    }
                }
                // limits
                if(!excludedFromFees[from]) {
                    // tx limit
                    if(limitSells) {
                        require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                        // multi-sell limit
                        if(blockMultiSells) {
                            // reset
                            if(userLastTradeData[from].lastSellTime + SellSecondsLimit <= block.timestamp) {
                                userLastTradeData[from].totalSellAmount = 0;
                            }
                            userLastTradeData[from].totalSellAmount += amount;
                            require(userLastTradeData[from].totalSellAmount <= maxSellTxAmount,"Cannot do that yet.");
                            userLastTradeData[from].lastSellTime = block.timestamp;
                        }
                    }
                }
            }
            // tokenomics
            if(address(this).balance > minimumWeiForTokenomics) {
                //marketing
                if(marketingSwapSendActive) {
                    uint256 marketingTokens = minimumWeiForTokenomics.mul(marketingSellFee).div(totalSellFees);
                    (bool success,) = address(marketingWallet).call{value: marketingTokens}("");
                }
                //liquidity
                if(liquiditySwapSendActive) {
                    uint256 liquidityTokens = minimumWeiForTokenomics.mul(liquiditySellFee).div(totalSellFees);
                    (bool success,) = address(liquidityWallet).call{value: liquidityTokens}("");
                }
                //development
                if(developmentSwapSendActive) {
                    uint256 developmentTokens = minimumWeiForTokenomics.mul(developmentSellFee).div(totalSellFees);
                    (bool success,) = address(developmentWallet).call{value: developmentTokens}("");
                }
                //holders
                if(holdersSwapSendActive) {
                    uint256 holdersTokens = minimumWeiForTokenomics.mul(BNBRewardsSellFee).div(totalSellFees);
                    (bool success,) = address(dividendTracker).call{value: holdersTokens}("");
                }
            }
        // fees management
            if(feeStatus) {
                // blacklist, can be disabled and cannot be enabled again
                if(blacklistActive) {
                    if(trade_type == 0 || trade_type == 2) {
                        require(!blacklistAddress[from],"your account is locked");
                    }
                }
                // wallet to wallet
                // not a real fee, we check if the user is trying to bypass the sell limit, if active
                if(trade_type == 0 && blockMultiSells && !excludedFromFees[from]) {
                    if(userLastTradeData[from].lastSellTime + SellSecondsLimit > block.timestamp ||
                       userLastTradeData[to].lastSellTime + SellSecondsLimit > block.timestamp ) {
                        require(userLastTradeData[from].totalSellAmount <= maxSellTxAmount && 
                                userLastTradeData[to].totalSellAmount <= maxSellTxAmount,"Cannot do that yet.");
                    }
                }
                // buy
                else if(trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                	uint txFees = amount * totalBuyFees / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                //sell
                else if(trade_type == 2 && sellFeeStatus && !excludedFromFees[from]) {
                	uint txFees = amount * totalSellFees / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
            }
        }
        // transfer tokens
        super._transfer(from, to, amount);
        //set dividends
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        // auto-claims one time per transaction
        if(!isInternalTransaction && ProcessDividendStatus) {
	    	uint256 gas = gasForProcessing;
	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} catch {}
        }
    }

    function PrivateSaleDistribution(address[] memory _address, uint256[] memory _amount) public onlyOwner { //can only be used once
        if(!distribuited){
            for(uint i=0; i< _amount.length; i++){
                address adr = _address[i];
                uint amnt = _amount[i] *10**9;
                super._transfer(owner(), adr, amnt);
            }
            distribuited = true; 
        }
    }

}



contract SafebuyDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public  minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("Safebuy_Dividen_Tracker", "Safebuy_Dividend_Tracker") {
    	claimWait = 21500;
        minimumTokenBalanceForDividends = 10000 * (10**9);//10 * (10**9);
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "Safebuy_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(false, "Safebuy_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Safebuy contract.");
    }

    function setMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner{
        minimumTokenBalanceForDividends = amount * 10**9;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "Safebuy_Dividend_Tracker: claimWait must be updated to between 20 mins and 24 hours");
        require(newClaimWait != claimWait, "Safebuy_Dividend_Tracker: Cannot update claimWait to same value");
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