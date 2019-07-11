/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

// File: @ensdomains/ens/contracts/ENS.sol

pragma solidity >=0.4.24;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

// File: @ensdomains/ens/contracts/Deed.sol

pragma solidity >=0.4.24;

interface Deed {

    function setOwner(address payable newOwner) external;
    function setRegistrar(address newRegistrar) external;
    function setBalance(uint newValue, bool throwOnFailure) external;
    function closeDeed(uint refundRatio) external;
    function destroyDeed() external;

    function owner() external view returns (address);
    function previousOwner() external view returns (address);
    function value() external view returns (uint);
    function creationDate() external view returns (uint);

}

// File: @ensdomains/ens/contracts/Registrar.sol

pragma solidity >=0.4.24;


interface Registrar {

    enum Mode { Open, Auction, Owned, Forbidden, Reveal, NotYetAvailable }

    event AuctionStarted(bytes32 indexed hash, uint registrationDate);
    event NewBid(bytes32 indexed hash, address indexed bidder, uint deposit);
    event BidRevealed(bytes32 indexed hash, address indexed owner, uint value, uint8 status);
    event HashRegistered(bytes32 indexed hash, address indexed owner, uint value, uint registrationDate);
    event HashReleased(bytes32 indexed hash, uint value);
    event HashInvalidated(bytes32 indexed hash, string indexed name, uint value, uint registrationDate);

    function state(bytes32 _hash) external view returns (Mode);
    function startAuction(bytes32 _hash) external;
    function startAuctions(bytes32[] calldata _hashes) external;
    function newBid(bytes32 sealedBid) external payable;
    function startAuctionsAndBid(bytes32[] calldata hashes, bytes32 sealedBid) external payable;
    function unsealBid(bytes32 _hash, uint _value, bytes32 _salt) external;
    function cancelBid(address bidder, bytes32 seal) external;
    function finalizeAuction(bytes32 _hash) external;
    function transfer(bytes32 _hash, address payable newOwner) external;
    function releaseDeed(bytes32 _hash) external;
    function invalidateName(string calldata unhashedName) external;
    function eraseNode(bytes32[] calldata labels) external;
    function transferRegistrars(bytes32 _hash) external;
    function acceptRegistrarTransfer(bytes32 hash, Deed deed, uint registrationDate) external;
    function entries(bytes32 _hash) external view returns (Mode, address, uint, uint, uint);
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/BaseRegistrar.sol

pragma solidity >=0.4.24;





contract BaseRegistrar is IERC721, Ownable {
    uint constant public GRACE_PERIOD = 90 days;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    // Expiration timestamp for migrated domains.
    uint public transferPeriodEnds;

    // The ENS registry
    ENS public ens;

    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    // The interim registrar
    Registrar public previousRegistrar;

    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns(uint);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner, uint duration) external returns(uint);

    function renew(uint256 id, uint duration) external returns(uint);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;

    /**
     * @dev Transfers a registration from the initial registrar.
     * This function is called by the initial registrar when a user calls `transferRegistrars`.
     */
    function acceptRegistrarTransfer(bytes32 label, Deed deed, uint) external;
}

// File: contracts/StringUtils.sol

pragma solidity >=0.4.24;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            byte b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

// File: contracts/PriceOracle.sol

pragma solidity >=0.4.24;

interface PriceOracle {
    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return The price of this renewal or registration, in wei.
     */
    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}

// File: @ensdomains/buffer/contracts/Buffer.sol

