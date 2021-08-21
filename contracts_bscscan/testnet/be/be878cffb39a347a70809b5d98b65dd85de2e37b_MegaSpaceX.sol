/*
    MegaSpaceX
    https://www.megaspacex.eu
    Sell tax 20%
    BNBRewards 10%
    liquidity 5%
    Buyback 2.5%
    Marketing 2.5%
SPDX-License-Identifier: MIT   
*/

pragma solidity ^0.6.12;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract MegaSpaceX is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address payable public marketingAddress =
        payable(0x470dC8622D832abda3b9234db7B2E67e48F422f3); // Marketing Address
    address public immutable deadAddress =
        0x000000000000000000000000000000000000dEaD;
    bool public swapping = false;
    MSPXDividendTracker public dividendTracker;
    address public liquidityWallet;
    uint256 public maxSellTransactionAmount = 1000000 * (10**9);
    uint256 public swapTokensAtAmount = 200000 * (10**9);
    uint256 public BNBRewardsFee;
    uint256 public liquidityFee;
    uint256 public totalFees;
    uint256 public marketingDivisor;
    uint256 private Originfees;
    uint256 private fees;
    uint256 public Buybackindex;
    uint8 private _decimals;
    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 400000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over

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
    bool public buyBackEnabled = true;
    bool public takeFee = true;
    uint256 private buyBackUpperLimit = 1 * 10**18;
    uint256 public lastBuybackTimestamp;
    uint256 public minTimeToBuyback = 3; // 3 seconds
    event BuyBackEnabledUpdated(bool enabled);

    function buyBackUpperLimitAmount() public view returns (uint256) {
        return buyBackUpperLimit;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setmaxSellTransactionAmount(uint256 maxSell) external onlyOwner {
        maxSellTransactionAmount = maxSell * 10**9;
    }

    function setswapTokensAtAmount(uint256 _swapTokensAtAmount)
        external
        onlyOwner
    {
        swapTokensAtAmount = _swapTokensAtAmount * 10**9;
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    function setdecimals(uint8 _decimalsvalue) public onlyOwner {
        _decimals = _decimalsvalue;
    }
    event SwapETHForTokens(uint256 amountIn, address[] path);

    constructor() public ERC20("MegaSpaceX", "MSPX") {
        uint256 _BNBRewardsFee = 10;
        uint256 _liquidityFee = 10;
        uint256 _marketingDivisor = 5;
        uint256 _Buybackindex = 100;
        BNBRewardsFee = _BNBRewardsFee;
        liquidityFee = _liquidityFee;
        Buybackindex = _Buybackindex;
        totalFees = BNBRewardsFee.add(liquidityFee);
        marketingDivisor = _marketingDivisor;
        dividendTracker = new MSPXDividendTracker();

        liquidityWallet = owner();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
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
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1000000000 * (10**9));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "MSPX: The dividend tracker already has that address"
        );

        MSPXDividendTracker newDividendTracker = MSPXDividendTracker(
            payable(newAddress)
        );

        require(
            newDividendTracker.owner() == address(this),
            "MSPX: The new dividend tracker must be owned by the MSPX token contract"
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
            "MSPX: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "MSPX: Account is already the value of 'excluded'"
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

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "MSPX: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "MSPX: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setfees(
        uint256 _marketingDivisor,
        uint256 _liquidityFee,
        uint256 _BNBRewardsFee
    ) external onlyOwner {
        marketingDivisor = _marketingDivisor;
        liquidityFee = _liquidityFee;
        BNBRewardsFee = _BNBRewardsFee;
        totalFees = BNBRewardsFee.add(liquidityFee);
    }

    function setBuybackindex(uint256 _Buybackindex) external onlyOwner {
        Buybackindex = _Buybackindex;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
    }

    function updateLiquidityWallet(address newLiquidityWallet)
        public
        onlyOwner
    {
        require(
            newLiquidityWallet != liquidityWallet,
            "Token: liquidity wallet is already this address"
        );
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "MSPX: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "MSPX: Cannot update gasForProcessing to same value"
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

    function excludeFromReward(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            !swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromFees[to] //no max for those excluded from fees
        ) {
            require(
                amount <= maxSellTransactionAmount,
                "Sell transfer amount exceeds the maxSellTransactionAmount."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            swapping = true;
            uint256 swapTokens = contractTokenBalance
                .mul(liquidityFee - marketingDivisor)
                .div(totalFees);
            swapAndLiquify(swapTokens);
            uint256 markettokens = contractTokenBalance
                .mul(marketingDivisor)
                .div(totalFees);
            transfertomarketwallet(markettokens);
            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);
            swapping = false;
        }
        takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            Originfees = amount.mul(totalFees).div(100);
            fees = 0;
            if (automatedMarketMakerPairs[to]) {
                fees = Originfees;
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        if (!swapping && automatedMarketMakerPairs[to]) {
            uint256 balance = address(this).balance;
            if (buyBackEnabled && balance > uint256(1 * 10**18)) {
                uint256 tokenSwapRate = _getTokenSwapRate();
                uint256 minTransferAmountToBuyBack = tokenSwapRate
                    .mul(buyBackUpperLimit)
                    .div(Buybackindex)
                    .div(10**18);
                if (balance > buyBackUpperLimit) {
                    if (amount >= minTransferAmountToBuyBack) {
                        balance = buyBackUpperLimit;
                        buyBackTokens(balance.div(Buybackindex));
                    } else if (
                        block.timestamp >
                        lastBuybackTimestamp + minTimeToBuyback
                    ) {
                        uint256 lowBuyBack = amount.mul(10**18).div(
                            tokenSwapRate
                        );
                        buyBackTokens(lowBuyBack);
                        lastBuybackTimestamp = block.timestamp;
                    }
                }
            }
        }

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

    function transfertomarketwallet(uint256 markettokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(markettokens);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        //Send to Marketing address
        transferToAddressETH(
            marketingAddress,
            transferredBalance.mul(marketingDivisor).div(liquidityFee)
        );
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 initialdividends = address(this).balance;
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance.sub(initialdividends);
        (bool success, ) = address(dividendTracker).call{value: dividends}("");

        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }

    function _getTokenSwapRate() private view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();
        return Res0.div(Res1).mul(10**18); // return amount of token0 needed to buy token1
    }

    function buyBackTokens(uint256 amount) private {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0,
            path,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp.add(300)
        );
        emit SwapETHForTokens(amount, path);
    }

    function afterPreSale() external onlyOwner {
        BNBRewardsFee = 10;
        liquidityFee = 10;
        marketingDivisor = 5;
        totalFees = BNBRewardsFee.add(liquidityFee);
        maxSellTransactionAmount = 1 * 10**6 * 10**9;
    }

    function prepareForPreSale() external onlyOwner {
        BNBRewardsFee = 0;
        liquidityFee = 0;
        marketingDivisor = 0;
        totalFees = BNBRewardsFee.add(liquidityFee);
        maxSellTransactionAmount = 1 * 10**9 * 10**9;
    }
}

contract MSPXDividendTracker is DividendPayingToken, Ownable {
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
        public
        DividendPayingToken("MSPX_Dividend_Tracker", "MSPX_Dividend_Tracker")
    {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 10000 * (10**9); //must hold 10000+ tokens
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        require(false, "MSPX_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public override {
        require(
            false,
            "MSPX_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main MSPX contract."
        );
    }

    function excludeFromDividends(address account) public onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400,
            "MSPX_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours"
        );
        require(
            newClaimWait != claimWait,
            "MSPX_Dividend_Tracker: Cannot update claimWait to same value"
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