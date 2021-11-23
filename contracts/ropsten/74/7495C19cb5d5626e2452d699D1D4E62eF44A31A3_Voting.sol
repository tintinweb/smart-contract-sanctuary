// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

pragma experimental ABIEncoderV2;

contract Voting {

    struct Person {
        address identifier;
        string name;
        bool voted;
        uint8 voteCount;
    }

    address public chairperson;
    mapping(address => Person) addressToPeople;
    mapping(string => Person) nameToPeople;
    string[] public peopleNames;

    enum Stage {Init, Reg, Vote, Done}
    Stage public stage = Stage.Init;

    //Events
    event PersonAdded(string[] peopleNames);
    event VoteStarted();
    event VoteComplete();

    constructor() {
        chairperson = msg.sender;
        stage = Stage.Reg;
    }

    function addPerson(string memory name) public {
        if (stage != Stage.Reg || bytes(nameToPeople[name].name).length != 0) {return;}
        Person memory newPerson = Person(msg.sender, name, false, 0);

        addressToPeople[msg.sender] = newPerson;
        nameToPeople[name] = newPerson;
        peopleNames.push(name);

        emit PersonAdded(peopleNames);

    }

    function startVoting() public {
        if (stage != Stage.Reg || msg.sender != chairperson) {return;}
        stage = Stage.Vote;
        emit VoteStarted();
    }

    function resetVote() public {
        if (msg.sender != chairperson) {return;}

        for(uint8 ppl = 0; ppl < peopleNames.length; ppl++) {
            Person memory persona = nameToPeople[peopleNames[ppl]];
            persona.voteCount = 0;
            persona.voted = false;
        }
        stage = Stage.Vote;
        emit VoteStarted();

    }

    function vote(string memory name) public {
        if (stage != Stage.Vote) {return;}
        Person storage sender = addressToPeople[msg.sender];
        if(sender.voted || bytes(nameToPeople[name].name).length == 0) {return;}
        Person storage voteReceiver = nameToPeople[name];
        if(msg.sender == voteReceiver.identifier) {return;}

        sender.voted = true;
        voteReceiver.voteCount += 1;
    }

    function determineWinner() public returns(string memory name){
        if(msg.sender != chairperson) {return "";}
        if (stage != Stage.Vote ) {return "";}
        stage = Stage.Done;

        string memory winnerName = "No candidtate received votes";
        uint256 winningVoteCount = 0;
        for(uint8 ppl = 0; ppl < peopleNames.length; ppl++) {
            Person memory persona = nameToPeople[peopleNames[ppl]];
            if(persona.voteCount > winningVoteCount) {
                winningVoteCount = persona.voteCount;
                winnerName = persona.name;
            }
        }
        
        emit VoteComplete();
        return winnerName;
    }


    

}