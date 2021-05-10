/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity >= 0.6.0;

contract Voucher {
    
    
    mapping(address=>uint256) public balances;
    
    constructor() {
        balances[msg.sender] = 100;
    }
    
    function transfer(address _to, uint256 _value) public {
        
        require(balances[msg.sender] >= _value, "Not enough funds");
        // transfer tokens from msg.sender to _to
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }
    
    
}