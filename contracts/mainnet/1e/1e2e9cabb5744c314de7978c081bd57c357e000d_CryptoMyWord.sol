pragma solidity ^0.4.19;
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
    function toSlice(string self) internal pure returns (slice) {
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
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
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
    function copy(slice self) internal pure returns (slice) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice&#39;s text.
     */
    function toString(slice self) internal pure returns (string) {
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
    function len(slice self) internal pure returns (uint l) {
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
    function empty(slice self) internal pure returns (bool) {
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
    function compare(slice self, slice other) internal pure returns (int) {
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
                uint256 mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
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
    function equals(slice self, slice other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice self, slice rune) internal pure returns (slice) {
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
    function nextRune(slice self) internal pure returns (slice ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice self) internal pure returns (uint ret) {
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
    function keccak(slice self) internal pure returns (bytes32 ret) {
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
    function startsWith(slice self, slice needle) internal pure returns (bool) {
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
    function beyond(slice self, slice needle) internal pure returns (slice) {
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
    function endsWith(slice self, slice needle) internal pure returns (bool) {
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
    function until(slice self, slice needle) internal pure returns (slice) {
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

    event log_bytemask(bytes32 mask);

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
                assembly { hash := sha3(needleptr, needlelen) }

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
    function find(slice self, slice needle) internal pure returns (slice) {
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
    function rfind(slice self, slice needle) internal pure returns (slice) {
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
    function split(slice self, slice needle, slice token) internal pure returns (slice) {
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
    function split(slice self, slice needle) internal pure returns (slice token) {
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
    function rsplit(slice self, slice needle, slice token) internal pure returns (slice) {
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
    function rsplit(slice self, slice needle) internal pure returns (slice token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice self, slice needle) internal pure returns (uint cnt) {
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
    function contains(slice self, slice needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice self, slice other) internal pure returns (string) {
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
    function join(slice self, slice[] parts) internal pure returns (string) {
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


contract CryptoMyWord {
  using SafeMath for uint256;
  using strings for *;

  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event NewWord(uint wordId, string name, uint price);

  address private owner;
  uint256 nameTokenId;
  uint256 tokenId;
  mapping (address => bool) private admins;
  //IItemRegistry private itemRegistry;
  bool private erc721Enabled = false;

  uint256 private increaseLimit1 = 0.8 ether;
  uint256 private increaseLimit2 = 1.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;

  uint256[] private listedItems;
  mapping (uint256 => address) public ownerOfItem;
  mapping (address => string) public nameOfOwner;
  mapping (address => string) public snsOfOwner;
  mapping (uint256 => uint256) private startingPriceOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => string) private nameOfItem;
  mapping (uint256 => string) private urlOfItem;
  mapping (uint256 => address[]) private borrowerOfItem;
  mapping (string => uint256[]) private nameToItems;
  mapping (uint256 => address) private approvedOfItem;
  mapping (string => uint256) private nameToParents;
  mapping (string => uint256) private nameToNameToken;
  mapping (string => string) private firstIdOfName;
  mapping (string => string) private secondIdOfName;

  function CryptoMyWord () public {
    owner = msg.sender;
    admins[owner] = true;
  }

  struct Token {
    address firstMintedBy;
    uint64 mintedAt;
    uint256 startingPrice;
    uint256 priceOfItem;
    string name;
    string url;
    string firstIdOfName;
    string secondIdOfName;
    address owner;
  }
  Token[] public tokens;
  struct Name {
    string name;
    uint256 parent;
  }
  Name[] public names;
  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }

  modifier onlyERC721() {
    require(erc721Enabled);
    _;
  }

  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function getOwner () view public returns(address) {
    return owner;
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }

  // Unlocks ERC721 behaviour, allowing for trading on third party platforms.
  function enableERC721 () onlyOwner() public {
    erc721Enabled = true;
  }

  // locks ERC721 behaviour, allowing for trading on third party platforms.
  function disableERC721 () onlyOwner() public {
    erc721Enabled = false;
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll () onlyOwner() public {
    owner.transfer(this.balance);
  }

  function withdrawAmount (uint256 _amount) onlyOwner() public {
    owner.transfer(_amount);
  }


  function listItem (uint256 _price, address _owner, string _name) onlyAdmins() public {
    require(nameToItems[_name].length == 0);
    Token memory token = Token({
      firstMintedBy: _owner,
      mintedAt: uint64(now),
      startingPrice: _price,
      priceOfItem: _price,
      name: _name,
      url: "",
      firstIdOfName: "",
      secondIdOfName: "",
      owner: _owner
    });
    tokenId = tokens.push(token) - 1;
    Name memory namesval = Name({
      name: _name,
      parent: tokenId
    });
    ownerOfItem[tokenId] = _owner;
    priceOfItem[tokenId] = _price;
    startingPriceOfItem[tokenId] = _price;
    nameOfItem[tokenId] = _name;
    nameToItems[_name].push(tokenId);
    listedItems.push(tokenId);
    nameToParents[_name] = tokenId;
    nameTokenId = names.push(namesval) - 1;
    nameToNameToken[_name] = nameTokenId;
  }

  function _mint (uint256 _price, address _owner, string _name, string _url) internal {
    address firstOwner = _owner;
    if(nameToItems[_name].length != 0){
      firstOwner = ownerOf(nameToParents[_name]);
      if(admins[firstOwner]){
        firstOwner = _owner;
      }
    }
    Token memory token = Token({
      firstMintedBy: firstOwner,
      mintedAt: uint64(now),
      startingPrice: _price,
      priceOfItem: _price,
      name: _name,
      url: "",
      firstIdOfName: "",
      secondIdOfName: "",
      owner: _owner
    });
    tokenId = tokens.push(token) - 1;
    Name memory namesval = Name({
      name: _name,
      parent: tokenId
    });
    if(nameToItems[_name].length != 0){
      names[nameToNameToken[_name]] = namesval;
    }
    ownerOfItem[tokenId] = _owner;
    priceOfItem[tokenId] = _price;
    startingPriceOfItem[tokenId] = _price;
    nameOfItem[tokenId] = _name;
    urlOfItem[tokenId] = _url;
    nameToItems[_name].push(tokenId);
    listedItems.push(tokenId);
    nameToParents[_name] = tokenId;
  }

  function composite (uint256 _firstId, uint256 _secondId, uint8 _space) public {
    int counter1 = 0;
    for (uint i = 0; i < borrowerOfItem[_firstId].length; i++) {
      if (borrowerOfItem[_firstId][i] == msg.sender) {
        counter1++;
      }
    }
    int counter2 = 0;
    for (uint i2 = 0; i2 < borrowerOfItem[_secondId].length; i2++) {
      if (borrowerOfItem[_secondId][i2] == msg.sender) {
        counter2++;
      }
    }
    require(ownerOfItem[_firstId] == msg.sender || counter1 > 0);
    require(ownerOfItem[_secondId] == msg.sender || counter2 > 0);
    string memory compositedName1 = nameOfItem[_firstId];
    string memory space = " ";
    if(_space > 0){
      compositedName1 = nameOfItem[_firstId].toSlice().concat(space.toSlice());
    }
    string memory compositedName = compositedName1.toSlice().concat(nameOfItem[_secondId].toSlice());
    require(nameToItems[compositedName].length == 0);
    firstIdOfName[compositedName] = nameOfItem[_firstId];
    secondIdOfName[compositedName] = nameOfItem[_secondId];
    _mint(0.01 ether, msg.sender, compositedName, "");
  }

  function setUrl (uint256 _tokenId, string _url) public {
    require(ownerOf(_tokenId) == msg.sender);
    tokens[_tokenId].url = _url;
  }

  /* Buying */
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(95); // 1.95
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(95); //1.3
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(95); //1.2
    } else if (_price < increaseLimit4) {
      return _price.mul(120).div(95); //1.12
    } else {
      return _price.mul(115).div(95); //1.1
    }
  }

  function calculateDevCut (uint256 _price) public pure returns (uint256 _devCut) {
    return _price.mul(4).div(100);
  }
  function calculateFirstCut (uint256 _price) public pure returns (uint256 _firstCut) {
    return _price.mul(1).div(100);
  }
  function ceil(uint a) public pure returns (uint ) {
    return uint(int(a * 100) / 100);
  }
  /*
     Buy a country directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All countries that
     have been listed can be bought by this method. User funds are sent
     directly to the previous owner and are never stored in the contract.
  */
  function buy (uint256 _itemId) payable public {
    require(priceOf(_itemId) > 0);
    require(ownerOf(_itemId) != address(0));
    require(msg.value >= priceOf(_itemId));
    require(ownerOf(_itemId) != msg.sender);
    require(!isContract(msg.sender));
    require(msg.sender != address(0));
    address firstOwner = tokens[_itemId].firstMintedBy;
    address oldOwner = ownerOf(_itemId);
    address newOwner = msg.sender;
    uint256 price = ceil(priceOf(_itemId));
    uint256 excess = msg.value.sub(price);
    string memory name = nameOf(_itemId);
    uint256 nextPrice = ceil(nextPriceOf(_itemId));
    //_transfer(oldOwner, newOwner, _itemId);
    _mint(nextPrice, newOwner, name, "");
    priceOfItem[_itemId] = nextPrice;

    Bought(_itemId, newOwner, price);
    Sold(_itemId, oldOwner, price);

    // Devevloper&#39;s cut which is left in contract and accesed by
    // `withdrawAll` and `withdrawAmountTo` methods.
    uint256 devCut = ceil(calculateDevCut(price));
    uint256 firstCut = ceil(calculateFirstCut(price));
    // Transfer payment to old owner minus the developer&#39;s cut.
    oldOwner.transfer(price.sub(devCut));
    firstOwner.transfer(price.sub(firstCut));
    if (excess > 0) {
      newOwner.transfer(excess);
    }
  }

  /* ERC721 */
  function implementsERC721() public view returns (bool _implements) {
    return erc721Enabled;
  }

  function name() public pure returns (string _name) {
    return "CryptoMyWord";
  }

  function symbol() public pure returns (string _symbol) {
    return "CMW";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return listedItems.length;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;

    for (uint256 i = 0; i < listedItems.length; i++) {
      if (ownerOf(listedItems[i]) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf (uint256 _itemId) public view returns (address _owner) {
    return ownerOfItem[_itemId];
  }

  function tokensOf (address _owner) external view returns (uint256[] _tokenIds) {
    uint256[] memory result = new uint256[](balanceOf(_owner));

    uint256 itemCounter = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      if (ownerOfItem[i] == _owner) {
        result[itemCounter] = i;
        itemCounter++;
      }
    }

    return result;
  }

  function getNames () external view returns (uint256[] _tokenIds){
    uint256[] memory result = new uint256[](names.length);
    uint256 itemCounter = 0;
    for (uint i = 0; i < names.length; i++) {
      result[itemCounter] = nameToNameToken[names[itemCounter].name];
      itemCounter++;
    }
    return result;
  }

  function tokenExists (uint256 _itemId) public view returns (bool _exists) {
    return priceOf(_itemId) > 0;
  }

  function approvedFor(uint256 _itemId) public view returns (address _approved) {
    return approvedOfItem[_itemId];
  }

  function approve(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender != _to);
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == msg.sender);

    if (_to == 0) {
      if (approvedOfItem[_itemId] != 0) {
        delete approvedOfItem[_itemId];
        Approval(msg.sender, 0, _itemId);
      }
    } else {
      approvedOfItem[_itemId] = _to;
      Approval(msg.sender, _to, _itemId);
    }
  }

  /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
  function transfer(address _to, uint256 _itemId) onlyERC721() public {
    require(msg.sender == ownerOf(_itemId));
    _transfer(msg.sender, _to, _itemId);
  }

  function transferFrom(address _from, address _to, uint256 _itemId) onlyERC721() public {
    require(approvedFor(_itemId) == msg.sender);
    _transfer(_from, _to, _itemId);
  }

  function _transfer(address _from, address _to, uint256 _itemId) internal {
    require(tokenExists(_itemId));
    require(ownerOf(_itemId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfItem[_itemId] = _to;
    approvedOfItem[_itemId] = 0;

    Transfer(_from, _to, _itemId);
  }

  /* Read */
  function isAdmin (address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  function startingPriceOf (uint256 _itemId) public view returns (uint256 _startingPrice) {
    return startingPriceOfItem[_itemId];
  }

  function priceOf (uint256 _itemId) public view returns (uint256 _price) {
    return priceOfItem[_itemId];
  }

  function nextPriceOf (uint256 _itemId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_itemId));
  }

  function nameOf (uint256 _itemId) public view returns (string _name) {
    return nameOfItem[_itemId];
  }

  function itemsByName (string _name) public view returns (uint256[] _items){
    return nameToItems[_name];
  }

  function allOf (uint256 _itemId) external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice) {
    return (ownerOf(_itemId), startingPriceOf(_itemId), priceOf(_itemId), nextPriceOf(_itemId));
  }

  function allForPopulate (uint256 _itemId) onlyOwner() external view returns (address _owner, uint256 _startingPrice, uint256 _price, uint256 _nextPrice) {
    return (ownerOf(_itemId), startingPriceOf(_itemId), priceOf(_itemId), nextPriceOf(_itemId));
  }

  function selfDestruct () onlyOwner() public{
    selfdestruct(owner);
  }

  function itemsForSaleLimit (uint256 _from, uint256 _take) public view returns (uint256[] _items) {
    uint256[] memory items = new uint256[](_take);

    for (uint256 i = 0; i < _take; i++) {
      items[i] = listedItems[_from + i];
    }

    return items;
  }

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // solium-disable-line
    return size > 0;
  }
}