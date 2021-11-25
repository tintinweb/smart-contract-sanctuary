pragma solidity >=0.4.22;


contract Proposals {
    address public owner;
    mapping(string => uint32) public proposalIndices;
    uint32 numProposals = 8;
    // The tokens we've given to each participant
    mapping(address => uint32) public tokens;
    // The votes that each proposal has gotten
    mapping(uint32 => uint32) public proposals;
    mapping(address => mapping(uint32 => uint32)) votesByFor;

    modifier restricted() {
        require(
            msg.sender == owner,
            "This function is restricted to the owner"
        );
        _;
    }

    // Truffle needs the public here
    constructor(uint32 studentCount) public {
        owner = msg.sender;

        proposalIndices["Nothing"] = 0;
        proposalIndices["Dog"] = 1;
        proposalIndices["Cat"] = 2;
        proposalIndices["Penguin"] = 3;
        proposalIndices["Monkey"] = 4;
        proposalIndices["Koala"] = 5;
        proposalIndices["Rabbit"] = 6;
        proposalIndices["Panda"] = 7;

        uint32 threeTokenStudents = (studentCount * 3) / 4;
        uint32 twoTokenStudents = studentCount - threeTokenStudents;
        proposals[0] = 3 * threeTokenStudents + 2 * twoTokenStudents - 1;

        for (uint32 i = 1; i < numProposals; ++i) {
            proposals[i] = 1;
        }
    }

    function setVotes(string memory proposal, uint32 amount) public restricted {
        uint32 i = proposalIndices[proposal];
        proposals[i] = amount;
    }

    function setupStudent(address addr) public restricted {
        // Enough to vote 3 times for a single proposal
        tokens[addr] = 9;
    }

    function voteFor(string memory proposal) public {
        // Will be Nothing if not present
        uint32 i = proposalIndices[proposal];
        require(
            tokens[msg.sender] >= 1,
            "You need to have a token to vote with"
        );
        uint32 n = votesByFor[msg.sender][i] + 1;
        // This makes it so that for N votes, we need to have spent a total of N^2 tokens
        uint32 required = 2 * n - 1;
        require(tokens[msg.sender] >= required, "Insufficient tokens");

        tokens[msg.sender] -= required;
        votesByFor[msg.sender][i] = n;
        proposals[i] += 1;
    }

    // This will take away all votes that the user has allocated so far
    function resetMyVotes() public {
        for (uint32 i = 0; i < numProposals; ++i) {
            uint32 n = votesByFor[msg.sender][i];
            tokens[msg.sender] += n * n;
            proposals[i] -= n;
            votesByFor[msg.sender][i] = 0;
        }
    }

    function myVotes(string memory proposal) public view returns(uint32 votes) {
        uint32 i = proposalIndices[proposal];
        return votesByFor[msg.sender][i];
    }
}