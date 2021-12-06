// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 */
abstract contract Initializable {
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
library MerkleProofUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title CollabSplitterFactory
/// @author Simon Fremaux (@dievardump)
contract CollabSplitter is Initializable {
    event ETHClaimed(address operator, address account, uint256 amount);
    event ERC20Claimed(
        address operator,
        address account,
        uint256 amount,
        address token
    );

    struct ERC20Data {
        uint256 totalReceived;
        uint256 lastBalance;
    }

    // string public name;
    bytes32 public merkleRoot;

    // keeps track of how much was received in ETH since the start
    uint256 public totalReceived;

    // keeps track of how much an account already claimed ETH
    mapping(address => uint256) public alreadyClaimed;

    // keeps track of ERC20 data
    mapping(address => ERC20Data) public erc20Data;
    // keeps track of how much an account already claimed for a given ERC20
    mapping(address => mapping(address => uint256)) private erc20AlreadyClaimed;

    function initialize(bytes32 merkleRoot_) external initializer {
        merkleRoot = merkleRoot_;
    }

    receive() external payable {
        totalReceived += msg.value;
    }

    /// @notice Does claimETH and claimERC20 in one call
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1 = 100, 2.5 = 250 etc...
    /// @param merkleProof the merkle proof used to ensure this claim is legit
    /// @param erc20s the ERC20 contracts addresses to claim from
    function claimBatch(
        address account,
        uint256 percent,
        bytes32[] memory merkleProof,
        address[] memory erc20s
    ) public {
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                merkleRoot,
                getNode(account, percent)
            ),
            'Invalid proof.'
        );

        _claimETH(account, percent);

        for (uint256 i; i < erc20s.length; i++) {
            _claimERC20(account, percent, erc20s[i]);
        }
    }

    /// @notice Allows to claim the ETH for an account
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1 = 100, 2.5 = 250 etc...
    /// @param merkleProof the merkle proof used to ensure this claim is legit
    function claimETH(
        address account,
        uint256 percent,
        bytes32[] memory merkleProof
    ) public {
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                merkleRoot,
                getNode(account, percent)
            ),
            'Invalid proof.'
        );

        _claimETH(account, percent);
    }

    /// @notice Allows to claim an ERC20 for an account
    /// @dev To be able to do so, every time a claim is asked, we will compare both current and last known
    ///      balance for this contract, allowing to keep up to date on how much it has ever received
    ///      then we can calculate the full amount due to the account, and substract the amount already claimed
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1% = 100, 2.5% = 250 etc...
    /// @param merkleProof the merkle proof used to ensure this claim is legit
    /// @param erc20s the ERC20 contracts addresses to claim from
    function claimERC20(
        address account,
        uint256 percent,
        bytes32[] memory merkleProof,
        address[] memory erc20s
    ) public {
        require(
            MerkleProofUpgradeable.verify(
                merkleProof,
                merkleRoot,
                getNode(account, percent)
            ),
            'Invalid proof.'
        );

        for (uint256 i; i < erc20s.length; i++) {
            _claimERC20(account, percent, erc20s[i]);
        }
    }

    /// @notice Function to create the "node" in the merkle tree, given account and allocation
    /// @param account the account
    /// @param percent the allocation
    /// @return the bytes32 representing the node / leaf
    function getNode(address account, uint256 percent)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(account, percent));
    }

    /// @notice Helper allowing to know how much ETH is still claimable for a list of accounts
    /// @param accounts the account to check for
    /// @param percents the allocation for this account
    function getBatchClaimableETH(
        address[] memory accounts,
        uint256[] memory percents
    ) public view returns (uint256[] memory) {
        uint256[] memory claimable = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            claimable[i] = _calculateDue(
                totalReceived,
                percents[i],
                alreadyClaimed[accounts[i]]
            );
        }
        return claimable;
    }

    /// @notice Helper allowing to know how much of an ERC20 is still claimable for a list of accounts
    /// @param accounts the account to check for
    /// @param percents the allocation for this account
    /// @param token the token (ERC20 contract) to check on
    function getBatchClaimableERC20(
        address[] memory accounts,
        uint256[] memory percents,
        address token
    ) public view returns (uint256[] memory) {
        ERC20Data memory data = erc20Data[token];
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 sinceLast = balance - data.lastBalance;

        // the difference between last claim and today's balance is what has been received as royalties
        // so we can add it to the total received
        data.totalReceived += sinceLast;

        uint256[] memory claimable = new uint256[](accounts.length);
        for (uint256 i; i < accounts.length; i++) {
            claimable[i] = _calculateDue(
                data.totalReceived,
                percents[i],
                erc20AlreadyClaimed[accounts[i]][token]
            );
        }

        return claimable;
    }

    /// @notice Helper to query how much an account already claimed for a list of tokens
    /// @param account the account to check for
    /// @param tokens the tokens addresses
    ///        use address(0) to query for nativ chain token
    function getBatchClaimed(address account, address[] memory tokens)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory claimed = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) {
                claimed[i] = alreadyClaimed[account];
            } else {
                claimed[i] = erc20AlreadyClaimed[account][tokens[i]];
            }
        }

        return claimed;
    }

    /// @dev internal function to claim ETH
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1% = 100, 2.5% = 250 etc...
    function _claimETH(address account, uint256 percent) internal {
        if (totalReceived == 0) return;

        uint256 dueNow = _calculateDue(
            totalReceived,
            percent,
            alreadyClaimed[account]
        );

        if (dueNow == 0) return;

        // update the already claimed first, blocking reEntrancy
        alreadyClaimed[account] += dueNow;

        // send the due;
        // @TODO: .call{}() calls with all gas left in the tx
        // Question: Should we limit the gas used here?!
        // It has to be at least enough for contracts (Gnosis etc...) to proxy and store
        (bool success, ) = account.call{value: dueNow}('');
        require(success, 'Error when sending ETH');

        emit ETHClaimed(msg.sender, account, dueNow);
    }

    /// @dev internal function to claim an ERC20
    /// @param account the account we want to claim for
    /// @param percent the allocation for this account | 2 decimal basis, meaning 1% = 100, 2.5% = 250 etc...
    /// @param erc20 the ERC20 contract to claim from
    function _claimERC20(
        address account,
        uint256 percent,
        address erc20
    ) internal {
        ERC20Data storage data = erc20Data[erc20];
        uint256 balance = IERC20(erc20).balanceOf(address(this));
        uint256 sinceLast = balance - data.lastBalance;

        // the difference between last known balance and today's balance is what has been received as royalties
        // so we can add it to the total received
        data.totalReceived += sinceLast;

        // now we can calculate how much is due to current account the same way we do for ETH
        if (data.totalReceived == 0) return;

        uint256 dueNow = _calculateDue(
            data.totalReceived,
            percent,
            erc20AlreadyClaimed[account][erc20]
        );

        if (dueNow == 0) return;

        // update the already claimed first
        erc20AlreadyClaimed[account][erc20] += dueNow;

        // transfer the dueNow
        require(
            IERC20(erc20).transfer(account, dueNow),
            'Error when sending ERC20'
        );

        // update the lastBalance, so we can recalculate next time
        // we could save this call by doing (balance - dueNow) but some ERC20 might have weird behavior
        // and actually make the balance different than this after the transfer
        // so for safety, reading the actual state again
        data.lastBalance = IERC20(erc20).balanceOf(address(this));

        // emitting an event will allow to identify claimable ERC20 in TheGraph
        // to be able to display them in the UI and keep stats
        emit ERC20Claimed(msg.sender, account, dueNow, erc20);
    }

    /// @dev Helpers that calculates how much is still left to claim
    /// @param total total received
    /// @param percent allocation
    /// @param claimed what was already claimed
    /// @return what is left to claim
    function _calculateDue(
        uint256 total,
        uint256 percent,
        uint256 claimed
    ) internal pure returns (uint256) {
        return (total * percent) / 10000 - claimed;
    }
}