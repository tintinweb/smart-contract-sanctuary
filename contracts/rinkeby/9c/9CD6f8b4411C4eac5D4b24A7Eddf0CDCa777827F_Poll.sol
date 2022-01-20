/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity ^0.8.11;
contract PollFactory {
    address[] public deployedPolls;
    mapping(address => bool) public voters;
    function createPoll(string calldata title, string calldata description, string[] calldata options) public {
        address poll = address(new Poll(msg.sender, title, description, options, this));
        deployedPolls.push(poll);
    }
    function verify() public payable {
        require(msg.value == 0.001 ether);
        require(!voters[msg.sender]);
        voters[msg.sender] = true;
    }
    function getDeployedPolls() public view returns (address[] memory) {
        return deployedPolls;
    }
}
contract Poll {
    PollFactory private pollFactory;
    mapping (address => bool) public voted;
    string[] public options;
    string public title;
    string public description;
    uint[] public votes;
    uint public winner;
    bool public closed;
    bool public paused;
    address public manager;
    constructor(address _manager, string memory _title, string memory _description, string[] memory _options, PollFactory _pollFactory) {
        manager = _manager;
        title = _title;
        description = _description;
        options = _options;
        votes = new uint[](options.length);
        pollFactory = _pollFactory;
    }
    event VoteEvent(uint option, uint newValue);
    event PauseEvent(bool newState);
    event GetWinnerEvent(uint winner);
    function vote(uint option) public verified {
        require(!closed, "This poll is currently closed");
        require(!voted[msg.sender], "This address already voted");
        votes[option] += 1;
        voted[msg.sender] = true;
        emit VoteEvent(option, votes[option]);
    }
    function pause(bool state) public restricted {
        paused = state;
        emit PauseEvent(paused);
    }
    function getWinner() public restricted {
        pause(true);
        closed = true;
        uint winnerIndex = 0;
        uint highestCount = 0;
        for (uint i = 0; i < votes.length; i++) {
            if (votes[i] > highestCount) {
                winnerIndex = i;
                highestCount = votes[i];
            }
        }
        winner = winnerIndex;
        emit GetWinnerEvent(winner);
    }
    function getOptions() public view returns (string[] memory) {
        return options;
    }
    function getVotes() public view returns (uint[] memory) {
        return votes;
    }
    function getSummary() external view returns(address, string memory, string memory, bool, bool, uint, string[] memory, uint[] memory) {
        return (
            manager,
            title,
            description,
            paused,
            closed,
            winner,
            getOptions(),
            getVotes()
        );
    }
    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this method");
        _;
    }
    modifier verified() {
        require(pollFactory.voters(msg.sender), "This address is not verified");
        _;
    }
}