/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.7;

// Allows anyone to claim a token if they exist in a merkle root
abstract contract IMerkleDistributor {
    // Time from the moment this contract is deployed and until the owner can withdraw leftover tokens
    uint256 public constant timelapseUntilWithdrawWindow = 90 days;

    // Returns the address of the token distributed by this contract
    function token() virtual external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim
    function merkleRoot() virtual external view returns (bytes32);
    // Returns the timestamp when this contract was deployed
    function deploymentTime() virtual external view returns (uint256);
    // Returns the address for the owner of this contract
    function owner() virtual external view returns (address);
    // Returns true if the index has been marked claimed
    function isClaimed(uint256 index) virtual external view returns (bool);
    // Send tokens to an address without that address claiming them
    function sendTokens(address dst, uint256 tokenAmount) virtual external;
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) virtual external;

    // This event is triggered whenever an address is added to the set of authed addresses
    event AddAuthorization(address account);
    // This event is triggered whenever an address is removed from the set of authed addresses
    event RemoveAuthorization(address account);
    // This event is triggered whenever a call to #claim succeeds
    event Claimed(uint256 index, address account, uint256 amount);
    // This event is triggered whenever some tokens are sent to an address without that address claiming them
    event SendTokens(address dst, uint256 tokenAmount);
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract MerkleDistributor is IMerkleDistributor {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "MerkleDistributorFactory/account-not-authorized");
        _;
    }
    /*
    * @notify Checks whether an address can send tokens out of this contract
    */
    modifier canSendTokens {
        require(
          either(authorizedAccounts[msg.sender] == 1, both(owner == msg.sender, now >= addition(deploymentTime, timelapseUntilWithdrawWindow))),
          "MerkleDistributorFactory/cannot-send-tokens"
        );
        _;
    }

    // The token being distributed
    address public immutable override token;
    // The owner of this contract
    address public immutable override owner;
    // The merkle root of all addresses that get a distribution
    bytes32 public immutable override merkleRoot;
    // Timestamp when this contract was deployed
    uint256 public immutable override deploymentTime;

    // This is a packed array of booleans
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        authorizedAccounts[msg.sender] = 1;
        owner                          = msg.sender;
        token                          = token_;
        merkleRoot                     = merkleRoot_;
        deploymentTime                 = now;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MerkleDistributorFactory/add-uint-uint-overflow");
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Administration ---
    /*
    * @notice Send tokens to an authorized address
    * @param dst The address to send tokens to
    * @param tokenAmount The amount of tokens to send
    */
    function sendTokens(address dst, uint256 tokenAmount) external override canSendTokens {
        require(dst != address(0), "MerkleDistributorFactory/null-dst");
        IERC20(token).transfer(dst, tokenAmount);
        emit SendTokens(dst, tokenAmount);
    }

    /*
    * @notice View function returning whether an address has already claimed their tokens
    * @param index The position of the address inside the merkle tree
    */
    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
    /*
    * @notice Mark an address as having claimed their distribution
    * @param index The position of the address inside the merkle tree
    */
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
    /*
    * @notice Claim your distribution
    * @param index The position of the address inside the merkle tree
    * @param account The actual address from the tree
    * @param amount The amount being distributed
    * @param merkleProof The merkle path used to prove that the address is in the tree and can claim amount tokens
    */
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor/drop-already-claimed');

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor/invalid-proof');

        // Mark it claimed and send the token
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor/transfer-failed');

        emit Claimed(index, account, amount);
    }
}

contract MerkleDistributorFactory {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "MerkleDistributorFactory/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Number of distributors created
    uint256 public nonce;
    // The token that's being distributed by every merkle distributor
    address public distributedToken;
    // Mapping of ID => distributor address
    mapping(uint256 => address) public distributors;
    // Tokens left to distribute to every distributor
    mapping(uint256 => uint256) public tokensToDistribute;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DeployDistributor(uint256 id, address distributor, uint256 tokenAmount);
    event SendTokensToDistributor(uint256 id);

    constructor(address distributedToken_) public {
        require(distributedToken_ != address(0), "MerkleDistributorFactory/null-distributed-token");

        authorizedAccounts[msg.sender] = 1;
        distributedToken               = distributedToken_;

        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MerkleDistributorFactory/add-uint-uint-overflow");
    }

    // --- Core Logic ---
    /*
    * @notice Deploy a new merkle distributor
    * @param merkleRoot The merkle root used in the distributor
    */
    function deployDistributor(bytes32 merkleRoot, uint256 tokenAmount) external isAuthorized {
        require(tokenAmount > 0, "MerkleDistributorFactory/null-token-amount");
        nonce                     = addition(nonce, 1);
        address newDistributor    = address(new MerkleDistributor(distributedToken, merkleRoot));
        distributors[nonce]       = newDistributor;
        tokensToDistribute[nonce] = tokenAmount;
        emit DeployDistributor(nonce, newDistributor, tokenAmount);
    }
    /*
    * @notice Send tokens to a distributor
    * @param nonce The nonce/id of the distributor to send tokens to
    */
    function sendTokensToDistributor(uint256 id) external isAuthorized {
        require(tokensToDistribute[id] > 0, "MerkleDistributorFactory/nothing-to-send");
        uint256 tokensToSend = tokensToDistribute[id];
        tokensToDistribute[id] = 0;
        IERC20(distributedToken).transfer(distributors[id], tokensToSend);
        emit SendTokensToDistributor(id);
    }
    /*
    * @notice Sent distributedToken tokens out of this contract and to a custom destination
    * @param dst The address that will receive tokens
    * @param tokenAmount The token amount to send
    */
    function sendTokensToCustom(address dst, uint256 tokenAmount) external isAuthorized {
        require(dst != address(0), "MerkleDistributorFactory/null-dst");
        IERC20(distributedToken).transfer(dst, tokenAmount);
    }
    /*
    * @notice This contract gives up on being an authorized address inside a specific distributor contract
    */
    function dropDistributorAuth(uint256 id) external isAuthorized {
        MerkleDistributor(distributors[id]).removeAuthorization(address(this));
    }
    /*
    * @notice Send tokens from a distributor contract to this contract
    */
    function getBackTokensFromDistributor(uint256 id, uint256 tokenAmount) external isAuthorized {
        MerkleDistributor(distributors[id]).sendTokens(address(this), tokenAmount);
    }
}