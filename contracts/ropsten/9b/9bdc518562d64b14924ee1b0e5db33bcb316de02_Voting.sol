pragma solidity ^0.5.5;

contract Voting {
    address private owner;

    string public publicKey;
    string public privateKey;

    bool public electionIsRunning;
    uint256 public maxNumberOfVoters;

    mapping(string => Vote) public votes;
    string[] public voters;

    struct Vote {
        bool eligibleToVote;
        string on;
    }

    constructor() public {
        owner = msg.sender;
        electionIsRunning = false;
        publicKey = "";
        privateKey = "";
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "This sender cannot access voting functions."
        );
        _;
    }

    modifier notRunning() {
        require(electionIsRunning == false, "Vote should not be running");
        require(
            maxNumberOfVoters >= voters.length,
            "Max number of voters is reached"
        );
        _;
    }

    modifier running() {
        require(electionIsRunning == true, "Vote should be running");
        require(
            maxNumberOfVoters > voters.length,
            "Max numbers of voters reached"
        );
        _;
    }

    function startElection(
        string memory key,
        // uint256 upTime,
        uint256 nVoters
    ) public onlyOwner notRunning {
        clearElection();
        maxNumberOfVoters = nVoters;
        publicKey = key;
        electionIsRunning = true;
    }

    function stopElection(string memory key) public onlyOwner running {
        electionIsRunning = false;
        privateKey = key;
    }

    function vote(string memory id, string memory voteData)
        public
        onlyOwner
        running
    {
        Vote memory userVote = votes[id];
        require(userVote.eligibleToVote, "This ID already voted!");

        userVote.on = voteData;
        userVote.eligibleToVote = false;
        votes[id] = userVote;
    }

    function addVoter(string memory id) public onlyOwner running {
        Vote memory userVote = Vote(true, "");
        votes[id] = userVote;
        voters.push(id);
    }

    function getNumberOfVoters() public view returns (uint256) {
        return voters.length;
    }

    function isAbleToVote(string memory id) public view running returns (bool) {
        return votes[id].eligibleToVote;
    }

    function getVote(uint256 index)
        public
        view
        notRunning
        returns (string memory)
    {
        return votes[voters[index]].on;
    }

    function clearElection() internal {
        for (uint256 i = 0; i < voters.length; i++) {
            votes[voters[i]] = Vote(false, "");
        }
        delete voters;
    }
}