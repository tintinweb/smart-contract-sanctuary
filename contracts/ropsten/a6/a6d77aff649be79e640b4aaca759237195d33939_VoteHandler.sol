/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

pragma abicoder v2;

contract VoteHandler
{
    // Read and write to ballots ('address' can be replaced with 'uint' for GroupID)
    mapping(uint => mapping(uint => address)) private ballotList;
    
    // Whitelisted Groups
    mapping(address => uint) public authorized;
    mapping(address => bool) public blacklisted;
    
    // Store ballots managed by Groups
    mapping(uint => mapping(uint => bool)) public ballotPool;
    
    // Events to monitor state changes
    event GroupAuthorized(address indexed groupAddress, uint indexed groupID);
    event BallotCreated(address indexed groupAddress, address ballotAddress, uint indexed groupID, uint indexed ballotID);
    
    address private owner;
    
    constructor()
    {
        owner = msg.sender;
    }
    
    function authorizeGroup(uint groupID) public returns (bool) 
    {
        require(authorized[msg.sender] != groupID, "This account is already whitelisted.");
        require(!blacklisted[msg.sender], "This account is blacklisted.");
        
        authorized[msg.sender] = groupID;
        emit GroupAuthorized(msg.sender, groupID);
        return true;
    }
    
    function createBallot(uint groupID, uint ballotID, uint timelimit) public returns (address)
    {
        require(authorized[msg.sender] == groupID, "Unauthorized user.");
        require(!ballotPool[groupID][ballotID], "Ballot already exist in pool.");
        
        // Create new template for Ballot object
        Ballot ballot = new Ballot(msg.sender, ballotID, timelimit);
        ballotPool[groupID][ballotID] = true;
        ballotList[groupID][ballotID] = address(ballot);
        
        emit BallotCreated(msg.sender, address(ballot), groupID, ballotID);
        return address(ballot);
    }


    function getBallotAddress(uint groupID, uint ballotID) view public returns(address)
    {
        require(ballotPool[groupID][ballotID], "Ballot does not exist in pool.");
        address ballotAddress = ballotList[groupID][ballotID];
        return ballotAddress;
    }

}

contract Ballot
{
    // Model a Choice
    struct Choice 
    {
        uint voteCount;
    }

    // Model a Question
    struct Question 
    {
        string[] choiceIDs;
	    mapping(string => Choice) choices;
    }
    
    // Keeps track of the valid question IDs
    uint[] public questionIDs;
    
    // Keeps track of total ballot submissions
    uint public submissions;
    
    uint public deadline;

    uint public ballotID;
    
    // Access a question
    mapping(uint => Question) private questions;
    
    // Events to monitor state changes
    event Voted(address indexed voterAddress, uint indexed ballotID, string[] choice);
    event QuestionAdded(address indexed groupAddress, uint indexed ballotID, uint indexed questionID, string[] selections);
    
    address private owner;
    
    constructor(address msgSender, uint _ballotID, uint timelimit)
    {
        owner = msgSender;
        ballotID = _ballotID;
        deadline = timelimit;
    }
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    
    function createQuestion(uint questionID, string[] memory selections) onlyOwner public
    {
        for(uint i = 0; i < selections.length; i++)
        {
            Choice memory choice;
            choice.voteCount = 0;
            questions[questionID].choices[selections[i]] = choice;
            questions[questionID].choiceIDs.push(selections[i]);
        }
        
        questionIDs.push(questionID);
        emit QuestionAdded(msg.sender, ballotID, questionID, selections);
    }

    function addVote(address voterAddress, string[] memory choices) onlyOwner public
    {
        require(block.timestamp < deadline, "Ballot has expired."); // Require votes to be within deadline

        for(uint i = 0; i < questionIDs.length; i++)
        {
            uint questionID = questionIDs[i];

            string memory choiceID = choices[i];
            questions[questionID].choices[choiceID].voteCount += 1;
        }

        submissions +=1;
        emit Voted(voterAddress, ballotID, choices);
    }

    function getChoice(uint questionID, string memory choiceID) view public returns (uint)
    {
        return questions[questionID].choices[choiceID].voteCount;
    }

    function getResult() view public returns (uint[][] memory)
    {
        uint[][] memory questionArray = new uint[][](questionIDs.length);

        for(uint i = 0; i < questionIDs.length; i++)
        {
            uint questionID = questionIDs[i];
            string[] memory choiceIDs = questions[questionID].choiceIDs;
            uint numofChoices = choiceIDs.length;
            uint[] memory choiceArray = new uint[](numofChoices);

            for(uint j = 0; j < numofChoices; j++)
            {
                string memory choiceID = choiceIDs[j];
                choiceArray[j] = (questions[questionID].choices[choiceID].voteCount);
            }
            questionArray[i] = choiceArray;
        
        }
        return questionArray;
    }
}