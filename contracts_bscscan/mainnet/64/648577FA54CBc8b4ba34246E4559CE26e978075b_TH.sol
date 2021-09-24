// SPDX-License-Identifier: MIT

//
// DIVIDEND YIELD PAID IN BNB! With the auto-claim feature,
// simply hold $TH and you'll receive BNB automatically in your wallet.
//
// Hold TH and get rewarded in BNB on every transaction!
//
//
// 📱 Telegram: https://t.me/THOfficial
// 🌎 Website: https://TH.io/
// 🌐 Twitter: https://twitter.com/THofficial
//

pragma solidity ^0.8.6;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract TH is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    mapping(address => uint256) private _lastTrade;

    uint256 public coolDownTime = 600 seconds;

    THDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public BNB = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);

    uint256 public maxTxPercent = 5;
    uint256 public swapTokensAtAmount = 2000000 * (10**18);

    uint256 public RewardsFee = 7;
    uint256 public liquidityFee = 4;
    uint256 public marketingFee = 2;
    uint256 public totalFees = RewardsFee.add(liquidityFee).add(marketingFee);

    address payable public marketingWallet = payable(0xF76d91704C51614dFD028D349A5Dc058A12b2866);

    uint256 public gasForProcessing = 300000;

    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

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

    constructor() ERC20("TH", "TH") {

        dividendTracker = new THDividendTracker();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);

        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "TH: The dividend tracker already has that address");

        THDividendTracker newDividendTracker = THDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "TH: The new dividend tracker must be owned by the TH token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "TH: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TH: Account is already the value of 'excluded'");
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
        marketingWallet = wallet;
    }

    function setRewardsFee(uint256 value) external onlyOwner{
        RewardsFee = value;
        totalFees = RewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = RewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = RewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMaxTxPercent(uint256 value) external onlyOwner{
        maxTxPercent = value;
    }

    function setCoolDownTime(uint256 value) external onlyOwner{
        coolDownTime = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "TH: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "TH: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "TH: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "TH: Cannot update gasForProcessing to same value");
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

    function excludeFromDividendsBool(address account, bool excluded) external onlyOwner{
        dividendTracker.excludeFromDividendsBool(account, excluded);
    }
    function excludeMultipleAccountsFromDividendsBool(address[] calldata accounts, bool excluded) external onlyOwner{
        dividendTracker.excludeMultipleAccountsFromDividendsBool(accounts, excluded);
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

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount;
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

    function checkAntiWhale(uint256 amount) internal view returns(bool){
        uint256 totLiquidity;
        if(address(this) == IUniswapV2Pair(uniswapV2Pair).token0()){
            (totLiquidity,,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }
        else{
            (,totLiquidity,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        }
        if(amount <= totLiquidity.mul(maxTxPercent).div(100)){
            return true;
        }
        else return false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(!_isExcludedFromFees[from] && automatedMarketMakerPairs[to]){
            uint256 timePassed = block.timestamp - _lastTrade[from];
            require(timePassed >= coolDownTime, "You must wait 30 seconds");
            _lastTrade[from] = block.timestamp;
        }

        if(!_isExcludedFromFees[to] && automatedMarketMakerPairs[from]){
            uint256 timePassed = block.timestamp - _lastTrade[to];
            require(timePassed >= coolDownTime, "You must wait 30 seconds");
            _lastTrade[to] = block.timestamp;
        }

        if(!_isExcludedFromFees[to] && !_isExcludedFromFees[from] && !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]){
            uint256 timePassed1 = block.timestamp - _lastTrade[to];
            uint256 timePassed2 = block.timestamp - _lastTrade[from];
            require(timePassed1 >= coolDownTime && timePassed2 >= coolDownTime, "You must wait 30 seconds");
            _lastTrade[to] = block.timestamp;
            _lastTrade[from] = block.timestamp;
        }

        if(
            !swapping &&
            !_isExcludedFromFees[to] &&
            !_isExcludedFromFees[from]
        ) {
            require(checkAntiWhale(amount), "Amount is exceeding maxTxPercent");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from]
        ) {
            swapping = true;

            contractTokenBalance = swapTokensAtAmount;

            if(marketingFee > 0){
                uint256 feeTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
                swapAndSendToFee(feeTokens);
            }

            if(liquidityFee > 0){
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
                swapAndLiquify(swapTokens);
            }
            if(RewardsFee > 0){
                uint256 sellTokens = contractTokenBalance.mul(RewardsFee).div(totalFees);
                swapAndSendDividends(sellTokens);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
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

    function swapAndSendToFee(uint256 tokens) private{
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);

        if(marketingFee > 0){
            marketingWallet.transfer(newBalance.div(totalFees).mul(marketingFee));
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

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

    function swapTokensForADA(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BNB;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForADA(tokens);
        uint256 dividends = IERC20(BNB).balanceOf(address(this));
        bool success = IERC20(BNB).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeRewardDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract THDividendTracker is Ownable, DividendPayingToken {
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
    event ExcludeFromDividendsBool(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromDividendsBool(address[] accounts, bool isExcluded);

    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor()  DividendPayingToken("TH_Dividen_Tracker", "TH_Dividend_Tracker") {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 200000 * (10**9);
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "TH_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "TH_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main TH contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function excludeFromDividendsBool(address account, bool excluded) external onlyOwner {
        require(excludedFromDividends[account] != excluded, "TH: Account is already the value of 'excluded'");
        excludedFromDividends[account] = excluded;

        emit ExcludeFromDividendsBool(account, excluded);
    }

    function excludeMultipleAccountsFromDividendsBool(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            excludedFromDividends[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromDividendsBool(accounts, excluded);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "TH_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "TH_Dividend_Tracker: Cannot update claimWait to same value");
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