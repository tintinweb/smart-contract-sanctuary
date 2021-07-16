/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity ^0.8.4;

contract Issure {
    constructor() public {}

    struct Issure {
        string institution_name;
        string document_type;
        string document_name;
        string detailed_description;
        string effective_on_myL_from;
        string suported_on_myL_from;
        string define_documents_attributes;
        }
        
       mapping(bytes32 => Issure) public issure;
       event IssureAdded(bytes32 _issureId);
       function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
         assembly {
                result := mload(add(source, 32))
        }
    }
        function addIssure(
        string memory _id,
        string memory _institution_name,
        string memory _document_type, 
        string memory _document_name, 
        string memory _detailed_description,
        string memory _effective_on_myL_from,
        string memory _supported_on_myL_from,
        string memory _define_documents_attributes) public {
        bytes32 byte_id = stringToBytes32(_id);
        issure[byte_id] = Issure(_institution_name, _document_type, _document_name, _detailed_description, _effective_on_myL_from, _supported_on_myL_from, _define_documents_attributes);
        emit IssureAdded(byte_id);
        }
         function getData(string memory _id) public view returns(string memory, string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
         bytes32 byte_id = stringToBytes32(_id);
         Issure memory temp = issure[byte_id];
         }
         }