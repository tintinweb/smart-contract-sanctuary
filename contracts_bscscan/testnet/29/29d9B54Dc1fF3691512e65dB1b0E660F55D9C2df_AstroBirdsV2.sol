/**
 *  
 * AstroBirdz
    TOTAL 11% tax:
    3% Auto add to Liquidity Pool .
    3% Auto added to marketing.
    1% Auto added to team
    3% Auto Send to buyback address.
    1% Auto send to PSI rewards
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import './interfaces/IPancakeFactory.sol';
import './interfaces/IPancakePair.sol';
import './interfaces/IPancakeRouter02.sol';
import './interfaces/IDividendTracker.sol';

// 
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using AddressUpgradeable for address;
    
    mapping (address => uint256) private _balances;
    mapping (address => bool) public feeExcludedAddress;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _lockTime;
    address public _Owner;
    address public _previousOwner;
    address public _psiAddress;
    address public _buybackAddress;
    address public _liquidityPoolAddress; // not used?
    address payable public _marketingAddress;
    address payable public _teamAddress;
    uint public psiFee;
    uint public liquidityFee;
    uint public marketingFee;
    uint public buybackFee;
    uint public teamFee;
    bool public sellLimiter; // by default false
    uint public sellLimit; // sell limit if sellLimiter is true
    
    uint256 public _maxTxAmount;
    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    uint256 private minTokensBeforeSwap;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier onlyOwner{
        require(_msgSender() == _Owner, 'Only Owner Can Call This Function');
        _;
    }
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
         _;
        inSwapAndLiquify = false;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    bool public pauseTrade;

    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event UpdateDefaultDexRouter(address indexed newAddress, address indexed oldAddress);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    mapping(address => bool) public dexRouters;
    // store addresses that are automatic market maker (dex) pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    IDividendTracker public dividendTracker;
    uint256 public gasForProcessing;

    receive() external payable {}

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function _ERC20_init(
        string memory _nm,
        string memory _sym,
        address payable marketingAddress_,
        address payable teamAddress_,
        address psiAddress_,
        address buybackAddress_,
        address router_
    ) internal initializer {
        _name = _nm;
        _symbol = _sym;
        _decimals = 18;
        swapAndLiquifyEnabled = true;
        minTokensBeforeSwap = 8;
        psiFee = 100; //1%
        liquidityFee = 300; //3%
        marketingFee = 300; //3%
        teamFee = 100; //1%
        buybackFee = 300; //3%
        sellLimit = 50000 * 10 ** 18; //sell limit if sellLimiter is true
        _maxTxAmount = 5000000 * 10**18;
        _marketingAddress = marketingAddress_;
        _teamAddress = teamAddress_;
        _psiAddress = psiAddress_;
        _buybackAddress = buybackAddress_;
        _Owner = _msgSender();
        
        pancakeRouter = IPancakeRouter02(router_);
        dexRouters[router_] = true;
         // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        _setAutomatedMarketMakerPair(pancakePair, true);
        
        feeExcludedAddress[_msgSender()] = true;
    }

    function initPSIDividendTracker(IDividendTracker _dividendTracker) external onlyOwner {
        require(address(dividendTracker) == address(0), "AstroBirdz: Dividend tracker already initialized");
        dividendTracker = _dividendTracker;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(pancakeRouter));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));

        // add pair as marketMaker
        _setAutomatedMarketMakerPair(pancakePair, true);

        // whitlist wallets f.e. owner wallet to send tokens before presales are over
        excludeFromFeesAndDividends(address(this));
        excludeFromFeesAndDividends(_Owner);

        // use by default 300,000 gas to process auto-claiming dividends
        gasForProcessing = 300000;
        minTokensBeforeSwap = 10000 * (10 ** decimals()); // min 10k tokens in contract before swapping
        _liquidityPoolAddress = _Owner;
        _psiAddress = dividendTracker.dividendToken();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint) {
        return _decimals;
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
    
    function calculateLiquidityFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * liquidityFee) / 10**4;
    }
    
    function calculatePSIFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * psiFee) / 10**4;
    }
    
    function calculateMarketingFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * marketingFee) / 10**4;
    }

    function calculateTeamFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * teamFee) / 10**4;
    }

    function calculateBuybackFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * buybackFee) / 10**4;
    }
    
    function setPSIFee(uint256 PSIfee_) public onlyOwner{
        require(PSIfee_ < 1500, 'Fee must be less than 15%');
        psiFee = PSIfee_;
    }
    
    function setLiquidityFee(uint256 LPfee_) public onlyOwner{
        require(LPfee_ < 1500, 'Fee must be less than 15%');
        liquidityFee = LPfee_;
    }
    
    function setBuybackFee(uint256 BBFee_) public onlyOwner{
        require(BBFee_ < 1500, 'Fee must be less than 15%');
        buybackFee = BBFee_;
    }

    function setMarketingFee(uint256 Mfee_) public onlyOwner{
        require(Mfee_ < 1500, 'Fee must be less than 15%');
        marketingFee = Mfee_;
    }

    function setTeamFee(uint256 Tfee_) public onlyOwner{
        require(Tfee_ < 1500, 'Fee must be less than 15%');
        teamFee = Tfee_;
    }
    
    function toggleSellLimit() external onlyOwner() {
        sellLimiter = !sellLimiter;
    }
    
    function setBuybackAddress(address buybackAddress_) public onlyOwner{
        require(buybackAddress_ != address(0),'Cannot be a zero address');
        _buybackAddress = buybackAddress_;
    }
    
    function changeMarketingAddress(address payable marketingAddress_) public onlyOwner{
        require(marketingAddress_ != address(0),'Cannot be a zero address');
        _marketingAddress = marketingAddress_;
    }

    function changeTeamAddress(address payable teamAddress_) public onlyOwner{
        require(teamAddress_ != address(0),'Cannot be a zero address');
        _teamAddress = teamAddress_;
    }

    function changePSIAddress(address PSIAddress_) public onlyOwner{
        require(PSIAddress_ != address(0),'Cannot be a zero address');
        _psiAddress = PSIAddress_;
    }

    function changeLiquidityAddress(address payable liquidityAddress_) public onlyOwner{
        require(liquidityAddress_ != address(0),'Cannot be a zero address');
        _liquidityPoolAddress = liquidityAddress_;
    }
    
    function changeSellLimit(uint256 _sellLimit) public onlyOwner{
        sellLimit = _sellLimit;
    }
    
    function changeMaxtx(uint256 _maxtx) public onlyOwner{
        _maxTxAmount = _maxtx;
    }
    
    function addExcludedAddress(address excludedA) public onlyOwner{
        feeExcludedAddress[excludedA] = true;
    }
    function removeExcludedAddress(address excludedA) public onlyOwner{
        feeExcludedAddress[excludedA] = false;
    }
    function excludeFromFeesAndDividends(address excludedA) public onlyOwner {
        addExcludedAddress(excludedA);
        dividendTracker.excludeFromDividends(excludedA);
    }

    function addNewRouter(address _router, bool makeDefault) external onlyOwner {
        dexRouters[_router] = true;
        dividendTracker.excludeFromDividends(_router);

        if (makeDefault) {
            emit UpdateDefaultDexRouter(_router, address(pancakeRouter));
            pancakeRouter = IPancakeRouter02(_router);
            pancakePair = IPancakeFactory(pancakeRouter.factory()).getPair(address(this), pancakeRouter.WETH());
            if (pancakePair == address(0))
                pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
            _setAutomatedMarketMakerPair(pancakePair, true);
        }
    }
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(
            value || pair != pancakePair,
            'AstroBirdz: The default pair cannot be removed from automatedMarketMakerPairs'
        );
        _setAutomatedMarketMakerPair(pair, value);
    }
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            'AstroBirdz: Automated market maker pair is already set to that value'
        );

        automatedMarketMakerPairs[pair] = value;
        if (value && address(dividendTracker) != address(0)) dividendTracker.excludeFromDividends(pair);
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            'AstroBirdz: gasForProcessing must be between 200,000 and 500,000'
        );
        require(newValue != gasForProcessing, 'AstroBirdz: Cannot update gasForProcessing to same value');
        gasForProcessing = newValue;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_Owner, newOwner);
        _Owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _Owner;
        _Owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_Owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_Owner, _previousOwner);
        _Owner = _previousOwner;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        require(receivers.length != 0, 'Cannot Proccess Null Transaction');
        require(receivers.length == amounts.length, 'Address and Amount array length must be same');
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
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
        // only calculate fee on trades
        if( feeExcludedAddress[recipient] ||
            feeExcludedAddress[_msgSender()] || 
            (!automatedMarketMakerPairs[recipient] && !automatedMarketMakerPairs[_msgSender()]) ) {
            _transferExcluded(_msgSender(), recipient, amount);
        } else {
            _transfer(_msgSender(), recipient, amount);    
        }
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(feeExcludedAddress[recipient] || feeExcludedAddress[sender]){
            _transferExcluded(sender, recipient, amount);
        }else{
            _transfer(sender, recipient, amount);
        }

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked { _approve(sender, _msgSender(), currentAllowance - amount); }
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
        unchecked { _approve(_msgSender(), spender, currentAllowance - subtractedValue); }
        return true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
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
    function _transferExcluded(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(sender != _Owner && recipient != _Owner)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if(automatedMarketMakerPairs[recipient] && balanceOf(recipient) > 0 && sellLimiter)
            require(amount < sellLimit, 'Cannot sell more than sellLimit');

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        unchecked { _balances[sender] -= amount; }
        _balances[recipient] += amount;

        if (address(dividendTracker) != address(0)) {
            try dividendTracker.setBalance(payable(sender), balanceOf(sender)) {} catch {}
            try dividendTracker.setBalance(payable(recipient), balanceOf(recipient)) {} catch {}
        }

        emit Transfer(sender, recipient, amount);
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(sender != _Owner && recipient != _Owner)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if(automatedMarketMakerPairs[recipient] && balanceOf(recipient) > 0 && sellLimiter)
            require(amount < sellLimit, 'Cannot sell more than sellLimit');
        if(automatedMarketMakerPairs[recipient] || automatedMarketMakerPairs[sender])
            require(pauseTrade, "Trading Paused");

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        unchecked { _balances[sender] -= amount; }

        uint256 tokenToTransfer = amount -
            calculateLiquidityFee(amount) -
            calculateBuybackFee(amount) -
            calculateMarketingFee(amount) -
            calculatePSIFee(amount) -
            calculateTeamFee(amount);
        
        _balances[recipient] += tokenToTransfer;

        if (address(dividendTracker) != address(0)) {
            try dividendTracker.setBalance(payable(sender), balanceOf(sender)) {} catch {}
            try dividendTracker.setBalance(payable(recipient), balanceOf(recipient)) {} catch {}
        }

        _balances[address(this)] += amount - tokenToTransfer;
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            contractTokenBalance >= minTokensBeforeSwap &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[sender] &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        emit Transfer(sender, recipient, tokenToTransfer);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFees = liquidityFee + marketingFee + teamFee + buybackFee + psiFee ;
        uint256 forLiquidity = (contractTokenBalance * liquidityFee) / totalFees;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance - (forLiquidity / 2)); // withold half of the liquidity tokens
        uint256 swappedBalance = address(this).balance - initialBalance;

        payable(_marketingAddress).transfer((swappedBalance * marketingFee) / totalFees);
        payable(_teamAddress).transfer((swappedBalance * teamFee) / totalFees);

        swapAndSendDividends((swappedBalance * psiFee) / totalFees);

        addLiquidity(forLiquidity / 2, (swappedBalance * liquidityFee) / totalFees);
        emit SwapAndLiquify(contractTokenBalance, swappedBalance, forLiquidity / 2);

        payable(_buybackAddress).transfer(address(this).balance - initialBalance); // buybackfee + leftovers
    }

    function toggleTrading() public onlyOwner{
        pauseTrade = !pauseTrade;
    }
     
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _liquidityPoolAddress,
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 ethAmount) private {
        uint256 psiBalanceBefore = IERC20(_psiAddress).balanceOf(address(dividendTracker));
        swapETHForPSI(ethAmount, address(dividendTracker));
        uint256 dividends = psiBalanceBefore - IERC20(_psiAddress).balanceOf(address(dividendTracker));

        dividendTracker.distributeDividends(dividends);
        emit SendDividends(ethAmount, dividends);
    }

    function swapETHForPSI(uint256 ethAmount, address recipient) private {
        // generate the uniswap pair path of weth -> PSI
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = _psiAddress;

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of PSI
            path,
            recipient,
            block.timestamp
        );
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(_msgSender() == tx.origin, "Invalid Request");
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[_msgSender()] >= amount,'insufficient balance!');

        _beforeTokenTransfer(account, address(0x000000000000000000000000000000000000dEaD), amount);

        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        unchecked { _balances[account] -= amount; }
        _totalSupply -= amount;

        emit Transfer(account, address(0x000000000000000000000000000000000000dEaD), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract AstroBirdsV2 is Initializable, ERC20Upgradeable {
    function initialize(
        string memory _name,
        string memory _symbol,
        address payable marketingAddress_,
        address payable teamAddress_,
        address psiAddress_,
        address buybackAddress_,
        address router_
    ) public initializer {
        ERC20Upgradeable._ERC20_init(
            _name,
            _symbol,
            marketingAddress_,
            teamAddress_,
            psiAddress_,
            buybackAddress_,
            router_
        );
        
        _mint(_msgSender(), 470000000 ether);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.4;

import './token/IBEP20.sol';
import './token/IDividendPayingTokenInterface.sol';
import './token/IDividendPayingTokenOptionalInterface.sol';
import './token/IERC20TokenRecover.sol';

interface IDividendTracker is
    IBEP20,
    IDividendPayingTokenInterface,
    IDividendPayingTokenOptionalInterface,
    IERC20TokenRecover
{
    function lastProcessedIndex() external view returns (uint256);

    function excludedFromDividends(address account) external view returns (bool);

    function lastClaimTimes(address account) external view returns (uint256);

    function claimWait() external view returns (uint256);

    function minimumTokenBalanceForDividends() external view returns (uint256);

    event ExcludeFromDividends(address indexed account);
    event IncludedInDividends(address indexed account);

    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    function excludeFromDividends(address account) external;

    function includeInDividends(address account) external;

    function updateClaimWait(uint256 newClaimWait) external;

    function updateMinTokenBalance(uint256 minTokens) external;

    function getLastProcessedIndex() external view returns (uint256);

    function getNumberOfTokenHolders() external view returns (uint256);

    function getAccount(address _account)
        external
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
        );

    function getAccountAtIndex(uint256 index)
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
        );

    function ensureBalance(bool _process) external;

    function ensureBalanceForUsers(bytes calldata accounts, bool _process) external;

    function ensureBalanceForUser(address payable account, bool _process) external;

    function setBalance(address payable account, uint256 newBalance) external;

    function process(uint256 gas)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function processAccount(address payable account, bool automatic) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IBEP20 is IERC20, IERC20Metadata {
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDividendPayingTokenInterface {
    function dividendToken() external view returns(address);
    function parentToken() external view returns(address);

    function totalDividendsDistributed() external view returns(uint256);

    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` can withdraw.
     */
    function dividendOf(address _owner) external view returns (uint256);

    /**
     * @notice Withdraws the ether distributed to the sender.
     * @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` 
     *      SHOULD be 0 after the transfer.
     *      MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
     */
    function withdrawDividend() external;

    function distributeDividends(uint256 amount) external;

    /**
     * @dev This event MUST emit when ether is distributed to token holders.
     * @param from The address which sends ether to this contract.
     * @param weiAmount The amount of distributed ether in wei.
     */
    event DividendsDistributed(address indexed from, uint256 weiAmount);

    /**
     * @dev This event MUST emit when an address withdraws their dividend.
     * @param to The address which withdraws ether from this contract.
     * @param weiAmount The amount of withdrawn ether in wei.
     */
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDividendPayingTokenOptionalInterface {
    /**
     * @notice View the amount of dividend in wei that an address can withdraw.
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` can withdraw.
     */
    function withdrawableDividendOf(address _owner) external view returns (uint256);

    /**
     * @notice View the amount of dividend in wei that an address has withdrawn.
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` has withdrawn.
     */
    function withdrawnDividendOf(address _owner) external view returns (uint256);

    /**
     * @notice View the amount of dividend in wei that an address has earned in total.
     * @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
     * @param _owner The address of a token holder.
     * @return The amount of dividend in wei that `_owner` has earned in total.
     */
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IERC20TokenRecover
 * @dev Allows owner to recover any ERC20 or ETH sent into the contract
 * based on https://github.com/vittominacori/eth-token-recover by Vittorio Minacori
 */
interface IERC20TokenRecover {
    /**
     * @notice function that transfers an token amount from this contract to the owner when accidentally sent
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    /**
     * @notice function that transfers an eth amount from this contract to the owner when accidentally sent
     * @param amount Number of eth to be sent
     */
    function recoverETH(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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