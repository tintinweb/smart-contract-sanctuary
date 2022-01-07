/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity ^0.8.1; 
 
contract Inheritance { 
      
    address private owner; 
    address private heir; 
    uint256 private lastProofOfLiveTimestamp; 
     
     
    modifier onlyOwner() { 
        require(msg.sender == owner, "Only the owner of the smart contract can call this function"); 
        _; 
    } 

    modifier onlyHeir() { 
        require(msg.sender == heir, "Only an heir can call this function"); 
        _; 
    } 

    // Accept any incoming amount
    receive() external payable {}
     
    constructor(address newHeir) {  
        owner = msg.sender; 
        lastProofOfLiveTimestamp = block.timestamp;
        heir = newHeir;  
    } 

    function getOwner() public view returns (address) {
        return owner;
    }
    function getHeir() public view returns (address) {
        return heir;
    }
    function getLastProofOfLiveTimestamp() public view returns (uint256) {
        return lastProofOfLiveTimestamp;
    }
     
    function setHeir(address newHeir) external payable onlyOwner { 
        heir = newHeir; 
    } 

    function withdraw(uint withdrawAmount) external onlyOwner {
        // Send the amount to the address that requested it
        payable(msg.sender).transfer(withdrawAmount);
        lastProofOfLiveTimestamp = block.timestamp; 
    }
     
    function claimControlContract(address _newHeir) external onlyHeir { 
        //Check 1 month after last withdraw of the owner 
        require(block.timestamp > (lastProofOfLiveTimestamp + 30 days), "Unable to call this function if Owner is alive"); 
        owner = msg.sender;
        lastProofOfLiveTimestamp = block.timestamp; 
        heir = _newHeir;
    } 
}