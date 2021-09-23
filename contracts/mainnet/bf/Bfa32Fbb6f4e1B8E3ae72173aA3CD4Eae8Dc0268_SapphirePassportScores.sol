// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import {Adminable} from "../lib/Adminable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {Initializable} from "../lib/Initializable.sol";
import {SapphireTypes} from "./SapphireTypes.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";

contract SapphirePassportScores is ISapphirePassportScores, Adminable, Initializable {

    /* ========== Libraries ========== */

    using SafeMath for uint256;

    /* ========== Events ========== */

    event MerkleRootUpdated(
        address indexed updater,
        bytes32 merkleRoot,
        uint256 updatedAt
    );

    event PauseStatusUpdated(bool value);

    event DelayDurationUpdated(
        address indexed account,
        uint256 value
    );

    event PauseOperatorUpdated(
        address pauseOperator
    );

    event MerkleRootUpdaterUpdated(
        address merkleRootUpdater
    );

    /* ========== Variables ========== */

    /**
     * @dev Mapping of the epoch to a merkle root and its timestamp
     */
    mapping (uint256 => SapphireTypes.RootInfo) public rootsHistory;

    bool public isPaused;

    uint256 public merkleRootDelayDuration;

    address public merkleRootUpdater;

    address public pauseOperator;

    uint256 public currentEpoch;

    /* ========== Modifiers ========== */

    modifier onlyMerkleRootUpdater() {
        require(
            merkleRootUpdater == msg.sender,
            "SapphirePassportScores: caller is not authorized to update merkle root"
        );
        _;
    }

    modifier onlyWhenActive() {
        require(
            !isPaused,
            "SapphirePassportScores: contract is not active"
        );
        _;
    }

    /* ========== Init ========== */

    function init(
        bytes32 _merkleRoot,
        address _merkleRootUpdater,
        address _pauseOperator
    )
        public
        onlyAdmin
        initializer()
    {
        // Current Merkle root
        rootsHistory[currentEpoch] = SapphireTypes.RootInfo(
            _merkleRoot,
            currentTimestamp()
        );

        // Upcoming Merkle root
        rootsHistory[currentEpoch + 1].merkleRoot = _merkleRoot;

        merkleRootUpdater = _merkleRootUpdater;
        pauseOperator = _pauseOperator;
        isPaused = true;
        merkleRootDelayDuration = 86400; // 24 * 60 * 60 sec
    }

    /* ========== View Functions ========== */

    /**
     * @dev Returns current block's timestamp
     *
     * @notice This function is introduced in order to properly test time delays in this contract
     */
    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function lastMerkleRootUpdate()
        public
        view
        returns (uint256)
    {
        return rootsHistory[currentEpoch].timestamp;
    }

    function currentMerkleRoot()
        public
        view
        returns (bytes32)
    {
        return rootsHistory[currentEpoch].merkleRoot;
    }

    function upcomingMerkleRoot()
        external
        view
        returns (bytes32)
    {
        return rootsHistory[currentEpoch + 1].merkleRoot;
    }

    /* ========== Mutative Functions ========== */

    /**
     * @dev Update upcoming merkle root
     *
     * @notice Can be called by:
     *      - the admin:
     *          1. Check if contract is paused
     *          2. Replace upcoming merkle root
     *      - merkle root updater:
     *          1. Check if contract is active
     *          2. Replace current merkle root with upcoming merkle root
     *          3. Update upcoming one with passed Merkle root.
     *          4. Update the last merkle root update with the current timestamp
     *          5. Increment the `currentEpoch`
     *
     * @param _newRoot New upcoming merkle root
     */
    function updateMerkleRoot(
        bytes32 _newRoot
    )
        external
    {
        require(
            _newRoot != 0x0000000000000000000000000000000000000000000000000000000000000000,
            "SapphirePassportScores: root is empty"
        );

        if (msg.sender == getAdmin()) {
            updateMerkleRootAsAdmin(_newRoot);
        } else {
            updateMerkleRootAsUpdater(_newRoot);
        }
        emit MerkleRootUpdated(msg.sender, _newRoot, currentTimestamp());
    }

    /**
     * @notice Verifies the user's score proof against the current Merkle root.
     *         Reverts if the proof is invalid.
     *
     * @param _proof Data required to verify if score is correct for the current merkle root
     */
    function verify(
        SapphireTypes.ScoreProof memory _proof
    )
        public
        view
        returns (bool)
    {
        return verifyForEpoch(_proof, currentEpoch);
    }

    /**
     * @notice Verifies the user's score proof against the merkle root of the given epoch.
     *         Reverts if proof is invalid
     *
     * @param _proof Data required to verify if score is correct for the current merkle root
     * @param _epoch The epoch of the Merkle root to verify the proof against
     */
    function verifyForEpoch(
        SapphireTypes.ScoreProof memory _proof,
        uint256 _epoch
    )
        public
        view
        returns (bool)
    {
        require(
            _epoch <= currentEpoch,
            "SapphirePassportScores: cannot verify a proof in the future"
        );

        require(
            _proof.account != address(0),
            "SapphirePassportScores: account cannot be address 0"
        );

        bytes32 node = keccak256(abi.encodePacked(_proof.account, _proof.protocol, _proof.score));

        require(
            MerkleProof.verify(_proof.merkleProof, rootsHistory[_epoch].merkleRoot, node),
            "SapphirePassportScores: invalid proof"
        );

        // Return true to improve experience when interacting with this contract (ex. Etherscan)
        return true;
    }

     /* ========== Private Functions ========== */

    /**
     * @dev Merkle root updating strategy for merkle root updater
    **/
    function updateMerkleRootAsUpdater(
        bytes32 _newRoot
    )
        private
        onlyMerkleRootUpdater
        onlyWhenActive
    {
        require(
            currentTimestamp() >= merkleRootDelayDuration.add(lastMerkleRootUpdate()),
            "SapphirePassportScores: cannot update merkle root before delay period"
        );

        currentEpoch++;

        rootsHistory[currentEpoch].timestamp = currentTimestamp();
        rootsHistory[currentEpoch + 1].merkleRoot = _newRoot;
    }

    /**
     * @dev Merkle root updating strategy for the admin
    **/
    function updateMerkleRootAsAdmin(
        bytes32 _newRoot
    )
        private
        onlyAdmin
    {
        require(
            isPaused,
            "SapphirePassportScores: only admin can update merkle root if paused"
        );

        rootsHistory[currentEpoch + 1].merkleRoot = _newRoot;
    }

    /* ========== Admin Functions ========== */

    /**
     * @dev Update merkle root delay duration
    */
    function setMerkleRootDelay(
        uint256 _delay
    )
        external
        onlyAdmin
    {
        require(
            _delay > 0,
            "SapphirePassportScores: the delay must be greater than 0"
        );

        require(
            _delay != merkleRootDelayDuration,
            "SapphirePassportScores: the same delay is already set"
        );

        merkleRootDelayDuration = _delay;
        emit DelayDurationUpdated(msg.sender, _delay);
    }

    /**
     * @dev Pause or unpause contract, which cause the merkle root updater
     *      to not be able to update the merkle root
     */
    function setPause(
        bool _value
    )
        external
    {
        require(
            msg.sender == pauseOperator,
            "SapphirePassportScores: caller is not the pause operator"
        );

        require(
            _value != isPaused,
            "SapphirePassportScores: cannot set the same pause value"
        );

        isPaused = _value;
        emit PauseStatusUpdated(_value);
    }

    /**
     * @dev Sets the merkle root updater
    */
    function setMerkleRootUpdater(
        address _merkleRootUpdater
    )
        external
        onlyAdmin
    {
        require(
            _merkleRootUpdater != merkleRootUpdater,
            "SapphirePassportScores: cannot set the same merkle root updater"
        );

        merkleRootUpdater = _merkleRootUpdater;
        emit MerkleRootUpdaterUpdated(merkleRootUpdater);
    }

    /**
     * @dev Sets the pause operator
    */
    function setPauseOperator(
        address _pauseOperator
    )
        external
        onlyAdmin
    {
        require(
            _pauseOperator != pauseOperator,
            "SapphirePassportScores: cannot set the same pause operator"
        );

        pauseOperator = _pauseOperator;
        emit PauseOperatorUpdated(pauseOperator);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { Storage } from "./Storage.sol";

/**
 * @title Adminable
 * @author dYdX
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * Taken from OpenZeppelin
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SapphireTypes {

    struct ScoreProof {
        address account;
        bytes32 protocol;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 borrowedAmount;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        Operation operation;
        address userToLiquidate;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphirePassportScores {
    function updateMerkleRoot(bytes32 newRoot) external;

    function setMerkleRootUpdater(address merkleRootUpdater) external;

    /**
     * Reverts if proof is invalid
     */
    function verify(SapphireTypes.ScoreProof calldata proof) external view returns(bool);

    function setMerkleRootDelay(uint256 delay) external;

    function setPause(bool status) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}