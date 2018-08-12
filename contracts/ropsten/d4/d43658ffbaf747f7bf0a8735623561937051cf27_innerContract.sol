pragma solidity ^0.4.18;

contract innerContract{
    address public owner;
    event contractDeployed(address);
    function innerContract() public {
        owner = msg.sender;
        emit contractDeployed(msg.sender);
    }
    function whatsMyName() public pure returns(string){
        return "Inner Contract";
    }
}

contract OuterContract {
    innerContract public deploy1;
    event contractDeployed(address);
    function OuterContract() public{
        deploy1 = new innerContract();
        emit contractDeployed(msg.sender);
    }
    function whatsMyName() public pure returns(string){
        return "Outer Contract";
    }
}