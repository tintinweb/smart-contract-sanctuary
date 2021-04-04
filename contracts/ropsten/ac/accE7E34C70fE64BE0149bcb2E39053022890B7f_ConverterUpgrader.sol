/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: solidity/contracts/utility/interfaces/IOwned.sol


pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;

    function acceptOwnership() external;
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {

}

// File: solidity/contracts/converter/interfaces/IConverter.sol


pragma solidity 0.6.12;




/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IERC20 _sourceToken,
        IERC20 _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IERC20 _sourceToken,
        IERC20 _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IERC20 _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function addReserve(IERC20 _token, uint32 _weight) external;

    function transferReservesOnUpgrade(address _newConverter) external;

    function onUpgradeComplete() external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IERC20 _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IERC20);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     *
     * @param _type        converter type
     * @param _anchor      converter anchor
     * @param _activated   true if the converter was activated, false if it was deactivated
     */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     *
     * @param _fromToken       source ERC20 token
     * @param _toToken         target ERC20 token
     * @param _trader          wallet that initiated the trade
     * @param _amount          input amount in units of the source token
     * @param _return          output amount minus conversion fee in units of the target token
     * @param _conversionFee   conversion fee in units of the target token
     */
    event Conversion(
        IERC20 indexed _fromToken,
        IERC20 indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     *
     * @param  _token1 address of the first token
     * @param  _token2 address of the second token
     * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
     * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
     */
    event TokenRateUpdate(IERC20 indexed _token1, IERC20 indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

// File: solidity/contracts/converter/interfaces/IConverterUpgrader.sol


pragma solidity 0.6.12;

/*
    Converter Upgrader interface
*/
interface IConverterUpgrader {
    function upgrade(bytes32 _version) external;

    function upgrade(uint16 _version) external;
}

// File: solidity/contracts/converter/interfaces/ITypedConverterCustomFactory.sol


pragma solidity 0.6.12;

/*
    Typed Converter Custom Factory interface
*/
interface ITypedConverterCustomFactory {
    function converterType() external pure returns (uint16);
}

// File: solidity/contracts/utility/interfaces/IContractRegistry.sol


pragma solidity 0.6.12;

/*
    Contract Registry interface
*/
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

// File: solidity/contracts/converter/interfaces/IConverterFactory.sol


pragma solidity 0.6.12;





/*
    Converter Factory interface
*/
interface IConverterFactory {
    function createAnchor(
        uint16 _type,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external returns (IConverterAnchor);

    function createConverter(
        uint16 _type,
        IConverterAnchor _anchor,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    ) external returns (IConverter);

    function customFactories(uint16 _type) external view returns (ITypedConverterCustomFactory);
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
 * @dev This contract provides support and utilities for contract ownership.
 */
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
     * @dev triggered when the owner is updated
     *
     * @param _prevOwner previous owner
     * @param _newOwner  new owner
     */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
     * @dev initializes a new Owned instance
     */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev allows transferring the contract ownership
     * the new owner still needs to accept the transfer
     * can only be called by the contract owner
     *
     * @param _newOwner    new contract owner
     */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
     * @dev used by a new owner to accept an ownership transfer
     */
    function acceptOwnership() public override {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;


/**
 * @dev Utilities & Common Modifiers
 */
contract Utils {
    uint32 internal constant PPM_RESOLUTION = 1000000;
    IERC20 internal constant NATIVE_TOKEN_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // ensures that the portion is valid
    modifier validPortion(uint32 _portion) {
        _validPortion(_portion);
        _;
    }

    // error message binary size optimization
    function _validPortion(uint32 _portion) internal pure {
        require(_portion > 0 && _portion <= PPM_RESOLUTION, "ERR_INVALID_PORTION");
    }

    // validates an external address - currently only checks that it isn't null or this
    modifier validExternalAddress(address _address) {
        _validExternalAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validExternalAddress(address _address) internal view {
        require(_address != address(0) && _address != address(this), "ERR_INVALID_EXTERNAL_ADDRESS");
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);
        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        require(fee <= PPM_RESOLUTION, "ERR_INVALID_FEE");
    }
}

// File: solidity/contracts/utility/ContractRegistryClient.sol


pragma solidity 0.6.12;




/**
 * @dev This is the base contract for ContractRegistry clients.
 */
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant LIQUIDITY_PROTECTION = "LiquidityProtection";
    bytes32 internal constant NETWORK_SETTINGS = "NetworkSettings";

    IContractRegistry public registry; // address of the current contract-registry
    IContractRegistry public prevRegistry; // address of the previous contract-registry
    bool public onlyOwnerCanUpdateRegistry; // only an owner can update the contract-registry

    /**
     * @dev verifies that the caller is mapped to the given contract name
     *
     * @param _contractName    contract name
     */
    modifier only(bytes32 _contractName) {
        _only(_contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 _contractName) internal view {
        require(msg.sender == addressOf(_contractName), "ERR_ACCESS_DENIED");
    }

    /**
     * @dev initializes a new ContractRegistryClient instance
     *
     * @param  _registry   address of a contract-registry contract
     */
    constructor(IContractRegistry _registry) internal validAddress(address(_registry)) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
     * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(msg.sender == owner || !onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract-registry
        IContractRegistry newRegistry = IContractRegistry(addressOf(CONTRACT_REGISTRY));

        // verify that the new contract-registry is different and not zero
        require(newRegistry != registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = newRegistry;
    }

    /**
     * @dev restores the previous contract-registry
     */
    function restoreRegistry() public ownerOnly {
        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
     * @dev restricts the permission to update the contract-registry
     *
     * @param _onlyOwnerCanUpdateRegistry  indicates whether or not permission is restricted to owner only
     */
    function restrictRegistryUpdate(bool _onlyOwnerCanUpdateRegistry) public ownerOnly {
        // change the permission to update the contract-registry
        onlyOwnerCanUpdateRegistry = _onlyOwnerCanUpdateRegistry;
    }

    /**
     * @dev returns the address associated with the given contract name
     *
     * @param _contractName    contract name
     *
     * @return contract address
     */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: solidity/contracts/converter/ConverterUpgrader.sol


pragma solidity 0.6.12;

interface ILegacyConverterVersion45 is IConverter {
    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function withdrawETH(address payable _to) external;
}

/**
 * @dev This contract contract allows upgrading an older converter contract (0.4 and up)
 * to the latest version.
 * To begin the upgrade process, simply execute the 'upgrade' function.
 * At the end of the process, the ownership of the newly upgraded converter will be transferred
 * back to the original owner and the original owner will need to execute the 'acceptOwnership' function.
 *
 * The address of the new converter is available in the ConverterUpgrade event.
 *
 * Note that for older converters that don't yet have the 'upgrade' function, ownership should first
 * be transferred manually to the ConverterUpgrader contract using the 'transferOwnership' function
 * and then the upgrader 'upgrade' function should be executed directly.
 */
contract ConverterUpgrader is IConverterUpgrader, ContractRegistryClient {
    /**
     * @dev triggered when the contract accept a converter ownership
     *
     * @param _converter   converter address
     * @param _owner       new owner - local upgrader address
     */
    event ConverterOwned(IConverter indexed _converter, address indexed _owner);

    /**
     * @dev triggered when the upgrading process is done
     *
     * @param _oldConverter    old converter address
     * @param _newConverter    new converter address
     */
    event ConverterUpgrade(address indexed _oldConverter, address indexed _newConverter);

    /**
     * @dev initializes a new ConverterUpgrader instance
     *
     * @param _registry    address of a contract registry contract
     */
    constructor(IContractRegistry _registry) public ContractRegistryClient(_registry) {}

    /**
     * @dev upgrades an old converter to the latest version
     * will throw if ownership wasn't transferred to the upgrader before calling this function.
     * ownership of the new converter will be transferred back to the original owner.
     * fires the ConverterUpgrade event upon success.
     * can only be called by a converter
     *
     * @param _version old converter version
     */
    function upgrade(bytes32 _version) external override {
        upgradeOld(IConverter(msg.sender), _version);
    }

    /**
     * @dev upgrades an old converter to the latest version
     * will throw if ownership wasn't transferred to the upgrader before calling this function.
     * ownership of the new converter will be transferred back to the original owner.
     * fires the ConverterUpgrade event upon success.
     * can only be called by a converter
     *
     * @param _version old converter version
     */
    function upgrade(uint16 _version) external override {
        upgrade(IConverter(msg.sender), _version);
    }

    /**
     * @dev upgrades an old converter to the latest version
     * will throw if ownership wasn't transferred to the upgrader before calling this function.
     * ownership of the new converter will be transferred back to the original owner.
     * fires the ConverterUpgrade event upon success.
     *
     * @param _converter old converter contract address
     */
    function upgradeOld(
        IConverter _converter,
        bytes32 /* _version */
    ) public {
        // the upgrader doesn't require the version for older converters
        upgrade(_converter, 0);
    }

    /**
     * @dev upgrades an old converter to the latest version
     * will throw if ownership wasn't transferred to the upgrader before calling this function.
     * ownership of the new converter will be transferred back to the original owner.
     * fires the ConverterUpgrade event upon success.
     *
     * @param _converter old converter contract address
     * @param _version old converter version
     */
    function upgrade(IConverter _converter, uint16 _version) private {
        IConverter converter = IConverter(_converter);
        address prevOwner = converter.owner();
        acceptConverterOwnership(converter);
        IConverter newConverter = createConverter(converter);
        copyReserves(converter, newConverter);
        copyConversionFee(converter, newConverter);
        transferReserveBalances(converter, newConverter, _version);
        IConverterAnchor anchor = converter.token();

        if (anchor.owner() == address(converter)) {
            converter.transferTokenOwnership(address(newConverter));
            newConverter.acceptAnchorOwnership();
        }

        converter.transferOwnership(prevOwner);
        newConverter.transferOwnership(prevOwner);

        newConverter.onUpgradeComplete();

        emit ConverterUpgrade(address(converter), address(newConverter));
    }

    /**
     * @dev the first step when upgrading a converter is to transfer the ownership to the local contract.
     * the upgrader contract then needs to accept the ownership transfer before initiating
     * the upgrade process.
     * fires the ConverterOwned event upon success
     *
     * @param _oldConverter       converter to accept ownership of
     */
    function acceptConverterOwnership(IConverter _oldConverter) private {
        _oldConverter.acceptOwnership();
        emit ConverterOwned(_oldConverter, address(this));
    }

    /**
     * @dev creates a new converter with same basic data as the original old converter
     * the newly created converter will have no reserves at this step.
     *
     * @param _oldConverter    old converter contract address
     *
     * @return the new converter  new converter contract address
     */
    function createConverter(IConverter _oldConverter) private returns (IConverter) {
        IConverterAnchor anchor = _oldConverter.token();
        uint32 maxConversionFee = _oldConverter.maxConversionFee();
        uint16 reserveTokenCount = _oldConverter.connectorTokenCount();

        // determine new converter type
        uint16 newType = 0;
        // new converter - get the type from the converter itself
        if (isV28OrHigherConverter(_oldConverter)) {
            newType = _oldConverter.converterType();
        } else if (reserveTokenCount > 1) {
            // old converter - if it has 1 reserve token, the type is a liquid token, otherwise the type liquidity pool
            newType = 1;
        }

        if (newType == 1 && reserveTokenCount == 2) {
            (, uint32 weight0, , , ) = _oldConverter.connectors(_oldConverter.connectorTokens(0));
            (, uint32 weight1, , , ) = _oldConverter.connectors(_oldConverter.connectorTokens(1));
            if (weight0 == PPM_RESOLUTION / 2 && weight1 == PPM_RESOLUTION / 2) {
                newType = 3;
            }
        }

        IConverterFactory converterFactory = IConverterFactory(addressOf(CONVERTER_FACTORY));
        IConverter converter = converterFactory.createConverter(newType, anchor, registry, maxConversionFee);

        converter.acceptOwnership();
        return converter;
    }

    /**
     * @dev copies the reserves from the old converter to the new one.
     * note that this will not work for an unlimited number of reserves due to block gas limit constraints.
     *
     * @param _oldConverter    old converter contract address
     * @param _newConverter    new converter contract address
     */
    function copyReserves(IConverter _oldConverter, IConverter _newConverter) private {
        uint16 reserveTokenCount = _oldConverter.connectorTokenCount();

        for (uint16 i = 0; i < reserveTokenCount; i++) {
            IERC20 reserveAddress = _oldConverter.connectorTokens(i);
            (, uint32 weight, , , ) = _oldConverter.connectors(reserveAddress);

            _newConverter.addReserve(reserveAddress, weight);
        }
    }

    /**
     * @dev copies the conversion fee from the old converter to the new one
     *
     * @param _oldConverter    old converter contract address
     * @param _newConverter    new converter contract address
     */
    function copyConversionFee(IConverter _oldConverter, IConverter _newConverter) private {
        uint32 conversionFee = _oldConverter.conversionFee();
        _newConverter.setConversionFee(conversionFee);
    }

    /**
     * @dev transfers the balance of each reserve in the old converter to the new one.
     * note that the function assumes that the new converter already has the exact same number of reserves
     * also, this will not work for an unlimited number of reserves due to block gas limit constraints.
     *
     * @param _oldConverter    old converter contract address
     * @param _newConverter    new converter contract address
     * @param _version old converter version
     */
    function transferReserveBalances(
        IConverter _oldConverter,
        IConverter _newConverter,
        uint16 _version
    ) private {
        if (_version <= 45) {
            transferReserveBalancesVersion45(ILegacyConverterVersion45(address(_oldConverter)), _newConverter);

            return;
        }

        _oldConverter.transferReservesOnUpgrade(address(_newConverter));
    }

    /**
     * @dev transfers the balance of each reserve in the old converter to the new one.
     * note that the function assumes that the new converter already has the exact same number of reserves
     * also, this will not work for an unlimited number of reserves due to block gas limit constraints.
     *
     * @param _oldConverter old converter contract address
     * @param _newConverter new converter contract address
     */
    function transferReserveBalancesVersion45(ILegacyConverterVersion45 _oldConverter, IConverter _newConverter)
        private
    {
        uint256 reserveBalance;
        uint16 reserveTokenCount = _oldConverter.connectorTokenCount();

        for (uint16 i = 0; i < reserveTokenCount; i++) {
            IERC20 reserveAddress = _oldConverter.connectorTokens(i);
            // Ether reserve
            if (reserveAddress == NATIVE_TOKEN_ADDRESS) {
                if (address(_oldConverter).balance > 0) {
                    _oldConverter.withdrawETH(address(_newConverter));
                }
            }
            // ERC20 reserve token
            else {
                IERC20 connector = reserveAddress;
                reserveBalance = connector.balanceOf(address(_oldConverter));
                if (reserveBalance > 0) {
                    _oldConverter.withdrawTokens(connector, address(_newConverter), reserveBalance);
                }
            }
        }
    }

    bytes4 private constant IS_V28_OR_HIGHER_FUNC_SELECTOR = bytes4(keccak256("isV28OrHigher()"));

    // using a static call to identify converter version
    // can't rely on the version number since the function had a different signature in older converters
    function isV28OrHigherConverter(IConverter _converter) internal view returns (bool) {
        bytes memory data = abi.encodeWithSelector(IS_V28_OR_HIGHER_FUNC_SELECTOR);
        (bool success, bytes memory returnData) = address(_converter).staticcall{ gas: 4000 }(data);

        if (success && returnData.length == 32) {
            return abi.decode(returnData, (bool));
        }

        return false;
    }
}