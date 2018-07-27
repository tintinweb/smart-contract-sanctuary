/*
   bancor buy contract
*/

pragma solidity ^0.4.0;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BancorBuy {

    string public returnData;
    address public owner;

	event Deposit(address indexed from, uint value);

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    function BancorBuy() {
        owner = msg.sender;
    }

    function() payable {
        Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) onlyOwner returns(bool) {
        require(amount <= this.balance);
        owner.transfer(amount);
        return true;
    }

    function withdrawToken(address tokenAddress) onlyOwner returns(bool) {
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint amount = token.balanceOf(this);
        token.transfer(owner, amount);
        return true;
    }

    function getTokenBalance(address tokenAddress) constant returns(uint) {
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint amount = token.balanceOf(this);
        return amount;
    }

    function getBalanceContract() constant returns(uint){
        return this.balance;
    }

}