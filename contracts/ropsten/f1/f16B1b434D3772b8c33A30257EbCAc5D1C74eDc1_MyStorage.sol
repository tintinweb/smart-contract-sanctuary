/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

pragma solidity >=0.5.0;

contract MyStorage {
    uint birthday;
    
    function set(uint birth) public {
        birthday = birth;
    }
    
    function get() public view returns (uint) {
        return birthday;
    }
}