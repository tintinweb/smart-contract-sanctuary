// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract ZOMBIECAKE is ERC20, Ownable {
    using SafeMath for uint256;

    bool private swapping;
    bool public swapAndLiquifyEnabled;
    uint256 public stage; // 0 - in presale

    uint256 public swapTokensAtAmount = 5000000 * (10**18);
    uint256 public _maxTxAmount = 50000000 * (10**18);
    uint256 public _minTxAmountForLotteryTicket = 166666 * (10**18);

    // lottery
    uint256 public lotteryPoolCapacity;
    address[] public players;
    uint256 public winnerCount = 3;
    address[] public winners;

    // tax
    uint256 public rewardsFee = 6;
    uint256 public liquidityFee = 1;
    uint256 public lotteryFee = 1;
    uint256 public marketingFee = 2;
    uint256 public totalFees =
        rewardsFee.add(liquidityFee).add(lotteryFee).add(marketingFee);

    // address
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    ZOMBIECAKEDividendTracker public dividendTracker;
    address public CAKE = address(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    address public _marketingWalletAddress =
        0x94Cf4005774eDdb9ffdbc6CEA452C72717E39D29;
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

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

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
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

    constructor() public ERC20("ZombieCake", "ZC") {
        dividendTracker = new ZOMBIECAKEDividendTracker();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000 * (10**18));
    }

    function setWinnerCount(uint256 val) external onlyOwner {
        require(val > 0);
        winnerCount = val;
    }

    function getPlayers() public view returns (uint256) {
        return players.length;
    }

    function getWinners() internal {
        delete winners;
        if (players.length <= winnerCount) {
            winners = players;
            return;
        }
        for (uint256 nonce = 0; nonce < winnerCount; nonce++) {
            bytes memory info = abi.encodePacked(
                block.difficulty,
                block.timestamp,
                players.length,
                nonce
            );
            bytes32 hash = keccak256(info);
            uint256 index = uint256(hash) % players.length;
            winners.push(players[index]);
        }
    }

    function cleanLottery() internal {
        delete players;
    }

    function sendBonus() external onlyOwner {
        if (!swapping) {
            swapping = true;

            // get winners
            getWinners();
            if (winners.length == 0) {
                return;
            }
            // send bonus
            uint256 lotteryRewardsPerWinner = lotteryPoolCapacity.div(
                winners.length
            );
            for (uint256 index = 0; index < winners.length; index++) {
                address winner = winners[index];
                swapAndSendCAKE(lotteryRewardsPerWinner, winner);
            }
            // clean lottery
            cleanLottery();
            lotteryPoolCapacity = 0;

            swapping = false;
        }
    }

    function setSwapTokensAtAmount(uint256 val) external onlyOwner {
        swapTokensAtAmount = val;
    }

    function setMaxTxAmount(uint256 val) external onlyOwner {
        _maxTxAmount = val;
    }

    function setMinTxAmountForLotteryTicket(uint256 val) external onlyOwner {
        _minTxAmountForLotteryTicket = val;
    }

    function setRewardsFee(uint256 val) external onlyOwner {
        rewardsFee = val;
        totalFees = rewardsFee.add(liquidityFee).add(lotteryFee).add(
            marketingFee
        );
    }

    function setLiquidityFee(uint256 val) external onlyOwner {
        liquidityFee = val;
        totalFees = rewardsFee.add(liquidityFee).add(lotteryFee).add(
            marketingFee
        );
    }

    function setLotteryFee(uint256 val) external onlyOwner {
        lotteryFee = val;
        totalFees = rewardsFee.add(liquidityFee).add(lotteryFee).add(
            marketingFee
        );
    }

    function setMarketingFee(uint256 val) external onlyOwner {
        marketingFee = val;
        totalFees = rewardsFee.add(liquidityFee).add(lotteryFee).add(
            marketingFee
        );
    }

    function setStage(uint256 val) external onlyOwner {
        stage = val;
    }

    function setSwapAndLiquifyEnabled(bool val) external onlyOwner {
        swapAndLiquifyEnabled = val;
    }

    receive() external payable {}

    function isContractaddr(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "The dividend tracker already has that address"
        );

        ZOMBIECAKEDividendTracker newDividendTracker = ZOMBIECAKEDividendTracker(
                payable(newAddress)
            );

        require(
            newDividendTracker.owner() == address(this),
            "The new dividend tracker must be owned by the main token contract"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] memory accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        _marketingWalletAddress = wallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
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

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
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

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
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
        dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function isFeeFree(address from, address to) internal view returns (bool) {
        return
            (from != uniswapV2Pair &&
                to != uniswapV2Pair &&
                (_isExcludedFromFees[from] || _isExcludedFromFees[to])) ||
            ((from == uniswapV2Pair && _isExcludedFromFees[to]) ||
                (to == uniswapV2Pair && _isExcludedFromFees[from]));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        bool presale = stage == 0;
        if (from != owner() && to != owner() && !presale) {
            require(
                amount <= _maxTxAmount,
                "ERC20: transfer amount exceeds the _maxTxAmount."
            );
        }
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        if (
            !isContractaddr(to) &&
            amount >= _minTxAmountForLotteryTicket &&
            !presale
        ) {
            players.push(to);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (lotteryPoolCapacity > contractTokenBalance) {
            lotteryPoolCapacity = contractTokenBalance;
        }
        uint256 contractTokenBalanceExculudeLottery = contractTokenBalance.sub(
            lotteryPoolCapacity
        );
        bool canSwap = contractTokenBalanceExculudeLottery >=
            swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapAndLiquifyEnabled &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 feeExcludeLottery = totalFees.sub(lotteryFee);
            uint256 marketingTokens = contractTokenBalanceExculudeLottery
                .mul(marketingFee)
                .div(feeExcludeLottery);
            swapAndSendCAKE(marketingTokens, _marketingWalletAddress);

            uint256 liquitidyTokens = contractTokenBalanceExculudeLottery
                .mul(liquidityFee)
                .div(feeExcludeLottery);
            swapAndLiquify(liquitidyTokens);

            uint256 rewardsTokens = contractTokenBalanceExculudeLottery
                .sub(marketingTokens)
                .sub(liquitidyTokens);
            swapAndSendDividends(rewardsTokens);

            swapping = false;
        }

        if (!isFeeFree(from, to)) {
            uint256 fees = amount.mul(totalFees).div(100);
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
            if (!swapping) {
                swapping = true;

                uint256 lottery = fees.mul(lotteryFee).div(totalFees);
                lotteryPoolCapacity = lotteryPoolCapacity.add(lottery);

                swapping = false;
            }
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

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

    function swapAndSendCAKE(uint256 tokens, address addr) private {
        uint256 initialCAKEBalance = IERC20(CAKE).balanceOf(address(this));

        swapTokensForCAKE(tokens);
        uint256 newBalance = (IERC20(CAKE).balanceOf(address(this))).sub(
            initialCAKEBalance
        );
        IERC20(CAKE).transfer(addr, newBalance);
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

    function swapTokensForCAKE(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = CAKE;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
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
            address(0),
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForCAKE(tokens);
        uint256 dividends = IERC20(CAKE).balanceOf(address(this));
        bool success = IERC20(CAKE).transfer(
            address(dividendTracker),
            dividends
        );

        if (success) {
            dividendTracker.distributeCAKEDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function emergencyWithdrawToken(address token) external onlyOwner {
        require(token != address(this));
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }

    function emergencyWithdraw() external onlyOwner {
        if (!swapping) {
            swapping = true;

            uint256 balance = balanceOf(address(this));
            super._transfer(address(this), owner(), balance);
            lotteryPoolCapacity = 0;

            swapping = false;
        }
    }
}

contract ZOMBIECAKEDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor()
        public
        DividendPayingToken(
            "ZOMBIECAKE_Dividen_Tracker",
            "ZOMBIECAKE_Dividen_Tracker"
        )
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 100000 * (10**18);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        require(false, " No transfers allowed");
    }

    function withdrawDividend() public override {
        require(
            false,
            "withdrawDividend disabled. Use the 'claim' function on the main token contract."
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
            "claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "Cannot update claimWait to same value"
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