/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// File: contracts/IUniswapV2Router02.sol

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
// File: contracts/IUniswapV2Factory.sol

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
// File: contracts/ERC20.sol

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
    uint256 constant internal _totalSupply = 1e22;
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
        return _totalSupply - _balances[address(0)];
    }

    function balanceOf(address account) public view override returns (uint256) {
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
        if (currentAllowance < _totalSupply) {
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }
        return true;
    }

    /*function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }*/

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

// File: contracts/Ownable.sol

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

// File: contracts/TradableErc20.sol

pragma solidity ^0.8.7;

//import "hardhat/console.sol";





abstract contract TradableErc20 is ERC20, Ownable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) public isBot;
    mapping(address => bool) _isExcludedFromFee;
    bool _autoBanBots = true;
    bool _inSwap;
    uint256 public maxBuy;

    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxByyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 public maxBuyIncrementValue; // value for increment maxBuy
    uint256 public incrementTime; // last increment time

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

        // approve uniswap router to transfer infinity contract tokens
        _approve(address(this), address(_uniswapV2Router), _totalSupply);

        uniswapV2Pair = pair;
        tradingEnable = true;

        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxByyIncrementPercentil) / 1000;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // antibot
        require(!isBot[from] && !isBot[to]);

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            // trading enable
            require(tradingEnable, "trading disabled");
            // antibot
            if (_autoBanBots) isBot[to] = true;
            // increment maxBuy
            uint256 incrementCount = (block.timestamp - incrementTime) /
                (maxBuyIncrementMinutesTimer * 1 minutes);
            if (incrementCount > 0) {
                if (maxBuy < _totalSupply) {
                    unchecked {
                        maxBuy += maxBuyIncrementValue * incrementCount;
                    }
                }
                incrementTime = block.timestamp;
            }
            // maxBuy limitation
            uint256 startBalanceTo = _balances[to];
            if (!_autoBanBots) require(startBalanceTo + amount <= maxBuy);
            // calculate fee
            uint256 fee = amount / 20; // 5% to contract and burn
            // transfers
            uint256 startBalanceFrom = _balances[from];
            require(
                startBalanceFrom >= amount,
                "not enough token for transfer"
            );
            unchecked {
                _balances[from] = startBalanceFrom - amount;
                _balances[to] = startBalanceTo + amount - 2 * fee;
                _balances[address(this)] += fee;
                _balances[address(0)] += fee;
            }
            emit Transfer(from, to, amount);
            emit Transfer(to, address(this), fee);
            emit Transfer(to, address(0), fee);
            // transfer end
            return;
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            // trading enable
            require(tradingEnable, "trading disabled");
            // calculate and transfer fee
            amount = _getFeeSell(amount, from);
            // get contract token balance
            uint256 contractTokenBalance = balanceOf(address(this));
            // swap contract tokens
            if (contractTokenBalance > 0) {
                // burn contract token surplus
                uint256 maxContractBalance = (balanceOf(uniswapV2Pair) *
                    getMaxContractBalancePercent()) / 100;
                if (contractTokenBalance > maxContractBalance) {
                    uint256 burnCount;
                    unchecked {
                        burnCount = contractTokenBalance - maxContractBalance;
                        contractTokenBalance = maxContractBalance;
                        _balances[address(this)] = maxContractBalance;
                        _balances[address(0)] += burnCount;
                    }
                    emit Transfer(address(this), address(0), burnCount);
                }
                // swap contract tokens
                uint256 swapCount = contractTokenBalance;
                uint256 maxSwapCount = 2 * amount;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
                swapTokensForEth(swapCount);
            }
        }

        // transfer
        super._transfer(from, to, amount);
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
        uint256 devFee = amount / 20; // 5%
        uint256 burnCount = getSellBurnCount(amount); // burn count

        amount -= devFee + burnCount;
        _balances[account] -= devFee + burnCount;
        _balances[address(0)] += burnCount;
        _balances[address(this)] += devFee;
        emit Transfer(account, address(0), burnCount);
        emit Transfer(account, address(this), devFee);
        return amount;
    }

    function setMaxBuy(uint256 percent) external onlyOwner {
        _setMaxBuy(percent);
    }

    function _setMaxBuy(uint256 percentil) internal {
        maxBuy = (percentil * _totalSupply) / 1000;
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

    function getMaxContractBalancePercent() internal virtual returns (uint256);
}

// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

// File: contracts/ZEUS10000.sol

// https://ZEUS10000.com
// https://t.me/zeus10000

pragma solidity ^0.8.7;



contract ZEUS10000 is TradableErc20, Withdrawable {
    uint256 maxContractLiquidityPercent = 4;

    constructor() TradableErc20("ZEUS10000", "ZEUS10000") {
        _withdrawAddress = address(0x64485E260439613940b16821ad080c6862B73152);
        _setMaxBuy(2);
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
}