// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../interface/IVolatilityOracle.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract VolatilityOracleOffChain is IVolatilityOracle, Initializable {
    address public signatory;

    address private _everlastingOption;

    uint256 public timestamp;
    uint256 public override price;
    uint256 public override volatility;

    constructor(address signatory_) {
        signatory = signatory_;
    }

    function initialize(address everlastingOption_) external initializer {
        _everlastingOption = everlastingOption_;
    }

    // update oracle volatility using off chain signed volatility
    // the signature must be verified in order for the volatility to be updated
    function updateVolatilityAndPrice(
        uint256 timestamp_,
        uint256 price_,
        uint256 volatility_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {
        if (timestamp_ > timestamp) {
            timestamp = timestamp_;
            volatility = volatility_;
            price = price_;
        }
    }

    function updateFromChainlink(
        uint256 timestamp_,
        uint256 price_,
        uint256 volatility_
    ) external override {
        require(msg.sender == _everlastingOption, "invalid sender");
        if (timestamp_ > timestamp) {
            timestamp = timestamp_;
            // save gas
            if (volatility_ != volatility) {
                volatility = volatility_;
            }
            if (price != price_) {
                price = price_;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVolatilityOracle {
    function volatility() external view returns (uint256);

    function price() external view returns (uint256);

    function updateVolatilityAndPrice(
        uint256 timestamp_,
        uint256 price_,
        uint256 volatility_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function updateFromChainlink(
        uint256 timestamp_,
        uint256 price_,
        uint256 volatility_
    ) external;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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