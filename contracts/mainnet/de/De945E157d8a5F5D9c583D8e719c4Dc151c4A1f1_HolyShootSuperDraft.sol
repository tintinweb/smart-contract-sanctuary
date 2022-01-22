// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

interface HolyShxxtLeague {
    function mint(address) external;
}

contract HolyShootSuperDraft is EIP712, Ownable {

    HolyShxxtLeague public constant holyShxxtLeague =
        HolyShxxtLeague(0xe93AAb5779e706c73DAf8Bf849bb8E46Fb183691);

    //for withdrawal
    address payable public constant holyShxxtWallet = payable(0x3606e8DDB3eacf871BaA5C5793534485e96ae498); 

    /**
        EIP712
     */
    bytes32 public constant GIVEAWAY_TYPEHASH =
        keccak256("SignGiveaway(address receiver,uint256 amount)");
    struct SignGiveaway {
        address receiver;
        uint256 amount;
    }

    bytes32 public constant ELITE_WHITELIST_TYPEHASH =
        keccak256("SignEliteWhitelist(address receiver,uint256 amount)");
    struct SignEliteWhitelist {
        address receiver;
        uint256 amount;
    }

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("SignWhitelist(address receiver,uint256 amount)");
    struct SignWhitelist {
        address receiver;
        uint256 amount;
    }

    /**
        Max HolyShxxt supply
     */
     uint256 public constant MAX_SUPPLY = 8888;

    /**
        Pause mint
    */
    bool public mintPaused = false;

    /**
        Giveaways
     */
    // minted through giveaway
    uint256 public numGiveaways = 0;
    // max giveaways for marketing
    uint256 public constant maxGiveaways = 50;     
    mapping(address => uint256) public giveawaysOf;

    /**
        Whitelists
     */
    // minted through elite whitelist
    uint256 public numEliteWhitelists = 0;
    // max elite whitelists
    uint256 public constant maxEliteWhitelists = 1000; //max 1000 elite whitelistes
    mapping(address => uint256) public eliteWhitelistsOf; 

    // minted through whitelist
    uint256 public numWhitelists = 0;
    // max whitelists
    uint256 public constant maxWhitelists = 6727; //max 6727 whitelists + 50 giveaways
    mapping(address => uint256) public whitelistsOf; 

    // minted through public sale
    uint256 public numPublicSale = 0;
    //max per mint in public sale
    uint256 public maxPerMint = 10;
    
    /**
        Scheduling
     */
    uint256 public elitesOpeningHours = 1642950000; // Sunday, January 23, 2022 3:00:00 PM GMT+0000
    uint256 public constant operationSecondsForElites = 3600 * 72; // 3 days

    uint256 public openingHours = 1644591600; // Friday, February 11, 2022 3:00:00 PM GMT+0000                     
    uint256 public constant operationSecondsForWhitelist = 3600 * 72; // 3 days

    /**
        Price
     */
    uint256 public constant eliteMintPrice = 0.1 ether;
    uint256 public constant whitelistMintPrice = 0.11 ether;
    uint256 public constant publicMintPrice = 0.13 ether;
    

    event SetElitesOpeningHours(uint256 elitesOpeningHours);
    event SetOpeningHours(uint256 openingHours);
    event MintWithGiveaway(address account, uint256 amount);
    event MintWithElitesWhitelist(address account, uint256 amount, uint256 changes);
    event MintWithWhitelist(address account, uint256 amount, uint256 changes);
    event MintHolyShxxt(address account, uint256 amount, uint256 changes);
    event Withdraw(address to);
    event MintPaused(bool mintPaused);
    event SetMaxPerMint(uint256 maxPerMint);

    constructor() EIP712("HolyShxxt", "1") {}

    modifier whenNotPaused() {
        require(
            !mintPaused,
            "Store is closed"
        );
        _;
    }

    modifier whenEliteWhitelistOpened() {
        require(
            block.timestamp >= elitesOpeningHours,
            "Store is not opened for elites and vips"
        );
        require(
            block.timestamp < elitesOpeningHours + operationSecondsForElites,
            "Store is closed for elites and vips"
        );
        _;
    }

    modifier whenWhitelistOpened() {
        require(
            block.timestamp >= openingHours,
            "Store is not opened for whitelist"
        );
        require(
            block.timestamp < openingHours + operationSecondsForWhitelist,
            "Store is closed for whitelist"
        );
        _;
    }

    modifier whenPublicOpened() {
        require(
            block.timestamp >= openingHours + operationSecondsForWhitelist,
            "Store is not opened"
        );
        _;
    }

    function setMintPaused(bool _mintPaused) external onlyOwner{
        mintPaused = _mintPaused;
        emit MintPaused(_mintPaused);
    }

    function setElitesOpeningHours(uint256 _elitesOpeningHours) external onlyOwner {
        elitesOpeningHours = _elitesOpeningHours;
        emit SetElitesOpeningHours(_elitesOpeningHours);
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        maxPerMint = _maxPerMint;
        emit SetMaxPerMint(_maxPerMint);
    }

    function mintByGiveaway(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external whenNotPaused whenWhitelistOpened {
        //giveaway mint happens during whitelist period
        uint256 myGiveaways = giveawaysOf[msg.sender];
        require(myGiveaways == 0, "Tsk tsk, not too greedy please");

        require(numGiveaways + _nftAmount <= maxGiveaways, "Max number of giveaways reached");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(GIVEAWAY_TYPEHASH, msg.sender, _nftAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        giveawaysOf[msg.sender] = _nftAmount; //update who has claimed their giveaways

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numGiveaways += _nftAmount;

        emit MintWithGiveaway(msg.sender, _nftAmount);
    }

    function mintByEliteWhitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenEliteWhitelistOpened {
        uint256 myEliteWhitelists = eliteWhitelistsOf[msg.sender];
        require(myEliteWhitelists == 0, "Tsk tsk, not too greedy please");

        require(numEliteWhitelists + _nftAmount <= maxEliteWhitelists, "Max number of whitelists reached");

        uint256 totalPrice = eliteMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(ELITE_WHITELIST_TYPEHASH, msg.sender, _nftAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        eliteWhitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numEliteWhitelists += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithElitesWhitelist(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function mintByWhitelist(
        uint256 _nftAmount,
        uint8 _vSig,
        bytes32 _rSig,
        bytes32 _sSig
    ) external payable whenNotPaused whenWhitelistOpened {
        uint256 myWhitelists = whitelistsOf[msg.sender];
        require(myWhitelists == 0, "Tsk tsk, not too greedy please");

        require(numWhitelists + _nftAmount <= maxWhitelists, "Max number of whitelists reached");

        uint256 totalPrice = whitelistMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, _nftAmount))
        );

        address signer = ecrecover(digest, _vSig, _rSig, _sSig);
        require(signer == owner(), "The signature is not from us, please check again");

        whitelistsOf[msg.sender] = _nftAmount; //update who has claimed their whitelists

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numWhitelists += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithWhitelist(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function publicMint(
        uint256 _nftAmount
    ) external payable whenNotPaused whenPublicOpened {
        require(_nftAmount <= maxPerMint, "Cannot exceed max nft per mint");

        require(numGiveaways + numEliteWhitelists + numWhitelists + numPublicSale + _nftAmount <= MAX_SUPPLY, "Max number of mintable reached");

        uint256 totalPrice = publicMintPrice * _nftAmount;
        require(totalPrice <= msg.value, "Not enough ETH");

        for (uint256 i = 0; i < _nftAmount; i++) {
            holyShxxtLeague.mint(msg.sender);
        }

        numPublicSale += _nftAmount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintHolyShxxt(msg.sender, _nftAmount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    // withdraw eth for sold HolyShxxt 
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        // Send eth to designated receiver
        emit Withdraw(holyShxxtWallet);

        holyShxxtWallet.transfer(balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
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

    /**
     * @dev Returns the domain separator for the current chain.
     */
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
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}