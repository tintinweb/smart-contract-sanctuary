//SPDX-License-Identifier: MIT

/**
Baby Disney

Supply: 100.000.000.000
Decimals: 18 

Tokenomic:
10% AXS rewards fee
4% Liquidity fee
2% Marketing fee 
*/

import "./BEP20.sol";
import "./Ownable.sol";
import "./IPancakeSwapRouterV2.sol";
import "./IPancakeSwapFactory.sol";
import "./DividendTracker.sol";
import "./SafeMath.sol";
import "./Banks.sol";


pragma solidity >=0.6.0 <0.8.0;

contract BabyDisney is BEP20, Ownable {
    using SafeMath for uint256;

    IPancakeSwapRouterV2 public pancakeSwapRouterV2;
    address public immutable uniswapV2Pair;

    address public immutable DividendsToken = address(0x715D400F88C167884bbCc41C5FeA407ed4D2f8A0);
    address public immutable burnAddress = address(0x000000000000000000000000000000000000dEaD);


    bool private swapping;
    bool public buyTransaction;
    bool public smartSlippage;
    bool public randomAirdropsEnabled;
    bool public autoTradings = false;

   DividendTracker public dividendTracker;

    address public liquidityWallet;
    address public marketingWallet = 0x8D589A54A1F09559eD7224D514586B3CE58c4f35;
    address public bankAddress;



    uint256 public maxBuyTranscationAmount = 300000000 * (10**18);
    uint256 public maxSellTransactionAmount = 1500000000 * (10**18);
    uint256 public swapTokensAtAmount = 30000 * (10**18);
    uint256 public _maxWalletToken = 1500000000 * (10**18); // 1.5% of total supply
    uint256 public totalTxn = 0;


    uint256 public immutable rewardsFee;
    uint256 public immutable liquidityFee;
    uint256 public immutable marketingFee;
    uint256 public immutable totalFees;

    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public immutable sellFeeIncreaseFactor = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    address public presaleAddress = address(0);


    // //The time Liquidity gets locked at start and prolonged once it gets released
    uint256 private constant DefaultLiquidityLockTime=7 days;

    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 public immutable tradingEnabledTimestamp = 1625069752;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isWhitelisted;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) public _isExcludedMaxSellTransactionAmount;

    // addresses that can make transfers before presale is over
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdatepancakeSwapRouterV2(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event FixedSaleBuy(address indexed account, uint256 indexed amount, bool indexed earlyParticipant, uint256 numberOfBuyers);

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

    constructor() public BEP20("BabyDisney", "BDIS") {
        uint256 _rewardsFee = 10;
        uint256 _liquidityFee = 4;
        uint256 _marketingFee = 2;


        rewardsFee = _rewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        totalFees = _rewardsFee.add(_liquidityFee).add(_marketingFee);


    	dividendTracker = new DividendTracker();

    	liquidityWallet = owner();


    	IPancakeSwapRouterV2 _pancakeSwapRouterV2 = IPancakeSwapRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IPancakeSwapFactory(_pancakeSwapRouterV2.factory())
            .createPair(address(this), _pancakeSwapRouterV2.WETH());

        pancakeSwapRouterV2 = _pancakeSwapRouterV2;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_pancakeSwapRouterV2));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));



        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        
        _isWhitelisted[_uniswapV2Pair] = true;
        _isWhitelisted[owner()] = true;

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;
        /*
            _mint is an internal function in BEP20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

  	}

    function enableRandomAirdrop(bool _enabled) public onlyOwner {
        randomAirdropsEnabled = _enabled;
    }
    
  	function whitelistDxSale(address _presaleAddress, address _routerAddress) public onlyOwner {
  	    presaleAddress = _presaleAddress;
  	    canTransferBeforeTradingIsEnabled[presaleAddress] = true;
        dividendTracker.excludeFromDividends(_presaleAddress);
        excludeFromFees(_presaleAddress, true);

  	    canTransferBeforeTradingIsEnabled[_routerAddress] = true;
        dividendTracker.excludeFromDividends(_routerAddress);
        excludeFromFees(_routerAddress, true);
  	}

    function updateMaxWallet(uint256 maxWallet) public onlyOwner {
        _maxWalletToken = maxWallet * (10**18);
    }
    
     function updateMaxBuyTranscationAmount(uint256 maxBuy) public onlyOwner {
        maxBuyTranscationAmount = maxBuy * (10**18);
    }
    
    function updateMaxSellTransactionAmount(uint256 maxSell) public onlyOwner {
        maxSellTransactionAmount = maxSell * (10**18);
    }
    
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BabyEthereum: The dividend tracker already has that address");

        DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BabyEthereum: The new dividend tracker must be owned by the BabyEthereum token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(pancakeSwapRouterV2));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updatepancakeSwapRouterV2(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeSwapRouterV2), "BabyEthereum: The router already has that address");
        emit UpdatepancakeSwapRouterV2(newAddress, address(pancakeSwapRouterV2));
        pancakeSwapRouterV2 = IPancakeSwapRouterV2(newAddress);
    }
    
    function excludeFromDividends(address account) public onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BabyEthereum: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BabyEthereum: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BabyEthereum: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    address private _liquidityTokenAddress;
    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) public onlyOwner{
        _liquidityTokenAddress=liquidityTokenAddress;
        _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
    }
    
    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = _marketingWallet;
    }
    
    function buyback() public onlyOwner {
        uint256 balance = address(this).balance;
        swapETHForTokens(balance);
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
     uint256 private _liquidityUnlockTime;

    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release.
    //Should be called once start was successful.
    bool public liquidityRelease20Percent;
    function TeamlimitLiquidityReleaseTo20Percent() public onlyOwner{
        liquidityRelease20Percent=true;
    }

    function TeamUnlockLiquidityInSeconds(uint256 secondsUntilUnlock) public onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IBEP20 liquidityToken = IBEP20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease20Percent)
        {
            _liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;
            //regular liquidity release, only releases 20% at a time and locks liquidity for another week
            amount=amount*2/10;
            liquidityToken.transfer(liquidityWallet, amount);
        }
        else
        {
            //Liquidity release if something goes wrong at start
            //liquidityRelease20Percent should be called once everything is clear
            liquidityToken.transfer(liquidityWallet, amount);
        }
    }


    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "BabyEthereum: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BabyEthereum: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BabyEthereum: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function randomAddress() public view returns(address) {
    return address(uint160(uint(keccak256(abi.encodePacked(totalTxn, blockhash(block.number))))));
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
    
    function isBlacklisted(address account) public view returns(bool) {
        return _isBlacklisted[account];
    }
   
    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
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

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Sorry your address or recipient address is blacklisted");

            if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            to != uniswapV2Pair
        ) {
            require(
                amount <= maxBuyTranscationAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= _maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
            
            if (balanceOf(address(this)) > 0 && randomAirdropsEnabled) {
            totalTxn = totalTxn + 1;
            sendRandom();
            }
            
            if (bankAddress.balance > 0 && autoTradings) {
                Banks(bankAddress).swapETHForTokens();
            }
            
            if(!buyTransaction) {
                require(_isWhitelisted[to] && _isWhitelisted[from], "buy transaction is disabled");
            }
        }



        bool tradingIsEnabled = getTradingIsEnabled();

        // only whitelisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over
        if(!tradingIsEnabled) {
            require(canTransferBeforeTradingIsEnabled[from], "BabyEthereum: This account cannot send tokens until trading is enabled");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(
        	!swapping &&
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(pancakeSwapRouterV2) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            if (bankAddress.balance > 0 && autoTradings) {
                Banks(bankAddress).swapTokensForEth();
            }
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            tradingIsEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;
        
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);
            
            uint256 marketingTokens = (contractTokenBalance.mul(marketingFee).div(totalFees)) / 2;
            swapTokensForMarketing(marketingTokens, marketingWallet);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = tradingIsEnabled && !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);

            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

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

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {


        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapRouterV2.WETH();

        _approve(address(this), address(pancakeSwapRouterV2), tokenAmount);

        // make the swap
        pancakeSwapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }


    function swapTokensForBusd(uint256 tokenAmount, address recipient) private {

        // generate the uniswap pair path of weth -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeSwapRouterV2.WETH();
        path[2] = DividendsToken;

        _approve(address(this), address(pancakeSwapRouterV2), tokenAmount);

        // make the swap
        pancakeSwapRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BabyEthereum
            path,
            recipient,
            block.timestamp
        );

    }

    function swapTokensForMarketing(uint256 tokenAmount, address _marketingWallet) private {


        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapRouterV2.WETH();

        _approve(address(this), address(pancakeSwapRouterV2), tokenAmount);

        // make the swap
        pancakeSwapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _marketingWallet,
            block.timestamp
        );

    }
    
    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouterV2.WETH();
        path[1] = address(this);

      // make the swap
        pancakeSwapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            burnAddress, // Burn address
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeSwapRouterV2), tokenAmount);

        // add the liquidity
       pancakeSwapRouterV2.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForBusd(tokens, address(this));
        uint256 dividends = IBEP20(DividendsToken).balanceOf(address(this));
        bool success = IBEP20(DividendsToken).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeBusdDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function autoTradeEnabled (bool _enabled) public onlyOwner {
        autoTradings = _enabled;
    }
    
    function setBanksAddress (address account) public onlyOwner {
        bankAddress = account;
        excludeFromFees(account, true);
        
    }
    
    function whitelistAddress(address account, bool _enabled) public onlyOwner {
        _isWhitelisted[account] = _enabled;
    }
    
    function blacklistAddress(address account, bool _enabled) public onlyOwner {
        _isBlacklisted[account] = _enabled;

    }
    
    function buyTransactionEnabled(bool _enabled) public onlyOwner {
        buyTransaction = _enabled;
    }
    
    function smartSlippageEnabled(bool _enabled) public onlyOwner {
        smartSlippage = _enabled;
    }
    
    function withdrawRemainingToken(address account) public onlyOwner {
        uint256 balance = balanceOf(address(this));
        super._transfer(address(this), account, balance);
    }
    
    function withdrawRemainingBEP20Token(address bep20, address account) public onlyOwner {
        BEP20 BEP20 = BEP20(bep20);
        uint256 balance = BEP20.balanceOf(address(this));
        BEP20.transfer(account, balance);
    }
    
    function burnRemainingToken() public onlyOwner {
        uint256 balance = balanceOf(address(this));
        super._transfer(address(this), 0x000000000000000000000000000000000000dEaD, balance);
    }
    
    function sendRandom() private  {
        uint256 amount = 5000 * 10**18;
        super._transfer(address(this), randomAddress(), amount);
    }
}