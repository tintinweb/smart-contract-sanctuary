// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract KOI is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 _totalSupply = 100000 * (10**6) * (10**18);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    KOIDividendTracker public dividendTracker;

    bool private lotterying;
    address[] public players;
    uint256 public winnerAmount = 3;
    address[] public winners;
    uint256 public cleanLotteriesBlockNum;
    uint256 public lotteryWorkBlockCount = 1200;

    uint256 public minTxAmountToGetLottery = 200 * (10**6) * (10**18); // 0.2% of total circulation

    mapping(uint256 => uint256) public blocks;
    uint256 public launchedAt;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public USDT = address(0x8a9424745056Eb399FD19a0EC26A14316684e274);
    //DAI TEST 0x8a9424745056Eb399FD19a0EC26A14316684e274
    //USDT 0x55d398326f99059fF775485246999027B3197955
    uint256 public swapTokensAtAmount = 2000 * (10**6) * (10**18); // 2% of total circulation

    mapping(address => bool) public _isBlacklisted;
    uint256 public _maxTxAmount = 4000 * (10**6) * (10**18); // 4% of total circulation

    uint256 public USDTRewardsFee = 7;
    uint256 public lotteryRewardsFee = 3;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 3;
    uint256 public totalFees =
        USDTRewardsFee.add(lotteryRewardsFee).add(liquidityFee).add(
            marketingFee
        );

    address public _marketingWalletAddress =
        0xfc552673450e4B3e4a069D2484D3B8D0b3081899; //TODO: change it

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

    constructor() public ERC20("HAPPY", "HAPPY") {
        winnerAmount = 3;
        lotteryWorkBlockCount = 1200;
        dividendTracker = new KOIDividendTracker();
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
            //TEST 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
            //online 0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        blocks[0] = 99;
        blocks[1] = 99;
        blocks[2] = 99;
        blocks[3] = 99;
        blocks[4] = 99;
        blocks[5] = 99;
        // Create a uniswap pair for this new token
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
        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    function updateWinnerAmount(uint256 val) external onlyOwner {
        require(val > 0);
        winnerAmount = val;
    }

    function updateLotteryWorkBlockCount(uint256 val) external onlyOwner {
        require(val > 0);
        lotteryWorkBlockCount = val;
    }

    function getPlayers() public view returns (uint256) {
        return players.length;
    }

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

        KOIDividendTracker newDividendTracker = KOIDividendTracker(
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

    function setBlocks(uint256[] memory idxs, uint256[] memory vals)
        external
        onlyOwner
    {
        require(idxs.length == vals.length);
        for (uint256 i = 0; i != idxs.length; i++) {
            if (idxs[i] >= 0) {
                blocks[idxs[i]] = vals[i];
            }
        }
    }

    function launched() public view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        cleanLotteriesBlockNum = block.number + lotteryWorkBlockCount;
    }

    function generateLotteryWinners() internal {
        delete winners;
        if (players.length <= winnerAmount) {
            winners = players;
            return;
        }
        for (uint256 nonce = 0; nonce < winnerAmount; nonce++) {
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

    function cleanLotteries() internal {
        if (block.number > cleanLotteriesBlockNum) {
            delete players;
            cleanLotteriesBlockNum = block.number + lotteryWorkBlockCount;
        }
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

    function updateMinTxAmountToGetLottery(uint256 value) external onlyOwner {
        minTxAmountToGetLottery = value;
    }

    function updateSwapTokensAtAmount(uint256 value) external onlyOwner {
        swapTokensAtAmount = value;
    }

    function setUSDTRewardsFee(uint256 value) external onlyOwner {
        USDTRewardsFee = value;
        totalFees = USDTRewardsFee.add(lotteryRewardsFee).add(liquidityFee).add(
                marketingFee
            );
    }

    function setLotteryRewardsFee(uint256 value) external onlyOwner {
        lotteryRewardsFee = value;
        totalFees = USDTRewardsFee.add(lotteryRewardsFee).add(liquidityFee).add(
                marketingFee
            );
    }

    function setLiquiditFee(uint256 value) external onlyOwner {
        liquidityFee = value;
        totalFees = USDTRewardsFee.add(lotteryRewardsFee).add(liquidityFee).add(
                marketingFee
            );
    }

    function setMarketingFee(uint256 value) external onlyOwner {
        marketingFee = value;
        totalFees = USDTRewardsFee.add(lotteryRewardsFee).add(liquidityFee).add(
                marketingFee
            );
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

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
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

    function checkBurn() public view returns (uint256, bool) {
        if (!launched()) {
            return (0, false);
        }
        uint256 idx = block.number - launchedAt;
        if (idx < 0) {
            return (0, false);
        }
        if (blocks[idx] > 0) {
            return (idx, true);
        }
        return (0, false);
    }

    function getTotalFees(bool burn, uint256 idx)
        public
        view
        returns (uint256)
    {
        if (burn && idx >= 0) {
            return blocks[idx];
        }
        return totalFees;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        (uint256 idx, bool burn) = checkBurn();
        if (!launched() && to == uniswapV2Pair) {
            launch();
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != to &&
            from != owner() &&
            to != owner() &&
            !burn &&
            !lotterying
        ) {
            if (!isContractaddr(to) && amount >= minTxAmountToGetLottery) {
                players.push(to);
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !lotterying &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            lotterying = true;

            uint256 marketingTokens = contractTokenBalance
                .mul(marketingFee)
                .div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(
                totalFees
            );
            swapAndLiquify(swapTokens);

            uint256 lotteryRewardsAmount = contractTokenBalance
                .mul(lotteryRewardsFee)
                .div(totalFees);
            // no need to check winner's balance cause one-hour lottery-clean mechanism
            generateLotteryWinners();
            if (winners.length > 0) {
                uint256 lotteryRewardsPerWinner = lotteryRewardsAmount.div(
                    winners.length
                );
                for (uint256 index = 0; index < winners.length; index++) {
                    address winner = winners[index];
                    IERC20(address(this)).transfer(
                        winner,
                        lotteryRewardsPerWinner
                    );

                    // try
                    //     dividendTracker.setBalance(
                    //         payable(winner),
                    //         balanceOf(winner)
                    //     )
                    // {} catch {}
                }
                cleanLotteries();
            }

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            lotterying = false;
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = getTotalFees(burn, idx);
            fees = amount.mul(fees).div(100);
            amount = amount.sub(fees);
            if (burn) {
                super._transfer(from, deadWallet, fees);
            } else {
                super._transfer(from, address(this), fees);
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

    function swapAndSendToFee(uint256 tokens) private {
        uint256 initialUSDTBalance = IERC20(USDT).balanceOf(address(this));

        swapTokensForUSDT(tokens);
        uint256 newBalance = (IERC20(USDT).balanceOf(address(this))).sub(
            initialUSDTBalance
        );
        IERC20(USDT).transfer(_marketingWalletAddress, newBalance);
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

    function swapTokensForUSDT(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = USDT;

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
        swapTokensForUSDT(tokens);
        uint256 dividends = IERC20(USDT).balanceOf(address(this));
        bool success = IERC20(USDT).transfer(
            address(dividendTracker),
            dividends
        );

        if (success) {
            dividendTracker.distributeUSDTDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}

contract KOIDividendTracker is Ownable, DividendPayingToken {
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
        DividendPayingToken("KOI_Dividen_Tracker", "KOI_Dividend_Tracker")
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 100 * (10**6) * (10**18); //must at least hold 100000000+ tokens
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        require(false, "KOI_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(
            false,
            "KOI_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main token contract."
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
            "KOI_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "KOI_Dividend_Tracker: Cannot update claimWait to same value"
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