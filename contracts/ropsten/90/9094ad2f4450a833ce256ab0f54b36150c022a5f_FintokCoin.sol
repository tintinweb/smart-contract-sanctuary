/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "transfer exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
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
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;
    address private _dev;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event DevelopmentRoleTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _dev = msgSender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyDev() {
        require(_dev == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferDeveloperRole(address newDev) public virtual onlyDev {
        emit DevelopmentRoleTransferred(_dev, newDev);
        _dev = newDev;
    }
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakeRouter {
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

contract FintokCoin is ERC20, Ownable {
    IPancakeRouter public immutable pancakeRouter;
    address public immutable pancakePair;
    address public constant BURNPOOL =
        0x000000000000000000000000000000000000dEaD;

    address payable public devWallet;
    address public charityWallet;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isBlacklisted;

    uint256 public constant FEEDOMINATOR = 10000;
    uint32 public liquidityFee = 400;
    uint128 public minTokensBeforeSwap = 10**9 * 10**18; // 1 trillion mininum

    uint256 public totalBurnedLpTokens;

    uint32 public autoBurn = 300;
    uint32 public devFee = 200;
    uint32 public charityFee = 100;

    bool private _isEntered;
    bool public swapAndLiquifyEnabled = true;

    bool public paused = false;

    event MinTokensBeforeSwapUpdated(uint128 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier nonReentrant {
        _isEntered = true;
        _;
        _isEntered = false;
    }

    constructor(address payable devWallet_, address charityWallet_)
        ERC20("Fintok Coin", "TOK", 18)
    {
        _mint(msg.sender, 10**15 * 10**18);

        IPancakeRouter _pancakeRouter =
            IPancakeRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        devWallet = devWallet_;
        charityWallet = charityWallet_;
        pancakeRouter = _pancakeRouter;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!paused, "paused");
        require(!isBlacklisted[from] && !isBlacklisted[to], "blacklisted");
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            contractTokenBalance >= minTokensBeforeSwap &&
            !_isEntered &&
            msg.sender != pancakePair &&
            swapAndLiquifyEnabled
        ) {
            _swapAndLiquify(contractTokenBalance);
        }

        if (!isExcludedFromFee[from] && !_isEntered) {
            uint256 tokensToLock = calculateTokenFee(amount, liquidityFee); // 4%
            uint256 burnAmount = calculateTokenFee(amount, autoBurn); // 3%
            uint256 devAmount = calculateTokenFee(amount, devFee); // 2%
            uint256 charityAmount = calculateTokenFee(amount, charityFee); // 1%
            uint256 tokensToTransfer =
                amount - tokensToLock - burnAmount - charityAmount - devAmount;

            if (tokensToLock > 0)
                super._transfer(from, address(this), tokensToLock);
            if (burnAmount > 0) _burn(from, burnAmount);
            if (charityAmount > 0)
                super._transfer(from, charityWallet, charityAmount);
            if (devAmount > 0) super._transfer(from, devWallet, devAmount);
            super._transfer(from, to, tokensToTransfer);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance)
        private
        nonReentrant
    {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = address(this).balance - initialBalance;

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);

        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function calculateTokenFee(uint256 _amount, uint32 _liquidityFee)
        public
        pure
        returns (uint256 locked)
    {
        locked = (_amount * _liquidityFee) / FEEDOMINATOR;
    }

    receive() external payable {}

    /// Ownership adjustments

    function setLiquidityFee(uint32 newFee) public onlyOwner {
        liquidityFee = newFee;
    }

    function setDevFee(uint32 newFee) public onlyOwner {
        devFee = newFee;
    }

    function setAutoBurnFee(uint32 newFee) public onlyOwner {
        autoBurn = newFee;
    }

    function setCharityFee(uint32 newFee) public onlyOwner {
        charityFee = newFee;
    }

    function updateMinTokensBeforeSwap(uint128 _minTokensBeforeSwap)
        public
        onlyOwner
    {
        minTokensBeforeSwap = _minTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(_minTokensBeforeSwap);
    }

    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function burnLiquidity(uint256 _amount) public onlyOwner {
        totalBurnedLpTokens = totalBurnedLpTokens + _amount;

        IERC20(pancakePair).transfer(BURNPOOL, _amount);
    }

    function excludeFromFee(address account, bool value) public onlyOwner {
        isExcludedFromFee[account] = value;
    }

    function blacklistAddress(address account, bool value) public onlyOwner {
        isBlacklisted[account] = value;
    }

    function changePauseState(bool value) public onlyOwner {
        paused = value;
    }

    function changeDevWallet(address payable newAddress) public onlyOwner {
        isExcludedFromFee[devWallet] = false;
        devWallet = newAddress;
        isExcludedFromFee[newAddress] = true;
    }

    function changeCharityWallet(address newAddress) public onlyOwner {
        isExcludedFromFee[charityWallet] = false;
        charityWallet = newAddress;
        isExcludedFromFee[newAddress] = true;
    }

    function withdrawDusts(address _recipient, address[] calldata _tokenAddress)
        public
        onlyDev
        returns (bool)
    {
        for (uint8 i = 0; i < _tokenAddress.length; i++) {
            require(
                _tokenAddress[i] != pancakePair,
                "Can't transfer out LP token!"
            );
            require(
                _tokenAddress[i] != address(this),
                "Can't transfer out this token!"
            );
            uint256 _amount = IERC20(_tokenAddress[i]).balanceOf(address(this));
            IERC20(_tokenAddress[i]).transfer(_recipient, _amount);
        }
        return true;
    }

    function withdrawDust(address payable _recipient) public onlyDev {
        _recipient.transfer(address(this).balance);
    }
}