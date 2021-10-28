/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;

    }

    address public chairperson;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    bytes32[] public proposalNames;


      constructor(bytes32 _tokenAddress, bytes32 _tokenAddress2) {
            chairperson = msg.sender;
            voters[chairperson].weight = 1;
            proposalNames.push(_tokenAddress);
            proposalNames.push(_tokenAddress2);

        for (uint i =0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
            name: proposalNames[i],
            voteCount: 0
            }));
        }

  }

    function giveRightToVote(address voter) public {

        require(!voters[voter].voted,
        "The voter already voted"
        );


        require(voters[voter].weight ==0, "weight does not equal zero");
        voters[voter].weight =1;

    }

        function checkrighttovote(address voter) public view returns (string memory) {
            if (voters[voter].weight > 0) {return "Has Right";} else {return "has no rights";}

    }


    function delegate(address from, address to) public {
        Voter storage sender = voters[from];
        require(!sender.voted, "you already voted");
        require(to != from, "self-delegation not allowed");
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != from, "found loop in delegation");
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

    function vote(uint proposal) public returns (string memory){
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "already voted");
        sender.weight += 1;
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
        return "done voting account ";
    }

        function getProposals() public pure returns (string memory) {
            return "proposals";

    }

        function othervote(uint proposal, address myother) public returns (string memory){
            Voter storage sender = voters[myother];
            require(sender.weight !=0, "has no right to vote");
            require(!sender.voted, "already voted");
            sender.voted = true;
            sender.vote = proposal;
            proposals[proposal].voteCount += sender.weight;
            return "done other voting account ";
    }


    address[] public hardhataccounts = [
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
0x90F79bf6EB2c4f870365E785982E1f101E93b906,
0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
0x976EA74026E726554dB657fA54763abd0C3a0aa9,
0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f,
0xa0Ee7A142d267C1f36714E4a8F75612F20a79720,
0xBcd4042DE499D14e55001CcbB24a551F3b954096,
0x71bE63f3384f5fb98995898A86B02Fb2426c5788,
0xFABB0ac9d68B0B445fB7357272Ff202C5651694a,
0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec,
0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097,
0xcd3B766CCDd6AE721141F452C550Ca635964ce71,
0x2546BcD3c84621e976D8185a91A922aE77ECEc30,
0xbDA5747bFD65F08deb54cb465eB87D40e51B197E,
0xdD2FD4581271e230360230F9337D5c0430Bf44C0,
0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199
];





    function resetVoting() public returns (string memory) {
            for (uint p=0; p < proposals.length; p ++) {
                proposals[p].voteCount = 0;
            }
            for (uint p=0; p < hardhataccounts.length; p ++) {
                voters[hardhataccounts[p]].weight = 0;
            }
            for (uint p=0; p < hardhataccounts.length; p ++) {
                voters[hardhataccounts[p]].voted = false;
            }
            return "votes reset";
    }

    uint[] public arr;

        function tallyVoting() public view returns (uint[] memory ) {
            uint[] memory newArray = new uint[](proposals.length);
            for (uint p=0; p < proposals.length; p ++) {
                newArray[p] = proposals[p].voteCount;
            }
            return newArray;
    }

        function votedstatus(address voter) public view returns (string memory) {
            if (voters[voter].voted) {return "voted";} else {return "has not voted";}

    }



    // function winningProposal() public view returns (uint winningProposal) {
    //     uint _winningVoteCount = 0;
    //     for (uint p=0; p < proposals.length; p ++) {
    //         if (proposals[p].voteCount > _winningVoteCount) {
    //             _winningVoteCount = proposals[p].voteCount;
    //             winningProposal = p;
    //         }
    //     }
    //     return winningProposal;
    // }

    // function winnerName() public view returns (bytes32 winnerName_) {
    //     winnerName_ = proposals[winningProposal()].name;
    // }


}