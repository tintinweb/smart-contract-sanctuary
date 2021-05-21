// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@yield-protocol/utils-v2/contracts/access/Ownable.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "../../math/CastBytes32Bytes6.sol";
import "./AggregatorV3Interface.sol";


/**
 * @title ChainlinkMultiOracle
 */
contract ChainlinkMultiOracle is IOracle, Ownable {
    using CastBytes32Bytes6 for bytes32;

    event SourcesSet(bytes6 baseId, bytes6 quoteId, address source);

    struct Source {
        address source;
        uint8 decimals;
    }

    mapping(bytes6 => mapping(bytes6 => Source)) public sources;

    /**
     * @notice Set or reset an oracle source
     */
    function setSource(bytes6 base, bytes6 quote, address source) public onlyOwner {
        uint8 decimals = AggregatorV3Interface(source).decimals();
        require (decimals <= 18, "Unsupported decimals");
        sources[base][quote] = Source({
            source: source,
            decimals: decimals
        });
        emit SourcesSet(base, quote, source);
    }

    /**
     * @notice Set or reset a number of oracle sources
     */
    function setSources(bytes6[] memory bases, bytes6[] memory quotes, address[] memory sources_) public onlyOwner {
        require(
            bases.length == quotes.length && 
            bases.length == sources_.length,
            "Mismatched inputs"
        );
        for (uint256 i = 0; i < bases.length; i++)
            setSource(bases[i], quotes[i], sources_[i]);
    }

    /**
     * @notice Retrieve the latest price of the price oracle.
     * @return price
     */
    function _peek(bytes6 base, bytes6 quote) private view returns (uint price, uint updateTime) {
        int rawPrice;
        uint80 roundId;
        uint80 answeredInRound;
        Source memory source = sources[base][quote];
        require (source.source != address(0), "Source not found");
        (roundId, rawPrice,, updateTime, answeredInRound) = AggregatorV3Interface(source.source).latestRoundData();
        require(rawPrice > 0, "Chainlink price <= 0");
        require(updateTime != 0, "Incomplete round");
        require(answeredInRound >= roundId, "Stale price");
        price = uint(rawPrice) * 10 ** (18 - source.decimals);
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * @return value
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount) public virtual override view returns (uint256 value, uint256 updateTime) {
        uint256 price;
        (price, updateTime) = _peek(base.b6(), quote.b6());
        value = price * amount / 1e18;
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.. Same as `peek` for this oracle.
     * @return value
     */
    function get(bytes32 base, bytes32 quote, uint256 amount) public virtual override view returns (uint256 value, uint256 updateTime) {
        uint256 price;
        (price, updateTime) = _peek(base.b6(), quote.b6());
        value = price * amount / 1e18;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(bytes32 base, bytes32 quote, uint256 amount) external returns (uint256 value, uint256 updateTime);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


library CastBytes32Bytes6 {
    function b6(bytes32 x) internal pure returns (bytes6 y){
        require (bytes32(y = bytes6(x)) == x, "Cast overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

{
  "optimizer": {
    "enabled": true,
    "runs": 5000
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