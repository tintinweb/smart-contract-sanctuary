pragma solidity ^0.4.20;

contract TestContractForDeploy {
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function funcWithoutArguments() public pure returns(bool){
        return true;
    }
    
    function funcThatReverts() public pure {
        revert();
    }
    
    function increaseNumber(uint256 x) public pure returns(uint256) {
        return x+1;
    }
    
    function () public payable {
    }
    
    function withdrawEther() public {
        require(owner == msg.sender);
        owner.transfer(address(this).balance);
    }
    
    function iWantToKillMyself() public {
        require(owner == msg.sender);
        selfdestruct(owner);
    }
    
}