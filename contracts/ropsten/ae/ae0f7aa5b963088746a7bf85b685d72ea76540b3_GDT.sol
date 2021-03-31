/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.4.21;

contract GDT {
    mapping (address => uint256) public _balances;

    string public _name = "GDT";
    string public _symbol = "GDT";
    uint8 public _decimals = 8;
    
    address _INITIAL_ADDRESS = 0x23A26573944FfC2922f4d886a6C63eEFc444d219;

    uint256 public _totalSupply = 400000000 * (uint256(10) ** 8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        _balances[_INITIAL_ADDRESS] = _totalSupply;
        emit Transfer(address(0), _INITIAL_ADDRESS, _totalSupply);
    }
    
    function name() public view returns (string) {
        return _name;
    }
    
    function symbol() public view returns (string)  {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    function allowance(address owner, address spender) public view returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[msg.sender] >= value, "ERC20: insufficient balance for transfer");
        _balances[msg.sender] -= value;  // deduct from sender's balance
        _balances[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public _allowed;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(to != address(0), "ERC20: transferFrom to the zero address");
        require(value <= _balances[from], "ERC20: insufficient balance for transferFrom");
        require(value <= _allowed[from][msg.sender], "ERC20: unauthorized transferFrom");
        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 amount)
        public
        returns (bool success)
    {
        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[msg.sender] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        approve(spender, _allowed[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowed[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        approve(spender, currentAllowance - subtractedValue);
        return true;
    }
}