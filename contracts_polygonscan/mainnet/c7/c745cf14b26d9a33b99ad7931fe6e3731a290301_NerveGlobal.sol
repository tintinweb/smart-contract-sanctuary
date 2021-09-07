/**
 *Submitted for verification at polygonscan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

    /******************************************/
    /*          NrvToken starts here          */
    /******************************************/

abstract contract NrvToken 

{
    function mintNrv(address _to, uint256 _amount) external virtual;

    function burnNrv(address _from, uint256 _amount) external virtual;
    
    function receiveFee() external payable virtual;
}

    /******************************************/
    /*            Nrv starts here             */
    /******************************************/

contract NerveGlobal
{
    NrvToken public nrvToken;
    address public nrvGov;
    bool internal initialized;
    uint256 public taskFee;
    uint256 public betFee;

    mapping(address => bytes32) public addressRegister;
    mapping(bytes32 => address) public nameRegister;

    uint256 internal currentTaskID;
    mapping(uint256 => taskInfo) internal tasks;

    uint256 internal currentBetID;
    mapping(uint256 => betInfo) internal bets;
    
    struct taskInfo    // Struct for Task Details.
    {
        uint96 amount;
        uint96 entranceAmount;
        uint40 endTask;
        uint24 participants;
        // <- 256
        
        address recipient;
        bool executed;
        bool finished;
        uint24 positiveVotes;
        uint24 negativeVotes;
        //<- 192

        mapping(address => uint256) stakes;
        mapping(address => bool) voted;       
    }

    struct betInfo    // Struct for Bet Details.
    {
        address initiator;
        uint40 endBet;
        bool winnerPartyA;
        bool draw;
        bool riennevaplus;
        bool finished;
        // 240

        uint80 stakesA;
        uint80 stakesB;
        // 160
        
        mapping(address => uint256) partyA;
        mapping(address => uint256) partyB;
    }

    event TaskAdded(address indexed initiator, uint256 indexed taskID, address indexed recipient, uint256 amount, string description, uint256 endTask, string language, uint256 lat, uint256 lon);
    event TaskJoined(address indexed participant, uint256 indexed taskID, uint256 amount);
    event Voted(address indexed participant, uint256 indexed taskID, bool vote, bool finished);
    event RecipientRedeemed(address indexed recipient, uint256 indexed taskID, uint256 amount);
    event UserRedeemed(address indexed participant, uint256 indexed taskID, uint256 amount);
    event TaskProved(uint256 indexed taskID, string proofLink);
    event TaskPromoted(uint256 indexed taskID, uint256 amount);

    event BetCreated(address indexed initiator, uint256 indexed betID, string description, uint256 endBet, string yesText, string noText, string language, uint256 lat, uint256 lon);
    event BetJoined(address indexed participant, uint256 indexed betID, uint256 amount, bool joinA);
    event BetClosed(address indexed initiator, uint256 indexed betID);
    event BetFinished(address indexed initiator, uint256 indexed betID, bool winnerPartyA, bool draw, bool failed);
    event BetRedeemed(address indexed participant, uint256 indexed betID, uint256 profit);
    event BetBailout(address indexed participant, uint256 indexed betID, uint256 userStake);
    event BetProved(uint256 indexed betID, string proofLink);
    event BetPromoted(uint256 indexed betID, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == address(nrvGov), "Caller is not nrvGov.");
        _;
    }
    
    constructor() 
    { 
        currentTaskID = 0;
        currentBetID = 0;
    }
    
    function initialize(address _nrvToken, address _nrvGov) public 
    {
        require(initialized == false, "Already initialized.");
        initialized = true;
        nrvGov = _nrvGov;
        nrvToken = NrvToken(_nrvToken);
    }

    function setFees(uint256 _taskFee, uint256 _betFee) external onlyGov
    {
        taskFee = _taskFee;
        betFee = _betFee;
    }

    function setGovernance(address _nrvGov) external onlyGov
    {
        nrvGov = _nrvGov;
    }

    /******************************************/
    /*           NrvTask starts here          */
    /******************************************/

    /**
    * @dev Public function to assign a task to a player. Msg.value is the entrance amount.
    * @param recipient Recipient's address.
    * @param description String that describes the task.
    * @param duration Time until task closes.
    */
    function createTask(address recipient, string memory description, uint256 duration, string memory language, uint256 lat, uint256 lon) public payable
    {
        require(recipient != address(0), "0x00 address not allowed.");
        require(msg.value != 0, "No stake defined.");
        
        currentTaskID++;        
        taskInfo storage s = tasks[currentTaskID];
        
        s.recipient = recipient;
        s.amount = uint96(msg.value);
        s.entranceAmount = uint96(msg.value);
        s.endTask = uint40(duration + block.timestamp);
        s.participants++;
        s.stakes[msg.sender] = msg.value;

        emit TaskAdded(msg.sender, currentTaskID, recipient, msg.value, description, s.endTask, language, lat, lon);
    }

    /**
    * @dev Public function to join an existing task. Msg.value gets staked.
    * @param taskID ID of the task to join.
    */
    function joinTask(uint256 taskID) public payable
    {           
        require(msg.value != 0, "No stake defined.");
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].entranceAmount <= msg.value, "Sent ETH does not match tasks entrance amount.");
        require(tasks[taskID].stakes[msg.sender] == 0, "Already participating in task.");
        require(tasks[taskID].endTask > block.timestamp, "Task participation period has ended." );
        require(tasks[taskID].recipient != msg.sender, "User can't be a task recipient.");
        require(tasks[taskID].finished != true, "Task already finished.");

        tasks[taskID].amount = tasks[taskID].amount + uint96(msg.value);
        tasks[taskID].stakes[msg.sender] = msg.value;
        tasks[taskID].participants++;

        emit TaskJoined(msg.sender, taskID, msg.value);
    }
    
    /**
    * @dev Public function to vote on a task.
    * @param taskID ID of the task to vote on.
    * @param vote Positive or negative vote.
    */
    function voteTask(uint256 taskID, bool vote) public
    { 
        require(tasks[taskID].amount != 0, "Task does not exist.");
        require(tasks[taskID].endTask > block.timestamp, "Task has already ended.");
        require(tasks[taskID].stakes[msg.sender] != 0, "Not participating in task.");
        require(tasks[taskID].voted[msg.sender] == false, "Vote has already been cast.");

        tasks[taskID].voted[msg.sender] = true;
        
        if (vote) {
            tasks[taskID].positiveVotes++;  

        } else {  
            tasks[taskID].negativeVotes++;                             
        }
        
        if (tasks[taskID].participants == tasks[taskID].negativeVotes + tasks[taskID].positiveVotes) {
            tasks[taskID].finished = true;
        }

        emit Voted(msg.sender, taskID, vote, tasks[taskID].finished);
    }

    /**
    * @dev Public function to redeem stakes as a recipient on task completion.
    * @param taskID ID of the task.
    */
    function redeemRecipient(uint256 taskID) public
    {
        require(tasks[taskID].recipient == msg.sender, "This task does not belong to message sender.");
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes >= tasks[taskID].negativeVotes, "Streamer lost the vote.");
        require(tasks[taskID].executed != true, "Task reward already redeemed");

        tasks[taskID].executed = true;                                                  // Avoid recursive calling
        uint256 fee = uint256(tasks[taskID].amount) / taskFee;
        payable(msg.sender).transfer(uint256(tasks[taskID].amount) - fee);   
        nrvToken.mintNrv(msg.sender, fee);         
        nrvToken.receiveFee {value: fee}();                                                          

        emit RecipientRedeemed(msg.sender, taskID, tasks[taskID].amount);
        
        delete tasks[taskID];
    }

    /**
    * @dev Public function to redeem stakes of a failed task as a user.
    * @param taskID ID of the task.
    */
    function redeemUser(uint256 taskID) public
    {
        require(tasks[taskID].endTask <= block.timestamp || tasks[taskID].finished == true, "Task is still running.");
        require(tasks[taskID].positiveVotes < tasks[taskID].negativeVotes, "Streamer fullfilled the task.");
        require(tasks[taskID].stakes[msg.sender] != 0, "User did not participate or has already redeemed his stakes.");

        uint256 tempStakes = tasks[taskID].stakes[msg.sender];

        tasks[taskID].stakes[msg.sender] = 0;       // Avoid recursive calling
        payable(msg.sender).transfer(tempStakes);

        emit UserRedeemed(msg.sender, taskID, tempStakes);
    }

    /**
    * @dev Public function to prove a task.
    * @param taskID ID of the task.
    * @param proofLink Link to proof.
    */
    function proveTask(uint256 taskID, string memory proofLink) public
    {
        require(tasks[taskID].recipient == msg.sender, "Can only be proved by recipient.");

        emit TaskProved(taskID, proofLink);
    }

    /**
    * @dev Public function to promote a task and burn NRV.
    * @param taskID ID of the task.
    * @param amount Amount of NRV to burn.
    */
    function promoteTask(uint256 taskID, uint256 amount) public
    {
        require(amount != 0, "Can't promote zero amount.");
        require(taskID <= currentTaskID, "Task doesn't exist.");
        nrvToken.burnNrv(msg.sender, amount);

        emit TaskPromoted(taskID, amount);
    }

    /******************************************/
    /*           NrvBet starts here           */
    /******************************************/

    /**
    * @dev Public function to create a new bet.
    * @param description Description of the Bet.
    * @param duration Time in seconds until bet gets reverted.
    */
    function createBet(string memory description, uint256 duration, string memory yesText, string memory noText, string memory language, uint256 lat, uint256 lon) public 
    {           
        currentBetID++;
        betInfo storage b = bets[currentBetID];

        b.initiator = msg.sender;
        b.endBet = uint40(block.timestamp + duration);

        emit BetCreated(msg.sender, currentBetID, description, b.endBet, yesText, noText, language, lat, lon);
    }

    /**
    * @dev Public function to join an existing bet. Msg.value gets allocated to the party associated with the chosen outcome.
    * @param betID ID of the bet to join.
    * @param joinA Chosen outcome.
    */
    function joinBet(uint256 betID, bool joinA) public payable
    {           
        require(msg.value != 0, "No stake defined.");
        require(bets[betID].initiator != address(0), "Bet does not exist.");
        require(bets[betID].partyA[msg.sender] == 0 && bets[betID].partyB[msg.sender] == 0, "Already participating in Bet.");
        require(bets[betID].initiator != msg.sender, "User can't be the bet initiator.");
        require(bets[betID].riennevaplus != true, "Bet already closed.");
        require(bets[betID].endBet > block.timestamp, "Bet expired.");

        if (joinA) {
            bets[betID].partyA[msg.sender] = msg.value;
            bets[betID].stakesA += uint80(msg.value);

        } else {
            bets[betID].partyB[msg.sender] = msg.value;
            bets[betID].stakesB += uint80(msg.value);

        }

        emit BetJoined(msg.sender, betID, msg.value, joinA);
    }

    /**
    * @dev Public function to close an existing bet. Users won't be able to join this bet anymore.
    * @param betID ID of the bet to close.
    */
    function closeBet(uint256 betID) public
    {           
        require(bets[betID].initiator == msg.sender, "Only the initiator of a bet can close it.");
        require(bets[betID].riennevaplus != true, "Bet already closed.");
        require(bets[betID].endBet > block.timestamp, "Bet expired.");
        
        if (bets[betID].stakesA == 0 || bets[betID].stakesB == 0) {         
            bets[betID].finished = true;
            emit BetFinished(msg.sender, betID, false, false, true);
        }
        
        bets[betID].riennevaplus = true;

        emit BetClosed(msg.sender, betID);
    }

    /**
    * @dev Public function to finish an existing bet. A result has to be determined and the winning party will be able to withdraw their gains.
    * @param betID ID of the bet to finish.
    */
    function finishBet(uint256 betID, bool winnerPartyA, bool draw) public
    {           
        require(bets[betID].initiator == msg.sender, "Only the initiator of a bet can finish it.");
        require(bets[betID].riennevaplus == true, "Bet still open.");
        require(bets[betID].finished != true, "Bet already finished.");
        require(bets[betID].endBet > block.timestamp, "Bet expired.");

        bets[betID].finished = true;
        bets[betID].winnerPartyA = winnerPartyA;
        bets[betID].draw = draw;

        uint256 losingStakes = bets[betID].winnerPartyA ? bets[betID].stakesB : bets[betID].stakesA;
        uint256 fee = losingStakes / betFee; 
        nrvToken.mintNrv(msg.sender, fee);         
        nrvToken.receiveFee {value: fee}();  

        emit BetFinished(msg.sender, betID, winnerPartyA, draw, false);
    }

    /**
    * @dev Public function to redeem gains on a bet. Reclaim initial stake and receive share of the funds of the losing party.
    * @param betID ID of the bet to redeem.
    */
    function redeemBet(uint256 betID) public
    {           
        require(bets[betID].initiator != msg.sender, "The initiator can't have stakes in a bet.");
        require(bets[betID].finished == true, "Bet is not finished.");
        require(bets[betID].draw == false, "No winner.");
        require(bets[betID].stakesA != 0 && bets[betID].stakesB != 0, "Bet participants on one side are 0.");

        uint256 stake;
        uint256 losingStakes;
        uint256 fee;
        uint256 userShare;
   
        if (bets[betID].winnerPartyA) {
            require(bets[betID].partyA[msg.sender] != 0, "User has no Stake on the winning side.");
            
            stake = bets[betID].partyA[msg.sender];
            bets[betID].partyA[msg.sender] = 0;             //Avoid recursive calling 
            losingStakes = bets[betID].stakesB;
            fee = losingStakes / betFee;
            userShare = (stake * (losingStakes - fee)) / bets[betID].stakesA;

        } else {
            require(bets[betID].partyB[msg.sender] != 0, "User has no Stake on the winning side.");

            stake = bets[betID].partyB[msg.sender];
            bets[betID].partyB[msg.sender] = 0;             //Avoid recursive calling
            losingStakes = bets[betID].stakesA;
            fee = losingStakes / betFee;
            userShare = (stake * (losingStakes - fee)) / bets[betID].stakesB;
        }
    
        payable(msg.sender).transfer(userShare + stake);

        emit BetRedeemed(msg.sender, betID, userShare);
    }

    /**
    * @dev Public function to bailout stakes on a bet. Reclaim initial stake.
    * @param betID ID of the bet to bailout.
    */
    function bailoutBet(uint256 betID) public
    {           
        require((bets[betID].draw == true) || (bets[betID].endBet < block.timestamp && bets[betID].finished == false) || 
        ((bets[betID].endBet < block.timestamp || bets[betID].finished == true) && (bets[betID].stakesA == 0 || bets[betID].stakesB == 0)), "End date of Bet not reached or participants on one not side 0.");
        require(bets[betID].partyA[msg.sender] != 0 || bets[betID].partyB[msg.sender] != 0, "User has no stakes in this bet.");
        
        uint256 stake;

        if(bets[betID].partyA[msg.sender] != 0){
            stake = bets[betID].partyA[msg.sender];
            bets[betID].partyA[msg.sender] = 0;

        } else {
            stake = bets[betID].partyB[msg.sender];
            bets[betID].partyB[msg.sender] = 0;
        }

        payable(msg.sender).transfer(stake);
        
        emit BetBailout(msg.sender, betID, stake);
    }

    /**
    * @dev Public function to prove a task.
    * @param betID ID of the bet.
    * @param proofLink Link to proof.
    */
    function proveBet(uint256 betID, string memory proofLink) public
    {
        require(bets[betID].initiator == msg.sender, "Can only be proved by initiator.");

        emit BetProved(betID, proofLink);
    }

    /**
    * @dev Public function to promote a bet and burn NRV.
    * @param betID ID of the bet.
    * @param amount Amount of NRV to burn.
    */
    function promoteBet(uint256 betID, uint256 amount) public
    {
        require(amount != 0, "Can't promote zero amount.");
        require(betID <= currentBetID, "Bet doesn't exist.");
        nrvToken.burnNrv(msg.sender, amount);

        emit TaskPromoted(betID, amount);
    }
}