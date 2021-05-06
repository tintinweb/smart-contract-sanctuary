/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.4.25;
contract CertificateNotary{
    address [] public registeredCertificate;
    event ContractCreated(address contractAddress);
    
function createCertificate(string _holdername, uint  _id, string _addresses, string _email, uint _number, uint _authorizedshare, uint _issueshare, uint _classname) public {
     address newMarriage = new Certificate(msg.sender, _holdername, _id, _addresses, _email, _number, _authorizedshare, _issueshare, _classname);
      emit ContractCreated(newMarriage);
    registeredCertificate.push(newMarriage);
    
}

function getDeployedCertificate() public view returns (address[]) {
 return registeredCertificate;
}
}
contract Certificate {
// Owner address
    address public owner;
    string public holdername;
    uint public id;
    string public addresses;
    string public email;
    uint public number;    
    uint public authorizedshare;
    uint public issueshare;
    uint public classname;
    constructor(address _owner, string _holdername, uint  _id,string _addresses,string  _email,uint _number,uint _authorizedshare, uint _issueshare, uint _classname) public {
        owner = _owner;
        holdername = _holdername;
        id = _id;
        addresses = _addresses;
        email = _email;
        number = _number; 
        authorizedshare = _authorizedshare;
        issueshare = _issueshare;
        classname = _classname;
    }
    function ringBell() public payable {
    require(msg.value > .0001 ether);
}
modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}
// To use a modifier, append it to the end of the function name
function collect() external onlyOwner {
    owner.transfer(address(this).balance);
}
function getBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
}


}