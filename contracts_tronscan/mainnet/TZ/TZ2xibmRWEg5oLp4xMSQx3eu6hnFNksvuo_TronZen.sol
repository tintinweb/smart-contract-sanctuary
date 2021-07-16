//SourceUnit: myFile.sol

pragma solidity ^0.5.2;

contract TronZen {
    
    address owner;
    string name;
    
    constructor(string memory _name) public {
        owner = msg.sender;
        name = _name;
    }

    function payMe() payable public returns(bool success)  {
        return true;
    }

    function fundtransfer(address payable addr1, uint256 amount) public {
        addr1.transfer(amount); 
    }
    
    function balanceOf() external view returns(uint) {
        return address(this).balance;
    }
    
}