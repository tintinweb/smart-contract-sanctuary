pragma solidity ^0.4.25;

contract SimpleCounterContract {
    
    uint256 private counter;
    address public owner;
    address public approvedAddress;
    // Set owner variable to address
    constructor() public {
       owner = msg.sender; 
    }
    // 2) Return current value of counter variable
    function getCount() public view returns (uint256) {
        return counter;
    }
    // 3) Increment counter variable by 1 id caller is owner/approved
    function incCounter() public {
        require(msg.sender == owner || msg.sender == approvedAddress);
        counter += 1;
    }
    
    // 4) Set approvedAddress if caller is the owner
    function setApprovedAddress(address _approvedAddress) public {
        require(msg.sender == owner);
        approvedAddress = _approvedAddress;
    }
}