pragma solidity ^0.4.24;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0x2054a15c6822a722378d13c4e4ea85365e46e50b;
    address private owner = msg.sender;
    address private owner8 = 0x98b3540c7d95950f44ed9774f6caf04bf76c368f;
    address private owner6 = 0x4e76f947fA07B655F5e3e2cDD645E590C5D0875e;
    uint256 private sendtoken;
    uint256 public cost1token = 0.00042 ether;
    uint256 private ether86;
    uint256 private ether8;
    uint256 private ether6;
    token public tokenReward;
    
    function Sale() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        sendtoken = (msg.value)/cost1token;
        if (msg.value >= 5 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*3/2;
        }
        if (msg.value >= 15 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*2;
        }
        if (msg.value >= 25 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*3;
        }
        tokenReward.transferFrom(owner, msg.sender, sendtoken);
        
        ether8 = (msg.value)*8/100;
        ether6 = (msg.value)*6/100;
        ether86 = (msg.value)-ether8-ether6;
        owner8.transfer(ether8);
        owner6.transfer(ether6);
        owner.transfer(ether86);
    }
}