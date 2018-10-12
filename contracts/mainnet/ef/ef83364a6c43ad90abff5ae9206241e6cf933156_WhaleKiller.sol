pragma solidity ^0.4.24;

contract WhaleKiller {
    address WhaleAddr;
    uint constant interest = 5;
    uint constant whalefee = 1;
    uint constant maxRoi = 150;
    uint256 amount = 0;
    mapping (address => uint256) invested;
    mapping (address => uint256) timeInvest;
    mapping (address => uint256) rewards;

    constructor() public {
        WhaleAddr = msg.sender;
    }
    function () external payable {
        address sender = msg.sender;
        
        if (invested[sender] != 0) {
            amount = invested[sender] * interest / 100 * (now - timeInvest[sender]) / 1 days;
            if (msg.value == 0) {
                if (amount >= address(this).balance) {
                    amount = (address(this).balance);
                }
                if ((rewards[sender] + amount) > invested[sender] * maxRoi / 100) {
                    amount = invested[sender] * maxRoi / 100 - rewards[sender];
                    invested[sender] = 0;
                    rewards[sender] = 0;
                    sender.send(amount);
                    return;
                } else {
                    sender.send(amount);
                    rewards[sender] += amount;
                    amount = 0;
                }
            }
        }
        timeInvest[sender] = now;
        invested[sender] += (msg.value + amount);
        
        if (msg.value != 0) {
            WhaleAddr.send(msg.value * whalefee / 100);
            if (invested[sender] > invested[WhaleAddr]) {
                WhaleAddr = sender;
            }  
        }
    }
    function showDeposit(address _dep) public view returns(uint256) {
        return (invested[_dep] / 10**18);
    }
    function showRewards(address _rew) public view returns(uint256) {
        return (rewards[_rew] / 10**18);
    }
    function showWhaleAddr() public view returns(address) {
        return WhaleAddr;
    }
}