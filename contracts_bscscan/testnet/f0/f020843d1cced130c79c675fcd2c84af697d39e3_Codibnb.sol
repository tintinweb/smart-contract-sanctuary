// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

import './Ownable.sol';
import './BEP20.sol';
import './IPancakeswapV2Router02.sol';
import './IPancakeswapV2Factory.sol';
import './IPancakeswapV2Pair.sol';
import './CodibnbDividendTracker.sol';


contract Codibnb is BEP20, Ownable {
    using SafeMath for uint256;

    IPancakeswapV2Router02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;
    address public marketingWallet = 0x7f5942bBD09aD495aF81206cf0cbbA19E4a574E3;
    address public airdropWallet = 0x1A788076BC9553B4957b4542741B06d48B000660;
    address public deployerWallet = 0xe8d2105E7f20D2ebA92B8BD43208A3c3a69687ce;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;

    CodibnbDividendTracker public dividendTracker;

    address public liquidityWallet = 0xe3B230c515464b3A96b72223b2699971e01739a1;

    uint256 public maxSellTransactionAmount = 500000 * (10**18);
    uint256 public swapTokensAtAmount = 1 * (10**18);

    uint256 public immutable BNBRewardsFee;
    uint256 public immutable buyBurnFee;
    uint256 public immutable liquidityFee;
    uint256 public immutable sellBurnFee;
    uint256 public immutable marketingFee;
    uint256 public immutable buyTotalFees;
    uint256 public immutable sellTotalFees;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

     // exlcude from Dividends
    mapping (address => bool) private _isExcludedFromDividends;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdatePancakeswapV2Router(address indexed newAddress, address indexed oldAddress);

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
    event UpdatedCanTransferBeforeTrading(address  account, bool state);
    event UpdateTradingEnabledTimestamp(uint256 timestamp);
    constructor() BEP20("Codibnb", "CODIBNB", 18) {
        uint256 _BNBRewardsFee = 6;
        uint256 _buyBurnFee = 0;
        uint256 _liquidityFee = 2;
        uint256 _sellBurnFee = 5;
        uint256 _marketingFee = 2;

        BNBRewardsFee = _BNBRewardsFee;
        buyBurnFee = _buyBurnFee;
        liquidityFee = _liquidityFee;
        sellBurnFee = _sellBurnFee;
        marketingFee = _marketingFee;
        buyTotalFees = _BNBRewardsFee.add(_buyBurnFee).add(_liquidityFee).add(_marketingFee);
        sellTotalFees = _BNBRewardsFee.add(_sellBurnFee).add(_liquidityFee).add(_marketingFee);


    	dividendTracker = new CodibnbDividendTracker();

        //testnet
    	// IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	//mainnet
    	IPancakeswapV2Router02 _pancakeswapV2Router = IPancakeswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a pancakeswap pair for this new token
        address _pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        pancakeswapV2Router = _pancakeswapV2Router;
        pancakeswapV2Pair = _pancakeswapV2Pair;

        _setAutomatedMarketMakerPair(_pancakeswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(burnAddress));
        dividendTracker.excludeFromDividends(address(airdropWallet));
        dividendTracker.excludeFromDividends(address(deployerWallet));
        dividendTracker.excludeFromDividends(address(_pancakeswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(airdropWallet, true);
        excludeFromFees(deployerWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(liquidityWallet, true);

        /*
            _mint is an internal function in BEP20.sol that is only called here,
            and CANNOT be called ever again
        */
        // AirdropWallet(0%)
        _mint(airdropWallet, 0 * (10**18));
        // DeployerWallet(100%)
        _mint(deployerWallet, 100000000 * (10**18));
    }

    receive() external payable {

  	}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Codibnb: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeswapV2Pair, "Codibnb: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Codibnb: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Codibnb: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Codibnb: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }
    
    function setMaxtxn(uint256 txnAmount) external onlyOwner {
        maxSellTransactionAmount = txnAmount;
    }
    function setSwapAt(uint256 swapAmount) external onlyOwner {
        swapTokensAtAmount = swapAmount;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
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

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

   
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if( 
        	!swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
        	from != address(pancakeswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] && //no max for those excluded from fees
            !_isExcludedFromFees[from]
        ) {
            require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
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
            uint256 rewardAndLiquidityFee = liquidityFee.add(BNBRewardsFee);
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(rewardAndLiquidityFee);
            swapAndLiquify(swapTokens);
            
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 rewardAndLiquidityFee = liquidityFee.add(BNBRewardsFee);
        	uint256 feesForSwap = amount.mul(rewardAndLiquidityFee).div(100);
        	amount = amount.sub(feesForSwap);
            super._transfer(from, address(this), feesForSwap);

            // if buy, use buyBurnFee, if sell, use sellBurnFee
            if(automatedMarketMakerPairs[from]) {
                uint256 burnfees = amount.mul(buyBurnFee).div(100);
                super._transfer(from, burnAddress, burnfees);
                amount = amount.sub(burnfees);
                
            } else if(automatedMarketMakerPairs[to]) {
                uint256 burnfees = amount.mul(sellBurnFee).div(100);
                super._transfer(from, burnAddress, burnfees);
                amount = amount.sub(burnfees);
            }
            
            uint256 marketingFees = amount.mul(marketingFee).div(100);
            super._transfer(from, marketingWallet, marketingFees);
        	amount = amount.sub(marketingFees);
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

        // add liquidity to pancakeswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");

        if(success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }
}