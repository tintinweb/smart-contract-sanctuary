/*
 *      Welcome to the &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838; Smart-Contract!
 *      The &#119822;&#119821;&#119819;&#119832; decentralized, charitable blockchain lottery!
 *      
 *      ##########################################
 *      ##########################################
 *      ###                                    ###
 *      ###          &#119823;&#119845;&#119834;&#119858; & &#119830;&#119842;&#119847; &#119812;&#119853;&#119841;&#119838;&#119851;          ###
 *      ###                 at                 ###
 *      ###          &#119812;&#119827;&#119815;&#119812;&#119825;&#119808;&#119813;&#119813;&#119819;&#119812;.&#119810;&#119822;&#119820;          ###
 *      ###                                    ###
 *      ##########################################
 *      ##########################################
 *
 *      Etheraffle is designed to give &#119841;&#119854;&#119840;&#119838; &#119849;&#119851;&#119842;&#119859;&#119838;&#119852; to 
 *      players, sustainable &#119812;&#119827;&#119815; &#119837;&#119842;&#119855;&#119842;&#119837;&#119838;&#119847;&#119837;&#119852; to &#119819;&#119822;&#119827; token 
 *      holders, and &#119845;&#119842;&#119839;&#119838;-&#119836;&#119841;&#119834;&#119847;&#119840;&#119842;&#119847;&#119840; &#119839;&#119854;&#119847;&#119837;&#119842;&#119847;&#119840; to charities.
 *
 *      Learn more & get involved at &#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119836;&#119848;&#119846;/&#119816;&#119810;&#119822; to become a
 *      &#119819;&#119822;&#119827; token holder today! Holding &#119819;&#119822;&#119827; tokens automatically  
 *      makes you a part of the decentralized, autonomous organisation  
 *      that &#119822;&#119830;&#119821;&#119826; Etheraffle. Take your place in this decentralized, 
 *      altruistic vision of the future!
 *
 *      If you want to chat to us you have loads of options:
 *      On &#119827;&#119838;&#119845;&#119838;&#119840;&#119851;&#119834;&#119846; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119853;.&#119846;&#119838;/&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;
 *      Or on &#119827;&#119856;&#119842;&#119853;&#119853;&#119838;&#119851; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119853;&#119856;&#119842;&#119853;&#119853;&#119838;&#119851;.&#119836;&#119848;&#119846;/&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;
 *      Or on &#119825;&#119838;&#119837;&#119837;&#119842;&#119853; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119851;&#119838;&#119837;&#119837;&#119842;&#119853;.&#119836;&#119848;&#119846;
 *
 */
 
