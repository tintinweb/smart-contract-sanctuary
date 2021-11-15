//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {BasePriceOracle} from "./BasePriceOracle.sol";
import {AggregatorV3Interface} from "../../interfaces/chainlink/AggregatorV3Interface.sol";

/**
 * @title On-chain Price Oracle (Chainlink Indirect)
 * @notice reads the price feed from 2 Chainlink aggregators, both are against the same currency
 * `decimals` is fixed to be 18 (to retain precision after division)
 * `description` is passed in from constructor
 */
contract ChainlinkIndirectPrice is BasePriceOracle {
    uint8 public constant override decimals = 18;
    string public override description;

    // Naming rule of Chainlink price feeds:
    // 1. USD is always on the right.
    // 2. Native currencies (ETH, BNB...) is usually on the right,
    //    unless the rate is quoted against USD.
    // 3. ERC20 (or eqivalent) tokens are always on the left.

    // Chainlink aggregators
    AggregatorV3Interface public aggregator0; // baseSymbol / USD, for example
    AggregatorV3Interface public aggregator1; // quoteSymbol / USD

    // Chainlink price feed decimals
    uint8 private decimals0;
    uint8 private decimals1;

    function initialize(
        address aggregator0Addr,
        address aggregator1Addr,
        string memory _baseSymbol,
        string memory _quoteSymbol,
        address _baseAddr,
        address _quoteAddr
    ) public initializer {
        require(aggregator0Addr != address(0), "Chainlink aggregator0 address is 0");
        require(aggregator1Addr != address(0), "Chainlink aggregator1 address is 0");
        require(_baseAddr != address(0), "_baseAddr is 0");
        require(_quoteAddr != address(0), "_quoteAddr is 0");
        aggregator0 = AggregatorV3Interface(aggregator0Addr);
        aggregator1 = AggregatorV3Interface(aggregator1Addr);
        decimals0 = aggregator0.decimals();
        decimals1 = aggregator1.decimals();

        super.setSymbols(_baseSymbol, _quoteSymbol, _baseAddr, _quoteAddr);
        description = string(abi.encodePacked(baseSymbol, " / ", quoteSymbol));
    }

    function lastUpdate() external view override returns (uint256 updateAt) {
        (, , , uint256 updateAt0, ) = aggregator0.latestRoundData();
        (, , , uint256 updateAt1, ) = aggregator1.latestRoundData();
        updateAt = updateAt0 > updateAt1 ? updateAt0 : updateAt1; // use more recent `updateAt`
    }

    /**
     * @dev internal function to find "baseSymbol / quoteSymbol" rate
     * @return rate in `decimals`, or type(uint256).max if the rate is invalid
     */
    function priceInternal() internal view returns (uint256) {
        (, int256 answer0, , , ) = aggregator0.latestRoundData();
        (, int256 answer1, , , ) = aggregator1.latestRoundData();
        if (answer0 > 0 && answer1 > 0) {
            return (10**(decimals + decimals1 - decimals0) * uint256(answer0)) / uint256(answer1);
        }
        return type(uint256).max; // non-positive price feeds are invalid
    }

    function price(address _baseAddr) external view override isValidSymbol(_baseAddr) returns (uint256) {
        if (baseAddr == _baseAddr) return priceInternal();
        return 1e36 / priceInternal();
    }

    function priceByQuoteSymbol(address _quoteAddr) external view override isValidSymbol(_quoteAddr) returns (uint256) {
        if (quoteAddr == _quoteAddr) return priceInternal();
        return 1e36 / priceInternal();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title BasePriceOracle Abstract Contract
 * @notice Abstract Contract to implement variables and modifiers in common
 */
abstract contract BasePriceOracle is IPriceOracle, Initializable {
    string public override baseSymbol;
    string public override quoteSymbol;
    address public override baseAddr;
    address public override quoteAddr;

    function setSymbols(
        string memory _baseSymbol,
        string memory _quoteSymbol,
        address _baseAddr,
        address _quoteAddr
    ) internal {
        baseSymbol = _baseSymbol;
        quoteSymbol = _quoteSymbol;
        baseAddr = _baseAddr;
        quoteAddr = _quoteAddr;
    }

    modifier isValidSymbol(address addr) {
        require(addr == baseAddr || addr == quoteAddr, "Symbol not in this price oracle");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPriceOracle {
    /**
     * @return decimals of the "baseSymbol / quoteSymbol" rate
     */
    function decimals() external view returns (uint8);

    /**
     * @return name of the token pair, in the form of "baseSymbol / quoteSymbol"
     */
    function description() external view returns (string memory);

    /**
     * @return name of the base symbol
     */
    function baseSymbol() external view returns (string memory);

    /**
     * @return name of the quote symbol
     */
    function quoteSymbol() external view returns (string memory);

    /**
     * @return address of the base symbol, zero address if `baseSymbol` is USD
     */
    function baseAddr() external view returns (address);

    /**
     * @return address of the quote symbol, zero address if `baseSymbol` is USD
     */
    function quoteAddr() external view returns (address);

    /**
     * @return updateAt timestamp of the last update as seconds since unix epoch
     */
    function lastUpdate() external view returns (uint256 updateAt);

    /**
     * @param _baseAddr address of the base symbol
     * @return the price feed in `decimals`, or type(uint256).max if the rate is invalid
     * Example: priceFeed() == 2e18
     *          => 1 baseSymbol = 2 quoteSymbol
     */
    function price(address _baseAddr) external view returns (uint256);

    /**
     * @param _quoteAddr address of the quote symbol
     * @return the price feed in `decimals`, or type(uint256).max if the rate is invalid
     */
    function priceByQuoteSymbol(address _quoteAddr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

