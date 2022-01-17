//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibExchange} from "../../libraries/core/RideLibExchange.sol";

import {IRideExchange} from "../../interfaces/core/IRideExchange.sol";

contract RideExchange is IRideExchange {
    function addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) external override {
        RideLibExchange._addXPerYPriceFeed(_keyX, _keyY, _priceFeed);
    }

    function removeXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        external
        override
    {
        RideLibExchange._removeXPerYPriceFeed(_keyX, _keyY);
    }

    function getXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        external
        view
        override
    {
        RideLibExchange._getXPerYPriceFeed(_keyX, _keyY);
    }

    function convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) external view override {
        RideLibExchange._convertCurrency(_keyX, _keyY, _amountX);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";

library RideLibExchange {
    bytes32 constant STORAGE_POSITION_EXCHANGE = keccak256("ds.exchange");

    struct StorageExchange {
        mapping(bytes32 => mapping(bytes32 => address)) xToYToXPerYPriceFeed;
        mapping(bytes32 => mapping(bytes32 => bool)) xToYToXPerYInverse;
    }

    function _storageExchange()
        internal
        pure
        returns (StorageExchange storage s)
    {
        bytes32 position = STORAGE_POSITION_EXCHANGE;
        assembly {
            s.slot := position
        }
    }

    function _requireXPerYPriceFeedSupported(bytes32 _keyX, bytes32 _keyY)
        internal
        view
    {
        require(
            _storageExchange().xToYToXPerYPriceFeed[_keyX][_keyY] != address(0),
            "price feed not supported"
        );
    }

    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );

    // NOTE: to add ETH/USD price feed (displayed on chainlink), x = USD, y = ETH
    function _addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) internal {
        RideLibOwnership._requireIsContractOwner();
        RideLibCurrencyRegistry._requireCurrencySupported(_keyX);
        RideLibCurrencyRegistry._requireCurrencySupported(_keyY);

        require(_priceFeed != address(0), "zero price feed address");
        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXPerYPriceFeed[_keyX][_keyY] == address(0),
            "price feed already supported"
        );
        s1.xToYToXPerYPriceFeed[_keyX][_keyY] = _priceFeed;
        s1.xToYToXPerYPriceFeed[_keyY][_keyX] = _priceFeed; // reverse pairing
        s1.xToYToXPerYInverse[_keyY][_keyX] = true;

        emit PriceFeedAdded(msg.sender, _keyX, _keyY, _priceFeed);
    }

    event PriceFeedRemoved(address indexed sender, address priceFeed);

    function _removeXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) internal {
        RideLibOwnership._requireIsContractOwner();
        _requireXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();
        address priceFeed = s1.xToYToXPerYPriceFeed[_keyX][_keyY];
        delete s1.xToYToXPerYPriceFeed[_keyX][_keyY];
        delete s1.xToYToXPerYPriceFeed[_keyY][_keyX]; // reverse pairing
        delete s1.xToYToXPerYInverse[_keyY][_keyX];

        // require(
        //     s1.xToYToXPerYPriceFeed[_keyX][_keyY] == address(0),
        //     "price feed not removed 1"
        // );
        // require(
        //     s1.xToYToXPerYPriceFeed[_keyY][_keyX] == address(0),
        //     "price feed not removed 2"
        // ); // reverse pairing
        // require(!s1.xToYToXPerYInverse[_keyY][_keyX], "reverse not removed");

        emit PriceFeedRemoved(msg.sender, priceFeed);
    }

    function _getXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (address)
    {
        _requireXPerYPriceFeedSupported(_keyX, _keyY);
        return _storageExchange().xToYToXPerYPriceFeed[_keyX][_keyY];
    }

    function _convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        if (_storageExchange().xToYToXPerYInverse[_keyX][_keyY]) {
            return _convertInverse(_keyX, _keyY, _amountX);
        } else {
            return _convertDirect(_keyX, _keyY, _amountX);
        }
    }

    function _convertDirect(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        uint256 xPerYWei = _getXPerYInWei(_keyX, _keyY);
        return (_amountX / xPerYWei) * 10e18; // note: no rounding occurs as value is converted into wei
    }

    function _convertInverse(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        uint256 xPerYWei = _getXPerYInWei(_keyX, _keyY);
        return (_amountX * xPerYWei) / 10e18; // note: no rounding occurs as value is converted into wei
    }

    function _getXPerYInWei(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _getXPerYPriceFeed(_keyX, _keyY)
        );
        (, int256 xPerY, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return uint256(uint256(xPerY) * 10**(18 - decimals)); // convert to wei
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

interface IRideExchange {
    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );

    function addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) external;

    event PriceFeedRemoved(address indexed sender, address priceFeed);

    function removeXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) external;

    function getXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) external view;

    function convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibOwnership {
    bytes32 constant STORAGE_POSITION_OWNERSHIP = keccak256("ds.ownership");

    struct StorageOwnership {
        address contractOwner;
    }

    function _storageOwnership()
        internal
        pure
        returns (StorageOwnership storage s)
    {
        bytes32 position = STORAGE_POSITION_OWNERSHIP;
        assembly {
            s.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setContractOwner(address _newOwner) internal {
        StorageOwnership storage s1 = _storageOwnership();
        address previousOwner = s1.contractOwner;
        s1.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address) {
        return _storageOwnership().contractOwner;
    }

    function _requireIsContractOwner() internal view {
        require(
            msg.sender == _storageOwnership().contractOwner,
            "not contract owner"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

// CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library RideLibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
        mapping(bytes32 => bool) currencyKeyToSupported;
        mapping(bytes32 => bool) currencyKeyToCrypto;
    }

    function _storageCurrencyRegistry()
        internal
        pure
        returns (StorageCurrencyRegistry storage s)
    {
        bytes32 position = STORAGE_POSITION_CURRENCYREGISTRY;
        assembly {
            s.slot := position
        }
    }

    function _requireCurrencySupported(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToSupported[_key],
            "currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "not crypto"
        );
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        bytes32 key = keccak256(abi.encode(_code));
        _register(key);
        return key;
    }

    function _registerCrypto(address _token) internal returns (bytes32) {
        require(_token != address(0), "zero token address");
        bytes32 key = bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        RideLibOwnership._requireIsContractOwner();
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    // _getKeyFiat to be called externally ONLY
    function _getKeyFiat(string memory _code) internal view returns (bytes32) {
        bytes32 key = keccak256(abi.encode(_code));
        _requireCurrencySupported(key);
        return key;
    }

    // _getKeyCrypto to be called externally ONLY
    function _getKeyCrypto(address _token) internal view returns (bytes32) {
        bytes32 key = bytes32(uint256(uint160(_token)) << 96);
        _requireCurrencySupported(key);
        return key;
    }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        RideLibOwnership._requireIsContractOwner();
        _requireCurrencySupported(_key);
        StorageCurrencyRegistry storage s1 = _storageCurrencyRegistry();
        delete s1.currencyKeyToSupported[_key]; // delete cheaper than set false
        // require(!s1.currencyKeyToSupported[_key], "failed to remove 1");

        if (s1.currencyKeyToCrypto[_key]) {
            delete s1.currencyKeyToCrypto[_key];
            // require(!s1.currencyKeyToCrypto[_key], "failed to remove 2");
        }

        emit CurrencyRemoved(msg.sender, _key);
    }
}