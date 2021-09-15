//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Upwork is Context, IERC20, IERC20Metadata, Ownable {
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;

    string private _name = "Upwork";
    string private constant _symbol = "UPW";
    uint8 private constant _decimals = 8;
    uint256 private constant _initialSupply = 100000000000000 * 10**8;
    uint256 private constant _numTokensSellToAddToLiquidity = 10000000000 * 10**8; // 0.01% of initial supply
    address private constant _pancakeSwapRouterAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    uint256 private _totalSupply;
    bool private _inSwapAndLiquify;

    uint256 public liquidityPercent = 8 * 10**2; // 8%
    uint256 public burnPercent = 2 * 10**2; // 2%
    uint256 public maxTxAmount = 100000000000 * 10**8; // 0.1%
    IUniswapV2Router02 public immutable uniswapRouter;
    address public immutable uniswapPair;

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /**
     * Initialize the token.
     */
    constructor () {
        _mint(owner(), _initialSupply);

        IUniswapV2Router02 _uniswapRouter = IUniswapV2Router02(_pancakeSwapRouterAddress);
        uniswapRouter = _uniswapRouter;
        
        address _uniswapPair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        uniswapPair = _uniswapPair;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_uniswapPair] = true;
    }
    
    /**
     * @dev Sets the maximum transaction amount.
     */
    function setMaxTxAmount(uint256 _maxTxAmount) public onlyOwner() {
        maxTxAmount = _maxTxAmount;
    }
    
    /**
     * @dev Sets the liquidity and burn percent.
     */
    function setTaxPercentages(uint256 _liquidityPercent, uint256 _burnPercent) public onlyOwner() {
        liquidityPercent = _liquidityPercent;
        burnPercent = _burnPercent;
    }

    /**
     * @dev Returns the fee status of an address.
     */
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    /**
     * @dev Sets exclude/include fees for an address.
     */
    function setExcludeFromFees(address account, bool value) public onlyOwner() {
        _isExcludedFromFees[account] = value;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
     * @dev Swaps tokens for ETH.
     */
    function _swapTokensForEth(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), amount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
    }

    /**
     * @dev Adds liquidity to PancakeSwap.
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    /**
     * @dev Swaps tokens for ETH and adds liquidity to PancakeSwap.
     */
    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(half);
        uint256 newBalance = address(this).balance - initialBalance;
        _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
     * @dev To recieve ETH from PancakeSwap when swaping.
     */
    receive() external payable {}

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= maxTxAmount)
        {
            contractTokenBalance = maxTxAmount;
        }

        if (contractTokenBalance >= _numTokensSellToAddToLiquidity && !_inSwapAndLiquify && sender != uniswapPair) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            _swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        if(isExcludedFromFees(recipient))
        {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
        }
        else
        {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

            uint256 autoLPAmount = amount * liquidityPercent / 100 / 10**2;
            uint256 autoBurnAmount = amount * burnPercent / 100 / 10**2;
            _balances[sender] -= amount;
            _balances[recipient] += amount - autoLPAmount - autoBurnAmount;
            _balances[address(this)] += autoLPAmount;
            _totalSupply -= autoBurnAmount;
            emit Transfer(sender, address(0), autoBurnAmount);
        }
        
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
}