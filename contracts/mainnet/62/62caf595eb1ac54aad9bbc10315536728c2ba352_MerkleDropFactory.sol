/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

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

library MerkleLib {

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}


contract MerkleDropFactory {
    using MerkleLib for bytes32;

    uint public numTrees = 0;

    address public management;
    address public treeAdder;

    struct MerkleTree {
        bytes32 merkleRoot;
        bytes32 ipfsHash;
        address tokenAddress;
        uint initialBalance;
        uint spentTokens;
    }

    mapping (address => mapping (uint => bool)) public withdrawn;
    mapping (uint => MerkleTree) public merkleTrees;

    event Withdraw(uint indexed merkleIndex, address indexed recipient, uint value);
    event MerkleTreeAdded(uint indexed index, address indexed tokenAddress, bytes32 newRoot, bytes32 ipfsHash);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address mgmt) {
        management = mgmt;
        treeAdder = mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) public managementOnly {
        management = newMgmt;
    }

    function setTreeAdder(address newAdder) public managementOnly {
        treeAdder = newAdder;
    }

    function addMerkleTree(bytes32 newRoot, bytes32 ipfsHash, address depositToken, uint initBalance) public {
        require(msg.sender == treeAdder, 'Only treeAdder can add trees');
        merkleTrees[++numTrees] = MerkleTree(
            newRoot,
            ipfsHash,
            depositToken,
            initBalance,
            0
        );
        emit MerkleTreeAdded(numTrees, depositToken, newRoot, ipfsHash);
    }

    function withdraw(uint merkleIndex, address walletAddress, uint value, bytes32[] memory proof) public {
        require(merkleIndex <= numTrees, "Provided merkle index doesn't exist");
        require(!withdrawn[walletAddress][merkleIndex], "You have already withdrawn your entitled token.");
        bytes32 leaf = keccak256(abi.encode(walletAddress, value));
        MerkleTree storage tree = merkleTrees[merkleIndex];
        require(tree.merkleRoot.verifyProof(leaf, proof), "The proof could not be verified.");
        withdrawn[walletAddress][merkleIndex] = true;
        require(IERC20(tree.tokenAddress).transfer(walletAddress, value), "ERC20 transfer failed");
        tree.spentTokens += value;
        emit Withdraw(merkleIndex, walletAddress, value);
    }

}