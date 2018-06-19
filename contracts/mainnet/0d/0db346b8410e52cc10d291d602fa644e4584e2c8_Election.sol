pragma solidity ^0.4.17;

contract Election{
    
    address public manager; // contract manager
    
    bool public isActive;
    mapping(uint256 => address[]) public users; // all votes
    mapping(address => uint256[]) public votes; // to fetch one user&#39;s votes
    uint256 public totalUsers; // total users participated (not unique user count)
    uint256 public totalVotes; // for calculating avg vote guess on client side. (stats only)
    address[] public winners; // winner list. will be set after manager calls finalizeContract function
    uint256 public winnerPrice; // reward per user for successfull guess.
    uint256 public voteResult; // candidate&#39;s vote result will be set after election.
    
    
    // minimum reqired ether to enter competition.
    modifier mRequiredValue(){
        require(msg.value == .01 ether);
        _;
    }
    
    // manager only functions: pause, finalizeContract
    modifier mManagerOnly(){
        require(msg.sender == manager);
        _;
    }
    
    // contract will be manually paused before on election day by manager.
    modifier mIsActive(){
        require(isActive);
        _;
    }
    
    // constructor
    function Election() public{
        manager = msg.sender;
        isActive = true;
    }
    
    /**
    * user can join competition with this function.
    * user&#39;s guess multiplied with 10 before calling this function for not using decimal numbers.
    * ex: user guess: 40.2 -> 402
    **/
    function voteRequest(uint256 guess) public payable mIsActive mRequiredValue {
        require(guess > 0);
        require(guess <= 1000);
        address[] storage list = users[guess];
        list.push(msg.sender);
        votes[msg.sender].push(guess);
        totalUsers++;
        totalVotes += guess;
    }
    
    // get user&#39;s vote history.
    function getUserVotes() public view returns(uint256[]){
        return votes[msg.sender];
    }

    // stats only function
    function getSummary() public returns(uint256, uint256, uint256) {
        return(
            totalVotes,
            totalUsers,
            this.balance
        );
    }
    
    // for pausing contract. contract will be paused on election day. new users can&#39;t join competition after contract paused.
    function pause() public mManagerOnly {
        isActive = !isActive;
    }
    
    /** send ether to winners.(5% manager fee.)
     * if there is no winner choose closest estimates will get rewards.
     * manager will call this function after official results announced by YSK.
     * winners will receive rewards instantly.
     * election results will be rounded to one decimal only.
     * if result is 40.52 then winner is who guessed 40.5
     * if result is 40.56 then winner is who guessed 40.6
     **/
    function finalizeContract(uint256 winningNumber) public mManagerOnly {
        voteResult = winningNumber;
        address[] memory list = users[winningNumber];
        address[] memory secondaryList;
        uint256 winnersCount = list.length;

        if(winnersCount == 0){
            // if there is no winner choose closest estimates.
            bool loop = true;
            uint256 index = 1;
            while(loop == true){
                list = users[winningNumber-index];
                secondaryList = users[winningNumber+index];
                winnersCount = list.length + secondaryList.length;

                if(winnersCount > 0){
                    loop = false;
                }
                else{
                    index++;
                }
            }
        }
        
        uint256 managerFee = (this.balance/100)*5; // manager fee %5
        uint256 reward = (this.balance - managerFee) / winnersCount; // reward for per winner.
        winnerPrice = reward;
        
        // set winner list
        winners = list;
        // transfer eth to winners.
        for (uint256 i = 0; i < list.length; i++) {
            list[i].transfer(reward);
        }
                
        // if anyone guessed the correct percent secondaryList will be empty array.
        for (uint256 j = 0; j < secondaryList.length; j++) {
            // transfer eth to winners.
            secondaryList[j].transfer(reward);
            winners.push(secondaryList[j]); // add to winners
        }
        
        // transfer fee to manager
        manager.transfer(this.balance);
        
        
    }
    
}