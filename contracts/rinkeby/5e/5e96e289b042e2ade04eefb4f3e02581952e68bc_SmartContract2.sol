/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity >0.8.0;
contract SmartContract2 {
     address private owner;
     uint private blocklock;
     uint constant BLOCK_HEIGHT =20;
     uint constant INFO_EVENT = 4;
    
    struct Document{
        string document_id;
        string document_name;
        string document_template;
        string document_value;
    }
     mapping(bytes32 => Document) public documents;
     
     event documentGenerated(bytes32 _documentid);
       event ChangeNotification(address indexed sender, uint status, bytes32 notificationMsg);
      
      function sendEvent(uint _status, bytes32 _notification) internal returns(bool) {
      
        return true;
    }
      
    
   
    
      modifier onlyBy(address _document) {
        if (msg.sender != _document) {
            revert();
        }
        _;
    }
    
    modifier checkBlockLock() {
        if (blocklock + BLOCK_HEIGHT > block.number) {
            revert();
        }
        _;
    }
    
     modifier blockLock() {
        blocklock = block.number;
        _;
    }
    
    struct Attribute {
        bytes32 hash;
        mapping(bytes32 => Endorsement) endorsements;
    }
    
    struct Endorsement {
        address endorser;
        bytes32 hash;
        bool accepted;
    }
     
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0*0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }
     function generateDocument(
        string memory _document_id,
        string  memory _document_name,
        string memory _document_template,
        string  memory _document_value) public {
            bytes32 byte_document_id = stringToBytes32(_document_id);
           documents[byte_document_id] = Document(_document_id, _document_name, _document_template, _document_value);
            emit documentGenerated(byte_document_id);
        }
          function getData(string memory _document_id) public view returns(string memory, string memory, string memory) {
         bytes32 byte_document_id = stringToBytes32(_document_id);
         Document memory temp = documents[byte_document_id];
          return (temp.document_name, temp.document_template, temp.document_value);
        
        }
  }