pragma solidity 0.4.24; contract DebugAuthorizer{
    
    bool public debugMode;

    constructor() public payable{
        if(address(this).balance == 1.337 ether){
            debugMode=true;
        }
    }
}