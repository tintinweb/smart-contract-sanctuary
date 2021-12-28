/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

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
}

contract Ownable is Context {
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
    function renounceOwnership() external virtual onlyOwner {
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

interface IUniswapV2Router02{
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

contract Whitepaper is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    IERC20 public constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // BUSD
    IERC20 public constant WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // WBNB

    bool private swapping;

    address public marketingWallet;
    address public buyBackWallet;
    address public liquidityAddress;
    
    uint256 public maxBuyTransactionAmount;
    uint256 public maxSellTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    mapping (address => uint256) public walletLastSell; // use to determine penalty tier
    uint256 public sellPenaltyTime = 7 days;
    uint256 public lastBuyBack;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    uint256 public tradingActiveBlock = 0;
    bool public swapEnabled = false;
    uint256 public tradingBlock = 0;
    
    bool private gasLimitActive = true;
    uint256 private constant gasPriceLimit = 70 * 1 gwei; // do not allow over x gwei for launch
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBuyBackFee;
    
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBuyBackFee;

    uint256 public sellTotalFeesTier2;
    uint256 public sellMarketingFeeTier2;
    uint256 public sellLiquidityFeeTier2;
    uint256 public sellBuyBackFeeTier2;

    uint256 public tokensForLiquidity;
    uint256 public tokensForBuyBack;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
    
    event BuyBackWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event LiquidityWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event BuyBackInitiated(uint256 indexed tokenAmount);

    event TransferForeignToken(address indexed token, uint256 amount);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 busdReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Whitepaper", "WP") {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), address(BUSD));
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        
        uint256 _buyMarketingFee = 30;
        uint256 _buyLiquidityFee = 20;
        uint256 _buyBuyBackFee = 100;

        uint256 _sellMarketingFee = 30;
        uint256 _sellLiquidityFee = 20;
        uint256 _sellBuyBackFee = 100;

        uint256 _sellMarketingFeeTier2 = 50;
        uint256 _sellLiquidityFeeTier2 = 50;
        uint256 _sellBuyBackFeeTier2 = 220;
        
        uint256 totalSupply = 1 * 1e9 * 1e18;
        
        maxBuyTransactionAmount = totalSupply * 1 / 10000; // 0.01% max buy
        maxSellTransactionAmount = totalSupply * 15/ 100000; // 0.015% max sell
        swapTokensAtAmount = totalSupply * 25 / 100000; // 0.025% Min swap amount

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyBuyBackFee = _buyBuyBackFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBuyBackFee;
        
        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellBuyBackFee = _sellBuyBackFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBuyBackFee;

        sellMarketingFeeTier2 = _sellMarketingFeeTier2;
        sellLiquidityFeeTier2 = _sellLiquidityFeeTier2;
        sellBuyBackFeeTier2 = _sellBuyBackFeeTier2;
        sellTotalFeesTier2 = sellMarketingFeeTier2 + sellLiquidityFeeTier2 + sellBuyBackFeeTier2;
        
    	marketingWallet = address(owner()); // set as marketing wallet
        buyBackWallet = address(owner()); // set as buyBack Wallet
        liquidityAddress = address(owner()); // set as liquidity address

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _createInitialSupply(msg.sender, totalSupply);
    }

    receive() external payable {

  	}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot enable trading again");
        tradingActive = true;
        swapEnabled = true;
        tradingBlock = block.number;
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        gasLimitActive = false;
        transferDelayEnabled = false;
        return true;
    }
    
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return true;
    }
    
    function airdropToWallets(address[] memory airdropWallets, uint256[] memory amounts) external onlyOwner {
        require(airdropWallets.length == amounts.length, "arrays must be the same length");
        require(airdropWallets.length < 200, "Can only airdrop 200 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 amount = amounts[i];
            super._transfer(msg.sender, wallet, amount);
        }
    }

    function isSellTier2(address wallet) public view returns (bool){
        if(walletLastSell[wallet] + sellPenaltyTime > block.timestamp){
            return true;
        }
        return false;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
      
    
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 10000)/1e18, "Cannot set maxTransactionAmount lower than 0.01%");
        maxBuyTransactionAmount = newNum * (10**18);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 10000)/1e18, "Cannot set maxTransactionAmount lower than 0.01%");
        maxSellTransactionAmount = newNum * (10**18);
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
    
    function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _buyBackFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyBuyBackFee = _buyBackFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyBuyBackFee;
        require(buyTotalFees <= 200, "Must keep fees at 20% or less");
    }
    
    function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _buyBackFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellBuyBackFee = _buyBackFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellBuyBackFee;
        require(sellTotalFees <= 200, "Must keep fees at 20% or less");
    }

    function updateSellFeesTier2(uint256 _marketingFee, uint256 _liquidityFee, uint256 _buyBackFee) external onlyOwner {
        sellMarketingFeeTier2 = _marketingFee;
        sellLiquidityFeeTier2 = _liquidityFee;
        sellBuyBackFeeTier2 = _buyBackFee;
        sellTotalFeesTier2 = sellMarketingFeeTier2 + sellLiquidityFeeTier2 + sellBuyBackFeeTier2;
        require(sellTotalFeesTier2 <= 320, "Must keep fees at 32% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        emit marketingWalletUpdated(newWallet, marketingWallet);
        marketingWallet = newWallet;
    }
    
    function updateBuyBackWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        emit BuyBackWalletUpdated(newWallet, buyBackWallet);
        buyBackWallet = newWallet;
    }

    function updateLiquidityWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "cannot set to 0 address");
        emit LiquidityWalletUpdated(newWallet, liquidityAddress);
        liquidityAddress = newWallet;
    }
    

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
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

        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }
        
        if(limitsInEffect){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                
                // only use to prevent sniper buys in the first blocks.
                if (gasLimitActive && automatedMarketMakerPairs[from]) {
                    require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxBuyTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
            }
        }

		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }
        
        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        uint256 tokensForMarketing = 0;

        // if a buyback is happening, update the lastBuyBack timestamp.
        if(automatedMarketMakerPairs[from] && to == buyBackWallet){
            lastBuyBack = block.timestamp;
            emit BuyBackInitiated(amount);
        }

        
        if(takeFee){
            // 99% fee for 5 blocks.  All tokens go to marketing.
            if(automatedMarketMakerPairs[from] && block.number <= tradingBlock + 5){
                fees = amount * 990 / 1000;
                tokensForMarketing = fees;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFeesTier2 > 0 && (isSellTier2(from) || lastBuyBack + 30 minutes >= block.timestamp)){
                fees = amount * sellTotalFeesTier2 / 1000;
                tokensForLiquidity += fees * sellLiquidityFeeTier2 / sellTotalFeesTier2;
                tokensForBuyBack += fees * sellBuyBackFeeTier2 / sellTotalFeesTier2;
                tokensForMarketing = fees * sellMarketingFeeTier2 / sellTotalFeesTier2;
                walletLastSell[from] = block.timestamp;
            }
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / 1000;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForBuyBack += fees * sellBuyBackFee / sellTotalFees;
                tokensForMarketing = fees * sellMarketingFee / sellTotalFees;
                walletLastSell[from] = block.timestamp;
            }
            // on buy or transfer
            else {
        	    fees = amount * buyTotalFees / 1000;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForBuyBack += fees * buyBuyBackFee / buyTotalFees;
                tokensForMarketing = fees * buyMarketingFee / buyTotalFees;
            }

            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }

            if(tokensForMarketing > 0){
                super._transfer(address(this), marketingWallet, tokensForMarketing);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForBUSD(uint256 tokenAmount) internal {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(BUSD);
        path[2] = address(WBNB);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        swapEthForBusd(address(this).balance);
    }

    function swapEthForBusd(uint256 ethAmountInWei) internal {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(BUSD);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 busdAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        BUSD.approve(address(uniswapV2Router), busdAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            address(BUSD),
            tokenAmount,
            busdAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForBuyBack;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10){
            contractBalance = swapTokensAtAmount * 10;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForBUSD = contractBalance - liquidityTokens;
        
        uint256 initialBUSDBalance = BUSD.balanceOf(address(this));

        swapTokensForBUSD(amountToSwapForBUSD); 
        
        uint256 busdBalance = BUSD.balanceOf(address(this)) - initialBUSDBalance;
        
        uint256 busdForBuyBack = busdBalance * tokensForBuyBack / (totalTokensToSwap - (tokensForLiquidity/2));
        
        uint256 busdForLiquidity = busdBalance - busdForBuyBack;
        
        tokensForLiquidity = 0;
        tokensForBuyBack = 0;
                
        if(liquidityTokens > 0 && busdForLiquidity > 0){
            addLiquidity(liquidityTokens, busdForLiquidity);
            emit SwapAndLiquify(amountToSwapForBUSD, busdForLiquidity, tokensForLiquidity);
        }
        
        BUSD.transfer(buyBackWallet, BUSD.balanceOf(address(this)));
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
}