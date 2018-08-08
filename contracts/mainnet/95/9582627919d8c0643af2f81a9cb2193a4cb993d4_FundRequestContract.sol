pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() constant public returns (uint);

  function balanceOf(address who) constant public returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public constant returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() public {owner = msg.sender;}

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract Callable is Owned {

    //sender => _allowed
    mapping(address => bool) public callers;

    //modifiers
    modifier onlyCaller {
        require(callers[msg.sender]);
        _;
    }

    //management of the repositories
    function updateCaller(address _caller, bool allowed) public onlyOwner {
        callers[_caller] = allowed;
    }
}

contract EternalStorage is Callable {

    mapping(bytes32 => uint) uIntStorage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => bytes) bytesStorage;
    mapping(bytes32 => bool) boolStorage;
    mapping(bytes32 => int) intStorage;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns (uint) {
        return uIntStorage[_key];
    }

    function getString(bytes32 _key) external view returns (string) {
        return stringStorage[_key];
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    function getBytes(bytes32 _key) external view returns (bytes) {
        return bytesStorage[_key];
    }

    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    function getInt(bytes32 _key) external view returns (int) {
        return intStorage[_key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) onlyCaller external {
        uIntStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value) onlyCaller external {
        stringStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) onlyCaller external {
        addressStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value) onlyCaller external {
        bytesStorage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value) onlyCaller external {
        boolStorage[_key] = _value;
    }

    function setInt(bytes32 _key, int _value) onlyCaller external {
        intStorage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) onlyCaller external {
        delete uIntStorage[_key];
    }

    function deleteString(bytes32 _key) onlyCaller external {
        delete stringStorage[_key];
    }

    function deleteAddress(bytes32 _key) onlyCaller external {
        delete addressStorage[_key];
    }

    function deleteBytes(bytes32 _key) onlyCaller external {
        delete bytesStorage[_key];
    }

    function deleteBool(bytes32 _key) onlyCaller external {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key) onlyCaller external {
        delete intStorage[_key];
    }
}

/*
 * Database Contract
 * Davy Van Roy
 * Quinten De Swaef
 */
contract FundRepository is Callable {

    using SafeMath for uint256;

    EternalStorage public db;

    //platform -> platformId => _funding
    mapping(bytes32 => mapping(string => Funding)) funds;

    struct Funding {
        address[] funders; //funders that funded tokens
        address[] tokens; //tokens that were funded
        mapping(address => TokenFunding) tokenFunding;
    }

    struct TokenFunding {
        mapping(address => uint256) balance;
        uint256 totalTokenBalance;
    }

    constructor(address _eternalStorage) public {
        db = EternalStorage(_eternalStorage);
    }

    function updateFunders(address _from, bytes32 _platform, string _platformId) public onlyCaller {
        bool existing = db.getBool(keccak256(abi.encodePacked("funds.userHasFunded", _platform, _platformId, _from)));
        if (!existing) {
            uint funderCount = getFunderCount(_platform, _platformId);
            db.setAddress(keccak256(abi.encodePacked("funds.funders.address", _platform, _platformId, funderCount)), _from);
            db.setUint(keccak256(abi.encodePacked("funds.funderCount", _platform, _platformId)), funderCount.add(1));
        }
    }

    function updateBalances(address _from, bytes32 _platform, string _platformId, address _token, uint256 _value) public onlyCaller {
        if (db.getBool(keccak256(abi.encodePacked("funds.token.address", _platform, _platformId, _token))) == false) {
            db.setBool(keccak256(abi.encodePacked("funds.token.address", _platform, _platformId, _token)), true);
            //add to the list of tokens for this platformId
            uint tokenCount = getFundedTokenCount(_platform, _platformId);
            db.setAddress(keccak256(abi.encodePacked("funds.token.address", _platform, _platformId, tokenCount)), _token);
            db.setUint(keccak256(abi.encodePacked("funds.tokenCount", _platform, _platformId)), tokenCount.add(1));
        }

        //add to the balance of this platformId for this token
        db.setUint(keccak256(abi.encodePacked("funds.tokenBalance", _platform, _platformId, _token)), balance(_platform, _platformId, _token).add(_value));

        //add to the balance the user has funded for the request
        db.setUint(keccak256(abi.encodePacked("funds.amountFundedByUser", _platform, _platformId, _from, _token)), amountFunded(_platform, _platformId, _from, _token).add(_value));

        //add the fact that the user has now funded this platformId
        db.setBool(keccak256(abi.encodePacked("funds.userHasFunded", _platform, _platformId, _from)), true);
    }

    function claimToken(bytes32 platform, string platformId, address _token) public onlyCaller returns (uint256) {
        require(!issueResolved(platform, platformId), "Can&#39;t claim token, issue is already resolved.");
        uint256 totalTokenBalance = balance(platform, platformId, _token);
        db.deleteUint(keccak256(abi.encodePacked("funds.tokenBalance", platform, platformId, _token)));
        return totalTokenBalance;
    }

    function refundToken(bytes32 _platform, string _platformId, address _owner, address _token) public onlyCaller returns (uint256) {
        require(!issueResolved(_platform, _platformId), "Can&#39;t refund token, issue is already resolved.");

        //delete amount from user, so he can&#39;t refund again
        uint256 userTokenBalance = amountFunded(_platform, _platformId, _owner, _token);
        db.deleteUint(keccak256(abi.encodePacked("funds.amountFundedByUser", _platform, _platformId, _owner, _token)));


        uint256 oldBalance = balance(_platform, _platformId, _token);
        uint256 newBalance = oldBalance.sub(userTokenBalance);

        require(newBalance <= oldBalance);

        //subtract amount from tokenBalance
        db.setUint(keccak256(abi.encodePacked("funds.tokenBalance", _platform, _platformId, _token)), newBalance);

        return userTokenBalance;
    }

    function finishResolveFund(bytes32 platform, string platformId) public onlyCaller returns (bool) {
        db.setBool(keccak256(abi.encodePacked("funds.issueResolved", platform, platformId)), true);
        db.deleteUint(keccak256(abi.encodePacked("funds.funderCount", platform, platformId)));
        return true;
    }

    //constants
    function getFundInfo(bytes32 _platform, string _platformId, address _funder, address _token) public view returns (uint256, uint256, uint256) {
        return (
        getFunderCount(_platform, _platformId),
        balance(_platform, _platformId, _token),
        amountFunded(_platform, _platformId, _funder, _token)
        );
    }

    function issueResolved(bytes32 _platform, string _platformId) public view returns (bool) {
        return db.getBool(keccak256(abi.encodePacked("funds.issueResolved", _platform, _platformId)));
    }

    function getFundedTokenCount(bytes32 _platform, string _platformId) public view returns (uint256) {
        return db.getUint(keccak256(abi.encodePacked("funds.tokenCount", _platform, _platformId)));
    }

    function getFundedTokensByIndex(bytes32 _platform, string _platformId, uint _index) public view returns (address) {
        return db.getAddress(keccak256(abi.encodePacked("funds.token.address", _platform, _platformId, _index)));
    }

    function getFunderCount(bytes32 _platform, string _platformId) public view returns (uint) {
        return db.getUint(keccak256(abi.encodePacked("funds.funderCount", _platform, _platformId)));
    }

    function getFunderByIndex(bytes32 _platform, string _platformId, uint index) external view returns (address) {
        return db.getAddress(keccak256(abi.encodePacked("funds.funders.address", _platform, _platformId, index)));
    }

    function amountFunded(bytes32 _platform, string _platformId, address _funder, address _token) public view returns (uint256) {
        return db.getUint(keccak256(abi.encodePacked("funds.amountFundedByUser", _platform, _platformId, _funder, _token)));
    }

    function balance(bytes32 _platform, string _platformId, address _token) view public returns (uint256) {
        return db.getUint(keccak256(abi.encodePacked("funds.tokenBalance", _platform, _platformId, _token)));
    }
}

contract ClaimRepository is Callable {
    using SafeMath for uint256;

    EternalStorage public db;

    constructor(address _eternalStorage) public {
        //constructor
        require(_eternalStorage != address(0), "Eternal storage cannot be 0x0");
        db = EternalStorage(_eternalStorage);
    }

    function addClaim(address _solverAddress, bytes32 _platform, string _platformId, string _solver, address _token, uint256 _requestBalance) public onlyCaller returns (bool) {
        if (db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId))) != address(0)) {
            require(db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId))) == _solverAddress, "Adding a claim needs to happen with the same claimer as before");
        } else {
            db.setString(keccak256(abi.encodePacked("claims.solver", _platform, _platformId)), _solver);
            db.setAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId)), _solverAddress);
        }

        uint tokenCount = db.getUint(keccak256(abi.encodePacked("claims.tokenCount", _platform, _platformId)));
        db.setUint(keccak256(abi.encodePacked("claims.tokenCount", _platform, _platformId)), tokenCount.add(1));
        db.setUint(keccak256(abi.encodePacked("claims.token.amount", _platform, _platformId, _token)), _requestBalance);
        db.setAddress(keccak256(abi.encodePacked("claims.token.address", _platform, _platformId, tokenCount)), _token);
        return true;
    }

    function isClaimed(bytes32 _platform, string _platformId) view external returns (bool claimed) {
        return db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId))) != address(0);
    }

    function getSolverAddress(bytes32 _platform, string _platformId) view external returns (address solverAddress) {
        return db.getAddress(keccak256(abi.encodePacked("claims.solver_address", _platform, _platformId)));
    }

    function getSolver(bytes32 _platform, string _platformId) view external returns (string){
        return db.getString(keccak256(abi.encodePacked("claims.solver", _platform, _platformId)));
    }

    function getTokenCount(bytes32 _platform, string _platformId) view external returns (uint count) {
        return db.getUint(keccak256(abi.encodePacked("claims.tokenCount", _platform, _platformId)));
    }

    function getTokenByIndex(bytes32 _platform, string _platformId, uint _index) view external returns (address token) {
        return db.getAddress(keccak256(abi.encodePacked("claims.token.address", _platform, _platformId, _index)));
    }

    function getAmountByToken(bytes32 _platform, string _platformId, address _token) view external returns (uint token) {
        return db.getUint(keccak256(abi.encodePacked("claims.token.amount", _platform, _platformId, _token)));
    }
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
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
        assembly {retptr := add(ret, 32)}

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
            assembly {b := and(mload(ptr), 0xFF)}
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
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
        assembly {b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)}
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
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
        assembly {word := mload(mload(add(self, 32)))}
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
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
                assembly {needledata := and(mload(needleptr), mask)}

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {ptrdata := and(mload(ptr), mask)}

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly {ptrdata := and(mload(ptr), mask)}
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {hash := sha3(needleptr, needlelen)}

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {testHash := sha3(ptr, needlelen)}
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
                assembly {needledata := and(mload(needleptr), mask)}

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {ptrdata := and(mload(ptr), mask)}

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly {ptrdata := and(mload(ptr), mask)}
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {hash := sha3(needleptr, needlelen)}
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {testHash := sha3(ptr, needlelen)}
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
        assembly {retptr := add(ret, 32)}
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
        for (uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly {retptr := add(ret, 32)}

        for (i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    /*
    * Additions by the FundRequest Team
    */

    function toBytes32(slice self) internal pure returns (bytes32 result) {
        string memory source = toString(self);
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) pure internal returns (string){
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

    function strConcat(string _a, string _b, string _c, string _d) pure internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) pure internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) pure internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function addressToString(address x) internal pure returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2 ** (8 * (19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2 * i] = charToByte(hi);
            s[2 * i + 1] = charToByte(lo);
        }
        return strConcat("0x", string(s));
    }

    function charToByte(byte b) internal pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte ch = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (ch != 0) {
                bytesString[charCount] = ch;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

contract Precondition is Owned {

    string public name;
    uint public version;
    bool public active = false;

    constructor(string _name, uint _version, bool _active) public {
        name = _name;
        version = _version;
        active = _active;
    }

    function setActive(bool _active) external onlyOwner {
        active = _active;
    }

    function isValid(bytes32 _platform, string _platformId, address _token, uint256 _value, address _funder) external view returns (bool valid);
}

/*
 * Main FundRequest Contract. The entrypoint for every claim/refund
 * Davy Van Roy
 * Quinten De Swaef
 */
contract FundRequestContract is Callable, ApproveAndCallFallBack {

    using SafeMath for uint256;
    using strings for *;

    event Funded(address indexed from, bytes32 platform, string platformId, address token, uint256 value);

    event Claimed(address indexed solverAddress, bytes32 platform, string platformId, string solver, address token, uint256 value);

    event Refund(address indexed owner, bytes32 platform, string platformId, address token, uint256 value);

    address constant public ETHER_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    //repositories
    FundRepository public fundRepository;

    ClaimRepository public claimRepository;

    address public claimSignerAddress;

    Precondition[] public preconditions;

    constructor(address _fundRepository, address _claimRepository) public {
        setFundRepository(_fundRepository);
        setClaimRepository(_claimRepository);
    }

    //ENTRYPOINTS

    /*
     * Public function, can only be called from the outside.
     * Fund an issue, providing a token and value.
     * Requires an allowance > _value of the token.
     */
    function fund(bytes32 _platform, string _platformId, address _token, uint256 _value) external returns (bool success) {
        require(doFunding(_platform, _platformId, _token, _value, msg.sender), "funding with token failed");
        return true;
    }

    /*
     * Public function, can only be called from the outside.
     * Fund an issue, ether as value of the transaction.
     * Requires ether to be whitelisted in a precondition.
     */
    function etherFund(bytes32 _platform, string _platformId) payable external returns (bool success) {
        require(doFunding(_platform, _platformId, ETHER_ADDRESS, msg.value, msg.sender), "funding with ether failed");
        return true;
    }

    /*
     * Public function, supposed to be called from another contract, after receiving approval
     * Funds an issue, expects platform, platformid to be concatted with |AAC| as delimiter and provided as _data
     * Only used with the FundRequest approveAndCall function at the moment. Might be removed later in favor of 2 calls.
     */
    function receiveApproval(address _from, uint _amount, address _token, bytes _data) public {
        var sliced = string(_data).toSlice();
        var platform = sliced.split("|AAC|".toSlice());
        var platformId = sliced.split("|AAC|".toSlice());
        require(doFunding(platform.toBytes32(), platformId.toString(), _token, _amount, _from));
    }

    /*
     * Claim: Public function, only supposed to be called from the outside
     * Anyone can call this function, but a valid signature from FundRequest is required
     */
    function claim(bytes32 platform, string platformId, string solver, address solverAddress, bytes32 r, bytes32 s, uint8 v) public returns (bool) {
        require(validClaim(platform, platformId, solver, solverAddress, r, s, v), "Claimsignature was not valid");
        uint256 tokenCount = fundRepository.getFundedTokenCount(platform, platformId);
        for (uint i = 0; i < tokenCount; i++) {
            address token = fundRepository.getFundedTokensByIndex(platform, platformId, i);
            uint256 tokenAmount = fundRepository.claimToken(platform, platformId, token);
            if (token == ETHER_ADDRESS) {
                solverAddress.transfer(tokenAmount);
            } else {
                require(ERC20(token).transfer(solverAddress, tokenAmount), "transfer of tokens from contract failed");
            }
            require(claimRepository.addClaim(solverAddress, platform, platformId, solver, token, tokenAmount), "adding claim to repository failed");
            emit Claimed(solverAddress, platform, platformId, solver, token, tokenAmount);
        }
        require(fundRepository.finishResolveFund(platform, platformId), "Resolving the fund failed");
        return true;
    }

    /*
     * Claim: Public function, only supposed to be called from the outside
     * Only FundRequest can call this function for now, which will refund a user for a specific issue.
     */
    function refund(bytes32 _platform, string _platformId, address _funder) external onlyCaller returns (bool) {
        uint256 tokenCount = fundRepository.getFundedTokenCount(_platform, _platformId);
        for (uint i = 0; i < tokenCount; i++) {
            address token = fundRepository.getFundedTokensByIndex(_platform, _platformId, i);
            uint256 tokenAmount = fundRepository.refundToken(_platform, _platformId, _funder, token);
            if (tokenAmount > 0) {
                if (token == ETHER_ADDRESS) {
                    _funder.transfer(tokenAmount);
                } else {
                    require(ERC20(token).transfer(_funder, tokenAmount), "transfer of tokens from contract failed");
                }
            }
            emit Refund(_funder, _platform, _platformId, token, tokenAmount);
        }
    }

    /*
     * only called from within the this contract itself, will actually do the funding
     */
    function doFunding(bytes32 _platform, string _platformId, address _token, uint256 _value, address _funder) internal returns (bool success) {
        if (_token == ETHER_ADDRESS) {
            //must check this, so we don&#39;t have people foefeling with the amounts
            require(msg.value == _value);
        }
        require(!fundRepository.issueResolved(_platform, _platformId), "Can&#39;t fund tokens, platformId already claimed");
        for (uint idx = 0; idx < preconditions.length; idx++) {
            if (address(preconditions[idx]) != address(0)) {
                require(preconditions[idx].isValid(_platform, _platformId, _token, _value, _funder));
            }
        }
        require(_value > 0, "amount of tokens needs to be more than 0");

        if (_token != ETHER_ADDRESS) {
            require(ERC20(_token).transferFrom(_funder, address(this), _value), "Transfer of tokens to contract failed");
        }

        fundRepository.updateFunders(_funder, _platform, _platformId);
        fundRepository.updateBalances(_funder, _platform, _platformId, _token, _value);
        emit Funded(_funder, _platform, _platformId, _token, _value);
        return true;
    }

    /*
     * checks if a claim is valid, by checking the signature
     */
    function validClaim(bytes32 platform, string platformId, string solver, address solverAddress, bytes32 r, bytes32 s, uint8 v) internal view returns (bool) {
        bytes32 h = keccak256(abi.encodePacked(createClaimMsg(platform, platformId, solver, solverAddress)));
        address signerAddress = ecrecover(h, v, r, s);
        return claimSignerAddress == signerAddress;
    }

    function createClaimMsg(bytes32 platform, string platformId, string solver, address solverAddress) internal pure returns (string) {
        return strings.bytes32ToString(platform)
        .strConcat(prependUnderscore(platformId))
        .strConcat(prependUnderscore(solver))
        .strConcat(prependUnderscore(strings.addressToString(solverAddress)));
    }

    function addPrecondition(address _precondition) external onlyOwner {
        preconditions.push(Precondition(_precondition));
    }

    function removePrecondition(uint _index) external onlyOwner {
        if (_index >= preconditions.length) return;

        for (uint i = _index; i < preconditions.length - 1; i++) {
            preconditions[i] = preconditions[i + 1];
        }

        delete preconditions[preconditions.length - 1];
        preconditions.length--;
    }

    function setFundRepository(address _repositoryAddress) public onlyOwner {
        fundRepository = FundRepository(_repositoryAddress);
    }

    function setClaimRepository(address _claimRepository) public onlyOwner {
        claimRepository = ClaimRepository(_claimRepository);
    }

    function setClaimSignerAddress(address _claimSignerAddress) addressNotNull(_claimSignerAddress) public onlyOwner {
        claimSignerAddress = _claimSignerAddress;
    }

    function prependUnderscore(string str) internal pure returns (string) {
        return "_".strConcat(str);
    }

    //required to be able to migrate to a new FundRequestContract
    function migrateTokens(address _token, address newContract) external onlyOwner {
        require(newContract != address(0));
        if (_token == ETHER_ADDRESS) {
            newContract.transfer(address(this).balance);
        } else {
            ERC20 token = ERC20(_token);
            token.transfer(newContract, token.balanceOf(address(this)));
        }
    }

    modifier addressNotNull(address target) {
        require(target != address(0), "target address can not be 0x0");
        _;
    }

    //required should there be an issue with available ether
    function deposit() external onlyOwner payable {
        require(msg.value > 0, "Should at least be 1 wei deposited");
    }
}