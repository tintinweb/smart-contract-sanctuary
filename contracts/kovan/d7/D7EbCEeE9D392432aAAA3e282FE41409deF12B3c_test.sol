/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.5.17;

contract  test {
    
    uint public a = 1;
    
    function check() public view returns(uint){
        return a;
    }
    
    function change(uint _a) public returns(bool){
        a = _a;
        return true;
    }
    
    
}