pragma solidity ^0.6.0;

contract Count {
    
    address public admin;
    uint public count = 1;
    
    constructor() public {
        admin = msg.sender;
    }

    function increment() public {
        count +=1;
    }

}