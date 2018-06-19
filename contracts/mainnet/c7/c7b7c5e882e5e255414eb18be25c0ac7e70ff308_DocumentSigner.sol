pragma solidity ^0.4.15;

contract DocumentSigner {
    mapping(string => address[]) signatureMap;
    
    function sign(string _documentHash) public {
        signatureMap[_documentHash].push(msg.sender);
    }

    function getSignatureAtIndex(string _documentHash, uint _index) public constant returns (address) {
    	return signatureMap[_documentHash][_index];
    }

    function getSignatures(string _documentHash) public constant returns (address[]) {
    	return signatureMap[_documentHash];
    }
}