//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "./crawler/impl/PriceCrawler.sol";
import "./crawler/impl/IPFSCrawler.sol";
import "./crawler/ICrawler.sol";

contract Fund is ICrawler, PriceCrawler, IPFSCrawler {
    
    using Counters for Counters.Counter;
    Counters.Counter private requestCounter;

    constructor() {}

    function iterateRequestId() internal returns(string memory reqId) {
        requestCounter.increment();
        reqId = string(abi.encodePacked("bsc-", requestCounter.current()));
    }

    function queryPriceOracle() onlyOwner public {
        crawlerQuery(iterateRequestId(), QueryType.PriceOracle, "");
    }

    function queryIPFS(string memory _id) onlyOwner public {
        crawlerQuery(iterateRequestId(), QueryType.IPFS, bytes(_id));
    }

    /**
     * @dev An implementation of the ICrawler callback function will be called after Crawler finished external querying. 
     *
     * Requirements:
     *
     * - resolverAddress must be correct
     */
    function crawlerCallback(string memory _reqId, QueryType _type, bytes calldata _calldata) external override onlyResolver {
        // TODO: check request id
        
        if (_type == QueryType.PriceOracle) {
            encodedPriceOracle = _calldata;
        } else if (_type == QueryType.IPFS) {
            encodedIPFS = _calldata;
        } else {
            revert("unimplemented callback type");
        }
        emit CrawlerCallback();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Crawler.sol";
import "../../obi/Obi.sol";

abstract contract PriceCrawler is Crawler {

    using Obi for Obi.Data;

    struct Token {
        string symbol;
        uint256 price;
        uint256 multiplier;
    }

    struct PriceOracle {
        string requestId;
        uint256 aggregatedAt;
        Token[] tokens;
    }

    bytes public encodedPriceOracle;

    /**
     * @dev Returns the list of price data that contains symbol and price (in USD).
     *
     * Requirements:
     *
     * - encodedPriceData cannot be zero
     */
    function getPriceOracle() public view returns (PriceOracle memory priceOracle) {
        require(encodedPriceOracle.length > 0, "Crawler: invalid price data");
        Obi.Data memory decoder = Obi.from(encodedPriceOracle);
        priceOracle.requestId = decoder.decodeString();
        priceOracle.aggregatedAt = decoder.decodeU64();
        
        // parsing prices of each symbol
        uint32 length = decoder.decodeU32();
        priceOracle.tokens = new Token[](length);
        for (uint256 i = 0; i < length; i++) {
            Token memory _token = Token("", 0, 0);
            _token.symbol = decoder.decodeString();
            _token.price = decoder.decodeU64();
            _token.multiplier = decoder.decodeU64();
            priceOracle.tokens[i] = _token;
        }
        
        require(decoder.finished(), "Crawler: data decode not finished");
    } 
    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Crawler.sol";

abstract contract IPFSCrawler is Crawler {

    bytes public encodedIPFS;

    /**
     * @dev Returns the raw data of latest IPFS.
     *
     * Requirements:
     *
     * - encodedPriceData cannot be zero
     */
    function getIPFS() external view returns(string memory _body) {
        return string(encodedIPFS);
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./QueryType.sol";

interface ICrawler {
    function crawlerCallback(string memory _reqId, QueryType _type, bytes calldata _calldata) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./QueryType.sol";

abstract contract Crawler is Ownable {

    address public resolver;

    event CrawlerQuery(string _reqId, address _caller, QueryType _type, bytes _calldata);
    event CrawlerCallback();

    modifier onlyResolver() {
        require(msg.sender == resolver, "Crawler: invalid resolver address");
        _;
    }

    function getResolver() public view returns(address) {
        return resolver;
    }

    function setResolver(address _resolver) onlyOwner public {
        resolver = _resolver;
    }

    function crawlerQuery(string memory _reqId, QueryType _type, bytes memory _calldata) internal {
        emit CrawlerQuery(_reqId, address(this), _type, _calldata);
    }

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

library Obi {
    using SafeMath for uint256;

    struct Data {
        uint256 offset;
        bytes raw;
    }

    function from(bytes memory data) internal pure returns (Data memory) {
        return Data({offset: 0, raw: data});
    }

    modifier shift(Data memory data, uint256 size) {
        require(data.raw.length >= data.offset + size, "Obi: Out of range");
        _;
        data.offset += size;
    }

    function finished(Data memory data) internal pure returns (bool) {
        return data.offset == data.raw.length;
    }

    function decodeU8(Data memory data)
        internal
        pure
        shift(data, 1)
        returns (uint8 value)
    {
        value = uint8(data.raw[data.offset]);
    }

    function decodeI8(Data memory data)
        internal
        pure
        shift(data, 1)
        returns (int8 value)
    {
        value = int8(uint8(data.raw[data.offset]));
    }

    function decodeU16(Data memory data) internal pure returns (uint16 value) {
        value = uint16(decodeU8(data)) << 8;
        value |= uint16(decodeU8(data));
    }

    function decodeI16(Data memory data) internal pure returns (int16 value) {
        value = int16(decodeI8(data)) << 8;
        value |= int16(decodeI8(data));
    }

    function decodeU32(Data memory data) internal pure returns (uint32 value) {
        value = uint32(decodeU16(data)) << 16;
        value |= uint32(decodeU16(data));
    }

    function decodeI32(Data memory data) internal pure returns (int32 value) {
        value = int32(decodeI16(data)) << 16;
        value |= int32(decodeI16(data));
    }

    function decodeU64(Data memory data) internal pure returns (uint64 value) {
        value = uint64(decodeU32(data)) << 32;
        value |= uint64(decodeU32(data));
    }

    function decodeI64(Data memory data) internal pure returns (int64 value) {
        value = int64(decodeI32(data)) << 32;
        value |= int64(decodeI32(data));
    }

    function decodeU128(Data memory data)
        internal
        pure
        returns (uint128 value)
    {
        value = uint128(decodeU64(data)) << 64;
        value |= uint128(decodeU64(data));
    }

    function decodeI128(Data memory data) internal pure returns (int128 value) {
        value = int128(decodeI64(data)) << 64;
        value |= int128(decodeI64(data));
    }

    function decodeU256(Data memory data)
        internal
        pure
        returns (uint256 value)
    {
        value = uint256(decodeU128(data)) << 128;
        value |= uint256(decodeU128(data));
    }

    function decodeI256(Data memory data) internal pure returns (int256 value) {
        value = int256(decodeI128(data)) << 128;
        value |= int256(decodeI128(data));
    }

    function decodeBool(Data memory data) internal pure returns (bool value) {
        value = (decodeU8(data) != 0);
    }

    function decodeBytes(Data memory data)
        internal
        pure
        returns (bytes memory value)
    {
        value = new bytes(decodeU32(data));
        for (uint256 i = 0; i < value.length; i++) {
            value[i] = bytes1(decodeU8(data));
        }
    }

    function decodeString(Data memory data)
        internal
        pure
        returns (string memory value)
    {
        return string(decodeBytes(data));
    }

    function decodeBytes32(Data memory data)
        internal
        pure
        shift(data, 32)
        returns (bytes1[32] memory value)
    {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(value, mload(add(add(raw, 32), offset)))
        }
    }

    function decodeBytes64(Data memory data)
        internal
        pure
        shift(data, 64)
        returns (bytes1[64] memory value)
    {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(value, mload(add(add(raw, 32), offset)))
            mstore(add(value, 32), mload(add(add(raw, 64), offset)))
        }
    }

    function decodeBytes65(Data memory data)
        internal
        pure
        shift(data, 65)
        returns (bytes1[65] memory value)
    {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(value, mload(add(add(raw, 32), offset)))
            mstore(add(value, 32), mload(add(add(raw, 64), offset)))
        }
        value[64] = data.raw[data.offset + 64];
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

enum QueryType{ 
    PriceOracle, 
    RNG, 
    IPFS
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

