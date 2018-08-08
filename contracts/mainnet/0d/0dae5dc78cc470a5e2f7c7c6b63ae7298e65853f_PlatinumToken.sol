pragma solidity ^0.4.13;

library ConvertStringByte {
  function bytes32ToString(bytes32 x) constant returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
          bytesString[charCount] = char;
          charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }
    return string(bytesStringTrimmed);
  }

  function stringToBytes32(string memory source) returns (bytes32 result) {
    assembly {
      result := mload(add(source, 32))
    }
  }
}

library Strings {
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
    function len(slice self) internal returns (uint) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (uint len = 0; ptr < end; len++) {
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
        return len;
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
        uint len;
        uint div = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        var b = word / div;
        if (b < 0x80) {
            ret = b;
            len = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            len = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            len = 3;
        } else {
            ret = b & 0x07;
            len = 4;
        }

        // Check for truncated codepoints
        if (len > self._len) {
            return 0;
        }

        for (uint i = 1; i < len; i++) {
            div = div / 256;
            b = (word / div) & 0xFF;
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
            ret := sha3(mload(add(self, 32)), mload(self))
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
            let len := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
                let len := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
            let len := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
                let len := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
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
    function count(slice self, slice needle) internal returns (uint count) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            count++;
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

        uint len = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            len += parts[i]._len;

        var ret = new string(len);
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


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Platinum is Ownable {
  using SafeMath for uint256;
  using Strings for *;

  // ========= 宣告 =========
  string public version = "0.0.1";
  // 基本單位
  string public unit = "oz";
  // 總供給量
  uint256 public total;
  // 存貨
  struct Bullion {
    string index;
    string unit;
    uint256 amount;
    string ipfs;
  }
  bytes32[] public storehouseIndex;
  mapping (bytes32 => Bullion) public storehouse;
  // 掛勾貨幣
  address public token;
  // 匯率 1白金：白金幣
  uint256 public rate = 10;
  // PlatinumToken 實例
  PlatinumToken coin;





  // ========= 初始化 =========
  function Platinum() {

  }




  // ========= event =========
  event Stock (
    string index,
    string unit,
    uint256 amount,
    string ipfs,
    uint256 total
  );

  event Ship (
    string index,
    uint256 total
  );

  event Mint (
    uint256 amount,
    uint256 total
  );

  event Alchemy (
    uint256 amount,
    uint256 total
  );

  event Buy (
    string index,
    address from,
    uint256 fee,
    uint256 price
  );






  // ========= 擁有者方法 =========

  /**
   * 操作存貨-進貨
   *
   * 此方法執行：
   *  - 紀錄新增的白金，紀錄資訊：
   *    - index: 白金編號
   *    - unit: 白金單位
   *    - amount: 數量
   *    - ipfs: 白金證明URL
   *  - 增加白金總庫存數量，量為amount
   *
   * Requires:
   *  - 執行者須為owner
   *  - 白金編號index不能重複
   *  - 單位須等於目前合約所設定的單位
   *  - 量amount需大於0
   *
   * Returns:
   *  - bool: 執行成功時，回傳true
   *
   * Events:
   *  - Stock: 執行成功時觸發
   */
  function stock(string _index, string _unit, uint256 _amount, string _ipfs) onlyOwner returns (bool) {
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);

    require(_amount > 0);
    require(_unit.toSlice().equals(unit.toSlice()));
    require(!(storehouse[_bindex].amount > 0));

    Bullion bullion = storehouse[_bindex];
    bullion.index = _index;
    bullion.unit = _unit;
    bullion.amount = _amount;
    bullion.ipfs = _ipfs;

    // 加入倉儲目錄
    storehouseIndex.push(_bindex);
    // 加入倉儲
    storehouse[_bindex] = bullion;

    // 增加總庫存
    total = total.add(_amount);

    Stock(bullion.index, bullion.unit, bullion.amount, bullion.ipfs, total);

    return true;
  }

  /**
   * 操作存貨-出貨
   *
   * 此方法執行：
   *  - 移除白金庫存
   *  - 減少白金總庫存量，量為白金庫存的數量
   *
   * Requires:
   *  - 執行者為owner
   *  - 白金編號index需存在於紀錄（已使用stock方法新增該庫存）
   *  - 白金總庫存需足夠，大於指定白金庫存的數量
   *
   * Returns:
   *  - bool: 執行成功時，回傳true
   *
   * Events:
   *  - Ship: 執行成功時觸發
   */
  function ship(string _index) onlyOwner returns (bool) {
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);

    require(storehouse[_bindex].amount > 0);
    Bullion bullion = storehouse[_bindex];
    require(total.sub(bullion.amount) >= 0);

    uint256 tmpAmount = bullion.amount;

    for (uint256 index = 0; index < storehouseIndex.length; index++) {
      Bullion _bullion = storehouse[storehouseIndex[index]];
      if (_bullion.index.toSlice().equals(_index.toSlice())) {
        // 從倉儲目錄移除
        delete storehouseIndex[index];
      }
    }
    // 從倉儲移除
    delete storehouse[_bindex];
    // 減少總庫存
    total = total.sub(tmpAmount);

    Ship(bullion.index, total);

    return true;
  }

  /**
   * 鑄幣
   *
   * 此方法執行：
   *  - 增加白金代幣數量
   *  - 減少總白金庫存
   *
   * Requires:
   *  - 執行者為owner
   *  - 白金總庫存需足夠，即大於等於ptAmount
   *  - 白金代幣合約需已設定（setTokenAddress方法）
   *
   * Returns:
   *  - bool: 執行成功時，回傳true
   *
   * Events:
   *  - Mint: 執行成功時觸發
   */
  function mint(uint256 _ptAmount) onlyOwner returns (bool) {
    require(token != 0x0);

    uint256 amount = convert2PlatinumToken(_ptAmount);
    // 發送token的增加涵式
    bool produced = coin.produce(amount);
    require(produced);

    total = total.sub(_ptAmount);

    Mint(_ptAmount, total);

    return true;
  }

  /**
   * 煉金
   *
   * 此方法執行：
   *  - 減少白金代幣
   *  - 增加總白金庫存
   *
   * Requires:
   *  - 執行者為owner
   *  - 需已設定白金代幣合約（setTokenAddress方法）
   *  - 白金代幣owner所擁有的代幣足夠，即tokenAmount小於等於代幣owner的白金代幣數量
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   *
   * Events:
   *  - Alchemy: 執行成功時觸發
   */
  function alchemy(uint256 _tokenAmount) onlyOwner returns (bool) {
    require(token != 0x0);

    uint256 amount = convert2Platinum(_tokenAmount);
    bool reduced = coin.reduce(_tokenAmount);
    require(reduced);

    total = total.add(amount);

    Alchemy(amount, total);

    return true;
  }

  /**
   * 設定-匯率
   *
   * 匯率規則:
   *  - 白金數量 * 匯率 = 白金代幣數量
   *  - 白金代幣數量 / 匯率 = 白金數量
   *
   * Requires:
   *  - 執行者為owner
   *  - 匯率rate需大於0
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   */
  function setRate(uint256 _rate) onlyOwner returns (bool) {
    require(_rate > 0);

    rate = _rate;
    return true;
  }

  /**
   * 設定-Token地址
   *
   * 設定白金合約地址
   *
   * Requires:
   *  - 執行者為owner
   *  - 合約地址address不為0
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   */
  function setTokenAddress(address _address) onlyOwner returns (bool) {
    require(_address != 0x0);

    coin = PlatinumToken(_address);
    token = _address;
    return true;
  }

  /**
   * 購買金條
   *
   * 此方法執行：
   *  - 扣除buyer的白金代幣
   *  - 移除白金庫存，代表buyer已從庫存買走白金
   *
   * Requires:
   *  - 執行者為owner
   *  - 白金編號index需存在於紀錄（已使用stock方法新增該庫存）
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   *
   * Events:
   *  - Buy: 執行成功時觸發
   */
  function buy(string _index, address buyer) onlyOwner returns (bool) {
    require(token != 0x0);
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);
    uint256 fee = coin.fee();
    require(storehouse[_bindex].amount > 0);

    Bullion bullion = storehouse[_bindex];
    uint256 tokenPrice = convert2PlatinumToken(bullion.amount);
    uint256 tokenPriceFee = tokenPrice.add(fee);

    // 轉帳
    bool transfered = coin.transferFrom(buyer, coin.owner(), tokenPriceFee);
    require(transfered);

    // 直接把剛剛賣出的價格煉金
    bool reduced = coin.reduce(tokenPrice);
    require(reduced);

    // 減少庫存
    for (uint256 index = 0; index < storehouseIndex.length; index++) {
      Bullion _bullion = storehouse[storehouseIndex[index]];
      if (_bullion.index.toSlice().equals(_index.toSlice())) {
        // 從倉儲目錄移除
        delete storehouseIndex[index];
      }
    }
    // 從倉儲移除
    delete storehouse[_bindex];

    Buy(_index, buyer, fee, tokenPrice);

    return true;
  }





  // ========= 公共方法 =========

  // 比率轉換-白金幣換白金
  function convert2Platinum(uint256 _amount) constant returns (uint256) {
    return _amount.div(rate);
  }

  // 比率轉換-白金換白金幣
  function convert2PlatinumToken(uint256 _amount) constant returns (uint256) {
    return _amount.mul(rate);
  }

  // 金條資訊
  function info(string _index) constant returns (string, string, uint256, string) {
    bytes32 _bindex = ConvertStringByte.stringToBytes32(_index);
    require(storehouse[_bindex].amount > 0);

    Bullion bullion = storehouse[_bindex];

    return (bullion.index, bullion.unit, bullion.amount, bullion.ipfs);
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PlatinumToken is Ownable, ERC20 {
  using SafeMath for uint256;
  // ========= 宣告 =========

  // 版本
  string public version = "0.0.1";
  // 名稱
  string public name;
  // 標記
  string public symbol;
  // 小數點位數
  uint256 public decimals;
  // 白金合約地址
  address public platinum;

  mapping (address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
  // 總供給量
  uint256 public totalSupply;
  // 手續費
  uint256 public fee = 10;

  // ========= 初始化 =========
  function PlatinumToken(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  /**
   * Transfer
   *
   * 傳送事件，當有白金代幣的所有權轉移時，此事件會被觸發
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  // ========= 權限控管 =========
  modifier isPlatinumContract() {
    require(platinum != 0x0);
    require(msg.sender == platinum);
    _;
  }

  modifier isOwnerOrPlatinumContract() {
    require(msg.sender != address(0) && (msg.sender == platinum || msg.sender == owner));
    _;
  }

  /**
   * 增產
   *
   *  此方法執行：
   *    - 增加owner的balance，量為指定的amount
   *    - 增加totalSupply，量為指定的amount
   *
   *  Requires:
   *    - 執行者為白金合約（可透過setPlatinumAddress方法設定）
   *    - amount須設定為0以上
   *
   *  Return:
   *    - bool: 執行成功回傳true
   */
  function produce(uint256 amount) isPlatinumContract returns (bool) {
    balances[owner] = balances[owner].add(amount);
    totalSupply = totalSupply.add(amount);

    return true;
  }

  /** 減產
   *
   *  此方法執行：
   *    - 減少owner的balance，量為指定的amount
   *    - 減少totalSupply，量為指定的amount
   *
   *  Requires:
   *    - 執行者為白金合約（可透過setPlatinumAddress方法設定）
   *    - amount須設定為0以上
   *    - owner的balance需大於等於指定的amount
   *    - totalSupply需大於等於指定的amount
   *
   *  Return:
   *    - bool: 執行成功回傳true
   */
  function reduce(uint256 amount) isPlatinumContract returns (bool) {
    require(balances[owner].sub(amount) >= 0);
    require(totalSupply.sub(amount) >= 0);

    balances[owner] = balances[owner].sub(amount);
    totalSupply = totalSupply.sub(amount);

    return true;
  }

  /**
   * 設定-白金合約地址
   *
   * 此方法執行：
   *  - 修改此合約所認識的白金合約地址，此地址決定能執行produce和reduce方法的合約
   *
   * Requires:
   *  - 執行者須為owner
   *  - 地址不能設為0
   *
   * Returns:
   *  - bool: 設定成功時回傳true
   */
  function setPlatinumAddress(address _address) onlyOwner returns (bool) {
    require(_address != 0x0);

    platinum = _address;
    return true;
  }

  /**
   * 設定-手續費
   *
   * 手續費規則：
   *  - 購買金條時，代幣量總量增加手續費為總扣除代幣總量
   *
   * Requires:
   *  - 執行者為owner
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   */
  function setFee(uint256 _fee) onlyOwner returns (bool) {
    require(_fee >= 0);

    fee = _fee;
    return true;
  }

  /**
   * 交易，轉移白金代幣
   *
   * 此方法執行：
   *  - 減少from的白金代幣，量為value
   *  - 增加to的白金代幣，量為value
   *
   * Requires:
   *  - 執行者為owner
   *
   * Returns:
   *  - bool: 執行成功回傳true
   *
   * Events:
   *  - Transfer: 執行成功時，觸發此事件
   */
  function transfer(address _to, uint256 _value) onlyOwner returns (bool) {
    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(owner, _to, _value);

    return true;
  }

  /**
   * 查詢白金代幣餘額
   *
   * Returns:
   *  - balance: 指定address的白金代幣餘額
   */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * 轉帳
   *
   * 實際將approve過的token數量進行交易
   *
   * 此方法執行：
   *  - 交易指定數量的代幣
   *
   * Requires:
   *  - 交易的代幣數量value需大於0
   *  - allowed的代幣數量需大於value（allowed的代幣先由呼叫approve方法設定）
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   */
  function transferFrom(address _from, address _to, uint256 _value) isOwnerOrPlatinumContract returns (bool) {
    var _allowance = allowed[_from][owner];

    uint256 valueSubFee = _value.sub(fee);

    balances[_to] = balances[_to].add(valueSubFee);
    balances[_from] = balances[_from].sub(_value);
    balances[owner] = balances[owner].add(fee);
    allowed[_from][owner] = _allowance.sub(_value);

    return true;
  }

  /**
   * 轉帳 - 允許
   *
   * 允許一定數量的代幣可以轉帳至owner
   *
   * 欲修改允許值，需先執行此方法將value設為0，再執行一次此方法將value設為指定值
   *
   * 此方法操作：
   *  - 修改allowed值，紀錄sender允許轉帳value數量代幣給owner
   *  - allowed值有設定時，value須為0
   *  - allowed值未設定時，value不為0
   *
   * Returns:
   *  - bool: 執行成功，回傳true
   */
  function approve(address _dummy, uint256 _value) returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][owner] == 0));
    // TODO whether or not to checkout the balance of the sender

    allowed[msg.sender][owner] = _value;
    Approval(msg.sender, owner, _value);
    return true;
  }

  /**
   * 轉帳 - 查詢允許值
   *
   * Returns:
   *  - unit256: 允許值
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}