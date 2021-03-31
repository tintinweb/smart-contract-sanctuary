/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity 0.6.7;

abstract contract MerkleDistributorFactoryLike {
    function nonce() external virtual returns (uint);
    function deployDistributor(bytes32 merkleRoot, uint256 tokenAmount) external virtual;
    function sendTokensToDistributor(uint256 id) external virtual;
    function sendTokensToCustom(address dst, uint256 tokenAmount) external virtual;
    function dropDistributorAuth(uint256 id) external virtual;
    function getBackTokensFromDistributor(uint256 id, uint256 tokenAmount) external virtual;
}

// Merkle Distribution Management proxy
// @notice: This contract should not be called directly, but instead be used by DSPause to delegatecall into
// @notice: Calling it directly will fail, DO NOT auth this contract in the distributionFactory.
contract MerkleDistributionManagement {

    function deployDistributor(
        address _merkleDistributorFactory,
        bytes32 _merkleRoot,
        uint256 _tokenAmount,
        bool    _sendTokens
    ) public {
        MerkleDistributorFactoryLike factory = MerkleDistributorFactoryLike(_merkleDistributorFactory);
        factory.deployDistributor(
            _merkleRoot, _tokenAmount
        );

        if (_sendTokens)
            factory.sendTokensToDistributor(factory.nonce());
    }

    function sendTokensToDistributor(
        address _merkleDistributorFactory,
        uint256 _id
    ) public {
        MerkleDistributorFactoryLike(_merkleDistributorFactory).sendTokensToDistributor(_id);
    }

    function sendTokensToCustom(
        address _merkleDistributorFactory,
        address _dst,
        uint256 _tokenAmount
    ) public {
        MerkleDistributorFactoryLike(_merkleDistributorFactory).sendTokensToCustom(_dst, _tokenAmount);
    }

    function dropDistributorAuth(
        address _merkleDistributorFactory,
        uint256 _id
    ) public {
        MerkleDistributorFactoryLike(_merkleDistributorFactory).dropDistributorAuth(_id);
    }

    function getBackTokensFromDistributor(
        address _merkleDistributorFactory,
        uint256 _id,
        uint256 _tokenAmount
    ) public {
        MerkleDistributorFactoryLike(_merkleDistributorFactory).getBackTokensFromDistributor(_id, _tokenAmount);
    }
}