// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import "./utils/LPSwapSupport.sol";
import "./utils/LockableFunction.sol";
import "./utils/MamaCocoNoBSSupport.sol";
import "./utils/AntiLPSniper.sol";

contract MamaCoco is IBEP20, LockableFunction, MamaCocoNoBSSupport, LPSwapSupport, AntiLPSniper{
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint256 internal _decimals;

    struct Fees{
        uint256 liquidity;
        uint256 marketing;
        uint256 development;
        uint256 charity;
        uint256 reflectionToken1;
        uint256 reflectionToken2;
        uint256 divisor;
    }

    struct TokenTracker{
        uint256 liquidity;
        uint256 marketing;
        uint256 development;
        uint256 charity;
        uint256 reflectionToken1;
        uint256 reflectionToken2;
    }

    Fees public buyFees;
    Fees public sellFees;
    Fees public transferFees;
    Fees public firstWeekSellFees;
    TokenTracker public taxAllocations;

    uint256 public tradingOpenedAt;
    uint256 public initialSellFeePeriod;

    address public marketingAddress = 0xf94ae1187D3572Ba64aE659C858DB200B7b65F2d;
    address public devAddress = 0xf94ae1187D3572Ba64aE659C858DB200B7b65F2d;
    address public charityAddress = 0xf94ae1187D3572Ba64aE659C858DB200B7b65F2d;

    uint256 public maxWalletSize;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) private isWhitelisted;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    constructor(string memory _NAME, string memory _SYMBOL, uint256 _DECIMALS, uint256 _supply, address routerAddress, address noBSRouterAddress,
            address tokenOwner) LPSwapSupport() NoBSAdvSupport(noBSRouterAddress) public {

        _name = _NAME;
        _symbol = _SYMBOL;
        _decimals = _DECIMALS;
        _totalSupply = _supply * 10 ** _decimals;

        updateRouter(routerAddress);

        transferFees.liquidity = 0;
        transferFees.marketing = 0;
        transferFees.development = 0;
        transferFees.charity = 0;
        transferFees.reflectionToken1 = 2;
        transferFees.reflectionToken2 = 8;
        transferFees.divisor = 100;

        buyFees.liquidity = 3;
        buyFees.marketing = 3;
        buyFees.development = 3;
        buyFees.charity = 1;
        buyFees.reflectionToken1 = 2;
        buyFees.reflectionToken2 = 3;
        buyFees.divisor = 100;

        sellFees.liquidity = 4;
        sellFees.marketing = 4;
        sellFees.development = 4;
        sellFees.charity = 1;
        sellFees.reflectionToken1 = 3;
        sellFees.reflectionToken2 = 4;
        sellFees.divisor = 100;

        firstWeekSellFees.liquidity = 3;
        firstWeekSellFees.marketing = 6;
        firstWeekSellFees.development = 3;
        firstWeekSellFees.charity = 6;
        firstWeekSellFees.reflectionToken1 = 3;
        firstWeekSellFees.reflectionToken2 = 9;
        firstWeekSellFees.divisor = 100;

        initialSellFeePeriod = 1 weeks;

        maxWalletSize = _totalSupply.div(100);
        minTokenSpendAmount = _totalSupply.div(100000);
        maxTokenSpendAmount = maxWalletSize;


        _balances[tokenOwner] = _totalSupply;
        emit Transfer(address(this), tokenOwner, _balances[tokenOwner]);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(tokenOwner, true);
        excludeFromFees(_owner, true);
        excludeFromFees(address(this), true);
    }

    function finalize() external onlyOwner init {
        updateRouterAndPair(address(pancakeRouter));
        updateReflectors(address(this), _balances[address(this)], _owner, _balances[_owner]);
    }

    receive() external payable {}

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return uint8(_decimals);
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override virtual view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function updateLPPair(address newAddress) public override onlyOwner {
        super.updateLPPair(newAddress);

        automatedMarketMakerPairs[newAddress] = true;
        excludeFromRewards(newAddress, true);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateTransferFees(uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 charityFee, uint256 reflector1Fee, uint256 reflector2Fee, uint256 feeDivisor) external onlyOwner {
        transferFees = Fees({
            liquidity: liquidityFee,
            marketing: marketingFee,
            development: devFee,
            charity: charityFee,
            reflectionToken1: reflector1Fee,
            reflectionToken2: reflector2Fee,
            divisor: feeDivisor
        });
    }

    function updateSellFees(uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 charityFee, uint256 reflector1Fee, uint256 reflector2Fee, uint256 feeDivisor) external onlyOwner {
        _updateFees(true, liquidityFee, marketingFee, devFee, charityFee, reflector1Fee, reflector2Fee, feeDivisor);
    }

    function updateBuyFees(uint256 liquidityFee, uint256 marketingFee, uint256 devFee, uint256 charityFee, uint256 reflector1Fee, uint256 reflector2Fee, uint256 feeDivisor) external onlyOwner {
        _updateFees(false, liquidityFee, marketingFee, devFee, charityFee, reflector1Fee, reflector2Fee, feeDivisor);
    }

    function _updateFees(bool updateSellFee, uint256 _liquidity, uint256 _marketing, uint256 _dev, uint256 _charity, uint256 _reflector1, uint256 _reflector2, uint256 _divisor) private {
        if(updateSellFee){
            sellFees = Fees({
                liquidity: _liquidity,
                marketing: _marketing,
                development: _dev,
                charity: _charity,
                reflectionToken1: _reflector1,
                reflectionToken2: _reflector2,
                divisor: _divisor
            });
        } else {
            buyFees = Fees({
                liquidity: _liquidity,
                marketing: _marketing,
                development: _dev,
                charity: _charity,
                reflectionToken1: _reflector1,
                reflectionToken2: _reflector2,
                divisor: _divisor
            });
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(gasleft() > gasForProcessing, "Requires more gas for transaction");
        uint256 tAmount = amount;
        if(amount == 0) {
            _simpleTransfer(from, to, 0, 0);
            return;
        }

        if(from != owner() && to != owner() && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            require(!isBlackListed[from] && !isBlackListed[to], "Address has been blacklisted");
            if(!isWhitelisted[from] && !isWhitelisted[to]) {
                if(automatedMarketMakerPairs[from] && antiSniperEnabled && !tradingIsEnabled){
                    banHammer(to);
                    to = address(this);
                } else {
                    require(tradingIsEnabled, "Cannot send tokens until trading is enabled");
                }
            }

            if(!inSwap && !automatedMarketMakerPairs[from]){
                performSwap();
            }

            tAmount = takeFees(from, amount, automatedMarketMakerPairs[to]);

            if(!automatedMarketMakerPairs[to]){
                require(balanceOf(to).add(tAmount) <= maxWalletSize, "Transfer would exceed wallet size restriction");
            }

            distributeRewards(gasForProcessing);

        }
        _simpleTransfer(from, to, amount, tAmount);
        updateReflectors(from, _balances[from], to, _balances[to]);
    }

    function _simpleTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tAmount
    ) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function takeFees(address from, uint256 amount, bool isSell) private returns(uint256){
        Fees memory txFees;
        if(isSell){
            if(block.timestamp < tradingOpenedAt.add(initialSellFeePeriod)){
                txFees = firstWeekSellFees;
            } else {
                txFees = sellFees;
            }
        } else if(automatedMarketMakerPairs[from]){
            txFees = buyFees;
        } else {
            txFees = transferFees;
        }
        uint256 divisor = txFees.divisor;
        uint256 totalFees = 0;
        uint256 thisFee = 0;

        thisFee = amount.mul(txFees.liquidity).div(divisor);
        totalFees = totalFees.add(thisFee);
        taxAllocations.liquidity = taxAllocations.liquidity.add(thisFee);

        thisFee = amount.mul(txFees.marketing).div(divisor);
        totalFees = totalFees.add(thisFee);
        taxAllocations.marketing = taxAllocations.marketing.add(thisFee);

        thisFee = amount.mul(txFees.charity).div(divisor);
        totalFees = totalFees.add(thisFee);
        taxAllocations.charity = taxAllocations.charity.add(thisFee);

        thisFee = amount.mul(txFees.development).div(divisor);
        totalFees = totalFees.add(thisFee);
        taxAllocations.development = taxAllocations.development.add(thisFee);

        thisFee = amount.mul(txFees.reflectionToken1).div(divisor);
        totalFees = totalFees.add(thisFee);
        taxAllocations.reflectionToken1 = taxAllocations.reflectionToken1.add(thisFee);

        thisFee = amount.mul(txFees.reflectionToken2).div(divisor);
        totalFees = totalFees.add(thisFee);
        taxAllocations.reflectionToken2 = taxAllocations.reflectionToken2.add(thisFee);

        _balances[address(this)] = _balances[address(this)].add(totalFees);
        emit Transfer(from, address(this), totalFees);
        return amount.sub(totalFees);
    }

    function performSwap() private lockTheSwap {
        if(!swapsEnabled)
            return;
        if(taxAllocations.liquidity >= minTokenSpendAmount){
            swapAndLiquify(taxAllocations.liquidity);
            taxAllocations.liquidity = 0;
        } else {
            // Attempt all swaps, token limits in LPSwapSupport will return early if amount is too low
            taxAllocations.marketing = taxAllocations.marketing.sub(swapTokensForCurrencyAdv(address(this), taxAllocations.marketing, marketingAddress));
            taxAllocations.development = taxAllocations.development.sub(swapTokensForCurrencyAdv(address(this), taxAllocations.development, devAddress));
            taxAllocations.charity = taxAllocations.charity.sub(swapTokensForCurrencyAdv(address(this), taxAllocations.charity, charityAddress));
        }

        if(taxAllocations.reflectionToken1 >= minTokenSpendAmount){
            taxAllocations.reflectionToken1 = taxAllocations.reflectionToken1.sub(swapTokensForCurrencyAdv(address(this), taxAllocations.reflectionToken1, address(this)));
            noBSReflectors[0].deposit{value: address(this).balance}();
        } else {
            taxAllocations.reflectionToken2 = taxAllocations.reflectionToken2.sub(swapTokensForCurrencyAdv(address(this), taxAllocations.reflectionToken2, address(this)));
            noBSReflectors[1].deposit{value: address(this).balance}();
        }
    }

    function updateMaxWalletSizeInTokens(uint256 amount) external onlyOwner {
        maxWalletSize = amount * 10 ** _decimals;
    }

    function updateMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function updateDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
    }

    function updateCharityAddress(address _charityAddress) external onlyOwner {
        charityAddress = _charityAddress;
    }

    function updateWhitelist(address user, bool shouldWhitelist) external onlyOwner {
        isWhitelisted[user] = shouldWhitelist;
    }

    function openTrading() external onlyOwner {
        require(!tradingIsEnabled, "Trading already open");
        tradingIsEnabled = true;
        tradingOpenedAt = block.timestamp;
        swapsEnabled = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol';
import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol';
import 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import "./Ownable.sol";

abstract contract LPSwapSupport is Ownable {
    using SafeMath for uint256;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 currencyReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;
    bool public swapsEnabled = true;

    uint256 public minSpendAmount;
    uint256 public maxSpendAmount;

    uint256 public minTokenSpendAmount;
    uint256 public maxTokenSpendAmount;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address public liquidityReceiver;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() public {
        liquidityReceiver = deadAddress;
        minSpendAmount = 0.001 ether;
        maxSpendAmount = 10 ether;
    }

    function _approve(address owner, address spender, uint256 tokenAmount) internal virtual;

    function updateRouter(address newAddress) public onlyOwner {
        require(newAddress != address(pancakeRouter), "The router is already set to this address");
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner{
        require(receiverAddress != liquidityReceiver, "LP is already sent to that address");
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual onlyOwner {
        if(newAddress != address(pancakeRouter)){
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual onlyOwner {
        require(newAddress != pancakePair, "The LP Pair is already set to this address");
        emit UpdatePair(newAddress, pancakePair);
        pancakePair = newAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 tokens) internal {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for
        swapTokensForCurrencyUnchecked(half);

        // how much did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForCurrency(uint256 tokenAmount) internal returns(uint256){
        return swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyUnchecked(uint256 tokenAmount) private returns(uint256){
        return _swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) internal returns(uint256){

        if(tokenAmount < minTokenSpendAmount){
            return 0;
        }
        if(maxSpendAmount != 0 && tokenAmount > maxSpendAmount){
            tokenAmount = maxSpendAmount;
        }
        return _swapTokensForCurrencyAdv(tokenAddress, tokenAmount, destination);
    }

    function _swapTokensForCurrencyAdv(address tokenAddress, uint256 tokenAmount, address destination) private returns(uint256){
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeRouter.WETH();

        if(tokenAddress != address(this)){
            IBEP20(tokenAddress).approve(address(pancakeRouter), tokenAmount);
        } else {
            _approve(address(this), address(pancakeRouter), tokenAmount);
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );

        return tokenAmount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 cAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: cAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }

    function swapCurrencyForTokens(uint256 amount) internal {
        swapCurrencyForTokensAdv(address(this), amount, address(this));
    }

    function swapCurrencyForTokensAdv(address tokenAddress, uint256 amount, address destination) internal {
        // generate the pair path of token
        if(amount < minSpendAmount) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenAddress;
        if(amount > address(this).balance){
            amount = address(this).balance;
        }
        if(amount > maxSpendAmount){
            amount = maxSpendAmount;
        }

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp.add(400)
        );
    }

    function updateSwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount <= maxAmount, "Minimum must be less than maximum");
        minSpendAmount = minAmount;
        maxSpendAmount = maxAmount;
    }

    function updateTokenSwapRange(uint256 minAmount, uint256 maxAmount) external onlyOwner {
        require(minAmount <= maxAmount || maxAmount == 0, "Minimum must be less than maximum unless max is 0 (Unlimited)");
        minTokenSpendAmount = minAmount;
        maxTokenSpendAmount = maxAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract LockableFunction {
    bool internal locked;

    modifier lockFunction {
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../NoBSHelpers/NoBSAdvSupport.sol";

abstract contract MamaCocoNoBSSupport is NoBSAdvSupport {

    function reflector1Rewards() external view returns (string memory) {
        return noBSReflectors[0].rewardCurrency();

    }

    function reflector2Rewards() external view returns (string memory) {
        return noBSReflectors[1].rewardCurrency();
    }

    function getUnpaidEarnings(address holder) external view returns (uint256 reflector1, uint256 reflector2) {
        reflector1 = noBSReflectors[0].getUnpaidEarnings(holder);
        reflector2 = noBSReflectors[1].getUnpaidEarnings(holder);
    }

    function getShares(address holder) external view returns (uint256 reflector0Amount, uint256 reflector0TotalExcluded, uint256 reflector0TotalRealised, uint256 reflector1Amount, uint256 reflector1TotalExcluded, uint256 reflector1TotalRealised) {
        (reflector0Amount, reflector0TotalExcluded, reflector0TotalRealised) = noBSReflectors[0].getShares(holder);
        (reflector1Amount, reflector1TotalExcluded, reflector1TotalRealised) = noBSReflectors[1].getShares(holder);
    }

    function forceRegister(address holder) external {
        noBSReflectors[0].enroll(holder);
        noBSReflectors[1].enroll(holder);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";

contract AntiLPSniper is Ownable{
    bool public antiSniperEnabled = true;
    mapping(address => bool) public isBlackListed;
    bool public tradingIsEnabled;

    function banHammer(address user) internal {
        isBlackListed[user] = true;
    }

    function updateBlacklist(address user, bool shouldBlacklist) external onlyOwner {
        isBlackListed[user] = shouldBlacklist;
    }

    function enableAntiSniper(bool enabled) external onlyOwner {
        antiSniperEnabled = enabled;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.5.0;

interface IPancakePair {
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

pragma solidity >=0.5.0;

interface IPancakeFactory {
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

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
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

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';

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
pragma solidity >=0.6.0;
abstract contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = _msgSender();
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is not unlockable yet");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./NoBSSupport.sol";
import "./interfaces/INoBSMultiReflectionRouter.sol";
import "./interfaces/INoBSDynamicReflector.sol";
import "./utils/NoBSInit.sol";
import "../utils/LockableFunction.sol";
import "../utils/Ownable.sol";

abstract contract NoBSAdvSupport is NoBSInit, Ownable, LockableFunction {
    INoBSMultiReflectionRouter public noBSRouter;
    INoBSDynamicReflector[] public noBSReflectors;
    uint256 public totalReflectors;
    uint256 private simpleIndex;

    constructor(address _noBSRouter) internal{
        noBSRouter = INoBSMultiReflectionRouter(payable(_noBSRouter));
    }

    function getAReflector() internal returns(INoBSDynamicReflector){
        simpleIndex = (simpleIndex + 1) % noBSReflectors.length;
        return noBSReflectors[simpleIndex];
    }

    function addReflector(address rewardsToken) public onlyOwner {
        noBSReflectors.push(INoBSDynamicReflector(noBSRouter.createAdditionalDynamicReflectorWithToken(rewardsToken)));
        totalReflectors++;
    }

    function updateReflectors(address from, uint256 fromBal, address to, uint256 toBal) internal {
        for(uint256 i = 0; i < totalReflectors; ++i){
            try noBSReflectors[i].setShare(from, fromBal) {} catch {}
            try noBSReflectors[i].setShare(to, toBal) {} catch {}
        }
    }

    function distributeRewardsForReflector(uint256 reflectorNo, uint256 gas) public {
        if(!locked){
            _distributeRewardsForReflector(reflectorNo, gas);
        }
    }

    function distributeRewards(uint256 gas) public {
        if(!locked){
            _distributeRewards(gas);
        }
    }

    function _distributeRewards(uint256 gas) private lockFunction {
        try getAReflector().process(gas) {} catch {}
    }

    function _distributeRewardsForReflector(uint256 reflectorNo, uint256 gas) private lockFunction {
        try noBSReflectors[reflectorNo].process(gas) {} catch {}
    }

    function manualClaim() external {
        if(!locked)
            _manualClaim();
    }

    function _manualClaim() private lockFunction {
        for(uint256 i = 0; i < totalReflectors; ++i){
            try noBSReflectors[i].claimDividendFor(_msgSender()) {} catch {}
        }
    }

    function excludeFromRewards(address hodler, bool shouldExclude) public onlyOwner {
        for(uint256 i = 0; i < totalReflectors; ++i){
            try noBSReflectors[i].excludeFromReward(hodler, shouldExclude) {} catch {}
        }
    }

    function setReflectorAddress(uint8 index, address reflector) external onlyOwner {
        if(index >= totalReflectors){
            noBSReflectors.push(INoBSDynamicReflector(reflector));
            totalReflectors++;
        } else {
            noBSReflectors[index] = INoBSDynamicReflector(reflector);
        }
    }

    function removeReflector(uint256 index) external onlyOwner {
        require(index < totalReflectors && totalReflectors > 0, "Index out of range");
        --totalReflectors;
        noBSReflectors[index] = noBSReflectors[totalReflectors];
        delete noBSReflectors[totalReflectors];
    }

    function setRewardToCurrency(uint256 reflectorIndex, bool andSwap) external onlyOwner {
        require(reflectorIndex < totalReflectors && totalReflectors > 0, "Index out of range");
        noBSReflectors[reflectorIndex].setRewardToCurrency(andSwap);
    }

    function setRewardToToken(uint256 reflectorIndex, address tokenAddress, bool andSwap) external onlyOwner {
        require(reflectorIndex < totalReflectors && totalReflectors > 0, "Index out of range");
        noBSReflectors[reflectorIndex].setRewardToToken(tokenAddress, andSwap);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./interfaces/INoBSRouter.sol";
import "./interfaces/INoBSDynamicReflector.sol";

abstract contract NoBSSupport {
    INoBSRouter public noBSRouter;
    INoBSDynamicReflector public noBSReflector;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./INoBSRouter.sol";

interface INoBSMultiReflectionRouter is INoBSRouter {

    // Multi-Reflector creation
    function createAdditionalDynamicReflector() external returns(address);
    function createAdditionalDynamicReflectorWithToken(address tokenToReflect) external returns(address);

    // Getters
    function reflectorAtIndex(uint256 index) external view returns(address);
    function getReflectorForContractAtIndex(address tokenAddress, uint256 index) external view returns(address);

    // Reflector Getters
    function getSharesForReflector(address reflector, address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function rewardCurrencyForReflector(address reflector) external view returns (string memory);

    // Reflection interactions
    function depositForReflector(address reflector) external payable;
    function enrollForReflector(address reflector, address shareholder) external;
    function claimDividendForHolderForReflector(address reflector, address shareholder) external;
    function processForReflector(address reflector, uint256 gas) external;

    function setShareForReflector(address reflector, address shareholder, uint256 amount) external;
    function excludeFromRewardForReflector(address reflector, address shareholder, bool shouldExclude) external;

    function setDistributionCriteriaForReflector(address reflector, uint256 _minPeriod, uint256 _minDistribution) external;
    function setRewardToCurrencyForReflector(address reflector, bool andSwap) external;
    function setRewardToTokenForReflector(address reflector, address _tokenAddress, bool andSwap) external;

    function updateGasForTransfersForReflector(address reflector, uint256 gasForTransfers) external;
    function getUnpaidEarningsForReflector(address reflector, address shareholder) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";

interface INoBSDynamicReflector is IBaseDistributor {
    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;
    function getRewardType() external view returns (string memory);
    function getUnpaidEarnings(address shareholder) external view returns (uint256);

    function updateGasForTransfers(uint256 gasForTransfers) external;
    function initialize(address _noBSRouter, address _lpRouter, address _controlToken, address _rewardsToken, address _feeReceiver, uint256 _setFee, uint256 _setFeeDivisor) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract NoBSInit {
    bool internal isInitialized;

    modifier init {
        require(!isInitialized, "Contract is already initialized");
        _;
        isInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface INoBSRouter {

    // Reflector creation
    function createDynamicReflector() external returns(address);
    function createDynamicReflectorWithToken(address tokenToReflect) external returns(address);

    // Getters
    function factory() external view returns(address);
    function getReflector() external view returns(address);
    function getReflectorFor(address tokenAddress) external view returns(address);

    // Reflector Getters
    function getShares(address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function rewardCurrency() external view returns(string memory);

    // Reflection interactions
    function deposit() external payable;
    function enroll(address shareholder) external;
    function claimDividendFor(address shareholder) external;
    function process(uint256 gas) external;

    function setShare(address shareholder, uint256 amount) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;

    function updateGasForTransfers(uint256 gasForTransfers) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBaseDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }

    struct RewardInfo{
        string name;
        address rewardAddress;
        uint256 decimals;
    }

    function getShares(address shareholder) external view returns(uint256 amount, uint256 totalExcluded, uint256 totalRealised);
    function deposit() external payable;
    function rewardCurrency() external view returns(string memory);
    function registerSelf() external;
    function enroll(address shareholder) external;
    function claimDividend() external;

    function process(uint256 gas) external;

    function setShare(address shareholder, uint256 amount) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function claimDividendFor(address shareholder) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}