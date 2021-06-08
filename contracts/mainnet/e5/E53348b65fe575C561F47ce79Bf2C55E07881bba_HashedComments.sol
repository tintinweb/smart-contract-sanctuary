/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity 0.8.4;

contract HashedComments {
  event Thread (
    address indexed creator,
    bytes32 indexed id,
    string indexed iUrl,
    string url,
    string title,
    string content
  );
  event Comment (
    address indexed creator,
    bytes32 id,
    bytes32 indexed threadId,
    bytes32 indexed replyId,
    string content
  );

  function createThread(
    string memory url,
    string memory title,
    string memory content
  ) public {
    bytes32 id = keccak256(abi.encode(msg.sender, blockhash(block.number - 1)));
    emit Thread (
      msg.sender,
      id,
      url,
      url,
      title,
      content
    );
  }

  function createComment(
    bytes32  threadId,
    bytes32 replyId,
    string  memory content
  ) public {
    bytes32 id = keccak256(abi.encode(msg.sender, blockhash(block.number - 1)));
    emit Comment (
      msg.sender,
      id,
      threadId,
      replyId,
      content
    );
  }
}