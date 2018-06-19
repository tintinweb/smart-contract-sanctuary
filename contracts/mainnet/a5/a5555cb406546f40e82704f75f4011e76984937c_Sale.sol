pragma solidity ^0.4.21;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0x2f7823aaf1ad1df0d5716e8f18e1764579f4abe6;
    address private owner90 = 0xf2b9DA535e8B8eF8aab29956823df7237f1863A3;
    address private owner10 = 0x966c0FD16a4f4292E6E0372e04fbB5c7013AD02e;
    uint256 private sendtoken;
    uint256 public cost1token = 0.00379 ether;
    uint256 private ether90;
    uint256 private ether10;
    token public tokenReward;
    
    function Sale() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        sendtoken = (msg.value)/cost1token;
        tokenReward.transferFrom(owner90, msg.sender, sendtoken);
        
        ether10 = (msg.value)/10;
        ether90 = (msg.value)-ether10;
        owner90.transfer(ether90);
        owner10.transfer(ether10);
    }
}