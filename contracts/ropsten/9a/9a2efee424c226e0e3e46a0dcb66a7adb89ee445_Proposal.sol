pragma solidity ^0.4.25;

contract Proposal {
    
    mapping(address => uint) public balances;
    mapping(address => bool) public partyA;
    mapping(address => bool) public partyB;
    mapping(address => bool) public partyC;

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

    function register(uint _party) public {
        if (_party == 1) {
            partyA[msg.sender] = true;
        }
        if (_party == 2) {
            partyB[msg.sender] = true;
        }
        if (_party == 3) {
            partyC[msg.sender] = true;
        }       
    }
    
    function getProposalsCount() public view returns(uint) {
        return proposals.length;
    }

    function create(string _title, string _content) public {
        require(partyA[msg.sender]);
        proposals.push(proposal(_title, _content, 1));
        balances[msg.sender] += 1;
    }

    function approveByA(uint _id, string _content) public {
        require(partyA[msg.sender]);
        require(proposals[_id].status == 0);
        proposals[_id].status = 1;
        proposals[_id].content = _content;
        balances[msg.sender] += 1;
    }

    function approveByB(uint _id, string _content) public {
        require(partyB[msg.sender]);
        require(proposals[_id].status == 1);
        proposals[_id].status = 2;
        proposals[_id].content = _content;
        balances[msg.sender] += 1;
    }

    function disapproveByB(uint _id, string _content) public {
        require(partyB[msg.sender]);
        require(proposals[_id].status == 1 || proposals[_id].status == 2);
        proposals[_id].status = 0;
        proposals[_id].content = _content;
        balances[msg.sender] -= 1;
    }

    function approveByC(uint _id, string _content) public {
        require(partyC[msg.sender]);
        require(proposals[_id].status == 2);
        proposals[_id].status = 3;
        proposals[_id].content = _content;
        balances[msg.sender] += 1;
    }

    function disapproveByC(uint _id, string _content) public {
        require(partyC[msg.sender]);
        require(proposals[_id].status == 2 || proposals[_id].status == 3);
        proposals[_id].status = 1;
        proposals[_id].content = _content;
        balances[msg.sender] -= 1;
    }

    function confirmByC(uint _id, string _content) public {
        require(partyC[msg.sender]);
        require(proposals[_id].status == 3);
        proposals[_id].status = 4;
        proposals[_id].content = _content;
    }
}