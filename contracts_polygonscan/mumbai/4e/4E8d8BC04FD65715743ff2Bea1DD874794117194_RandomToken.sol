// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library RandomToken {

    function getRandomToken(address _mintAddress, uint256 _presents,
        string memory _externalTransactionId, uint256 _nonce, uint256 _modulus) public view returns (uint256) {

        uint256 _tokenId = (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    _mintAddress,
                    _presents,
                    _externalTransactionId,
                    _nonce
                )
            )
        ) % _modulus) + 1;

        return _tokenId;
    }
}