pragma solidity ^0.4.25;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Partner {
    address private maintoken = 0xb852bb71be29dd8b3258844a3a4c400874d7c0f3;
    address private owner = 0x26b6f285692fb87d17622b3b14de32dacccbc50e;
    address private partner = 0xaed486df1ac13972c2e428921d938f94defd7974;
    uint256 private sendtoken;
    uint256 public cost1token = 0.01 ether;
    uint256 private ether60;
    uint256 private ether40;
    token public tokenReward;
    
    function Partner() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        sendtoken = (msg.value)/cost1token;
        tokenReward.transferFrom(owner, msg.sender, sendtoken);
        
        ether40 = (msg.value)*4/10;
        ether60 = (msg.value)-ether40;
        owner.transfer(ether60);
        partner.transfer(ether40);
    }
}