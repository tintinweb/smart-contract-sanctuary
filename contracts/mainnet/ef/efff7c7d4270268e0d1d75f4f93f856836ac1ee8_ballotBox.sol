pragma solidity ^0.4.23;

contract ballotBox {
    // addresses set to true are able to create new ballots
    mapping(address => bool) public creators;
    // define ballot object/struct
    struct ballot {
        uint8 choiceCount;
        uint256 voteCountBlock;
    }
    // create array of ballots
    ballot[] public ballots;
    
    // event to record what ballot contracts have been deployed with what parameters
    event BallotCreated( string ballotProposal, uint256 indexed ballotIndex, address indexed ballotCreator, bytes32[] choices, uint256 countBlock );
    // event to record a vote
    event Vote(uint256 indexed ballotIndex, address voter, uint8 choice);
    // event to record changes to creator permission                                 
    event CreatorModified(address creator, bool active, address indexed by);
    
    constructor() public {
        // set contract creator as authorized ballot creator
        creators[msg.sender] = true;
        emit CreatorModified(msg.sender, true, msg.sender);
    }
    
    function createBallot(string _ballotQuestion, bytes32[] _choices, uint256 _countBlock) public {
        // ensure the count is in the future
        require(_countBlock > block.number);
        // ensure msg.sender is an authorized ballot creator
        require(creators[msg.sender]);
        // add ballot object to array
        ballots.push(ballot(uint8(_choices.length),_countBlock));
        // fire event to record ballot contract creation and parameters
        emit BallotCreated( _ballotQuestion, ballots.length-1 , msg.sender, _choices, _countBlock);
    }
    
    function vote(uint256 _ballotIndex, uint8 _choice) public {
        // ensure the count Block is not exceeded
        require(ballots[_ballotIndex].voteCountBlock > block.number);
        // ensure vote is a valid choice
        require(_choice < ballots[_ballotIndex].choiceCount);
        // fire event to record Vote
        emit Vote(_ballotIndex, msg.sender, _choice);
    }
    
    function modifyCreator(address _creator, bool _active) public {
        // ensure only creators can add or remove creators
        require(creators[msg.sender]);
        // ensure creators can only remove themselves
        if(_active == false) require(_creator == msg.sender);
        // set creator status
        creators[_creator] = _active;
        // fire event to record creator permission change
        emit CreatorModified(_creator, _active, msg.sender); 
    }
}