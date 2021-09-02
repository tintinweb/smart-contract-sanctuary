// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '../../Versioned.sol';
import '../../Pausable.sol';
import '../Adapter.sol';
import './interfaces/HegicETHOptions.888.sol';
import './interfaces/HegicWBTCOptions.888.sol';
import './interfaces/OptionType.888.sol';

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// Hegic888AdapterV1_1  => Invalid data length received
// Hegic888AdapterV1_2  => Invalid currency length received. Should be 1 (only ETH)
// Hegic888AdapterV1_3  => Invalid amounts length received. Should be 1 (only ETH)
// Hegic888AdapterV1_4  => While process ETH option purchase, invalid currency found, expected address(0) for ETH
// Hegic888AdapterV1_5  => While process ETH option purchase, amount received is not enough to perform purchase
// Hegic888AdapterV1_6  => While process ETH option purchase, an error occured when trying to send back extra ETH received
// Hegic888AdapterV1_7  => While process WBTC option purchase, invalid currency found, expected address(0) for ETH
// Hegic888AdapterV1_8  => While process WBTC option purchase, amount received is not enough to perform purchase
// Hegic888AdapterV1_9  => While process WBTC option purchase, an error occured when trying to send back extra ETH received
// Hegic888AdapterV1_10 => Invalid asset type provided

