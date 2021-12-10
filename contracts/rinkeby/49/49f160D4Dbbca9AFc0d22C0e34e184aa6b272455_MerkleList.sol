pragma solidity 0.8.6;


import "MerkleProofIndex.sol";
import "IJellyAccessControls.sol";
import "IJellyContract.sol";

/**
 * @notice TokenAllowList - Allow List that references a given `token` balance to return approvals.
 */
contract MerkleList is IJellyContract  {
 
    bytes32 public merkleRoot;
    string public merkleURI; 
    IJellyAccessControls public accessControls;

    /// @notice Jelly template id for the pool factory.
    uint256 public constant override TEMPLATE_TYPE = 6;
    bytes32 public constant override TEMPLATE_ID = keccak256("MERKLE_LIST");


    /// @notice Whether initialised or not.
    bool private initialised;

    constructor() {
    }

    /**
     * @notice Initializes token point list with reference token.
     * @param _merkleRoot Merkle Root
     */

    function initMerkleList(address _accessControls, bytes32 _merkleRoot, string memory _merkleURI) public {
        require(!initialised, "Already initialised");
        merkleRoot = _merkleRoot;
        merkleURI = _merkleURI;
        accessControls = IJellyAccessControls(_accessControls);
        initialised = true;
    }

    /**
     * @notice Updates Merkle Root.
     * @param _merkleRoot Merkle Root
     */
    function updateMerkle(bytes32 _merkleRoot, string memory _merkleURI) public {
        require(
            accessControls.hasAdminRole(msg.sender),
            "updateMerkle: Sender must be admin"
        );
        merkleRoot = _merkleRoot;
        merkleURI = _merkleURI;
    }


    /**
     * @notice Checks if account address is in the list (has any tokens).
     * @param _account Account address.
     * @return bool True or False.
     */
    function tokensClaimable(uint _index, address _account, uint256 _amount, bytes32[] calldata _merkleProof ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_index, _account, _amount));
        (bool valid, uint256 index) = MerkleProofIndex.verify(_merkleProof, merkleRoot, leaf);
        return valid;
    }



    function init(bytes calldata _data) external override payable {}

    function initContract(
        bytes calldata _data
    ) public override {
        (
        address _accessControls,
        bytes32 _merkleRoot, 
        string memory _merkleURI
        ) = abi.decode(_data, (address, bytes32, string));

        initMerkleList(
                       _accessControls,
                       _merkleRoot,
                       _merkleURI
                    );
    }

   /** 
     * @dev Generates init data for Farm Factory
  */
    function getInitData(
        address _accessControls,
        bytes32 _merkleRoot,
        string memory _merkleURI
    )
        external
        pure
        returns (bytes memory _data)
    {
        return abi.encode(
                        _accessControls,
                        _merkleRoot,
                        _merkleURI
                        );
    }


}

// SPDX-License-Identifier: MIT
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol

pragma solidity 0.8.6;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofIndex {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool, uint256) {
        bytes32 computedHash = leaf;
        uint256 index = 0;

        for (uint256 i = 0; i < proof.length; i++) {
            index *= 2;
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                index += 1;
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return (computedHash == root, index);
    }
}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function initAccessControls(address _admin) external ;

}

pragma solidity 0.8.6;

import "IMasterContract.sol";

interface IJellyContract is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.

    function TEMPLATE_ID() external view returns(bytes32);
    function TEMPLATE_TYPE() external view returns(uint256);
    function initContract( bytes calldata data ) external;

}

pragma solidity 0.8.6;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}