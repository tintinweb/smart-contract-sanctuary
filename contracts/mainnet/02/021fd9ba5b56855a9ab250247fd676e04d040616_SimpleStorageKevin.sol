//Tell the Solidity compiler what version to use
pragma solidity ^0.4.8;

//Declares a new contract
contract SimpleStorageKevin {
    
    //Storage. Persists in between transactions
    uint x = 316;

    //Allows the unsigned integer stored to be changed
    function setKevin(uint newValue)
        public
    {
        x = newValue;
    }
    
    //Returns the currently stored unsigned integer
    function getKevin()
        public
        view
        returns (uint) 
    {
        return x;
    }
}