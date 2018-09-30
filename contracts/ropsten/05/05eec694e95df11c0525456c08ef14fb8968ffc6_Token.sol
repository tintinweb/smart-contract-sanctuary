pragma solidity ^0.4.21;

contract Token {
    
    mapping (address => uint256) balance;
    
    constructor() public {
        // set balance of creator to 100000
        balance[msg.sender] = 100000;
    }
    
    
    function sendTo(address _to, uint256 _amount) public {
        // check balance of sender
        require(balance[msg.sender] >= _amount);
        
        // update balances
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }
    
    
    function balanceOf(address _who) public view returns (uint256) {
        return balance[_who];
    }
    
    
}