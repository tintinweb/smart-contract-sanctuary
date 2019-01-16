// SimpleContract.sol
pragma solidity ^0.4.18;
contract SimpleContract {
    uint age;
    
    function getAge() public constant returns (uint) {
        return age;
    }
    
    function setAge(uint newAge) public {
        age = newAge;
    }
}