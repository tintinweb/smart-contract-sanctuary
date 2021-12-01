/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity ^0.8.0;

contract PRIVACYDOCUMENT {
  struct Document {
    string id;
    string content;
    string filename;
    string createdDate;
  }

  mapping(address => Document[]) Properties;   

  function addDocument(string memory _id, string memory _content, string memory _filename, string memory _createdDate) public returns (bool) {
    Document memory currentEntry;

    currentEntry.id = _id;
    currentEntry.content = _content;
    currentEntry.filename = _filename;
    currentEntry.createdDate = _createdDate;

    Properties[msg.sender].push(currentEntry);

    return true;
  }


  function getDocument(string memory _filename) public view returns (string memory id, string memory content, string memory filename, string memory createdDate) {

    for(uint i = 0; i < Properties[msg.sender].length;  i++) {
      if(compareStringsbyBytes(Properties[msg.sender][i].filename, _filename))
        return (Properties[msg.sender][i].id, Properties[msg.sender][i].content, Properties[msg.sender][i].filename, Properties[msg.sender][i].createdDate);
    }

    return ('', '', '', '');
  }

  function compareStringsbyBytes(string memory s1, string memory s2) internal pure returns(bool) {
    return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
  }
}