pragma solidity^0.4.21;

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="bedfccdfddd6d0d7dafed0d1cadad1ca90d0dbca">[email&#160;protected]</a>>
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
 
//pragma solidity ^0.4.14;

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
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

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
// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

//pragma solidity ^0.4.0;//please import oraclizeAPI_pre0.4.sol when solidity < 0.4.0

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function useCoupon(string _coupon);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
    function randomDS_getSessionPubKeyHash() returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        oraclize.useCoupon(code);
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) {
    }

    function oraclize_useCoupon(string code) oraclizeAPI internal {
        oraclize.useCoupon(code);
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }
    function oraclize_setConfig(bytes32 config) oraclizeAPI internal {
        return oraclize.setConfig(config);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] arr) internal returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there&#39;s a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }

    function ba2cbor(bytes[] arr) internal returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there&#39;s a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }


    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        if ((_nbytes == 0)||(_nbytes > 32)) throw;
	// Convert from seconds to ledger timer ticks
        _delay *= 10; 
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly { 
            mstore(add(delay, 0x20), _delay) 
        }
        
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);

        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        
        bytes memory delay_bytes8_left = new bytes(8);
        
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))

        }
        
        oraclize_randomDS_setCommitment(queryId, sha3(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }
    
    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(sha3(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(sha3(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = 1; //role
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) throw;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) throw;

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal returns (bool){
        bool match_ = true;
	
	if (prefix.length != n_random_bytes) throw;
	        
        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(sha3(keyhash) == sha3(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if &#39;result&#39; is the prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

        // Step 4: commitment match verification, sha3(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == sha3(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[queryId];
        } else return false;


        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

        // verify if sessionPubkeyHash was verified already, if not.. let&#39;s do it!
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }


    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal returns (bytes) {
        uint minLength = length + toOffset;

        if (to.length < minLength) {
            // Buffer too small
            throw; // Should be a better way?
        }

        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can&#39;t access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

}
// </ORACLIZE_API>

contract ReceiverInterface {
    function receiveEther() external payable {}
}

contract EtheraffleUpgrade {
    function addToPrizePool() payable external {}
}

contract FreeLOTInterface {
    function mint(address _to, uint _amt) external {}
    function destroy(address _from, uint _amt) external {}
    function balanceOf(address who) constant public returns (uint) {}
}

contract Etheraffle is usingOraclize {
    using strings for *;

    uint    public week;
    bool    public paused;
    uint    public upgraded;
    uint    public prizePool;
    address public ethRelief;
    address public etheraffle;
    address public upgradeAddr;
    address public disburseAddr;
    uint    public take         = 150; // ppt
    uint    public gasAmt       = 500000;
    uint    public resultsDelay = 3600;
    uint    public matchesDelay = 3600;
    uint    public rafEnd       = 500400; // 7:00pm Saturdays
    uint    public wdrawBfr     = 6048000;
    uint    public gasPrc       = 20000000000; // 20 gwei
    uint    public tktPrice     = 2000000000000000;
    uint    public oracCost     = 1500000000000000; // $1 @ $700
    uint[]  public pctOfPool    = [520, 114, 47, 319]; // ppt...
    uint[]  public odds         = [56, 1032, 54200, 13983816]; // Rounded down to nearest whole 
    uint  constant WEEKDUR      = 604800;
    uint  constant BIRTHDAY     = 1500249600;//Etheraffle&#39;s birthday <3

    FreeLOTInterface freeLOT;

    string randomStr1 = "[URL] [&#39;json(https://api.random.org/json-rpc/1/invoke).result.random[\"data\", \"serialNumber\"]&#39;,&#39;\\n{\"jsonrpc\": \"2.0\",\"method\":\"generateSignedIntegers\",\"id\":\"";
    string randomStr2 = "\",\"params\":{\"n\":\"6\",\"min\":1,\"max\":49,\"replacement\":false,\"base\":10,\"apiKey\":${[decrypt] BIaCXRwykpLeDE9h1dQaAUi0LPTD4Jz0kwh6SVTftO+zromdgBhmdQhFwPsaLEGDHHn8bhQA8ksyjOZJpjDzKcVWlkBx5C07udHFtMnvG9g9VITYGxoMOhpFCTnoIKTBlIbNe5D1rIgl9OYUVX4ibTT8fCEE8TkWqQ==}}&#39;]";
    string apiStr1    = "[URL] [&#39;json(https://etheraffle.com/api/a).m&#39;,&#39;{\"r\":\"";
    string apiStr2    = "\",\"k\":${[decrypt] BDzj/WPcHzGWYRL2cXvMNvInBxhutESn6Xj8pVzUUH+oEeWBoyycp23B7FSjqKJww6uH5AxvD4srlX0D/Rhl678YcKSNX2oMJJ47ciZrCnj6+28GHCLBV+XiA/1GDis9p5Q9NIKI}}&#39;]";

    mapping (uint => rafStruct) public raffle;
    struct rafStruct {
        mapping (address => uint[][]) entries;
        uint unclaimed;
        uint[] winNums;
        uint[] winAmts;
        uint timeStamp;
        bool wdrawOpen;
        uint numEntries;
        uint freeEntries;
    }

    mapping (bytes32 => qIDStruct) public qID;
    struct qIDStruct {
        uint weekNo;
        bool isRandom;
        bool isManual;
    }
    /**
    * @dev  Modifier to prepend to functions adding the additional
    *       conditional requiring caller of the method to be the
    *       etheraffle address.
    */
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
    /**
    * @dev  Modifier to prepend to functions adding the additional
    *       conditional requiring the paused bool to be false.
    */
    modifier onlyIfNotPaused() {
        require(!paused);
        _;
    }
    event LogFunctionsPaused(uint identifier, uint atTime);
    event LogQuerySent(bytes32 queryID, uint dueAt, uint sendTime);
    event LogReclaim(uint indexed fromRaffle, uint amount, uint atTime);
    event LogUpgrade(address newContract, uint ethTransferred, uint atTime);
    event LogPrizePoolAddition(address fromWhom, uint howMuch, uint atTime);
    event LogFreeLOTWin(uint indexed forRaffle, address toWhom, uint entryNumber, uint amount, uint atTime);
    event LogOraclizeCallback(address functionCaller, bytes32 queryID, string result, uint indexed forRaffle, uint atTime);
    event LogFundsDisbursed(uint indexed forRaffle, uint oraclizeTotal, uint amount, address indexed toAddress, uint atTime);
    event LogWithdraw(uint indexed forRaffle, address indexed toWhom, uint forEntryNumber, uint matches, uint amountWon, uint atTime);
    event LogWinningNumbers(uint indexed forRaffle, uint numberOfEntries, uint[] wNumbers, uint currentPrizePool, uint randomSerialNo, uint atTime);
    event LogTicketBought(uint indexed forRaffle, uint indexed entryNumber, address indexed theEntrant, uint[] chosenNumbers, uint personalEntryNumber, uint tktCost, uint atTime, uint affiliateID);
    event LogPrizePoolsUpdated(uint newMainPrizePool, uint indexed forRaffle, uint unclaimedPrizePool, uint threeMatchWinAmt, uint fourMatchWinAmt, uint fiveMatchWinAmt, uint sixMatchwinAmt, uint atTime);
    /**
     * @dev   Constructor - sets the Etheraffle contract address &
     *        the disbursal contract address for investors, calls
     *        the newRaffle() function with sets the current
     *        raffle ID global var plus sets up the first raffle&#39;s
     *        struct with correct time stamp. Sets the withdraw
     *        before time to a ten week period, and prepares the
     *        initial oraclize call which will begin the recursive
     *        function.
     *
     * @param _freeLOT    The address of the Etheraffle FreeLOT special token.
     * @param _dsbrs      The address of the Etheraffle disbursal contract.
     * @param _msig       The address of the Etheraffle managerial multisig wallet.
     * @param _ethRelief  The address of the EthRelief charity contract.
     */
    function Etheraffle(address _freeLOT, address _dsbrs, address _msig, address _ethRelief) payable {
        week         = getWeek();
        etheraffle   = _msig;
        disburseAddr = _dsbrs;
        ethRelief    = _ethRelief;
        freeLOT      = FreeLOTInterface(_freeLOT);
        uint delay   = (week * WEEKDUR) + BIRTHDAY + rafEnd + resultsDelay;
        raffle[week].timeStamp = (week * WEEKDUR) + BIRTHDAY;
        bytes32 query = oraclize_query(delay, "nested", strConcat(randomStr1, uint2str(getWeek()), randomStr2), gasAmt);
        qID[query].weekNo = week;
        qID[query].isRandom = true;
        emit LogQuerySent(query, delay, now);
    }
    /**
     * @dev   Function using Etheraffle&#39;s birthday to calculate the
     *        week number since then.
     */
    function getWeek() public constant returns (uint) {
        uint curWeek = (now - BIRTHDAY) / WEEKDUR;
        if (now - ((curWeek * WEEKDUR) + BIRTHDAY) > rafEnd) {
            curWeek++;
        }
        return curWeek;
    }
    /**
     * @dev   Function which gets current week number and if different
     *        from the global var week number, it updates that and sets
     *        up the new raffle struct. Should only be called once a
     *        week after the raffle is closed. Should it get called
     *        sooner, the contract is paused for inspection.
     */
    function newRaffle() internal {
        uint newWeek = getWeek();
        if (newWeek == week) {
            pauseContract(4);
            return;
        } else {//∴ new raffle...
            week = newWeek;
            raffle[newWeek].timeStamp = BIRTHDAY + (newWeek * WEEKDUR);
        }
    }
    /**
     * @dev  To pause the contract&#39;s functions should the need arise. Internal.
     *       Logs an event of the pausing.
     *
     * @param _id    A uint to identify the caller of this function.
     */
    function pauseContract(uint _id) internal {
      paused = true;
      emit LogFunctionsPaused(_id, now);
    }
    /**
     * @dev  Function to enter the raffle. Requires the caller to send ether
     *       of amount greater than or equal to the ticket price.
     *
     * @param _cNums    Ordered array of entrant&#39;s six selected numbers.
     * @param _affID    Affiliate ID of the source of this entry.
     */
    function enterRaffle(uint[] _cNums, uint _affID) payable external onlyIfNotPaused {
        require(msg.value >= tktPrice);
        buyTicket(_cNums, msg.sender, msg.value, _affID);
    }
    /**
     * @dev  Function to enter the raffle on behalf of another address. Requires the 
     *       caller to send ether of amount greater than or equal to the ticket price.
     *       In the event of a win, only the onBehalfOf address can claim it.
     *
     * @param _cNums        Ordered array of entrant&#39;s six selected numbers.
     * @param _affID        Affiliate ID of the source of this entry.
     * @param _onBehalfOf   The address to be entered on behalf of.
     */
    function enterOnBehalfOf(uint[] _cNums, uint _affID, address _onBehalfOf) payable external onlyIfNotPaused {
        require(msg.value >= tktPrice);
        buyTicket(_cNums, _onBehalfOf, msg.value, _affID);
    }
    /**
     * @dev  Function to enter the raffle for free. Requires the caller&#39;s
     *       balance of the Etheraffle freeLOT token to be greater than
     *       zero. Function destroys one freeLOT token, increments the
     *       freeEntries variable in the raffle struct then purchases the
     *       ticket.
     *
     * @param _cNums    Ordered array of entrant&#39;s six selected numbers.
     * @param _affID    Affiliate ID of the source of this entry.
     */
    function enterFreeRaffle(uint[] _cNums, uint _affID) payable external onlyIfNotPaused {
        freeLOT.destroy(msg.sender, 1);
        raffle[week].freeEntries++;
        buyTicket(_cNums, msg.sender, msg.value, _affID);
    }
    /**
     * @dev   Function to buy tickets. Internal. Requires the entry number
     *        array to be of length 6, requires the timestamp of the current
     *        raffle struct to have been set, and for this time this function
     *        is call to be before the end of the raffle. Then requires that
     *        the chosen numbers are ordered lowest to highest & bound between
     *        1 and 49. Function increments the total number of entries in the
     *        current raffle&#39;s struct, increments the prize pool accordingly
     *        and pushes the chosen number array into the entries map and then
     *        logs the ticket purchase.
     *
     * @param _cNums       Array of users selected numbers.
     * @param _entrant     Entrant&#39;s ethereum address.
     * @param _value       The ticket purchase price.
     * @param _affID       The affiliate ID of the source of this entry.
     */
    function buyTicket
    (
        uint[]  _cNums,
        address _entrant,
        uint    _value,
        uint    _affID
    )
        internal
    {
        require
        (
            _cNums.length == 6 &&
            raffle[week].timeStamp > 0 &&
            now < raffle[week].timeStamp + rafEnd &&
            0         < _cNums[0] &&
            _cNums[0] < _cNums[1] &&
            _cNums[1] < _cNums[2] &&
            _cNums[2] < _cNums[3] &&
            _cNums[3] < _cNums[4] &&
            _cNums[4] < _cNums[5] &&
            _cNums[5] <= 49
        );
        raffle[week].numEntries++;
        prizePool += _value;
        raffle[week].entries[_entrant].push(_cNums);
        emit LogTicketBought(week, raffle[week].numEntries, _entrant, _cNums, raffle[week].entries[_entrant].length, _value, now, _affID);
    }
    /**
     * @dev Withdraw Winnings function. User calls this function in order to withdraw
     *      whatever winnings they are owed. Function can be paused via the modifier
     *      function "onlyIfNotPaused"
     *
     * @param _week        Week number of the raffle the winning entry is from
     * @param _entryNum    The entrants entry number into this raffle
     */
    function withdrawWinnings(uint _week, uint _entryNum) onlyIfNotPaused external {
        require
        (
            raffle[_week].timeStamp > 0 &&
            now - raffle[_week].timeStamp > WEEKDUR - (WEEKDUR / 7) &&
            now - raffle[_week].timeStamp < wdrawBfr &&
            raffle[_week].wdrawOpen == true &&
            raffle[_week].entries[msg.sender][_entryNum - 1].length == 6
        );
        uint matches = getMatches(_week, msg.sender, _entryNum);
        if (matches == 2) return winFreeGo(_week, _entryNum);
        require
        (
            matches >= 3 &&
            raffle[_week].winAmts[matches - 3] > 0 &&
            raffle[_week].winAmts[matches - 3] <= this.balance
        );
        raffle[_week].entries[msg.sender][_entryNum - 1].push(1);
        if (raffle[_week].winAmts[matches - 3] <= raffle[_week].unclaimed) {
            raffle[_week].unclaimed -= raffle[_week].winAmts[matches - 3];
        } else {
            raffle[_week].unclaimed = 0;
            pauseContract(5);
        }
        msg.sender.transfer(raffle[_week].winAmts[matches - 3]);
        emit LogWithdraw(_week, msg.sender, _entryNum, matches, raffle[_week].winAmts[matches - 3], now);
    }
    /*
     * @dev     Mints a FreeLOT coupon to a two match winner allowing them 
     *          a free entry to Etheraffle. Function pausable by pause toggle.
     */
    function winFreeGo(uint _week, uint _entryNum) onlyIfNotPaused internal {
        raffle[_week].entries[msg.sender][_entryNum - 1].push(1);
        freeLOT.mint(msg.sender, 1);
        emit LogFreeLOTWin(_week, msg.sender, _entryNum, 1, now);
    }
    /**
     * @dev    Called by the weekly oraclize callback. Checks raffle 10
     *         weeks older than current raffle for any unclaimed prize
     *         pool. If any found, returns it to the main prizePool and
     *         zeros the amount.
     */
    function reclaimUnclaimed() internal {
        uint old = getWeek() - 11;
        prizePool += raffle[old].unclaimed;
        emit LogReclaim(old, raffle[old].unclaimed, now);
    }
    /**
     * @dev  Function totals up oraclize cost for the raffle, subtracts
     *       it from the prizepool (if less than, if greater than if
     *       pauses the contract and fires an event). Calculates profit
     *       based on raffle&#39;s tickets sales and the take percentage,
     *       then forwards that amount of ether to the disbursal contract.
     *
     * @param _week   The week number of the raffle in question.
     */
    function disburseFunds(uint _week) internal {
        uint oracTot = 2 * ((gasAmt * gasPrc) + oracCost);//2 queries per draw...
        if (oracTot > prizePool) return pauseContract(1);
        prizePool -= oracTot;
        uint profit;
        if (raffle[_week].numEntries > 0) {
            profit = ((raffle[_week].numEntries - raffle[_week].freeEntries) * tktPrice * take) / 1000;
            prizePool -= profit;
            uint half = profit / 2;
            ReceiverInterface(disburseAddr).receiveEther.value(half)();
            ReceiverInterface(ethRelief).receiveEther.value(profit - half)();
            emit LogFundsDisbursed(_week, oracTot, profit - half, ethRelief, now);
            emit LogFundsDisbursed(_week, oracTot, half, disburseAddr, now);
            return;
        }
        emit LogFundsDisbursed(_week, oracTot, profit, 0, now);
    }
    /**
     * @dev   The Oralize call back function. The oracalize api calls are
     *        recursive. One to random.org for the draw and the other to
     *        the Etheraffle api for the numbers of matches each entry made
     *        against the winning numbers. Each calls the other recursively.
     *        The former when calledback closes and reclaims any unclaimed
     *        prizepool from the raffle ten weeks previous to now. Then it
     *        disburses profit to the disbursal contract, then it sets the
     *        winning numbers received from random.org into the raffle
     *        struct. Finally it prepares the next oraclize call. Which
     *        latter callback first sets up the new raffle struct, then
     *        sets the payouts based on the number of winners in each tier
     *        returned from the api call, then prepares the next oraclize
     *        query for a week later to draw the next raffle&#39;s winning
     *        numbers.
     *
     * @param _myID     bytes32 - Unique id oraclize provides with their
     *                            callbacks.
     * @param _result   string - The result of the api call.
     */
    function __callback(bytes32 _myID, string _result) onlyIfNotPaused {
        require(msg.sender == oraclize_cbAddress() || msg.sender == etheraffle);
        emit LogOraclizeCallback(msg.sender, _myID, _result, qID[_myID].weekNo, now);
        if (qID[_myID].isRandom == true) {
            reclaimUnclaimed();
            disburseFunds(qID[_myID].weekNo);
            setWinningNumbers(qID[_myID].weekNo, _result);
            if (qID[_myID].isManual == true) return;
            bytes32 query = oraclize_query(matchesDelay, "nested", strConcat(apiStr1, uint2str(qID[_myID].weekNo), apiStr2), gasAmt);
            qID[query].weekNo = qID[_myID].weekNo;
            emit LogQuerySent(query, matchesDelay + now, now);
        } else {
            newRaffle();
            setPayOuts(qID[_myID].weekNo, _result);
            if (qID[_myID].isManual == true) return;
            uint delay = (getWeek() * WEEKDUR) + BIRTHDAY + rafEnd + resultsDelay;
            query = oraclize_query(delay, "nested", strConcat(randomStr1, uint2str(getWeek()), randomStr2), gasAmt);
            qID[query].weekNo = getWeek();
            qID[query].isRandom = true;
            emit LogQuerySent(query, delay, now);
        }
    }
    /**
     * @dev   Slices a string according to specified delimiter, returning
     *        the sliced parts in an array.
     *
     * @param _string   The string to be sliced.
     */
    function stringToArray(string _string) internal returns (string[]) {
        var str    = _string.toSlice();
        var delim  = ",".toSlice();
        var parts  = new string[](str.count(delim) + 1);
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = str.split(delim).toString();
        }
        return parts;
    }
    /**
     * @dev   Takes oraclize random.org api call result string and splits
     *        it at the commas into an array, parses those strings in that
     *        array as integers and pushes them into the winning numbers
     *        array in the raffle&#39;s struct. Fires event logging the data,
     *        including the serial number of the random.org callback so
     *        its veracity can be proven.
     *
     * @param _week    The week number of the raffle in question.
     * @param _result   The results string from oraclize callback.
     */
    function setWinningNumbers(uint _week, string _result) internal {
        string[] memory arr = stringToArray(_result);
        for (uint i = 0; i < arr.length; i++){
            raffle[_week].winNums.push(parseInt(arr[i]));
        }
        uint serialNo = parseInt(arr[6]);
        emit LogWinningNumbers(_week, raffle[_week].numEntries, raffle[_week].winNums, prizePool, serialNo, now);
    }
    /*  
     * @dev     Returns TOTAL payout per tier when calculated using the odds method.
     *
     * @param _numWinners       Number of X match winners
     * @param _matchesIndex     Index of matches array (∴ 3 match win, 4 match win etc)
     */
    function oddsTotal(uint _numWinners, uint _matchesIndex) internal view returns (uint) {
        return oddsSingle(_matchesIndex) * _numWinners;
    }
    /*
     * @dev     Returns TOTAL payout per tier when calculated using the splits method.
     *
     * @param _numWinners       Number of X match winners
     * @param _matchesIndex     Index of matches array (∴ 3 match win, 4 match win etc)
     */
    function splitsTotal(uint _numWinners, uint _matchesIndex) internal view returns (uint) {
        return splitsSingle(_numWinners, _matchesIndex) * _numWinners;
    }
    /*
     * @dev     Returns single payout when calculated using the odds method.
     *
     * @param _matchesIndex     Index of matches array (∴ 3 match win, 4 match win etc)
     */
    function oddsSingle(uint _matchesIndex) internal view returns (uint) {
        return tktPrice * odds[_matchesIndex];
    }
    /*
     * @dev     Returns a single payout when calculated using the splits method.
     *
     * @param _numWinners       Number of X match winners
     * @param _matchesIndex     Index of matches array (∴ 3 match win, 4 match win etc)
     */
    function splitsSingle(uint _numWinners, uint _matchesIndex) internal view returns (uint) {
        return (prizePool * pctOfPool[_matchesIndex]) / (_numWinners * 1000);
    }
    /**
     * @dev   Takes the results of the oraclize Etheraffle api call back
     *        and uses them to calculate the prizes due to each tier
     *        (3 matches, 4 matches etc) then pushes them into the winning
     *        amounts array in the raffle in question&#39;s struct. Calculates
     *        the total winnings of the raffle, subtracts it from the
     *        global prize pool sequesters that amount into the raffle&#39;s
     *        struct "unclaimed" variable, ∴ "rolling over" the unwon
     *        ether. Enables winner withdrawals by setting the withdraw
     *        open bool to true.
     *
     * @param _week    The week number of the raffle in question.
     * @param _result  The results string from oraclize callback.
     */
    function setPayOuts(uint _week, string _result) internal {
        string[] memory numWinnersStr = stringToArray(_result);
        if (numWinnersStr.length < 4) return pauseContract(2);
        uint[] memory numWinnersInt = new uint[](4);
        for (uint i = 0; i < 4; i++) {
            numWinnersInt[i] = parseInt(numWinnersStr[i]);
        }
        uint[] memory payOuts = new uint[](4);
        uint total;
        for (i = 0; i < 4; i++) {
            if (numWinnersInt[i] != 0) {
                uint amt = oddsTotal(numWinnersInt[i], i) <= splitsTotal(numWinnersInt[i], i) 
                         ? oddsSingle(i) 
                         : splitsSingle(numWinnersInt[i], i); 
                payOuts[i] = amt;
                total += payOuts[i] * numWinnersInt[i];
            }
        }
        raffle[_week].unclaimed = total;
        if (raffle[_week].unclaimed > prizePool) return pauseContract(3);
        prizePool -= raffle[_week].unclaimed;
        for (i = 0; i < payOuts.length; i++) {
            raffle[_week].winAmts.push(payOuts[i]);
        }
        raffle[_week].wdrawOpen = true;
        emit LogPrizePoolsUpdated(prizePool, _week, raffle[_week].unclaimed, payOuts[0], payOuts[1], payOuts[2], payOuts[3], now);
    }
    /**
     * @dev   Function compares array of entrant&#39;s 6 chosen numbers to
      *       the raffle in question&#39;s winning numbers, counting how
      *       many matches there are.
      *
      * @param _week         The week number of the Raffle in question
      * @param _entrant      Entrant&#39;s ethereum address
      * @param _entryNum     number of entrant&#39;s entry in question.
     */
    function getMatches(uint _week, address _entrant, uint _entryNum) constant internal returns (uint) {
        uint matches;
        for (uint i = 0; i < 6; i++) {
            for (uint j = 0; j < 6; j++) {
                if (raffle[_week].entries[_entrant][_entryNum - 1][i] == raffle[_week].winNums[j]) {
                    matches++;
                    break;
                }
            }
        }
        return matches;
    }
    /**
     * @dev     Manually make an Oraclize API call, incase of automation
     *          failure. Only callable by the Etheraffle address.
     *
     * @param _delay      Either a time in seconds before desired callback
     *                    time for the API call, or a future UTC format time for
     *                    the desired time for the API callback.
     * @param _week       The week number this query is for.
     * @param _isRandom   Whether or not the api call being made is for
     *                    the random.org results draw, or for the Etheraffle
     *                    API results call.
     * @param _isManual   The Oraclize call back is a recursive function in
     *                    which each call fires off another call in perpetuity.
     *                    This bool allows that recursiveness for this call to be
     *                    turned on or off depending on caller&#39;s requirements.
     */
    function manuallyMakeOraclizeCall
    (
        uint _week,
        uint _delay,
        bool _isRandom,
        bool _isManual,
        bool _status
    )
        onlyEtheraffle external
    {
        paused = _status;
        string memory weekNumStr = uint2str(_week);
        if (_isRandom == true){
            bytes32 query = oraclize_query(_delay, "nested", strConcat(randomStr1, weekNumStr, randomStr2), gasAmt);
            qID[query].weekNo   = _week;
            qID[query].isRandom = true;
            qID[query].isManual = _isManual;
        } else {
            query = oraclize_query(_delay, "nested", strConcat(apiStr1, weekNumStr, apiStr2), gasAmt);
            qID[query].weekNo   = _week;
            qID[query].isManual = _isManual;
        }
    }
    /**
     * @dev    Set the Oraclize strings, in case of url changes. Only callable by
     *         the Etheraffle address  .
     *
     * @param _newRandomHalfOne       string - with properly escaped characters for
     *                                the first half of the random.org call string.
     * @param _newRandomHalfTwo       string - with properly escaped characters for
     *                                the second half of the random.org call string.
     * @param _newEtheraffleHalfOne   string - with properly escaped characters for
     *                                the first half of the EtheraffleAPI call string.
     * @param _newEtheraffleHalfTwo   string - with properly escaped characters for
     *                                the second half of the EtheraffleAPI call string.
     *
     */
    function setOraclizeString
    (
        string _newRandomHalfOne,
        string _newRandomHalfTwo,
        string _newEtheraffleHalfOne,
        string _newEtheraffleHalfTwo
    )
        onlyEtheraffle external
    {
        randomStr1 = _newRandomHalfOne;
        randomStr2 = _newRandomHalfTwo;
        apiStr1    = _newEtheraffleHalfOne;
        apiStr2    = _newEtheraffleHalfTwo;
    }
    /**
     * @dev   Set the ticket price of the raffle. Only callable by the
     *        Etheraffle address.
     *
     * @param _newPrice   uint - The desired new ticket price.
     *
     */
    function setTktPrice(uint _newPrice) onlyEtheraffle external {
        tktPrice = _newPrice;
    }
    /**
     * @dev    Set new take percentage. Only callable by the Etheraffle
     *         address.
     *
     * @param _newTake   uint - The desired new take, parts per thousand.
     *
     */
    function setTake(uint _newTake) onlyEtheraffle external {
        take = _newTake;
    }
    /**
     * @dev     Set the payouts manually, in case of a failed Oraclize call.
     *          Only callable by the Etheraffle address.
     *
     * @param _week         The week number of the raffle to set the payouts for.
     * @param _numMatches   Number of matches. Comma-separated STRING of 4
     *                      integers long, consisting of the number of 3 match
     *                      winners, 4 match winners, 5 & 6 match winners in
     *                      that order.
     */
    function setPayouts(uint _week, string _numMatches) onlyEtheraffle external {
        setPayOuts(_week, _numMatches);
    }
    /**
     * @dev   Set the FreeLOT token contract address, in case of future updrades.
     *        Only allable by the Etheraffle address.
     *
     * @param _newAddr   New address of FreeLOT contract.
     */
    function setFreeLOT(address _newAddr) onlyEtheraffle external {
        freeLOT = FreeLOTInterface(_newAddr);
      }
    /**
     * @dev   Set the EthRelief contract address, and gas required to run
     *        the receiving function. Only allable by the Etheraffle address.
     *
     * @param _newAddr   New address of the EthRelief contract.
     */
    function setEthRelief(address _newAddr) onlyEtheraffle external {
        ethRelief = _newAddr;
    }
    /**
     * @dev   Set the dividend contract address, and gas required to run
     *        the receive ether function. Only callable by the Etheraffle
     *        address.
     *
     * @param _newAddr   New address of dividend contract.
     */
    function setDisbursingAddr(address _newAddr) onlyEtheraffle external {
        disburseAddr = _newAddr;
    }
    /**
     * @dev   Set the Etheraffle multisig contract address, in case of future
     *        upgrades. Only callable by the current Etheraffle address.
     *
     * @param _newAddr   New address of Etheraffle multisig contract.
     */
    function setEtheraffle(address _newAddr) onlyEtheraffle external {
        etheraffle = _newAddr;
    }
    /**
     * @dev     Set the raffle end time, in number of seconds passed
     *          the start time of 00:00am Monday. Only callable by
     *          the Etheraffle address.
     *
     * @param _newTime    The time desired in seconds.
     */
    function setRafEnd(uint _newTime) onlyEtheraffle external {
        rafEnd = _newTime;
    }
    /**
     * @dev     Set the wdrawBfr time - the time a winner has to withdraw
     *          their winnings before the unclaimed prizepool is rolled
     *          back into the global prizepool. Only callable by the
     *          Etheraffle address.
     *
     * @param _newTime    The time desired in seconds.
     */
    function setWithdrawBeforeTime(uint _newTime) onlyEtheraffle external {
        wdrawBfr = _newTime;
    }
    /**
     * @dev     Set the paused status of the raffles. Only callable by
     *          the Etheraffle address.
     *
     * @param _status    The desired status of the raffles.
     */
    function setPaused(bool _status) onlyEtheraffle external {
        paused = _status;
    }
    /**
     * @dev     Set the percentage-of-prizepool array. Only callable by the
     *          Etheraffle address.
     *
     * @param _newPoP     An array of four integers totalling 1000.
     */
    function setPercentOfPool(uint[] _newPoP) onlyEtheraffle external {
        pctOfPool = _newPoP;
    }
    /**
     * @dev     Get a entrant&#39;s number of entries into a specific raffle
     *
     * @param _week       The week number of the queried raffle.
     * @param _entrant    The entrant in question.
     */
    function getUserNumEntries(address _entrant, uint _week) constant external returns (uint) {
        return raffle[_week].entries[_entrant].length;
    }
    /**
     * @dev     Get chosen numbers of an entrant, for a specific raffle.
     *          Returns an array.
     *
     * @param _entrant    The entrant in question&#39;s address.
     * @param _week       The week number of the queried raffle.
     * @param _entryNum   The entrant&#39;s entry number in this raffle.
     */
    function getChosenNumbers(address _entrant, uint _week, uint _entryNum) constant external returns (uint[]) {
        return raffle[_week].entries[_entrant][_entryNum-1];
    }
    /**
     * @dev     Get winning details of a raffle, ie, it&#39;s winning numbers
     *          and the prize amounts. Returns two arrays.
     *
     * @param _week   The week number of the raffle in question.
     */
    function getWinningDetails(uint _week) constant external returns (uint[], uint[]) {
        return (raffle[_week].winNums, raffle[_week].winAmts);
    }
    /**
     * @dev     Upgrades the Etheraffle contract. Only callable by the
     *          Etheraffle address. Calls an addToPrizePool method as
     *          per the abstract contract above. Function renders the
     *          entry method uncallable, cancels the Oraclize recursion,
     *          then zeroes the prizepool and sends the funds to the new
     *          contract. Sets a var tracking when upgrade occurred and logs
     *          the event.
     *
     * @param _newAddr   The new contract address.
     */
    function upgradeContract(address _newAddr) onlyEtheraffle external {
        require(upgraded == 0 && upgradeAddr == address(0));
        uint amt    = prizePool;
        upgradeAddr = _newAddr;
        upgraded    = now;
        week        = 0;
        prizePool   = 0;
        gasAmt      = 0;
        apiStr1     = "";
        randomStr1  = "";
        require(this.balance >= amt);
        EtheraffleUpgrade(_newAddr).addToPrizePool.value(amt)();
        emit LogUpgrade(_newAddr, amt, upgraded);
    }
    /**
     * @dev     Self destruct contract. Only callable by Etheraffle address.
     *          function. It deletes all contract code and data and forwards
     *          any remaining ether from non-claimed winning raffle tickets
     *          to the EthRelief charity contract. Requires the upgrade contract
     *          method to have been called 10 or more weeks prior, to allow
     *          winning tickets to be claimed within the usual withdrawal time
     *          frame.
     */
    function selfDestruct() onlyEtheraffle external {
        require(now - upgraded > WEEKDUR * 10);
        selfdestruct(ethRelief);
    }
    /**
     * @dev     Function allowing manual addition to the global prizepool.
     *          Requires the caller to send ether.
     */
    function addToPrizePool() payable external {
        require(msg.value > 0);
        prizePool += msg.value;
        emit LogPrizePoolAddition(msg.sender, msg.value, now);
    }
    /**
     * @dev   Fallback function.
     */
    function () payable external {}
}