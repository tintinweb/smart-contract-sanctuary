// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library AdLibrary {
    struct Ad {
        address owner; // Lp/owner for this ad
        address tokenSource; // token address on the source side
        address tokenDest; // token address here (on the destination side)
        uint256 amount; // total amount of tokens
        uint256 fee; // fee in percentage basis points
    }

    function getAdHash(Ad memory _ad, uint256 _adId)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _ad.owner,
                    _ad.tokenSource,
                    _ad.tokenDest,
                    _ad.amount,
                    _ad.fee,
                    _adId
                )
            );
    }

    function getKey(bytes32 _adHash, address _user, uint _transferId) public pure returns(bytes memory) {
        return abi.encodePacked(_adHash, _user, _transferId);
    }

    function getValue(uint _amount) public pure returns (bytes memory) {
        return abi.encodePacked(_amount);
    }

    function keyHash(bytes memory _key) public pure returns (bytes32) {
        return keccak256(_key);
    }
}