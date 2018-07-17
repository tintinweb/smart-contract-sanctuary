pragma solidity ^0.4.7.;

contract stateless {
    
    ///@dev needed to make contract pay out
    constructor() public payable{}
    
    ///@dev needed to fund the contract
    function() public payable {
    // nothing to do
    }
    
    function report(uint16 _deviceId, uint16 uptime, uint8 month) public {
        //stateless we will use the transaction input
    }
    
    function withdrawFunds(uint16 _deviceId) external payable {
        msg.sender.transfer(0.01 ether);///@dev improve with payout logic
    }
    
    function showContractBalance() external view returns(uint) {
        return address(this).balance;
    }
    
    function addFunds() public payable {
        address(this).transfer(msg.value);
    }
    
}