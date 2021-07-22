////////////////////////////////////////////////////////////////////////
//////////////// Telegram : https://t.me/btcrewardbsc /////////////////
//////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
///////////////////////////// Tokens ///////////////////////////////
///////////////////////////////////////////////////////////////////

 pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./BTCRDividendTracker.sol";
import "./IUniswapV2Factory.sol";




contract BTCReward is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public _dividendToken = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public buyBackEnabled = false;
    bool public buyBackRandomEnabled = true;

    BTCRDividendTracker public dividendTracker;

    address public buyBackWallet;
    
    uint256 public maxBuyTranscationAmount = 1000000 * (10**18);
    uint256 public maxSellTransactionAmount = 1000000 * (10**18);
    uint256 public swapTokensAtAmount = 100000 * (10**18);
    uint256 public maxWalletToken = 50000000 * (10**18); // 1.5% of total supply

    uint256 public dividendRewardsFee;
    uint256 public marketingFee;
    uint256 public immutable totalFees;

    // sells have fees of 12 and 6 (10 * 1.2 and 5 * 1.2)
    uint256 public sellFeeIncreaseFactor = 130;
    
    uint256 public marketingDivisor = 40;
    
    uint256 public _buyBackMultiplier = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 500000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxSellTFransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    
    event BuyBackEnabledUpdated(bool enabled);
    event BuyBackRandomEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludedMaxSellTransactionAmount(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event BuyBackWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

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
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("BTC Reward", "BTCR") {
        uint256 _dividendRewardsFee = 10;
        uint256 _marketingFee = 4;

        dividendRewardsFee = _dividendRewardsFee;
        marketingFee = _marketingFee;
        totalFees = _dividendRewardsFee.add(_marketingFee);

    	dividendTracker = new BTCRDividendTracker();

    	buyBackWallet = 0xf685E5895e38566929338dFbBB47eA6A6F78c509;
    	
    	//
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //0xf685E5895e38566929338dFbBB47eA6A6F78c509
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));
        

        // exclude from paying fees or having max transaction amount
        excludeFromFees(buyBackWallet, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {

  	}
  	
  	function setMaxBuyTransaction(uint256 maxTxn) external onlyOwner {
  	    maxBuyTranscationAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 maxTxn) external onlyOwner {
  	    maxSellTransactionAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxWalletToken(uint256 maxToken) external onlyOwner {
  	    maxWalletToken = maxToken * (10**18);
  	}
  	
  	function setSellTransactionMultiplier(uint256 multiplier) external onlyOwner {
  	    require(sellFeeIncreaseFactor >= 1 && sellFeeIncreaseFactor <= 1000, "BTCR: Sell transaction multipler must be between 1 (1x) and 1000 (2x)");
  	    sellFeeIncreaseFactor = multiplier;
  	}
  	
  	function setMarketingDivisor(uint256 divisor) external onlyOwner {
  	    require(marketingDivisor >= 0 && marketingDivisor <= 100, "BTCR: Marketing divisor must be between 0 (0%) and 100 (100%)");
  	    sellFeeIncreaseFactor = divisor;
    }
    
    function setTradingIsEnabled(bool _enabled) public onlyOwner {
        tradingIsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function setBuyBackRandomEnabled(bool _enabled) public onlyOwner {
        buyBackRandomEnabled = _enabled;
        emit BuyBackRandomEnabledUpdated(_enabled);
    }
    
    function triggerBuyBack(uint256 amount) public onlyOwner {
        require(!swapping, "BTCR: A swapping process is currently running, wait till that is complete");
        
        uint256 buyBackBalance = address(this).balance;
        swapBNBForTokens(buyBackBalance.div(10**2).mul(amount));
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BTCR: The dividend tracker already has that address");

        BTCRDividendTracker newDividendTracker = BTCRDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BTCR: The new dividend tracker must be owned by the FLOKIBUSD token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }
    
    function updateDividendRewardFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "BTCR: Dividend reward tax must be between 0 and 10");
        dividendRewardsFee = newFee;
    }
    
    function updateMarketingFee(uint8 newFee) public onlyOwner {
        require(newFee >= 0 && newFee <= 10, "BTCR: Dividend reward tax must be between 0 and 10");
        marketingFee = newFee;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BTCR: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BTCR: Account is already the value of 'excluded'");
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
        require(pair != uniswapV2Pair, "BTCR: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BTCR: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateBuyBackWallet(address newBuyBackWallet) public onlyOwner {
        require(newBuyBackWallet != buyBackWallet, "BTCR: The liquidity wallet is already this address");
        excludeFromFees(newBuyBackWallet, true);
        buyBackWallet = newBuyBackWallet;
        emit BuyBackWalletUpdated(newBuyBackWallet, buyBackWallet);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 700000, "BTCR: gasForProcessing must be between 200,000 and 700,000");
        require(newValue != gasForProcessing, "BTCR: Cannot update gasForProcessing to same value");
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
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }
    
    function rand() public view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / 
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) / 
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from]
        ) {
            require(
                amount <= maxBuyTranscationAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            
            uint256 contractBalanceRecepient = balanceOf(to);
            require(
                contractBalanceRecepient + amount <= maxWalletToken,
                "Exceeds maximum wallet token amount."
            );
        } else if (
        	tradingIsEnabled &&
            automatedMarketMakerPairs[to]
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
            
            if (!swapping && canSwap) {
                swapping = true;

                uint256 swapTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                swapTokensForBNB(swapTokens);
                transferToBuyBackWallet(payable(buyBackWallet), address(this).balance.div(10**2).mul(marketingDivisor));
                
                uint256 buyBackBalance = address(this).balance;
                if (buyBackEnabled && buyBackBalance > uint256(1 * 10**18)) {
                    swapBNBForTokens(buyBackBalance.div(10**2).mul(rand()));
                }
                
                if (_dividendToken == uniswapV2Router.WETH()) {
                    uint256 sellTokens = balanceOf(address(this));
                    swapAndSendDividendsInBNB(sellTokens);
                } else {
                    uint256 sellTokens = balanceOf(address(this));
                    swapAndSendDividends(sellTokens);
                }
    
                swapping = false;
            }
        }

        bool takeFee = tradingIsEnabled && !swapping;

        if(takeFee) {
        	uint256 fees = amount.div(100).mul(totalFees);

            // if sell, multiply by 1.2
            if(automatedMarketMakerPairs[to]) {
                fees = fees.div(100).mul(sellFeeIncreaseFactor);
            }
            
            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
                fees = 0;
            }

        	amount = amount.sub(fees);

            if(fees > 0){
                super._transfer(from, address(this), fees);
            }
            
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

    function swapTokensForBNB(uint256 tokenAmount) private {
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
    
    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

    function swapTokensForDividendToken(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of weth -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of dividend token
            path,
            recipient,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this));
        uint256 dividends = IERC20(_dividendToken).balanceOf(address(this));
        bool success = IERC20(_dividendToken).transfer(address(dividendTracker), dividends);
        
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function swapAndSendDividendsInBNB(uint256 tokens) private {
        uint256 currentBNBBalance = address(this).balance;
        swapTokensForBNB(tokens);
        uint256 newBNBBalance = address(this).balance;
        
        uint256 dividends = newBNBBalance.sub(currentBNBBalance);
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        
        if (success) {
            dividendTracker.distributeDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
    
    function transferToBuyBackWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}