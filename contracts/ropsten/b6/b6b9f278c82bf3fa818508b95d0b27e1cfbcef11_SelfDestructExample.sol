pragma solidity ^0.4.24;

contract SelfDestructExample {
    function() public payable {}
    
    function sendEthToContract(address _contract) public {
        selfdestruct(_contract);
    }
}