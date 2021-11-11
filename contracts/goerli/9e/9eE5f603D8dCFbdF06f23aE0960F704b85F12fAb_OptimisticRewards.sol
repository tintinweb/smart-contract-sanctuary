// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "../interfaces/IERC20.sol";
import "../interfaces/IVotingVault.sol";
import "../interfaces/ILockingVault.sol";
import "../libraries/Authorizable.sol";
import "../libraries/MerkleRewards.sol";
// 0x7e1DA0C8683cB527dF2F407b9163C29f84377E84
// This contract follows an optimistic reward model, an authorized address the 'proposer'
// can submit a new merkle root and after a delay it is set the new merkle root.
// Durning the period before the root is accepted governance can prevent the update
// by removing that proposed root and resetting the timer.

// We've chosen this model to allow rewards flexibility. Any replicable off-chain program
// which can be run and verified by governance and community members, can be the rewards
// algorithm followed by this contract.

contract OptimisticRewards is MerkleRewards, Authorizable, IVotingVault {
    // The optional pending root for this rewards contract
    bytes32 public pendingRoot;
    // The time the pending proposal root was proposed. Note always check for 0 here when using.
    uint256 public proposalTime;
    // The address with the power to propose new roots.
    address public proposer;
    // Defaults to one week
    uint256 public challengePeriod = 7 days;

    /// @notice Constructs this contract and sets state variables
    /// @param _governance The address which owns this contract and can reset other vars
    /// @param _startingRoot The starting merkle root for this contract
    /// @param _proposer The address which can propose new roots
    /// @param _revoker The address which can stop proposed roots
    /// @param _token The token in which rewards are paid
    /// @param _lockingVault The governance locking vault for this token
    constructor(
        address _governance,
        bytes32 _startingRoot,
        address _proposer,
        address _revoker,
        IERC20 _token,
        ILockingVault _lockingVault
    ) MerkleRewards(_startingRoot, _token, _lockingVault) {
        proposer = _proposer;
        _authorize(_revoker);
        setOwner(_governance);
    }

    /// @notice Two combined functions (1) check if the previous rewards are confirmed and if so post them
    ///         (2) propose rewards for the next period. By combining into one call we just need one regular maintenance
    ///         call instead of two.
    /// @param newRoot The merkle root of the proposed new rewards
    /// @dev NOTE - If called before a proposed root would take effect it will overwrite that root AND timestamp. Meaning
    ///             valid rewards may be delayed by a sloppy proposer sending a tx even a few minutes ahead of time.
    function proposeRewards(bytes32 newRoot) external {
        // First authorize the call
        require(msg.sender == proposer, "Not proposer");
        // Second check if a valid outstanding update can be propagated to allow people to claim
        if (
            // We check there is some update pending, no setting to zero
            pendingRoot != bytes32(0) &&
            proposalTime != 0 &&
            // Then we check enough time has passed
            block.timestamp > proposalTime + challengePeriod
        ) {
            // Set the root in the MerkleRewards contract
            rewardsRoot = pendingRoot;
        }
        // Update state
        pendingRoot = newRoot;
        proposalTime = block.timestamp;
    }

    /// @notice Attempts to load the voting power of a user via merkleProofs
    /// @param user The address we want to load the voting power of
    // @param blockNumber unused in this contract
    /// @param extraData Abi encoded vault balance merkle proof pair
    /// @return the number of votes
    function queryVotePower(
        address user,
        uint256,
        bytes calldata extraData
    ) external view override returns (uint256) {
        // Decode the extra data
        (uint256 totalGrant, bytes32[] memory proof) =
            abi.decode(extraData, (uint256, bytes32[]));
        // Hash the user plus the total grant amount
        bytes32 leafHash = keccak256(abi.encodePacked(user, totalGrant));

        // Verify the proof for this leaf
        require(
            MerkleProof.verify(proof, rewardsRoot, leafHash),
            "Invalid Proof"
        );

        // Return the total votes for the user
        // Note - If you want to set up a system where unclaimed rewards have preferential voting treatment
        //        it is quite easy to add a multiplier to these lines and it will achieve that.
        uint256 votes = totalGrant - claimed[user];
        return (votes);
    }

    /// @notice Allows a revoker to remove a rewards root. This is a spam vector given a malicious revoker,
    ///         with the only solution being governance removal of that authorized revoker.
    function challengeRewards() external onlyAuthorized {
        // Delete pending rewards
        pendingRoot = bytes32(0);
        proposalTime = 0;
    }

    /// @notice Allows changing the proposer by governance
    /// @param _proposer The new proposer address
    function setProposer(address _proposer) external onlyOwner {
        proposer = _proposer;
    }

    /// @notice Allows changing the proposal challenge period by governance
    /// @param _challengePeriod The new challenge period
    function setChallengePeriod(uint256 _challengePeriod) external onlyOwner {
        challengePeriod = _challengePeriod;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IVotingVault {
    /// @notice Attempts to load the voting power of a user
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    /// @param extraData Abi encoded optional extra data used by some vaults, such as merkle proofs
    /// @return the number of votes
    function queryVotePower(
        address user,
        uint256 blockNumber,
        bytes calldata extraData
    ) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface ILockingVault {
    /// @notice Deposits and delegates voting power to an address provided with the call
    /// @param fundedAccount The address to credit this deposit to
    /// @param amount The amount of token which is deposited
    /// @param firstDelegation First delegation address
    function deposit(
        address fundedAccount,
        uint256 amount,
        address firstDelegation
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner() {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner() {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner() {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILockingVault.sol";

contract MerkleRewards {
    // The merkle root with deposits encoded into it as hash [address, amount]
    // Assumed to be a node sorted tree
    bytes32 public rewardsRoot;
    // The token to pay out
    IERC20 public immutable token;
    // The historic user claims
    mapping(address => uint256) public claimed;
    // The locking gov vault
    ILockingVault public lockingVault;

    /// @notice Constructs the contract and sets state and immutable variables
    /// @param _rewardsRoot The root a keccak256 merkle tree with leaves which are address amount pairs
    /// @param _token The erc20 contract which will be sent to the people with claims on the contract
    /// @param _lockingVault The governance vault which this deposits to on behalf of users
    constructor(
        bytes32 _rewardsRoot,
        IERC20 _token,
        ILockingVault _lockingVault
    ) {
        rewardsRoot = _rewardsRoot;
        token = _token;
        lockingVault = _lockingVault;
        // We approve the locking vault so that it we can deposit on behalf of users
        _token.approve(address(lockingVault), type(uint256).max);
    }

    /// @notice Claims an amount of tokens which are in the tree and moves them directly into
    ///         governance
    /// @param amount The amount of tokens to claim
    /// @param delegate The address the user will delegate to, WARNING - should not be zero
    /// @param totalGrant The total amount of tokens the user was granted
    /// @param merkleProof The merkle de-commitment which proves the user is in the merkle root
    /// @param destination The address which will be credited with funds
    function claimAndDelegate(
        uint256 amount,
        address delegate,
        uint256 totalGrant,
        bytes32[] calldata merkleProof,
        address destination
    ) external {
        // No delegating to zero
        require(delegate != address(0), "Zero addr delegation");
        // Validate the withdraw
        _validateWithdraw(amount, totalGrant, merkleProof);
        // Deposit for this sender into governance locking vault
        lockingVault.deposit(destination, amount, delegate);
    }

    /// @notice Claims an amount of tokens which are in the tree and send them to the user
    /// @param amount The amount of tokens to claim
    /// @param totalGrant The total amount of tokens the user was granted
    /// @param merkleProof The merkle de-commitment which proves the user is in the merkle root
    /// @param destination The address which will be credited with funds
    function claim(
        uint256 amount,
        uint256 totalGrant,
        bytes32[] calldata merkleProof,
        address destination
    ) external {
        // Validate the withdraw
        _validateWithdraw(amount, totalGrant, merkleProof);
        // Transfer to the user
        token.transfer(destination, amount);
    }

    /// @notice Validate a withdraw attempt by checking merkle proof and ensuring the user has not
    ///         previously withdrawn
    /// @param amount The amount of tokens being claimed
    /// @param totalGrant The total amount of tokens the user was granted
    /// @param merkleProof The merkle de-commitment which proves the user is in the merkle root
    function _validateWithdraw(
        uint256 amount,
        uint256 totalGrant,
        bytes32[] memory merkleProof
    ) internal {
        // Hash the user plus the total grant amount
        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender, totalGrant));

        // Verify the proof for this leaf
        require(
            MerkleProof.verify(merkleProof, rewardsRoot, leafHash),
            "Invalid Proof"
        );
        // Check that this claim won't give them more than the total grant then
        // increase the stored claim amount
        require(claimed[msg.sender] + amount <= totalGrant, "Claimed too much");
        claimed[msg.sender] += amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
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
    ) internal pure returns (bool) {
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