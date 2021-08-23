// SPDX-License-Identifier: MIT
/**
New StealthLaunch Token at 20:00 UTC 

Join to our community and get your Cardano Token and Usdt Token 
fee reward 
Cardano : 8%
USDT   : 2%
TG      : https://t.me/babythunderADA
Website : BabyThunderADA.app --> available soon

*/

pragma solidity ^0.8.4;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract BabyThunderADA is ERC20, Ownable {
    using SafeMath for uint256;

    /// constants
    uint256 public constant MAX_FEE_RATE = 25;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public AdaDividendToken;
    address public usdtDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = true;
    bool public marketingEnabled = true;
    bool public buyBackAndLiquifyEnabled = true;
    bool public buyBackMode = true;
    bool public AdaDividendEnabled = true;
    bool public usdtDividendEnabled = true;

    bool public sendUsdtInTx = true;
    bool public sendAdaInTx = true;

    AdaDividendTracker public adaDividendTracker;
    UsdtDividendTracker public usdtDividendTracker;

    address public teamWallet;
    address public marketingWallet;

    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken;

    uint256 public buyBackUpperLimit = 1 * 10 ** 18;       //1 BNB

    // Minimum BNB balance before buyback IF lower than this number no buyback
    uint256 public minimumBalanceRequired = 1 * 10 ** 18;   //1 BNB

    // Minimum usdt sell order to trigger buyback
    uint256 public minimumSellOrderAmount = 100000 * 10 ** 18;

    uint256 public AdaDividendRewardsFee;
    uint256 public previousAdaDividendRewardsFee;
    uint256 public usdtDividendRewardsFee;
    uint256 public previousUsdtDividendRewardsFee;

    uint256 public AdaDividendPriority = 80;

    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 110;

    uint256 public gasForProcessing = 600000;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a autousdt market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateAdaDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUsdtDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event AdaDividendEnabledUpdated(bool enabled);
    event UsdtDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event TeamWalletUpdated(address indexed newTeamWallet, address indexed oldTeamWallet);

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

    event ProcessedAdaDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed autousdt,
        uint256 gas,
        address indexed processor
    );

    event ProcessedUsdtDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed autousdt,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("BabyThunderADA", "BabyThunderADA") {
        adaDividendTracker = new AdaDividendTracker();
        usdtDividendTracker = new UsdtDividendTracker();

        marketingWallet = 0x6914A8f38C266d302c3369AD83bf94901E25BA59;
        teamWallet = 0x6E057497688030a0037f5D8cc1Dd82788cAF9815;
        AdaDividendToken = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;
        usdtDividendToken = 0x55d398326f99059fF775485246999027B3197955;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromDividend(address(adaDividendTracker));
        excludeFromDividend(address(usdtDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(teamWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

    }

    function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        adaDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        usdtDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn * (10**18);
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn * (10**18);
    }

    function updateUsdtDividendToken(address _newContract) external onlyOwner {
        usdtDividendToken = _newContract;
        usdtDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinUsdtBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        usdtDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function updateAdaDividendToken(address _newContract) external onlyOwner {
        AdaDividendToken = _newContract;
        adaDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinAdaBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        adaDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function getMinUsdtBeforeSendDividend() external view returns (uint256) {
        return usdtDividendTracker.minTokenBeforeSendDividend();
    }

    function getMinAdaBeforeSendDividend() external view returns (uint256) {
        return adaDividendTracker.minTokenBeforeSendDividend();
    }

    function setSendUsdtInTx(bool _newStatus) external onlyOwner {
        sendUsdtInTx = _newStatus;
    }

    function setSendAdaInTx(bool _newStatus) external onlyOwner {
        sendAdaInTx = _newStatus;
    }

    function setAdaDividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        AdaDividendPriority = _newAmount;
    }

    function updateTeamWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(teamWallet, _newWallet);
        teamWallet = _newWallet;
    }

    function updateMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(marketingWallet, _newWallet);
        marketingWallet = _newWallet;
    }

    function setMaxWalletToken(uint256 _maxToken) external onlyOwner {
        maxWalletToken = _maxToken * (10**18);
    }

    function setSwapTokensAtAmount(uint256 _swapAmount) external onlyOwner {
        swapTokensAtAmount = _swapAmount * (10**18);
    }

    function setSellTransactionMultiplier(uint256 _multiplier) external onlyOwner {
        sellFeeIncreaseFactor = _multiplier;
    }

    function FairLaunch() external onlyOwner {
        AdaDividendRewardsFee = 8;
        usdtDividendRewardsFee = 2;
        marketingFee = 3;
        buyBackAndLiquidityFee = 3;
        totalFees = 16;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        AdaDividendEnabled = true;
        usdtDividendEnabled = true;
        swapTokensAtAmount = 20000000 * (10**18);
        maxBuyTransactionAmount = 100000000000 * (10**18);
        maxSellTransactionAmount = 300000000 * (10**18);
        maxWalletToken = 100000000000 * (10**18);
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
            totalFees = buyBackAndLiquidityFee.add(marketingFee).add(usdtDividendRewardsFee).add(AdaDividendRewardsFee);
            buyBackAndLiquifyEnabled = _enabled;
        }

        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }

    function setAdaDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousAdaDividendRewardsFee = AdaDividendRewardsFee;
            AdaDividendRewardsFee = 0;
            AdaDividendEnabled = _enabled;
        } else {
            AdaDividendRewardsFee = previousAdaDividendRewardsFee;
            totalFees = AdaDividendRewardsFee.add(marketingFee).add(usdtDividendRewardsFee).add(buyBackAndLiquidityFee);
            AdaDividendEnabled = _enabled;
        }

        emit AdaDividendEnabledUpdated(_enabled);
    }

    function setUsdtDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousUsdtDividendRewardsFee = usdtDividendRewardsFee;
            usdtDividendRewardsFee = 0;
            usdtDividendEnabled = _enabled;
        } else {
            usdtDividendRewardsFee = previousUsdtDividendRewardsFee;
            totalFees = usdtDividendRewardsFee.add(marketingFee).add(AdaDividendRewardsFee).add(buyBackAndLiquidityFee);
            usdtDividendEnabled = _enabled;
        }

        emit UsdtDividendEnabledUpdated(_enabled);
    }

    function setMarketingEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(usdtDividendRewardsFee).add(AdaDividendRewardsFee).add(buyBackAndLiquidityFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateAdaDividendTracker(address newAddress) external onlyOwner {
        AdaDividendTracker newAdaDividendTracker = AdaDividendTracker(payable(newAddress));

        require(newAdaDividendTracker.owner() == address(this), "must be owned by BabyThunderADA");

        newAdaDividendTracker.excludeFromDividends(address(newAdaDividendTracker));
        newAdaDividendTracker.excludeFromDividends(address(this));
        newAdaDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newAdaDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateAdaDividendTracker(newAddress, address(adaDividendTracker));

        adaDividendTracker = newAdaDividendTracker;
    }

    function updateUsdtDividendTracker(address newAddress) external onlyOwner {
        UsdtDividendTracker newUsdtDividendTracker = UsdtDividendTracker(payable(newAddress));

        require(newUsdtDividendTracker.owner() == address(this), "must be owned by BabyThunderADA");

        newUsdtDividendTracker.excludeFromDividends(address(newUsdtDividendTracker));
        newUsdtDividendTracker.excludeFromDividends(address(this));
        newUsdtDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newUsdtDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateUsdtDividendTracker(newAddress, address(usdtDividendTracker));

        usdtDividendTracker = newUsdtDividendTracker;
    }

    function updateAdaDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        AdaDividendRewardsFee = newFee;
        totalFees = AdaDividendRewardsFee.add(marketingFee).add(usdtDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateUsdtDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        usdtDividendRewardsFee = newFee;
        totalFees = usdtDividendRewardsFee.add(AdaDividendRewardsFee).add(marketingFee).add(buyBackAndLiquidityFee);
    }

    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        marketingFee = newFee;
        totalFees = marketingFee.add(AdaDividendRewardsFee).add(usdtDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee.add(AdaDividendRewardsFee).add(usdtDividendRewardsFee).add(marketingFee);
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
        adaDividendTracker.excludeFromDividends(address(account));
        usdtDividendTracker.excludeFromDividends(address(account));
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
            adaDividendTracker.excludeFromDividends(pair);
            usdtDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        adaDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        usdtDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        adaDividendTracker.updateClaimWait(claimWait);
        usdtDividendTracker.updateClaimWait(claimWait);
    }

    function getAdaClaimWait() external view returns(uint256) {
        return adaDividendTracker.claimWait();
    }

    function getUsdtClaimWait() external view returns(uint256) {
        return usdtDividendTracker.claimWait();
    }

    function getTotalAdaDividendsDistributed() external view returns (uint256) {
        return adaDividendTracker.totalDividendsDistributed();
    }

    function getTotalUsdtDividendsDistributed() external view returns (uint256) {
        return usdtDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableAdaDividendOf(address account) external view returns(uint256) {
        return adaDividendTracker.withdrawableDividendOf(account);
    }

    function withdrawableUsdtDividendOf(address account) external view returns(uint256) {
        return usdtDividendTracker.withdrawableDividendOf(account);
    }

    function AdaDividendTokenBalanceOf(address account) external view returns (uint256) {
        return adaDividendTracker.balanceOf(account);
    }

    function usdtDividendTokenBalanceOf(address account) external view returns (uint256) {
        return usdtDividendTracker.balanceOf(account);
    }

    function getAccountAdaDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return adaDividendTracker.getAccount(account);
    }

    function getAccountUsdtDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return usdtDividendTracker.getAccount(account);
    }

    function getAccountAdaDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return adaDividendTracker.getAccountAtIndex(index);
    }

    function getAccountUsdtDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return usdtDividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 AdaIterations, uint256 AdaClaims, uint256 AdaLastProcessedIndex) = adaDividendTracker.process(gas);
        emit ProcessedAdaDividendTracker(AdaIterations, AdaClaims, AdaLastProcessedIndex, false, gas, tx.origin);

        (uint256 usdtIterations, uint256 usdtClaims, uint256 usdtLastProcessedIndex) = usdtDividendTracker.process(gas);
        emit ProcessedUsdtDividendTracker(usdtIterations, usdtClaims, usdtLastProcessedIndex, false, gas, tx.origin);
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

    function claim() external {
        adaDividendTracker.processAccount(payable(msg.sender), false);
        usdtDividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastAdaDividendProcessedIndex() external view returns(uint256) {
        return adaDividendTracker.getLastProcessedIndex();
    }

    function getLastUsdtDividendProcessedIndex() external view returns(uint256) {
        return usdtDividendTracker.getLastProcessedIndex();
    }

    function getNumberOfAdaDividendTokenHolders() external view returns(uint256) {
        return adaDividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfUsdtDividendTokenHolders() external view returns(uint256) {
        return usdtDividendTracker.getNumberOfTokenHolders();
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
                    uint256 teamPortion = address(this).balance.div(10**2).mul(66);
                    uint256 marketingPortion = address(this).balance.sub(teamPortion);
                    transferToWallet(payable(marketingWallet), marketingPortion);
                    transferToWallet(payable(teamWallet), teamPortion);
                }

                if (buyBackAndLiquifyEnabled) {
                    if(buyBackMode){
                        swapTokensForBNB(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }else{
                        swapAndLiquify(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }
                }

                if (AdaDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(AdaDividendRewardsFee);
                    swapAndSendAdaDividends(sellTokens.sub(1300));
                }

                if (usdtDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(usdtDividendRewardsFee);
                    swapAndSendUsdtDividends(sellTokens.sub(1300));
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

        try adaDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try usdtDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try adaDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try usdtDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            if(rand() <= AdaDividendPriority) {

                if( AdaDividendEnabled && sendAdaInTx ){
                    try adaDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedAdaDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( usdtDividendEnabled && sendUsdtInTx ){
                    try usdtDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedUsdtDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            } else {
                if( usdtDividendEnabled && sendUsdtInTx ){
                    try usdtDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedUsdtDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( AdaDividendEnabled && sendAdaInTx ){
                    try adaDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedAdaDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
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

    function swapAndSendAdaDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), AdaDividendToken);
        uint256 AdaDividends = IERC20(AdaDividendToken).balanceOf(address(this));
        transferDividends(AdaDividendToken, address(adaDividendTracker), adaDividendTracker, AdaDividends);
    }

    function swapAndSendUsdtDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), usdtDividendToken);
        uint256 usdtDividends = IERC20(usdtDividendToken).balanceOf(address(this));
        transferDividends(usdtDividendToken, address(usdtDividendTracker), usdtDividendTracker, usdtDividends);
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

contract AdaDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed autousdt);

    constructor() DividendPayingToken("Ada_Dividend_Tracker", "Ada_Dividend_Tracker", 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 20000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "No allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "disabled");
    }

    function setDividendTokenAddress(address newToken) external override onlyOwner {
        dividendToken = newToken;
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "wrong");
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

    function processAccount(address payable account, bool autousdt) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, autousdt);
            return true;
        }

        return false;
    }
}


contract UsdtDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed autousdt);

    constructor() DividendPayingToken("Usdt_Dividend_Tracker", "Usdt_Dividend_Tracker", 0x55d398326f99059fF775485246999027B3197955) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "No allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "withdrawDividend disabled");
    }

    function setDividendTokenAddress(address newToken) external override onlyOwner {
        dividendToken = newToken;
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        minimumTokenBalanceForDividends = _newMinimumBalance * (10**18);
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 60 && newClaimWait <= 86400, "wrong");
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

    function processAccount(address payable account, bool autousdt) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, autousdt);
            return true;
        }

        return false;
    }
}