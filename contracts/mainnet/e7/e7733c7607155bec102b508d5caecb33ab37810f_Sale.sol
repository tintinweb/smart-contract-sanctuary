pragma solidity ^0.4.24;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract Sale {
    address private maintoken = 0x2054a15c6822a722378d13c4e4ea85365e46e50b;
    address private owner = 0xabc45921642cbe058555361490f49b6321ed6989;
    address private owner8 = 0x01139e28b2a050e0E6Bdb3b86cd022DF86229493;
    address private owner6 = 0x966c0FD16a4f4292E6E0372e04fbB5c7013AD02e;                uint256 private sendtoken;
    uint256 public cost1token = 0.0004 ether;
    uint256 private ethersum;
    uint256 private ethersum8;
    uint256 private ethersum6;                token public tokenReward;
    
    function Sale() public {
        tokenReward = token(maintoken);
    }
    
    function() external payable {
        sendtoken = (msg.value)/cost1token;
        if (msg.value >= 5 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*125/100;
        }
        if (msg.value >= 10 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*150/100;
        }
        if (msg.value >= 15 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*175/100;
        }
        if (msg.value >= 20 ether) {
            sendtoken = (msg.value)/cost1token;
            sendtoken = sendtoken*200/100;
        }
        tokenReward.transferFrom(owner, msg.sender, sendtoken);
        
        ethersum8 = (msg.value)*8/100;
        ethersum6 = (msg.value)*6/100;    	    	    	    	
    	    	ethersum = (msg.value)-ethersum8-ethersum6;    	    	    	        
        owner8.transfer(ethersum8);
        owner6.transfer(ethersum6);    	    	    	        owner.transfer(ethersum);
    }
}