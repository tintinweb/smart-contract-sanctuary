// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingContract {

    function hasDepositsOrOwns(address owner, uint256[] memory tokenIds) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IStakingContract.sol";

/*
    ____  ____  ___    ____  _____   ________   __    _________    ____  __________  _____
   / __ \/ __ \/   |  / __ \/  _/ | / / ____/  / /   / ____/   |  / __ \/ ____/ __ \/ ___/
  / /_/ / / / / /| | / /_/ // //  |/ / / __   / /   / __/ / /| | / / / / __/ / /_/ /\__ \ 
 / _, _/ /_/ / ___ |/ _, _// // /|  / /_/ /  / /___/ /___/ ___ |/ /_/ / /___/ _, _/___/ / 
/_/ |_|\____/_/  |_/_/ |_/___/_/ |_/\____/  /_____/_____/_/  |_/_____/_____/_/ |_|/____/  
                                                                                          

I see you nerd! ⌐⊙_⊙
*/

contract RLBreedingManager is Ownable {
    using Counters for Counters.Counter;

    using ECDSA for bytes32;

    Counters.Counter private _breedingCounter;

    address public cubsContractAddress;

    uint256 public maxBreedingSupply = 5000;

    IStakingContract public roarStakingContractInstance;

    // Mapping of token numbers to last timestamp bred
    mapping(uint256 => uint256) public lastTimestamps;

    // Used to validate authorized mint addresses
    address private _signerAddress = 0xB44b7e7988A225F8C479cB08a63C04e0039B53Ff;

    uint256 public maleCooldown = 28 * 24 * 3600;
    uint256 public femaleCooldown = 3 * 24 * 3600;

    constructor() {
        //
    }

    function setAddresses(address newCubsContractAddress, address roarStakingAddress, address newSignerAddress) public onlyOwner {
        cubsContractAddress = newCubsContractAddress;
        roarStakingContractInstance = IStakingContract(roarStakingAddress);
        _signerAddress = newSignerAddress;
    }

    function setMaxBreedingSupply(uint256 newMaxBreedingSupply) public onlyOwner {
        maxBreedingSupply = newMaxBreedingSupply;
    }

    function setCooldowns(uint256 newMaleCooldown, uint256 newFemaleCooldown) public onlyOwner {
        maleCooldown = newMaleCooldown;
        femaleCooldown = newFemaleCooldown;
    }

    function currentBreedingCount() external view returns (uint256) {
        return _breedingCounter.current();
    }

    /**
     * @dev Throws if called by any account other than the cubs contract.
     */
    modifier onlyCubs() {
        require(cubsContractAddress == msg.sender, "Caller is not the cubs contract");
        _;
    }

    function hashCooldowns(uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature) public pure returns (bytes32) {
        return keccak256(abi.encode(
            maleTokenId,
            femaleTokenId,
            hasSignature
        ));
    }

    function hashListing(uint256 tokenId, uint256 rentalFee, uint256 expiry) public pure returns (bytes32) {
        return keccak256(abi.encode(
            tokenId,
            rentalFee,
            expiry
        ));
    }

    /*
    * Breed Roaring Leaders - both need to be owned by caller
    */
    function breedOwnLeaders(address ownerAddress, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, bytes memory signature) public onlyCubs {
        require(_breedingCounter.current() < maxBreedingSupply, "Max breeding supply");
        _breedingCounter.increment();
        
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = maleTokenId;
        tokenIds[1] = femaleTokenId;
        require(roarStakingContractInstance.hasDepositsOrOwns(ownerAddress, tokenIds), "Not owner");
        
        _verifyCooldowns(maleTokenId, femaleTokenId, hasSignature, instantCooldown, signature);
    }

    function breedUsingMarketplace(address ownerAddress, uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, address renter, bool acceptorIsMaleOwner, uint256 rentalFee, uint256 expiry, bytes memory cooldownSignature, bytes memory listingSignature) public onlyCubs {
        require(_breedingCounter.current() < maxBreedingSupply, "Max breeding supply");
        _breedingCounter.increment();
        require(expiry > block.timestamp, "Listing has expired");
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = maleTokenId;
        require(roarStakingContractInstance.hasDepositsOrOwns(acceptorIsMaleOwner ? ownerAddress : renter, tokenIds), "Not owner");
        tokenIds[0] = femaleTokenId;
        require(roarStakingContractInstance.hasDepositsOrOwns(acceptorIsMaleOwner ? renter : ownerAddress, tokenIds), "Not owner");
        
        _verifyCooldowns(maleTokenId, femaleTokenId, hasSignature, instantCooldown, cooldownSignature);

        require(renter == hashListing(acceptorIsMaleOwner ? femaleTokenId : maleTokenId, rentalFee, expiry).toEthSignedMessageHash().recover(listingSignature), "Invalid listing signature");
    }

    function _verifyCooldowns(uint256 maleTokenId, uint256 femaleTokenId, bool hasSignature, bool instantCooldown, bytes memory signature) internal {
        if (!instantCooldown) {
            require((lastTimestamps[maleTokenId] + maleCooldown < block.timestamp) && (lastTimestamps[femaleTokenId] + femaleCooldown < block.timestamp), "Cooldown not expired");
        }
        require(_signerAddress == hashCooldowns(maleTokenId, femaleTokenId, hasSignature).toEthSignedMessageHash().recover(signature), "Invalid cooldown signature");

        lastTimestamps[maleTokenId] = block.timestamp;
        lastTimestamps[femaleTokenId] = block.timestamp;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
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