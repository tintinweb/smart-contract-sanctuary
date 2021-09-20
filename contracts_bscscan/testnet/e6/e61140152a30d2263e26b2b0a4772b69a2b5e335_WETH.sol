/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

pragma solidity ^0.6.6;

contract WETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed from, address indexed user, uint amount);
    event Transfer(address indexed from, address indexed dst, uint amount);
    event Deposit(address indexed dst, uint amount);
    event Withdrawal(address indexed from, uint amount);

    mapping (address => uint ) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    receive() external payable { 
        deposit();
    }
    function  deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);

    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address user, uint amount ) public returns (bool) {
        allowance[msg.sender][user] = amount;
        Approval(msg.sender, user, amount);
        return true;
    }
    function transfer(address dst, uint amount ) public returns (bool) {
        return transferFrom(msg.sender, dst, amount);

    }

    function transferFrom(address from, address dst, uint amount)
    public
    returns (bool)
    {
        require(balanceOf[from] >= amount);

        if (from != msg.sender && allowance[from][msg.sender] != uint(-1)) {
            require(allowance[from][msg.sender] >= amount);
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(from, dst, amount);

        return true;
    }
}