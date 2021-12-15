/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity >=0.5.0 <0.9.0;
 
contract AdminPool{
    
    address public admin;
    uint public createTime;
    uint public adminContribution;
    uint public totalscore;
    uint topHunderd = 100;
    uint count;
    
    enum POOL_STATE {
        OPEN, CLOSED
    }
    POOL_STATE public pool_state;

    mapping (uint => User) public leaderboard; // array of users

    struct User { // each user has an address and score
    address user;
    uint score;
    bool claimed;
    // 2 more variables. total claim and participation
    }

    function addScore(address user, uint score) public returns (bool) // function to be called to update leaderboard
    {
    require(msg.sender == admin,"Only Admin can call this function");
    if(leaderboard[topHunderd-1].score >= score) return false; // if the score is low, don't update

    for (uint i=0; i<topHunderd;i++){ // loop through the leaderboard

    if(leaderboard[i].score < score){ // check where to add the new score


    User memory currentUser = leaderboard[i];
    for(uint j=i+1; j<topHunderd+1; j++){

    User memory nextUser = leaderboard[j];
    leaderboard[j] = currentUser;
    currentUser = nextUser;
    }
    totalscore = totalscore + score;
    count++;

    leaderboard[i] = User({ // insert
    user: user,
    score: score,
    claimed: true
    });

    delete leaderboard[topHunderd]; // delete last from list
    return true;
    }
    }
    }
    
    uint constant day1 = 86400;
    uint constant day2 = 172800;
    uint constant day3 = 259200;

    
    constructor(){
        
        admin = msg.sender; // setting deployer as the admin
        pool_state = POOL_STATE.CLOSED; // initially the pool is closed 
    }
    /*modifier onlyWinner {
    require(msg.sender == winnerAddress);
    _;
    }*/
    
    // this is required to receive ETH
    receive () payable external{
        require(pool_state == POOL_STATE.OPEN); // can only accept ETH if the pool is open
    }
    
    function startPool() public payable {
        require(msg.sender == admin);
        require(pool_state == POOL_STATE.CLOSED, "The pool is already open");
        require(msg.value == 5 ether);
        adminContribution = 5 ether;
        pool_state = POOL_STATE.OPEN; // if admin calls this function then the state changes to OPEN and everyone can contribute in the pool
    }
    
    function endPool() public {
        require(msg.sender == admin);
        require(pool_state == POOL_STATE.OPEN, "The pool is already closed");
        pool_state = POOL_STATE.CLOSED; // if admin calls this function then the state changes to CLOSED and nobody can contribute in the pool
        createTime = block.timestamp;
    }
    
    // to check the balance of the contract
    function getBalance() public view returns(uint){

        return address(this).balance;
    }
    
 /*   function announceWinner(address payable _winnerAddress) public {
        require(msg.sender == admin); // admin will announce the winner
        createTime = block.timestamp; // time stamp will be created
    }
*/
    function claimReward () public {
        //address publisher = msg.sender;
        for(uint i=0; i<= count;i++)
        {
            if(msg.sender == leaderboard[i].user && leaderboard[i].claimed == true)
        {
        if(block.timestamp - createTime < day1){ // winner gets 70% of the balance if they try to claim on the 1st day
            payable (msg.sender).transfer((getBalance() * leaderboard[i].score / totalscore) * 70 / 100);
            leaderboard[i].claimed = false;
           // payable(admin).transfer(getBalance());
        }
        else if(block.timestamp - createTime > day1 && block.timestamp - createTime < day2){ // winner gets 80% of the balance if they try to claim on the 2nd day
            payable (msg.sender).transfer(getBalance() * (leaderboard[i].score / totalscore) * 80 / 100);
            leaderboard[i].claimed = false;
           // payable(admin).transfer(getBalance());
        }
        else if (block.timestamp - createTime > day1 && block.timestamp - createTime > day2 && block.timestamp - createTime < day3){ // winner gets 90% of the balance if they try to claim on the 3rd day
            payable (msg.sender).transfer(getBalance() * (leaderboard[i].score / totalscore) * 90 / 100);
            leaderboard[i].claimed = false;
           // payable(admin).transfer(getBalance());
        } 
        else { // winner gets 95% of the balance after 3 days.
            payable (msg.sender).transfer(getBalance() * (leaderboard[i].score / totalscore) * 95 / 100);
            leaderboard[i].claimed = false;
           // payable(admin).transfer(getBalance());
        }
        
    }
}
    }
}