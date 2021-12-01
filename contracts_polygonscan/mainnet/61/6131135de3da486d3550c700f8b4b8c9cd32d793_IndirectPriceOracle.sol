//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {BasePriceOracle} from "./BasePriceOracle.sol";

contract IndirectPriceOracle is BasePriceOracle {
    uint8 public constant override decimals = 18;
    string public override description;

    IPriceOracle public priceOracle0;
    IPriceOracle public priceOracle1;
    string public intermediateSymbol;
    address public intermediateAddr;

    bool public AC;
    bool public AD;
    bool public BC;
    bool public BD;

    uint8 public decimals0;
    uint8 public decimals1;

    function initialize(address _priceOracle0, address _priceOracle1) external initializer {
        require(_priceOracle0 != address(0), "IPriceOracle 0 address is 0");
        require(_priceOracle1 != address(0), "IPriceOracle 1 address is 0");

        priceOracle0 = IPriceOracle(_priceOracle0);
        priceOracle1 = IPriceOracle(_priceOracle1);
        decimals0 = priceOracle0.decimals();
        decimals1 = priceOracle1.decimals();
        address A = priceOracle0.baseAddr();
        address B = priceOracle0.quoteAddr();
        address C = priceOracle1.baseAddr();
        address D = priceOracle1.quoteAddr();

        AC = A == C;
        AD = A == D;
        BC = B == C;
        BD = B == D;

        require(AC || AD || BC || BD, "Common address not found!");

        address _baseAddr;
        address _quoteAddr;
        string memory _baseSymbol;
        string memory _quoteSymbol;

        // setup symbols and addrs
        if (AC) {
            _baseAddr = B;
            _baseSymbol = priceOracle0.quoteSymbol();
            _quoteAddr = D;
            _quoteSymbol = priceOracle1.quoteSymbol();
            intermediateAddr = A;
            intermediateSymbol = priceOracle0.baseSymbol();
        } else if (AD) {
            _baseAddr = B;
            _baseSymbol = priceOracle0.quoteSymbol();
            _quoteAddr = C;
            _quoteSymbol = priceOracle1.baseSymbol();
            intermediateAddr = A;
            intermediateSymbol = priceOracle0.baseSymbol();
        } else if (BC) {
            _baseAddr = A;
            _baseSymbol = priceOracle0.baseSymbol();
            _quoteAddr = D;
            _quoteSymbol = priceOracle1.quoteSymbol();
            intermediateAddr = B;
            intermediateSymbol = priceOracle0.quoteSymbol();
        } else {
            _baseAddr = A;
            _baseSymbol = priceOracle0.baseSymbol();
            _quoteAddr = C;
            _quoteSymbol = priceOracle1.baseSymbol();
            intermediateAddr = B;
            intermediateSymbol = priceOracle0.quoteSymbol();
        }
        super.setSymbols(_baseSymbol, _quoteSymbol, _baseAddr, _quoteAddr);
        description = string(abi.encodePacked(baseSymbol, " / ", quoteSymbol));
    }

    function lastUpdate() external view override returns (uint256 updateAt) {
        uint256 oracle0LastUpdate = priceOracle0.lastUpdate();
        uint256 oracle1LastUpdate = priceOracle1.lastUpdate();
        // use more recent timestamp
        updateAt = oracle0LastUpdate > oracle1LastUpdate ? oracle0LastUpdate : oracle1LastUpdate;
    }

    function priceInternal() internal view returns (uint256) {
        uint256 price0 = priceOracle0.price(baseAddr);
        uint256 price1 = priceOracle1.price(intermediateAddr);

        if (price0 == type(uint256).max) return price0;
        if (price1 == type(uint256).max) return price1;

        // All 4 cases reduce to the same formula
        // if (AC) {
        //     // A==C
        //     // B / D = B / A * C / D
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // } else if (AD) {
        //     // A==D
        //     // B / C = B / A * D / C
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // } else if (BC) {
        //     // B==C
        //     // A / D = A / B * C / D
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // } else {
        //     // B==D
        //     // A / C = A / B * D / C
        //     price = priceOracle0.price(baseAddr) * priceOracle1.price(intermediateAdrr);
        // }

        return (price0 * price1 * 10**decimals) / 10**decimals0 / 10**decimals1;
    }

    function price(address _baseAddr) external view override isValidSymbol(_baseAddr) returns (uint256) {
        uint256 priceFeed = priceInternal();
        if (priceFeed == type(uint256).max) return priceFeed;
        if (baseAddr == _baseAddr) return priceFeed;
        return 1e36 / priceFeed;
    }

    function priceByQuoteSymbol(address _quoteAddr) external view override isValidSymbol(_quoteAddr) returns (uint256) {
        uint256 priceFeed = priceInternal();
        if (priceFeed == type(uint256).max) return priceFeed;
        if (quoteAddr == _quoteAddr) return priceFeed;
        return 1e36 / priceFeed;
    }
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