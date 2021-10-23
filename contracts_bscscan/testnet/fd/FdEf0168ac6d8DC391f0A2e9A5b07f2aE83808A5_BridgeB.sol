pragma solidity ^0.8.9;
import "contracts/libraries/MerkleProof.sol";
interface IERC20 {
     function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(
    address recipient, 
    uint256 amount) 
    external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function mint(uint256 _value, address _beneficiary)  external ;
     function burn(uint256 _value, address _beneficiary)  external;
}

contract BridgeB {
    address private tokenB;
    address private gnosisAdd;
    mapping(bytes32=>bool) private rootArray;
    mapping(bytes32=>bool) private txClaim;
    event BurnTokens(bytes32  leaf, bytes txDetails);
    event MintTokens(address receiver,uint amountUnlocked,uint time);
    constructor(address tokB, address _gnosisSafe) {
        tokenB = tokB;
        gnosisAdd = _gnosisSafe;     
    }
    modifier gnosisSafeOnly(address caller) {
        require(caller==gnosisAdd,"Only GnosisSmartContract Account can call this function");
        _;
    }
     //test  only
    function checkBlockHeader(bytes32 root) external view gnosisSafeOnly(msg.sender)
     returns(bool) {
        return rootArray[root]; 
    }
 
   function checkTx(bytes32 TX) external view gnosisSafeOnly(msg.sender)
     returns(bool) {
        return txClaim[TX]; 
    }
    //test only
    
 
    //submitBlockHeader
    function submitBlockHeader(bytes32 root) external gnosisSafeOnly(msg.sender) {
        require(rootArray[root]==false,"this root already exists");
        rootArray[root] = true;
    }
    function burnTokens(address userFrom,uint amount) external {
        require(userFrom!=address(0),"please provide a valid chain address");
        require(amount>=0,"please specify a amount greater than 0");
        require(IERC20(tokenB).allowance(userFrom, address(this))>=amount,"please approve the bridge contract of the said amount.");

        IERC20(tokenB).burn(amount,userFrom);
        emit BurnTokens(keccak256(abi.encode(address(0),amount,block.timestamp)),abi.encode(address(0),amount,block.timestamp));
    }
    //tokenFunctionality
    function mintTokens(bytes32 root, bytes32[] memory proof, bytes memory leaf) external  {
            require(txClaim[keccak256(leaf)]==false,"tx already claimed");
            require(rootArray[root]==true,"this root is not a part our rootHeaders");
            //leaf is hash/encoding of receiving chain address and amount
             MerkleProof.verify(proof,root,keccak256(leaf));
             //tx is not claimed, root is in on chain root headers, use proof and leaf checks out, claim successful
             __mint(leaf);

    }
    function __mint(bytes memory arg) internal  {
        (address receiver, uint amountUnlocked,uint time) = abi.decode(arg,(address,uint,uint));
        txClaim[keccak256(arg)] = true;        
        IERC20(tokenB).mint(amountUnlocked,receiver);
        emit MintTokens(receiver, amountUnlocked,time);
        
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