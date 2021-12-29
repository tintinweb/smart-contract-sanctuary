/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract AdminPool {

    address public admin;
    uint public createTime;
    uint public adminContribution;
    uint public totalScore;
    uint count;

    enum POOL_STATE {
        OPEN, CLOSED
    }
    POOL_STATE public poolState;

    mapping (uint => User) public leaderboard;

    struct User {
        address user;
        uint score;
        bool isClaimed;
        // 2 more variables. total claim and participation
    }

    uint constant day1 = 86400;
    uint constant day2 = 172800;
    uint constant day3 = 259200;

    constructor() {
        admin = msg.sender;
        poolState = POOL_STATE.CLOSED;
    }

    receive () payable external {
        require(poolState == POOL_STATE.OPEN);
    }

    function adminWithdraw() public {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(getBalance());
    }

    function startPool() public payable {
        require(msg.sender == admin, "Only admin can start the pool");
        require(poolState == POOL_STATE.CLOSED, "The pool is already open");
        require(msg.value > 0, "Please contribute desired amount to start pool");
        adminContribution = msg.value;
        poolState = POOL_STATE.OPEN;
        for(uint i=0; i<count; i++) {
            delete leaderboard[i];
        }
        totalScore = 0;
        count = 0;
    }

    // function endPool() public {
    //     require(msg.sender == admin, "Only admin can end the pool");
    //     require(poolState == POOL_STATE.OPEN, "The pool is already closed");
    //     poolState = POOL_STATE.CLOSED;
    //     createTime = block.timestamp;
    // }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function addScore(User[] calldata scoreData) public returns (bool) {
        require(msg.sender == admin, "Only admin can add score");
        require(poolState == POOL_STATE.OPEN, "The pool is already closed");
        for(uint i = 0; i < scoreData.length; i++) {
            totalScore = totalScore + scoreData[i].score;
            leaderboard[i] = User({
                user: scoreData[i].user,
                score: scoreData[i].score,
                isClaimed: false
            });
            count++;
        }
        poolState = POOL_STATE.CLOSED;
        createTime = block.timestamp;
        return true;
    }

    function claimReward () public {
        require(poolState == POOL_STATE.CLOSED, "The pool should be opened to claim");
        for(uint i = 0; i < count; i++) {
            if(msg.sender == leaderboard[i].user) {
                if (leaderboard[i].isClaimed == false) {
                    if(block.timestamp - createTime < day1) { // winner gets 70% of the balance if they try to claim on the 1st day
                        payable (msg.sender).transfer((getBalance() * leaderboard[i].score / totalScore) * 70 / 100);
                        leaderboard[i].isClaimed = true;
                    } else if(block.timestamp - createTime > day1 && block.timestamp - createTime < day2) { // winner gets 80% of the balance if they try to claim on the 2nd day
                        payable (msg.sender).transfer(getBalance() * (leaderboard[i].score / totalScore) * 80 / 100);
                        leaderboard[i].isClaimed = true;
                    } else if (block.timestamp - createTime > day1 && block.timestamp - createTime > day2 && block.timestamp - createTime < day3){ // winner gets 90% of the balance if they try to claim on the 3rd day
                        payable (msg.sender).transfer(getBalance() * (leaderboard[i].score / totalScore) * 90 / 100);
                        leaderboard[i].isClaimed = true;
                    } else { // winner gets 95% of the balance after 3 days.
                        payable (msg.sender).transfer(getBalance() * (leaderboard[i].score / totalScore) * 95 / 100);
                        leaderboard[i].isClaimed = true;
                    }
                }
            }
        }
    }
}