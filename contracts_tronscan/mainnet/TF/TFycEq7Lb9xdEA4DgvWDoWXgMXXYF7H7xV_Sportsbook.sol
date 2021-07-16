//SourceUnit: Sportsbook.sol

pragma solidity 0.4.25;

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <arachnid@notdot.net>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
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
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
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
    function toSlice(string memory self) internal pure returns (slice memory) {
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
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
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
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
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
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
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
    function empty(slice memory self) internal pure returns (bool) {
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
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = uint256(-1); // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
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
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
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
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
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
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
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
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
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
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

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
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
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
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
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
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
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
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
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
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
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
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
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
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
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
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
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
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
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
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
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
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
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

//-----------------------------------------------------------------------------
// SafeMath
//-----------------------------------------------------------------------------

library SafeMath
{
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) { return 0; }
		c = a * b;
		require(c / a == b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		require(c >= a);
	}
}

//-----------------------------------------------------------------------------
// Ownership
//-----------------------------------------------------------------------------

contract owned
{
	address internal owner;
	address internal newOwner;

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

//-----------------------------------------------------------------------------
// Trontopia token
//-----------------------------------------------------------------------------

interface interfaceTOKEN
{
	function mintToken(address _user, uint256 _tronAmount) external returns(bool);
}

interface InterfaceVOUCHERS
{
	function mintVouchers(address _user, uint256 _mainBetSUN, uint256 _siteBetSUN) external returns(bool);
}



//**************************************************************************//
//---------------------   DIAMOND CONTRACT INTERFACE  ----------------------//
//**************************************************************************//

interface InterfaceDIAMOND
{
    function usersDiamondFrozen(address _user)  external view returns(uint256);
}




//**************************************************************************//
//-------------------    REFERRAL CONTRACT INTERFACE    --------------------//
//**************************************************************************//

interface InterfaceREFERRAL {
    function referrers(address user) external returns(address);
    function updateReferrer(address _user, address _referrer) external returns(bool);
    function payReferrerBonusOnly(address _user, uint256 _trxAmount ) external returns(bool);
    //function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _refBonus) external returns(bool);
}


//-----------------------------------------------------------------------------
// Sportsbook
//-----------------------------------------------------------------------------

contract Sportsbook is owned
{
	using SafeMath for uint256;
	using strings for *;


    //rake variables
    uint256 public tempRakePool;
    uint256 public mainRakePool;
    uint256 public mainRakePoolDepositedAllTime;
    uint256 public ownerRakeWithdrawn;
    uint256 public voucherRakeWithdrawn;
    uint256 public diamondRakeWithdrawn;
    uint256 public vaultRakeWithdrawn;
    uint256 public divRakeWithdrawn;
    
    
    uint256 public ownerRakePercent = 20;     //20% of mainRakePool
    uint256 public voucherRakePercent = 20;   //20% of mainRakePool
    uint256 public vaultRakePercent = 20;     //20% of mainRakePool
    uint256 public diamondRakePercent = 20;   //20% of mainRakePool
    uint256 public divRakePercent = 20;       //20% of mainRakePool
    uint256 public globalRakePerMillion = 60000;    //6% of TRX wagered
    uint256 private maxWinDivisibleAmount = 50;

    uint256 public reduceExtraMinting;  //123 = 1.23%
    uint256 public reduceMainMinting;  //123 = 1.23%
    
    mapping (address => uint256) public accumulatedMintToken;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    mapping (address => uint256) public accumulatedMintVoucher;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    mapping (address => uint256) public accumulatedMintVoucherSide; // total amount of bet of particular player, for minting use, once minting done this value will be zero


	// Minimum bet amount; not necessarily the actual min enforced
	// by MonsterByte, but an additional check against stupidity
	uint256 public minimumBetAmountSUN = 100 * 1e6;

	// Total available TRX that has either been deposited or freed
	// up from lost wagers
	uint256 public totalAvailableSUN = 0;

	// Total amount that is required to cover all current bets if
	// they were to win (contract could potentially lock this into
	// the contract).
	uint256 public totalPotentialPayoutSUN = 0;


    function GetValueAndResetMintPending(address user) public returns(uint256,uint256,uint256)
    {
        require(msg.sender == dividendContractAddress, "invalid caller");
        uint256 d1=accumulatedMintToken[user];
        uint256 d2=accumulatedMintVoucher[user];
        uint256 d3=accumulatedMintVoucherSide[user];
        accumulatedMintToken[user] = 0;
        accumulatedMintVoucher[user] = 0;
        accumulatedMintVoucherSide[user] = 0;
        return (d1,d2,d3);
    }


    function GetValueOfMintPending(address user) public view returns(uint256,uint256,uint256)
    {
        uint256 d1=accumulatedMintToken[user];
        uint256 d2=accumulatedMintVoucher[user];
        uint256 d3=accumulatedMintVoucherSide[user];
        return (d1,d2,d3);
    }


	struct Bet {
		uint64 ticket;
		bool parlay;
		uint8 status;
		uint8 result;
		uint256 created;
		uint256 changed;
		uint256 amount;
		uint64 to_win;
		string title;
		string info;
		address user;
	}

	event BetPlaced(address indexed user, uint64 ticket, uint256 amount);
	event BetAccepted(address indexed user, uint64 ticket, string title);
	event BetRejected(address indexed user, uint64 ticket, string title, string reason);
	event BetGraded(address indexed user, uint64 ticket, string title, string result);
	event BetSettled(address indexed user, uint64 ticket);
    event BetSettled(uint256 nowTime,address indexed user,uint64 ticket,uint256 wagerAmount,uint8 betResult);     

	// MonsterByte agent
	address public agent;

	// Trontopia stuff
    address public topiaTokenContractAddress;
    address public dividendContractAddress;
    address public voucherContractAddress;
    address public vaultContractAddress;
    address public diamondContractAddress;
    address public diamondVoucherContractAddress;
    address public refPoolContractAddress;

	mapping(uint256 => Bet) bets;

	modifier onlyAgent {
		require(agent != address(0));
		require(msg.sender == agent);
		_;
	}

	function setAgent(address newAgent) public onlyOwner {
		agent = newAgent;
	}

    
    /**
        Function allows owner to update the Topia contract address
    */
    function updateContractAddresses(address topiaContract, address voucherContract, address dividendContract, address refPoolContract, address vaultContract, address diamondContract,address diamondVoucherContract) public onlyOwner returns(string)
    {
        
        topiaTokenContractAddress = topiaContract;
        voucherContractAddress = voucherContract;
        dividendContractAddress = dividendContract;
        refPoolContractAddress = refPoolContract;
        vaultContractAddress = vaultContract;
        diamondContractAddress = diamondContract;
        diamondVoucherContractAddress = diamondVoucherContract;
        return "done";
    }


	function updateMinimumBetAmount(uint256 newMinimum) public onlyOwner {
		minimumBetAmountSUN = newMinimum;
	}

	function deposit() public payable {
		totalAvailableSUN = totalAvailableSUN.add(msg.value);
	}

	function withdraw(uint256 amount) public onlyOwner {
		require(totalAvailableSUN >= amount, "Amount exceeds balance");
		require(msg.sender == owner, "Only owner may initiate withdrawal");

		totalAvailableSUN = totalAvailableSUN.sub(amount);

		require(owner.send(amount));
	}


    function setReduceExtraMinting(uint256 _reduceExtraMinting) onlyOwner public returns(bool)
    {
        reduceExtraMinting = _reduceExtraMinting;
    }


    function setReduceMainMinting(uint256 _reduceMainMinting) onlyOwner public returns(bool)
    {
        reduceMainMinting = _reduceMainMinting;
    }

     //Calculate percent and return result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }   


    function divSet(address user, uint256 _value) internal returns (bool)
    {


        
        if(topiaTokenContractAddress != address(0)){
            // Mint tokens depending on how much TRX is received
            uint256 usersDiamondFrozen = InterfaceDIAMOND(diamondVoucherContractAddress).usersDiamondFrozen(user);
        
            uint256 extraMint;
            if(usersDiamondFrozen >= 1000000 && usersDiamondFrozen < 1000000000){
                extraMint = usersDiamondFrozen / 1000000;
            }	
            else if (usersDiamondFrozen >= 1000000000)
            {
                extraMint = 1000;
            }	    
            uint256 extraMintValue = _value * extraMint / 1000;
            extraMintValue -= calculatePercentage(extraMintValue,reduceExtraMinting);
            _value -= calculatePercentage(extraMintValue,reduceMainMinting);
            accumulatedMintToken[user] += _value + extraMintValue;
            //interfaceTOKEN(topiaTokenContractAddress).mintToken(user, _value + extraMintValue);
        }
         
        return true;

    }

	function placeBet(uint64 ticket, string memory title, bool parlay, address _referrer) payable public {
		uint256 betid = uniquebetid(msg.sender, ticket);
		Bet memory bet = bets[betid];

		require(bet.created == 0, "Bet already exists");
		require(msg.value >= minimumBetAmountSUN, "Bet amount too low");

		bet.ticket = ticket;
		bet.parlay = parlay;
		bet.status = 1;
		bet.result = 0;
		bet.created = block.timestamp;
		bet.changed = block.timestamp;
		bet.amount = msg.value;
		bet.title = title;
		bet.info = '';
		bet.user = msg.sender;

		bets[betid] = bet;

        
        // Set referer address if user has usd ref link and does not have any existing referer...
        if (_referrer != address(0x0) && InterfaceREFERRAL(refPoolContractAddress).referrers(msg.sender) == address(0x0) )
        {
            // Set their referral address
            InterfaceREFERRAL(refPoolContractAddress).updateReferrer(msg.sender, _referrer);
        }


        //tempRakePool += msg.value * globalRakePerMillion / 1e6;
		emit BetPlaced(msg.sender, ticket, msg.value);
	}




	function placeBets(uint64[] tickets, string memory titles, uint256[] amounts, bool parlay, address _referrer) payable public {
		require(tickets.length == amounts.length, "Mismatched bet parameters");

		require(msg.value >= minimumBetAmountSUN.mul(tickets.length), "Bet amount too low");

		uint256 totalBet = 0;

		Bet memory bet;

		strings.slice memory titles_slice = titles.toSlice();
		strings.slice memory delim = "::".toSlice();

		for (uint i = 0; i < tickets.length; i++) {
			uint256 betid = uniquebetid(msg.sender, tickets[i]);
            
			bet = bets[betid];
			require(bet.created == 0, "Bet already exists");

			bet.ticket = tickets[i];
			bet.parlay = parlay;
			bet.status = 1;
			bet.result = 0;
			bet.created = block.timestamp;
			bet.changed = block.timestamp;
			bet.amount = amounts[i];
			bet.title = titles_slice.split(delim).toString();
			bet.info = '';
			bet.user = msg.sender;

			bets[betid] = bet;

			totalBet = totalBet.add(amounts[i]);

			emit BetPlaced(msg.sender, tickets[i], amounts[i]);
		}

        // Set referer address if user has usd ref link and does not have any existing referer...
        if (_referrer != address(0x0) && InterfaceREFERRAL(refPoolContractAddress).referrers(msg.sender) == address(0x0) )
        {
            // Set their referral address
            InterfaceREFERRAL(refPoolContractAddress).updateReferrer(msg.sender, _referrer);
        }

		require(totalBet == msg.value, "Amount paid not equal to sum of bet amounts");
	}

	function rejectBet(address user, uint64 ticket, string memory reason) public onlyAgent {
		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		require(bet.status == 1, "Action invalid on this bet");

		bet.status = 3;
		bet.changed = block.timestamp;
		bet.info = reason;

		emit BetRejected(user, ticket, bet.title, reason);
	}

	function refundBet(address user, uint64 ticket) public onlyAgent {
		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		require(bet.status == 3, "Action invalid on this bet");

		bet.status = 6;
		bet.changed = block.timestamp;

		makePayment(user, bet.amount);
	}

	function acceptBet(address user, uint64 ticket, uint64 to_win) public onlyAgent {
		require(to_win != 0);

		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		require(bet.status == 1, "Action invalid on this bet");

		bet.status = 2;
		bet.changed = block.timestamp;
		bet.to_win = to_win;

		totalPotentialPayoutSUN = totalPotentialPayoutSUN.add(bet.amount).add(to_win);

		emit BetAccepted(user, ticket, bet.title);
	}

	function gradeBet(address user, uint64 ticket, uint8 result, string memory reason) public onlyAgent {
		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		require(bet.status == 2, "Action invalid on this bet");
		require(result != 0, "Invalid result");
		require(result <= 4, "Invalid result");

		string memory info;

		if (result == 3) {
			info = "Bet won";
		} else if (result == 1) {
			info = "Bet lost";
		} else if (result == 2) {
			info = "Bet push";
		} else if (result == 4) {
			info = "Bet cancelled: "
				.toSlice()
				.concat(reason.toSlice());
		}

		bet.status = 4;
		bet.changed = block.timestamp;
		bet.result = result;
		bet.info = info;

		emit BetGraded(user, ticket, bet.title, info);

		/*if (result == 3 || result == 2) {
			if (topiaTokenContractAddress != address(0)) {
				interfaceTOKEN(topiaTokenContractAddress).mintToken(user, bet.amount);
			}
		}*/
	}

	function gradeReducedWin(address user, uint64 ticket, uint64 to_win) public onlyAgent {
		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		require(bet.status == 2, "Action invalid on this bet");
		require(bet.parlay == true, "Not a parlay bet");

		string memory info = "Bet won (reduced winnings)";

		totalPotentialPayoutSUN = totalPotentialPayoutSUN.sub(bet.to_win).add(to_win);

		bet.to_win = to_win;

		bet.status = 4;
		bet.changed = block.timestamp;
		bet.result = 3;
		bet.info = info;

		emit BetGraded(user, ticket, bet.title, info);

		/*if (topiaTokenContractAddress != address(0)) {
			interfaceTOKEN(topiaTokenContractAddress).mintToken(user, bet.amount);
		}*/
	}

	function settleBet(address user, uint64 ticket) public onlyAgent {
		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		require(bet.status == 4, "Action invalid on this bet");

		bet.status = 5;
		bet.changed = block.timestamp;

		if (bet.result == 3) {
			makePayment(user, SafeMath.add(bet.to_win, bet.amount));
		} else if (bet.result == 2) {
			makePayment(user, bet.amount);
		} else if (bet.result == 4) {
			makePayment(user, bet.amount);
		} else if (bet.result == 1) {
			// User forfeits the wager; owner may now take it
			totalAvailableSUN = totalAvailableSUN.add(bet.amount);
		}

		totalPotentialPayoutSUN = totalPotentialPayoutSUN.sub(bet.amount).sub(bet.to_win);
        divSet(user, bet.amount);
	    tempRakePool +=  bet.amount * globalRakePerMillion / 1e6;


		if (bet.result == 3 || bet.result == 2 || bet.result == 1 ) {
			if (voucherContractAddress != address(0)) {
                		accumulatedMintVoucher[user] += bet.amount;
                		//accumulatedMintVoucherSide[user] += 0;                
				//InterfaceVOUCHERS(voucherContractAddress).mintVouchers(user, bet.amount, 0);
			}
		}

        
        // If the user won their main bet, their sidebet or both, their referrer gets payed
        if (bet.result == 3 && InterfaceREFERRAL(refPoolContractAddress).referrers(user) != address(0x0))
        {           
            // Processing referral system fund distribution
            // [✓] 0.2% trx to referral if any.
            InterfaceREFERRAL(refPoolContractAddress).payReferrerBonusOnly(user, bet.amount);
        }
		emit BetSettled(now, user, ticket,bet.amount, bet.result );        
        

	}

	function eraseBet(address user, uint64 ticket) public onlyAgent {
		uint256 betid = uniquebetid(user, ticket);
		Bet storage bet = bets[betid];

		require(bet.created > 0, "Bet not found");

		// Only allow erasure of end-of-lifecycle bets
		require(bet.status == 5 || bet.status == 6, "Illegal bet erasure");

		// If we did allow erasing other bets, then we'd update the payout potential...
		//if (bet.status == 2 || bet.status == 4)
		//	totalPotentialPayoutSUN = totalPotentialPayoutSUN.sub(bet.amount).sub(bet.to_win);

		delete bets[betid];
	}

	function eraseBets(address[] users, uint64[] tickets) public onlyAgent {
		require(tickets.length == users.length, "Mismatched bet parameters");

		for (uint i = 0; i < tickets.length; i++) {
			uint256 betid = uniquebetid(users[i], tickets[i]);
			Bet storage bet = bets[betid];

			if (bet.created == 0)
				continue;

			if (bet.status == 5 || bet.status == 6)
				delete bets[betid];
		}
	}

	function makePayment(address recipient, uint256 amount) private {
		//recipient.transfer(amount);
		require(recipient.send(amount));
	}

	function uniquebetid (address user, uint64 ticket) private pure returns (uint256) {
		return (uint256(user) << (256-160)) | uint128(ticket);
	}

    //************************************ Rake codes below ********************************* */  
    //*************************************************************************************** */

    /**
        Function to change max bet amount and max bet divisible amount.
    */
    function updateMaxBetMaxWin(uint256 minimumBetAmountSUN_, uint256 maxWinDivisibleAmount_  ) public onlyOwner returns(string)
    {
        minimumBetAmountSUN = minimumBetAmountSUN_;
        maxWinDivisibleAmount = maxWinDivisibleAmount_;

        return("Max bet and max win updated successfully");
    }



    function maxWin() public view returns(uint256){
        return (address(this).balance.sub(tempRakePool + mainRakePool )) / maxWinDivisibleAmount;
    }
   
    
    function availableToWithdrawOwner() public view returns(uint256){
        return address(this).balance.sub(tempRakePool + mainRakePool);
    }


    /**
        This function lets owner to withdraw TRX as much he deposited.
        Thus there is NO "exit scam" possibility, as there is no other way to take TRX out of this contract
    */
    function manualWithdrawTRX(uint256 amountSUN) public onlyOwner returns(string)
    {
        uint256 availableToWithdraw = address(this).balance.sub(tempRakePool + mainRakePool);
        
        require(availableToWithdraw > amountSUN, 'withdrawing more than available');

        //transferring the TRX to owner
        owner.transfer(amountSUN);

        return "Transaction successful";
    }
    

    
    function addRakeToMainPool() internal{
        if(tempRakePool > 0){
            mainRakePool += tempRakePool;
            mainRakePoolDepositedAllTime += tempRakePool;
            tempRakePool = 0;
        }
    }    

    
    function getAvailableOwnerRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > ownerRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - ownerRakeWithdrawn;
            mainRake = totalRake * ownerRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * ownerRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
 
     
    function getAvailableVoucherRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > voucherRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - voucherRakeWithdrawn;
            mainRake = totalRake * voucherRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * voucherRakePercent / 100;
        
        return mainRake + tempRake;
        
    }


    
    function getAvailableVaultRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > vaultRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - vaultRakeWithdrawn;
            mainRake = totalRake * vaultRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * vaultRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
    function getAvailableDiamondRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > diamondRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - diamondRakeWithdrawn;
            mainRake = totalRake * diamondRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * diamondRakePercent / 100;
        
        return mainRake + tempRake;
        
    }

    function getAvailableDivRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > divRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - divRakeWithdrawn;
            mainRake = totalRake * divRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * divRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
     

    
    function withdrawOwnerPool() external onlyOwner returns (string)
    {
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > ownerRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - ownerRakeWithdrawn;
            
            //taking % of that
            uint256 finalOwnerRake = totalRake * ownerRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalOwnerRake);
            ownerRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalOwnerRake);
            
            return "Owner rake withdrawn successfully";
            
        }
        
        return "Nothing to withdraw";
    }





    
    function updateRakePercents(uint256 _ownerRakePercent, uint256 _voucherRakePercent, uint256 _vaultRakePercent, uint256 _diamondRakePercent, uint256 _divRakePercent) external onlyOwner returns (string)
    {
        require(_ownerRakePercent <= 100 && _voucherRakePercent <= 100 && _vaultRakePercent <= 100 && _diamondRakePercent <= 100, 'Invalid amount' );
        ownerRakePercent = _ownerRakePercent;
        voucherRakePercent = _voucherRakePercent;
        vaultRakePercent = _vaultRakePercent;
        diamondRakePercent = _diamondRakePercent;
        divRakePercent = _divRakePercent;
        return "All rake percents updated successfully";
    }
     
    function updateGlobalRakePerMillion(uint256 newGlobalRakePerMillion) external onlyOwner returns (string){
        require(newGlobalRakePerMillion < 1000000, 'Invalid amount');
        globalRakePerMillion = newGlobalRakePerMillion;
        return "globalRakePerMillion updated successfully";
    }


      /**
     * This function can be called by voucher contract to request payment of voucherRakePool
     */
    function requestVoucherRakePayment() public returns(bool){
        
        require(msg.sender == voucherContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > voucherRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - voucherRakeWithdrawn;
            
            //taking % of that
            uint256 finalVoucherRake = totalRake * voucherRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalVoucherRake);
            voucherRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalVoucherRake);
            
        }
        
        return true;
    }

   /**
     * This function can be called by vault contract to request payment of vaultRakePool
     */
    function requestVaultRakePayment() public returns(bool){
        
        require(msg.sender == vaultContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > vaultRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - vaultRakeWithdrawn;
            
            //taking % of that
            uint256 finalRake = totalRake * vaultRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalRake);
            vaultRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalRake);
            
        }
        
        return true;
    }


    /**
     * This function can be called by diamond contract to request payment of diamondRakePool
     */
    function requestDiamondRakePayment() public returns(bool){
        
        require(msg.sender == diamondContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > diamondRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - diamondRakeWithdrawn;
            
            //taking % of that
            uint256 finalRake = totalRake * diamondRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalRake);
            diamondRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalRake);
            
        }
        
        return true;
    }


    /**
     * This function can be called by dividend contract to request payment of divRakePool
     */
    function requestDivRakePayment(uint256 requestedAmount) public returns(bool){
        
        require(msg.sender == dividendContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > divRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - divRakeWithdrawn;
            
            //taking % of that
            uint256 finalRake = totalRake * divRakePercent / 100;

            //if requestedAmount is higher than available finalRake, then it will simply return false as... 
            //we want to return false because it will break loop in dividend contract 
            //because there is no normal case, when requestedAmount would be higher than finalRake
            if(finalRake < requestedAmount) {return false;}

            mainRakePool = mainRakePool.sub(requestedAmount);
            divRakeWithdrawn = mainRakePoolDepositedAllTime - ((finalRake - requestedAmount) * (100 / divRakePercent) );
            
            //transferring rake amount
            msg.sender.transfer(requestedAmount);
            
        }
        
        return true;
    }
    




    /**
        Function to deposit into rake pool
    */
    function manuallyFundRakePools() public payable onlyOwner returns(string){
        require(msg.value > 0, 'Not emough TRX');
        
        tempRakePool += msg.value;
        
        return "Pool funded successfully";
        
    }
    
 
    


}