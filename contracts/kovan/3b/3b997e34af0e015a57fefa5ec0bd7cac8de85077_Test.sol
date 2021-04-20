/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity 0.7.0;

contract Test {
    
    uint256 value;
    
    event ChangeValue(uint256 oldValue, uint256 newValue);
    
    function foo(uint256 amount) public returns(uint256) {
        emit ChangeValue(value, amount);
        value = amount;
    }
}