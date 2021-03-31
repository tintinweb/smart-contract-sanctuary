/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.4.21;

contract GDT {
    mapping (address => uint256) public balanceOf;

    string public name = "GDT";
    string public symbol = "GDT";
    uint8 public decimals = 8;
    
    address INITIAL_ADDRESS = 0x23A26573944FfC2922f4d886a6C63eEFc444d219;

    uint256 public totalSupply = 400000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        balanceOf[INITIAL_ADDRESS] = totalSupply;
        emit Transfer(address(0), INITIAL_ADDRESS, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[msg.sender] >= value, "ERC20: insufficient balance for transfer");
        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(to != address(0), "ERC20: transferFrom to the zero address");
        require(value <= balanceOf[from], "ERC20: insufficient balance for transferFrom");
        require(value <= allowance[from][msg.sender], "ERC20: unauthorized transferFrom");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 amount)
        public
        returns (bool success)
    {
        uint256 accountBalance = balanceOf[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[msg.sender] = accountBalance - amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        approve(spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        approve(spender, currentAllowance - subtractedValue);
        return true;
    }
}