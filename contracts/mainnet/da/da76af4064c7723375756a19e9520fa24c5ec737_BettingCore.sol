pragma solidity 0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="aacbd8cbc9c2c4c3ceeac4c5decec5de84c4cfde">[email&#160;protected]</a>>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a &#39;slice&#39;. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first &#39;.&#39;,
 *      modifying s to only contain the remainder of the string after the &#39;.&#39;.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew(&#39;.&#39;)` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */
library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
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
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string self) internal returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-termintaed utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal returns (slice ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice self) internal returns (slice) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice&#39;s text.
     */
    function toString(slice self) internal returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice self) internal returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice self) internal returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice self, slice other) internal returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        var selfptr = self._ptr;
        var otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                var diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice self, slice other) internal returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice self, slice rune) internal returns (slice) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint len;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            len = 1;
        } else if(b < 0xE0) {
            len = 2;
        } else if(b < 0xF0) {
            len = 3;
        } else {
            len = 4;
        }

        // Check for truncated codepoints
        if (len > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += len;
        self._len -= len;
        rune._len = len;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice self) internal returns (slice ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice self) internal returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        var b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice self) internal returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, length), sha3(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        var selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        var selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 68 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 69 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    ptr := add(selfptr, sub(selflen, needlelen))
                    loop:
                    jumpi(ret, eq(and(mload(ptr), mask), needledata))
                    ptr := sub(ptr, 1)
                    jumpi(loop, gt(add(ptr, 1), selfptr))
                    ptr := selfptr
                    jump(exit)
                    ret:
                    ptr := add(ptr, needlelen)
                    exit:
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice self, slice needle) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice self, slice needle) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice self, slice needle) internal returns (slice token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice self, slice needle) internal returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice self, slice needle) internal returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice self, slice other) internal returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice self, slice[] parts) internal returns (string) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for (uint i = 0; i < parts.length; i++) {
            length += parts[i]._len;
        }

        var ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
    * @dev give an address access to this role
    */
    function add(Role storage role, address addr) internal {
        role.bearer[addr] = true;
    }

    /**
    * @dev remove an address&#39; access to this role
    */
    function remove(Role storage role, address addr) internal {
        role.bearer[addr] = false;
    }

    /**
    * @dev check if an address has this role
    * // reverts
    */
    function check(Role storage role, address addr) view internal {
        require(has(role, addr));
    }

    /**
    * @dev check if an address has this role
    * @return bool
    */
    function has(Role storage role, address addr) view internal returns (bool) {
        return role.bearer[addr];
    }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 *      Supports unlimited numbers of roles and addresses.
 *      See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC is Ownable {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);

    /**
    * @dev constructor. Sets msg.sender as admin by default
    */
    function RBAC() public {
    }

    /**
    * @dev reverts if addr does not have role
    * @param addr address
    * @param roleName the name of the role
    * // reverts
    */
    function checkRole(address addr, string roleName) view public {
        roles[roleName].check(addr);
    }

    /**
    * @dev determine if addr has role
    * @param addr address
    * @param roleName the name of the role
    * @return bool
    */
    function hasRole(address addr, string roleName) view public returns (bool) {
        return roles[roleName].has(addr);
    }

    /**
    * @dev add a role to an address
    * @param addr address
    * @param roleName the name of the role
    */
    function adminAddRole(address addr, string roleName) onlyOwner public {
        roles[roleName].add(addr);
        RoleAdded(addr, roleName);
    }

    /**
    * @dev remove a role from an address
    * @param addr address
    * @param roleName the name of the role
    */
    function adminRemoveRole(address addr, string roleName) onlyOwner public {
        roles[roleName].remove(addr);
        RoleRemoved(addr, roleName);
    }

    /**
    * @dev modifier to scope access to a single role (uses msg.sender as addr)
    * @param roleName the name of the role
    * // reverts
    */
    modifier onlyRole(string roleName) {
        checkRole(msg.sender, roleName);
        _;
    }

    modifier onlyOwnerOr(string roleName) {
        require(msg.sender == owner || roles[roleName].has(msg.sender));
        _;
    }    
}

