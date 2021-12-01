// SPDX-License-Identifier: SimPL-2.0
pragma solidity  ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract CloudERC721Creature is ERC721Enumerable, Ownable {
    using ECDSA for *;

    constructor(address _owner, string memory _name, string memory _symbol)
        ERC721(_name, _symbol) ERC721Enumerable() Ownable() 
    {
        transferOwnership(_owner);
    }

    /**
        param: _to, mint to address
        param: _id, mint token id
        param: signature, signMessage(abi.encodePacked(NFTAddress, _to, _id))
     */
    function mintProxy(address _to, uint256 _id, bytes memory signature) public {
        bytes32 message = keccak256(abi.encodePacked(address(this), _to, _id));
        require(_verify(message, signature, owner()), "access error");
        _safeMint(_to, _id);
    }

    /**
        param: _toArray, to address array
        param: _idArray, tokenid to mint array
        param: signature, signMessage(abi.encodePacked(NFTAddress, _toArray, _idArray), owner)
     */
    function mintBatchProxy(address[] memory _toArray, uint256[] memory _idArray, bytes memory signature) public {
        require(_toArray.length == _idArray.length, "params error");

        bytes32 message = keccak256(abi.encodePacked(address(this), _toArray, _idArray));
        require(_verify(message, signature, owner()), "access error");

        for (uint i = 0; i < _toArray.length; i++) {
            _safeMint(_toArray[i], _idArray[i]);
        }
    }

    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
        return data
            .toEthSignedMessageHash()
            .recover(signature) == account;
    }

}