pragma solidity >0.4.18;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library Buffer {
    /**
    * @dev Represents a mutable buffer. Buffers have a current value (buf) and
    *      a capacity. The capacity may be longer than the current value, in
    *      which case it can be extended without the need to allocate more memory.
    */
    struct buffer {
        bytes buf;
        uint capacity;
    }

    /**
    * @dev Initializes a buffer with an initial capacity.
    * @param buf The buffer to initialize.
    * @param capacity The number of bytes of space to allocate the buffer.
    * @return The buffer, for chaining.
    */
    function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
    * @dev Initializes a new buffer from an existing bytes object.
    *      Changes to the buffer may mutate the original value.
    * @param b The bytes object to initialize the buffer with.
    * @return A new buffer.
    */
    function fromBytes(bytes memory b) internal pure returns(buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
    * @dev Sets buffer length to 0.
    * @param buf The buffer to truncate.
    * @return The original buffer, for chaining..
    */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
    * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The start offset to write to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint dest;
        uint src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we&#39;re extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @param len The number of bytes to copy.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
    * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
    * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write the byte at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
    * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
    * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
    *      exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (left-aligned).
    * @return The original buffer, for chaining.
    */
    function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        // Right-align data
        data = data >> (8 * (32 - len));
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + sizeof(buffer length) + off + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
    * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
    *      capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chhaining.
    */
    function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
    * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer, for chaining.
    */
    function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
    * @dev Writes an integer to the buffer. Resizes if doing so would exceed
    *      the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param off The offset to write at.
    * @param data The data to append.
    * @param len The number of bytes to write (right-aligned).
    * @return The original buffer, for chaining.
    */
    function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

// File: @ensdomains/dnssec-oracle/contracts/BytesUtils.sol

pragma solidity >0.4.23;

library BytesUtils {
    /*
    * @dev Returns the keccak-256 hash of a byte range.
    * @param self The byte string to hash.
    * @param offset The position to start hashing at.
    * @param len The number of bytes to hash.
    * @return The hash of the byte range.
    */
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }


    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal.
    * @param self The first bytes to compare.
    * @param other The second bytes to compare.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, bytes memory other) internal pure returns (int) {
        return compare(self, 0, self.length, other, 0, other.length);
    }

    /*
    * @dev Returns a positive number if `other` comes lexicographically after
    *      `self`, a negative number if it comes before, or zero if the
    *      contents of the two bytes are equal. Comparison is done per-rune,
    *      on unicode codepoints.
    * @param self The first bytes to compare.
    * @param offset The offset of self.
    * @param len    The length of self.
    * @param other The second bytes to compare.
    * @param otheroffset The offset of the other string.
    * @param otherlen    The length of the other string.
    * @return The result of the comparison.
    */
    function compare(bytes memory self, uint offset, uint len, bytes memory other, uint otheroffset, uint otherlen) internal pure returns (int) {
        uint shortest = len;
        if (otherlen < len)
        shortest = otherlen;

        uint selfptr;
        uint otherptr;

        assembly {
            selfptr := add(self, add(offset, 32))
            otherptr := add(other, add(otheroffset, 32))
        }
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask;
                if (shortest > 32) {
                    mask = uint256(- 1); // aka 0xffffff....
                } else {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint diff = (a & mask) - (b & mask);
                if (diff != 0)
                return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }

        return int(len) - int(otherlen);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @param len The number of bytes to compare
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset, uint len) internal pure returns (bool) {
        return keccak(self, offset, len) == keccak(other, otherOffset, len);
    }

    /*
    * @dev Returns true if the two byte ranges are equal with offsets.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @param otherOffset The offset into the second byte range.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other, uint otherOffset) internal pure returns (bool) {
        return keccak(self, offset, self.length - offset) == keccak(other, otherOffset, other.length - otherOffset);
    }

    /*
    * @dev Compares a range of &#39;self&#39; to all of &#39;other&#39; and returns True iff
    *      they are equal.
    * @param self The first byte range to compare.
    * @param offset The offset into the first byte range.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, uint offset, bytes memory other) internal pure returns (bool) {
        return self.length >= offset + other.length && equals(self, offset, other, 0, other.length);
    }

    /*
    * @dev Returns true if the two byte ranges are equal.
    * @param self The first byte range to compare.
    * @param other The second byte range to compare.
    * @return True if the byte ranges are equal, false otherwise.
    */
    function equals(bytes memory self, bytes memory other) internal pure returns(bool) {
        return self.length == other.length && equals(self, 0, other, 0, self.length);
    }

    /*
    * @dev Returns the 8-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 8 bits of the string, interpreted as an integer.
    */
    function readUint8(bytes memory self, uint idx) internal pure returns (uint8 ret) {
        return uint8(self[idx]);
    }

    /*
    * @dev Returns the 16-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 16 bits of the string, interpreted as an integer.
    */
    function readUint16(bytes memory self, uint idx) internal pure returns (uint16 ret) {
        require(idx + 2 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 2), idx)), 0xFFFF)
        }
    }

    /*
    * @dev Returns the 32-bit number at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bits of the string, interpreted as an integer.
    */
    function readUint32(bytes memory self, uint idx) internal pure returns (uint32 ret) {
        require(idx + 4 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 4), idx)), 0xFFFFFFFF)
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }

    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes20(bytes memory self, uint idx) internal pure returns (bytes20 ret) {
        require(idx + 20 <= self.length);
        assembly {
            ret := and(mload(add(add(self, 32), idx)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000)
        }
    }

    /*
    * @dev Returns the n byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes.
    * @param len The number of bytes.
    * @return The specified 32 bytes of the string.
    */
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes32 ret) {
        require(len <= 32);
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)),  mask)
        }
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
    * @dev Copies a substring into a new byte string.
    * @param self The byte string to copy from.
    * @param offset The offset to start copying at.
    * @param len The number of bytes to copy.
    */
    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }

    // Maps characters from 0x30 to 0x7A to their base32 values.
    // 0xFF represents invalid characters in that range.
    bytes constant base32HexTable = hex&#39;00010203040506070809FFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1FFFFFFFFFFFFFFFFFFFFF0A0B0C0D0E0F101112131415161718191A1B1C1D1E1F&#39;;

    /**
     * @dev Decodes unpadded base32 data of up to one word in length.
     * @param self The data to decode.
     * @param off Offset into the string to start at.
     * @param len Number of characters to decode.
     * @return The decoded data, left aligned.
     */
    function base32HexDecodeWord(bytes memory self, uint off, uint len) internal pure returns(bytes32) {
        require(len <= 52);

        uint ret = 0;
        uint8 decoded;
        for(uint i = 0; i < len; i++) {
            bytes1 char = self[off + i];
            require(char >= 0x30 && char <= 0x7A);
            decoded = uint8(base32HexTable[uint(uint8(char)) - 0x30]);
            require(decoded <= 0x20);
            if(i == len - 1) {
                break;
            }
            ret = (ret << 5) | decoded;
        }

        uint bitlen = len * 5;
        if(len % 8 == 0) {
            // Multiple of 8 characters, no padding
            ret = (ret << 5) | decoded;
        } else if(len % 8 == 2) {
            // Two extra characters - 1 byte
            ret = (ret << 3) | (decoded >> 2);
            bitlen -= 2;
        } else if(len % 8 == 4) {
            // Four extra characters - 2 bytes
            ret = (ret << 1) | (decoded >> 4);
            bitlen -= 4;
        } else if(len % 8 == 5) {
            // Five extra characters - 3 bytes
            ret = (ret << 4) | (decoded >> 1);
            bitlen -= 1;
        } else if(len % 8 == 7) {
            // Seven extra characters - 4 bytes
            ret = (ret << 2) | (decoded >> 3);
            bitlen -= 3;
        } else {
            revert();
        }

        return bytes32(ret << (256 - bitlen));
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account&#39;s access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: contracts/ShortNameClaims.sol

pragma solidity ^0.5.0;







/**
 * @dev ShortNameClaims is a contract that permits people to register claims
 *      for short (3-6 character) ENS names ahead of the auction process.
 *
 *      Anyone with a DNS name registered before January 1, 2019, may use this
 *      name to support a claim for a matching ENS name. In the event that
 *      multiple claimants request the same name, the name will be assigned to
 *      the oldest registered DNS name.
 *
 *      Claims may be submitted by calling `submitExactClaim`,
 *      `submitCombinedClaim` or `submitPrefixClaim` as appropriate.
 *
 *      Claims require lodging a deposit equivalent to 365 days&#39; registration of
 *      the name. If the claim is approved, this deposit is spent, and the name
 *      is registered for the claimant for 365 days. If the claim is declined,
 *      the deposit will be returned.
 */
contract ShortNameClaims {
    using Roles for Roles.Role;

    uint constant public REGISTRATION_PERIOD = 31536000;

    using Buffer for Buffer.buffer;
    using BytesUtils for bytes;
    using StringUtils for string;

    enum Phase {
        OPEN,
        REVIEW,
        FINAL
    }

    enum Status {
        PENDING,
        APPROVED,
        DECLINED,
        WITHDRAWN
    }

    struct Claim {
        bytes32 labelHash;
        address claimant;
        uint paid;
        Status status;
    }

    Roles.Role owners;
    Roles.Role ratifiers;

    PriceOracle public priceOracle;
    BaseRegistrar public registrar;
    mapping(bytes32=>Claim) public claims;
    mapping(bytes32=>bool) approvedNames;
    uint public pendingClaims;
    uint public unresolvedClaims;
    Phase public phase;

    event ClaimSubmitted(string claimed, bytes dnsname, uint paid, address claimant, string email);
    event ClaimStatusChanged(bytes32 indexed claimId, Status status);

    constructor(PriceOracle _priceOracle, BaseRegistrar _registrar, address _ratifier) public {
        priceOracle = _priceOracle;
        registrar = _registrar;
        phase = Phase.OPEN;

        owners.add(msg.sender);
        ratifiers.add(_ratifier);
    }

    modifier onlyOwner() {
        require(owners.has(msg.sender), "Caller must be an owner");
        _;
    }

    modifier onlyRatifier() {
        require(ratifiers.has(msg.sender), "Caller must be a ratifier");
        _;
    }

    modifier inPhase(Phase p) {
        require(phase == p, "Not in required phase");
        _;
    }

    function addOwner(address owner) external onlyOwner {
        owners.add(owner);
    }

    function removeOwner(address owner) external onlyOwner {
        owners.remove(owner);
    }

    function addRatifier(address ratifier) external onlyRatifier {
        ratifiers.add(ratifier);
    }

    function removeRatifier(address ratifier) external onlyRatifier {
        ratifiers.remove(ratifier);
    }

    /**
     * @dev Computes the claim ID for a submitted claim, so it can be looked up
     *      using `claims`.
     * @param claimed The name being claimed (eg, &#39;foo&#39;)
     * @param dnsname The DNS-encoded name supporting the claim (eg, &#39;foo.test&#39;)
     * @param claimant The address making the claim.
     * @return The claim ID.
     */
    function computeClaimId(string memory claimed, bytes memory dnsname, address claimant, string memory email) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(keccak256(bytes(claimed)), keccak256(dnsname), claimant, keccak256(bytes(email))));
    }

    /**
     * @dev Returns the cost associated with placing a claim.
     * @param claimed The name being claimed.
     * @return The cost in wei for this claim.
     */
    function getClaimCost(string memory claimed) public view returns(uint) {
        return priceOracle.price(claimed, 0, REGISTRATION_PERIOD);
    }

    /**
     * @dev Submits a claim for an exact match (eg, foo.test -> foo.eth).
     *      Claimants must provide an amount of ether equal to 365 days&#39;
     *      registration cost; call `getClaimCost` to determine this amount.
     *      Claimants should supply a little extra in case of variation in price;
     *      any excess will be returned to the sender.
     * @param name The DNS-encoded name of the domain being used to support the
     *             claim.
     * @param claimant The address of the claimant.
     * @param email An email address for correspondence regarding the claim.
     */
    function submitExactClaim(bytes memory name, address claimant, string memory email) public payable {
        string memory claimed = getLabel(name, 0);
        handleClaim(claimed, name, claimant, email);
    }

    /**
     * @dev Submits a claim for match on name+tld (eg, foo.tv -> footv).
     *      Claimants must provide an amount of ether equal to 365 days&#39;
     *      registration cost; call `getClaimCost` to determine this amount.
     *      Claimants should supply a little extra in case of variation in price;
     *      any excess will be returned to the sender.
     * @param name The DNS-encoded name of the domain being used to support the
     *             claim.
     * @param claimant The address of the claimant.
     * @param email An email address for correspondence regarding the claim.
     */
    function submitCombinedClaim(bytes memory name, address claimant, string memory email) public payable {
        bytes memory firstLabel = bytes(getLabel(name, 0));
        bytes memory secondLabel = bytes(getLabel(name, 1));
        Buffer.buffer memory buf;
        buf.init(firstLabel.length + secondLabel.length);
        buf.append(firstLabel);
        buf.append(secondLabel);

        handleClaim(string(buf.buf), name, claimant, email);
    }

    /**
     * @dev Submits a claim for prefix match (eg, fooeth.test -> foo.eth).
     *      Claimants must provide an amount of ether equal to 365 days&#39;
     *      registration cost; call `getClaimCost` to determine this amount.
     *      Claimants should supply a little extra in case of variation in price;
     *      any excess will be returned to the sender.
     * @param name The DNS-encoded name of the domain being used to support the
     *             claim.
     * @param claimant The address of the claimant.
     * @param email An email address for correspondence regarding the claim.
     */
    function submitPrefixClaim(bytes memory name, address claimant, string memory email) public payable {
        bytes memory firstLabel = bytes(getLabel(name, 0));
        require(firstLabel.equals(firstLabel.length - 3, bytes("eth")));
        handleClaim(string(firstLabel.substring(0, firstLabel.length - 3)), name, claimant, email);
    }

    /**
     * @dev Closes the claim submission period.
     *      Callable only by the owner.
     */
    function closeClaims() external onlyOwner inPhase(Phase.OPEN) {
        phase = Phase.REVIEW;
    }

    /**
     * @dev Ratifies the current set of claims.
     *      Ratification freezes the claims and their resolutions, and permits
     *      them to be acted on.
     */
    function ratifyClaims() external onlyRatifier inPhase(Phase.REVIEW) {
        // Can&#39;t ratify until all claims have a resolution.
        require(pendingClaims == 0);
        phase = Phase.FINAL;
    }

    /**
     * @dev Cleans up the contract, after all claims are resolved.
     *      Callable only by the owner, and only in final state.
     */
    function destroy() external onlyOwner inPhase(Phase.FINAL) {
        require(unresolvedClaims == 0);
        selfdestruct(toPayable(msg.sender));
    }

    /**
     * @dev Sets the status of a claim to either APPROVED or DECLINED.
     *      Callable only during the review phase, and only by the owner or
     *      ratifier.
     * @param claimId The claim to set the status of.
     * @param approved True if the claim is approved, false if it is declined.
     */
    function setClaimStatus(bytes32 claimId, bool approved) public inPhase(Phase.REVIEW) {
        // Only callable by owner or ratifier
        require(owners.has(msg.sender) || ratifiers.has(msg.sender));

        Claim memory claim = claims[claimId];
        require(claim.paid > 0, "Claim not found");

        if(claim.status == Status.PENDING) {
          // Claim went from pending -> approved/declined; update counters
          pendingClaims--;
          unresolvedClaims++;
        } else if(claim.status == Status.APPROVED) {
          // Claim was previously approved; remove from approved map
          approvedNames[claim.labelHash] = false;
        }

        // Claim was just approved; check the name was not already used, and add
        // to approved map
        if(approved) {
          require(!approvedNames[claim.labelHash]);
          approvedNames[claim.labelHash] = true;
        }

        Status status = approved?Status.APPROVED:Status.DECLINED;
        claims[claimId].status = status;
        emit ClaimStatusChanged(claimId, status);
    }

    /**
     * @dev Sets the status of multiple claims. Callable only during the review
     *      phase, and only by the owner or ratifier.
     * @param approved A list of approved claim IDs.
     * @param declined A list of declined claim IDs.
     */
    function setClaimStatuses(bytes32[] calldata approved, bytes32[] calldata declined) external {
        for(uint i = 0; i < approved.length; i++) {
            setClaimStatus(approved[i], true);
        }
        for(uint i = 0; i < declined.length; i++) {
            setClaimStatus(declined[i], false);
        }
    }

    /**
     * @dev Resolves a claim. Callable by anyone, only in the final phase.
     *      Resolving a claim either registers the name or refunds the claimant.
     * @param claimId The claim ID to resolve.
     */
    function resolveClaim(bytes32 claimId) public inPhase(Phase.FINAL) {
        Claim memory claim = claims[claimId];
        require(claim.paid > 0, "Claim not found");

        if(claim.status == Status.APPROVED) {
            registrar.register(uint256(claim.labelHash), claim.claimant, REGISTRATION_PERIOD);
            toPayable(registrar.owner()).transfer(claim.paid);
        } else if(claim.status == Status.DECLINED) {
            toPayable(claim.claimant).transfer(claim.paid);
        } else {
            // It should not be possible to get to FINAL with claim IDs that are
            // not either APPROVED or DECLINED.
            assert(false);
        }

        unresolvedClaims--;
        delete claims[claimId];
    }

    /**
     * @dev Resolves multiple claims. Callable by anyone, only in the final phase.
     * @param claimIds A list of claim IDs to resolve.
     */
    function resolveClaims(bytes32[] calldata claimIds) external {
        for(uint i = 0; i < claimIds.length; i++) {
            resolveClaim(claimIds[i]);
        }
    }

    /**
     * @dev Withdraws a claim and refunds the claimant.
     *      Callable only by the claimant, at any time.
     * @param claimId The ID of the claim to withdraw.
     */
    function withdrawClaim(bytes32 claimId) external {
        Claim memory claim = claims[claimId];

        // Only callable by claimant
        require(msg.sender == claim.claimant);

        if(claim.status == Status.PENDING) {
            pendingClaims--;
        } else {
            unresolvedClaims--;
        }

        toPayable(claim.claimant).transfer(claim.paid);
        emit ClaimStatusChanged(claimId, Status.WITHDRAWN);
        delete claims[claimId];
    }

    function handleClaim(string memory claimed, bytes memory name, address claimant, string memory email) internal inPhase(Phase.OPEN) {
        uint len = claimed.strlen();
        require(len >= 3 && len <= 6);

        bytes32 claimId = computeClaimId(claimed, name, claimant, email);
        require(claims[claimId].paid == 0, "Claim already submitted");

        // Require that there are at most two labels (name.tld)
        require(bytes(getLabel(name, 2)).length == 0, "Name must be a 2LD");

        uint price = getClaimCost(claimed);
        require(msg.value >= price, "Insufficient funds for reservation");
        if(msg.value > price) {
            msg.sender.transfer(msg.value - price);
        }

        claims[claimId] = Claim(keccak256(bytes(claimed)), claimant, price, Status.PENDING);
        pendingClaims++;
        emit ClaimSubmitted(claimed, name, price, claimant, email);
    }

    function getLabel(bytes memory name, uint idx) internal pure returns(string memory) {
        // Skip the first `idx` labels
        uint offset = 0;
        for(uint i = 0; i < idx; i++) {
            if(offset >= name.length) return "";
            offset += name.readUint8(offset) + 1;
        }

        // Read the label we care about
        if(offset >= name.length) return &#39;&#39;;
        uint len = name.readUint8(offset);
        return string(name.substring(offset + 1, len));
    }

    function toPayable(address addr) internal pure returns(address payable) {
        return address(uint160(addr));
    }
}