// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./utils/Context.sol";
import "./utils/Ownable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/Pancakeswap/IFactory.sol";
import "../interfaces/Pancakeswap/IPair.sol";
import "../interfaces/Pancakeswap/IRouter01.sol";
import "../interfaces/Pancakeswap/IRouter02.sol";


contract ERC20Deflationary is Context, IERC20, Ownable {
    // balances for address that are included.
    mapping (address => uint256) private _rBalances;
    // balances for address that are excluded.
    mapping (address => uint256) private _tBalances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;


    // liquidity pool provider router
    IUniswapV2Router02 internal _uniswapV2Router;
    address internal _uniswapV2Pair;

    address private constant burnAccount = 0x000000000000000000000000000000000000dEaD;

    address[] private _excludedFromReward;
   
   // this percent of transaction amount that will be burnt.
    uint8 private _taxBurn;
    // percent of transaction amount that will be redistribute to all holders.
    uint8 private _taxReward;
    // percent of transaction amount that will be added to the liquidity pool
    uint8 private _taxLiquidity; 
    uint8 private immutable _decimals;
    uint256 private  _totalSupply;
    uint256 private _currentSupply;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    // swap and liquify every million tokens
    uint256 private _minTokensBeforeSwap;

    string private _name;
    string private _symbol;


    bool private _inSwapAndLiquify;
    bool private _autoSwapAndLiquifyEnabled;
    bool private _autoBurnEnabled;
    bool private _rewardEnabled;
        
    modifier lockTheSwap {
        require(!_inSwapAndLiquify, "Currently in swap and liquify.");
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    struct ValuesFromAmount {
        uint256 amount;
        uint256 tBurnFee;
        uint256 tRewardFee;
        uint256 tLiquidityFee;
        // amount after fee
        uint256 tTransferAmount;

        uint256 rAmount;
        uint256 rBurnFee;
        uint256 rRewardFee;
        uint256 rLiquidityFee;
        uint256 rTransferAmount;
    }

    event Burn(address from, uint256 amount);
    event TaxBurnUpdate(uint8 previous, uint8 current);
    event TaxRewardUpdate(uint8 previous, uint8 current);
    event TaxLiquidityUpdate(uint8 previous, uint8 current);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensAddedToLiquidity
    );
    event ExcludeAccountFromReward(address account);
    event IncludeAccountInReward(address account);
    event ExcludeAccountFromFee(address account);
    event IncludeAccountInFee(address account);
    event MinTokensBeforeSwapUpdated(uint256 previous, uint256 current);
    event EnabledAutoBurn(uint8 taxBurn_);
    event EnabledReward(uint taxReward_);
    event EnabledAutoSwapAndLiquify(uint8 taxLiquidity_);
    event DisabledAutoBurn();
    event DisabledReward();
    event DisabledAutoSwapAndLiquify();


    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        // Sets the values for `name`, `symbol`, `totalSupply`, `taxFeeBurn`, `taxFeeReward`, and `taxFeeLiquidity`.
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10**decimals_);
        _currentSupply = _totalSupply;
        _rTotal = (~uint256(0) - (~uint256(0) % _totalSupply));

        // mint
        _rBalances[_msgSender()] = _rTotal;

        
        
        
        // exclude owner and this contract from fee.
        _excludeFromFee(owner());
        _excludeFromFee(address(this));

        // exclude owner, burnAccount, and this contract from receiving rewards.
        excludeAccountFromReward(owner());
        excludeAccountFromReward(burnAccount);
        excludeAccountFromReward(address(this));
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function taxBurn() public view virtual returns (uint8) {
        return _taxBurn;
    }

    function taxReward() public view virtual returns (uint8) {
        return _taxReward;
    }

    function taxLiquidity() public view virtual returns (uint8) {
        return _taxLiquidity;
    }
    function minTokensBeforeSwap() public view virtual returns (uint256) {
        return _minTokensBeforeSwap;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function currentSupply() public view virtual returns (uint256) {
        return _currentSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tBalances[account];
        return tokenFromReflection(_rBalances[account]);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
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
        require(account != burnAccount, "ERC20: burn from the burn address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        uint256 rAmount = _getRValuesWithoutFee(amount);

        if (isExcluded(account)) {
            _tBalances[account] -= amount;
            _rBalances[account] -= rAmount;
        } else {
            _rBalances[account] -= rAmount;
        }

        _tBalances[burnAccount] += amount;
        _rBalances[burnAccount] += rAmount;

        // decrease the current coin supply
        _currentSupply -= amount;

        emit Burn(account, amount);
        emit Transfer(account, burnAccount, amount);
    }
   
     

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        ValuesFromAmount memory values = _getValues(amount, _isExcludedFromFee[sender]);
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, values);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, values);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, values);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, values);
        } else {
            _transferStandard(sender, recipient, values);
        }

        if (!_isExcludedFromFee[sender]) {
            _afterTokenTransfer(values);
        }

    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function totalFees() public view virtual returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @dev Distribute tokens to all holders that are included from reward. 
     *
     *  Requirements:
     * - the caller must have a balance of at least `amount`.
     */
    function airdrop(uint256 amount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        ValuesFromAmount memory values = _getValues(amount, false);
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _rTotal = _rTotal - values.rAmount;
        _tFeeTotal = _tFeeTotal + amount ;
    }

    function reflectionFromToken(uint256 amount, bool deductTransferFee) public view returns(uint256) {
        require(amount <= _totalSupply, "Amount must be less than supply");
        ValuesFromAmount memory values = _getValues(amount, deductTransferFee);
        return values.rTransferAmount;
    }

    /**
        Used to figure out the balance of rBalance.
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }


    /**
     * burns
     * reflect
     * add liquidity

        tValues = (uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee, uint256 tLiquidityFee);
        rValues = uint256 rAmount, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 rLiquidityFee;
     */
    function _afterTokenTransfer(ValuesFromAmount memory values) internal virtual {
        // burn from contract address
        if (_autoBurnEnabled) {
            _tBalances[address(this)] += values.tBurnFee;
            _rBalances[address(this)] += values.rBurnFee;
            _approve(address(this), _msgSender(), values.tBurnFee);
            burnFrom(address(this), values.tBurnFee);
        }   
        
        
        // reflect
        if (_rewardEnabled) {
            _distributeFee(values.rRewardFee, values.tRewardFee);
        }
        
        
        // add to liquidity
        
        if (_autoSwapAndLiquifyEnabled) {
            // add liquidity fee to this contract.
            _tBalances[address(this)] += values.tLiquidityFee;
            _rBalances[address(this)] += values.rLiquidityFee;

            uint256 contractBalance = _tBalances[address(this)];

            // whether the current contract balances makes the threshold to swap and liquify.
            bool overMinTokensBeforeSwap = contractBalance >= _minTokensBeforeSwap;

            if (overMinTokensBeforeSwap &&
                !_inSwapAndLiquify &&
                _msgSender() != _uniswapV2Pair &&
                _autoSwapAndLiquifyEnabled
                ) 
            {
                swapAndLiquify(contractBalance);
            }
        }
        
     }

    
    function _transferStandard(address sender, address recipient, ValuesFromAmount memory values) private {
        
    
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;   

        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    
    function _transferToExcluded(address sender, address recipient, ValuesFromAmount memory values) private {
        
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _tBalances[recipient] = _tBalances[recipient] + values.tTransferAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;    

        
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    
    function _transferFromExcluded(address sender, address recipient, ValuesFromAmount memory values) private {
        
        _tBalances[sender] = _tBalances[sender] - values.amount;
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;   


        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    
    function _transferBothExcluded(address sender, address recipient, ValuesFromAmount memory values) private {

        _tBalances[sender] = _tBalances[sender] - values.amount;
        _rBalances[sender] = _rBalances[sender] - values.rAmount;
        _tBalances[recipient] = _tBalances[recipient] + values.tTransferAmount;
        _rBalances[recipient] = _rBalances[recipient] + values.rTransferAmount;        

        
        emit Transfer(sender, recipient, values.tTransferAmount);
    }

    // allow the contract to receive ETH
    receive() external payable {}

    function swapAndLiquify(uint256 contractBalance) internal lockTheSwap {
        // split the contract balance into two halves.
        uint256 tokensToSwap = contractBalance / 2;
        uint256 tokensAddToLiquidity = contractBalance - tokensToSwap;

        // contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // swap half of the tokens to ETH.
        swapTokensForEth(tokensToSwap);

        uint256 ethAddToLiquify = address(this).balance - initialBalance;

        addLiquidity(ethAddToLiquify, tokensAddToLiquidity);

        emit SwapAndLiquify(tokensToSwap, ethAddToLiquify, tokensAddToLiquidity);
    }

    function swapTokensForEth(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), amount);


        // swap tokens to eth
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 
            0, 
            path, 
            address(this), 
            block.timestamp + 60 * 1000
            );
    }
    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) public {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this), 
            tokenAmount, 
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), 
            block.timestamp + 60 * 1000
        );
    }
    function _distributeFee(uint256 rFee, uint256 tFee) private {
        // to decrease rate thus increase amount reward receive.
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    function _getValues(uint256 amount, bool deductTransferFee) private view returns (ValuesFromAmount memory) {
        ValuesFromAmount memory values;
        values.amount = amount;
        _getTValues(values, deductTransferFee);
        _getRValues(values, deductTransferFee);
        return values;
    }

    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee) view private {
        
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            // calculate fee
            values.tBurnFee = _calculateTax(values.amount, _taxBurn);
            values.tRewardFee = _calculateTax(values.amount, _taxReward);
            values.tLiquidityFee = _calculateTax(values.amount, _taxLiquidity);
            
            // amount after fee
            values.tTransferAmount = values.amount - values.tBurnFee - values.tRewardFee - values.tLiquidityFee;
        }
        
    }

    function _getRValues(ValuesFromAmount memory values, bool deductTransferFee) view private {
        uint256 currentRate = _getRate();

        values.rAmount = values.amount * currentRate;

        if (deductTransferFee) {
            values.rTransferAmount = values.rAmount;
        } else {
            values.rAmount = values.amount * currentRate;
            values.rBurnFee = values.tBurnFee * currentRate;
            values.rRewardFee = values.tRewardFee * currentRate;
            values.rLiquidityFee = values.tLiquidityFee * currentRate;
            values.rTransferAmount = values.rAmount - values.rBurnFee - values.rRewardFee - values.rLiquidityFee;
        }
        
    }

    function _getRValuesWithoutFee(uint256 amount) private view returns (uint256) {
        uint256 currentRate = _getRate();
        return amount * currentRate;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rBalances[_excludedFromReward[i]] > rSupply || _tBalances[_excludedFromReward[i]] > tSupply) return (_rTotal, _totalSupply);
            rSupply = rSupply - _rBalances[_excludedFromReward[i]];
            tSupply = tSupply - _tBalances[_excludedFromReward[i]];
        }
        if (rSupply < _rTotal / _totalSupply) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }

    function _calculateTax(uint256 amount, uint8 taxRate) private pure returns (uint256) {
        return amount * taxRate / (10**2);
    }


    /*
        Owner functions
    */
    function enableAutoBurn(uint8 taxBurn_) public onlyOwner {
        require(!_autoBurnEnabled, "Auto burn feature is already enabled.");
        _autoBurnEnabled = true;
        setTaxBurn(taxBurn_);
        
        
        emit EnabledAutoBurn(taxBurn_);
    }

    function enableReward(uint8 taxReward_) public onlyOwner {
        require(!_rewardEnabled, "Reward feature is already enabled.");
        _rewardEnabled = true;
        setTaxReward(taxReward_);
        
        
        emit EnabledReward(taxReward_);
    }

    function enableAutoSwapAndLiquify(uint8 taxLiquidity_, address routerAddress, uint256 minTokensBeforeSwap_) public onlyOwner {
        require(!_autoSwapAndLiquifyEnabled, "Auto swap and liquify feature is already enabled.");

        _minTokensBeforeSwap = minTokensBeforeSwap_;

        // init Router
        
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);

        if (IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH()) == address(0)) {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        } else {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .getPair(address(this), uniswapV2Router.WETH());
        }
        

        _uniswapV2Router = uniswapV2Router;

        // enable
        _autoSwapAndLiquifyEnabled = true;
        setTaxLiquidity(taxLiquidity_);
        
        
        emit EnabledAutoSwapAndLiquify(taxLiquidity_);
    }


    function disableAutoBurn() public onlyOwner {
        require(_autoBurnEnabled, "Auto burn feature is already disabled.");
        setTaxBurn(0);
        _autoBurnEnabled = false;
        
        
        emit DisabledAutoBurn();
    }

    function disableReward() public onlyOwner {
        require(_rewardEnabled, "Reward feature is already disabled.");
        setTaxReward(0);
        _rewardEnabled = false;
        
        
        emit DisabledReward();
    }

    function disableAutoSwapAndLiquify() public onlyOwner {
        require(_autoSwapAndLiquifyEnabled, "Auto swap and liquify feature is already disabled.");
        setTaxLiquidity(0);
        _autoSwapAndLiquifyEnabled = false;
        
        
        emit DisabledAutoSwapAndLiquify();
    }

    function setMinTokensBeforeSwap(uint256 minTokensBeforeSwap_) public onlyOwner {
        require(minTokensBeforeSwap_ < _currentSupply, "minTokensBeforeSwap must be higher than current supply.");
        _minTokensBeforeSwap = minTokensBeforeSwap_;
    }

    function setTaxBurn(uint8 taxBurn_) public onlyOwner {
        require(_autoBurnEnabled, "Auto burn feature must be enabled. Try the EnableAutoBurn function.");
        require(taxBurn_ + _taxReward + _taxLiquidity < 100, "Tax fee too high.");
        uint8 previous = _taxBurn;
        _taxBurn = taxBurn_;
        emit TaxBurnUpdate(previous, _taxBurn);
    }

    function setTaxReward(uint8 taxReward_) public onlyOwner {
        require(_rewardEnabled, "Reward feature must be enabled. Try the EnableReward function.");
        require(_taxBurn + taxReward_ + _taxLiquidity < 100, "Tax fee too high.");
        uint8 previous = _taxReward;
        _taxReward = taxReward_;
        emit TaxRewardUpdate(previous, _taxReward);
    }

    function setTaxLiquidity(uint8 taxLiquidity_) public onlyOwner {
        require(_autoSwapAndLiquifyEnabled, "Auto swap and liquify feature must be enabled. Try the EnableAutoSwapAndLiquify function.");
        require(_taxBurn + _taxReward + taxLiquidity_ < 100, "Tax fee too high.");
        uint8 previous = _taxLiquidity;
        _taxLiquidity = taxLiquidity_;
        emit TaxLiquidityUpdate(previous, _taxLiquidity);
    }

    function _excludeFromFee(address account) private onlyOwner {
        _isExcludedFromFee[account] = true;

        emit ExcludeAccountFromFee(account);
    }

    function _includeInFee(address account) private onlyOwner {
        _isExcludedFromFee[account] = false;
        
        emit IncludeAccountInFee(account);
    }

    function excludeAccountFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rBalances[account] > 0) {
            _tBalances[account] = tokenFromReflection(_rBalances[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
        
        emit ExcludeAccountFromReward(account);
    }

    function includeAccountFromReward(address account) public onlyOwner {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tBalances[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }

        emit IncludeAccountInReward(account);
    }
    

}

pragma solidity ^0.8.4;

import "./utils/Context.sol";
import "./ERC20Deflationary.sol";

contract ExampleToken is Context, ERC20Deflationary {

    // pancakeswap for testnet
    //address routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    //uniswap
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string name_ = "ExampleToken";
    string symbol_ = "EXT";
    uint8 decimal_ = 9;
    uint256 totalSupply_ = 100;
    uint8 taxFee_ = 10;

    constructor () ERC20Deflationary(name_, symbol_, decimal_, totalSupply_) {
        enableAutoBurn(taxFee_);
        enableReward(taxFee_);
        //enableAutoSwapAndLiquify(10, routerAddress, 10 * 10**9);
    }

}

// A copy of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// A copy of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^ 0.8.4;

// for more info: https://uniswap.org/docs/v2/smart-contracts/factory/

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity ^0.8.4;

// for more info: https://uniswap.org/docs/v2/smart-contracts/pair/

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
}

pragma solidity ^0.8.4;

// for more info: https://uniswap.org/docs/v2/smart-contracts/router01/

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

pragma solidity ^0.8.4;

// for more info: https://uniswap.org/docs/v2/smart-contracts/router02/

import "./IRouter01.sol";

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

