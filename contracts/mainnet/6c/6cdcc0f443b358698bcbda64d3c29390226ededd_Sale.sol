pragma solidity ^0.4.24;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0x2054a15c6822a722378d13c4e4ea85365e46e50b;
    address private owner = msg.sender;
    address private owner10 = 0x966c0FD16a4f4292E6E0372e04fbB5c7013AD02e;
    uint256 private sendtoken;
    uint256 public cost1token = 0.00014 ether;
    uint256 private ether90;
    uint256 private ether10;
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
        
        ether10 = (msg.value)/10;
        ether90 = (msg.value)-ether10;
        owner.transfer(ether90);
        owner10.transfer(ether10);
    }
}