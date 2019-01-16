pragma solidity ^0.4.20;

contract PayableToken {
    mapping (address => uint256) public balanceOf;

    constructor(uint256 initialSupply) public payable {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    }

    function transfer(address _to, uint256 _value) public payable{
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
    }
}
//TODO 
/*
1.send ether to another ,and query the balance of both.
# Deploy
Env: JS VM
constructor:10000 wei.
# Test
1. call balanceOf(account addr): 10000
2. call balcanceOf(contract addr): 0
3. call transfer(contract addr,100) from account addr to contract addr:
4. call balanceOf(account addr): 9900
5. call balcanceOf(contract addr): 100

# Deploy
Env: Injected Web3
Acount: 0xa731bce24d1c8f98ce4298c2e64372084562bdc2
TestNet:Ropsten.
constructor:10000 wei.
*/