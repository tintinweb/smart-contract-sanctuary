/**
 *Submitted for verification at Etherscan.io on 2020-08-30
*/

pragma solidity ^0.6.7;


contract Owned {
    address payable _owner;
    address payable _newOwner;

    modifier onlyOwner() {
        require(msg.sender==_owner);
        _;
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        require(newOwner!=address(0));
        _newOwner = newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender==_newOwner);

        if (msg.sender==_newOwner) {
            _owner = _newOwner;
        }
    }
}

abstract contract ERC20 {
    function totalSupply() view public virtual returns (uint);
    function balanceOf(address owner) view public virtual returns (uint256 balance);
    function transfer(address to, uint256 value) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool success);
    function approve(address spender, uint256 value) public virtual returns (bool success);
    function allowance(address owner, address spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Token is Owned, ERC20 {
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint public _totalSupply;

    mapping (address=>uint256) _balances;
    mapping (address=>mapping (address=>uint256)) _allowed;
    mapping (address=>bool) _minters;

    function balanceOf(address owner) view public virtual override returns (uint256 balance) {return _balances[owner];}

    function transfer(address to, uint256 amount) public virtual override returns (bool success) {
        require (_balances[msg.sender]>=amount && amount>0);
        _balances[msg.sender]-=amount;
        _balances[to]+=amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }

    function transferFrom(address from,address to,uint256 amount) public virtual override returns (bool success) {
        require (_balances[from]>=amount && _allowed[from][msg.sender]>=amount && amount>0);
        _balances[from]-=amount;
        _allowed[from][msg.sender]-=amount;
        _balances[to]+=amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool success) {
        _allowed[msg.sender][spender]=amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) view public virtual override returns (uint256 remaining) {
        return _allowed[owner][spender];
    }

    function totalSupply() view public virtual override returns (uint) {
        return _totalSupply;
    }
    
    modifier onlyMinter() {
        require(_minters[msg.sender]==true);
        _;
    } 
    
    function addMinter(address minter) public onlyOwner {
        require(minter != address(0), "ERC20: zero address");
        
        _minters[minter] = true;
    }
    
    function removeMinter(address minter) public onlyOwner {
        require(minter != address(0), "ERC20: zero address");
        
        _minters[minter] = false;
    }

    function mint(address account, uint amount) public onlyMinter {
        require(account != address(0), "ERC20: mint from the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint amount) public onlyMinter {
        require(account != address(0), "ERC20: burn to the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

contract YFFAToken is Token{
    constructor() public{
        _symbol = "YFFA";
        _name = "Yearn Alpha Finance";
        _decimals = 18;
        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        addMinter(_owner);
    }

    receive () payable external {
        require(msg.value>0);
        _owner.transfer(msg.value);
    }
}