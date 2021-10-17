/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

pragma solidity ^0.5.0;

contract cert{

    struct cert_details{
        string name;
        string course;
        string school;
        uint date;
        address signer;
        bytes32 certid;
        bool isUsed;
    }
    
    mapping(address=>cert_details) certificates;
    mapping(bytes32=>cert_details) certificatesbyid;
    
    address owner;
    constructor() public {
        owner=msg.sender;
    }
    modifier ownerOnly{
        require(owner==msg.sender);
        _;
    }
    

    event certadded(string name,string course,string school,uint date,bytes32 certid);
    

    function viewlastcert(address sender) view public returns(string memory name,string memory course,string memory school,uint date,bytes32 certid){
        return (certificates[sender].name,certificates[sender].course,certificates[sender].school,certificates[sender].date,certificates[sender].certid);
    }

    function viewlastcertid(address sender) view public returns(bytes32 certid){
        return (certificates[sender].certid);
    }
    function viewcertbyid(bytes32 certid) view public returns(string memory name,string memory course,string memory school,uint date,address singer){
        return (certificatesbyid[certid].name,certificatesbyid[certid].course,certificatesbyid[certid].school,certificatesbyid[certid].date,certificatesbyid[certid].signer);
    }

    function verifyid(bytes32 certid) view public returns(bool isUsed) {
        return certificatesbyid[certid].isUsed;
    }
    
    function addcert(string memory name,string memory course,string memory school,uint date) public {
        bytes32 certid;
        certid=keccak256(abi.encodePacked(name,course,school,date,msg.sender));
        bool isUsed=true;
        certificates[msg.sender]=cert_details(name,course,school,date,msg.sender,certid,isUsed);
        certificatesbyid[certid]=cert_details(name,course,school,date,msg.sender,certid,isUsed);

    }
 }