/// @title Hegic888AdapterV1
/// @author Iulian Rotaru
/// @notice Adapter to purchase Hegic ETH or WBTC options
contract Hegic888AdapterV1 is Versioned, Pausable, Adapter {
    //
    //      _        _
    //  ___| |_ __ _| |_ ___
    // / __| __/ _` | __/ _ \
    // \__ \ || (_| | ||  __/
    // |___/\__\__,_|\__\___|
    //

    // Address of Hegic ETH options contract
    HegicETHOptionsV888 public hegicEthOptions;

    // Address of Hegic WBTC options contract
    HegicWBTCOptionsV888 public hegicWbtcOptions;

    //
    //   ___ _ __  _   _ _ __ ___  ___
    //  / _ \ '_ \| | | | '_ ` _ \/ __|
    // |  __/ | | | |_| | | | | | \__ \
    //  \___|_| |_|\__,_|_| |_| |_|___/
    //

    // Enum of supported asset types
    enum AssetType {
        Eth,
        Wbtc
    }

    //
    //  _       _                        _
    // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
    // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
    // | | | | | ||  __/ |  | | | | (_| | \__ \
    // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Perform an option purchase
    /// @param caller Address purchasing the option
    /// @param currencies List of usable currencies
    /// @param amounts List of usable currencies amounts
    /// @param data Extra data usable by adapter
    /// @return A tuple containing used amounts and output data
    function purchase(
        address caller,
        address[] memory currencies,
        uint256[] memory amounts,
        bytes calldata data
    ) internal override returns (uint256[] memory, bytes memory) {
        require(data.length == 160, 'Hegic888AdapterV1_1');
        require(currencies.length == 1, 'Hegic888AdapterV1_2');
        require(amounts.length == 1, 'Hegic888AdapterV1_3');

        AssetType _assetType; // Stack depth optimizations
        uint256 total;
        uint256[] memory totalETH = new uint256[](1);
        uint256 optionID;

        {
            OptionTypeV888.OptionType _optionType;
            uint256 _period;
            uint256 _amount;
            uint256 _strike;
            (_optionType, _assetType, _period, _amount, _strike) = abi.decode(
                data,
                (OptionTypeV888.OptionType, AssetType, uint256, uint256, uint256)
            );

            if (_assetType == AssetType.Eth) {
                require(currencies[0] == address(0), 'Hegic888AdapterV1_4');
                (total, , , ) = hegicEthOptions.fees(_period, _amount, _strike, _optionType);
                totalETH[0] = total;
                require(msg.value >= totalETH[0], 'Hegic888AdapterV1_5');
                optionID = hegicEthOptions.create{value: totalETH[0]}(_period, _amount, _strike, _optionType);

                if (address(this).balance > 0) {
                    (bool success, ) = payable(caller).call{value: address(this).balance}('');
                    require(success, 'Hegic888AdapterV1_6');
                }
            } else if (AssetType(_assetType) == AssetType.Wbtc) {
                require(currencies[0] == address(0), 'Hegic888AdapterV1_7');
                (total, totalETH[0], , , ) = hegicWbtcOptions.fees(_period, _amount, _strike, _optionType);
                require(msg.value >= totalETH[0], 'Hegic888AdapterV1_8');
                optionID = hegicWbtcOptions.create{value: totalETH[0]}(_period, _amount, _strike, _optionType);

                if (address(this).balance > 0) {
                    (bool success, ) = payable(caller).call{value: address(this).balance}('');
                    require(success, 'Hegic888AdapterV1_9');
                }
            } else {
                revert('Hegic888AdapterV1_10');
            }
        }

        if (_assetType == AssetType.Wbtc) {
            hegicWbtcOptions.transfer(optionID, payable(caller));
        } else {
            hegicEthOptions.transfer(optionID, payable(caller));
        }

        return (totalETH, abi.encode(total, optionID));
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Retrieve adapter name
    /// @return Adapter name
    function name() external pure override returns (string memory) {
        return 'Hegic888V1';
    }

    //
    //  _       _ _
    // (_)_ __ (_) |_
    // | | '_ \| | __|
    // | | | | | | |_
    // |_|_| |_|_|\__|
    //

    function __Hegic888AdapterV1__constructor(address _gateway, address _hegicEthOptions, address _hegicWbtcOptions)
        public
        initVersion(1)
    {
        hegicEthOptions = HegicETHOptionsV888(_hegicEthOptions);
        hegicWbtcOptions = HegicWBTCOptionsV888(_hegicWbtcOptions);
        setGateway(_gateway);
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

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// V1 => Already initializing
// V2 => Invalid version received. Expected current

/// @title Versioned
/// @author Iulian Rotaru
/// @notice Initialized for multiple versions
contract Versioned {
    //
    //      _        _
    //  ___| |_ __ _| |_ ___
    // / __| __/ _` | __/ _ \
    // \__ \ || (_| | ||  __/
    // |___/\__\__,_|\__\___|
    //

    // Stores the current implementation version
    uint256 version;

    // Stores the initializing state for each version
    bool private _initializing;

    //
    //                      _ _  __ _
    //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
    // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
    // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
    // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
    //

    // Allows to be called only if version number is current version + 1
    modifier initVersion(uint256 _version) {
        require(!_initializing, 'V1');
        require(_version == version + 1, 'V2');
        version = _version;

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Retrieves current implementation version
    /// @return Implementatiomn version
    function getVersion() public view returns (uint256) {
        return version;
    }
}

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/StorageSlot.sol';

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// P1 => Contract is not paused
// P2 => Contract is paused

/// @title Pausable
/// @author Iulian Rotaru
/// @notice Pausable logics, reading storage slot to retrieve pause state
contract Pausable {
    //
    //                      _              _
    //   ___ ___  _ __  ___| |_ __ _ _ __ | |_ ___
    //  / __/ _ \| '_ \/ __| __/ _` | '_ \| __/ __|
    // | (_| (_) | | | \__ \ || (_| | | | | |_\__ \
    //  \___\___/|_| |_|___/\__\__,_|_| |_|\__|___/
    //

    // Storage slot for the Paused state
    bytes32 internal constant _PAUSED_SLOT = 0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450;

    //
    //                      _ _  __ _
    //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
    // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
    // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
    // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
    //

    // Allows methods to be called if paused
    modifier whenPaused() {
        require(StorageSlot.getBooleanSlot(_PAUSED_SLOT).value == true, 'P1');
        _;
    }

    // Allows methods to be called if not paused
    modifier whenNotPaused() {
        require(StorageSlot.getBooleanSlot(_PAUSED_SLOT).value == false, 'P1');
        _;
    }
}

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../Owned.sol';

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// A1 => Useless call, not changing address
// A2 => Invalid currencies and amount length
// A3 => Received amount of ETH too low

/// @title Adapter
/// @author Iulian Rotaru
/// @notice Adapter base logics
abstract contract Adapter is Owned {

    address public gateway;

    modifier isGateway() {
      require(msg.sender == gateway, 'A1');
      _;
    }

    //
    //  _       _                        _
    // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
    // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
    // | | | | | ||  __/ |  | | | | (_| | \__ \
    // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Changes gateway address
    /// @param newGateway Address of new gateway
    function setGateway(address newGateway) internal {
      require(gateway != newGateway, 'A1');
      gateway = newGateway;
    }

    /// @dev Perform an internal option purchase
    /// @param caller Address purchasing the option
    /// @param currencies List of usable currencies
    /// @param amounts List of usable currencies amounts
    /// @param data Extra data usable by adapter
    /// @return A tuple containing used amounts and output data
    function purchase(
        address caller,
        address[] memory currencies,
        uint256[] memory amounts,
        bytes calldata data
    ) internal virtual returns (uint256[] memory, bytes memory);

    function _preparePayment(address[] memory currencies, uint256[] memory amounts) internal {
        require(currencies.length == amounts.length, 'A2');
        for (uint256 currencyIdx = 0; currencyIdx < currencies.length; ++currencyIdx) {
            if (currencies[currencyIdx] == address(0)) {
                require(msg.value >= amounts[currencyIdx], 'A3');
            } else {
                IERC20(currencies[currencyIdx]).transferFrom(msg.sender, address(this), amounts[currencyIdx]);
            }
        }
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Perform an option purchase
    /// @param caller Address purchasing the option
    /// @param currencies List of usable currencies
    /// @param amounts List of usable currencies amounts
    /// @param data Extra data usable by adapter
    /// @return A tuple containing used amounts and output data
    function run(
        address caller,
        address[] memory currencies,
        uint256[] memory amounts,
        bytes calldata data
    ) external payable isGateway returns (uint256[] memory, bytes memory) {
        _preparePayment(currencies, amounts);
        return purchase(caller, currencies, amounts, data);
    }

    function name() external view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import './OptionType.888.sol';

interface HegicETHOptionsV888 {
    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionTypeV888.OptionType optionType
    ) external payable returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;

    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionTypeV888.OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        );
}

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import './OptionType.888.sol';

interface HegicWBTCOptionsV888 {
    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionTypeV888.OptionType optionType
    ) external payable returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;

    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionTypeV888.OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 totalETH,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        );

    function wbtc() external view returns (address);
}

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

library OptionTypeV888 {
    //
    //   ___ _ __  _   _ _ __ ___  ___
    //  / _ \ '_ \| | | | '_ ` _ \/ __|
    // |  __/ | | | |_| | | | | | \__ \
    //  \___|_| |_|\__,_|_| |_| |_|___/
    //

    enum OptionType {
        Invalid,
        Put,
        Call
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/StorageSlot.sol';

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// O1 => Caller is not admin

/// @title Owned
/// @author Iulian Rotaru
/// @notice Owner logics, reading storage slot to retrieve admin
contract Owned {
    //
    //                      _              _
    //   ___ ___  _ __  ___| |_ __ _ _ __ | |_ ___
    //  / __/ _ \| '_ \/ __| __/ _` | '_ \| __/ __|
    // | (_| (_) | | | \__ \ || (_| | | | | |_\__ \
    //  \___\___/|_| |_|___/\__\__,_|_| |_|\__|___/
    //

    // Storage slot for the Admin address
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    //
    //                      _ _  __ _
    //  _ __ ___   ___   __| (_)/ _(_) ___ _ __ ___
    // | '_ ` _ \ / _ \ / _` | | |_| |/ _ \ '__/ __|
    // | | | | | | (_) | (_| | |  _| |  __/ |  \__ \
    // |_| |_| |_|\___/ \__,_|_|_| |_|\___|_|  |___/
    //

    // Modifier allowing only admins to call methods
    modifier isAdmin() {
        require(StorageSlot.getAddressSlot(_ADMIN_SLOT).value == msg.sender, 'O1');
        _;
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Retrieves Admin address
    /// @return Admin address
    function getAdmin() public view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }
}

{
  "optimizer": {
    "enabled": false,
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