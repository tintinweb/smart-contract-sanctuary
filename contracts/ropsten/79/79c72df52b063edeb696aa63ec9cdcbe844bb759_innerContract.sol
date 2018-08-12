pragma solidity ^0.4.18;

contract innerContract{
    address public owner;
    event contractDeployed(address);
    
    string private __message;
    
    function innerContract(string _message) public {
        owner = msg.sender;
        
        __message = _message;
        
        emit contractDeployed(msg.sender);
    }
    function whatsMyName() public view returns(string){
        return __message;
    }
}

contract OuterContract {
    innerContract public deploy1;
    event contractDeployed(address);
    function OuterContract() public{
        deploy1 = new innerContract("inner contract test");
        emit contractDeployed(msg.sender);
    }
    function whatsMyName() public pure returns(string){
        return "Outer Contract";
    }
}