/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// File: contracts/FirstBlockBots.sol

abstract contract FirstBlockBots {
    mapping(address => bool) public isBot;
    uint256 notBanBlock;

    function startAntibot() internal {
        notBanBlock = block.number + 1;
    }

    function isAutoBanBots() public view returns (bool) {
        return block.number < notBanBlock;
    }

    function trySetBot(address account) internal {
        if (!isAutoBanBots()) return;
        isBot[account] = true;
    }

    function checkBot(address account) internal view {
        require(!isBot[account], "bot detected");
    }
}

// File: contracts/IERC20.sol

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
// File: contracts/ERC20.sol

pragma solidity ^0.8.7;


abstract contract ERC20 is IERC20 {
    uint256 internal constant _totalSupply = 1234567890;
    string _name;
    string _symbol;
    uint8 constant _decimals = 0;
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
    ) internal virtual;

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
}
// File: contracts/MaxBuyDynamic.sol



abstract contract MaxBuyDynamic is ERC20 {
    uint256 public maxBuy;
    uint256 constant maxBuyIncrementMinutesTimer = 2; // increment maxbuy minutes
    uint256 constant maxBuyIncrementPercentil = 1; // increment maxbyu percentil 1000=100%
    uint256 public maxBuyIncrementValue; // value for increment maxBuy
    uint256 public incrementTime; // last increment time

    function startMaxBuyDynamic() internal {
        incrementTime = block.timestamp;
        maxBuyIncrementValue = (_totalSupply * maxBuyIncrementPercentil) / 1000;
    }

    function checkAndIncrementMaxBuyLimit(uint256 amount) internal {
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
        require(amount <= maxBuy);
    }

    function getMaxBuy() external view returns (uint256) {
        uint256 incrementCount = (block.timestamp - incrementTime) /
            (maxBuyIncrementMinutesTimer * 1 minutes);
        if (incrementCount == 0) return maxBuy;

        return maxBuy + maxBuyIncrementValue * incrementCount;
    }

    function setMaxBuyPercentil(uint256 percentil) internal {
        maxBuy = (_totalSupply * percentil) / 1000;
    }
}

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






