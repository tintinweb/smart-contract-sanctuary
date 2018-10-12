pragma solidity ^0.4.25;

contract Proposal {
    
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public partyOf;
    mapping(address => string) public usernames;
    
    /*
    partyOf:
    1: A
    2: B
    3: C
    */

    struct proposal {
        string title;
        string content;
        uint status;
    }
    
    /*
    status:
    0: created by A
    1: approved by A
    2: approved by B
    3: approved by C
    4: confirmed by C
    */

    proposal[] public proposals;

    function register(uint _party, string _username) public {
        require(_party == 1 || _party == 2 || _party == 3);
        partyOf[msg.sender] = _party;
        usernames[msg.sender] = _username;
    }
    
    function getProposalsCount() public view returns(uint) {
        return proposals.length;
    }

    function create(string _title, string _content) public {
        require(partyOf[msg.sender] == 1);
        proposals.push(proposal(_title, _content, 1));
        balanceOf[msg.sender] += 1;
    }

    function approve(uint _id, string _content) public {
        // party A
        if (proposals[_id].status == 0) {
            require(partyOf[msg.sender] == 1);
            proposals[_id].status = 1;
        }
        // party B
        else if (proposals[_id].status == 1) {
            require(partyOf[msg.sender] == 2);
            proposals[_id].status = 2;
        }
        // party C
        else if (proposals[_id].status == 2) {
            require(partyOf[msg.sender] == 3);
            proposals[_id].status = 3;
        }
        // confirm by party C
        else if (proposals[_id].status == 3) {
            require(partyOf[msg.sender] == 3);
            proposals[_id].status = 4;
        }

        proposals[_id].content = _content;
        balanceOf[msg.sender] += 1;
    }

    function disapprove(uint _id, string _content) public {
        // party B
        if (proposals[_id].status == 1) {
            require(partyOf[msg.sender] == 2);
            proposals[_id].status = 0;
        }
        // party C
        if (proposals[_id].status == 2 || proposals[_id].status == 3) {
            require(partyOf[msg.sender] == 3);
            proposals[_id].status = 1;
        }

        proposals[_id].content = _content;
        balanceOf[msg.sender] -= 1;
    }
}