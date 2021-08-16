// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Silhouettes {
	address private Owner = msg.sender;
	string private Name = 'Silhouettes';
	string private Symbol = 'SIL';
	uint256 Increment = 0;
	uint256 Fee = 0.002 ether;

	mapping(uint256 => PNG) private pngs;
	struct PNG{uint256 id; string hash; string tags; uint256 value; address owner;}
	event Uploaded(uint256 id, string hash, string tags, uint256 value, address owner);

	constructor() {}
	function upload(string memory _hash, string memory _tags) public payable {
		require(Owner != address(0));
		require(msg.value >= Fee);
		require(bytes(_hash).length > 0);
		require(bytes(_tags).length > 0);
		Increment++;
		pngs[Increment] = PNG(Increment, _hash, _tags, Fee, Owner);
		emit Uploaded(Increment, _hash, _tags, Fee, Owner);
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