pragma solidity ^0.4.24;

// Name your new coin. Make sure the constructor has the same name.
contract Splitter {
    // two hardware addresses
    address Alice = 0x59bbe76dcc000894fce82b133d710e373c3fa84f;
    address Bob = 0x50d3974136a65de20f7fb9b7a4102a816dc75d94;
    
    function splitEther()
    external // to only be called by other functions
    payable // enabling function to accept ether with function call
    {
        uint value = msg.value; // keyphrase that equals the amount of ether sent with the function call
        
        Alice.transfer(value/2);
        Bob.transfer(value/2);
    }
}