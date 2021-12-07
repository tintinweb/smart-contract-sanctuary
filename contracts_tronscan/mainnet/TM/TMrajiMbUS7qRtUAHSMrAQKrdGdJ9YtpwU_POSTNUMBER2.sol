//SourceUnit: POSTNUMBER2.sol

// Specify version of solidity file (https://solidity.readthedocs.io/en/v0.4.24/layout-of-source-files.html#version-pragma)
pragma solidity ^0.5.17;// ^0.4.0;

contract POSTNUMBER2 {
    // Define variable number of type uint8
    uint8 numberUint8;

    // Write function to change the value of variable number
    function postNumberUint8(uint8 value) public returns (uint8) {
        numberUint8 = value;
        return numberUint8;
    }
    
    // Read function to fetch variable number
    function getNumberUint8() public view returns (uint8){
        return numberUint8;
    }
}