/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Certificant{
    
    struct Cert {
        string enc_cert;
        string sm3_cert;
        bool exist;// 用来判断该证书是否存在
    }

    // 索引是证书编号
    mapping (string => Cert) certs;

    // 管理员账户
    mapping (address => bool) accounts;

    constructor(){
        accounts[0xEA56710f1E5b551e19Dba9155Ce93868503A59b1] = true;
        accounts[0x48e151a4a77ecA3859c4042c967B391C86688Ef0] = true;
        accounts[0x2C448f513ce9eaeECce3B13Fc8c36d976d6dA951] = true;
        accounts[0xEDe12c22fC58C4239a883938643F5B91a4426c14] = true;
        accounts[0xa71Cf314d862c21576CF2bf33d3B3E0D17d2c06B] = true;
    }

    modifier onlyAdmin(){
        require(accounts[msg.sender] == true, "Permission Denied");
        _;
    }

    modifier certExist(string memory id){
        require(certs[id].exist == true, "Certificate does not exist");
        _;
    }

    function store(string memory id, string memory enc_cert, string memory sm3_cert) public onlyAdmin {
        require(certs[id].exist != true, "Certificate already exists");
        certs[id].enc_cert = enc_cert;
        certs[id].sm3_cert = sm3_cert;
        certs[id].exist = true;
    }

    function revoke(string memory id) public onlyAdmin certExist(id) {
        delete(certs[id]);
    }

    function query(string memory id) public view certExist(id) returns(string memory){
        return certs[id].enc_cert;
    }

    function verify(string memory id, string memory sm3) public view certExist(id) returns(bool){
        if(keccak256(abi.encodePacked(sm3)) == keccak256(abi.encodePacked(certs[id].sm3_cert))){
            return true;
        }else{
            return false;
        }
    }
}