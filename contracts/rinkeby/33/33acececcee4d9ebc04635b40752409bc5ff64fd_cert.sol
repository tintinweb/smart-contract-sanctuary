/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.5.0;

contract cert{

    struct cert_details{
        string name;
        string course;
        string school;
        uint date;
        bytes32 certid;
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

    function viewcertbyid(bytes32 certid) view public returns(string memory name,string memory course,string memory school,uint date){
        return (certificatesbyid[certid].name,certificatesbyid[certid].course,certificatesbyid[certid].school,certificatesbyid[certid].date);
    }
   
    function addcert(string memory name,string memory course,string memory school,uint date) public {
        bytes32 certid;
        certid=keccak256(abi.encodePacked(name,course,school,date));
        certificates[msg.sender]=cert_details(name,course,school,date,certid);
        certificatesbyid[certid]=cert_details(name,course,school,date,certid);
    }       
 }