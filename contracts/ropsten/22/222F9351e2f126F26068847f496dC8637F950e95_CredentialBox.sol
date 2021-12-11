/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

abstract contract OwnerHelper {
    address private owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public {
        require(_to != owner);
        require(_to != address(0x0));
        address _from = owner;
        owner = _to;
        emit OwnerTransferPropose(_from, _to);
    }
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint256 private idCount;
    uint lastUpdated;
    mapping(uint8 => string) private vaccineEnum;

    struct Credential{
        uint256 id;
        address issuer;
        uint8 vaccineType;
        uint8 statusNumber;
        string value;
        uint256 createDate;
    }

    mapping(address => Credential) private credentials;

    constructor() {
   
        vaccineEnum[0] = "PFIZER";
        vaccineEnum[1] = "JANSSEN";
        vaccineEnum[2] = "MODERNA";
        vaccineEnum[3] = "ASTRAZENECA";
    }

    function claimCredential(address _vaccineAddress, uint8 _vaccineType, string calldata _value) onlyIssuer public returns(bool){
        Credential storage credential = credentials[_vaccineAddress];
        require(credentials[_vaccineAddress].id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.vaccineType = _vaccineType;
        credential.value = _value;
        credential.statusNumber = 1;
        credential.createDate = block.timestamp;

        idCount+=1;
        return true;
    }

    function checkCredential(address _vaccineAddress) public view returns (bool){ //백신접종 여부 확인
       
         if(credentials[_vaccineAddress].statusNumber >=1) return true;
         else return false;
    }

    function addVaccineType(uint8 _type, string calldata _value) onlyIssuer public returns (bool) { //백신 종류 추가
        require(bytes(vaccineEnum[_type]).length == 0);
        vaccineEnum[_type] = _value;
        return true;
    }

    function getVaccineType(uint8 _type) public view returns (string memory) { //타입번호 별 백신 종류 확인
        return vaccineEnum[_type];
    }

    function changeStatus(address _vaccineAddress) onlyIssuer public returns (bool){ //백신 접종 회차 추가
        require(credentials[_vaccineAddress].statusNumber >=1);
        credentials[_vaccineAddress].statusNumber += 1;
        return true;
    }

    function checkTwoWeeks(address _vaccineAddress) public view returns (bool) { //백신 접종 2주 경과 여부
         return ((block.timestamp-(credentials[_vaccineAddress].createDate)) > 2 weeks);
    }
    }