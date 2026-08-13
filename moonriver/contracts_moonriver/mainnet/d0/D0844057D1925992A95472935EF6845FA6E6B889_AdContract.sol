/**
 *Submitted for verification at moonriver.moonscan.io on 2022-04-19
*/

pragma solidity 0.8.13;

contract AdContract {
    mapping(address => uint) public adLABEL;
    mapping(address => uint) public adLINK;
    mapping(address => uint) public adVALUE;
    mapping(address => uint) public adSTAMP;
    bool internal locked;

    function addAD(address toADD, uint adLABELv, uint adLINKv) external payable {
        require(!locked, "No re-entrancy");
        locked = true;
        require(msg.value >= tx.gasprice);
        uint ctr;
        //2678400 seconds = 31 days, 2592000 = 30 days, 2505600 = 29 days, 86400 = 1 day
        if (block.timestamp < (adSTAMP[toADD] + 2592000)) {
        	ctr = (adVALUE[toADD] * (2678400 - (block.timestamp - adSTAMP[toADD]))) / 86400;
        	} else {
        	ctr = (adVALUE[toADD] * 86400) / ((block.timestamp - adSTAMP[toADD]) - 2505600);
        }
        require(msg.value > ctr);
        require(block.timestamp > (adSTAMP[toADD] + 86400)); //lock, 86400 seconds = 1 day
        adVALUE[toADD] = msg.value;
        adLINK[toADD] = adLINKv;
        adLABEL[toADD] = adLABELv;
        adSTAMP[toADD] = block.timestamp;
        (bool sent, ) = toADD.call{value: (msg.value - (msg.value / 100))}("");
        require(sent, "Failed to send Ether");
        locked = false;
    }

    function operTAKE(uint operTAKEv) public {
        require(msg.sender == 0x0661eE3542CfffBBEFCA7F83cfaD2E9D006d61a2);
        (bool sent, ) = msg.sender.call{value: operTAKEv}("");
        require(sent, "Failed to send Ether");
    }

}