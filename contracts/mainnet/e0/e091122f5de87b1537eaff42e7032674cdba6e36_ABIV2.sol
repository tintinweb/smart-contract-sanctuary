pragma solidity 0.5.2;

import './Ownable.sol';
import './MemberCertificateV2.sol';

contract ABIV2 is Ownable{
    event NewMemberCertificate(address memberAddr, bytes32 name, uint validityDate);
    constructor() public{
    }

    function generateCertificate(bytes32 _name, uint _validityDate) public onlyOwner() returns(address){
        MemberCertificateV2 member = new MemberCertificateV2(_name, _validityDate);
        emit NewMemberCertificate(address(member), _name, _validityDate);
        return address(member);
    }
    
    function setName(address certificateAddr, bytes32 newName) onlyOwner() public {
        MemberCertificateV2 member = MemberCertificateV2(certificateAddr);
        member.setName(newName);
    }

    
    function setValidityDate(address certificateAddr, uint newValidityDate) onlyOwner() public{
        MemberCertificateV2 member = MemberCertificateV2(certificateAddr);
        member.setValidityDate(newValidityDate);
    }
}
/*
1. deploy contract admin

deploy admin 0.050054 * 5,5jt = 275ribu
deploy abi 0.080423 * 5,5jt = 443ribu
add abi to admin 0.004351 * 5,5jt = 25ribu
generate certificate 0.055407 * 5,5jt = 305ribu * 21 member = 6,4jt

7,148,000


V2
Deploy abi 0.018428 * 6jt = 110ribu
bikin member 0.009852 * 6jt = 60ribu
update tiap tahun 0.00074 * 6jt = 4,4ribu
incase mau set name 0.000739 * 6jt = 4,4ribu
*current gas price = 22 wei
*/