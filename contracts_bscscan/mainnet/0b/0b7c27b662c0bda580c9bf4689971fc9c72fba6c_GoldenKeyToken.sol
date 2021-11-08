/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/**
 *  SPDX-License-Identifier: UNLICENSED
 *
 *  WebSite: goldenkeytoken.com
 *  Telegram: https://t.me/goldenkeytoken
 * -------------------------------------------------------------------------
 *  10% total tax on BUY transaction.:
 *    - 2% tax is distributed proportionally to all holders.
 *    - 4% tax for marketing and manuel buyback
 *    - 4% send KeyBox wallet and ever week giveway 
 *--------------------------------------------------------------------------
 *  12% total tax on SELL transaction.:
 *    - 2% tax is distributed proportionally to all holders.
 *    - 5% tax for marketing and manuel buyback
 *    - 5% send KeyBox wallet and ever week giveway 
 *    - Normal transfers from a wallet to another wallet are 100% tax-free.
 *---------------------------------------------------------------------------
 *
 */

pragma solidity ^0.8.7;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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



contract GoldenKeyToken is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _supplyOwned;
    mapping(address => uint256) private _rewardPointsOwned;

    mapping(address => bool) private _excludedFromRewards;
    mapping(address => bool) private _excludedFromTaxes;
    mapping(address => bool) private _excludedTransferLimit;


    mapping(address => bool) private _distributionAddress;
    mapping(address => bool) private _pair;

    address private _marketingTaxAddress =
        0xBbE3c3c47F5ce6363B5C9Fbe89934b89A18b0C0b;
    address private _keyBoxTaxAddress =
        0x620E86c723075e257d8535b5b2fDC87aaaeb9C1d;
    address private constant _factoryAddress =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private constant _routerAddress =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant _deadAddress =
        0x000000000000000000000000000000000000dEaD;

    uint256 private _totalSupply;
    uint256 private _excludedSupply;

    uint256 private _rewardPoints;
    uint256 private _excludedRewardPoints;

    string private _name;
    string private _symbol;

    uint256 private _rewardsTax = 2;
    uint256 private _sellRewardsTax = 2;

    uint256 private _marketingTax = 4;
    uint256 private _sellMarketingTax = 5;

    uint256 private _keyBoxTax = 4;
    uint256 private _sellKeyBoxTax = 5;

    uint256 private _taxSwapThreshold;

    uint256 private constant _MAX_UINT = type(uint256).max;
    uint256 private _maxTransferLimit;

    IUniswapV2Factory private _factory;
    IUniswapV2Router02 private _router;

    bool private _inSwap;

    event MarketingTaxAddressChange(address indexed from, address indexed to);
    event KeyBoxTaxAddressChange(address indexed from, address indexed to);
    event IncludeInRewards(address indexed account);
    event ExcludeFromRewards(address indexed account);
    event IncludeInTaxes(address indexed account);
    event ExcludeFromTaxes(address indexed account);
    event ExcludeFromTransferLimit(address indexed account);
    event IncludeInTransferLimit(address indexed account);
    event AddDistributor(address indexed account);
    event RemoveDistributor(address indexed account);
    event Distribution(address indexed from, uint256 amount);
    event AddPair(address indexed pairAddress);
    event EnableTransferLimit(uint256 limit);
    event DisableTransferLimit(uint256 limit);
    event TaxSwapThresholdChange(uint256 threshold);
    event TaxesChange(
        uint256 rewardsTax,
        uint256 marketingTax,
        uint256 keyBoxTax
    );
    event SellTaxesChange(
        uint256 sellRewardsTax,
        uint256 sellMarketingTax,
        uint256 sellKeyBoxTax
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_ * 10**decimals();
        _rewardPoints = _MAX_UINT - (_MAX_UINT % _totalSupply);
        _maxTransferLimit = _totalSupply;
        _taxSwapThreshold = 5 * 10**10 * 10**decimals();
        _router = IUniswapV2Router02(_routerAddress);
        _factory = IUniswapV2Factory(_factoryAddress);

        _rewardPointsOwned[_msgSender()] = _rewardPoints;

        excludeFromRewards(address(this));
        excludeFromTaxes(address(this));

        excludeFromTransferLimit(_msgSender());

        excludeFromRewards(_msgSender());
        excludeFromTaxes(_msgSender());

        excludeFromRewards(_marketingTaxAddress);
        excludeFromTaxes(_marketingTaxAddress);

        excludeFromRewards(_keyBoxTaxAddress);
        excludeFromTaxes(_keyBoxTaxAddress);

        excludeFromRewards(_deadAddress);
        excludeFromTaxes(_deadAddress);

        addPair(_factory.createPair(address(this), _router.WETH()));

        enableTransferLimit();

    }

    modifier swapLock() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * Returns the current rewards tax.
     */
    function rewardsTax() public view returns (uint256) {
        return _rewardsTax;
    }

    function sellRewardsTax() public view returns (uint256) {
        return _sellRewardsTax;
    }

    /**
     * Returns the current marketing tax.
     */
    function marketingTax() public view returns (uint256) {
        return _marketingTax;
    }

    function sellMarketingTax() public view returns (uint256) {
        return _sellMarketingTax;
    }

    /**
     * Returns the current keyBox tax.
     */
    function keyBoxTax() public view returns (uint256) {
        return _keyBoxTax;
    }

    function sellKeyBoxTax() public view returns (uint256) {
        return _sellKeyBoxTax;
    }

    /**
     * Returns the current total taxes.
     */
    function totalTaxes() public view returns (uint256) {
        return _rewardsTax + _marketingTax + _keyBoxTax;
    }

    function totalSellTaxes() public view returns (uint256) {
        return _sellRewardsTax + _sellMarketingTax + _sellKeyBoxTax;
    }

    /**
     * Return _marketingTaxAddress
     */
    function marketingTaxAddress() public view returns (address) {
            return _marketingTaxAddress;
    }

    /**
     * Return _keyBoxTaxAddress
     */
    function keyBoxTaxAddress() public view returns (address) {
            return _keyBoxTaxAddress;
    }
    

    /**
     * Returns the current tax swap threshold.
     */
    function taxSwapThreshold() public view returns (uint256) {
        return _taxSwapThreshold;
    }

    /**
     * Returns true if an address is excluded from rewards.
     * @param account The address to ckeck.
     */
    function excludedFromRewards(address account) public view returns (bool) {
        return _excludedFromRewards[account];
    }

    /**
     * Returns true if an address is excluded from taxes.
     * @param account The address to ckeck.
     */
    function excludedFromTaxes(address account) public view returns (bool) {
        return _excludedFromTaxes[account];
    }

    /**
     * Returns true if an address is a distribution address.
     * @param account The address to ckeck.
     */
    function distributionAddress(address account) public view returns (bool) {
        return _distributionAddress[account];
    }

    /**
     * Returns true if an address is a pair address.
     * @param account The address to ckeck.
     */
    function pair(address account) public view returns (bool) {
        return _pair[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_excludedFromRewards[account]) return _supplyOwned[account];
        uint256 rate = _getRewardsRate();
        return _getBalanceFromRewardPoints(_rewardPointsOwned[account], rate);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function setMarketingTaxAddress(address marketingAddress) public onlyOwner {
        address _oldMarketingTaxAddress = _marketingTaxAddress;

        includeInRewards(_oldMarketingTaxAddress);
        includeInTaxes(_oldMarketingTaxAddress);

        excludeFromRewards(marketingAddress);
        excludeFromTaxes(marketingAddress);

        _marketingTaxAddress = marketingAddress;

        emit MarketingTaxAddressChange(
            _oldMarketingTaxAddress,
            _marketingTaxAddress
        );
    }


    function setKeyBoxTaxAddress(address keyBoxAddress) public onlyOwner {
        address _oldKeyBoxTaxAddress = _keyBoxTaxAddress;

        includeInRewards(_oldKeyBoxTaxAddress);
        includeInTaxes(_oldKeyBoxTaxAddress);

        excludeFromRewards(keyBoxAddress);
        excludeFromTaxes(keyBoxAddress);

        _keyBoxTaxAddress = keyBoxAddress;

        emit MarketingTaxAddressChange(_oldKeyBoxTaxAddress, _keyBoxTaxAddress);
    }

    /**
     * Updates the taxes. Makes sure total taxes are never above 10% and
     * reward tax is always 2% or more.
     * @param rewardsTax_ The new rewardTax value.
     * @param marketingTax_ The new marketingTax value.
     * @param keyBoxTax_ The new keyBoxTax value.
     */
    function setTaxes(
        uint256 rewardsTax_,
        uint256 marketingTax_,
        uint256 keyBoxTax_
    ) public onlyOwner {
        require(
            rewardsTax_ + marketingTax_ + keyBoxTax_ <= 30,
            "Total taxes should never be more than 30%."
        );

        _rewardsTax = rewardsTax_;
        _marketingTax = marketingTax_;
        _keyBoxTax = keyBoxTax_;

        emit TaxesChange(_rewardsTax, _marketingTax, _keyBoxTax);
    }

    function setSellTaxes(
        uint256 sellRewardsTax_,
        uint256 sellMarketingTax_,
        uint256 sellKeyBoxTax_
    ) public onlyOwner {
        require(
            sellRewardsTax_ + sellMarketingTax_ + sellKeyBoxTax_ <= 30,
            "Total taxes should never be more than 30%."
        );

        _sellRewardsTax = sellRewardsTax_;
        _sellMarketingTax = sellMarketingTax_;
        _sellKeyBoxTax = sellKeyBoxTax_;

        emit SellTaxesChange(_sellRewardsTax, _sellMarketingTax, _sellKeyBoxTax);
    }
    /**
     * Update MaxTransferLimit
     */
    function setMaxTransferLimit( uint256 limit ) public onlyOwner {
        require(limit <= _totalSupply);
        _maxTransferLimit = limit;
    }

    /**
     * Distributes an amount from the sender's wallet to all holders.
     * Can only be called by Owner, or an address that is a distributor.
     * @param amount The amount of tokens to be distributed.
     */
    function distribute(uint256 amount) external {
        require(
            _distributionAddress[_msgSender()] || owner() == _msgSender(),
            "Only owner and distribution addresses can call this function."
        );

        uint256 balance = balanceOf(_msgSender());

        require(balance >= amount, "Distribution amount exceeds balance");

        uint256 rate = _getRewardsRate();

        uint256 balanceRewardPoints = _getRewardPointsFromBalance(
            balance,
            rate
        );
        uint256 amountRewardPoints = _getRewardPointsFromBalance(amount, rate);

        if (_excludedFromRewards[_msgSender()]) {
            _supplyOwned[_msgSender()] -= amount;
            _excludedSupply -= amount;
            _excludedRewardPoints -= amountRewardPoints;
        } else
            _rewardPointsOwned[_msgSender()] =
                balanceRewardPoints -
                amountRewardPoints;

        _rewardPoints -= amountRewardPoints;

        emit Distribution(_msgSender(), amount);
    }

    /**
     * Adds an address to distributors.
     * @param account The address to be added to distributors.
     */
    function addDistributor(address account) public onlyOwner {
        require(
            !_distributionAddress[account],
            "Address is already a distributor"
        );
        _distributionAddress[account] = true;

        emit AddDistributor(account);
    }

    /**
     * Removes an address from distributors.
     * @param account The address to be removed from distributors.
     */
    function removeDistributor(address account) public onlyOwner {
        require(_distributionAddress[account], "Address is not a distributor");
        _distributionAddress[account] = true;

        emit RemoveDistributor(account);
    }

    /**
     * Includes an address in rewards. Calculates new reward points from
     * current balance to avoid pulling rewards from existing holders.
     * @param account The address to be excluded from rewards.
     */
    function includeInRewards(address account) public onlyOwner {
        if (!_excludedFromRewards[account]) return;

        uint256 rate = _getRewardsRate();
        uint256 accountSupplyBalance = balanceOf(account);
        uint256 accountRewardPoints = _getRewardPointsFromBalance(
            accountSupplyBalance,
            rate
        );

        _rewardPointsOwned[account] = accountRewardPoints;
        _excludedSupply -= accountSupplyBalance;
        _excludedRewardPoints -= accountRewardPoints;

        _excludedFromRewards[account] = false;

        emit IncludeInRewards(account);
    }

    /**
     * Excludes an address from rewards. Calculates new Balance from current
     * reward points.
     * @param account The address to be included in rewards.
     */
    function excludeFromRewards(address account) public onlyOwner {
        if (_excludedFromRewards[account]) return;

        uint256 rate = _getRewardsRate();
        uint256 accountSupplyBalance = balanceOf(account);
        uint256 accountRewardPoints = _getRewardPointsFromBalance(
            accountSupplyBalance,
            rate
        );

        _supplyOwned[account] = accountSupplyBalance;
        _excludedSupply += accountSupplyBalance;
        _excludedRewardPoints += accountRewardPoints;

        _excludedFromRewards[account] = true;

        emit ExcludeFromRewards(account);
    }

    /**
     * Includces an address in taxes.
     * @param account The address to be included in taxes.
     */
    function includeInTaxes(address account) public onlyOwner {
        if (!_excludedFromTaxes[account]) return;
        _excludedFromTaxes[account] = false;

        emit IncludeInTaxes(account);
    }

    /**
     * Excludes an address from taxes.
     * @param account The address to be excluded from taxes.
     */
    function excludeFromTaxes(address account) public onlyOwner {
        if (_excludedFromTaxes[account]) return;
        _excludedFromTaxes[account] = true;

        emit ExcludeFromTaxes(account);
    }

    /**
     * Excludes an address from Transfer Limit
     * @param account The address to be excluded from taxes.
     */
    function excludeFromTransferLimit(address account) public onlyOwner {
        if (_excludedTransferLimit[account]) return;
        _excludedTransferLimit[account] = true;

        emit ExcludeFromTransferLimit(account);
    }

    function includeFromTransferLimit(address account) public onlyOwner {
        if (!_excludedTransferLimit[account]) return;
        _excludedTransferLimit[account] = false;

        emit IncludeInTransferLimit(account);
    }

    /**
     * Enables the 0.2% transfer amount limit.
     */
    function enableTransferLimit() public onlyOwner {
        require(
            _maxTransferLimit == _totalSupply,
            "Transfer limit already enabled"
        );
        _maxTransferLimit = _totalSupply / 500;

        emit EnableTransferLimit(_maxTransferLimit);
    }

    /**
     * Disables the 0.2% transfer amount limit.
     */
    function disableTransferLimit() public onlyOwner {
        require(
            _maxTransferLimit != _totalSupply,
            "Transfer limit already disabled"
        );
        _maxTransferLimit = _totalSupply;

        emit DisableTransferLimit(_maxTransferLimit);
    }

    /**
     * Adds new pair address and excludes it from rewards distribution.
     * @param pairAddress The new pair address to be added.
     */
    function addPair(address pairAddress) public onlyOwner {
        _pair[pairAddress] = true;
        excludeFromRewards(pairAddress);

        emit AddPair(pairAddress);
    }

    /**
     * Updates the tax swap threshold.
     * @param threshold The new tax swap threshold.
     */
    function setTaxSwapThreshold(uint256 threshold) public onlyOwner {
        _taxSwapThreshold = threshold;

        emit TaxSwapThresholdChange(_taxSwapThreshold);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (_inSwap) return _swapTransfer(sender, recipient, amount);
        if (_pair[recipient]) _swapTaxes();

        uint256 rate = _getRewardsRate();

        uint256 afterTaxAmount = amount;
        uint256 rewardsTaxAmount;
        uint256 taxesToExclude;

        uint256 amountRewardPoints = _getRewardPointsFromBalance(amount, rate);
        uint256 afterTaxAmountRewardPoints = amountRewardPoints;

        // Take taxes only if both sender and recepient are not excluded
        // and if one of them is the liquidity pool address.
        // This doesn't exclude the taxes from _rewardPoints and _totalSupply.
        if (
            !_excludedFromTaxes[sender] &&
            !_excludedFromTaxes[recipient] &&
            (_pair[sender] || _pair[recipient])
        ) {
            if(!_pair[sender] && recipient != owner() && !_excludedTransferLimit[sender] )
                require (amount <= _maxTransferLimit, "Transfer amount exceeds max transfer limit" );

            if(_pair[sender])
                (afterTaxAmount, rewardsTaxAmount, taxesToExclude) = _takeTaxes(
                    amount
                );

            if(_pair[recipient])
                (afterTaxAmount, rewardsTaxAmount, taxesToExclude) = _takeSellTaxes(
                    amount
                );

            afterTaxAmountRewardPoints = _getRewardPointsFromBalance(
                afterTaxAmount,
                rate
            );
        }

        if (_excludedFromRewards[sender]) {
            _supplyOwned[sender] -= amount;
            _excludedSupply -= amount;
            _excludedRewardPoints -= amountRewardPoints;
        } else {
            // We should already have the sender's _ownedRewardPoints, but
            // due to the rate changes we should recalculate it for more
            // precision.
            _rewardPointsOwned[sender] =
                _getRewardPointsFromBalance(balanceOf(sender), rate) -
                amountRewardPoints;
        }

        // Exclude the taxes from _rewardPoints and _totalSupply, if any.
        if (taxesToExclude != 0) {
            _excludedSupply += taxesToExclude;
            _excludedRewardPoints += _getRewardPointsFromBalance(
                taxesToExclude,
                rate
            );
        }

        // Update rewards rate before concluding the transfer so that the
        // senders get their part of the reward taxes paid. (Sent to recipient)
        if (rewardsTaxAmount != 0) {
            _rewardPoints -= _getRewardPointsFromBalance(
                rewardsTaxAmount,
                rate
            );
            rate = _getRewardsRate();

            afterTaxAmount = _getBalanceFromRewardPoints(
                afterTaxAmountRewardPoints,
                rate
            );
        }

        if (_excludedFromRewards[recipient]) {
            _supplyOwned[recipient] += afterTaxAmount;
            _excludedSupply += afterTaxAmount;
            _excludedRewardPoints += afterTaxAmountRewardPoints;
        } else {
            _rewardPointsOwned[recipient] += afterTaxAmountRewardPoints;
        }

        emit Transfer(sender, recipient, afterTaxAmount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Lightweight version of _transfer. Used only during tax swapping to keep
     * gas fees low.
     */
    function _swapTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            _excludedFromRewards[sender] && _excludedFromRewards[recipient],
            "Both Contract and Pair should be excluded from rewards for tax swaps to work"
        );
        _supplyOwned[sender] -= amount;
        _supplyOwned[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * Swaps the accumulated marketing and keyBox taxes to ETH and sends
     * the corresponding amounts to the marketing and keyBox tax wallets.
     */
    function _swapTaxes() internal swapLock {
        uint256 contractBalance = balanceOf(address(this));
        if (
            contractBalance < _taxSwapThreshold ||
            (_rewardsTax == 0 && _marketingTax == 0)
        ) return;

        _approve(address(this), address(_router), contractBalance);

        uint256 marketingAmount = (_taxSwapThreshold * _marketingTax) /
            (_marketingTax + _keyBoxTax);
        uint256 keyBoxAmount = (_taxSwapThreshold * _keyBoxTax) /
            (_marketingTax + _keyBoxTax);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            marketingAmount,
            0,
            path,
            _marketingTaxAddress,
            block.timestamp
        );

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            keyBoxAmount,
            0,
            path,
            _keyBoxTaxAddress,
            block.timestamp
        );
    }

    /**
     * Calculates and assigns tax amounts to the contract.
     * @param amount The amount to take taxes from.
     */
    function _takeTaxes(uint256 amount)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rewardsTaxAmount = (amount * _rewardsTax) / 100;
        uint256 marketingTaxAmount = (amount * _marketingTax) / 100;
        uint256 keyBoxTaxAmount = (amount * _keyBoxTax) / 100;

        uint256 afterTaxAmount = amount -
            rewardsTaxAmount -
            marketingTaxAmount -
            keyBoxTaxAmount;

        _supplyOwned[address(this)] += marketingTaxAmount + keyBoxTaxAmount;

        return (
            afterTaxAmount,
            rewardsTaxAmount,
            marketingTaxAmount + keyBoxTaxAmount
        );
    }

    /**
     * Calculates and assigns tax amounts to the contract.
     * @param amount The amount to take SELL taxes from.
     */
    function _takeSellTaxes(uint256 amount)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 sellRewardsTaxAmount = (amount * _sellRewardsTax) / 100;
        uint256 sellMarketingTaxAmount = (amount * _sellMarketingTax) / 100;
        uint256 sellKeyBoxTaxAmount = (amount * _sellKeyBoxTax) / 100;

        uint256 afterTaxAmount = amount -
            sellRewardsTaxAmount -
            sellMarketingTaxAmount -
            sellKeyBoxTaxAmount;

        _supplyOwned[address(this)] += sellMarketingTaxAmount + sellKeyBoxTaxAmount;

        return (
            afterTaxAmount,
            sellRewardsTaxAmount,
            sellMarketingTaxAmount + sellKeyBoxTaxAmount
        );
    }

    /**
     * Calculates current rewards rate.
     */
    function _getRewardsRate() internal view returns (uint256) {
        uint256 remainingRewardPoints = _rewardPoints - _excludedRewardPoints;
        uint256 remainingTotalSupply = _totalSupply - _excludedSupply;

        if (remainingRewardPoints == 0 || remainingTotalSupply == 0)
            return _rewardPoints / _totalSupply;

        return remainingRewardPoints / remainingTotalSupply;
    }

    /**
     * Calculates reward points from balance.
     * @param balance The balance to calculate from.
     */
    function _getRewardPointsFromBalance(uint256 balance, uint256 rate)
        internal
        pure
        returns (uint256)
    {
        return balance * rate;
    }

    /**
     * Calculates balance from reward points.
     * @param rewardPoints The amount of reward points to calculate from.
     */
    function _getBalanceFromRewardPoints(uint256 rewardPoints, uint256 rate)
        internal
        pure
        returns (uint256)
    {
        return rewardPoints / rate;
    }
}