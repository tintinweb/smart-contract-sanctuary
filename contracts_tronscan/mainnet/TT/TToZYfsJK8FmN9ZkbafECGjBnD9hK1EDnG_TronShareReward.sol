//SourceUnit: TronShareReward.sol

pragma solidity ^0.4.13;

interface TronShare {
    function allShare(uint ShareID, uint ReplyID) returns (address,string,uint,bool,string);
}

// Enable users to reward authors from TronShare and record the reward
contract TronShareReward {
    uint256 tronAddress = 0x412edc0a1db7fcb3b2647e2565b2eaaa82eb702cf1;

    TronShare TS = TronShare(address(tronAddress));
    
    struct oneReward {
        address from;
        uint value;
    }
    mapping(uint => mapping(uint => oneReward[])) public allRewards;
    
    function Reward(uint ShareID, uint ReplyID) payable public {
        address to;
        (to,,,,) = TS.allShare(ShareID,ReplyID); // get the author
        to.transfer(msg.value);
        allRewards[ShareID][ReplyID].push(oneReward(msg.sender, msg.value)); // record the reward
    }

    function getSum(uint ShareID, uint ReplyID) view public returns (uint) {
        uint sum = 0;
        for (uint i=0; i<allRewards[ShareID][ReplyID].length; ++i)
            sum += allRewards[ShareID][ReplyID][i].value;
        return sum;
    }
}