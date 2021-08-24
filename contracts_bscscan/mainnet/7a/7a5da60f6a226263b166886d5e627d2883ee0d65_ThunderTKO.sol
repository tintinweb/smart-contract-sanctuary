// SPDX-License-Identifier: MIT
/**

fee reward 
TKO : 8%
Thoreum   : 2%



*/

pragma solidity ^0.8.4;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract ThunderTKO is ERC20, Ownable {
    using SafeMath for uint256;

    /// constants
    uint256 public constant MAX_FEE_RATE = 25;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public TkoDividendToken;
    address public thorDividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = true;
    bool public marketingEnabled = true;
    bool public buyBackAndLiquifyEnabled = true;
    bool public buyBackMode = true;
    bool public TkoDividendEnabled = true;
    bool public thorDividendEnabled = true;

    bool public sendThorInTx = true;
    bool public sendTkoInTx = true;

    TkoDividendTracker public tkoDividendTracker;
    ThorDividendTracker public thorDividendTracker;

    address public teamWallet;
    address public marketingWallet;

    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken;

    uint256 public buyBackUpperLimit = 1 * 10 ** 18;       //1 BNB

    // Minimum BNB balance before buyback IF lower than this number no buyback
    uint256 public minimumBalanceRequired = 1 * 10 ** 18;   //1 BNB

    // Minimum thor sell order to trigger buyback
    uint256 public minimumSellOrderAmount = 100000 * 10 ** 18;

    uint256 public TkoDividendRewardsFee;
    uint256 public previousTkoDividendRewardsFee;
    uint256 public thorDividendRewardsFee;
    uint256 public previousThorDividendRewardsFee;

    uint256 public TkoDividendPriority = 80;

    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 110;

    uint256 public gasForProcessing = 600000;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a autothor market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateTkoDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateThorDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event BuyBackAndLiquifyEnabledUpdated(bool enabled);
    event MarketingEnabledUpdated(bool enabled);
    event TkoDividendEnabledUpdated(bool enabled);
    event ThorDividendEnabledUpdated(bool enabled);

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

    event ProcessedTkoDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed autothor,
        uint256 gas,
        address indexed processor
    );

    event ProcessedThorDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed autothor,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("ThunderTKO", "ThunderTKO") {
        tkoDividendTracker = new TkoDividendTracker();
        thorDividendTracker = new ThorDividendTracker();

        marketingWallet = 0x6914A8f38C266d302c3369AD83bf94901E25BA59;
        teamWallet = 0x6E057497688030a0037f5D8cc1Dd82788cAF9815;
        TkoDividendToken = 0x9f589e3eabe42ebC94A44727b3f3531C0c877809;
        thorDividendToken = 0x580dE58c1BD593A43DaDcF0A739d504621817c05;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        excludeFromDividend(address(tkoDividendTracker));
        excludeFromDividend(address(thorDividendTracker));
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
        tkoDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        thorDividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn * (10**18);
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn * (10**18);
    }

    function updateThorDividendToken(address _newContract) external onlyOwner {
        thorDividendToken = _newContract;
        thorDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinThorBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        thorDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function updateTkoDividendToken(address _newContract) external onlyOwner {
        TkoDividendToken = _newContract;
        tkoDividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinTkoBeforeSendDividend(uint256 _newAmount) external onlyOwner {
        tkoDividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function getMinThorBeforeSendDividend() external view returns (uint256) {
        return thorDividendTracker.minTokenBeforeSendDividend();
    }

    function getMinTkoBeforeSendDividend() external view returns (uint256) {
        return tkoDividendTracker.minTokenBeforeSendDividend();
    }

    function setSendThorInTx(bool _newStatus) external onlyOwner {
        sendThorInTx = _newStatus;
    }

    function setSendTkoInTx(bool _newStatus) external onlyOwner {
        sendTkoInTx = _newStatus;
    }

    function setTkoDividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        TkoDividendPriority = _newAmount;
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
        TkoDividendRewardsFee = 8;
        thorDividendRewardsFee = 2;
        marketingFee = 3;
        buyBackAndLiquidityFee = 3;
        totalFees = 16;
        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        TkoDividendEnabled = true;
        thorDividendEnabled = true;
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
            totalFees = buyBackAndLiquidityFee.add(marketingFee).add(thorDividendRewardsFee).add(TkoDividendRewardsFee);
            buyBackAndLiquifyEnabled = _enabled;
        }

        emit BuyBackAndLiquifyEnabledUpdated(_enabled);
    }

    function setTkoDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousTkoDividendRewardsFee = TkoDividendRewardsFee;
            TkoDividendRewardsFee = 0;
            TkoDividendEnabled = _enabled;
        } else {
            TkoDividendRewardsFee = previousTkoDividendRewardsFee;
            totalFees = TkoDividendRewardsFee.add(marketingFee).add(thorDividendRewardsFee).add(buyBackAndLiquidityFee);
            TkoDividendEnabled = _enabled;
        }

        emit TkoDividendEnabledUpdated(_enabled);
    }

    function setThorDividendEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousThorDividendRewardsFee = thorDividendRewardsFee;
            thorDividendRewardsFee = 0;
            thorDividendEnabled = _enabled;
        } else {
            thorDividendRewardsFee = previousThorDividendRewardsFee;
            totalFees = thorDividendRewardsFee.add(marketingFee).add(TkoDividendRewardsFee).add(buyBackAndLiquidityFee);
            thorDividendEnabled = _enabled;
        }

        emit ThorDividendEnabledUpdated(_enabled);
    }

    function setMarketingEnabled(bool _enabled) external onlyOwner {
        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            totalFees = marketingFee.add(thorDividendRewardsFee).add(TkoDividendRewardsFee).add(buyBackAndLiquidityFee);
            marketingEnabled = _enabled;
        }

        emit MarketingEnabledUpdated(_enabled);
    }

    function updateTkoDividendTracker(address newAddress) external onlyOwner {
        TkoDividendTracker newTkoDividendTracker = TkoDividendTracker(payable(newAddress));

        require(newTkoDividendTracker.owner() == address(this), "must be owned by ThunderTKO");

        newTkoDividendTracker.excludeFromDividends(address(newTkoDividendTracker));
        newTkoDividendTracker.excludeFromDividends(address(this));
        newTkoDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newTkoDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateTkoDividendTracker(newAddress, address(tkoDividendTracker));

        tkoDividendTracker = newTkoDividendTracker;
    }

    function updateThorDividendTracker(address newAddress) external onlyOwner {
        ThorDividendTracker newThorDividendTracker = ThorDividendTracker(payable(newAddress));

        require(newThorDividendTracker.owner() == address(this), "must be owned by ThunderTKO");

        newThorDividendTracker.excludeFromDividends(address(newThorDividendTracker));
        newThorDividendTracker.excludeFromDividends(address(this));
        newThorDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newThorDividendTracker.excludeFromDividends(address(deadAddress));

        emit UpdateThorDividendTracker(newAddress, address(thorDividendTracker));

        thorDividendTracker = newThorDividendTracker;
    }

    function updateTkoDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        TkoDividendRewardsFee = newFee;
        totalFees = TkoDividendRewardsFee.add(marketingFee).add(thorDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateThorDividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        thorDividendRewardsFee = newFee;
        totalFees = thorDividendRewardsFee.add(TkoDividendRewardsFee).add(marketingFee).add(buyBackAndLiquidityFee);
    }

    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        marketingFee = newFee;
        totalFees = marketingFee.add(TkoDividendRewardsFee).add(thorDividendRewardsFee).add(buyBackAndLiquidityFee);
    }

    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        buyBackAndLiquidityFee = newFee;
        totalFees = buyBackAndLiquidityFee.add(TkoDividendRewardsFee).add(thorDividendRewardsFee).add(marketingFee);
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
        tkoDividendTracker.excludeFromDividends(address(account));
        thorDividendTracker.excludeFromDividends(address(account));
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
            tkoDividendTracker.excludeFromDividends(pair);
            thorDividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
        emit GasForProcessingUpdated(newValue, gasForProcessing);
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        tkoDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        thorDividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        tkoDividendTracker.updateClaimWait(claimWait);
        thorDividendTracker.updateClaimWait(claimWait);
    }

    function getTkoClaimWait() external view returns(uint256) {
        return tkoDividendTracker.claimWait();
    }

    function getThorClaimWait() external view returns(uint256) {
        return thorDividendTracker.claimWait();
    }

    function getTotalTkoDividendsDistributed() external view returns (uint256) {
        return tkoDividendTracker.totalDividendsDistributed();
    }

    function getTotalThorDividendsDistributed() external view returns (uint256) {
        return thorDividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableTkoDividendOf(address account) external view returns(uint256) {
        return tkoDividendTracker.withdrawableDividendOf(account);
    }

    function withdrawableThorDividendOf(address account) external view returns(uint256) {
        return thorDividendTracker.withdrawableDividendOf(account);
    }

    function TkoDividendTokenBalanceOf(address account) external view returns (uint256) {
        return tkoDividendTracker.balanceOf(account);
    }

    function thorDividendTokenBalanceOf(address account) external view returns (uint256) {
        return thorDividendTracker.balanceOf(account);
    }

    function getAccountTkoDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return tkoDividendTracker.getAccount(account);
    }

    function getAccountThorDividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return thorDividendTracker.getAccount(account);
    }

    function getAccountTkoDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return tkoDividendTracker.getAccountAtIndex(index);
    }

    function getAccountThorDividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return thorDividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 TkoIterations, uint256 TkoClaims, uint256 TkoLastProcessedIndex) = tkoDividendTracker.process(gas);
        emit ProcessedTkoDividendTracker(TkoIterations, TkoClaims, TkoLastProcessedIndex, false, gas, tx.origin);

        (uint256 thorIterations, uint256 thorClaims, uint256 thorLastProcessedIndex) = thorDividendTracker.process(gas);
        emit ProcessedThorDividendTracker(thorIterations, thorClaims, thorLastProcessedIndex, false, gas, tx.origin);
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
        tkoDividendTracker.processAccount(payable(msg.sender), false);
        thorDividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastTkoDividendProcessedIndex() external view returns(uint256) {
        return tkoDividendTracker.getLastProcessedIndex();
    }

    function getLastThorDividendProcessedIndex() external view returns(uint256) {
        return thorDividendTracker.getLastProcessedIndex();
    }

    function getNumberOfTkoDividendTokenHolders() external view returns(uint256) {
        return tkoDividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfThorDividendTokenHolders() external view returns(uint256) {
        return thorDividendTracker.getNumberOfTokenHolders();
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

                if (TkoDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(TkoDividendRewardsFee);
                    swapAndSendTkoDividends(sellTokens.sub(1300));
                }

                if (thorDividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.div(totalFees).mul(thorDividendRewardsFee);
                    swapAndSendThorDividends(sellTokens.sub(1300));
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

        try tkoDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try thorDividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try tkoDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try thorDividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            if(rand() <= TkoDividendPriority) {

                if( TkoDividendEnabled && sendTkoInTx ){
                    try tkoDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedTkoDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( thorDividendEnabled && sendThorInTx ){
                    try thorDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedThorDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            } else {
                if( thorDividendEnabled && sendThorInTx ){
                    try thorDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedThorDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( TkoDividendEnabled && sendTkoInTx ){
                    try tkoDividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedTkoDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
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

    function swapAndSendTkoDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), TkoDividendToken);
        uint256 TkoDividends = IERC20(TkoDividendToken).balanceOf(address(this));
        transferDividends(TkoDividendToken, address(tkoDividendTracker), tkoDividendTracker, TkoDividends);
    }

    function swapAndSendThorDividends(uint256 tokens) private {
        swapTokensForDividendToken(tokens, address(this), thorDividendToken);
        uint256 thorDividends = IERC20(thorDividendToken).balanceOf(address(this));
        transferDividends(thorDividendToken, address(thorDividendTracker), thorDividendTracker, thorDividends);
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

contract TkoDividendTracker is DividendPayingToken, Ownable {
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

    event Claim(address indexed account, uint256 amount, bool indexed autothor);

    constructor() DividendPayingToken("Tko_Dividend_Tracker", "Tko_Dividend_Tracker", 0x9f589e3eabe42ebC94A44727b3f3531C0c877809) {
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

    function processAccount(address payable account, bool autothor) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, autothor);
            return true;
        }

        return false;
    }
}


contract ThorDividendTracker is DividendPayingToken, Ownable {
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

    event Claim(address indexed account, uint256 amount, bool indexed autothor);

    constructor() DividendPayingToken("Thor_Dividend_Tracker", "Thor_Dividend_Tracker", 0x580dE58c1BD593A43DaDcF0A739d504621817c05) {
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

    function processAccount(address payable account, bool autothor) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, autothor);
            return true;
        }

        return false;
    }
}