abstract contract TradableErc20 is MaxBuyDynamic, FirstBlockBots, Ownable {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair;
    bool public tradingEnable;
    mapping(address => bool) _isExcludedFromFee;
    bool _inSwap;
    mapping(address => uint256) _buyTimes;
    uint256 _sellDelay = 24; // sell delay in hours
    uint256 public tax24HoursPercent = 30;
    uint256 public maxWalletValue;

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
        uint256 initialSupply = getSupplyForMakeLiquidity();
        _balances[address(this)] = initialSupply;
        _allowances[address(this)][address(_uniswapV2Router)] = _totalSupply; // approve uniswap router to transfer infinity contract tokens
        _isExcludedFromFee[pair] = true;
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            initialSupply,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        uniswapV2Pair = pair;
        tradingEnable = true;

        startAntibot();
        startMaxBuyDynamic();
        setMaxWalletValuePercentil(10);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // get start balances
        uint256 startBalanceFrom = _balances[from];
        uint256 startBalanceTo = _balances[to];
        require(startBalanceFrom >= amount, "not enough token for transfer");

        // buy
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            // trading enable
            require(tradingEnable, "trading disabled");
            // max buy limit
            if (!isAutoBanBots()) checkAndIncrementMaxBuyLimit(amount);
            trySetBot(to);
            // calculate fee
            uint256 devFee = amount / 20; // 5% to contract
            uint256 burnFee = amount / 50; // 2% burn
            // transfers
            unchecked {
                _balances[from] = startBalanceFrom - amount;
                _balances[to] = startBalanceTo + amount - devFee - burnFee;
                _balances[address(this)] += devFee;
                _balances[address(0)] += burnFee;
            }
            emit Transfer(from, to, amount);
            emit Transfer(to, address(this), devFee);
            emit Transfer(to, address(0), burnFee);
            // save buy time
            _buyTimes[to] = block.timestamp;
            // max wallet limit
            require(_balances[to] <= maxWalletValue, "max wallet limit");
            // transfer end
            return;
        }

        // sell
        if (!_inSwap && uniswapV2Pair != address(0) && to == uniswapV2Pair) {
            // trading enable
            require(tradingEnable, "trading disabled");
            // antibot
            checkBot(from);
            // get start balances
            uint256 contractBalance = _balances[address(this)];
            uint256 zeroBalance = _balances[address(0)];
            // calculate fee
            uint256 devFee = amount / 20; // 5%
            uint256 burnCount = getSellBurnCount(from, amount); // burn count
            // transfer tokens calculations
            uint256 amountTransfered = amount - devFee - burnCount;
            contractBalance += devFee;
            zeroBalance += burnCount;
            // calculate swap contract tokens count
            uint256 swapCount;
            if (contractBalance > 0) {
                // burn contract token surplus
                uint256 maxContractBalance = _balances[uniswapV2Pair] / 25; // 4% max contract balance
                if (contractBalance > maxContractBalance) {
                    uint256 contractBurnCount;
                    unchecked {
                        contractBurnCount =
                            contractBalance -
                            maxContractBalance;
                        contractBalance = maxContractBalance;
                        zeroBalance += contractBurnCount;
                    }
                    emit Transfer(address(this), address(0), contractBurnCount);
                }
                // swap contract tokens count
                swapCount = contractBalance;
                uint256 maxSwapCount = 2 * amountTransfered;
                if (swapCount > maxSwapCount) swapCount = maxSwapCount;
            }

            // swap contract tokens
            _balances[address(this)] = contractBalance;
            emit Transfer(from, address(this), devFee);
            if (swapCount > 0) swapTokensForEth(swapCount);

            // transfer tokens write
            unchecked {
                _balances[from] = startBalanceFrom - amount;
                _balances[to] = startBalanceTo + amountTransfered;
                _balances[address(0)] = zeroBalance;
            }
            emit Transfer(from, to, amount);
            emit Transfer(from, address(0), burnCount);
            return;
        }

        // transfer
        unchecked {
            _balances[from] = startBalanceFrom - amount;
            _balances[to] = startBalanceTo + amount;
        }
        emit Transfer(from, to, amount);

        // account limitations
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            uint256 burnCount = getSellBurnCount(from, amount); // burn count
            _balances[to] -= burnCount;
            _balances[address(0)] += burnCount;
            emit Transfer(to, address(0), burnCount);
            // max wallet limit
            require(_balances[to] <= maxWalletValue, "max wallet limit");
        }
    }

    function getSellBurnCount(address account, uint256 amount)
        public
        view
        returns (uint256)
    {
        // calculate fee percent
        uint256 buyTime = _buyTimes[account];
        uint256 timeEnd = buyTime + _sellDelay * 1 hours;
        if (block.timestamp >= timeEnd) return amount / 20; // 5%
        uint256 timeLeft = timeEnd - block.timestamp;
        return
            amount /
            20 +
            (amount * tax24HoursPercent * timeLeft) /
            (100 * _sellDelay * 1 hours); // 5% + delay tax
    }

    function setMaxWalletValuePercentil(uint256 percentil) public onlyOwner {
        maxWalletValue = (_totalSupply * percentil) / 1000;
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

    function setExcludeFromFee(address[] memory accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _isExcludedFromFee[accounts[i]] = value;
        }
    }

    function setTradingEnable(bool value) external onlyOwner {
        tradingEnable = value;
    }

    function setBots(address[] memory accounts, bool value) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            isBot[accounts[i]] = value;
        }
    }

    function getSupplyForMakeLiquidity() internal virtual returns (uint256);
}

// File: contracts/Withdrawable.sol

abstract contract Withdrawable {
    address internal _withdrawAddress;

    modifier onlyWithdrawer() {
        require(msg.sender == _withdrawAddress);
        _;
    }

    function withdraw() external onlyWithdrawer {
        _withdraw();
    }

    function _withdraw() internal {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    function setWithdrawAddress(address newWithdrawAddress)
        external
        onlyWithdrawer
    {
        _withdrawAddress = newWithdrawAddress;
    }
}

// File: contracts/THE_BOY_WHO_SAVED_CRYPTO.sol

pragma solidity ^0.8.7;



contract THE_BOY_WHO_SAVED_CRYPTO is TradableErc20, Withdrawable {
    constructor() TradableErc20("THE BOY WHO SAVED CRYPTO", "SMINEM") {
        _withdrawAddress = address(0xd9C17345999274A94526339C7B04B0C8900b39C0);
        setMaxBuyPercentil(2);
    }

    function getSupplyForMakeLiquidity() internal pure override returns (uint256) {
        return _totalSupply;
    }

    function withdrawByOwner() external onlyOwner{
        _withdraw();
    }
}