/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity ^0.8.0;


/**

Buy The Floor 

Demand-side NFT exchange that allows buyers to make offchain blanket bids for NFTs based on type.  

*/

 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
 
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


/// @title ERC-721 Non-Fungible Token Standard
       /// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
       ///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
       interface ERC721 /* is ERC165 */ {
           /// @dev This emits when ownership of any NFT changes by any mechanism.
           ///  This event emits when NFTs are created (`from` == 0) and destroyed
           ///  (`to` == 0). Exception: during contract creation, any number of NFTs
           ///  may be created and assigned without emitting Transfer. At the time of
           ///  any transfer, the approved address for that NFT (if any) is reset to none.
           event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

           /// @dev This emits when the approved address for an NFT is changed or
           ///  reaffirmed. The zero address indicates there is no approved address.
           ///  When a Transfer event emits, this also indicates that the approved
           ///  address for that NFT (if any) is reset to none.
           event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

           /// @dev This emits when an operator is enabled or disabled for an owner.
           ///  The operator can manage all NFTs of the owner.
           event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

           /// @notice Count all NFTs assigned to an owner
           /// @dev NFTs assigned to the zero address are considered invalid, and this
           ///  function throws for queries about the zero address.
           /// @param _owner An address for whom to query the balance
           /// @return The number of NFTs owned by `_owner`, possibly zero
           function balanceOf(address _owner) external view returns (uint256);

           /// @notice Find the owner of an NFT
           /// @dev NFTs assigned to zero address are considered invalid, and queries
           ///  about them do throw.
           /// @param _tokenId The identifier for an NFT
           /// @return The address of the owner of the NFT
           function ownerOf(uint256 _tokenId) external view returns (address);

           /// @notice Transfers the ownership of an NFT from one address to another address
           /// @dev Throws unless `msg.sender` is the current owner, an authorized
           ///  operator, or the approved address for this NFT. Throws if `_from` is
           ///  not the current owner. Throws if `_to` is the zero address. Throws if
           ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
           ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
           ///  `onERC721Received` on `_to` and throws if the return value is not
           ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           /// @param data Additional data with no specified format, sent in call to `_to`
           function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

           /// @notice Transfers the ownership of an NFT from one address to another address
           /// @dev This works identically to the other function with an extra data parameter,
           ///  except this function just sets data to ""
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

           /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
           ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
           ///  THEY MAY BE PERMANENTLY LOST
           /// @dev Throws unless `msg.sender` is the current owner, an authorized
           ///  operator, or the approved address for this NFT. Throws if `_from` is
           ///  not the current owner. Throws if `_to` is the zero address. Throws if
           ///  `_tokenId` is not a valid NFT.
           /// @param _from The current owner of the NFT
           /// @param _to The new owner
           /// @param _tokenId The NFT to transfer
           function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

           /// @notice Set or reaffirm the approved address for an NFT
           /// @dev The zero address indicates there is no approved address.
           /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
           ///  operator of the current owner.
           /// @param _approved The new approved NFT controller
           /// @param _tokenId The NFT to approve
           function approve(address _approved, uint256 _tokenId) external payable;

           /// @notice Enable or disable approval for a third party ("operator") to manage
           ///  all of `msg.sender`'s assets.
           /// @dev Emits the ApprovalForAll event. The contract MUST allow
           ///  multiple operators per owner.
           /// @param _operator Address to add to the set of authorized operators.
           /// @param _approved True if the operator is approved, false to revoke approval
           function setApprovalForAll(address _operator, bool _approved) external;

           /// @notice Get the approved address for a single NFT
           /// @dev Throws if `_tokenId` is not a valid NFT
           /// @param _tokenId The NFT to find the approved address for
           /// @return The approved address for this NFT, or the zero address if there is none
           function getApproved(uint256 _tokenId) external view returns (address);

           /// @notice Query if an address is an authorized operator for another address
           /// @param _owner The address that owns the NFTs
           /// @param _operator The address that acts on behalf of the owner
           /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
           function isApprovedForAll(address _owner, address _operator) external view returns (bool);
       }

       interface ERC165 {
           /// @notice Query if a contract implements an interface
           /// @param interfaceID The interface identifier, as specified in ERC-165
           /// @dev Interface identification is specified in ERC-165. This function
           ///  uses less than 30,000 gas.
           /// @return `true` if the contract implements `interfaceID` and
           ///  `interfaceID` is not 0xffffffff, `false` otherwise
           function supportsInterface(bytes4 interfaceID) external view returns (bool);
       }

       interface ERC721TokenReceiver {
           /// @notice Handle the receipt of an NFT
           /// @dev The ERC721 smart contract calls this function on the
           /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
           /// of other than the magic value MUST result in the transaction being reverted.
           /// @notice The contract address is always the message sender.
           /// @param _operator The address which called `safeTransferFrom` function
           /// @param _from The address which previously owned the token
           /// @param _tokenId The NFT identifier which is being transferred
           /// @param _data Additional data with no specified format
           /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
           /// unless throwing
           function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
        }
        
        interface ProjectBasedNFT {
            function tokenIdToProjectId(uint256 tokenId) external returns(uint256);
        }



// ----------------------------------------------------------------------------

// Owned contract

// ----------------------------------------------------------------------------

contract Owned {

    address public owner;

    address public newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}



/*
ERC20 tokens must be approved to this contract ! 
Then, the buyer will perform an offchain metatx personalsign for their bid 

NFT must also be approved to this contract - setApprovalForAll
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */

