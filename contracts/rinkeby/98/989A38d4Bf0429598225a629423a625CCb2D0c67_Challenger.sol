// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

contract AccessRestriction {
    address public owner;
    mapping(address => bytes32) private accessHash;

    modifier onlyOwner(){
        require(owner == msg.sender, "NOT_OWNER_CALL");
        _;
    }

    modifier onlyOwnerBy(address sender){
        require(owner == sender, "NOT_OWNER_CALL");
        _;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "NOT_CALLED_BY_RIGHT_ADDRESS");
        _;
    }

    modifier onlyByHash(bytes32 hash) {
        require(accessHash[owner] == hash, "NOT_RIGHT_HASH");
        _;
    }

    function getAccessHash() public view returns (bytes32)
    {
        return accessHash[msg.sender];
    }

    function getSender() external view returns (address)
    {
        return msg.sender;
    }

    constructor() public {
        owner = msg.sender;
        accessHash[owner] = keccak256(abi.encode(block.timestamp)); //todo generate truly random hash
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

import "./AccessRestriction.sol";

contract Challenger is AccessRestriction {

    function unlockChallenge() internal {}

    function submitData(bytes32 hash) onlyByHash(hash) external {

    }

    function getSenderHere() external view returns (address)
    {
        return msg.sender;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}