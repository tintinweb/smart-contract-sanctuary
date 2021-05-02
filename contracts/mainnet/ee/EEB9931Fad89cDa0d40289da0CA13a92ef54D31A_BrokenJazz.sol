// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Signable.sol";

// Author: Francesco Sullo <[email protected]>
// BrokenJazz website: https://brokenjazz.cc

contract BrokenJazz is
ERC721URIStorage,
Signable
{

    constructor(
        address _oracle
    )
    ERC721("BrokenJazz", "BKJZ")
    Signable(_oracle)
    {}

    function claimToken(
        uint256 _tokenId,
        string memory _tokenURI,
        bytes memory _signature
    ) external
    {
        require(
            _tokenId > 0 && _tokenId < 55,
            "Invalid token ID"
        );
        require(
            isSignedByOracle(
                encodeForSignature(
                    msg.sender,
                    _tokenId,
                    _tokenURI
                ),
                _signature
            ),
            "Invalid signature"
        );

        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function encodeForSignature(
        address _address,
        uint _tokenId,
        string memory _tokenURI
    ) public pure
    returns (bytes32)
    {
        // EIP-191
        return keccak256(abi.encodePacked(
                "\x19\x00",
                _address,
                _tokenId,
                _tokenURI
            ));
    }

}