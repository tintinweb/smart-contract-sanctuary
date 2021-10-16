/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.5.0;

contract cert{

    struct cert_details{
        string name;
        string course;
        string school;
        string date;
        string certid;
    }
    
    mapping(address=>cert_details) certificates;
    
    address owner;
    constructor() public {
        owner=msg.sender;
    }
    modifier ownerOnly{
        require(owner==msg.sender);
        _;
    }
    

    event certadded(string name,string course,string school,string date,string certid);
    

    function viewcert(address sender) view public returns(string memory name,string memory course,string memory school,string memory date,string memory certid){
        return (certificates[sender].name,certificates[sender].course,certificates[sender].school,certificates[sender].date,certificates[sender].certid);
    }
    
    function addcert(string memory name,string memory course,string memory school,string memory date,string memory certid) public{
        certificates[msg.sender]=cert_details(name,course,school,date,certid);
     }
        
 }