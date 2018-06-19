pragma solidity ^0.4.0;

contract HelloWorld {
    address public owner;
    
    modifier onlyOwner() { require(msg.sender == owner); _; }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function salutaAndonio() public pure returns(bytes32 hw) {
        hw = &quot;HelloWorld&quot;;
    }
    
    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
    
}