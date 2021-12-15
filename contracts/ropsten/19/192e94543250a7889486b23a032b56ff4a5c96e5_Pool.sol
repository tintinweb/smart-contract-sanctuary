/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity >=0.5.0 <0.9.0;
 
contract Pool{
    
    address payable[] public players; // dynamic array of type address payable
    address public admin;
    // address payable public winnerAddress;
    uint public createTime;
    uint public adminContribution;
    uint topTen = 10; // list the top 10 on leaderboard
    //uint user_score;
    uint public totalscore;
    
    enum POOL_STATE {
        OPEN, CLOSED
    }
    POOL_STATE public pool_state;

    mapping (uint => User) public leaderboard; // array of users

    struct User { // each user has an address and score
    address user;
    uint score;
    
    // 2 more variables. total claim and participation
    }

    /*function addScore(address user, uint score) public returns (bool) // function to be called to update leaderboard
    {
    if(leaderboard[topTen-1].score >= score) return false; // if the score is low, don't update

    for (uint i=0; i<topTen;i++){ // loop through the leaderboard

    if(leaderboard[i].score < score){ // check where to add the new score


    User memory currentUser = leaderboard[i];
    for(uint j=i+1; j<topTen+1; j++){

    User memory nextUser = leaderboard[j];
    leaderboard[j] = currentUser;
    currentUser = nextUser;
    }
    totalscore = totalscore + score;

    leaderboard[i] = User({ // insert
    user: user,
    score: score
    });

    delete leaderboard[topTen]; // delete last from list
    return true;
    }
    }
    }
    */
    uint constant day1 = 86400;
    uint constant day2 = 172800;
    uint constant day3 = 259200;

    uint constant adminETH = 3000000000000000000;
    uint count = 0;
    
    constructor(){
        
        admin = msg.sender; // setting deployer as the admin
        pool_state = POOL_STATE.CLOSED; // initially the pool is closed 
    }
    /*modifier onlyWinner {
    require(msg.sender == winnerAddress);
    _;
    }*/
    
    // this is required to receive ETH. any amount of ETH
    receive () payable external{
        
    }
    function payPool() public payable{
        require(pool_state == POOL_STATE.OPEN, "Pool is closed"); // can only accept ETH if the pool is open
        require(msg.value == 0.01 ether);
         // each player sends exactly 0.01 ETH, not more, not less 
        players.push(payable(msg.sender)); // add the player to the array
        count = count+1;
    }

    function startPool() public {
        require(msg.sender == admin);
        require(pool_state == POOL_STATE.CLOSED, "The pool is already open");
        pool_state = POOL_STATE.OPEN; // if admin calls this function then the state changes to OPEN and everyone can contribute in the pool
    }
    function endpoolbe() public { // ths is to be called from backend
        require(pool_state == POOL_STATE.OPEN, "The pool is already closed");
        pool_state = POOL_STATE.CLOSED;
    }
    
    function endPool() public {
        require(msg.sender == admin);
        require(pool_state == POOL_STATE.OPEN, "The pool is already closed");
        pool_state = POOL_STATE.CLOSED; // if admin calls this function then the state changes to CLOSED and nobody can contribute in the pool
    }
    
    // to check the balance of the contract
    function getBalance() public view returns(uint){

        return address(this).balance;
    }
    function getBalancediff() public view returns(uint){
        return adminETH + address(this).balance - address(this).balance;
    }
    
    // helper function that returns a big random integer
    /*function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }*/
    
 /*   function announceWinner(address payable _winnerAddress) public {
        require(msg.sender == admin); // admin will announce the winner
        winnerAddress = _winnerAddress;
        displayWinner();
        createTime = block.timestamp; // time stamp will be created
    }
    function displayWinner() public view returns(address) {
        return winnerAddress;
    }
*/
    /*function winnerReward () public {
        address publisher = msg.sender;
        for(uint i=0; i< players.length;i++)
        {
            if(msg.sender == leaderboard[i].user)
            {
        if(block.timestamp - createTime < day1){ // winner gets 70% of the balance if they try to claim on the 1st day
            payable (msg.sender).transfer((getBalance() + adminETH - getBalance())* (leaderboard[i].score / totalscore) *70 / 100);
           // payable(admin).transfer(getBalance());
        }
        else if(block.timestamp - createTime > day1 && block.timestamp - createTime < day2){ // winner gets 80% of the balance if they try to claim on the 2nd day
            payable (msg.sender).transfer((getBalance() + adminETH - getBalance())* (leaderboard[i].score / totalscore) *80 / 100);
           // payable(admin).transfer(getBalance());
        }
        else if (block.timestamp - createTime > day1 && block.timestamp - createTime > day2 && block.timestamp - createTime < day3){ // winner gets 90% of the balance if they try to claim on the 3rd day
            payable (msg.sender).transfer((getBalance() + adminETH - getBalance())* (leaderboard[i].score / totalscore) *90 / 100);
           // payable(admin).transfer(getBalance());
        } 
        else { // winner gets 95% of the balance after 3 days.
            payable (msg.sender).transfer((getBalance() + adminETH - getBalance())* (leaderboard[i].score / totalscore) *95 / 100);
           // payable(admin).transfer(getBalance());
        }
        
    }
            }
        } */
        //abc.transfer((getBalance() - getBalancediff()) * user_score / totalscore);
    
    // total score 1165, user score 1000. 1000/1165 * 100 
    // selecting the winner

   /* function newwinnerWithdraw() public {
        // require(msg.sender == winnerAddress);
        // only the winner can call this function and withdraw the funds
        
        if(block.timestamp - createTime < day1){ // winner gets 70% of the balance if they try to claim on the 1st day
            payable (msg.sender).transfer((getBalance() + adminETH - getBalance())* (leaderboard[i].score / totalscore) *70) / 100);
           // payable(admin).transfer(getBalance());
        }
        else if(block.timestamp - createTime > day1 && block.timestamp - createTime < day2){ // winner gets 80% of the balance if they try to claim on the 2nd day
            payable (msg.sender).transfer((getBalance()*80) / 100);
           // payable(admin).transfer(getBalance());
        }
        else if (block.timestamp - createTime > day1 && block.timestamp - createTime > day2 && block.timestamp - createTime < day3){ // winner gets 90% of the balance if they try to claim on the 3rd day
            payable (msg.sender).transfer((getBalance()*90) / 100);
           // payable(admin).transfer(getBalance());
        } 
        else { // winner gets 95% of the balance after 3 days.
            payable (msg.sender).transfer((getBalance()*95) / 100);
           // payable(admin).transfer(getBalance());
        }
        
    } */
    /*
    function winnerWithdraw() public {
        // require(msg.sender == winnerAddress);
        // only the winner can call this function and withdraw the funds
        
        if(block.timestamp - createTime < day1){ // winner gets 70% of the balance if they try to claim on the 1st day
            payable (msg.sender).transfer((getBalance()*70) / 100);
            payable(admin).transfer(getBalance());
        }
        else if(block.timestamp - createTime > day1 && block.timestamp - createTime < day2){ // winner gets 80% of the balance if they try to claim on the 2nd day
            payable (msg.sender).transfer((getBalance()*80) / 100);
            payable(admin).transfer(getBalance());
        }
        else if (block.timestamp - createTime > day1 && block.timestamp - createTime > day2 && block.timestamp - createTime < day3){ // winner gets 90% of the balance if they try to claim on the 3rd day
            payable (msg.sender).transfer((getBalance()*90) / 100);
            payable(admin).transfer(getBalance());
        } 
        else { // winner gets 95% of the balance after 3 days.
            payable (msg.sender).transfer((getBalance()*95) / 100);
            payable(admin).transfer(getBalance());
        }
        
    } */
    function adminWithdraw() public {
    require(msg.sender == admin);
    payable(admin).transfer(getBalance());
    }
}