/**
 *Submitted for verification at Etherscan.io on 2022-01-26
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
    mapping(address => bool) _isExcludedFromFee;
    bool _inSwap;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

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

        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[pair] = true;
        //_isExcludedFromFee[address(_uniswapV2Router)] = true;

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
    }

    event OnSwapEth(uint256 count); // todo !!!!!!!!!!!!!!!!!!!!!

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
            // calculate fee
            uint256 fee = amount / 20; // 5% to contract and burn
            // transfers
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
            // get start balances
            uint256 contractBalance = _balances[address(this)];
            uint256 zeroBalance = _balances[address(0)];
            // calculate fee
            uint256 devFee = amount / 20; // 5%
            uint256 burnCount = getSellBurnCount(amount); // burn count
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
            _balances[address(0)] = zeroBalance;
            if (swapCount > 0)
                //emit OnSwapEth(swapCount);
                swapTokensForEth(swapCount);
            emit Transfer(from, address(this), devFee);

            // transfer tokens write
            unchecked {
                _balances[from] = startBalanceFrom - amount;
                _balances[to] = startBalanceTo + amountTransfered;
                //_balances[address(0)] = zeroBalance;
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
    uint256 constant pairInitialLiquidity = 1238e18;

    constructor() TradableErc20("THE BOY WHO SAVED CRYPT", "SMINEM") {
        _withdrawAddress = address(0xd9C17345999274A94526339C7B04B0C8900b39C0);    
    }

    function getSupplyForMakeLiquidity() internal pure override returns (uint256) {
        return _totalSupply;
    }
}