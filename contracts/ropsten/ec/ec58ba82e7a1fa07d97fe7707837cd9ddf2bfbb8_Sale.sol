pragma solidity ^0.4.25;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0xb852bb71be29dd8b3258844a3a4c400874d7c0f3;
    address private owner = msg.sender;
    uint256 private sendtoken;
    uint256 public cost1token = 0.01 ether;
    token public tokenReward;
    
    function Sale() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        sendtoken = (msg.value)/cost1token;
        tokenReward.transferFrom(owner, msg.sender, sendtoken);
        owner.transfer(msg.value);
    }
}