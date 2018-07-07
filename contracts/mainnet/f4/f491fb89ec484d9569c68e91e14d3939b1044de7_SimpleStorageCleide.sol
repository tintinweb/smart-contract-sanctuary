//Tell the Solidity compiler what version to use
pragma solidity ^0.4.8;

//Declares a new contract
contract SimpleStorageCleide {
    //Storage. Persists in between transactions
    uint price;

    //Allows the unsigned integer stored to be changed
    function setCleide (uint newValue) 
    public
    {
        price = newValue;
    }
    
    //Returns the currently stored unsigned integer
    function getCleide() 
    public 
    view
    returns (uint) 
    {
        return price;
    }
}