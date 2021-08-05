/**
 *Submitted for verification at Etherscan.io on 2020-07-31
*/

pragma solidity >=0.6.0 <0.7.0;

contract UnchainedIndex {
  constructor () public {
      owner = msg.sender;
      indexHash = "QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH"; // empty file
  }

  function publishHash(string memory hash) public {
      require(msg.sender == owner, "msg.sender must be owner");
      indexHash = hash;
      emit HashPublished(hash);
  }

  event HashPublished(string hash);

  string indexHash;
  address owner;
}