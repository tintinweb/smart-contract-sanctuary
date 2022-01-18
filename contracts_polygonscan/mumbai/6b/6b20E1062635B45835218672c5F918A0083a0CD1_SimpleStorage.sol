/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

//Tell the Solidity compiler what version to use
pragma solidity ^0.8.0;

//Declares a new contract
contract SimpleStorage {
    //Storage. Persists in between transactions
    uint x;

    //Allows the unsigned integer stored to be changed
    function set(uint newValue) external {
        x = newValue;
    }

    //Returns the currently stored unsigned integer
    function get() external view returns (uint) {
        return x;
    }
}