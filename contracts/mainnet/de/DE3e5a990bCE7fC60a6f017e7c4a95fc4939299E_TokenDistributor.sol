/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.6.12;



// Part: GTCErc20

/** 
 * @title - A retroactive ERC20 token distribution contract 
 * @author - [email protected]
 * @notice - Provided an EIP712 compliant signed message & token claim, distributes GTC tokens 
 **/

/**
* @notice interface for interacting with GTCToken delegate function
*/
interface GTCErc20 {
    function delegateOnDist(address, address) external;
}

// Part: OpenZeppelin/[email protected]/ECDSA

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/MerkleProof

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

// File: TokenDistributor.sol

contract TokenDistributor{ 
    
    address immutable public signer;
    address immutable public token; 
    uint immutable public deployTime;
    address immutable public timeLockContract;
    bytes32 immutable public merkleRoot;

    // hash of the domain separator
    bytes32 DOMAIN_SEPARATOR;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    
    // EIP712 domain struct 
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    // How long will this contract process token claims? 30 days
    uint public constant CONTRACT_ACTIVE = 30 days;

    // as required by EIP712, we create type hash that will be rolled up into the final signed message
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    // typehash for our token claim - matches the Claim struct  
    bytes32 constant GTC_TOKEN_CLAIM_TYPEHASH = keccak256(
        "Claim(uint32 user_id,address user_address,uint256 user_amount,address delegate_address,bytes32 leaf)"
    );
    
    // This event is triggered when a call to ClaimTokens succeeds.
    event Claimed(uint256 user_id, address account, uint256 amount, bytes32 leaf);

    // This event is triggered when unclaimed drops are moved to Timelock after CONTRACT_ACTIVE period 
    event TransferUnclaimed(uint256 amount);

    /**
     * @notice Construct a new TokenDistribution contract 
     * @param _signer - public key matching the private key that will be signing claims
     * @param _token - address of ERC20 that claims will be distributed from
     * @param _timeLock - address of the timelock contract where unclaimed funds will be swept   
     **/
    constructor(address _token, address _signer, address _timeLock, bytes32 _merkleRoot) public {
        signer = _signer;
        token = _token;
        merkleRoot = _merkleRoot;
        timeLockContract = _timeLock;
        deployTime = block.timestamp; 
        
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "GTC",
            version: '1.0.0',
            chainId: 1,
            verifyingContract: address(this)
        }));

    }
    
    /**
    * @notice process incoming token claims, must be signed by <signer>  
    * @param user_id - serves as nonce - only one claim per user_id
    * @param user_address - ethereum account token claim will be transfered too
    * @param user_amount - amount user will receive, in wei
    * @param delegate_address - address token claim will be deletaged too 
    * @param eth_signed_message_hash_hex - EIP712 pre-signed message hash payload
    * @param eth_signed_signature_hex = eth_sign style, EIP712 compliant, signed message
    * @param merkleProof - proof hashes for leaf
    * @param leaf - leaf hash for user claim in merkle tree    
    **/
    function claimTokens(
        uint32 user_id, 
        address user_address, 
        uint256 user_amount,
        address delegate_address, 
        bytes32 eth_signed_message_hash_hex, 
        bytes memory eth_signed_signature_hex,
        bytes32[] calldata merkleProof,
        bytes32 leaf

        ) external {

        // only accept claim if msg.sender address is in signed claim   
        require(msg.sender == user_address, 'TokenDistributor: Must be msg sender.');

        // one claim per user  
        require(!isClaimed(user_id), 'TokenDistributor: Tokens already claimed.');
        
        // claim must provide a message signed by defined <signer>  
        require(isSigned(eth_signed_message_hash_hex, eth_signed_signature_hex), 'TokenDistributor: Valid Signature Required.');
        
        bytes32 hashed_base_claim = keccak256(abi.encode( 
            GTC_TOKEN_CLAIM_TYPEHASH,
            user_id,
            user_address,
            user_amount, 
            delegate_address, 
            leaf
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashed_base_claim
        ));

        // can we reproduce the same hash from the raw claim metadata? 
        require(digest == eth_signed_message_hash_hex, 'TokenDistributor: Claim Hash Mismatch.');
        
        // can we repoduce leaf hash included in the claim?
        bytes32 leaf_hash = keccak256(abi.encode(keccak256(abi.encode(user_id, user_amount))));
        require(leaf == leaf_hash, 'TokenDistributor: Leaf Hash Mismatch.');

        // does the leaf exist on our tree? 
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'TokenDistributor: Valid Proof Required.');
        
        // process token claim !! 
        _delegateTokens(user_address, delegate_address); 
        _setClaimed(user_id);
   
        require(IERC20(token).transfer(user_address, user_amount), 'TokenDistributor: Transfer failed.');
        emit Claimed(user_id, user_address, user_amount, leaf);
    }
    
    /**
    * @notice checks claimedBitMap to see if if user_id is 0/1
    * @dev fork from uniswap merkle distributor, unmodified
    * @return - boolean  
    **/
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
    
    /**
    * @notice used to move any remaining tokens out of the contract after expiration   
    **/
    function transferUnclaimed() public {
        require(block.timestamp >= deployTime + CONTRACT_ACTIVE, 'TokenDistributor: Contract is still active.');
        // transfer all GTC to TimeLock
        uint remainingBalance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(timeLockContract, remainingBalance), 'TokenDistributor: Transfer unclaimed failed.');
        emit TransferUnclaimed(remainingBalance);
    }

    /**
    * @notice verify that a message was signed by the holder of the private keys of a given address
    * @return true if message was signed by signer designated on contstruction, else false 
    **/
    function isSigned(bytes32 eth_signed_message_hash_hex, bytes memory eth_signed_signature_hex) internal view returns (bool) {
        address untrusted_signer = ECDSA.recover(eth_signed_message_hash_hex, eth_signed_signature_hex);
        return untrusted_signer == signer;
    }

    /**
    * @notice - function can be used to create DOMAIN_SEPARATORs
    * @dev - from EIP712 spec, unmodified 
    **/
    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    /**
    * @notice Sets a given user_id to claimed 
    * @dev taken from uniswap merkle distributor, unmodified
    **/
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
    * @notice execute call on token contract to delegate tokens   
    */
    function _delegateTokens(address delegator, address delegatee) private {
         GTCErc20  GTCToken = GTCErc20(token);
         GTCToken.delegateOnDist(delegator, delegatee);
    } 
}