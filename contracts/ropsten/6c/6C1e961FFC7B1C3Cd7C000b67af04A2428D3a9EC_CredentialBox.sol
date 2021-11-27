/**
 *Submitted for verification at Etherscan.io on 2021-11-27
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
    	owner = _to;
    	emit OwnerTransferPropose(owner, _to);
  	}
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer {
        require(issuers[msg.sender] == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    int256 private idCount;
    mapping(int8 => string) private alumniEnum;
    mapping(int8 => string) private statusEnum;

    struct Credential{
        int256 id;
        address issuer;
        int8 alumniType;
        int8 statusType;
        string value;
        int256 expiredDate;
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        alumniEnum[0] = "SEB";
        alumniEnum[1] = "BEB";
        alumniEnum[2] = "AIB";
    }

    function claimCredential(address _alumniAddress, int8 _alumniType, string calldata _value) onlyIssuer public returns(bool){
        Credential storage credential = credentials[_alumniAddress];
        require(credential.id == 0);
        credential.id = idCount;
        credential.issuer = msg.sender;
        credential.alumniType = _alumniType;
        credential.statusType = 0;
        credential.value = _value;
        credential.expiredDate = 0;
        
        idCount += 1;

        return true;
    }

    function getCredential(address _alumniAddress) public view returns (Credential memory){
        return credentials[_alumniAddress];
    }

    function addAlumniType(int8 _type, string calldata _value) onlyIssuer public returns (bool) {
        require(bytes(alumniEnum[_type]).length != 0);
        alumniEnum[_type] = _value;
        return true;
    }

    function getAlumniType(int8 _type) public view returns (string memory) {
        return alumniEnum[_type];
    }

    function addStatusType(int8 _type, string calldata _value) onlyIssuer public returns (bool){
        require(bytes(statusEnum[_type]).length != 0);
        statusEnum[_type] = _value;
        return true;
    }

    function getStatusType(int8 _type) public view returns (string memory) {
        return statusEnum[_type];
    }

    function changeStatus(address _alumni, int8 _type) onlyIssuer public returns (bool) {
        require(credentials[_alumni].id != 0);
        require(bytes(statusEnum[_type]).length != 0);
        credentials[_alumni].statusType = _type;
        return true;
    }

}