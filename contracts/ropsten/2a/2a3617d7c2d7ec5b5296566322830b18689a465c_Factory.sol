pragma solidity ^0.4.24;
contract Factory {
    
    address[] private contracts;
    uint256 public numbeOfCotnracts;
    
    constructor() public {
        numbeOfCotnracts = 0;
    }
    
    function createA() public returns (address) {
        Abstract aContract = new A(msg.sender);
        address _contractAddress = aContract.getAddress();
        contracts.push(_contractAddress);
        return _contractAddress;
    }
    
    function createB() public returns (address) {
        Abstract aContract = new B(msg.sender);
        address _contractAddress = aContract.getAddress();
        contracts.push(_contractAddress);
        return _contractAddress;
    }
    
    function getContract(uint256 index) public view returns (address) {
        return contracts[index];
    }
}

contract Abstract {
    function getOwner() public view returns (address){}
    function getAddress() constant public returns (address)  {
        return address(this);
    }
}

contract A is Abstract {
    
    address private owner;
    
    constructor(address creator) public {
        owner = creator;
    }
    
    function getOwner() public view returns (address){
        return owner;
    }
}

contract B is Abstract {
    
    address private owner;
    
    constructor(address creator) public {
        owner = creator;
    }
    
    function getOwner() public view returns (address){
        return owner;
    }
}