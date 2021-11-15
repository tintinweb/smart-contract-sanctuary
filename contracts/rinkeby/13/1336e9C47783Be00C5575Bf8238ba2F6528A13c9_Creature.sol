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

    mapping (uint256 => bytes5) _tokenPayloadHashes;

    constructor(address _proxyRegistryAddress) {
        _tokenPayloadHashes[0] = 0x622b109227;
        _tokenPayloadHashes[1] = 0x7012f98e24;
        _tokenPayloadHashes[2] = 0x1988284e72;
    }

    function sliceBytes32To5(bytes32 input) public pure returns (bytes5 output) {
        assembly {
            output := input
        }
    }

    // function dynamicVariable(string memory variableName) public returns (bytes5) {
    //     (bool success, bytes memory data) = address(this).delegatecall(abi.encodeWithSelector(
    //         bytes4(keccak256(abi.encodePacked(variableName)))
    //     ));
    //     require(success, 'Call failed');
    //     return abi.decode(data, (bytes5));
    // }

    function compareHash(uint256 _tokenId, string memory _tokenPayload) public view returns (string memory) {
        require(_tokenPayloadHashes[_tokenId] == sliceBytes32To5(keccak256(abi.encodePacked(_tokenPayload))), "not match");
        return "it is match!";
    }
}

