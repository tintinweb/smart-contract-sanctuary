pragma solidity ^0.8.0;

import "IERC20.sol";

contract dummyFaucet{
    
    IERC20 dummy;
    
    constructor (address theDummy){
        dummy= IERC20 (theDummy);
    }
    
    function getDummy() external{
        dummy.transfer(msg.sender,100000000000000000000);
    }
    
}