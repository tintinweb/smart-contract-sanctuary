// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IMirrorWriteRaceOracle} from "./interface/IMirrorWriteRaceOracle.sol";
import {InitializedGovernable} from "../lib/InitializedGovernable.sol";

/**
 * @title MirrorWriteRaceOracle
 * @author MirrorXYZ
 */
contract MirrorWriteRaceOracle is
    IMirrorWriteRaceOracle,
    InitializedGovernable
{
    /// @notice Merkle root
    bytes32 public root;

    constructor(
        address owner_,
        address governor_,
        bytes32 root_
    ) InitializedGovernable(owner_, governor_) {
        root = root_;
    }

    function updateRoot(bytes32 newRoot) public override onlyGovernance {
        root = newRoot;
    }

    /**
     * @notice verifies that an account has participated in the Write Race.
     * see: https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
     */
    function verify(
        address account,
        uint256 index,
        bytes32[] memory proof
    ) public view override returns (bool) {
        bytes32 computedHash = getNode(account, index);

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function getNode(address account, uint256 index)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, index));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IMirrorWriteRaceOracle
 * @author MirrorXYZ
 */
interface IMirrorWriteRaceOracle {
    event UpdatedRoot(bytes32 oldRoot, bytes32 newRoot);

    function updateRoot(bytes32 newRoot) external;

    function verify(
        address account,
        uint256 index,
        bytes32[] memory proof
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Ownable} from "../lib/Ownable.sol";
import {IGovernable} from "../lib/interface/IGovernable.sol";

contract InitializedGovernable is Ownable, IGovernable {
    // ============ Events ============

    event GovernorChanged(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    // ============ Mutable Storage ============

    // Mirror governance contract.
    address public override governor;

    // ============ Modifiers ============

    modifier onlyGovernance() {
        require(isOwner() || isGovernor(), "caller is not governance");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "caller is not governor");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_, address governor_) Ownable(owner_) {
        _setGovernor(governor_);
    }

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        _setGovernor(governor_);
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
    }

    // ============ Internal Functions ============

    function _setGovernor(address governor_) internal {
        emit GovernorChanged(governor, governor_);

        governor = governor_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernable {
    function changeGovernor(address governor_) external;

    function isGovernor() external view returns (bool);

    function governor() external view returns (address);
}

