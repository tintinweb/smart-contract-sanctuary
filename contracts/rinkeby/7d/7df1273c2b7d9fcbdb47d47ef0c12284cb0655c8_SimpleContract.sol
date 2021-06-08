/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SimpleContract.sol
pragma solidity ^0.4.18;
contract SimpleContract {
    uint age;
    
    function constuctor() public {
        
    }
    
     function getAge() public constant returns (uint) {
        return age;
    }
    
    function setAge (uint newAge) public {
        age = newAge;
    }
}