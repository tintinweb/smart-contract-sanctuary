/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.8.3;

abstract contract ERC20TOKEN {
    function name() virtual public view returns (string memory);

    function symbol() virtual public view returns (string memory);

    function decimals() virtual public view returns (uint8);
   
    function totalSupply() virtual public view returns (uint);

    function balanceOf(address account) virtual public view returns (uint);

    function transfer(address recipient, uint amount) virtual public returns (bool);

    function allowance(address owner, address sender) virtual public view returns (uint);

    function approve(address sender, uint amount) virtual public returns (bool);

    function transferFrom(address sender,address recipient,uint amount) virtual public returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract MyToken is ERC20TOKEN, Owned {
    
    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint256)) private allowances;

    constructor () {
        _symbol = "NOVY2";
        _name = "NOVYTOKEN2";
        _decimal = 5;
        _totalSupply = (1000000 * 5**uint(decimals()));
        _minter = 0xB292724Cc9d3939A240507E995e507BA8E28674d;
        
        balances[msg.sender] = 1000000;
        emit Transfer(address(0), _minter, _totalSupply);
    }
    
    function name() virtual public view override returns (string memory) {
        return _name;
    }

    function symbol() virtual public view override  returns (string memory) {
        return _symbol;
    }

    function decimals() virtual public view override returns (uint8) {
        return 5;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (balances[msg.sender] >= amount && amount > 0) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
            return true;
        } else { return false; }
    }
    
    function allowance(address owner, address spender) virtual public view override returns (uint) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    if (balances[sender] >= amount && allowances[owner][msg.sender] >= amount && amount > 0) {
            balances[recipient] += amount;
            balances[sender] -= amount;
            allowances[recipient][msg.sender] -= amount;
            emit Transfer(sender, recipient, amount);
            return true;
        } else { return false; }
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(owner, spender, allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

}