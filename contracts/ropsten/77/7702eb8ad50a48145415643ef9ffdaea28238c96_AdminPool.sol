/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract AdminPool {

    uint count;
    address public admin;
    uint public adminContribution;
    uint constant day1 = 86400;
    uint constant day2 = 172800;
    uint constant day3 = 259200;

    enum POOL_STATE {
        OPEN, CLOSED
    }

    mapping (uint => User) public user;
    struct User {
        address user;
        uint score;
        bool isClaimed;
    }

    mapping (uint => Pool) public pools;
    struct Pool {
        User user;
        uint pool_id;
        uint totalScore;
        POOL_STATE poolState;
        uint createTime;
    }

    constructor() {
        admin = msg.sender;
    }

    receive () payable external {
        //require(poolState == POOL_STATE.OPEN);
    }

    function adminWithdraw() public {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(getBalance());
    }

    function startPool(uint pool_id) public payable {
        require(msg.sender == admin, "Only admin can start the pool");
        require(msg.value > 0, "Please contribute desired amount to start pool");
        bool isFound = false;
        for(uint i = 0; i < count; i++) {
            if (pools[i].pool_id == pool_id) {
                isFound = true;
            }
        }
        if (!isFound) {
            adminContribution += msg.value;
            pools[count].pool_id = pool_id;
            pools[count].poolState = POOL_STATE.OPEN;
            pools[count].totalScore = 0;
            count++;
        } else {
            // revert("Pool is already started");
        }
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function addScore(User[] calldata scoreData, uint pool_id) public returns (bool) {
        require(msg.sender == admin, "Only admin can add score");
        for(uint i = 0; i < count; i++) {
            if(pool_id == pools[i].pool_id && pools[i].poolState == POOL_STATE.OPEN) {
                for(uint index = 0; index < scoreData.length; index++) {
                    pools[i].totalScore =  pools[i].totalScore + scoreData[index].score;
                    pools[i].user = User({
                        user: scoreData[index].user,
                        score: scoreData[index].score,
                        isClaimed: false
                    });
                }
                pools[i].poolState = POOL_STATE.CLOSED;
                pools[i].createTime = block.timestamp;
            }
        }
        return true;
    }

    function claimReward (uint pool_id) public {
        for(uint i = 0; i < count; i++) {
            if(msg.sender == pools[i].user.user && pool_id == pools[i].pool_id && pools[i].poolState == POOL_STATE.CLOSED) {
                if (pools[i].user.isClaimed == false ) {
                    if(block.timestamp - pools[i].createTime < day1) {
                        payable (msg.sender).transfer(getBalance() * (pools[i].user.score / pools[i].totalScore) * 70 / 100);
                        pools[i].user.isClaimed = true;
                    } else if(block.timestamp - pools[i].createTime > day1 && block.timestamp - pools[i].createTime < day2) { // winner gets 80% of the balance if they try to claim on the 2nd day
                        payable (msg.sender).transfer(getBalance() * (pools[i].user.score / pools[i].totalScore) * 80 / 100);
                        pools[i].user.isClaimed = true;
                    } else if (block.timestamp - pools[i].createTime > day1 && block.timestamp - pools[i].createTime > day2 && block.timestamp - pools[i].createTime < day3) { // winner gets 90% of the balance if they try to claim on the 3rd day
                        payable (msg.sender).transfer(getBalance() * (pools[i].user.score / pools[i].totalScore) * 90 / 100);
                        pools[i].user.isClaimed = true;
                    } else {
                        payable (msg.sender).transfer(getBalance() * (pools[i].user.score / pools[i].totalScore) * 95 / 100);
                        pools[i].user.isClaimed = true;
                    }
                }
            }
        }
    }

    function claimAllReward () public {
        uint totalClaim = 0;
        for(uint i = 0; i < count; i++) {
            if (pools[i].poolState == POOL_STATE.CLOSED) {
                if(msg.sender == pools[i].user.user) {
                    if (pools[i].user.isClaimed == false ) {
                        if(block.timestamp - pools[i].createTime < day1) {
                            totalClaim += getBalance() * (pools[i].user.score / pools[i].totalScore) * 70 / 100;
                        } else if(block.timestamp - pools[i].createTime > day1 && block.timestamp - pools[i].createTime < day2) { // winner gets 80% of the balance if they try to claim on the 2nd day
                            totalClaim += getBalance() * (pools[i].user.score / pools[i].totalScore) * 80 / 100;
                        } else if (block.timestamp - pools[i].createTime > day1 && block.timestamp - pools[i].createTime > day2 && block.timestamp - pools[i].createTime < day3) { // winner gets 90% of the balance if they try to claim on the 3rd day
                            totalClaim += getBalance() * (pools[i].user.score / pools[i].totalScore) * 90 / 100;
                        } else {
                            totalClaim += getBalance() * (pools[i].user.score / pools[i].totalScore) * 95 / 100;
                        }
                    }
                }
            }
        }
        if (totalClaim > 0) {
            payable (msg.sender).transfer(totalClaim);
            for(uint i = 0; i < count; i++) {
                if (pools[i].poolState == POOL_STATE.CLOSED) {
                    if(msg.sender == pools[i].user.user) {
                        if (pools[i].user.isClaimed == false) {
                            pools[i].user.isClaimed = true;
                        }
                    }
                }
            }
        }
    }
}