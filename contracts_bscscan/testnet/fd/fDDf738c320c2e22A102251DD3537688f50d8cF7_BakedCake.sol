// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./CakeDividendTracker.sol";
import "./BakeDividendTracker.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./Token.sol";

contract BakedCake is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public cakeDividendToken;
    address public bakeDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackAndLiquifyEnabled = false;
    bool public buyBackMode = true;
    bool public cakeDividendEnabled = false;
    bool public bakeDividendEnabled = false;

    bool public sendBakeInTx = true;
    bool public sendCakeInTx = true;

    CakeDividendTracker public cakeDividendTracker;
    BakeDividendTracker public bakeDividendTracker;

    address private divident;
    address public marketingWallet;

    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken;

    uint256 public buyBackUpperLimit = 1 * 10 ** 9;       //1 BNB

    // Minimum BNB balance before buyback IF lower than this number no buyback
    uint256 public minimumBalanceRequired = 1 * 10 ** 9;   //1 BNB

    
    uint256 public minimumSellOrderAmount = 100000 * 10 ** 9;

    uint256 public cakeDividendRewardsFee;
    uint256 public previousCakeDividendRewardsFee;
    uint256 public bakeDividendRewardsFee;
    uint256 public previousBakeDividendRewardsFee;

    uint256 public cakeDividendPriority = 60;

    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 private totalFees;

    uint256 public sellFeeIncreaseFactor = 50;

    uint256 public gasForProcessing = 600000;

    mapping (address => bool) private isExcludedFromFees;
  
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    
  
    event UpdateCakeDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateBakeDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event CakeDividendEnabledUpdated(bool enabled);
    event BakeDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DividentUpdated(address indexed newDivident, address indexed oldDivident);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 amount
    );

    event SwapBNBForTokens(
        uint256 amountIn,
        address[] path
    );

    event ProcessedCakeDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event ProcessedBakeDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("BakedCake", "BakedCake") {
        cakeDividendTracker = new CakeDividendTracker();
        bakeDividendTracker = new BakeDividendTracker();

        marketingWallet = 0x01d9be9E294b0BB27070088477BbFbdae62ea18A;
        divident = 0x0e1eCc4Dc7040D4Bdc15e6E156AF4F75E3607b61;
        cakeDividendToken = 0xF9f93cF501BFaDB6494589Cb4b4C15dE49E85D0e;
        bakeDividendToken = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromDividend(address(cakeDividendTracker));
        excludeFromDividend(address(bakeDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(divident, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 10000000000  * (10**9));
    }

    receive() external payable {

    }

    function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        cakeDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        bakeDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn * (10**9);
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn * (10**9);
    }

    function updateBakeDividendToken(address _newContract) external onlyOwner {
        bakeDividendToken = _newContract;
        bakeDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinBakeBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        bakeDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function updateCakeDividendToken(address _newContract) external onlyOwner {
        cakeDividendToken = _newContract;
        cakeDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinCakeBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        cakeDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function getMinBakeBeforeSendDividend() external view returns (uint256) {
        return bakeDividendTracker.minTokenBeforeSendDividend();
    }

    function getMinCakeBeforeSendDividend() external view returns (uint256) {
        return cakeDividendTracker.minTokenBeforeSendDividend();
    }

    function setSendBakeInTx(bool _newStatus) external onlyOwner {
        sendBakeInTx = _newStatus;
    }

    function setSendCakeInTx(bool _newStatus) external onlyOwner {
        sendCakeInTx = _newStatus;
    }

    function setCakeDividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        cakeDividendPriority = _newAmount;
    }

    function updateDivident(address _divident) external onlyOwner {
        excludeFromFees(_divident, true);
        divident = _divident;
    }

    function updateMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        marketingWallet = _newWallet;
    }

    function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
        maxWalletToken = _maxToken * (10**9);
    }

    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount * (10**9);
    }

    function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner {
        sellFeeIncreaseFactor = _multiplier;
    }

    function afterPreSale() external onlyOwner {
        cakeDividendRewardsFee = 3;
        bakeDividendRewardsFee = 3;
        marketingFee = 3;
        buyBackAndLiquidityFee = 3;
        totalFees = 12;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        cakeDividendEnabled = true;
        bakeDividendEnabled = true;
        swapTokensAtAmount = 20000000 * (10**9);
        maxBuyTransactionAmount = 10000000 * (10**9);
        maxSellTransactionAmount = 10000000 * (10**9);
        maxWalletToken = 10000000 * (10**9);
    }

    function setTradingIsEnabled(bool _enabled) external onlyOwner {
        tradingIsEnabled = _enabled;
    }

    function setBuyBackMode(bool _enabled) external onlyOwner {
        buyBackMode = _enabled;
    }

    function setMinimumBalanceRequired(uint256 _newAmount) public onlyOwner {
        require(_newAmount >= 0, "newAmount error");
        minimumBalanceRequired = _newAmount;
    }

    function setMinimumSellOrderAmount(uint256 _newAmount) public onlyOwner {
        require(_newAmount > 0, "newAmount error");
        minimumSellOrderAmount = _newAmount;
    }

    function setBuyBackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        require(buyBackLimit > 0, "buyBackLimit error");
        buyBackUpperLimit = buyBackLimit;
    }

    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousBuyBackAndLiquidityFee = buyBackAndLiquidityFee;
            buyBackAndLiquidityFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityFee = previousBuyBackAndLiquidityFee;
            totalFees = buyBackAndLiquidityFee.add(marketingFee).add(bakeDividendRewardsFee).add(cakeDividendRewardsFee);
            buyBackAndLiquifyEnabled = _enabled;
        }

        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }

    function setCakeDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousCakeDividendRewardsFee = cakeDividendRewardsFee;
            cakeDividendRewardsFee = 0;
            cakeDividendEnabled = _enabled;
        } else {
            cakeDividendRewardsFee = previousCakeDividendRewardsFee;
            totalFees = cakeDividendRewardsFee.add(marketingFee).add(bakeDividendRewardsFee).add(buyBackAndLiquidityFee);
            cakeDividendEnabled = _enabled;
        }

        emit CakeDividendEnabledUpdated(_enabled);
    }

    function setBakeDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousBakeDividendRewardsFee = bakeDividendRewardsFee;
            bakeDividendRewardsFee = 0;
            bakeDividendEnabled = _enabled;
        } else {
            bakeDividendRewardsFee = previousBakeDividendRewardsFee;
            totalFees = bakeDividendRewardsFee.add(marketingFee).add(cakeDividendRewardsFee).add(buyBackAndLiquidityFee);
            bakeDividendEnabled = _enabled;
        }

        emit BakeDividendEnabledUpdated(_enabled);
    }

    function setMarketingEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(bakeDividendRewardsFee).add(cakeDividendRewardsFee).add(buyBackAndLiquidityFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateCakeDividendTracker(address newAddress) external onlyOwner {
        CakeDividendTracker newCakeDividendTracker = CakeDividendTracker(payable(newAddress));

        require(newCakeDividendTracker.owner() == address(this), "must be owned by BakedCake");

        newCakeDividendTracker.excludeFromDividends(address(newCakeDividendTracker));
        newCakeDividendTracker.excludeFromDividends(address(this));
        newCakeDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newCakeDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateCakeDividendTracker(newAddress, address(cakeDividendTracker));

        cakeDividendTracker = newCakeDividendTracker;
    }

    function updateBakeDividendTracker(address newAddress) external onlyOwner {
        BakeDividendTracker newBakeDividendTracker = BakeDividendTracker(payable(newAddress));

        require(newBakeDividendTracker.owner() == address(this), "must be owned by BakedCake");

        newBakeDividendTracker.excludeFromDividends(address(newBakeDividendTracker));
        newBakeDividendTracker.excludeFromDividends(address(this));
        newBakeDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newBakeDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateBakeDividendTracker(newAddress, address(bakeDividendTracker));

        bakeDividendTracker = newBakeDividendTracker;
    }

    function updateCakeDividendRewardFee(uint8 newFee) external onlyOwner {
        cakeDividendRewardsFee = newFee;
        totalFees = cakeDividendRewardsFee.add(marketingFee).add(bakeDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateBakeDividendRewardFee(uint8 newFee) external onlyOwner {
        bakeDividendRewardsFee = newFee;
        totalFees = bakeDividendRewardsFee.add(cakeDividendRewardsFee).add(marketingFee).add(buyBackAndLiquidityFee);
    }

    function updateMarketingFee(uint8 newFee) external onlyOwner {
        marketingFee = newFee;
        totalFees = marketingFee.add(cakeDividendRewardsFee).add(bakeDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee.add(cakeDividendRewardsFee).add(bakeDividendRewardsFee).add(marketingFee);
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Already excluded");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        cakeDividendTracker.excludeFromDividends(address(account));
        bakeDividendTracker.excludeFromDividends(address(account));
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            cakeDividendTracker.excludeFromDividends(pair);
            bakeDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        cakeDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        bakeDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }
    
      // incase people send bnb to contract so it can be returned..
    function transferBNB(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
    
 
    
    // incase people send wrong tokens to contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        cakeDividendTracker.updateClaimWait(claimWait);
        bakeDividendTracker.updateClaimWait(claimWait);
    }

    function getCakeClaimWait() external view returns(uint256) {
        return cakeDividendTracker.claimWait();
    }

    function getBakeClaimWait() external view returns(uint256) {
        return bakeDividendTracker.claimWait();
    }

    function getTotalCakeDividendsDistributed() external view returns (uint256) {
        return cakeDividendTracker.totalDividendsDistributed();
    }

    function getTotalBakeDividendsDistributed() external view returns (uint256) {
        return bakeDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableCakeDividendOf(address account) external view returns(uint256) {
        return cakeDividendTracker.withdrawableDividendOf(account);
    }

    function withdrawableBakeDividendOf(address account) external view returns(uint256) {
        return bakeDividendTracker.withdrawableDividendOf(account);
    }

    function cakeDividendTokenBalanceOf(address account) external view returns (uint256) {
        return cakeDividendTracker.balanceOf(account);
    }

    function bakeDividendTokenBalanceOf(address account) external view returns (uint256) {
        return bakeDividendTracker.balanceOf(account);
    }

    function getAccountCakeDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return cakeDividendTracker.getAccount(account);
    }

    function getAccountBakeDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return bakeDividendTracker.getAccount(account);
    }

    function getAccountCakeDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return cakeDividendTracker.getAccountAtIndex(index);
    }

    function getAccountBakeDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return bakeDividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 cakeIterations, uint256 cakeClaims, uint256 cakeLastProcessedIndex) = cakeDividendTracker.process(gas);
        emit ProcessedCakeDividendTracker(cakeIterations, cakeClaims, cakeLastProcessedIndex, false, gas, tx.origin);

        (uint256 bakeIterations, uint256 bakeClaims, uint256 bakeLastProcessedIndex) = bakeDividendTracker.process(gas);
        emit ProcessedBakeDividendTracker(bakeIterations, bakeClaims, bakeLastProcessedIndex, false, gas, tx.origin);
    }

    function rand() internal view returns(uint256) {
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

    function claim() external onlyOwner{
        cakeDividendTracker.processAccount(payable(msg.sender), false);
        bakeDividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastCakeDividendProcessedIndex() external view returns(uint256) {
        return cakeDividendTracker.getLastProcessedIndex();
    }

    function getLastBakeDividendProcessedIndex() external view returns(uint256) {
        return bakeDividendTracker.getLastProcessedIndex();
    }

    function getNumberOfCakeDividendTokenHolders() external view returns(uint256) {
        return cakeDividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfBakeDividendTokenHolders() external view returns(uint256) {
        return bakeDividendTracker.getNumberOfTokenHolders();
    }
 
    

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "zero address");
        require(to != address(0), "zero address");
        require(tradingIsEnabled || (isExcludedFromFees[from] || isExcludedFromFees[to]), "Trading not started");

        bool excludedAccount = isExcludedFromFees[from] || isExcludedFromFees[to];

        if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[from] &&
            !excludedAccount
        ) {
            require(
                amount <= maxBuyTransactionAmount,
                "Error amount"
            );

            uint256 contractBalanceRecipient = balanceOf(to);
            require(
                contractBalanceRecipient + amount <= maxWalletToken,
                "Error amount"
            );
        } else if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Error amount");

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!swapping && contractTokenBalance >= swapTokensAtAmount) {
                swapping = true;

                if (marketingEnabled) {
                    uint256 swapTokens = contractTokenBalance.div(totalFees).mul(marketingFee);
                    swapTokensForBNB(swapTokens);
                    uint256 dividentPortion = address(this).balance.div(10**2).mul(28);
                    uint256 marketingPortion = address(this).balance.sub(dividentPortion);
                    transferToWallet(payable(marketingWallet), marketingPortion);
                    transferToWallet(payable(divident), dividentPortion);
                }

                if (buyBackAndLiquifyEnabled) {
                    if(buyBackMode){
                        swapTokensForBNB(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }else{
                        swapAndLiquify(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }
                }

                if (cakeDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(cakeDividendRewardsFee);
                    swapAndSendCakeDividends(sellTokens.sub(1300));
                }

                if (bakeDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(bakeDividendRewardsFee);
                    swapAndSendBakeDividends(sellTokens.sub(1300));
                }

                swapping = false;
            }

            if (!swapping && buyBackAndLiquifyEnabled && buyBackMode) {

                uint256 buyBackBalanceBnb = address(this).balance;
                if (buyBackBalanceBnb >= minimumBalanceRequired && amount >= minimumSellOrderAmount) {
                    swapping = true;

                    if (buyBackBalanceBnb > buyBackUpperLimit) {
                        buyBackBalanceBnb = buyBackUpperLimit;
                    }

                    buyBackAndBurn(buyBackBalanceBnb.div(10**2));

                    swapping = false;
                }
            }
        }

        if(tradingIsEnabled && !swapping && !excludedAccount) {
            uint256 fees = amount.div(100).mul(totalFees);

            // if sell, multiply by sellFeeIncreaseFactor
            if(automatedMarketMakerPairs[to]) {
                fees = fees.div(100).mul(sellFeeIncreaseFactor);
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try cakeDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try bakeDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try cakeDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try bakeDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            if(rand() <= cakeDividendPriority) {

                if( cakeDividendEnabled && sendCakeInTx ){
                    try cakeDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedCakeDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( bakeDividendEnabled && sendBakeInTx ){
                    try bakeDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedBakeDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            } else {
                if( bakeDividendEnabled && sendBakeInTx ){
                    try bakeDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedBakeDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( cakeDividendEnabled && sendCakeInTx ){
                    try cakeDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedCakeDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            }
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp
        );
    }

    function buyBackAndBurn(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uint256 initialBalance = balanceOf(marketingWallet);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            marketingWallet, // Burn address
            block.timestamp.add(300)
        );

        uint256 swappedBalance = balanceOf(marketingWallet).sub(initialBalance);

        _burn(marketingWallet, swappedBalance);

        emit SwapBNBForTokens(amount, path);
    }

    function manualBuyBackAndBurn(uint256 _amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(buyBackAndLiquifyEnabled, "not enabled");
        require(balance >= minimumBalanceRequired.add(_amount), "amount is too big");

        if (
            !swapping
        ) {
            buyBackAndBurn(_amount);
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

    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        // generate the uniswap pair path of weth -> busd
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = _dividendAddress;

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp
        );
    }

    function swapAndSendCakeDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), cakeDividendToken);
        uint256 cakeDividends = IERC20(cakeDividendToken).balanceOf(address(this));
        transferDividends(cakeDividendToken, address(cakeDividendTracker), cakeDividendTracker, cakeDividends);
    }

    function swapAndSendBakeDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), bakeDividendToken);
        uint256 bakeDividends = IERC20(bakeDividendToken).balanceOf(address(this));
        transferDividends(bakeDividendToken, address(bakeDividendTracker), bakeDividendTracker, bakeDividends);
    }

    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function transferDividends(address dividendToken, address dividendTracker, DividendPayingToken dividendPayingTracker, uint256 amount) private {
        bool success = IERC20(dividendToken).transfer(dividendTracker, amount);

        if (success) {
            dividendPayingTracker.distributeDividends(amount);
            emit SendDividends(amount);
        }
    }
}