contract BuyTheFloorExchange is Owned  {

  using SafeMath for uint;
  
  uint public _fee_pct=1;

    
  mapping (bytes32 => uint) public burnedSignatures; 
  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;

  bytes32 private immutable _HASHED_NAME;
  bytes32 private immutable _HASHED_VERSION;
  bytes32 private immutable _TYPE_HASH;
 
  constructor(string memory name, string memory version) {
    bytes32 hashedName = keccak256(bytes(name));
    bytes32 hashedVersion = keccak256(bytes(version));
    bytes32 typeHash = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    _HASHED_NAME = hashedName;
    _HASHED_VERSION = hashedVersion;
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    _TYPE_HASH = typeHash;
}

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
  
  event BuyTheFloor(address indexed bidderAddress, address indexed sellerAddress, address indexed nftContractAddress, uint256 tokenId, address currencyTokenAddress, uint currencyTokenAmount);
  event SignatureBurned(address indexed bidderAddress, bytes32 hash);
  
  struct BidPacket {
    address bidderAddress;
    address nftContractAddress;
    address currencyTokenAddress;
    uint256 currencyTokenAmount;
    bool requireProjectId;
    uint256 projectId;
    uint256 expires;
  }


  bytes32 constant BIDPACKET_TYPEHASH = keccak256(
      "BidPacket(address bidderAddress,address nftContractAddress,address currencyTokenAddress,uint256 currencyTokenAmount,bool requireProjectId,uint256 projectId,uint256 expires)"
  );



    function getBidPacketTypehash()  public pure returns (bytes32) {
      return BIDPACKET_TYPEHASH;
  }
  
  function getBidPacketHash(address bidderAddress,address nftContractAddress,address currencyTokenAddress, uint256 currencyTokenAmount,bool requireProjectId,uint256 projectId,uint256 expires) public pure returns (bytes32) {
          return keccak256(abi.encode(
              BIDPACKET_TYPEHASH,
              bidderAddress,
              nftContractAddress,
              currencyTokenAddress,
              currencyTokenAmount,
              requireProjectId,
              projectId,
              expires
          ));
      }

  function getBidTypedDataHash(address bidderAddress,address nftContractAddress,address currencyTokenAddress, uint256 currencyTokenAmount,bool requireProjectId,uint256 projectId,uint256 expires) public view returns (bytes32) {


              
              bytes32 digest = _hashTypedDataV4(keccak256(abi.encodePacked(
                  getBidPacketHash(bidderAddress,nftContractAddress,currencyTokenAddress,currencyTokenAmount,requireProjectId,projectId,expires)
              )));
              return digest;
          }
  

  //require pre-approval from the buyer in the form of a personal sign 
  function sellNFT(address nftContractAddress, uint256 tokenId, address from, address to, address currencyToken, uint256 currencyAmount, bool requireProjectId,uint256 projectId, uint256 expires, bytes memory signature) public returns (bool){
      
      //require personalsign from buyer to be submitted by seller  
      bytes32 sigHash = getBidTypedDataHash(to,nftContractAddress,currencyToken,currencyAmount,requireProjectId,projectId,expires);

      address recoveredSignatureSigner = ECDSA.recover(sigHash,signature);


      //make sure the signer is the depositor of the tokens
      require(to == recoveredSignatureSigner, 'Invalid signature');
      require(from == msg.sender, 'Not NFT Owner');
      
      
      require(block.number < expires || expires == 0, 'bid expired');
     
      require(burnedSignatures[sigHash] == 0, 'signature already used');
      burnedSignatures[sigHash] = 0x1;
      
      if(requireProjectId){
          require(ProjectBasedNFT(nftContractAddress).tokenIdToProjectId(tokenId) == projectId , 'Incorrect Project Id');
      }
      
      
      ERC721(nftContractAddress).safeTransferFrom(from, to, tokenId);
      
      _transferCurrencyForSale(from,to,currencyToken,currencyAmount);
      
      
      emit BuyTheFloor(to, from, nftContractAddress, tokenId, currencyToken, currencyAmount);
      emit SignatureBurned(to, sigHash);

      return true;
  }
  
  function _transferCurrencyForSale(address from, address to, address currencyToken, uint256 currencyAmount) internal returns (bool){
    uint256 feeAmount = currencyAmount.mul(_fee_pct).div(100);

    require( IERC20(currencyToken).transferFrom(to, from, currencyAmount.sub(feeAmount) ), 'unable to pay' );
    require( IERC20(currencyToken).transferFrom(to, owner, feeAmount ), 'unable to pay'  );
    
    return true;
  }
  
   
  function cancelBid(address nftContractAddress, address to, address currencyToken, uint256 currencyAmount,  bool requireProjectId, uint256 projectId, uint256 expires, bytes memory buyerSignature ) public returns (bool){
      bytes32 sigHash = getBidTypedDataHash(to,nftContractAddress,currencyToken,currencyAmount,requireProjectId,projectId,expires);
      address recoveredSignatureSigner = ECDSA.recover(sigHash,buyerSignature);
      
      require(to == recoveredSignatureSigner, 'Invalid signature');
      require(msg.sender == recoveredSignatureSigner, 'Not bid owner');
      require(burnedSignatures[sigHash]==0, 'Already burned');
      
      burnedSignatures[sigHash] = 0x2;
      emit SignatureBurned(to, sigHash);
      
      return true;
  }
  
  
  
}