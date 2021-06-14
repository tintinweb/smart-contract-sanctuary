/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.24;
contract class21{

    
    // array
    uint[12] public monthlyBalance;
    
    
    // mapping
    mapping(address=>uint) public customerBalance;
    
    //struct
    struct building{
        string ownerName;
        string color;
        uint squarFeet;
    }
    
    // combination
    mapping(address=>building) public asset;
    
    
    constructor() public{
        // array looping
        for(uint i=0; i<12;i++){
            monthlyBalance[i] = 100*i;
        }
        
        // mapping init
        customerBalance[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 50;
        customerBalance[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = 100;
        
        // struct
        asset[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = building("Andrew", "Yellow", 8);
        asset[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = building("Bob", "Blue", 20);
        
    }
    
    
}