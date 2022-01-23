// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// OpenZeppelin libs
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// UniSwap libs
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// Dividend tracker
import "./DividendTracker/BOLASDividendTracker.sol";

contract BOLAS is ERC20, Ownable {
    // contract version
    string constant version = 'v1.0.2';

    // Keeps track of balances for address.
    mapping(address => uint256) private _balances;

    // Keeps track of which address are excluded from fee.
    mapping(address => bool) private _isExcludedFromFee;

    // addresses that can make transfers before presale is over
    mapping(address => bool) public canTransferBeforeTradingIsEnabled;

    // store addresses that a automatic market maker pairs
    mapping(address => bool) public automatedMarketMakerPairs;

    // Liquidity pool provider router
    IUniswapV2Router02 public uniswapV2Router;

    // This Token and WETH pair contract address.
    address internal _uniswapV2Pair;

    // Where app fee tokens are sent to. Used for BOLAS app rewards
    address private _appsWallet;

    // Where marketing fee tokens are sent to.
    address private _marketingWallet;

    // Where liquidity tokens are sent to.
    address private _liquidityWallet;

    // This percent of a transaction will be burnt.
    uint16 private _taxBurn;

    // This percent of a transaction sent to marketing.
    uint16 private _taxMarketing;

    // This percent of a transaction will be dividend.
    uint16 private _taxDividend;

    // This percent of a transaction will be added to the liquidity pool. More details at https://github.com/Sheldenshi/ERC20Deflationary.
    uint16 private _taxLiquify;

    // This percent list of a transaction will be used for app slots.
    uint16[6] private _taxApps;

    uint16 private _totalTaxApps;

    // ERC20 Token Standard
    uint256 private _totalSupply;

    // Total amount of tokens burnt.
    uint256 private _totalBurnt;

    // Total amount of tokens locked in the LP (this token and WETH pair).
    uint256 private _totalTokensLockedInLiquidity;

    // Total amount of ETH locked in the LP (this token and WETH pair).
    uint256 private _totalETHLockedInLiquidity;

    // A threshold for swap and liquify.
    uint256 private _minTokensBeforeSwap;

    // Whether a previous call of SwapAndLiquify process is still in process.
    bool private _inSwapAndLiquify;

    // whether the token can already be traded
    bool public isTradingEnabled;

    bool private _autoSwapAndLiquifyEnabled;
    bool private _autoBurnEnabled;
    bool private _autoDividendEnabled;

    // Dividend states
    BOLASDividendTracker public dividendTracker;
    bool public isAutoDividendProcessing = true;
    uint256 public gasForProcessing = 150000; // processing auto-claiming dividends

    // Return values of _getValues function.
    struct TokenFeeValues {
        // Amount of tokens for to transfer.
        uint256 amount;
        // Amount tokens charged for burning.
        uint256 burnFee;
        // Amount tokens charged for marketing.
        uint256 marketingFee;
        // Amount tokens charged for dividends.
        uint256 dividendFee;
        // Amount tokens charged to add to liquidity.
        uint256 liquifyFee;
        // Amount of tokens charged for apps.
        uint256 appFee;
        // Amount of total fee
        uint256 totalFeeIntoContract;
        // Amount tokens after fees.
        uint256 transferAmount;
    }

    // Return ETH values of _getSwapValues function.
    struct SwapingETHValues {
        // Amount ETH used for liquidity.
        uint256 liquidityETHAmount;
        // Amount ETH used for dividends.
        uint256 dividendsETHAmount;
        // Amount ETH used for marketing.
        uint256 marketingETHAmount;
        // Amount ETH used for apps.
        uint256 appsETHAmount;
    }

    /*
        Events
    */
    event Burn(address from, uint256 amount);
    event TaxBurnUpdate(uint16 previousTax, uint16 currentTax);
    event TaxDividendUpdate(uint16 previousTax, uint16 currentTax);
    event TaxMarketingUpdate(uint16 previousTax, uint16 currentTax);
    event TaxLiquifyUpdate(uint16 previousTax, uint16 currentTax);
    event TaxAppUpdate(uint8 index, uint16 previousTax, uint16 currentTax);
    event AllAppTaxUpdate(uint16[6] appFees);
    event MinTokensBeforeSwapUpdated(uint256 previous, uint256 current);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensAddedToLiquidity
    );
    event ExcludeAccountFromFee(address account);
    event IncludeAccountInFee(address account);
    event EnabledAutoBurn();
    event EnabledAutoDividend();
    event EnabledAutoSwapAndLiquify();
    event DisabledAutoBurn();
    event DisabledAutoDividend();
    event DisabledAutoSwapAndLiquify();
    event Airdrop(uint256 amount);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event UpdateAppWallet(address indexed newAddress, address indexed oldAddress);
    event UpdateMarketingWallet(address indexed newAddress, address indexed oldAddress);
    event UpdateLiquidityWallet(address indexed newAddress, address indexed oldAddress);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor(
        address appWallet_,
        address marketingWallet_,
        address liquidityWallet_,
        address swapRouterAddress_) ERC20("BOLAS", "BOLAS") Ownable(){
        // uniswap initialization
        uniswapV2Router = IUniswapV2Router02(swapRouterAddress_);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        automatedMarketMakerPairs[_uniswapV2Pair] = true;
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        // enable features
        switchAutoBurn(600, true);
        switchAutoDividend(300, true);
        switchAutoSwapAndLiquify(100, 100_000_000_000 * 10 ** decimals(), true);
        setTaxMarketing(100);
        setAllTaxApps([uint16(0), 0, 0, 0, 0, 0]);

        // exclude this contract from fee.
        excludeAccountFromFee(address(this));
        excludeAccountFromFee(address(uniswapV2Router));

        // configure wallets
        updateAppsWallet(appWallet_);
        updateMarketingWallet(marketingWallet_);
        updateLiquidityWallet(liquidityWallet_);

        // Add initial supply to sender
        _mint(msg.sender, 192_000_000_000_000 * 10 ** decimals());
    }

    // allow the contract to receive ETH
    receive() external payable {}

    function updateDividendTracker(address dividendTrackerAddress_) external onlyOwner {
        // dividend setup
        dividendTracker = BOLASDividendTracker(payable(dividendTrackerAddress_));

        // exclude internals
        _tryExcludeFromDividends(address(dividendTracker));
        _tryExcludeFromDividends(address(this));
        _tryExcludeFromDividends(owner());
        _tryExcludeFromDividends(address(uniswapV2Router));

        // exclude wallets
        _tryExcludeFromDividends(_appsWallet);
        _tryExcludeFromDividends(_marketingWallet);
        _tryExcludeFromDividends(_liquidityWallet);
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Returns the address of this token and WETH pair.
     */
    function uniswapV2Pair() public view returns (address) {
        return _uniswapV2Pair;
    }

    /**
     * @dev Returns the current burn tax.
     */
    function taxBurn() public view returns (uint16) {
        return _taxBurn;
    }

    /**
     * @dev Returns the current marketing tax.
     */
    function taxMarketing() public view returns (uint16) {
        return _taxMarketing;
    }

    /**
     * @dev Returns the app tax of index.
     */
    function taxAppOf(uint8 index) public view returns (uint16) {
        return _taxApps[index];
    }

    /**
     * @dev Returns all app tax values
     */
    function taxApps() public view returns (uint16[6] memory) {
        return _taxApps;
    }

    /**
     * @dev Returns total app tax values
     */
    function totalTaxApps() public view returns (uint16) {
        return _totalTaxApps;
    }

    /**
     * @dev Returns the current liquify tax.
     */
    function taxLiquify() public view returns (uint16) {
        return _taxLiquify;
    }

    /**
     * @dev Returns the current dividend tax.
     */
    function taxDividend() public view returns (uint16) {
        return _taxDividend;
    }

    /**
    * @dev Returns true if auto burn feature is enabled.
     */
    function autoBurnEnabled() public view returns (bool) {
        return _autoBurnEnabled;
    }

    /**
     * @dev Returns true if auto swap and liquify feature is enabled.
     */
    function autoSwapAndLiquifyEnabled() public view returns (bool) {
        return _autoSwapAndLiquifyEnabled;
    }

    /**
     * @dev Returns the threshold before swap and liquify.
     */
    function minTokensBeforeSwap() external view returns (uint256) {
        return _minTokensBeforeSwap;
    }

    /**
     * @dev Returns the total number of tokens burnt.
     */
    function totalBurnt() external view returns (uint256) {
        return _totalBurnt;
    }

    /**
     * @dev Returns the total number of tokens locked in the LP.
     */
    function totalTokensLockedInLiquidity() external view returns (uint256) {
        return _totalTokensLockedInLiquidity;
    }

    /**
     * @dev Returns the total number of ETH locked in the LP.
     */
    function totalETHLockedInLiquidity() external view returns (uint256) {
        return _totalETHLockedInLiquidity;
    }

    /**
     * @dev Returns whether an account is excluded from fee.
     */
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    // Dividend methods
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

    function isExcludedFromDividends(address account) public view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function withdrawableDividendOf(address account) external view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function hasDividends(address account) external view returns (bool) {
        (, int256 index,,,,,,) = dividendTracker.getAccount(account);
        return (index > - 1);
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

    function excludeFromDividends(address account, bool exclude) public onlyOwner {
        dividendTracker.excludeFromDividends(account, exclude);
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

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender));
    }

    function switchAutoDividendProcessing(bool enabled) external onlyOwner {
        require(enabled != isAutoDividendProcessing, "already has been set!");
        isAutoDividendProcessing = enabled;
    }

    function _tryExcludeFromDividends(address addressToExclude) internal {
        if (address(dividendTracker) == address(0) || dividendTracker.isExcludedFromDividends(addressToExclude)) return;
        dividendTracker.excludeFromDividends(addressToExclude, true);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal override {
        super._transferOwnership(newOwner);
        _tryExcludeFromDividends(newOwner);
        canTransferBeforeTradingIsEnabled[newOwner] = true;
        excludeAccountFromFee(newOwner);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Burn} event indicating the amount burnt.
     * Emits a {Transfer} event with `to` set to the burn address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from 0 address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        // Transfer from account to the burnAccount
    unchecked {
        _balances[account] = accountBalance - amount;
    }

        _totalSupply -= amount;
        _totalBurnt += amount;

        emit Burn(account, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (!isTradingEnabled) {
            //turn transfer on to allow for whitelist
            require(canTransferBeforeTradingIsEnabled[sender]
                || canTransferBeforeTradingIsEnabled[recipient], "Trading is not enabled yet");
        }

        _beforeTokenTransfer(sender, recipient, amount);
        if (amount == 0) {
            _transferTokens(sender, recipient, 0);
            emit Transfer(sender, recipient, amount);
            return;
        }

        bool hasContracts = _isContract(sender) || _isContract(recipient);

        // process fees
        bool takeFee = (!_isExcludedFromFee[sender])
        && (!_isExcludedFromFee[recipient])
        && (hasContracts)
        && (!_inSwapAndLiquify)
        // liquidity removal
        && !(automatedMarketMakerPairs[sender] && recipient == address(uniswapV2Router));

        TokenFeeValues memory values = _getFeeValues(amount, takeFee);
        if (takeFee) {
            _transferTokens(sender, address(this), values.totalFeeIntoContract);
            _burn(sender, values.burnFee);
        }

        //Swapping is only possible if sender is not pancake pair,
        if (
            (hasContracts)
            && (!automatedMarketMakerPairs[sender])
            && (_autoSwapAndLiquifyEnabled)
            && (!_inSwapAndLiquify)
        ) _swapContractToken();

        // send tokens to recipient
        _transferTokens(sender, recipient, values.transferAmount);

        // process dividends
        _processTransferDividends(sender, recipient);

        _afterTokenTransfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Simply performs a token transfer from sender to recipient
     */
    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;
    }

    function _swapContractToken() private {
        // preparation
        uint contractBalance = _balances[address(this)];
        bool overMinTokensBeforeSwap = contractBalance >= _minTokensBeforeSwap;
        if (!overMinTokensBeforeSwap) return;
        // start swapping
        _inSwapAndLiquify = true;

        uint256 totalTokensForLiquidity = _minTokensBeforeSwap * _taxLiquify / _totalSwappableTax();
        uint256 liquidityTokenHalfAsETH = totalTokensForLiquidity / 2;
        uint256 liquidityTokenHalfAsBOLAS = totalTokensForLiquidity - liquidityTokenHalfAsETH;
        uint256 totalTokensToSwap = _minTokensBeforeSwap - liquidityTokenHalfAsBOLAS;
        // Contract's current ETH balance.
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(totalTokensToSwap);
        uint256 swappedETHAmount = address(this).balance - initialETHBalance;
        SwapingETHValues memory values = getSwappingETHValues(swappedETHAmount);

        // process adding liquidity
        addLiquidity(values.liquidityETHAmount, liquidityTokenHalfAsBOLAS);

        // process sending dividends
        sendEth(address(dividendTracker), values.dividendsETHAmount);

        // process sending marketing fee
        sendEth(_marketingWallet, values.marketingETHAmount);

        // process sending apps fee
        sendEth(_appsWallet, values.appsETHAmount);

        // start swapping
        _inSwapAndLiquify = false;
    }

    function _processTransferDividends(address sender, address recipient) internal {
        uint256 fromBalance = balanceOf(sender);
        uint256 toBalance = balanceOf(recipient);

        dividendTracker.setBalance(payable(sender), fromBalance);
        dividendTracker.setBalance(payable(recipient), toBalance);

        if (!_inSwapAndLiquify && isAutoDividendProcessing) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } catch {}
        }
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
      * @dev Returns swappable total fee (all fees that should be swapped)
      * outputs 1% as 100, 1.5% as 150
     */
    function _totalSwappableTax() private view returns (uint16) {
        return _taxLiquify + _taxDividend + _taxMarketing + _totalTaxApps;
    }

    /**
     * @dev Excludes an account from fee.
      *
      * Emits a {ExcludeAccountFromFee} event.
      *
      * Requirements:
      *
      * - `account` is included in fee.
      */
    function excludeAccountFromFee(address account) internal {
        require(!_isExcludedFromFee[account], "Already excluded.");

        _isExcludedFromFee[account] = true;

        emit ExcludeAccountFromFee(account);
    }

    /**
     * @dev Excludes multiple accounts from fee.
      *
      * Emits a {ExcludeMultipleAccountsFromFees} event.
      */
    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    /**
      * @dev Includes an account from fee.
      *
      * Emits a {IncludeAccountFromFee} event.
      *
      * Requirements:
      *
      * - `account` is excluded in fee.
      */
    function includeAccountInFee(address account) internal {
        require(_isExcludedFromFee[account], "Account is already included.");

        _isExcludedFromFee[account] = false;

        emit IncludeAccountInFee(account);
    }

    // Sends ETH into a specified account from this contract
    function sendEth(address account, uint256 amount) private returns (bool) {
        (bool success,) = account.call{value : amount}("");
        return success;
    }

    /**
     * @dev Swap `amount` tokens for ETH.
     *
     * Emits {Transfer} event. From this contract to the token and WETH Pair.
     */
    function swapTokensForEth(uint256 amount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Swap tokens to ETH
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this), // this contract will receive the eth that were swapped from the token
            block.timestamp + 60 * 1000
        );
    }

    /**
     * @dev Add `ethAmount` of ETH and `tokenAmount` of tokens to the LP.
     * Depends on the current rate for the pair between this token and WETH,
     * `ethAmount` and `tokenAmount` might not match perfectly.
     * Dust(leftover) ETH or token will be refunded to this contract
     * (usually very small quantity).
     *
     * Emits {Transfer} event. From this contract to the token and WETH Pai.
     */
    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) private {
        // Add the ETH and token to LP.
        // The LP tokens will be sent to burnAccount.
        // No one will have access to them, so the liquidity will be locked forever.
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityWallet, // the LP is sent to burnAccount.
            block.timestamp + 60 * 1000
        );
    }

    /**
     * @dev Returns fees and transfer amount in tokens.
     * tXXXX stands for tokenXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getFeeValues(uint256 amount, bool deductTransferFee) private view returns (TokenFeeValues memory) {
        TokenFeeValues memory values;
        values.amount = amount;

        if (!deductTransferFee) {
            values.transferAmount = values.amount;
        } else {
            // fee to inside the contract
            values.dividendFee = _calculateTax(values.amount, _taxDividend);
            values.liquifyFee = _calculateTax(values.amount, _taxLiquify);
            values.marketingFee = _calculateTax(values.amount, _taxMarketing);
            values.appFee = _calculateTax(values.amount, _totalTaxApps);
            values.totalFeeIntoContract = values.dividendFee + values.liquifyFee + values.marketingFee + values.appFee;

            // fee to outside the contract
            values.burnFee = _calculateTax(values.amount, _taxBurn);
            // amount after fee
            values.transferAmount = values.amount - (values.totalFeeIntoContract + values.burnFee);
        }

        return values;
    }

    /**
     * @dev Returns fee based on `amount` and `taxRate`
     */
    function _calculateTax(uint256 amount, uint16 tax) private pure returns (uint256) {
        return amount * tax / (10 ** 2) / (10 ** 2);
    }

    /**
     * @dev Returns swappable fee amounts in ETH.
     */
    function getSwappingETHValues(uint256 ethAmount) public view returns (SwapingETHValues memory) {
        SwapingETHValues memory values;
        uint16 totalTax = (_taxLiquify / 2) + _taxDividend + _taxMarketing + _totalTaxApps;

        values.dividendsETHAmount = _calculateSwappableTax(ethAmount, _taxDividend, totalTax);
        values.marketingETHAmount = _calculateSwappableTax(ethAmount, _taxMarketing, totalTax);
        values.appsETHAmount = _calculateSwappableTax(ethAmount, _totalTaxApps, totalTax);
        // remaining ETH is as the liquidity half
        values.liquidityETHAmount = ethAmount - (values.dividendsETHAmount + values.marketingETHAmount + values.appsETHAmount);

        return values;
    }

    /**
     * @dev Returns ETH swap amount based on tax & total tax
     */
    function _calculateSwappableTax(uint256 amount, uint16 tax, uint16 totalTax) private pure returns (uint256) {
        return (amount * tax) / totalTax;
    }

    /*
        Owner functions
    */

    function activate() public onlyOwner {
        require(!isTradingEnabled, "Trading is already enabled");
        isTradingEnabled = true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "AMM pair has been assigned!");
        automatedMarketMakerPairs[pair] = value;
        if (value) dividendTracker.excludeFromDividends(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function switchAutoBurn(uint16 taxBurn_, bool enable) public onlyOwner {
        if (!enable) {
            require(_autoBurnEnabled, "Already disabled.");
            setTaxBurn(0);
            _autoBurnEnabled = false;

            emit DisabledAutoBurn();
            return;
        }
        require(!_autoBurnEnabled, "Already enabled.");
        require(taxBurn_ > 0, "Tax must be greater than 0.");

        _autoBurnEnabled = true;
        setTaxBurn(taxBurn_);

        emit EnabledAutoBurn();
    }

    function switchAutoDividend(uint16 taxDividend_, bool enable) public onlyOwner {
        if (!enable) {
            require(_autoDividendEnabled, "Already disabled.");
            setTaxDividend(0);
            _autoDividendEnabled = false;

            emit DisabledAutoDividend();
            return;
        }
        require(!_autoDividendEnabled, "Already enabled.");
        require(taxDividend_ > 0, "Tax must be greater than 0.");

        _autoDividendEnabled = true;
        setTaxDividend(taxDividend_);

        emit EnabledAutoDividend();
    }

    function switchAutoSwapAndLiquify(uint16 taxLiquify_, uint256 minTokensBeforeSwap_, bool enable) public onlyOwner {
        if (!enable) {
            require(_autoSwapAndLiquifyEnabled, "Already disabled.");
            setTaxLiquify(0);
            _autoSwapAndLiquifyEnabled = false;
            emit DisabledAutoSwapAndLiquify();
            return;
        }

        require(!_autoSwapAndLiquifyEnabled, "Already enabled.");
        require(taxLiquify_ > 0, "Tax must be greater than 0.");

        _minTokensBeforeSwap = minTokensBeforeSwap_;
        _autoSwapAndLiquifyEnabled = true;
        setTaxLiquify(taxLiquify_);

        emit EnabledAutoSwapAndLiquify();
    }

    /**
     * @dev Updates `_minTokensBeforeSwap`
      *
      * Emits a {MinTokensBeforeSwap} event.
      *
      * Requirements:
      *
      * - `minTokensBeforeSwap_` must be less than _currentSupply.
      */
    function setMinTokensBeforeSwap(uint256 minTokensBeforeSwap_) public onlyOwner {
        require(minTokensBeforeSwap_ < _totalSupply, "Must be lower than current supply.");

        uint256 previous = _minTokensBeforeSwap;
        _minTokensBeforeSwap = minTokensBeforeSwap_;

        emit MinTokensBeforeSwapUpdated(previous, _minTokensBeforeSwap);
    }

    /**
      * @dev Updates taxBurn
      *
      * Emits a {TaxBurnUpdate} event.
      *
      * Requirements:
      *
      * - auto burn feature must be enabled.
      * - total tax rate must be less than 100%.
      */
    function setTaxBurn(uint16 taxBurn_) public onlyOwner {
        require(_autoBurnEnabled, "Auto burn not enabled");
        require(taxBurn_ + _taxDividend + _taxLiquify + _totalTaxApps + _taxMarketing < 10000, "Tax fee too high.");

        uint16 previousTax = _taxBurn;
        _taxBurn = taxBurn_;

        emit TaxBurnUpdate(previousTax, taxBurn_);
    }

    /**
      * @dev Updates taxDividend
      *
      * Emits a {TaxDividendUpdate} event.
      *
      * Requirements:
      *
      * - auto dividend feature must be enabled.
      * - total tax rate must be less than 100%.
      */
    function setTaxDividend(uint16 taxDividend_) public onlyOwner {
        require(_autoDividendEnabled, "Auto dividend not enabled");
        require(_taxBurn + taxDividend_ + _taxLiquify + _totalTaxApps + _taxMarketing < 10000, "Tax fee too high.");

        uint16 previousTax = _taxDividend;
        _taxDividend = taxDividend_;

        emit TaxDividendUpdate(previousTax, taxDividend_);
    }

    /**
      * @dev Updates taxMarketing
      *
      * Emits a {TaxMarketingUpdate} event.
      *
      * Requirements:
      *
      * - total tax rate must be less than 100%.
      */
    function setTaxMarketing(uint16 taxMarketing_) public onlyOwner {
        require(_taxBurn + _taxDividend + _taxLiquify + _totalTaxApps + taxMarketing_ < 10000, "Tax fee too high.");

        uint16 previousTax = _taxMarketing;
        _taxMarketing = taxMarketing_;

        emit TaxMarketingUpdate(previousTax, taxMarketing_);
    }

    /**
      * @dev Updates taxLiquify
      *
      * Emits a {TaxLiquifyUpdate} event.
      *
      * Requirements:
      *
      * - auto swap and liquify feature must be enabled.
      * - total tax rate must be less than 100%.
      */
    function setTaxLiquify(uint16 taxLiquify_) public onlyOwner {
        require(_autoSwapAndLiquifyEnabled, "Auto swap and liquify not enabled");
        require(_taxBurn + _taxDividend + taxLiquify_ + _totalTaxApps + _taxMarketing < 10000, "Tax fee too high.");

        uint16 previousTax = _taxLiquify;
        _taxLiquify = taxLiquify_;

        emit TaxLiquifyUpdate(previousTax, taxLiquify_);
    }

    /**
      * @dev Updates taxApp
      *
      * Emits a {TaxAppUpdate} event.
      *
      * Requirements:
      *
      * - auto swap and app feature must be enabled.
      * - total tax rate must be less than 100%.
      */
    function setTaxApps(uint8 index, uint16 taxApp_) public onlyOwner {
        uint16 previousTax = _taxApps[index];
        _taxApps[index] = taxApp_;

        _totalTaxApps = 0;
        for (uint8 i = 0; i < 6; i++) {
            _totalTaxApps += _taxApps[i];
        }

        require(_taxBurn + _taxDividend + _taxLiquify + _totalTaxApps + _taxMarketing < 10000, "Tax fee too high.");
        emit TaxAppUpdate(index, previousTax, taxApp_);
    }

    /**
     * @dev Sets all app fees at once.
      *
      * Emits a {AllAppTaxUpdate} event.
      */
    function setAllTaxApps(
        uint16[6] memory fees
    ) public onlyOwner {
        for (uint256 i = 0; i < 6; i++) _taxApps[i] = fees[i];
        _totalTaxApps = 0;
        for (uint8 i = 0; i < 6; i++) _totalTaxApps += _taxApps[i];
        require(_taxBurn + _taxDividend + _taxLiquify + _totalTaxApps + _taxMarketing < 10000, "Tax fee too high.");
        emit AllAppTaxUpdate(_taxApps);
    }

    function updateAppsWallet(address newAddress) public onlyOwner {
        require(newAddress != address(_appsWallet), "Already set!");
        if (!_isExcludedFromFee[newAddress]) excludeAccountFromFee(newAddress);
        _tryExcludeFromDividends(newAddress);
        emit UpdateAppWallet(newAddress, address(_appsWallet));
        _appsWallet = newAddress;
    }

    function updateMarketingWallet(address newAddress) public onlyOwner {
        require(newAddress != address(_marketingWallet), "Already set!");
        if (!_isExcludedFromFee[newAddress]) excludeAccountFromFee(newAddress);
        _tryExcludeFromDividends(newAddress);
        emit UpdateMarketingWallet(newAddress, address(_marketingWallet));
        _marketingWallet = newAddress;
    }

    function updateLiquidityWallet(address newAddress) public onlyOwner {
        require(newAddress != address(_liquidityWallet), "Already set!");
        if (!_isExcludedFromFee[newAddress]) excludeAccountFromFee(newAddress);
        _tryExcludeFromDividends(newAddress);
        emit UpdateLiquidityWallet(newAddress, address(_liquidityWallet));
        _liquidityWallet = newAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DividendPayingToken.sol";
import "../Common/IterableMapping.sol";

contract BOLASDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public constant BASE = 10 ** 18;
    uint256 public lastProcessedIndex;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    mapping(address => bool) public isExcludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    event ExcludeFromDividends(address indexed account, bool exclude);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount);

    constructor() DividendPayingToken("BOLAS Dividends", "BOLAS_DIVIDEND"){
        claimWait = 3600;
        minimumTokenBalanceForDividends = 1_000_000 * BASE;
        //must buy at least 1M tokens to be eligibile for dividends
    }
    // view functions
    function withdrawDividend() pure public override {
        require(false, "disabled, use 'claim' function");
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address account) external view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        return _getAccount(account);
    }

    function _getAccount(address _account)
    private view returns (
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

        iterationsUntilProcessed = - 1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
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
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, - 1, - 1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return _getAccount(account);
    }
    // state functions

    // // owner restricted
    function excludeFromDividends(address account, bool exclude) external onlyOwner {
        require(isExcludedFromDividends[account] != exclude, "already has been set!");
        isExcludedFromDividends[account] = exclude;
        uint256 bal = IERC20(owner()).balanceOf(account);
        if (exclude) {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        } else {
            _setBalance(account, bal);
            tokenHoldersMap.set(account, bal);
        }

        emit ExcludeFromDividends(account, exclude);
    }

    function updateMinimumForDividends(uint256 amount) external onlyOwner {
        require((amount >= 100_000 * BASE) && // 100K minimum
            (10_000_000_000 * BASE >= amount) // 10B maximum
        , "should be 1M <= amount <= 10B");
        require(amount != minimumTokenBalanceForDividends, "value already assigned!");
        minimumTokenBalanceForDividends = amount;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1800 && newClaimWait <= 86400, "must be updated 1 to 24 hours");
        require(newClaimWait != claimWait, "same claimWait value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (isExcludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        _processAccount(account);
    }

    function processAccount(address payable account) external onlyOwner {
        uint256 amount = _withdrawDividendOfUser(account);
        emit Claim(account, amount);
    }

    function _processAccount(address payable account) private returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            return true;
        }

        return false;
    }

    // // public functions
    function process(uint256 gas) external returns (uint256, uint256, uint256) {
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
                if (_processAccount(payable(account))) {
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

    // private
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

// OpenZeppelin libs
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Common/SafeMath.sol";
import "../Common/SafeMathUint.sol";
import "../Common/SafeMathInt.sol";
import "./IDividendPayingToken.sol";
import "./IDividendPayingTokenOptional.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional, Ownable {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2 ** 128;
    uint256 internal magnifiedDividendPerShare;
    uint256 internal lastAmount;
    uint256 public totalDividendsDistributed;
    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;



    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeDividends();
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends() public override payable {
        require(totalSupply() > 0, "dividened totalsupply error");
        if (msg.value > 0) {
            uint256 _magnifiedShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply());
            magnifiedDividendPerShare = _magnifiedShare;
            emit DividendsDistributed(msg.sender, msg.value);
            uint256 _totalDistributed = totalDividendsDistributed.add(msg.value);
            totalDividendsDistributed = _totalDistributed;
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            uint256 _withdrawnAmount = withdrawnDividends[user].add(_withdrawableDividend);
            (bool success,) = user.call{value : _withdrawableDividend, gas : 3000}("");
            if (!success) {
                return 0;
            }
            withdrawnDividends[user] = _withdrawnAmount;
            return _withdrawableDividend;
        }
        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns (uint256) {
        uint256 _dividend = withdrawableDividendOf(_owner);
        return _dividend;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        uint256 _withdrawable = accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
        return _withdrawable;
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        uint256 _withdrawn = withdrawnDividends[_owner];
        return _withdrawn;
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        uint256 _accumulative = magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
        return _accumulative;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    function _transfer(address, address, uint256) internal virtual override {
        require(false, "transfer inallowed");
    }


    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        int256 _correction = magnifiedDividendCorrections[account]
        .sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
        magnifiedDividendCorrections[account] = _correction;
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        int256 _correction = magnifiedDividendCorrections[account]
        .add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
        magnifiedDividendCorrections[account] = _correction;
    }

    /// @dev Internal function that adjusts an address dividends shares according to the new token balance.
    /// @param account The account whose tokens will be proccessed .
    /// @param newBalance The new address balance.
    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }


    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "Negative number is not allowed");
        return b;
    }
}

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.2;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256), "multplitiy error");
        require((b == 0) || (c / b == a), "multiplity error mul");
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != - 1 || a != MIN_INT256, "SafeMath error div");

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SafeMath error sub");
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMath error add");
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "SafeMath error abs");
        return a < 0 ? - a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "SafeMath toUint error");
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface IDividendPayingToken {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns (uint256);

    /// @notice Distributes ether to token holders as dividends.
    /// @dev SHOULD distribute the paid ether to token holders as dividends.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
    function distributeDividends() external payable;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface IDividendPayingTokenOptional {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) external view returns (uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) external view returns (uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}