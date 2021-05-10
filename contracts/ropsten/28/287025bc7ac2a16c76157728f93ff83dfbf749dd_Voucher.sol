/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity >= 0.6.0;

contract Voucher {
    
    //mapping addresses of users (keys to integers)
    mapping(address=>uint256) public balances;
    
    // Voucher creation balances
    constructor() public {
        balances[msg.sender] = 100; //creator
    }
    
    
    function transfer(address _to, uint256 _value) public {
        
        
        //to avoid negative balances
        require(balances[msg.sender]>= _value, "Not enough funds");
        
        //transfer tokens from msg.sender to _to
        //same as python dictionary
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    
    //function to access users' balances
    //function getBalance(address _who) public {
    //    return balances[_who];
    //}
    
    
}