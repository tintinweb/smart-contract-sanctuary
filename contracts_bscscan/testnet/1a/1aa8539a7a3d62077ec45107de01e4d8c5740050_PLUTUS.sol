// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract PLUTUS is ERC20, Ownable {
    using SafeMath for uint256;

    // Mappings
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private canTransferBeforeTradingIsEnabled;
    mapping(address => bool) public blacklist;

    // Allocations
    uint256 public _devTokenAllocation;
    uint256 public _dreamTokenAllocation;
    uint256 public _treasuryTokenAllocation;
    uint256 public _liquidityTokenAllocation;
    uint256 public _bnbRewardsTokenAllocation;

    // Buy fees
    uint256 private _liquidityFeeOnBuy = 2;
    uint256 private _devFeeOnBuy = 1;
    uint256 private _dreamFeeOnBuy = 0;
    uint256 private _treasuryFeeOnBuy = 4;
    uint256 private _bnbRewardsFeeOnBuy = 3;
    // Sell fees
    uint256 private _liquidityFeeOnSell = 1;
    uint256 private _devFeeOnSell = 1;
    uint256 private _dreamFeeOnSell = 2;
    uint256 private _treasuryFeeOnSell = 6;
    uint256 private _bnbRewardsFeeOnSell = 0;

    uint256 private _devFee = _devFeeOnSell;
    uint256 private _dreamFee = _dreamFeeOnSell;
    uint256 private _treasuryFee = _treasuryFeeOnSell;
    uint256 private _liquidityFee = _liquidityFeeOnSell;
    uint256 private _bnbRewardsFee = _bnbRewardsFeeOnSell;
    uint256 private _taxFee =
        _liquidityFeeOnSell
            .add(_devFee)
            .add(_dreamFee)
            .add(_treasuryFee)
            .add(_liquidityFee)
            .add(_bnbRewardsFee);

    address payable public _developmentAddress =
        payable(0xb61719587d14249FE45B951cDb3e557c4B8e8e54);
    address payable public _treasuryAddress =
        payable(0x7B0138C49570F78d45a07fCEcc11E70e605f33dB);
    address payable public _dreamAddress =
        payable(0x2d6DE6Af5672d466CBb6d4c32915E1A558d037Da);

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private InSwap;
    bool private swapEnabled = true;

    PLUTUSDividendTracker public dividendTracker;

    uint256 public _maxWalletSize = 2500000 * (10**18);
    uint256 public _maxTxAmount = 1000000 * (10**18);
    uint256 public _tokenSwapThreshold = 200000 * (10**18);
    uint256 public _gasForProcessing = 300000;

    // timestamp for when the token can be traded freely on PanackeSwap
    uint256 private tradingEnabledTimestamp = 1643041773;

    // Events
    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("PLUTUS CAPITAL", "PLUTUS") {
        dividendTracker = new PLUTUSDividendTracker();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(_developmentAddress, true);
        excludeFromFees(_treasuryAddress, true);
        excludeFromFees(_dreamAddress, true);

        // enable owner and fixed-sale wallet to send tokens before presales are over
        canTransferBeforeTradingIsEnabled[owner()] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000 * (10**18));
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getTradingIsEnabled() public view returns (bool) {
        return block.timestamp >= tradingEnabledTimestamp;
    }

    // Transfer logic
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !blacklist[from] && !blacklist[to],
            "TOKEN: Your account is blacklisted!"
        );

        if (
            (from != owner() && to != owner()) ||
            (from != _treasuryAddress && to != _treasuryAddress)
        ) {
            bool tradingIsEnabled = getTradingIsEnabled();

            // only whitelisted addresses can make transfers after the fixed-sale has started
            // and before the public presale is over
            if (!tradingIsEnabled) {
                require(
                    canTransferBeforeTradingIsEnabled[from],
                    "PLUTUS: This account cannot send tokens until trading is enabled"
                );
            }

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to) + amount < _maxWalletSize,
                    "TOKEN: Balance exceeds wallet size!"
                );
            }

            if (
                !InSwap &&
                tradingIsEnabled &&
                from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
                !_isExcludedFromFees[to] //no max for those excluded from fees
            ) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the _maxTxAmount."
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool shouldSwap = contractTokenBalance >= _tokenSwapThreshold;

            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }

            if (
                tradingIsEnabled &&
                shouldSwap &&
                swapEnabled &&
                !InSwap &&
                from != uniswapV2Pair
            ) {
                InSwap = true;

                // Liquidity
                swapAndLiquify();
                _liquidityTokenAllocation = 0;

                // Rewards
                swapAndSendDividends();
                _bnbRewardsTokenAllocation = 0;

                // Remaining fees
                swapAndSendRemainingFees();
                _devTokenAllocation = 0;
                _dreamTokenAllocation = 0;
                _treasuryTokenAllocation = 0;

                InSwap = false;
            }
        }

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            (_isExcludedFromFees[from] || _isExcludedFromFees[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _devFee = _devFeeOnBuy;
                _dreamFee = _dreamFeeOnBuy;
                _treasuryFee = _treasuryFeeOnBuy;
                _liquidityFee = _liquidityFeeOnBuy;
                _bnbRewardsFee = _bnbRewardsFeeOnBuy;
                _taxFee = _devFee
                    .add(_dreamFee)
                    .add(_treasuryFee)
                    .add(_liquidityFee)
                    .add(_bnbRewardsFee);
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _devFee = _devFeeOnSell;
                _dreamFee = _dreamFeeOnSell;
                _treasuryFee = _treasuryFeeOnSell;
                _liquidityFee = _liquidityFeeOnSell;
                _bnbRewardsFee = _bnbRewardsFeeOnSell;
                _taxFee = _devFee
                    .add(_dreamFee)
                    .add(_treasuryFee)
                    .add(_liquidityFee)
                    .add(_bnbRewardsFee);
            }
        }

        if (takeFee) {
            uint256 fees = amount.mul(_taxFee).div(100);

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
            _setTokenAllocation(fees);
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!InSwap) {
            uint256 gas = _gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function _setTokenAllocation(uint256 amount) private {
        uint256 devPercentage = _devFee.mul(100).div(_taxFee);
        uint256 dreamPercentage = _dreamFee.mul(100).div(_taxFee);
        uint256 treasuryPercentage = _treasuryFee.mul(100).div(_taxFee);
        uint256 liquidityPercentage = _liquidityFee.mul(100).div(_taxFee);
        uint256 bnbRewardsPercentage = _bnbRewardsFee.mul(100).div(_taxFee);

        uint256 devAmount = amount.mul(devPercentage).div(100);
        uint256 dreamAmount = amount.mul(dreamPercentage).div(100);
        uint256 treasuryAmount = amount.mul(treasuryPercentage).div(100);
        uint256 liquidityAmount = amount.mul(liquidityPercentage).div(100);
        uint256 bnbRewardsAmount = amount.mul(bnbRewardsPercentage).div(100);

        _devTokenAllocation = _devTokenAllocation.add(devAmount);
        _dreamTokenAllocation = _dreamTokenAllocation.add(dreamAmount);
        _treasuryTokenAllocation = _treasuryTokenAllocation.add(treasuryAmount);
        _liquidityTokenAllocation = _liquidityTokenAllocation.add(
            liquidityAmount
        );
        _bnbRewardsTokenAllocation = _bnbRewardsTokenAllocation.add(
            bnbRewardsAmount
        );
    }

    function swapAndLiquify() private {
        uint256 tokens = _liquidityTokenAllocation;

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
    }

    function swapAndSendRemainingFees() private {
        uint256 tokens = balanceOf(address(this));
        swapTokensForEth(tokens);
        uint256 ethAmount = address(this).balance;

        uint256 devPercentage = _devTokenAllocation.mul(100).div(tokens);
        uint256 dreamPercentage = _dreamTokenAllocation.mul(100).div(tokens);

        uint256 devETHAmount = ethAmount.mul(devPercentage).div(100);
        uint256 dreamETHAmount = ethAmount.mul(dreamPercentage).div(100);

        (bool successDev, ) = _developmentAddress.call{value: devETHAmount}("");
        (bool successDream, ) = _dreamAddress.call{value: dreamETHAmount}("");

        uint256 remainingEthAmount = address(this).balance;
        (bool successTreasury, ) = _treasuryAddress.call{
            value: remainingEthAmount
        }("");

        require(successDev, "Tx Failed");
        require(successDream, "Tx failed");
        require(successTreasury, "Tx Failed");
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // Token management functions
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "PLUTUS: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "PLUTUS: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setDevWalletAddress(address payable wallet) external onlyOwner {
        _developmentAddress = wallet;
    }

    function setTreasuryWalletAddress(address payable wallet)
        external
        onlyOwner
    {
        _treasuryAddress = wallet;
    }

    function setDreamWalletAddress(address payable wallet) external onlyOwner {
        _dreamAddress = wallet;
    }

    function setFee(
        uint256 liquidityFeeBuy,
        uint256 devFeeBuy,
        uint256 dreamFeeBuy,
        uint256 treasuryFeeBuy,
        uint256 liquidityFeeSell,
        uint256 devFeeSell,
        uint256 dreamFeeSell,
        uint256 treasuryFeeSell,
        uint256 bnbRewardsFeeBuy,
        uint256 bnbRewardsFeeSell
    ) public onlyOwner {
        _liquidityFeeOnBuy = liquidityFeeBuy;
        _devFeeOnBuy = devFeeBuy;
        _dreamFeeOnBuy = dreamFeeBuy;
        _treasuryFeeOnBuy = treasuryFeeBuy;
        _liquidityFeeOnSell = liquidityFeeSell;
        _devFeeOnSell = devFeeSell;
        _dreamFeeOnSell = dreamFeeSell;
        _treasuryFeeOnSell = treasuryFeeSell;
        _bnbRewardsFeeOnBuy = bnbRewardsFeeBuy;
        _bnbRewardsFeeOnSell = bnbRewardsFeeSell;
    }

    function setMinSwapTokensThreshold(uint256 tokenSwapThreshold)
        public
        onlyOwner
    {
        _tokenSwapThreshold = tokenSwapThreshold;
    }

    function setSwapEnabled(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function setCanTransferBeforeTradingIsEnabled(
        address account,
        bool canTransfer
    ) public onlyOwner {
        canTransferBeforeTradingIsEnabled[account] = canTransfer;
    }

    function blacklistAddresses(address[] memory _blacklist, bool canTrade)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _blacklist.length; i++) {
            blacklist[_blacklist[i]] = !canTrade;
        }
    }

    // Dividend logic
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "PLUTUS: The dividend tracker already has that address"
        );

        PLUTUSDividendTracker newDividendTracker = PLUTUSDividendTracker(
            payable(newAddress)
        );

        require(
            newDividendTracker.owner() == address(this),
            "PLUTUS: The new dividend tracker must be owned by the PLUTUS token contract"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "PLUTUS: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != _gasForProcessing,
            "PLUTUS: Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, _gasForProcessing);
        _gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function swapAndSendDividends() private {
        uint256 tokens = _bnbRewardsTokenAllocation;
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success, ) = address(dividendTracker).call{value: dividends}("");

        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }

    // Enable the current contract to receive BNB
    receive() external payable {}
}

contract PLUTUSDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor()
        DividendPayingToken(
            "PLUTUS_Dividend_Tracker",
            "PLUTUS_Dividend_Tracker"
        )
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        require(false, "PLUTUS_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(
            false,
            "PLUTUS_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main PLUTUS contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "PLUTUS_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "PLUTUS_Dividend_Tracker: Cannot update claimWait to same value"
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}