// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Uniswap.sol";

import "./A80DividendTracker.sol";
import "./B20DividendTracker.sol";


contract Daima is ERC20, Ownable {
    using SafeMath for uint256;

    /// constants
    uint256 public constant MAX_FEE_RATE = 25;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public a80DividendToken;
    address public b20DividendToken;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    bool private swapping;
    bool public tradingIsEnabled = false;
    bool public marketingEnabled = false;
    bool public buyBackAndLiquifyEnabled = false;
    bool public buyBackMode = true;
    bool public a80DividendEnabled = false;
    bool public b20DividendEnabled = false;

    bool public sendA80InTx = true;
    bool public sendB20InTx = true;

    A80DividendTracker public a80DividendTracker;
    B20DividendTracker public b20DividendTracker;

    address public marketingWallet;

    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWalletToken;

    uint256 public buyBackUpperLimit = 1 * 10 ** 18;        //1 BNB

    // Minimum BNB balance before buyback IF lower than this number no buyback
    uint256 public minimumBalanceRequired = 1 * 10 ** 18;   //1 BNB

    uint256 public minimumSellOrderAmount = 100000 * 10 ** 18;

    uint256 public a80DividendRewardsFee;
    uint256 public previousA80DividendRewardsFee;
    uint256 public b20DividendRewardsFee;
    uint256 public previousB20DividendRewardsFee;

    uint256 public a80DividendPriority = 80;

    uint256 public marketingFee;
    uint256 public previousMarketingFee;
    uint256 public buyBackAndLiquidityFee;
    uint256 public previousBuyBackAndLiquidityFee;
    uint256 public totalFees;

    uint256 public sellFeeIncreaseFactor = 150;

    uint256 public gasForProcessing = 600000;

    mapping (address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
        uint256 amount
    );

    event ProcessedA80DividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event ProcessedB20DividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address payable a80Tracker, address payable b20Tracker) ERC20("Daima Token", "Daima") {
        a80DividendTracker = A80DividendTracker(a80Tracker);
        b20DividendTracker = B20DividendTracker(b20Tracker);

        marketingWallet = 0xBC394A3A0f1f6D8b271F7456b425c10Fb147105a;

        a80DividendToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // mainnet WBNB address
        b20DividendToken = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;  // mainnet Banana address

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7); //BSC Mainnet Router
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //BSC Testnet Router

        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        _totalSupply = 100 * 10**9 * (10**18);
        _balances[owner()] = _balances[owner()].add(_totalSupply);
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {

    }

    function prepareForPartnerOrExchangeListing(address _partnerOrExchangeAddress) external onlyOwner {
        a80DividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        b20DividendTracker.excludeFromDividends(_partnerOrExchangeAddress);
        excludeFromFees(_partnerOrExchangeAddress, true);
    }

    function setMaxBuyTransaction(uint256 _maxTxn) external onlyOwner {
        maxBuyTransactionAmount = _maxTxn * (10**18);
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn * (10**18);
    }

    function updateA80DividendToken(address _newContract) external onlyOwner {
        a80DividendToken = _newContract;
        a80DividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateB20DividendToken(address _newContract) external onlyOwner {
        b20DividendToken = _newContract;
        b20DividendTracker.setDividendTokenAddress(_newContract);
    }

    function updateMinA80BeforeSendDividend(uint256 _newAmount) external onlyOwner {
        a80DividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function updateMinB20BeforeSendDividend(uint256 _newAmount) external onlyOwner {
        b20DividendTracker.setMinTokenBeforeSendDividend(_newAmount);
    }

    function getMinA80BeforeSendDividend() external view returns (uint256) {
        return a80DividendTracker.minTokenBeforeSendDividend();
    }

    function getMinB20BeforeSendDividend() external view returns (uint256) {
        return b20DividendTracker.minTokenBeforeSendDividend();
    }

    function setSendA80InTx(bool _newStatus) external onlyOwner {
        sendA80InTx = _newStatus;
    }

    function setSendB20InTx(bool _newStatus) external onlyOwner {
        sendB20InTx = _newStatus;
    }

    function setA80DividendPriority(uint256 _newAmount) external onlyOwner {
        require(_newAmount >= 0 && _newAmount <= 100, "Error amount");
        a80DividendPriority = _newAmount;
    }

    function updateMarketingWallet(address _newWallet) external onlyOwner {
        excludeFromFees(_newWallet, true);
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

    function afterPreSale() external onlyOwner {
        a80DividendRewardsFee = 8;
        b20DividendRewardsFee = 2;
        marketingFee = 4;
        buyBackAndLiquidityFee = 4;

        _updateTotalFee();

        marketingEnabled = true;
        buyBackAndLiquifyEnabled = true;
        a80DividendEnabled = true;
        b20DividendEnabled = true;
        swapTokensAtAmount = 30000000 * (10**18);
        maxBuyTransactionAmount = 1000000000 * (10**18);
        maxSellTransactionAmount = 50000000 * (10**18);
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

    function _updateTotalFee() internal {
        totalFees = buyBackAndLiquidityFee.add(marketingFee).add(a80DividendRewardsFee).add(b20DividendRewardsFee);
    }

    function setBuyBackAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(buyBackAndLiquifyEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousBuyBackAndLiquidityFee = buyBackAndLiquidityFee;
            buyBackAndLiquidityFee = 0;
            buyBackAndLiquifyEnabled = _enabled;
        } else {
            buyBackAndLiquidityFee = previousBuyBackAndLiquidityFee;
            buyBackAndLiquifyEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setA80DividendEnabled(bool _enabled) external onlyOwner {
        require(a80DividendEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousA80DividendRewardsFee = a80DividendRewardsFee;
            a80DividendRewardsFee = 0;
            a80DividendEnabled = _enabled;
        } else {
            a80DividendRewardsFee = previousA80DividendRewardsFee;
            a80DividendEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setB20DividendEnabled(bool _enabled) external onlyOwner {
        require(b20DividendEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousB20DividendRewardsFee = b20DividendRewardsFee;
            b20DividendRewardsFee = 0;
            b20DividendEnabled = _enabled;
        } else {
            b20DividendRewardsFee = previousB20DividendRewardsFee;
            b20DividendEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function setMarketingEnabled(bool _enabled) external onlyOwner {
        require(marketingEnabled != _enabled, "Not changed");

        if (_enabled == false) {
            previousMarketingFee = marketingFee;
            marketingFee = 0;
            marketingEnabled = _enabled;
        } else {
            marketingFee = previousMarketingFee;
            marketingEnabled = _enabled;
        }
        _updateTotalFee();
    }

    function updateA80DividendTracker(address newAddress) external onlyOwner {
        A80DividendTracker newA80DividendTracker = A80DividendTracker(payable(newAddress));

        require(newA80DividendTracker.owner() == address(this), "must be owned by Daima");

        newA80DividendTracker.excludeFromDividends(address(newA80DividendTracker));
        newA80DividendTracker.excludeFromDividends(address(this));
        newA80DividendTracker.excludeFromDividends(address(uniswapV2Router));
        newA80DividendTracker.excludeFromDividends(address(deadAddress));

        a80DividendTracker = newA80DividendTracker;
    }

    function updateB20DividendTracker(address newAddress) external onlyOwner {
        B20DividendTracker newB20DividendTracker = B20DividendTracker(payable(newAddress));

        require(newB20DividendTracker.owner() == address(this), "must be owned by Daima");

        newB20DividendTracker.excludeFromDividends(address(newB20DividendTracker));
        newB20DividendTracker.excludeFromDividends(address(this));
        newB20DividendTracker.excludeFromDividends(address(uniswapV2Router));
        newB20DividendTracker.excludeFromDividends(address(deadAddress));

        b20DividendTracker = newB20DividendTracker;
    }

    function updateA80DividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        a80DividendRewardsFee = newFee;
        _updateTotalFee();
    }

    function updateB20DividendRewardFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        b20DividendRewardsFee = newFee;
        _updateTotalFee();
    }

    function updateMarketingFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        marketingFee = newFee;
        _updateTotalFee();
    }

    function updateBuyBackAndLiquidityFee(uint8 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_RATE, "wrong");
        buyBackAndLiquidityFee = newFee;
        _updateTotalFee();
    }

    function updateUniswapV2Router(address newAddress) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Already excluded");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromDividend(address account) public onlyOwner {
        a80DividendTracker.excludeFromDividends(address(account));
        b20DividendTracker.excludeFromDividends(address(account));
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            a80DividendTracker.excludeFromDividends(pair);
            b20DividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        gasForProcessing = newValue;
    }

    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        a80DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
        b20DividendTracker.updateMinimumTokenBalanceForDividends(newMinimumBalance);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        a80DividendTracker.updateClaimWait(claimWait);
        b20DividendTracker.updateClaimWait(claimWait);
    }

    function getA80ClaimWait() external view returns(uint256) {
        return a80DividendTracker.claimWait();
    }

    function getB20ClaimWait() external view returns(uint256) {
        return b20DividendTracker.claimWait();
    }

    function getTotalA80DividendsDistributed() external view returns (uint256) {
        return a80DividendTracker.totalDividendsDistributed();
    }

    function getTotalB20DividendsDistributed() external view returns (uint256) {
        return b20DividendTracker.totalDividendsDistributed();
    }

    function getIsExcludedFromFees(address account) public view returns(bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableA80DividendOf(address account) external view returns(uint256) {
        return a80DividendTracker.withdrawableDividendOf(account);
    }

    function withdrawableB20DividendOf(address account) external view returns(uint256) {
        return b20DividendTracker.withdrawableDividendOf(account);
    }

    function a80DividendTokenBalanceOf(address account) external view returns (uint256) {
        return a80DividendTracker.balanceOf(account);
    }

    function b20DividendTokenBalanceOf(address account) external view returns (uint256) {
        return b20DividendTracker.balanceOf(account);
    }

    function getAccountA80DividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return a80DividendTracker.getAccount(account);
    }

    function getAccountB20DividendsInfo(address account)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return b20DividendTracker.getAccount(account);
    }

    function getAccountA80DividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return a80DividendTracker.getAccountAtIndex(index);
    }

    function getAccountB20DividendsInfoAtIndex(uint256 index)
    external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return b20DividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external onlyOwner {
        (uint256 aIterations, uint256 aClaims, uint256 aLastProcessedIndex) = a80DividendTracker.process(gas);
        emit ProcessedA80DividendTracker(aIterations, aClaims, aLastProcessedIndex, false, gas, tx.origin);

        (uint256 bIterations, uint256 bClaims, uint256 bLastProcessedIndex) = b20DividendTracker.process(gas);
        emit ProcessedB20DividendTracker(bIterations, bClaims, bLastProcessedIndex, false, gas, tx.origin);
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
        a80DividendTracker.processAccount(payable(msg.sender), false);
        b20DividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastA80DividendProcessedIndex() external view returns(uint256) {
        return a80DividendTracker.getLastProcessedIndex();
    }

    function getLastB20DividendProcessedIndex() external view returns(uint256) {
        return b20DividendTracker.getLastProcessedIndex();
    }

    function getNumberOfA80DividendTokenHolders() external view returns(uint256) {
        return a80DividendTracker.getNumberOfTokenHolders();
    }

    function getNumberOfB20DividendTokenHolders() external view returns(uint256) {
        return b20DividendTracker.getNumberOfTokenHolders();
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
            require(amount <= maxBuyTransactionAmount, "Error amount");

            uint256 contractBalanceRecipient = balanceOf(to);
            require(contractBalanceRecipient + amount <= maxWalletToken, "Error amount");
        } else if (
            tradingIsEnabled &&
            automatedMarketMakerPairs[to] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Error amount");

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!swapping && contractTokenBalance >= swapTokensAtAmount) {
                swapping = true;

                if(marketingEnabled && buyBackAndLiquifyEnabled && buyBackMode){
                    uint256 total2Fees = marketingFee.add(buyBackAndLiquidityFee);

                    uint256 swapTokens = contractTokenBalance.mul(total2Fees).div(totalFees);

                    uint256 beforeAmount = address(this).balance;
                    swapTokensForBNB(swapTokens);
                    uint256 increaseAmount = address(this).balance.sub(beforeAmount);

                    if(increaseAmount > 0){
                        uint256 marketingPortion = increaseAmount.mul(marketingFee).div(total2Fees);
                        transferToWallet(payable(marketingWallet), marketingPortion);
                    }
                }else{
                    if (marketingEnabled) {
                        uint256 swapTokens = contractTokenBalance.mul(marketingFee).div(totalFees);

                        uint256 beforeAmount = address(this).balance;
                        swapTokensForBNB(swapTokens);
                        uint256 increaseAmount = address(this).balance.sub(beforeAmount);

                        if(increaseAmount > 0){
                            transferToWallet(payable(marketingWallet), increaseAmount);
                        }
                    }

                    if (buyBackAndLiquifyEnabled) {
                        if(buyBackMode){
                            swapTokensForBNB(contractTokenBalance.mul(buyBackAndLiquidityFee).div(totalFees));
                        }else{
                            swapAndLiquify(contractTokenBalance.mul(buyBackAndLiquidityFee).div(totalFees));
                        }
                    }
                }

                if (a80DividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.mul(a80DividendRewardsFee).div(totalFees);
                    swapAndSendA80Dividends(sellTokens.sub(1300));
                }

                if (b20DividendEnabled) {
                    uint256 sellTokens = contractTokenBalance.mul(b20DividendRewardsFee).div(totalFees);
                    swapAndSendB20Dividends(sellTokens.sub(1300));
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
            uint256 fees = amount.mul(totalFees).div(100);

            // if sell, multiply by sellFeeIncreaseFactor
            if(automatedMarketMakerPairs[to]) {
                fees = fees.mul(sellFeeIncreaseFactor).div(100);
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try a80DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try b20DividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try a80DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        try b20DividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping && to != deadAddress) {
            uint256 gas = gasForProcessing;

            if(rand() <= a80DividendPriority) {
                if( a80DividendEnabled && sendA80InTx ){
                    try a80DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedA80DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( b20DividendEnabled && sendB20InTx ){
                    try b20DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedB20DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }
            } else {
                if( b20DividendEnabled && sendB20InTx ){
                    try b20DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedB20DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
                    }
                    catch {

                    }
                }

                if( a80DividendEnabled && sendA80InTx ){
                    try a80DividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                        emit ProcessedA80DividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
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
            block.timestamp.add(300)
        );
    }

    function buyBackAndBurn(uint256 amount) private {
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
            block.timestamp.add(300)
        );

    }

    function swapTokensForDividendToken(uint256 _tokenAmount, address _recipient, address _dividendAddress) private {
        address[] memory path;

        if(uniswapV2Router.WETH() == _dividendAddress){
            path = new address[](2);
            path[0] = address(this);
            path[1] = _dividendAddress;
        }else{
            path = new address[](3);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();
            path[2] = _dividendAddress;
        }

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of dividend token
            path,
            _recipient,
            block.timestamp.add(300)
        );
    }

    function swapAndSendA80Dividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(a80DividendToken).balanceOf(address(a80DividendTracker));

        swapTokensForDividendToken(tokens, address(a80DividendTracker), a80DividendToken);

        uint256 a80Dividends = IERC20(a80DividendToken).balanceOf(address(a80DividendTracker)).sub(beforeAmount);

        if(a80Dividends > 0){
            a80DividendTracker.distributeDividends(a80Dividends);
            emit SendDividends(a80Dividends);
        }
    }

    function swapAndSendB20Dividends(uint256 tokens) private {
        uint256 beforeAmount = IERC20(b20DividendToken).balanceOf(address(b20DividendTracker));

        swapTokensForDividendToken(tokens, address(b20DividendTracker), b20DividendToken);

        uint256 b20Dividends = IERC20(b20DividendToken).balanceOf(address(b20DividendTracker)).sub(beforeAmount);

        if(b20Dividends > 0){
            b20DividendTracker.distributeDividends(b20Dividends);
            emit SendDividends(b20Dividends);
        }
    }

    function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
}