/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

//SPDX-License-Identifier: None
pragma solidity =0.8.1;

contract WFLR {
    string public constant name = "Wrapped Flare";
    string public constant symbol = "WFLR";
    uint8  public constant decimals = 18;

    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Deposit(address indexed from, address indexed to, uint amount);
    event Withdrawal(address indexed from, address indexed to, uint amount);

    mapping(address => uint) public  balanceOf;
    mapping(address => mapping (address => uint)) public allowance;

    receive() external payable {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.sender, msg.value);
    }

    function depositTo(address to) public payable {
        balanceOf[to] += msg.value;
        emit Deposit(msg.sender, to, msg.value);
    }

    function withdraw(uint amount) external {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, msg.sender, amount);
    }

    function withdrawTo(uint amount, address to) external {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        payable(to).transfer(amount);
        emit Withdrawal(msg.sender, to, amount);
    }

    function totalSupply() external view returns (uint) {
        return address(this).balance;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(balanceOf[from] >= amount);

        if (from != msg.sender && allowance[from][msg.sender] != type(uint).max) {
            require(allowance[from][msg.sender] >= amount);
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }
}