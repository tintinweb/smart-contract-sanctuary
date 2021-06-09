/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract WGContract {

    address owner;

    mapping (address => bool) public membersMap;

    address[] public membersList;

    uint8 memberCount = 0;

    uint8 requiredApprovalCount;

    struct Submission {
        string imageHash;
        string description;
        address owner;
        uint8 numberOfApprovals;
    }

    mapping(string => Submission) public submissions;

    mapping(string => address[]) public approvals;

    mapping(address => string[]) public pendingSubmissionsForMember;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isMember() {
        require(membersMap[msg.sender] == true, "Caller is not member");
        _;
    }

    function addMember(address _newMember) public isOwner {
        membersMap[_newMember] = true;
        membersList.push(_newMember);
        memberCount ++;
    }

    function checkMembership(address _member) public returns (bool)  {
        return membersMap[_member];
    }

    function uploadSubmission(string memory _imageHash, string memory _description) public isMember {
        submissions[_imageHash].imageHash = _imageHash;
        submissions[_imageHash].description = _description;
        submissions[_imageHash].owner = msg.sender;
        submissions[_imageHash].numberOfApprovals = 0;
        for(uint i=0; i<memberCount; i++){
            if(membersList[i]!=msg.sender){
                pendingSubmissionsForMember[membersList[i]].push(_imageHash);
            }
        }
    }

    function getPendingSubmissions(address _member) public isMember returns (Submission[] memory){
        string[] memory pendingHashes = pendingSubmissionsForMember[_member];
        Submission[] memory pendingSubmissions = new Submission[](pendingHashes.length);
        for(uint i=0; i<pendingHashes.length; i++){
            pendingSubmissions[i] = submissions[pendingHashes[i]];
        }
        return pendingSubmissions;
    }

    // Cannot approve if already approved or is owner of submission
    function approveSubmission(string memory _hash) public isMember {
        bool hasApproved = false;
        for(uint i=0; i<approvals[_hash].length; i++){
            if(approvals[_hash][i]==msg.sender){
                hasApproved = true;
            }
        }
        if(!hasApproved && submissions[_hash].owner!=msg.sender){
            submissions[_hash].numberOfApprovals++;
            approvals[_hash].push(msg.sender);
            for(uint i=0; i<pendingSubmissionsForMember[msg.sender].length; i++){
                if(compareStrings(pendingSubmissionsForMember[msg.sender][i],_hash)){
                    pendingSubmissionsForMember[msg.sender][i] = pendingSubmissionsForMember[msg.sender][pendingSubmissionsForMember[msg.sender].length-1];
                    pendingSubmissionsForMember[msg.sender].pop();
                }
            }

            //if has collected enough approvals -> transfer EHRE and delete it
            if(submissions[_hash].numberOfApprovals==membersList.length-1){
                //TODO: transfer EHRE to owner of submission

                delete submissions[_hash];
                delete approvals[_hash];
            }
        }
    }

    // delete submission, approvals of submission and remove hash of image from pending submissions
    function denySubmission(string memory _hash) public isMember {
        bool canDeny = false;
        for(uint i=0; i<pendingSubmissionsForMember[msg.sender].length; i++){
            if(compareStrings(pendingSubmissionsForMember[msg.sender][i],_hash)){
                canDeny = true;
            }
        }

        if(canDeny){
            delete submissions[_hash];
            delete approvals[_hash];
            for(uint i=0; i<membersList.length; i++){
                for(uint j=0; j<pendingSubmissionsForMember[membersList[i]].length; j++){
                    if(compareStrings(pendingSubmissionsForMember[membersList[i]][j],_hash)){
                        pendingSubmissionsForMember[membersList[i]][j] = pendingSubmissionsForMember[membersList[i]][pendingSubmissionsForMember[membersList[i]].length-1];
                        pendingSubmissionsForMember[membersList[i]].pop();
                    }
                }
            }
        }
    }

    function compareStrings(string memory a, string memory b) private view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}