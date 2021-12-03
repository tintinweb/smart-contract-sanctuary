/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

contract ERC20 is Context, IERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 _totalSupply;
    string private _name = "CO2";
    string private _symbol= "CO2";
    mapping (address => bool) public frozenAccount;


    bool public status = true;
    modifier on() {
        require(status == true);
        _;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) on public virtual override returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[recipient]);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) on public virtual override returns (bool) {
        require(!frozenAccount[sender]);
        require(!frozenAccount[recipient]);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance.sub(amount));

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) on public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) on public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

contract CO2 is ERC20 {

    using SafeMath for uint256;
    uint8 public decimals = 18;
    event Mint(address indexed to, uint value);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address target, bool frozen);

    address public _controllerAddress = 0xaF88527b82AeBb26C8ff9CE8b90Fbf1Ac230e963;

    constructor() {
        _totalSupply = 100000000000*10**18;
        _balances[0xaF88527b82AeBb26C8ff9CE8b90Fbf1Ac230e963] = _totalSupply;
    }

    function turnon() controller public {
        status = true;
    }
    function turnoff() controller public {
        status = false;
    }

    modifier controller () {
        require(msg.sender == _controllerAddress);
        _;
    }

    function mint(address _to, uint256 _amount) on controller public returns (bool) {
        _totalSupply = _totalSupply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function burn(uint256 _value) on public returns (bool success) {
        require(_balances[msg.sender] >= _value);   // Check if the sender has enough
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function freezeAccount(address target, bool freeze)  on controller public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

}