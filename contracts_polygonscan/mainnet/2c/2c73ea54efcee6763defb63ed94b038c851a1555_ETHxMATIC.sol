// SPDX-License-Identifier: MIT


/*

Join to our community and get your ETH Token and Matic Token 
fee reward 
ETH : 5%
Matic   : 5%
TG      : https:
Website :  --> available soon

*/

pragma solidity ^0.8.4;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract ETHxMATIC is ERC20, Ownable {
    using SafeMath for uint256;

    /// constants
    uint256 public constant MAX_FEE_RATE = 25;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public EthDividendToken;
    address public maticDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = true;
    bool public marketingEnabled = true;
    bool public buyBackAndLiquifyEnabled = true;
    bool public buyBackMode = true;
    bool public EthDividendEnabled = true;
    bool public maticDividendEnabled = true;

    bool public sendMaticInTx = true;
    bool public sendEthInTx = true;

    EthDividendTracker public ethDividendTracker;
    MaticDividendTracker public maticDividendTracker;

    address public devWallet;
    address public marketingWallet;

    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken;

    uint256 public buyBackUpperLimit = 1 * 10 ** 18;       //1 ETH

    // Minimum ETH balance before buyback IF lower than this number no buyback
    uint256 public minimumBalanceRequired = 1 * 10 ** 18;   //1 ETH

    // Minimum matic sell order to trigger buyback
    uint256 public minimumSellOrderAmount = 100000 * 10 ** 18;

    uint256 public EthDividendRewardsFee;
    uint256 public previousEthDividendRewardsFee;
    uint256 public maticDividendRewardsFee;
    uint256 public previousMaticDividendRewardsFee;

    uint256 public EthDividendPriority = 80;

    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 110;

    uint256 public gasForProcessing = 600000;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateEthDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateMaticDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event EthDividendEnabledUpdated(bool enabled);
    event MaticDividendEnabledUpdated(bool enabled);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevWalletUpdated(address indexed newDevWallet, address indexed oldDevWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 amount
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event ProcessedEthDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event ProcessedMaticDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("ETHxMATIC", "ETHxMATIC") {
        ethDividendTracker = new EthDividendTracker();
        maticDividendTracker = new MaticDividendTracker();

        marketingWallet = 0x3042dFB9ED10618c925733C770Ce1Fdd475eeFd6;
        devWallet = 0x583d2A624acFC4a01ad93cdDE2a759ad344992A6;
        EthDividendToken = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        maticDividendToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromDividend(address(ethDividendTracker));
        excludeFromDividend(address(maticDividendTracker));
        excludeFromDividend(address(this));
        excludeFromDividend(address(_uniswapV2Router));
        excludeFromDividend(deadAddress);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
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
        ethDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        maticDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn * (10**18);
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn * (10**18);
    }

    function updateMaticDividendToken(address _newContract) external onlyOwner {
        maticDividendToken = _newContract;
        maticDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinMaticBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        maticDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function updateEthDividendToken(address _newContract) external onlyOwner {
        EthDividendToken = _newContract;
        ethDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinEthBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        ethDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function getMinMaticBeforeSendDividend() external view returns (uint256) {
        return maticDividendTracker.minTokenBeforeSendDividend();
    }

    function getMinEthBeforeSendDividend() external view returns (uint256) {
        return ethDividendTracker.minTokenBeforeSendDividend();
    }

    function setSendMaticInTx(bool _newStatus) external onlyOwner {
        sendMaticInTx = _newStatus;
    }

    function setSendEthInTx(bool _newStatus) external onlyOwner {
        sendEthInTx = _newStatus;
    }

    function setEthDividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        EthDividendPriority = _newAmount;
    }

    function updateDevWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
        emit MarketingWalletUpdated(devWallet, _newWallet);
        devWallet = _newWallet;
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

    function StealthLaunch() external onlyOwner {
        EthDividendRewardsFee = 5;
        maticDividendRewardsFee = 5;
        marketingFee = 3;
        buyBackAndLiquidityFee = 3;
        totalFees = 16;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        EthDividendEnabled = true;
        maticDividendEnabled = true;
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
            totalFees = buyBackAndLiquidityFee.add(marketingFee).add(maticDividendRewardsFee).add(EthDividendRewardsFee);
            buyBackAndLiquifyEnabled = _enabled;
        }

        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }

    function setEthDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousEthDividendRewardsFee = EthDividendRewardsFee;
            EthDividendRewardsFee = 0;
            EthDividendEnabled = _enabled;
        } else {
            EthDividendRewardsFee = previousEthDividendRewardsFee;
            totalFees = EthDividendRewardsFee.add(marketingFee).add(maticDividendRewardsFee).add(buyBackAndLiquidityFee);
            EthDividendEnabled = _enabled;
        }

        emit EthDividendEnabledUpdated(_enabled);
    }

    function setMaticDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousMaticDividendRewardsFee = maticDividendRewardsFee;
            maticDividendRewardsFee = 0;
            maticDividendEnabled = _enabled;
        } else {
            maticDividendRewardsFee = previousMaticDividendRewardsFee;
            totalFees = maticDividendRewardsFee.add(marketingFee).add(EthDividendRewardsFee).add(buyBackAndLiquidityFee);
            maticDividendEnabled = _enabled;
        }

        emit MaticDividendEnabledUpdated(_enabled);
    }

    function setMarketingEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(maticDividendRewardsFee).add(EthDividendRewardsFee).add(buyBackAndLiquidityFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateEthDividendTracker(address newAddress) external onlyOwner {
        EthDividendTracker newEthDividendTracker = EthDividendTracker(payable(newAddress));

        require(newEthDividendTracker.owner() == address(this), "must be owned by ETHxMATIC");

        newEthDividendTracker.excludeFromDividends(address(newEthDividendTracker));
        newEthDividendTracker.excludeFromDividends(address(this));
        newEthDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newEthDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateEthDividendTracker(newAddress, address(ethDividendTracker));

        ethDividendTracker = newEthDividendTracker;
    }

    function updateMaticDividendTracker(address newAddress) external onlyOwner {
        MaticDividendTracker newMaticDividendTracker = MaticDividendTracker(payable(newAddress));

        require(newMaticDividendTracker.owner() == address(this), "must be owned by ETHxMATIC");

        newMaticDividendTracker.excludeFromDividends(address(newMaticDividendTracker));
        newMaticDividendTracker.excludeFromDividends(address(this));
        newMaticDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newMaticDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateMaticDividendTracker(newAddress, address(maticDividendTracker));

        maticDividendTracker = newMaticDividendTracker;
    }

    function updateEthDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        EthDividendRewardsFee = newFee;
        totalFees = EthDividendRewardsFee.add(marketingFee).add(maticDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateMaticDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        maticDividendRewardsFee = newFee;
        totalFees = maticDividendRewardsFee.add(EthDividendRewardsFee).add(marketingFee).add(buyBackAndLiquidityFee);
    }

    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        marketingFee = newFee;
        totalFees = marketingFee.add(EthDividendRewardsFee).add(maticDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee.add(EthDividendRewardsFee).add(maticDividendRewardsFee).add(marketingFee);
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
        ethDividendTracker.excludeFromDividends(address(account));
        maticDividendTracker.excludeFromDividends(address(account));
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
            ethDividendTracker.excludeFromDividends(pair);
            maticDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        ethDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        maticDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        ethDividendTracker.updateClaimWait(claimWait);
        maticDividendTracker.updateClaimWait(claimWait);
    }

    function getEthClaimWait() external view returns(uint256) {
        return ethDividendTracker.claimWait();
    }

    function getMaticClaimWait() external view returns(uint256) {
        return maticDividendTracker.claimWait();
    }

    function getTotalEthDividendsDistributed() external view returns (uint256) {
        return ethDividendTracker.totalDividendsDistributed();
    }

    function getTotalMaticDividendsDistributed() external view returns (uint256) {
        return maticDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableEthDividendOf(address account) external view returns(uint256) {
        return ethDividendTracker.withdrawableDividendOf(account);
    }

    function withdrawableMaticDividendOf(address account) external view returns(uint256) {
        return maticDividendTracker.withdrawableDividendOf(account);
    }

    function EthDividendTokenBalanceOf(address account) external view returns (uint256) {
        return ethDividendTracker.balanceOf(account);
    }

    function maticDividendTokenBalanceOf(address account) external view returns (uint256) {
        return maticDividendTracker.balanceOf(account);
    }

    function getAccountEthDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return ethDividendTracker.getAccount(account);
    }

    function getAccountMaticDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return maticDividendTracker.getAccount(account);
    }

    function getAccountEthDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return ethDividendTracker.getAccountAtIndex(index);
    }

    function getAccountMaticDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return maticDividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 EthIterations, uint256 EthClaims, uint256 EthLastProcessedIndex) = ethDividendTracker.process(gas);
        emit ProcessedEthDividendTracker(EthIterations, EthClaims, EthLastProcessedIndex, false, gas, tx.origin);

        (uint256 maticIterations, uint256 maticClaims, uint256 maticLastProcessedIndex) = maticDividendTracker.process(gas);
        emit ProcessedMaticDividendTracker(maticIterations, maticClaims, maticLastProcessedIndex, false, gas, tx.origin);
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
        ethDividendTracker.processAccount(payable(msg.sender), false);
        maticDividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastEthDividendProcessedIndex() external view returns(uint256) {
        return ethDividendTracker.getLastProcessedIndex();
    }

    function getLastMaticDividendProcessedIndex() external view returns(uint256) {
        return maticDividendTracker.getLastProcessedIndex();
    }

    function getNumberOfEthDividendTokenHolders() external view returns(uint256) {
        return ethDividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfMaticDividendTokenHolders() external view returns(uint256) {
        return maticDividendTracker.getNumberOfTokenHolders();
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
                    swapTokensForETH(swapTokens);
                    uint256 devPortion = address(this).balance.div(10**2).mul(66);
                    uint256 marketingPortion = address(this).balance.sub(devPortion);
                    transferToWallet(payable(marketingWallet), marketingPortion);
                    transferToWallet(payable(devWallet), devPortion);
                }

                if (buyBackAndLiquifyEnabled) {
                    if(buyBackMode){
                        swapTokensForETH(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }else{
                        swapAndLiquify(contractTokenBalance.div(totalFees).mul(buyBackAndLiquidityFee));
                    }
                }

                if (EthDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(EthDividendRewardsFee);
                    swapAndSendEthDividends(sellTokens.sub(1300));
                }

                if (maticDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(maticDividendRewardsFee);
                    swapAndSendMaticDividends(sellTokens.sub(1300));
                }

                swapping = false;
            }

            if (!swapping && buyBackAndLiquifyEnabled && buyBackMode) {

                uint256 buyBackBalanceEth = address(this).balance;
                if (buyBackBalanceEth >= minimumBalanceRequired && amount >= minimumSellOrderAmount) {
                    swapping = true;

                    if (buyBackBalanceEth > buyBackUpperLimit) {
                        buyBackBalanceEth = buyBackUpperLimit;
                    }

                    buyBackAndBurn(buyBackBalanceEth.div(10**2));

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

        try ethDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try maticDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try ethDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try maticDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            if(rand() <= EthDividendPriority) {

                if( EthDividendEnabled && sendEthInTx ){
                    try ethDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedEthDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( maticDividendEnabled && sendMaticInTx ){
                    try maticDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedMaticDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            } else {
                if( maticDividendEnabled && sendMaticInTx ){
                    try maticDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedMaticDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( EthDividendEnabled && sendEthInTx ){
                    try ethDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedEthDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
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

        swapTokensForETH(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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

        emit SwapETHForTokens(amount, path);
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

    function swapTokensForETH(uint256 tokenAmount) private {
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

    function swapAndSendEthDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), EthDividendToken);
        uint256 EthDividends = IERC20(EthDividendToken).balanceOf(address(this));
        transferDividends(EthDividendToken, address(ethDividendTracker), ethDividendTracker, EthDividends);
    }

    function swapAndSendMaticDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), maticDividendToken);
        uint256 maticDividends = IERC20(maticDividendToken).balanceOf(address(this));
        transferDividends(maticDividendToken, address(maticDividendTracker), maticDividendTracker, maticDividends);
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

contract EthDividendTracker is DividendPayingToken, Ownable {
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

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Eth_Dividend_Tracker", "Ath_Dividend_Tracker", 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619) {
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


contract MaticDividendTracker is DividendPayingToken, Ownable {
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

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Matic_Dividend_Tracker", "Matic_Dividend_Tracker", 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270) {
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