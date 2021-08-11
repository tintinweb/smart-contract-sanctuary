// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "../Interfaces/IOracle.sol";
import "../Interfaces/IChainlinkOracle.sol";
import "../lib/LibMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev The Chainlink oracle adapter allows you to wrap a Chainlink oracle feed
 *      and ensure that the price is always returned in a WAD format.
 *      The upstream feed may be changed (Eg updated to a new Chainlink feed) while
 *      keeping price consistency for the actual Tracer perp market.
 *      The Fast Gas / GWEI Chainlink feed is an exception to this
 *      as it is already formatted correctly.
 */
contract OracleAdapter is IOracle, Ownable {
    using LibMath for uint256;
    IChainlinkOracle public oracle;
    uint256 private constant MAX_DECIMALS = 18;
    uint256 public scaler;

    constructor(address _oracle) {
        setOracle(_oracle);
    }

    /**
     * @notice Gets the latest answer from the Chainlink feed.
     * @dev converts the price to a WAD price before returning.
     */
    function latestAnswer() external view override returns (uint256) {
        (uint80 roundID, int256 price, , uint256 timeStamp, uint80 answeredInRound) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "COA: Stale answer");
        require(timeStamp != 0, "COA: Round incomplete");
        return toWad(uint256(price));
    }

    function decimals() external pure override returns (uint8) {
        return uint8(MAX_DECIMALS);
    }

    /**
     * @notice converts a raw value to a WAD value based on the decimals in the feed.
     * @dev this allows consistency for oracles used throughout the protocol
     *      and allows oracles to have their decimals changed withou affecting
     *      the market itself
     */
    function toWad(uint256 raw) internal view returns (uint256) {
        return raw * scaler;
    }

    /**
     * @notice Change the upstream feed address.
     */
    function changeOracle(address newOracle) external onlyOwner {
        setOracle(newOracle);
    }

    /**
     * @notice sets the upstream oracle
     * @dev resets the scalar value to ensure WAD values are always returned
     */
    function setOracle(address newOracle) internal {
        oracle = IChainlinkOracle(newOracle);
        // reset the scaler for consistency
        uint8 _decimals = oracle.decimals();
        require(_decimals <= MAX_DECIMALS, "COA: too many decimals");
        scaler = uint256(10**(MAX_DECIMALS - _decimals));
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

interface IOracle {
    function latestAnswer() external view returns (uint256);

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * This interface follows the AggregatorV3 interface. The getRoundData has been excluded as only the
 * latestRoundData function is used in the system to fetch answers.
 * https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
 * Before being used by the system, any Chainlink feeds that do not provide answers in WAD format (18 decimals) should be wrapped in a
 * Tracer Chainlink Adapter (see contrafts/oracle/ChainlinkOracleAdapter.sol) to ensure the correct number of decimals.
 */
interface IChainlinkOracle {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // latestRoundData should raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

library LibMath {
    uint256 private constant POSITIVE_INT256_MAX = uint256(type(int256).max);

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= POSITIVE_INT256_MAX, "uint256 overflow");
        return int256(x);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x > 0 ? int256(x) : int256(-1 * x);
    }

    /**
     * @notice Get sum of an (unsigned) array
     * @param arr Array to get the sum of
     * @return Sum of first n elements
     */
    function sum(uint256[] memory arr) internal pure returns (uint256) {
        uint256 n = arr.length;
        uint256 total = 0;

        for (uint256 i = 0; i < n; i++) {
            total += arr[i];
        }

        return total;
    }

    /**
     * @notice Get sum of an (unsigned) array, for the first n elements
     * @param arr Array to get the sum of
     * @param n The number of (first) elements you want to sum up
     * @return Sum of first n elements
     */
    function sumN(uint256[] memory arr, uint256 n) internal pure returns (uint256) {
        require(n <= arr.length, "N too high");
        uint256 total = 0;

        for (uint256 i = 0; i < n; i++) {
            total += arr[i];
        }

        return total;
    }

    /**
     * @notice Get the mean of an (unsigned) array
     * @param arr Array of uint256's
     * @return The mean of the array's elements
     */
    function mean(uint256[] memory arr) internal pure returns (uint256) {
        uint256 n = arr.length;

        return sum(arr) / n;
    }

    /**
     * @notice Get the mean of the first n elements of an (unsigned) array
     * @dev Used for zero-initialised arrays where you only want to calculate
     *      the mean of the first n (populated) elements; rest are 0
     * @param arr Array to get the mean of
     * @param len Divisor/number of elements to get the mean of
     * @return Average of first n elements
     */
    function meanN(uint256[] memory arr, uint256 len) internal pure returns (uint256) {
        require(len != 0, "len is 0");
        return sumN(arr, len) / len;
    }

    /**
     * @notice Get the minimum of two unsigned numbers
     * @param a First number
     * @param b Second number
     * @return Minimum of the two
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Get the minimum of two signed numbers
     * @param a First (signed) number
     * @param b Second (signed) number
     * @return Minimum of the two number
     */
    function signedMin(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}