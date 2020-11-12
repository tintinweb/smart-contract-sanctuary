pragma solidity 0.5.2;

import './Ownable.sol';

contract MemberCertificateV2 is Ownable{
    address public creator;
    uint public validityDate;
    bytes32 public name;

    event ChangeName(bytes32 prevName, bytes32 newName);
    event ChangeValidityDate(uint prevValidityDate, uint newValidityDate);

    constructor(bytes32 _name, uint _validityDate) public{
        creator = msg.sender;
        name = _name;
        validityDate = _validityDate;
    }

    function setName(bytes32 newName) onlyOwner() public {
        bytes32 prevName = name;
        name = newName;
        emit ChangeName(prevName, name);
    }

    
    function setValidityDate(uint newValidityDate) onlyOwner() public{
        uint prevValidityDate = validityDate;
        validityDate = newValidityDate;
        emit ChangeValidityDate(prevValidityDate, validityDate);
    }

}