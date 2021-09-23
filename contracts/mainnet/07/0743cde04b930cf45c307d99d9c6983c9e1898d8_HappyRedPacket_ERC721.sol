/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]





/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts/proxy/utils/[email protected]



// solhint-disable-next-line compiler-version


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]





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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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


// File contracts/redpacket_erc721.sol



/**
 * @author          Mengjie Chen
 * @contact         [email protected]
 * @author_time     07/16/2021
 * @maintainer      Mengjie Chen
 * @maintain_time   07/30/2021
**/

pragma solidity >= 0.8.0;



contract HappyRedPacket_ERC721 is Initializable {

    struct RedPacket {
        address creator;
        uint16 remaining_tokens;
        address token_addr;
        uint32 end_time;
        mapping(address => uint256) claimed_list; 
        uint256[] erc721_list;
        address public_key;
        uint256 bit_status; //0 - available 1 - not available
    }

    event CreationSuccess (
        uint256 total_tokens,
        bytes32 indexed id,
        string name,
        string message,
        address indexed creator,
        uint256 creation_time,
        address token_address,
        uint256 packet_number,
        uint256 duration,
        uint256[] token_ids
    );

    event ClaimSuccess(
        bytes32 indexed id,
        address indexed claimer,
        uint256 claimed_token_id,
        address token_address
    );

    uint32 nonce;
    mapping(bytes32 => RedPacket) redpacket_by_id;
    bytes32 private seed;

    function initialize() public initializer {
        seed = keccak256(abi.encodePacked("Former NBA Commissioner David St", block.timestamp, msg.sender));
    }

    // Remember to call check_ownership() before create_red_packet()
    function check_ownership(uint256[] memory erc721_token_id_list, address token_addr) 
        external 
        view 
        returns(bool is_your_token)
    {
        is_your_token = true;
        for (uint256 i= 0; i < erc721_token_id_list.length; i ++){
            address owner = IERC721(token_addr).ownerOf(erc721_token_id_list[i]);
            if (owner != msg.sender){
                is_your_token = false;
                break;
            }
        }
        return is_your_token;
    }


    function create_red_packet (
        address _public_key,
        uint64 _duration,
        bytes32 _seed,
        string memory _message,
        string memory _name,
        address _token_addr,
        uint256[] memory _erc721_token_ids
    )
        external
    {
        nonce ++;
        require(_erc721_token_ids.length > 0, "At least 1 recipient");
        require(_erc721_token_ids.length <= 256, "At most 256 recipient");
        require(IERC721(_token_addr).isApprovedForAll(msg.sender, address(this)), "No approved yet");

        bytes32 packet_id = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce, seed, _seed));
        {
            RedPacket storage rp = redpacket_by_id[packet_id];
            rp.creator = msg.sender;
            rp.remaining_tokens = uint16(_erc721_token_ids.length);
            rp.token_addr = _token_addr;
            rp.end_time = uint32(block.timestamp + _duration);
            rp.erc721_list = _erc721_token_ids;
            rp.public_key = _public_key;
        }
        {
            uint256 number = _erc721_token_ids.length;
            uint256 duration = _duration;
            emit CreationSuccess (
                _erc721_token_ids.length, 
                packet_id, 
                _name,
                _message, 
                msg.sender, 
                block.timestamp, 
                _token_addr, 
                number, 
                duration, 
                _erc721_token_ids
            );
        }
    }

    function claim(bytes32 pkt_id, bytes memory signedMsg, address payable recipient)
        external 
        returns (uint256 claimed)
    {
        RedPacket storage rp = redpacket_by_id[pkt_id];
        uint256[] storage erc721_token_id_list = rp.erc721_list;
        require(rp.end_time > block.timestamp, "Expired"); 
        require(_verify(signedMsg, rp.public_key), "verification failed");
        uint16 remaining_tokens = rp.remaining_tokens;
        require(remaining_tokens > 0, "No available token remain");

        uint256 claimed_index;
        uint256 claimed_token_id;
        uint256 new_bit_status;
        uint16 new_remaining_tokens;
        (
            claimed_index, 
            claimed_token_id,
            new_bit_status, 
            new_remaining_tokens
        ) = _get_token_index(
            erc721_token_id_list, 
            remaining_tokens, 
            rp.token_addr, 
            rp.creator,
            rp.bit_status
        );

        rp.bit_status  = new_bit_status | (1 << claimed_index);
        rp.remaining_tokens = new_remaining_tokens - 1;

        // Penalize greedy attackers by placing duplication check at the very last
        require(rp.claimed_list[msg.sender] == 0, "Already claimed");
        rp.claimed_list[msg.sender] = claimed_token_id;
        address token_addr = rp.token_addr;
        IERC721(token_addr).safeTransferFrom(rp.creator, recipient, claimed_token_id);

        emit ClaimSuccess(pkt_id, address(recipient), claimed_token_id, token_addr);
        return claimed_token_id;
    }

    function check_availability(bytes32 pkt_id) 
        external
        view
        returns (
            address token_address,
            uint16 balance, 
            uint256 total_pkts,
            bool expired, 
            uint256 claimed_id,
            uint256 bit_status
        )
    {
        RedPacket storage rp = redpacket_by_id[pkt_id];
        return (
            rp.token_addr,
            rp.remaining_tokens,
            rp.erc721_list.length,
            block.timestamp > rp.end_time,
            rp.claimed_list[msg.sender],
            rp.bit_status
        );
    }

    function check_claimed_id(bytes32 id) 
        external 
        view 
        returns(uint256 claimed_token_id)
    {
        RedPacket storage rp = redpacket_by_id[id];
        claimed_token_id = rp.claimed_list[msg.sender];
        return(claimed_token_id);
    }

    function check_erc721_remain_ids(bytes32 id)
        external 
        view returns(uint256 bit_status, uint256[] memory erc721_token_ids)
    {
        RedPacket storage rp = redpacket_by_id[id];
        erc721_token_ids = rp.erc721_list;
        // use bit_status to get remained token id in erc_721_token_ids
        return(rp.bit_status, erc721_token_ids);
    }

