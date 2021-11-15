//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {BasePriceOracle} from "./BasePriceOracle.sol";
import {AggregatorV3Interface} from "../../interfaces/chainlink/AggregatorV3Interface.sol";

/**
 * @title On-chain Price Oracle (Chainlink Direct)
 * @notice reads the price feed from 1 Chainlink aggregator directly
 * `decimals` and `description` are copied as-is
 */
contract ChainlinkDirectPrice is BasePriceOracle {
    uint8 public override decimals;
    string public override description;

    AggregatorV3Interface public aggregator;

    function initialize(
        address aggregatorAddr,
        string memory _baseSymbol,
        string memory _quoteSymbol,
        address _baseAddr,
        address _quoteAddr
    ) public initializer {
        require(aggregatorAddr != address(0), "Chainlink aggregator address is 0");
        require(_baseAddr != address(0), "_baseaddr is 0");
        require(_quoteAddr != address(0), "_quoteAddr is 0");
        aggregator = AggregatorV3Interface(aggregatorAddr);
        decimals = aggregator.decimals();
        description = aggregator.description();
        super.setSymbols(_baseSymbol, _quoteSymbol, _baseAddr, _quoteAddr);
    }

    function lastUpdate() external view override returns (uint256 updateAt) {
        (, , , updateAt, ) = aggregator.latestRoundData();
    }

    /**
     * @dev internal function to find "baseSymbol / quoteSymbol" rate
     * @return rate in `decimals`, or type(uint256).max if the rate is invalid
     */
    function priceInternal() internal view returns (uint256) {
        (, int256 answer, , , ) = aggregator.latestRoundData();
        if (answer <= 0) return type(uint256).max; // non-positive price feed is invalid
        return uint256(answer);
    }

    function price(address _baseAddr) external view override isValidSymbol(_baseAddr) returns (uint256) {
        if (baseAddr == _baseAddr) return priceInternal();
        return 10**(decimals * 2) / priceInternal();
    }

    function priceByQuoteSymbol(address _quoteAddr) external view override isValidSymbol(_quoteAddr) returns (uint256) {
        if (quoteAddr == _quoteAddr) return priceInternal();
        return 10**(decimals * 2) / priceInternal();
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

