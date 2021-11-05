// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IPropertyValidator.sol";

contract RangePropertyValidator is IPropertyValidator {
    function checkBrokerAsset(uint256 tokenId, bytes calldata propertyData)
        external
        pure
        override
    {
        (uint256 tokenIdLowerBound, uint256 tokenIdUpperBound) = abi.decode(
            propertyData,
            (uint256, uint256)
        );
        require(
            tokenIdLowerBound <= tokenId && tokenId <= tokenIdUpperBound,
            "Token id out of range"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPropertyValidator {
    /// @dev Checks that the given asset data satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenId The ERC721 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function checkBrokerAsset(uint256 tokenId, bytes calldata propertyData)
        external
        view;
}