//------------------------------------------------------------------
    // as a workaround for "CompilerError: Stack too deep, try removing local variables"
    function _verify(bytes memory signedMsg, address public_key) private view returns (bool verified) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n20";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msg.sender));
        address calculated_public_key = ECDSA.recover(prefixedHash, signedMsg);
        return (calculated_public_key == public_key);
    }

    function _get_token_index(
        uint256[] storage erc721_token_id_list,
        uint16 remaining_tokens,
        address token_addr,
        address creator,
        uint256 bit_status
    )
        private
        view
        returns(
            uint256 index,
            uint256 claimed_token_id,
            uint256 new_bit_status,
            uint16 new_remaining_tokens
        )
    {
        uint256 claimed_index = random(seed, nonce) % (remaining_tokens);
        uint16 real_index = _get_exact_index(bit_status, claimed_index);
        claimed_token_id = erc721_token_id_list[real_index];
        if(IERC721(token_addr).ownerOf(claimed_token_id) != creator){
            for (uint16 i = 0; i < erc721_token_id_list.length; i++) {
                if ((bit_status & (1 << i)) != 0) {
                    continue;
                }
                if (IERC721(token_addr).ownerOf(erc721_token_id_list[i]) != creator) {
                    // update bit map
                    bit_status = bit_status | (1 << i);
                    remaining_tokens--;
                    require(remaining_tokens > 0, "No available token remain");
                    continue;
                }else{
                    claimed_token_id = erc721_token_id_list[i];
                    real_index = i;
                    break;
                }
            }
        }
        return(real_index, claimed_token_id, bit_status, remaining_tokens);
    }

    function _get_exact_index(uint256 bit_status, uint256 claimed_index) 
        private 
        pure 
        returns (uint16 real_index)
    {
        uint16 real_count = 0;
        uint16 count = uint16(claimed_index + 1);
        while (count > 0){
            if ((bit_status & 1) == 0){
                count --;
            }
            real_count ++;
            bit_status = bit_status >> 1;  
        }
        
        return real_count - 1;
    }

    // A boring wrapper
    function random(bytes32 _seed, uint32 nonce_rand) internal view returns (uint256 rand) {
        return uint256(keccak256(abi.encodePacked(nonce_rand, msg.sender, _seed, block.timestamp))) + 1 ;
    }
}