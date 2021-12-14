// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ISystemParameters.sol";

import "./libraries/PureParameters.sol";

import "./common/Globals.sol";

contract SystemParameters is ISystemParameters, OwnableUpgradeable {
    using PureParameters for PureParameters.Param;

    bytes32 public constant LIQUIDATION_BOUNDARY_KEY = keccak256("LIQUIDATION_BOUNDARY");

    bytes32 public constant CURVE_REGISTRY_KEY = keccak256("CURVE_REGISTRY");
    bytes32 public constant CURVE_DOLLAR_ZAP_KEY = keccak256("CURVE_DOLLAR_ZAP");
    bytes32 public constant YEARN_REGISTRY_KEY = keccak256("YEARN_REGISTRY");

    mapping(bytes32 => PureParameters.Param) private _parameters;

    function systemParametersInitialize() external initializer {
        __Ownable_init();
    }

    function getLiquidationBoundaryParam() external view override returns (uint256) {
        return _getParam(LIQUIDATION_BOUNDARY_KEY).getUintFromParam();
    }

    function getCurveZapParam() external view override returns (address) {
        return _getParam(CURVE_DOLLAR_ZAP_KEY).getAdrressFromParam();
    }

    function getCurveRegistryParam() external view override returns (address) {
        return _getParam(CURVE_REGISTRY_KEY).getAdrressFromParam();
    }

    function getYEarnRegistryParam() external view override returns (address) {
        return _getParam(YEARN_REGISTRY_KEY).getAdrressFromParam();
    }

    function setupLiquidationBoundary(uint256 _newValue) external onlyOwner {
        require(
            _newValue >= ONE_PERCENT * 50 && _newValue <= ONE_PERCENT * 80,
            "SystemParameters: The new value of the liquidation boundary is invalid."
        );

        _parameters[LIQUIDATION_BOUNDARY_KEY] = PureParameters.makeUintParam(_newValue);

        emit UintParamUpdated(LIQUIDATION_BOUNDARY_KEY, _newValue);
    }

    function setupCurveZap(address _newValue) external onlyOwner {
        _parameters[CURVE_DOLLAR_ZAP_KEY] = PureParameters.makeAdrressParam(_newValue);

        emit AddressParamUpdated(CURVE_DOLLAR_ZAP_KEY, _newValue);
    }

    function setupCurveRegistry(address _newValue) external onlyOwner {
        _parameters[CURVE_REGISTRY_KEY] = PureParameters.makeAdrressParam(_newValue);

        emit AddressParamUpdated(CURVE_REGISTRY_KEY, _newValue);
    }

    function setupYEarnRegistry(address _newValue) external onlyOwner {
        _parameters[YEARN_REGISTRY_KEY] = PureParameters.makeAdrressParam(_newValue);

        emit AddressParamUpdated(YEARN_REGISTRY_KEY, _newValue);
    }

    function _getParam(bytes32 _paramKey) internal view returns (PureParameters.Param memory) {
        require(
            PureParameters.paramExists(_parameters[_paramKey]),
            "SystemParameters: Param for this key doesn't exist."
        );

        return _parameters[_paramKey];
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint8 constant STANDARD_DECIMALS = 18;
uint256 constant ONE_TOKEN = 10**STANDARD_DECIMALS;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint8 constant PRICE_DECIMALS = 8;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ISystemParameters {
    event UintParamUpdated(bytes32 _paramKey, uint256 _newValue);
    event AddressParamUpdated(bytes32 _paramKey, address _newValue);

    /**
     * @notice Getter for parameter by key LIQUIDATION_BOUNDARY_KEY
     * @return current liquidation boundary parameter value
     */
    function getLiquidationBoundaryParam() external view returns (uint256);

    /**
     * @notice Getter for parameter by key YEARN_CONTROLLER_KEY
     * @return current YEarn controller parameter value
     */
    function getYEarnRegistryParam() external view returns (address);

    /**
     * @notice Getter for parameter by key CURVE_REGISTRY_KEY
     * @return current cerve pool parameter value
     */
    function getCurveRegistryParam() external view returns (address);

    /**
     * @notice Getter for parameter by key CURVE_DOLLAR_ZAP_KEY
     * @return current cerve zap parameter value
     */
    function getCurveZapParam() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

library PureParameters {
    enum Types {NOT_EXIST, UINT, ADDRESS, BYTES32, BOOL}

    struct Param {
        uint256 uintParam;
        address addressParam;
        bytes32 bytes32Param;
        bool boolParam;
        Types currentType;
    }

    function makeUintParam(uint256 _num) internal pure returns (Param memory) {
        return
            Param({
                uintParam: _num,
                currentType: Types.UINT,
                addressParam: address(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getUintFromParam(Param memory _param) internal pure returns (uint256) {
        require(_param.currentType == Types.UINT, "PureParameters: Parameter not contain uint.");

        return _param.uintParam;
    }

    function makeAdrressParam(address _address) internal pure returns (Param memory) {
        return
            Param({
                addressParam: _address,
                currentType: Types.ADDRESS,
                uintParam: uint256(0),
                bytes32Param: bytes32(0),
                boolParam: false
            });
    }

    function getAdrressFromParam(Param memory _param) internal pure returns (address) {
        require(
            _param.currentType == Types.ADDRESS,
            "PureParameters: Parameter not contain address."
        );

        return _param.addressParam;
    }

    function makeBytes32Param(bytes32 _hash) internal pure returns (Param memory) {
        return
            Param({
                bytes32Param: _hash,
                currentType: Types.BYTES32,
                addressParam: address(0),
                uintParam: uint256(0),
                boolParam: false
            });
    }

    function getBytes32FromParam(Param memory _param) internal pure returns (bytes32) {
        require(
            _param.currentType == Types.BYTES32,
            "PureParameters: Parameter not contain bytes32."
        );

        return _param.bytes32Param;
    }

    function makeBoolParam(bool _bool) internal pure returns (Param memory) {
        return
            Param({
                boolParam: _bool,
                currentType: Types.BOOL,
                addressParam: address(0),
                uintParam: uint256(0),
                bytes32Param: bytes32(0)
            });
    }

    function getBoolFromParam(Param memory _param) internal pure returns (bool) {
        require(_param.currentType == Types.BOOL, "PureParameters: Parameter not contain bool.");

        return _param.boolParam;
    }

    function paramExists(Param memory _param) internal pure returns (bool) {
        return (_param.currentType != Types.NOT_EXIST);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}