// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
// contract Creature is ERC721Tradable {
//     constructor(address _proxyRegistryAddress)
//         ERC721Tradable("Poker Card", "POKER", _proxyRegistryAddress)
//     {}

contract Creature {
    // function baseTokenURI() override public pure returns (string memory) {
    //     return "http://54.226.30.196:4001/";
    // }

    bytes5 _tokenPayloadHash1 = 0x622b109227;
    bytes5 _tokenPayloadHash2 = 0x7012f98e24;
    bytes5 _tokenPayloadHash3 = 0x1988284e72;

    function sliceBytes32To5(bytes32 input) public pure returns (bytes5 output) {
        assembly {
            output := input
        }
    }

    function dynamicVariable(string memory variableName) public pure returns (bytes5) {
        bytes memory data = abi.encodeWithSelector(
            bytes4(
                keccak256(abi.encodePacked(variableName))
            )
        );
        return abi.decode(data, (bytes5));
    }

    function compareHash(string memory _tokenPayload) public pure returns (string memory) {
        require(dynamicVariable("_tokenPayloadHash1") == sliceBytes32To5(keccak256(abi.encodePacked(_tokenPayload))), "not match");
        return "it is match!";
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
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