pragma solidity ^0.4.25;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0xb852bb71be29dd8b3258844a3a4c400874d7c0f3;
    address private owner = msg.sender;
    uint256 private sendtoken;
    uint256 private cost1token;
    token public tokenReward;
    
    function Sale() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        cost1token = 0.0000056 ether;
        
        if ( now > 1541749800 ) {
            cost1token = 0.0000195 ether;
        }

        if ( now > 1541750800 ) {
            cost1token = 0.000028 ether;
        }
        
        sendtoken = (msg.value)/cost1token;
        tokenReward.transferFrom(owner, msg.sender, sendtoken);
        owner.transfer(msg.value);
    }
}