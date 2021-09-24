/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

pragma solidity ^0.7.0;
contract bank {
    uint public total = 0;
    mapping(address => uint) public balances;
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
         total += msg.value;
    }
    
    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount , "Out of amount");
        
        (bool sent, ) = msg.sender.call{value: _amount}("");
        
        require(sent, "Failed to send Ether");
        
        balances[msg.sender] -= _amount;
        total -= _amount;
        
    }
    
    function getBalance(address user) public view returns(uint) {
        return balances[user];
    }
    
    function failsafe() public {
          (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        
        require(sent, "Failed to send Ether");
    }
    
}