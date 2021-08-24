/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity =0.8.7;

contract EMS {
  // pki storage
  mapping(address => bytes32) public pki;

  // message event
  event Message(address indexed to, bool encrypted);

  // change public key
  function setPubKey (bytes32 pubKey) public {
    pki[msg.sender] = pubKey;
  }

  function sendMessage (address to, bytes memory data) public {
    emit Message(to, false);
  }

  function sendMessageEncrypted (address to, bytes memory data) public {
    bytes32 pubKey = pki[to];
    require(pubKey != 0);
    emit Message(to, true);
  }
}