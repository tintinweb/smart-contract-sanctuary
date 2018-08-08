pragma solidity 0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <arachnid@notdot.net>
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
     *      null-terminated utf-8 string.
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


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


pragma solidity 0.4.24;

contract SparksterToken is StandardToken, Ownable{
	using strings for *;
	using SafeMath for uint256;
	struct Member {
		address walletAddress;
		mapping(uint256 => bool) groupMemberships; // What groups does this member belong to?
		mapping(uint256 => uint256) ethBalance; // How much eth has this member contributed for this group?
		mapping(uint256 => uint256) tokenBalance; // The member&#39;s token balance in a specific group.
		uint256 max1; // Maximum amount this user can contribute for phase1.
		int256 transferred; // The amount of tokens the member has transferred out or been transferred in. Sending tokens out will increase this value and accepting tokens in will decrease it. In other words, the more negative this value is, the more unlocked tokens the member holds.
		bool exists; // A flag to see if we have a record of this member or not. If we don&#39;t, they won&#39;t be allowed to purchase.
	}

	struct Group {
		bool distributed; // Whether or not tokens in this group have been distributed.
		bool distributing; // This flag is set when we first enter the distribute function and is there to prevent race conditions, since distribution might take a long time.
		bool unlocked; // Whether or not tokens in this group have been unlocked.
		uint256 groupNumber; // This group&#39;s number
		uint256 ratio; // 1 eth:ratio tokens. This amount represents the decimal amount. ratio*10**decimal = ratio sparks.
		uint256 startTime; // Epoch of crowdsale start time.
		uint256 phase1endTime; // Epoch of phase1 end time.
		uint256 phase2endTime; // Epoch of phase2 end time.
		uint256 deadline; // No contributions allowed after this epoch.
		uint256 max2; // cap of phase2
		uint256 max3; // Total ether this group can collect in phase 3.
		uint256 ethTotal; // How much ether has this group collected?
		uint256 cap; // The hard ether cap.
		uint256 howManyDistributed;
	}

	bool internal transferLock = true; // A Global transfer lock. Set to lock down all tokens from all groups.
	bool internal allowedToSell = false;
	bool internal allowedToPurchase = false;
	string public name;									 // name for display
	string public symbol;								 //An identifier
	uint8 public decimals;							//How many decimals to show.
	uint256 internal maxGasPrice; // The maximum allowed gas for the purchase function.
	uint256 internal nextGroupNumber;
	uint256 public sellPrice; // sellPrice wei:1 spark token; we won&#39;t allow to sell back parts of a token.
	address[] internal allMembers;	
	address[] internal allNonMembers;
	mapping(address => bool) internal nonMemberTransfers;
	mapping(address => Member) internal members;
	mapping(uint256 => Group) internal groups;
	mapping(uint256 => address[]) internal associations; // Will hold a record of which addresses belong to which group.
	uint256 internal openGroupNumber;
	event PurchaseSuccess(address indexed _addr, uint256 _weiAmount,uint256 _totalEthBalance,uint256 _totalTokenBalance);
	event DistributeDone(uint256 groupNumber);
	event UnlockDone(uint256 groupNumber);
	event GroupCreated(uint256 groupNumber, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline, uint256 phase2cap, uint256 phase3cap, uint256 cap, uint256 ratio);
	event ChangedAllowedToSell(bool allowedToSell);
	event ChangedAllowedToPurchase(bool allowedToPurchase);
	event ChangedTransferLock(bool transferLock);
	event SetSellPrice(uint256 sellPrice);
	event Added(address walletAddress, uint256 group, uint256 tokens, uint256 maxContribution1);
	event SplitTokens(uint256 splitFactor);
	event ReverseSplitTokens(uint256 splitFactor);
	
	// Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
	modifier onlyPayloadSize(uint size) {	 
		require(msg.data.length == size + 4);
		_;
	}

	modifier canTransfer() {
		require(!transferLock);
		_;
	}

	modifier canPurchase() {
		require(allowedToPurchase);
		_;
	}

	modifier canSell() {
		require(allowedToSell);
		_;
	}

	function() public payable {
		purchase();
	}

	constructor() public {
		name = "Sparkster";									// Set the name for display purposes
		decimals = 18;					 // Amount of decimals for display purposes
		symbol = "SPRK";							// Set the symbol for display purposes
		setMaximumGasPrice(40);
		// Give all the tokens to the owner to start with.
		mintTokens(435000000);
	}
	
	function setMaximumGasPrice(uint256 gweiPrice) public onlyOwner returns(bool success) {
		maxGasPrice = gweiPrice.mul(10**9); // Convert the gwei value to wei.
		return true;
	}
	
	function parseAddr(string _a) pure internal returns (address){ // From Oraclize
		bytes memory tmp = bytes(_a);
		uint160 iaddr = 0;
		uint160 b1;
		uint160 b2;
		for (uint i=2; i<2+2*20; i+=2){
			iaddr *= 256;
			b1 = uint160(tmp[i]);
			b2 = uint160(tmp[i+1]);
			if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
			else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
			if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
			else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
			iaddr += (b1*16+b2);
		}
		return address(iaddr);
	}

	function parseInt(string _a, uint _b) pure internal returns (uint) {
		bytes memory bresult = bytes(_a);
		uint mint = 0;
		bool decim = false;
		for (uint i = 0; i < bresult.length; i++) {
			if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
				if (decim) {
					if (_b == 0) break;
						else _b--;
				}
				mint *= 10;
				mint += uint(bresult[i]) - 48;
			} else if (bresult[i] == 46) decim = true;
		}
		return mint;
	}

	function mintTokens(uint256 amount) public onlyOwner {
		// Here, we&#39;ll consider amount to be the full token amount, so we have to get its decimal value.
		uint256 decimalAmount = amount.mul(uint(10)**decimals);
		totalSupply_ = totalSupply_.add(decimalAmount);
		balances[msg.sender] = balances[msg.sender].add(decimalAmount);
		emit Transfer(address(0), msg.sender, decimalAmount); // Per erc20 standards-compliance.
	}
	
	function purchase() public canPurchase payable{
		require(msg.sender != address(0)); // Don&#39;t allow the 0 address.
		Member storage memberRecord = members[msg.sender];
		Group storage openGroup = groups[openGroupNumber];
		require(openGroup.ratio > 0); // Group must be initialized.
		require(memberRecord.exists && memberRecord.groupMemberships[openGroup.groupNumber] && !openGroup.distributing && !openGroup.distributed && !openGroup.unlocked); // member must exist; Don&#39;t allow to purchase if we&#39;re in the middle of distributing this group; Don&#39;t let someone buy tokens on the current group if that group is already distributed, unlocked or both; don&#39;t allow member to purchase if they&#39;re not part of the open group.
		uint256 currentTimestamp = block.timestamp;
		require(currentTimestamp >= openGroup.startTime && currentTimestamp <= openGroup.deadline);																 //the timestamp must be greater than or equal to the start time and less than or equal to the deadline time
		require(tx.gasprice <= maxGasPrice); // Restrict maximum gas this transaction is allowed to consume.
		uint256 weiAmount = msg.value;																		// The amount purchased by the current member
		require(weiAmount >= 0.1 ether);
		uint256 ethTotal = openGroup.ethTotal.add(weiAmount); // Calculate total contribution of all members in this group.
		require(ethTotal <= openGroup.cap);														// Check to see if accepting these funds will put us above the hard ether cap.
		uint256 userETHTotal = memberRecord.ethBalance[openGroup.groupNumber].add(weiAmount);	// Calculate the total amount purchased by the current member
		if(currentTimestamp <= openGroup.phase1endTime){																			 // whether the current timestamp is in the first phase
			require(userETHTotal <= memberRecord.max1);														 // Will these new funds put the member over their first phase contribution limit?
		} else if (currentTimestamp <= openGroup.phase2endTime) { // Are we in phase 2?
			require(userETHTotal <= openGroup.max2); // Allow to contribute no more than max2 in phase 2.
		} else { // We&#39;ve passed both phases 1 and 2.
			require(userETHTotal <= openGroup.max3); // Don&#39;t allow to contribute more than max3 in phase 3.
		}
		uint256 tokenAmount = weiAmount.mul(openGroup.ratio);						 //calculate member token amount.
		uint256 newLeftOver = balances[owner].sub(tokenAmount); // Won&#39;t pass if result is < 0.
		openGroup.ethTotal = ethTotal;								 // Calculate the total amount purchased by all members in this group.
		memberRecord.ethBalance[openGroup.groupNumber] = userETHTotal;														 // Record the total amount purchased by the current member
		memberRecord.tokenBalance[openGroup.groupNumber] = memberRecord.tokenBalance[openGroup.groupNumber].add(tokenAmount); // Update the member&#39;s token amount.
		balances[owner] = newLeftOver; // Update the available number of tokens.
		owner.transfer(weiAmount); // Transfer to owner, don&#39;t keep funds in the contract.
		emit PurchaseSuccess(msg.sender,weiAmount,memberRecord.ethBalance[openGroup.groupNumber],memberRecord.tokenBalance[openGroup.groupNumber]); 
	}
	
	function sell(uint256 amount) public canSell { // Can&#39;t sell unless owner has allowed it.
		uint256 decimalAmount = amount.mul(uint(10)**decimals); // convert the full token value to the smallest unit possible.
		if (members[msg.sender].exists) { // If this seller exists, they have an unlocked balance we need to take care of.
			int256 sellValue = members[msg.sender].transferred + int(decimalAmount);
			require(sellValue >= members[msg.sender].transferred); // Check for overflow.
			require(sellValue <= int(getUnlockedBalanceLimit(msg.sender))); // Make sure they&#39;re not selling more than their unlocked amount.
			members[msg.sender].transferred = sellValue;
		}
		balances[msg.sender] = balances[msg.sender].sub(decimalAmount); // Do this before transferring to avoid re-entrance attacks; will throw if result < 0.
		// Amount is considered to be how many full tokens the user wants to sell.
		uint256 totalCost = amount.mul(sellPrice); // sellPrice is the per-full-token value.
		require(address(this).balance >= totalCost); // The contract must have enough funds to cover the selling.
		balances[owner] = balances[owner].add(decimalAmount); // Put these tokens back into the available pile.
		msg.sender.transfer(totalCost); // Pay the seller for their tokens.
		emit Transfer(msg.sender, owner, decimalAmount); // Notify exchanges of the sell.
	}

	function fundContract() public onlyOwner payable { // For the owner to put funds into the contract.
	}

	function setSellPrice(uint256 thePrice) public onlyOwner {
		sellPrice = thePrice;
		emit SetSellPrice(sellPrice);
	}
	
	function setAllowedToSell(bool value) public onlyOwner {
		allowedToSell = value;
		emit ChangedAllowedToSell(allowedToSell);
	}

	function setAllowedToPurchase(bool value) public onlyOwner {
		allowedToPurchase = value;
		emit ChangedAllowedToPurchase(allowedToPurchase);
	}
	
	function createGroup(uint256 startEpoch, uint256 phase1endEpoch, uint256 phase2endEpoch, uint256 deadlineEpoch, uint256 phase2cap, uint256 phase3cap, uint256 etherCap, uint256 ratio) public onlyOwner returns (bool success, uint256 createdGroupNumber) {
		Group storage theGroup = groups[nextGroupNumber];
		theGroup.groupNumber = nextGroupNumber;
		theGroup.startTime = startEpoch;
		theGroup.phase1endTime = phase1endEpoch;
		theGroup.phase2endTime = phase2endEpoch;
		theGroup.deadline = deadlineEpoch;
		theGroup.max2 = phase2cap;
		theGroup.max3 = phase3cap;
		theGroup.cap = etherCap;
		theGroup.ratio = ratio;
		createdGroupNumber = nextGroupNumber;
		nextGroupNumber++;
		success = true;
		emit GroupCreated(createdGroupNumber, startEpoch, phase1endEpoch, phase2endEpoch, deadlineEpoch, phase2cap, phase3cap, etherCap, ratio);
	}

	function createGroup() public onlyOwner returns (bool success, uint256 createdGroupNumber) {
		return createGroup(0, 0, 0, 0, 0, 0, 0, 0);
	}

	function getGroup(uint256 groupNumber) public view onlyOwner returns(bool distributed, bool unlocked, uint256 phase2cap, uint256 phase3cap, uint256 cap, uint256 ratio, uint256 startTime, uint256 phase1endTime, uint256 phase2endTime, uint256 deadline, uint256 ethTotal, uint256 howManyDistributed) {
		require(groupNumber < nextGroupNumber);
		Group storage theGroup = groups[groupNumber];
		distributed = theGroup.distributed;
		unlocked = theGroup.unlocked;
		phase2cap = theGroup.max2;
		phase3cap = theGroup.max3;
		cap = theGroup.cap;
		ratio = theGroup.ratio;
		startTime = theGroup.startTime;
		phase1endTime = theGroup.phase1endTime;
		phase2endTime = theGroup.phase2endTime;
		deadline = theGroup.deadline;
		ethTotal = theGroup.ethTotal;
		howManyDistributed = theGroup.howManyDistributed;
	}

	function getHowManyLeftToDistribute(uint256 groupNumber) public view returns(uint256 howManyLeftToDistribute) {
		require(groupNumber < nextGroupNumber);
		Group storage theGroup = groups[groupNumber];
		howManyLeftToDistribute = associations[groupNumber].length - theGroup.howManyDistributed; // No need to use SafeMath here since we&#39;re guaranteed to not underflow on this line.
	}
	
	function getMembersInGroup(uint256 groupNumber) public view returns (address[]) {
		require(groupNumber < nextGroupNumber); // Check for nonexistent group
		return associations[groupNumber];
	}

	function addMember(address walletAddress, uint256 groupNumber, uint256 tokens, uint256 maxContribution1) public onlyOwner returns (bool success) {
		Member storage theMember = members[walletAddress];
		Group storage theGroup = groups[groupNumber];
		require(groupNumber < nextGroupNumber); // Don&#39;t let the owner assign to a group that doesn&#39;t exist, protect against mistypes.
		require(!theGroup.distributed && !theGroup.distributing && !theGroup.unlocked); // Don&#39;t let us add to a distributed group, a group that&#39;s distributing right now, or a group that&#39;s already been unlocked.
		require(!theMember.exists); // Don&#39;t let the owner re-add a member.
		theMember.walletAddress = walletAddress;
		theMember.groupMemberships[groupNumber] = true;
		balances[owner] = balances[owner].sub(tokens);
		theMember.tokenBalance[groupNumber] = tokens;
		theMember.max1 = maxContribution1;
		theMember.transferred = -int(balances[walletAddress]); // Don&#39;t lock the tokens they come in with if they already hold a balance.
		theMember.exists = true;
		associations[groupNumber].push(walletAddress); // Push this user&#39;s address to the associations array so we can easily keep track of which users belong to which group...
		// ... Solidity doesn&#39;t allow to iterate over a map.
		allMembers.push(walletAddress); // Push this address to allMembers array so we can easily loop through all addresses...
		// Used for splitTokens and reverseSplitTokens.
		emit Added(walletAddress, groupNumber, tokens, maxContribution1);
		return true;
	}

	function addMemberToGroup(address walletAddress, uint256 groupNumber) public onlyOwner returns(bool success) {
		Member storage memberRecord = members[walletAddress];
		require(memberRecord.exists && groupNumber < nextGroupNumber && !memberRecord.groupMemberships[groupNumber]); // Don&#39;t add this user to a group if they already exist in that group.
		memberRecord.groupMemberships[groupNumber] = true;
		associations[groupNumber].push(walletAddress);
		return true;
	}
	function upload(string uploadedData) public onlyOwner returns (bool success) {
		// We&#39;ll separate records by a | and individual entries in the record by a :.
		strings.slice memory uploadedSlice = uploadedData.toSlice();
		strings.slice memory nextRecord = "".toSlice();
		strings.slice memory nextDatum = "".toSlice();
		strings.slice memory recordSeparator = "|".toSlice();
		strings.slice memory datumSeparator = ":".toSlice();
		while (!uploadedSlice.empty()) {
			nextRecord = uploadedSlice.split(recordSeparator);
			nextDatum = nextRecord.split(datumSeparator);
			address memberAddress = parseAddr(nextDatum.toString());
			nextDatum = nextRecord.split(datumSeparator);
			uint256 memberGroup = parseInt(nextDatum.toString(), 0);
			nextDatum = nextRecord.split(datumSeparator);
			uint256 memberTokens = parseInt(nextDatum.toString(), 0);
			nextDatum = nextRecord.split(datumSeparator);
			uint256 memberMaxContribution1 = parseInt(nextDatum.toString(), 0);
			addMember(memberAddress, memberGroup, memberTokens, memberMaxContribution1);
		}
		return true;
	}
	
	function distribute(uint256 groupNumber, uint256 howMany) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(groupNumber < nextGroupNumber && !theGroup.distributed ); // can&#39;t have already distributed
		uint256 inclusiveStartIndex = theGroup.howManyDistributed;
		uint256 exclusiveEndIndex = inclusiveStartIndex.add(howMany);
		theGroup.distributing = true;
		uint256 n = associations[groupNumber].length;
		require(n > 0 ); // We must have more than 0 members in this group
		if (exclusiveEndIndex > n) { // This batch will overrun the array.
			exclusiveEndIndex = n;
		}
		for (uint256 i = inclusiveStartIndex; i < exclusiveEndIndex; i++) { // This section might be expensive in terms of gas cost!
			address memberAddress = associations[groupNumber][i];
			Member storage currentMember = members[memberAddress];
			uint256 balance = currentMember.tokenBalance[groupNumber];
			if (balance > 0) { // No need to waste ticks if they have no tokens to distribute
				balances[memberAddress] = balances[memberAddress].add(balance);
				emit Transfer(owner, memberAddress, balance); // Notify exchanges of the distribution.
			}
			theGroup.howManyDistributed++;
		}
		if (theGroup.howManyDistributed == n) { // Done distributing all members.
			theGroup.distributed = true;
			theGroup.distributing = false;
			emit DistributeDone(groupNumber);
		}
		return true;
	}

	function getUnlockedBalanceLimit(address walletAddress) internal view returns(uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (!theMember.exists) {
			return balances[walletAddress];
		}
		for (uint256 i = 0; i < nextGroupNumber; i++) {
			if (groups[i].unlocked) {
				balance = balance.add(theMember.tokenBalance[i]);
			}
		}
		return balance;
	}

	function getUnlockedTokens(address walletAddress) public view returns(uint256 balance) {
		Member storage theMember = members[walletAddress];
		if (!theMember.exists) {
			return balances[walletAddress];
		}
		return uint256(int(getUnlockedBalanceLimit(walletAddress)) - theMember.transferred);
	}

	function unlock(uint256 groupNumber) public onlyOwner returns (bool success) {
		Group storage theGroup = groups[groupNumber];
		require(theGroup.distributed && !theGroup.unlocked); // Distribution must have occurred first.
		theGroup.unlocked = true;
		emit UnlockDone(groupNumber);
		return true;
	}
	
	function setTransferLock(bool value) public onlyOwner {
		transferLock = value;
		emit ChangedTransferLock(transferLock);
	}
	
	function burn(uint256 amount) public onlyOwner {
		// Burns tokens from the owner&#39;s supply and doesn&#39;t touch allocated tokens.
		// Decrease totalSupply and leftOver by the amount to burn so we can decrease the circulation.
		balances[msg.sender] = balances[msg.sender].sub(amount); // Will throw if result < 0
		totalSupply_ = totalSupply_.sub(amount); // Will throw if result < 0
		emit Transfer(msg.sender, address(0), amount);
	}
	
	function splitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		// SplitFactor is the multiplier per decimal of spark. splitFactor * 10**decimals = splitFactor sparks
		uint256 n = allMembers.length;
		uint256 ownerBalance = balances[msg.sender];
		uint256 increaseSupplyBy = ownerBalance.mul(splitFactor).sub(ownerBalance); // We need to mint owner*splitFactor - owner additional tokens.
		balances[msg.sender] = balances[msg.sender].mul(splitFactor);
		totalSupply_ = totalSupply_.mul(splitFactor);
		emit Transfer(address(0), msg.sender, increaseSupplyBy); // Notify exchange that we&#39;ve minted tokens.
		for (uint256 i = 0; i < n; i++) {
			Member storage currentMember = members[allMembers[i]];
			// Take care of transferred balance.
			currentMember.transferred = currentMember.transferred * int(splitFactor);
			// Iterate over all of this user&#39;s balances for all groups. If a user is not a part of a group their balance will be 0.
			for (uint256 j = 0; j < nextGroupNumber; j++) {
				uint256 memberBalance = currentMember.tokenBalance[j];
				uint256 multiplier = memberBalance.mul(splitFactor);
				currentMember.tokenBalance[j] = multiplier;
			}
		}
		// Next, increase group ratios by splitFactor, so users will receive ratio + splitFactor tokens per ether.
		n = nextGroupNumber;
		require(n > 0); // Must have at least one group.
		for (i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.mul(splitFactor);
		}
		emit SplitTokens(splitFactor);
		return true;
	}
	
	function reverseSplitTokensBeforeDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		// SplitFactor is the multiplier per decimal of spark. splitFactor * 10**decimals = splitFactor sparks
		uint256 n = allMembers.length;
		uint256 ownerBalance = balances[msg.sender];
		uint256 decreaseSupplyBy = ownerBalance.sub(ownerBalance.div(splitFactor));
		// We don&#39;t use burnTokens here since the amount to subtract might be more than what the owner currently holds in their unallocated supply which will cause the function to throw.
		totalSupply_ = totalSupply_.div(splitFactor);
		balances[msg.sender] = ownerBalance.div(splitFactor);
		// Notify the exchanges of how many tokens were burned.
		emit Transfer(msg.sender, address(0), decreaseSupplyBy);
		for (uint256 i = 0; i < n; i++) {
			Member storage currentMember = members[allMembers[i]];
			// Take care of the member&#39;s transferred balance.
			currentMember.transferred = currentMember.transferred / int(splitFactor);
			for (uint256 j = 0; j < nextGroupNumber; j++) {
				uint256 memberBalance = currentMember.tokenBalance[j];
				uint256 divier = memberBalance.div(splitFactor);
				currentMember.tokenBalance[j] = divier;
			}
		}
		// Next, decrease group ratios by splitFactor, so users will receive ratio - splitFactor tokens per ether.
		n = nextGroupNumber;
		require(n > 0); // Must have at least one group. Groups are 0-indexed.
		for (i = 0; i < n; i++) {
			Group storage currentGroup = groups[i];
			currentGroup.ratio = currentGroup.ratio.div(splitFactor);
		}
		emit ReverseSplitTokens(splitFactor);
		return true;
	}

	function splitTokensAfterDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		splitTokensBeforeDistribution(splitFactor);
		uint256 n = allMembers.length;
		for (uint256 i = 0; i < n; i++) {
			address currentMember = allMembers[i];
			uint256 memberBalance = balances[currentMember];
			if (memberBalance > 0) {
				uint256 multiplier1 = memberBalance.mul(splitFactor);
				uint256 increaseMemberSupplyBy = multiplier1.sub(memberBalance);
				balances[currentMember] = multiplier1;
				emit Transfer(address(0), currentMember, increaseMemberSupplyBy);
			}
		}
		n = allNonMembers.length;
		for (i = 0; i < n; i++) {
			address currentNonMember = allNonMembers[i];
			// If this address started out as a nonmember and then became a member, we&#39;ve seen them already in allMembers so don&#39;t grow or shrink them twice.
			if (members[currentNonMember].exists) {
				continue;
			}
			uint256 nonMemberBalance = balances[currentNonMember];
			if (nonMemberBalance > 0) {
				uint256 multiplier2 = nonMemberBalance.mul(splitFactor);
				uint256 increaseNonMemberSupplyBy = multiplier2.sub(nonMemberBalance);
				balances[currentNonMember] = multiplier2;
				emit Transfer(address(0), currentNonMember, increaseNonMemberSupplyBy);
			}
		}
		emit SplitTokens(splitFactor);
		return true;
	}

	function reverseSplitTokensAfterDistribution(uint256 splitFactor) public onlyOwner returns (bool success) {
		reverseSplitTokensBeforeDistribution(splitFactor);
		uint256 n = allMembers.length;
		for (uint256 i = 0; i < n; i++) {
			address currentMember = allMembers[i];
			uint256 memberBalance = balances[currentMember];
			if (memberBalance > 0) {
				uint256 divier1 = memberBalance.div(splitFactor);
				uint256 decreaseMemberSupplyBy = memberBalance.sub(divier1);
				balances[currentMember] = divier1;
				emit Transfer(currentMember, address(0), decreaseMemberSupplyBy);
			}
		}
		n = allNonMembers.length;
		for (i = 0; i < n; i++) {
			address currentNonMember = allNonMembers[i];
			// If this address started out as a nonmember and then became a member, we&#39;ve seen them already in allMembers so don&#39;t grow or shrink them twice.
			if (members[currentNonMember].exists) {
				continue;
			}
			uint256 nonMemberBalance = balances[currentNonMember];
			if (nonMemberBalance > 0) {
				uint256 divier2 = nonMemberBalance.div(splitFactor);
				uint256 decreaseNonMemberSupplyBy = nonMemberBalance.sub(divier2);
				balances[currentNonMember] = divier2;
				emit Transfer(currentNonMember, address(0), decreaseNonMemberSupplyBy);
			}
		}
		emit ReverseSplitTokens(splitFactor);
		return true;
	}

	function changeMaxContribution(address memberAddress, uint256 newMax1) public onlyOwner {
		// Allows to change a member&#39;s maximum contribution for phase 1.
		Member storage theMember = members[memberAddress];
		require(theMember.exists); // Don&#39;t allow to change for a nonexistent member.
		theMember.max1 = newMax1;
	}
	
	function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) canTransfer returns (bool success) {		
		// If the transferrer has purchased tokens, they must be unlocked before they can be used.
		Member storage fromMember = members[msg.sender];
		if (fromMember.exists) { // If this is the owner, this check will be false so no need to check specifically for owner here.
			int256 transferValue = fromMember.transferred + int(_value);
			require(transferValue >= fromMember.transferred); // Check for overflow.
			require(transferValue <= int(getUnlockedBalanceLimit(msg.sender))); // Make sure they don&#39;t transfer out more than their unlocked limit.
			fromMember.transferred = transferValue;
		}
		// If any of the parties involved are not members, add them to the nonmembers list.
		// Don&#39;t add the owner, since they&#39;re a special case.
		if (!fromMember.exists && msg.sender != owner) {
			bool fromTransferee = nonMemberTransfers[msg.sender];
			if (!fromTransferee) { // If we haven&#39;t added this transferee before.
				nonMemberTransfers[msg.sender] = true;
				allNonMembers.push(msg.sender);
			}
		}
		if (!members[_to].exists && _to != owner) {
			bool toTransferee = nonMemberTransfers[_to];
			if (!toTransferee) { // If we haven&#39;t added this transferee before.
				nonMemberTransfers[_to] = true;
				allNonMembers.push(_to);
			}
		} else if (members[_to].exists) { // Add this transfer to the unlocked balance
			int256 transferInValue = members[_to].transferred - int(_value);
			require(transferInValue <= members[_to].transferred); // Check for underflow.
			members[_to].transferred = transferInValue;
		}
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) canTransfer returns (bool success) {
		// If the transferrer has purchased tokens, they must be unlocked before they can be used.
		Member storage fromMember = members[_from];
		if (fromMember.exists) { // If _from is the owner, this check will always fail, so we don&#39;t need to check specifically for owner here.
			int256 transferValue = fromMember.transferred + int(_value);
			require(transferValue >= fromMember.transferred); // Check for overflow.
			require(transferValue <= int(getUnlockedBalanceLimit(msg.sender))); // Make sure they don&#39;t transfer out more than their unlocked limit.
			fromMember.transferred = transferValue;
		}
		// If any of the parties involved are not members, add them to the nonmembers list.
		// Don&#39;t add the owner since they&#39;re a special case.
		if (!fromMember.exists && _from != owner) {
			bool fromTransferee = nonMemberTransfers[_from];
			if (!fromTransferee) { // If we haven&#39;t added this transferee before.
				nonMemberTransfers[_from] = true;
				allNonMembers.push(_from);
			}
		}
		if (!members[_to].exists && _to != owner) {
			bool toTransferee = nonMemberTransfers[_to];
			if (!toTransferee) { // If we haven&#39;t added this transferee before.
				nonMemberTransfers[_to] = true;
				allNonMembers.push(_to);
			}
		} else if (members[_to].exists) { // Add this transfer to the unlocked balance
			int256 transferInValue = members[_to].transferred - int(_value);
			require(transferInValue <= members[_to].transferred); // Check for underflow.
			members[_to].transferred = transferInValue;
		}
		return super.transferFrom(_from, _to, _value);
	}

	function setOpenGroup(uint256 groupNumber) public onlyOwner returns (bool success) {
		require(groupNumber < nextGroupNumber);
		openGroupNumber = groupNumber;
		return true;
	}

	function getUndistributedBalanceOf(address walletAddress, uint256 groupNumber) public view returns (uint256 balance) {
		Member storage theMember = members[walletAddress];
		require(theMember.exists);
		if (groups[groupNumber].distributed) // Here, the group will be distributed but tokenBalance will still have a value, so that we know how many tokens to allocate to the unlocked balance.
			return 0;
		return theMember.tokenBalance[groupNumber];
	}

	function checkMyUndistributedBalance(uint256 groupNumber) public view returns (uint256 balance) {
		return getUndistributedBalanceOf(msg.sender, groupNumber);
	}

	function transferRecovery(address _from, address _to, uint256 _value) public onlyOwner returns (bool success) {
		// Will be used if someone sends tokens to an incorrect address by accident. This way, we have the ability to recover the tokens. For example, sometimes there&#39;s a problem of lost tokens if someone sends tokens to a contract address that can&#39;t utilize the tokens.
		allowed[_from][msg.sender] = allowed[_from][msg.sender].add(_value); // Authorize the owner to spend on someone&#39;s behalf.
		Member storage fromMember = members[_from];
		if (fromMember.exists) {
			int256 oldTransferred = fromMember.transferred;
			fromMember.transferred -= int(_value); // Unlock this amount.
			require(oldTransferred >= fromMember.transferred); // Check for underflow.
		}
		return transferFrom(_from, _to, _value);
	}
}