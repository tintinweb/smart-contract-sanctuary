// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./ITracker.sol";


contract Dawn is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 public constant BASE = 10**18;
    uint256 public constant MAX_BUY_TX_AMOUNT = 500_000 * BASE; //0.5%
    uint256 public constant REWARDS_FEE = 7;
    uint256 public constant DEV_FEE = 7;
    uint256 public constant PENALTY_FEE = 15;
    uint256 public constant TOTAL_FEES = REWARDS_FEE + DEV_FEE;
    uint256 public accumulatedPenalty;
    uint256 public buyLimitTimestamp; // buy limit for the first 5 minutes after trading activation
    uint256 public sellTaxPenaltyTimestamp; // sell extra fee of 15%
    uint256 public gasForProcessing = 150_000; // processing auto-claiming dividends
    uint256 public liquidateTokensAtAmount = 10_000 * BASE; //0.01
    // minimum held in token contract to process fees
    ITracker public dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public devAddress;

    bool private liquidating;
    bool public tradingEnabled; // whether the token can already be traded
    bool public isAutoProcessing;

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // addresses that can make transfers before presale is over
    mapping(address => bool) public canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs
    mapping(address => bool) public automatedMarketMakerPairs;

    // store addresses that are blacklisted
    mapping(address => bool) public isBlacklisted;

    // store buy cooldown timestamp
    mapping(address => uint256) public buyCooldown;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event DevWalletUpdated(
        address indexed newDevWallet,
        address indexed oldDevWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event ExcludeFromFees(address indexed account, bool exclude);

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address _devAddress) ERC20("The Dawn Story", "DAWN") {
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_devAddress, true);
        excludeFromFees(address(this), true);
        // update the dev address
        devAddress = _devAddress;
        // enable owner wallet to send tokens before presales are over.
        canTransferBeforeTradingIsEnabled[owner()] = true;
        _mint(owner(), 100_000_000 * BASE); //100%

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        //  Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
    }

    receive() external payable {}

    // view functions
    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
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

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function withdrawableDividendOf(address account)
        external
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function hasDividends(address account) external view returns (bool) {
        (, int256 index, , , , , , ) = dividendTracker.getAccount(account);
        return (index > -1);
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

    // state functions
    // // owner restricted
    function activate() public onlyOwner {
        require(!tradingEnabled, "Trading is already enabled");
        tradingEnabled = true;
        buyLimitTimestamp = (block.timestamp).add(300);
        sellTaxPenaltyTimestamp = (block.timestamp).add(86400);
    }

    function addTransferBeforeTrading(address account) external onlyOwner {
        require(account != address(0), "Sets the zero address");
        canTransferBeforeTradingIsEnabled[account] = true;
    }

    function blackList(address _user) external onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
    }

    function excludeDividendsPairOnce() external onlyOwner {
        require(
            !automatedMarketMakerPairs[uniswapV2Pair],
            "uniswap pair has been set!"
        );
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }

    function removeFromBlacklist(address _user) external onlyOwner {
        require(isBlacklisted[_user], "user already whitelisted");
        isBlacklisted[_user] = false;
    }

    function excludeFromFees(address account, bool exclude) public onlyOwner {
        require(
            _isExcludedFromFees[account] != exclude,
            "Already has been assigned!"
        );
        _isExcludedFromFees[account] = exclude;
        emit ExcludeFromFees(account, exclude);
    }

    function excludeFromDividends(address account, bool exclude)
        public
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, exclude);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair, "JoeTrader pair is irremovable!");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "Tracker already has been set!"
        );
        ITracker newDividendTracker = ITracker(payable(newAddress));
        require(
            newDividendTracker.owner() == address(this),
            "Tracker must be owned by token"
        );
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(DEAD_ADDRESS, true);
        newDividendTracker.excludeFromDividends(address(devAddress), true);
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue != gasForProcessing, "Value has been assigned!");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateMinimumForDividends(uint256 amount) external onlyOwner {
        dividendTracker.updateMinimumForDividends(amount);
    }

    function updateDevWallet(address newDevWallet) external onlyOwner {
        require(newDevWallet != devAddress, "Dev wallet has been assigned!");
        excludeFromFees(newDevWallet, true);
        emit DevWalletUpdated(newDevWallet, devAddress);
        devAddress = newDevWallet;
    }

    function updateAmountToLiquidateAt(uint256 liquidateAmount)
        external
        onlyOwner
    {
        require(
            (liquidateAmount >= 10_000 * BASE) && //0.01%-0.1%
                (100_000 * BASE >= liquidateAmount),
            "should be 100M <= value <= 1B"
        );
        require(
            liquidateAmount != liquidateTokensAtAmount,
            "value already assigned!"
        );
        liquidateTokensAtAmount = liquidateAmount;
    }

    // // public access
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
        dividendTracker.processAccount(payable(msg.sender));
    }

    function switchAutoProcessing(bool enabled) external onlyOwner {
        require(enabled != isAutoProcessing, "already has been set!");
        isAutoProcessing = enabled;
    }

    // private
    function sendEth(address account, uint256 amount) private {
        (bool success, ) = account.call{value: amount}("");
    }

    function swapAndSend(uint256 tokens) private {
        swapTokensForETH(tokens);

        uint256 dividends = address(this).balance;
        uint256 devTokens = dividends.mul(DEV_FEE).div(TOTAL_FEES);
        if (accumulatedPenalty > 0) {
            devTokens += dividends.mul(accumulatedPenalty).div(tokens);
            accumulatedPenalty = 0;
        }
        sendEth(devAddress, devTokens);
        uint256 rewardTokens = address(this).balance;
        sendEth(address(dividendTracker), rewardTokens);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the JoeTrader pair path of token -> ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of eth
            path,
            address(this),
            block.timestamp
        );
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "AMM pair has been assigned!"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) dividendTracker.excludeFromDividends(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        // blacklisting check
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "from or to is blacklisted"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool tradingIsEnabled = tradingEnabled;
        bool areMeet = !liquidating && tradingIsEnabled;
        bool hasContracts = isContract(from) || isContract(to);
        // only whitelisted addresses can make transfers before the public presale is over.
        if (!tradingIsEnabled) {
            //turn transfer on to allow for whitelist form/mutlisend presale
            require(
                canTransferBeforeTradingIsEnabled[from],
                "Trading is not enabled"
            );
        }

        if (hasContracts) {
            if (areMeet) {
                if (
                    automatedMarketMakerPairs[from] && // buys only by detecting transfer from automated market maker pair
                    to != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
                    !_isExcludedFromFees[to] //no max for those excluded from fees)
                ) {
                    if (buyLimitTimestamp >= block.timestamp)
                        require(
                            amount <= MAX_BUY_TX_AMOUNT,
                            "exceeds MAX_BUY_TX_AMOUNT"
                        );
                    require(
                        buyCooldown[to] <= block.timestamp,
                        "under cooldown period"
                    );
                    buyCooldown[to] = (block.timestamp).add(30);
                }

                uint256 contractTokenBalance = balanceOf(address(this));

                bool canSwap = contractTokenBalance >= liquidateTokensAtAmount;

                if (canSwap && !automatedMarketMakerPairs[from]) {
                    liquidating = true;

                    swapAndSend(contractTokenBalance);

                    liquidating = false;
                }
            }

            bool takeFee = tradingIsEnabled && !liquidating;

            // if any account belongs to _isExcludedFromFee account then remove the fee
            if (
                _isExcludedFromFees[from] ||
                _isExcludedFromFees[to] ||
                (automatedMarketMakerPairs[from] && // third condition is for liquidity removing
                    to == address(uniswapV2Router))
            ) {
                takeFee = false;
            }

            if (takeFee) {
                uint256 fees;
                if (block.timestamp < sellTaxPenaltyTimestamp && automatedMarketMakerPairs[to]) {
                    fees = amount.mul(TOTAL_FEES.add(PENALTY_FEE)).div(100);
                    accumulatedPenalty += amount.mul(PENALTY_FEE).div(100);
                } else {
                    fees = amount.mul(TOTAL_FEES).div(100);
                }
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            }
        }
        super._transfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);

        dividendTracker.setBalance(payable(from), fromBalance);
        dividendTracker.setBalance(payable(to), toBalance);

        if (!liquidating && isAutoProcessing && hasContracts) {
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
}