/**
 * @title Heritable
 * @dev The Heritable contract provides ownership transfer capabilities, in the
 * case that the current owner stops "heartbeating". Only the heir can pronounce the
 * owner&#39;s death.
 */
contract Heritable is RBAC {
  address private heir_;

  // Time window the owner has to notify they are alive.
  uint256 private heartbeatTimeout_;

  // Timestamp of the owner&#39;s death, as pronounced by the heir.
  uint256 private timeOfDeath_;

  event HeirChanged(address indexed owner, address indexed newHeir);
  event OwnerHeartbeated(address indexed owner);
  event OwnerProclaimedDead(address indexed owner, address indexed heir, uint256 timeOfDeath);
  event HeirOwnershipClaimed(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev Throw an exception if called by any account other than the heir&#39;s.
   */
  modifier onlyHeir() {
    require(msg.sender == heir_);
    _;
  }


  /**
   * @notice Create a new Heritable Contract with heir address 0x0.
   * @param _heartbeatTimeout time available for the owner to notify they are alive,
   * before the heir can take ownership.
   */
  function Heritable(uint256 _heartbeatTimeout) public {
    setHeartbeatTimeout(_heartbeatTimeout);
  }

  function setHeir(address newHeir) public onlyOwner {
    require(newHeir != owner);
    heartbeat();
    HeirChanged(owner, newHeir);
    heir_ = newHeir;
  }

  /**
   * @dev Use these getter functions to access the internal variables in
   * an inherited contract.
   */
  function heir() public view returns(address) {
    return heir_;
  }

  function heartbeatTimeout() public view returns(uint256) {
    return heartbeatTimeout_;
  }
  
  function timeOfDeath() public view returns(uint256) {
    return timeOfDeath_;
  }

  /**
   * @dev set heir = 0x0
   */
  function removeHeir() public onlyOwner {
    heartbeat();
    heir_ = 0;
  }

  /**
   * @dev Heir can pronounce the owners death. To claim the ownership, they will
   * have to wait for `heartbeatTimeout` seconds.
   */
  function proclaimDeath() public onlyHeir {
    require(ownerLives());
    OwnerProclaimedDead(owner, heir_, timeOfDeath_);
    timeOfDeath_ = block.timestamp;
  }

  /**
   * @dev Owner can send a heartbeat if they were mistakenly pronounced dead.
   */
  function heartbeat() public onlyOwner {
    OwnerHeartbeated(owner);
    timeOfDeath_ = 0;
  }

  /**
   * @dev Allows heir to transfer ownership only if heartbeat has timed out.
   */
  function claimHeirOwnership() public onlyHeir {
    require(!ownerLives());
    require(block.timestamp >= timeOfDeath_ + heartbeatTimeout_);
    OwnershipTransferred(owner, heir_);
    HeirOwnershipClaimed(owner, heir_);
    owner = heir_;
    timeOfDeath_ = 0;
  }

  function setHeartbeatTimeout(uint256 newHeartbeatTimeout) internal onlyOwner {
    require(ownerLives());
    heartbeatTimeout_ = newHeartbeatTimeout;
  }

  function ownerLives() internal view returns (bool) {
    return timeOfDeath_ == 0;
  }
}

contract BettingBase {
    enum BetStatus {
        None,
        Won
    }

    enum LineStages {
        OpenedUntilStart,
        ResultSubmitted,
        Cancelled,
        Refunded,
        Paid
    }    

    enum LineType {
        ThreeWay,
        TwoWay,
        DoubleChance,
        SomeOfMany
    }

    enum TwoWayLineType {
        Standart,
        YesNo,
        OverUnder,
        AsianHandicap,
        HeadToHead
    }

    enum PaymentType {
        No,
        Gain, 
        Refund
    }
}

contract AbstractBetStorage is BettingBase {
    function addBet(uint lineId, uint betId, address player, uint amount) external;
    function addLine(uint lineId, LineType lineType, uint start, uint resultCount) external;
    function cancelLine(uint lineId) external;
    function getBetPool(uint lineId, uint betId) external view returns (BetStatus status, uint sum);
    function getLineData(uint lineId) external view returns (uint startTime, uint resultCount, LineType lineType, LineStages stage);
    function getLineData2(uint lineId) external view returns (uint resultCount, LineStages stage);
    function getLineSum(uint lineId) external view returns (uint sum);
    function getPlayerBet(uint lineId, uint betId, address player) external view returns (uint result);
    function getSumOfPlayerBetsById(uint lineId, uint playerId, PaymentType paymentType) external view returns (address player, uint amount);
    function isBetStorage() external pure returns (bool);
    function setLineStartTime(uint lineId, uint time) external;    
    function startPayments(uint lineId, uint chunkSize) external returns (PaymentType paymentType, uint startId, uint endId, uint luckyPool, uint unluckyPool);
    function submitResult(uint lineId, uint[] results) external;
    function transferOwnership(address newOwner) public;
    function tryCloseLine(uint lineId, uint lastPlayerId, PaymentType paymentType) external returns (bool lineClosed);
}

contract BettingCore is BettingBase, Heritable {
    using SafeMath for uint;
    using strings for *;

    enum ActivityType{
        Soccer,
        IceHockey,
        Basketball,
        Tennis,
        BoxingAndMMA, 
        Formula1,               
        Volleyball,
        Chess,
        Athletics,
        Biathlon,
        Baseball,
        Rugby,
        AmericanFootball,
        Cycling,
        AutoMotorSports,        
        Other
    }    
    
    struct Activity {
        string title;
        ActivityType activityType;
    }

    struct Event {
        uint activityId;
        string title;
    }    

    struct Line {
        uint eventId;
        string title;
        string outcomes;
    }

    struct FeeDiscount {
        uint64 till;
        uint8 discount;
    }    

    // it&#39;s not possible to take off players bets
    bool public payoutToOwnerIsLimited;
    // total sum of bets
    uint public blockedSum; 
    uint public fee;
    uint public minBetAmount;
    string public contractMessage;
   
    Activity[] public activities;
    Event[] public events;
    Line[] private lines;

    mapping(address => FeeDiscount) private discounts;

    event NewActivity(uint indexed activityId, ActivityType activityType, string title);
    event NewEvent(uint indexed activityId, uint indexed eventId, string title);
    event NewLine(uint indexed eventId, uint indexed lineId, string title, LineType lineType, uint start, string outcomes);     
    event BetMade(uint indexed lineId, uint betId, address indexed player, uint amount);
    event PlayerPaid(uint indexed lineId, address indexed player, uint amount);
    event ResultSubmitted(uint indexed lineId, uint[] results);
    event LineCanceled(uint indexed lineId, string comment);
    event LineClosed(uint indexed lineId, PaymentType paymentType, uint totalPool);
    event LineStartTimeChanged(uint indexed lineId, uint newTime);

    AbstractBetStorage private betStorage;

    function BettingCore() Heritable(2592000) public {
        minBetAmount = 5 finney; // 0.005 ETH
        fee = 200; // 2 %
        payoutToOwnerIsLimited = true;
        blockedSum = 1 wei;
        contractMessage = "betdapp.co";
    }

    function() external onlyOwner payable {
    }

    function addActivity(ActivityType activityType, string title) external onlyOwnerOr("Edit") returns (uint activityId) {
        Activity memory _activity = Activity({
            title: title, 
            activityType: activityType
        });

        activityId = activities.push(_activity) - 1;
        NewActivity(activityId, activityType, title);
    }

    function addDoubleChanceLine(uint eventId, string title, uint start) external onlyOwnerOr("Edit") {
        addLine(eventId, title, LineType.DoubleChance, start, "1X_12_X2");
    }

    function addEvent(uint activityId, string title) external onlyOwnerOr("Edit") returns (uint eventId) {
        Event memory _event = Event({
            activityId: activityId, 
            title: title
        });

        eventId = events.push(_event) - 1;
        NewEvent(activityId, eventId, title);      
    }

    function addThreeWayLine(uint eventId, string title, uint start) external onlyOwnerOr("Edit") {
        addLine(eventId, title, LineType.ThreeWay, start,  "1_X_2");
    }

    function addSomeOfManyLine(uint eventId, string title, uint start, string outcomes) external onlyOwnerOr("Edit") {
        addLine(eventId, title, LineType.SomeOfMany, start, outcomes);
    }

    function addTwoWayLine(uint eventId, string title, uint start, TwoWayLineType customType) external onlyOwnerOr("Edit") {
        string memory outcomes;

        if (customType == TwoWayLineType.YesNo) {
            outcomes = "Yes_No";
        } else if (customType == TwoWayLineType.OverUnder) {
            outcomes = "Over_Under";
        } else {
            outcomes = "1_2";
        }
        
        addLine(eventId, title, LineType.TwoWay, start, outcomes);
    }

    function bet(uint lineId, uint betId) external payable {
        uint amount = msg.value;
        require(amount >= minBetAmount);
        address player = msg.sender;
        betStorage.addBet(lineId, betId, player, amount);
        blockedSum = blockedSum.add(amount);
        BetMade(lineId, betId, player, amount);
    }

    function cancelLine(uint lineId, string comment) external onlyOwnerOr("Submit") {
        betStorage.cancelLine(lineId);
        LineCanceled(lineId, comment);
    }   

    function getMyBets(uint lineId) external view returns (uint[] result) {
        return getPlayerBets(lineId, msg.sender);
    }

    function getMyDiscount() external view returns (uint discount, uint till) {
        (discount, till) = getPlayerDiscount(msg.sender);
    }

    function getLineData(uint lineId) external view returns (uint eventId, string title, string outcomes, uint startTime, uint resultCount, LineType lineType, LineStages stage, BetStatus[] status, uint[] pool) {
        (startTime, resultCount, lineType, stage) = betStorage.getLineData(lineId);

        Line storage line = lines[lineId];
        eventId = line.eventId;
        title = line.title;
        outcomes = line.outcomes;
        status = new BetStatus[](resultCount);
        pool = new uint[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            (status[i], pool[i]) = betStorage.getBetPool(lineId, i);
        }
    }

    function getLineStat(uint lineId) external view returns (LineStages stage, BetStatus[] status, uint[] pool) {       
        uint resultCount;
        (resultCount, stage) = betStorage.getLineData2(lineId);
        status = new BetStatus[](resultCount);
        pool = new uint[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            (status[i], pool[i]) = betStorage.getBetPool(lineId, i);
        }
    }

    // emergency
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function payout(uint sum) external onlyOwner {
        require(sum > 0);
        require(!payoutToOwnerIsLimited || (this.balance - blockedSum) >= sum);
        msg.sender.transfer(sum);
    }    

    function payPlayers(uint lineId, uint chunkSize) external onlyOwnerOr("Pay") {
        uint startId;
        uint endId;
        PaymentType paymentType;
        uint luckyPool;
        uint unluckyPool;

        (paymentType, startId, endId, luckyPool, unluckyPool) = betStorage.startPayments(lineId, chunkSize);

        for (uint i = startId; i < endId; i++) {
            address player;
            uint amount; 
            (player, amount) = betStorage.getSumOfPlayerBetsById(lineId, i, paymentType);

            if (amount == 0) {
                continue;
            }

            uint payment;            
            
            if (paymentType == PaymentType.Gain) {
                payment = amount.add(amount.mul(unluckyPool).div(luckyPool)).div(10000).mul(10000 - getFee(player));

                if (payment < amount) {
                    payment = amount;
                }
            } else {
                payment = amount;               
            }

            if (payment > 0) {
                player.transfer(payment);
                PlayerPaid(lineId, player, payment);
            }
        }

        if (betStorage.tryCloseLine(lineId, endId, paymentType)) {
            uint totalPool = betStorage.getLineSum(lineId);
            blockedSum = blockedSum.sub(totalPool);
            LineClosed(lineId, paymentType, totalPool);
        }
    }
    
    function setContractMessage(string value) external onlyOwner {
        contractMessage = value;
    }    

    function setDiscountForPlayer(address player, uint discount, uint till) external onlyOwner {
        require(till > now && discount > 0 && discount <= 100);
        discounts[player].till = uint64(till);
        discounts[player].discount = uint8(discount);
    }

    function setFee(uint value) external onlyOwner {
        // 100 = 1% fee;
        require(value >= 0 && value <= 500);
        fee = value;
    }

    function setLineStartTime(uint lineId, uint time) external onlyOwnerOr("Edit") {
        betStorage.setLineStartTime(lineId, time);
        LineStartTimeChanged(lineId, time);
    }    

    function setMinBetAmount(uint value) external onlyOwner {
        require(value > 0);
        minBetAmount = value;
    }

    // if something goes wrong with contract, we can turn on this function
    // and then withdraw balance and pay players by hand without need to kill contract
    function setPayoutLimit(bool value) external onlyOwner {
        payoutToOwnerIsLimited = value;
    }

    function setStorage(address contractAddress) external onlyOwner {        
        AbstractBetStorage candidateContract = AbstractBetStorage(contractAddress);
        require(candidateContract.isBetStorage());
        betStorage = candidateContract;
        // betStorage.transferOwnership(address(this));
    }

    function setStorageOwner(address newOwner) external onlyOwner {
        betStorage.transferOwnership(newOwner);
    }    

    function submitResult(uint lineId, uint[] results) external onlyOwnerOr("Submit") {
        betStorage.submitResult(lineId, results);
        ResultSubmitted(lineId, results);
    }    

    function addLine(uint eventId, string title, LineType lineType, uint start, string outcomes) private {
        require(start > now);

        Line memory line = Line({
            eventId: eventId, 
            title: title, 
            outcomes: outcomes
        });

        uint lineId = lines.push(line) - 1;
        uint resultCount;

        if (lineType == LineType.ThreeWay || lineType == LineType.DoubleChance) {
            resultCount = 3;           
        } else if (lineType == LineType.TwoWay) {
            resultCount = 2; 
        } else {
            resultCount = getSplitCount(outcomes);
        }       

        betStorage.addLine(lineId, lineType, start, resultCount);
        NewLine(eventId, lineId, title, lineType, start, outcomes);
    }

    function getFee(address player) private view returns (uint newFee) {
        var data = discounts[player];

        if (data.till > now) {
            return fee * (100 - data.discount) / 100;
        }

        return fee;
    }    

    function getPlayerBets(uint lineId, address player) private view returns (uint[] result) {
        Line storage line = lines[lineId];
        uint count = getSplitCount(line.outcomes);
        result = new uint[](count);

        for (uint i = 0; i < count; i++) {
            result[i] = betStorage.getPlayerBet(lineId, i, player);
        }
    }

    function getPlayerDiscount(address player) private view returns (uint discount, uint till) {
        FeeDiscount storage discountFee = discounts[player];
        discount = discountFee.discount;
        till = discountFee.till;
    }    

    function getSplitCount(string input) private returns (uint) { 
        var s = input.toSlice();
        var delim = "_".toSlice();
        var parts = new string[](s.count(delim) + 1);

        for (uint i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }

        return parts.length;
    }
}