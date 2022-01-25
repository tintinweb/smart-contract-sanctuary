pragma solidity >=0.7.0 <0.9.0;
// import "hardhat/console.sol";
contract Ballot{
    struct Voter{
        bool voted;
        uint vote;
        uint weight;
        address delegate;
    }

    struct Proposal{
        string name;
        uint noOfVotes;
    }

    mapping(address=> Voter) voters;

    Proposal[] public proposals;

    uint public noofProposals;

    address public chairperson;

    event Voted(address voter,uint i);

    constructor (string[] memory proposalNames){
        chairperson=msg.sender;
        voters[msg.sender].weight=1;
        noofProposals=0;

        for(uint i=0;i<proposalNames.length;i++){
            noofProposals+=1;
            proposals.push(Proposal({name: proposalNames[i], noOfVotes: 0}));
        }
    }

    function addVoter(address voter) public{
        require(msg.sender==chairperson);
        require(!voters[voter].voted,"Member already voted");
        require(voters[voter].weight==0,"Member already added");
        voters[voter].weight=1;
    }

    function delegate(address to) public{
        require(!voters[msg.sender].voted,"Member already voted");
        while(voters[to].delegate!=address(0)){
            to=voters[to].delegate;

            require(to!=msg.sender,"Loop detected in chain");
        }

        if(voters[to].voted){
            proposals[voters[to].vote].noOfVotes+=voters[msg.sender].weight;
            voters[msg.sender].weight=0;
        } else {
            voters[to].weight+=voters[msg.sender].weight;
            voters[msg.sender].weight=0;
        }
    }

    function vote(uint proposal) public{

        require(!voters[msg.sender].voted,"Member already voted");
        require(voters[msg.sender].weight>=1,"Member doesn't have rights");
        require(proposal<proposals.length,"Proposal doesn't exist");
        voters[msg.sender].voted=true;
        voters[msg.sender].vote=proposal;
        proposals[proposal].noOfVotes+=voters[msg.sender].weight;
        emit Voted(msg.sender,proposal);
    }

    function winningProposal() public view returns (uint _winningProposal){
        uint winningVotes=0;
        for(uint i=0;i<proposals.length;i++){
            if(winningVotes<proposals[i].noOfVotes){
                winningVotes=proposals[i].noOfVotes;
                _winningProposal=i;
            }
        }

    }

    function winnerName() public view returns (string memory winner){
        winner=proposals[winningProposal()].name;
    }
}