// SPDX-License-Identifier: MIT   
pragma solidity^0.8.4;

contract PartyFactory{
    address[] listParty;

    function createParty (uint minimum) public {
        address newParty = address(new Party(minimum, msg.sender));
        listParty.push(newParty);
    }

    function getListParty () public view returns (address[] memory) {
        return listParty;
    }
}

contract Party{

    struct Request {
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint approvalCount;
        mapping(address=>bool) approvals;
    }
    uint index;
    mapping (uint => Request) requests;
    address public manager;
    uint public minimumContribution;
    mapping (address => bool) public approvers;
    uint public contributor;
    address[] memberList;

    constructor(uint contribution, address creator) public {
        manager = creator;
        minimumContribution = contribution;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
        if(!approvers[msg.sender]){
            contributor++;
        }
        approvers[msg.sender] = true;
        memberList.push(msg.sender);
    }

    function createRequest (string memory description, uint value, address payable recipient) public{
        Request storage r = requests[index++];
        r.description = description;
        r.value = value;
        r.recipient = recipient;
        r.complete = false;
        r.approvalCount = 0;
    }

    function approveRequest (uint indexRequest) public {

        Request storage request = requests[indexRequest];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);
        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint indexRequest) public restricted {
        Request storage request = requests[indexRequest];

        require(request.approvalCount > contributor/2);
        require(!request.complete);

        request.recipient.transfer(request.value);
        request.complete = true;
    }

    function getSummary() public view returns(uint, uint, uint, uint, address){
        return(
            minimumContribution,
            address(this).balance,
            index,
            contributor,
            manager
        );
    }

    function getRequestsCount() public view returns(uint) {
        return index;
    }
    function getMemberList() public view returns (address[] memory){
        return memberList;
    }

    modifier restricted {
        require(msg.sender == manager);
        _;
    }
}