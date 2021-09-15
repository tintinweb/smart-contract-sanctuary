/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
}

contract Certification {
    
    struct Certificate {
        string name;
        string issuer;
        string data;
        uint256 issuetime;
        uint256 validation;
    }
    
    mapping(bytes32 => Certificate) private certificates;
    address public owner;
    address public tokenCont;
    IERC20 tokenContract;
    event certificateGenerated(bytes32 _certificateId);
    
    constructor(address _contract) {
        tokenCont = _contract;
        tokenContract = IERC20(tokenCont);
        owner = msg.sender;
    }
    
    function withdrawToken(uint _amount) external returns (bool) {
        tokenContract.transfer(owner, _amount);
        return true;
    }
    
     function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }
    
    function generateCertificate(string memory _id, string memory _name, string memory _issuer, string memory _data, uint256 _issuetime, uint256 _validation) public {
        bytes32 byte_id = stringToBytes32(_id);
        require(certificates[byte_id].issuetime == 0, "Certificate with given id already exists");
        certificates[byte_id] = Certificate(_name,_issuer,_data,_issuetime,_validation);
        tokenContract.approve(address(this), 200);
        tokenContract.transferFrom(msg.sender,address(this), 200);
        emit certificateGenerated(byte_id);
    }
    
    function validateCertificate(string memory _id) public view returns(string memory,string memory,uint256,uint256){
        bytes32 byte_id = stringToBytes32(_id);
        Certificate memory temp = certificates[byte_id];
        require(temp.issuetime != 0, "No data exists");
        return (temp.name, temp.issuer, temp.issuetime, temp.validation);
    }
    
    function getCertificateData(string memory _id) public view returns(string memory){
        bytes32 byte_id = stringToBytes32(_id);
        Certificate memory temp = certificates[byte_id];
        require(temp.issuetime != 0, "No data exists");
        return (temp.data);
    }
}