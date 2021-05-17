/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

// File: solidity/contracts/token/interfaces/IERC20Token.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity/contracts/utility/TokenHandler.sol


pragma solidity 0.6.12;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
     * @dev executes the ERC20 token's `approve` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _spender approved address
     * @param _value   allowance amount
     */
    function safeApprove(
        IERC20Token _token,
        address _spender,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_APPROVE_FAILED");
    }

    /**
     * @dev executes the ERC20 token's `transfer` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _to      target address
     * @param _value   transfer amount
     */
    function safeTransfer(
        IERC20Token _token,
        address _to,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_TRANSFER_FAILED");
    }

    /**
     * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
     * the main purpose of this function is to prevent a non standard ERC20 token
     * from failing silently
     *
     * @param _token   ERC20 token address
     * @param _from    source address
     * @param _to      target address
     * @param _value   transfer amount
     */
    function safeTransferFrom(
        IERC20Token _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERR_TRANSFER_FROM_FAILED");
    }
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

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: solidity/contracts/utility/interfaces/IContractRegistry.sol


pragma solidity 0.6.12;

/*
    Contract Registry interface
*/
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
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
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IERC20Token _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function withdrawTokens(
        IERC20Token _token,
        address _to,
        uint256 _amount
    ) external;

    function withdrawETH(address payable _to) external;

    function addReserve(IERC20Token _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IERC20Token _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IERC20Token _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IERC20Token);

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
        IERC20Token indexed _fromToken,
        IERC20Token indexed _toToken,
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
    event TokenRateUpdate(IERC20Token indexed _token1, IERC20Token indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

// File: solidity/contracts/converter/interfaces/ITypedConverterCustomFactory.sol


pragma solidity 0.6.12;

/*
    Typed Converter Custom Factory interface
*/
interface ITypedConverterCustomFactory {
    function converterType() external pure returns (uint16);
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

// File: solidity/contracts/converter/interfaces/IConverterRegistry.sol


pragma solidity 0.6.12;



interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);

    function getAnchors() external view returns (address[] memory);

    function getAnchor(uint256 _index) external view returns (IConverterAnchor);

    function isAnchor(address _value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 _index) external view returns (IConverterAnchor);

    function isLiquidityPool(address _value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 _index) external view returns (IERC20Token);

    function isConvertibleToken(address _value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IERC20Token _convertibleToken) external view returns (uint256);

    function getConvertibleTokenAnchors(IERC20Token _convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenAnchor(IERC20Token _convertibleToken, uint256 _index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenAnchor(IERC20Token _convertibleToken, address _value) external view returns (bool);
}

// File: solidity/contracts/converter/interfaces/IConverterRegistryData.sol


pragma solidity 0.6.12;



interface IConverterRegistryData {
    function addSmartToken(IConverterAnchor _anchor) external;

    function removeSmartToken(IConverterAnchor _anchor) external;

    function addLiquidityPool(IConverterAnchor _liquidityPoolAnchor) external;

    function removeLiquidityPool(IConverterAnchor _liquidityPoolAnchor) external;

    function addConvertibleToken(IERC20Token _convertibleToken, IConverterAnchor _anchor) external;

    function removeConvertibleToken(IERC20Token _convertibleToken, IConverterAnchor _anchor) external;

    function getSmartTokenCount() external view returns (uint256);

    function getSmartTokens() external view returns (address[] memory);

    function getSmartToken(uint256 _index) external view returns (IConverterAnchor);

    function isSmartToken(address _value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);

    function getLiquidityPools() external view returns (address[] memory);

    function getLiquidityPool(uint256 _index) external view returns (IConverterAnchor);

    function isLiquidityPool(address _value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);

    function getConvertibleTokens() external view returns (address[] memory);

    function getConvertibleToken(uint256 _index) external view returns (IERC20Token);

    function isConvertibleToken(address _value) external view returns (bool);

    function getConvertibleTokenSmartTokenCount(IERC20Token _convertibleToken) external view returns (uint256);

    function getConvertibleTokenSmartTokens(IERC20Token _convertibleToken) external view returns (address[] memory);

    function getConvertibleTokenSmartToken(IERC20Token _convertibleToken, uint256 _index)
        external
        view
        returns (IConverterAnchor);

    function isConvertibleTokenSmartToken(IERC20Token _convertibleToken, address _value) external view returns (bool);
}

// File: solidity/contracts/token/interfaces/IDSToken.sol


pragma solidity 0.6.12;




/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20Token {
    function issue(address _to, uint256 _amount) external;

    function destroy(address _from, uint256 _amount) external;
}

// File: solidity/contracts/converter/ConverterRegistry.sol


pragma solidity 0.6.12;








/**
 * @dev This contract maintains a list of all active converters in the Bancor Network.
 *
 * Since converters can be upgraded and thus their address can change, the registry actually keeps
 * converter anchors internally and not the converters themselves.
 * The active converter for each anchor can be easily accessed by querying the anchor's owner.
 *
 * The registry exposes 3 differnet lists that can be accessed and iterated, based on the use-case of the caller:
 * - Anchors - can be used to get all the latest / historical data in the network
 * - Liquidity pools - can be used to get all liquidity pools for funding, liquidation etc.
 * - Convertible tokens - can be used to get all tokens that can be converted in the network (excluding pool
 *   tokens), and for each one - all anchors that hold it in their reserves
 *
 *
 * The contract fires events whenever one of the primitives is added to or removed from the registry
 *
 * The contract is upgradable.
 */
contract ConverterRegistry is IConverterRegistry, ContractRegistryClient, TokenHandler {
    uint32 private constant PPM_RESOLUTION = 1000000;

    /**
     * @dev triggered when a converter anchor is added to the registry
     *
     * @param _anchor anchor token
     */
    event ConverterAnchorAdded(IConverterAnchor indexed _anchor);

    /**
     * @dev triggered when a converter anchor is removed from the registry
     *
     * @param _anchor anchor token
     */
    event ConverterAnchorRemoved(IConverterAnchor indexed _anchor);

    /**
     * @dev triggered when a liquidity pool is added to the registry
     *
     * @param _liquidityPool liquidity pool
     */
    event LiquidityPoolAdded(IConverterAnchor indexed _liquidityPool);

    /**
     * @dev triggered when a liquidity pool is removed from the registry
     *
     * @param _liquidityPool liquidity pool
     */
    event LiquidityPoolRemoved(IConverterAnchor indexed _liquidityPool);

    /**
     * @dev triggered when a convertible token is added to the registry
     *
     * @param _convertibleToken convertible token
     * @param _smartToken associated anchor token
     */
    event ConvertibleTokenAdded(IERC20Token indexed _convertibleToken, IConverterAnchor indexed _smartToken);

    /**
     * @dev triggered when a convertible token is removed from the registry
     *
     * @param _convertibleToken convertible token
     * @param _smartToken associated anchor token
     */
    event ConvertibleTokenRemoved(IERC20Token indexed _convertibleToken, IConverterAnchor indexed _smartToken);

    /**
     * @dev deprecated, backward compatibility, use `ConverterAnchorAdded`
     */
    event SmartTokenAdded(IConverterAnchor indexed _smartToken);

    /**
     * @dev deprecated, backward compatibility, use `ConverterAnchorRemoved`
     */
    event SmartTokenRemoved(IConverterAnchor indexed _smartToken);

    /**
     * @dev initializes a new ConverterRegistry instance
     *
     * @param _registry address of a contract registry contract
     */
    constructor(IContractRegistry _registry) public ContractRegistryClient(_registry) {}

    /**
     * @dev creates a zero supply liquid token / empty liquidity pool and adds its converter to the registry
     *
     * @param _type                converter type, see ConverterBase contract main doc
     * @param _name                token / pool name
     * @param _symbol              token / pool symbol
     * @param _decimals            token / pool decimals
     * @param _maxConversionFee    maximum conversion-fee
     * @param _reserveTokens       reserve tokens
     * @param _reserveWeights      reserve weights
     *
     * @return new converter
     */
    function newConverter(
        uint16 _type,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint32 _maxConversionFee,
        IERC20Token[] memory _reserveTokens,
        uint32[] memory _reserveWeights
    ) public virtual returns (IConverter) {
        uint256 length = _reserveTokens.length;
        require(length == _reserveWeights.length, "ERR_INVALID_RESERVES");

        // for standard pools, change type 1 to type 3
        if (_type == 1 && isStandardPool(_reserveWeights)) {
            _type = 3;
        }

        require(
            getLiquidityPoolByConfig(_type, _reserveTokens, _reserveWeights) == IConverterAnchor(0),
            "ERR_ALREADY_EXISTS"
        );

        IConverterFactory factory = IConverterFactory(addressOf(CONVERTER_FACTORY));
        IConverterAnchor anchor = IConverterAnchor(factory.createAnchor(_type, _name, _symbol, _decimals));
        IConverter converter = IConverter(factory.createConverter(_type, anchor, registry, _maxConversionFee));

        anchor.acceptOwnership();
        converter.acceptOwnership();

        for (uint256 i = 0; i < length; i++) converter.addReserve(_reserveTokens[i], _reserveWeights[i]);

        anchor.transferOwnership(address(converter));
        converter.acceptAnchorOwnership();
        converter.transferOwnership(msg.sender);

        addConverterInternal(converter);
        return converter;
    }

    /**
     * @dev adds an existing converter to the registry
     * can only be called by the owner
     *
     * @param _converter converter
     */
    function addConverter(IConverter _converter) public ownerOnly {
        require(isConverterValid(_converter), "ERR_INVALID_CONVERTER");
        addConverterInternal(_converter);
    }

    /**
     * @dev removes a converter from the registry
     * anyone can remove an existing converter from the registry, as long as the converter is invalid
     * note that the owner can also remove valid converters
     *
     * @param _converter converter
     */
    function removeConverter(IConverter _converter) public {
        require(msg.sender == owner || !isConverterValid(_converter), "ERR_ACCESS_DENIED");
        removeConverterInternal(_converter);
    }

    /**
     * @dev returns the number of converter anchors in the registry
     *
     * @return number of anchors
     */
    function getAnchorCount() public view override returns (uint256) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getSmartTokenCount();
    }

    /**
     * @dev returns the list of converter anchors in the registry
     *
     * @return list of anchors
     */
    function getAnchors() public view override returns (address[] memory) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getSmartTokens();
    }

    /**
     * @dev returns the converter anchor at a given index
     *
     * @param _index index
     * @return anchor at the given index
     */
    function getAnchor(uint256 _index) public view override returns (IConverterAnchor) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getSmartToken(_index);
    }

    /**
     * @dev checks whether or not a given value is a converter anchor
     *
     * @param _value value
     * @return true if the given value is an anchor, false if not
     */
    function isAnchor(address _value) public view override returns (bool) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).isSmartToken(_value);
    }

    /**
     * @dev returns the number of liquidity pools in the registry
     *
     * @return number of liquidity pools
     */
    function getLiquidityPoolCount() public view override returns (uint256) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getLiquidityPoolCount();
    }

    /**
     * @dev returns the list of liquidity pools in the registry
     *
     * @return list of liquidity pools
     */
    function getLiquidityPools() public view override returns (address[] memory) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getLiquidityPools();
    }

    /**
     * @dev returns the liquidity pool at a given index
     *
     * @param _index index
     * @return liquidity pool at the given index
     */
    function getLiquidityPool(uint256 _index) public view override returns (IConverterAnchor) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getLiquidityPool(_index);
    }

    /**
     * @dev checks whether or not a given value is a liquidity pool
     *
     * @param _value value
     * @return true if the given value is a liquidity pool, false if not
     */
    function isLiquidityPool(address _value) public view override returns (bool) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).isLiquidityPool(_value);
    }

    /**
     * @dev returns the number of convertible tokens in the registry
     *
     * @return number of convertible tokens
     */
    function getConvertibleTokenCount() public view override returns (uint256) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenCount();
    }

    /**
     * @dev returns the list of convertible tokens in the registry
     *
     * @return list of convertible tokens
     */
    function getConvertibleTokens() public view override returns (address[] memory) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokens();
    }

    /**
     * @dev returns the convertible token at a given index
     *
     * @param _index index
     * @return convertible token at the given index
     */
    function getConvertibleToken(uint256 _index) public view override returns (IERC20Token) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleToken(_index);
    }

    /**
     * @dev checks whether or not a given value is a convertible token
     *
     * @param _value value
     * @return true if the given value is a convertible token, false if not
     */
    function isConvertibleToken(address _value) public view override returns (bool) {
        return IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).isConvertibleToken(_value);
    }

    /**
     * @dev returns the number of converter anchors associated with a given convertible token
     *
     * @param _convertibleToken convertible token
     * @return number of anchors associated with the given convertible token
     */
    function getConvertibleTokenAnchorCount(IERC20Token _convertibleToken) public view override returns (uint256) {
        return
            IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartTokenCount(
                _convertibleToken
            );
    }

    /**
     * @dev returns the list of aoncerter anchors associated with a given convertible token
     *
     * @param _convertibleToken convertible token
     * @return list of anchors associated with the given convertible token
     */
    function getConvertibleTokenAnchors(IERC20Token _convertibleToken) public view override returns (address[] memory) {
        return
            IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartTokens(
                _convertibleToken
            );
    }

    /**
     * @dev returns the converter anchor associated with a given convertible token at a given index
     *
     * @param _index index
     * @return anchor associated with the given convertible token at the given index
     */
    function getConvertibleTokenAnchor(IERC20Token _convertibleToken, uint256 _index)
        public
        view
        override
        returns (IConverterAnchor)
    {
        return
            IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartToken(
                _convertibleToken,
                _index
            );
    }

    /**
     * @dev checks whether or not a given value is a converter anchor of a given convertible token
     *
     * @param _convertibleToken convertible token
     * @param _value value
     * @return true if the given value is an anchor of the given convertible token, false if not
     */
    function isConvertibleTokenAnchor(IERC20Token _convertibleToken, address _value)
        public
        view
        override
        returns (bool)
    {
        return
            IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA)).isConvertibleTokenSmartToken(
                _convertibleToken,
                _value
            );
    }

    /**
     * @dev returns a list of converters for a given list of anchors
     * this is a utility function that can be used to reduce the number of calls to the contract
     *
     * @param _anchors list of converter anchors
     * @return list of converters
     */
    function getConvertersByAnchors(address[] memory _anchors) public view returns (IConverter[] memory) {
        IConverter[] memory converters = new IConverter[](_anchors.length);

        for (uint256 i = 0; i < _anchors.length; i++)
            converters[i] = IConverter(payable(IConverterAnchor(_anchors[i]).owner()));

        return converters;
    }

    /**
     * @dev checks whether or not a given converter is valid
     *
     * @param _converter converter
     * @return true if the given converter is valid, false if not
     */
    function isConverterValid(IConverter _converter) public view returns (bool) {
        // verify that the converter is active
        return _converter.token().owner() == address(_converter);
    }

    /**
     * @dev checks if a liquidity pool with given configuration is already registered
     *
     * @param _converter converter with specific configuration
     * @return if a liquidity pool with the same configuration is already registered
     */
    function isSimilarLiquidityPoolRegistered(IConverter _converter) public view returns (bool) {
        uint256 reserveTokenCount = _converter.connectorTokenCount();
        IERC20Token[] memory reserveTokens = new IERC20Token[](reserveTokenCount);
        uint32[] memory reserveWeights = new uint32[](reserveTokenCount);

        // get the reserve-configuration of the converter
        for (uint256 i = 0; i < reserveTokenCount; i++) {
            IERC20Token reserveToken = _converter.connectorTokens(i);
            reserveTokens[i] = reserveToken;
            reserveWeights[i] = getReserveWeight(_converter, reserveToken);
        }

        // return if a liquidity pool with the same configuration is already registered
        return
            getLiquidityPoolByConfig(getConverterType(_converter, reserveTokenCount), reserveTokens, reserveWeights) !=
            IConverterAnchor(0);
    }

    /**
     * @dev searches for a liquidity pool with specific configuration
     *
     * @param _type            converter type, see ConverterBase contract main doc
     * @param _reserveTokens   reserve tokens
     * @param _reserveWeights  reserve weights
     * @return the liquidity pool, or zero if no such liquidity pool exists
     */
    function getLiquidityPoolByConfig(
        uint16 _type,
        IERC20Token[] memory _reserveTokens,
        uint32[] memory _reserveWeights
    ) public view returns (IConverterAnchor) {
        // verify that the input parameters represent a valid liquidity pool
        if (_reserveTokens.length == _reserveWeights.length && _reserveTokens.length > 1) {
            // get the anchors of the least frequent token (optimization)
            address[] memory convertibleTokenAnchors = getLeastFrequentTokenAnchors(_reserveTokens);
            // search for a converter with the same configuration
            for (uint256 i = 0; i < convertibleTokenAnchors.length; i++) {
                IConverterAnchor anchor = IConverterAnchor(convertibleTokenAnchors[i]);
                IConverter converter = IConverter(payable(anchor.owner()));
                if (isConverterReserveConfigEqual(converter, _type, _reserveTokens, _reserveWeights)) return anchor;
            }
        }

        return IConverterAnchor(0);
    }

    /**
     * @dev adds a converter anchor to the registry
     *
     * @param _anchor converter anchor
     */
    function addAnchor(IConverterRegistryData _converterRegistryData, IConverterAnchor _anchor) internal {
        _converterRegistryData.addSmartToken(_anchor);
        emit ConverterAnchorAdded(_anchor);
        emit SmartTokenAdded(_anchor);
    }

    /**
     * @dev removes a converter anchor from the registry
     *
     * @param _anchor converter anchor
     */
    function removeAnchor(IConverterRegistryData _converterRegistryData, IConverterAnchor _anchor) internal {
        _converterRegistryData.removeSmartToken(_anchor);
        emit ConverterAnchorRemoved(_anchor);
        emit SmartTokenRemoved(_anchor);
    }

    /**
     * @dev adds a liquidity pool to the registry
     *
     * @param _liquidityPoolAnchor liquidity pool converter anchor
     */
    function addLiquidityPool(IConverterRegistryData _converterRegistryData, IConverterAnchor _liquidityPoolAnchor)
        internal
    {
        _converterRegistryData.addLiquidityPool(_liquidityPoolAnchor);
        emit LiquidityPoolAdded(_liquidityPoolAnchor);
    }

    /**
     * @dev removes a liquidity pool from the registry
     *
     * @param _liquidityPoolAnchor liquidity pool converter anchor
     */
    function removeLiquidityPool(IConverterRegistryData _converterRegistryData, IConverterAnchor _liquidityPoolAnchor)
        internal
    {
        _converterRegistryData.removeLiquidityPool(_liquidityPoolAnchor);
        emit LiquidityPoolRemoved(_liquidityPoolAnchor);
    }

    /**
     * @dev adds a convertible token to the registry
     *
     * @param _convertibleToken    convertible token
     * @param _anchor              associated converter anchor
     */
    function addConvertibleToken(
        IConverterRegistryData _converterRegistryData,
        IERC20Token _convertibleToken,
        IConverterAnchor _anchor
    ) internal {
        _converterRegistryData.addConvertibleToken(_convertibleToken, _anchor);
        emit ConvertibleTokenAdded(_convertibleToken, _anchor);
    }

    /**
     * @dev removes a convertible token from the registry
     *
     * @param _convertibleToken    convertible token
     * @param _anchor              associated converter anchor
     */
    function removeConvertibleToken(
        IConverterRegistryData _converterRegistryData,
        IERC20Token _convertibleToken,
        IConverterAnchor _anchor
    ) internal {
        _converterRegistryData.removeConvertibleToken(_convertibleToken, _anchor);
        emit ConvertibleTokenRemoved(_convertibleToken, _anchor);
    }

    /**
     * @dev checks whether or not a given configuration depicts a standard pool
     *
     * @param _reserveWeights  reserve weights
     *
     * @return true if the given configuration depicts a standard pool, false otherwise
     */
    function isStandardPool(uint32[] memory _reserveWeights) internal view virtual returns (bool) {
        this; // silent state mutability warning without generating additional bytecode
        return
            _reserveWeights.length == 2 &&
            _reserveWeights[0] == PPM_RESOLUTION / 2 &&
            _reserveWeights[1] == PPM_RESOLUTION / 2;
    }

    function addConverterInternal(IConverter _converter) private {
        IConverterRegistryData converterRegistryData = IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA));
        IConverterAnchor anchor = IConverter(_converter).token();
        uint256 reserveTokenCount = _converter.connectorTokenCount();

        // add the converter anchor
        addAnchor(converterRegistryData, anchor);
        if (reserveTokenCount > 1) addLiquidityPool(converterRegistryData, anchor);
        else addConvertibleToken(converterRegistryData, IDSToken(address(anchor)), anchor);

        // add all reserve tokens
        for (uint256 i = 0; i < reserveTokenCount; i++)
            addConvertibleToken(converterRegistryData, _converter.connectorTokens(i), anchor);
    }

    function removeConverterInternal(IConverter _converter) private {
        IConverterRegistryData converterRegistryData = IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA));
        IConverterAnchor anchor = IConverter(_converter).token();
        uint256 reserveTokenCount = _converter.connectorTokenCount();

        // remove the converter anchor
        removeAnchor(converterRegistryData, anchor);
        if (reserveTokenCount > 1) removeLiquidityPool(converterRegistryData, anchor);
        else removeConvertibleToken(converterRegistryData, IDSToken(address(anchor)), anchor);

        // remove all reserve tokens
        for (uint256 i = 0; i < reserveTokenCount; i++)
            removeConvertibleToken(converterRegistryData, _converter.connectorTokens(i), anchor);
    }

    function getLeastFrequentTokenAnchors(IERC20Token[] memory _reserveTokens) private view returns (address[] memory) {
        IConverterRegistryData converterRegistryData = IConverterRegistryData(addressOf(CONVERTER_REGISTRY_DATA));
        uint256 minAnchorCount = converterRegistryData.getConvertibleTokenSmartTokenCount(_reserveTokens[0]);
        uint256 index = 0;

        // find the reserve token which has the smallest number of converter anchors
        for (uint256 i = 1; i < _reserveTokens.length; i++) {
            uint256 convertibleTokenAnchorCount = converterRegistryData.getConvertibleTokenSmartTokenCount(
                _reserveTokens[i]
            );
            if (minAnchorCount > convertibleTokenAnchorCount) {
                minAnchorCount = convertibleTokenAnchorCount;
                index = i;
            }
        }

        return converterRegistryData.getConvertibleTokenSmartTokens(_reserveTokens[index]);
    }

    function isConverterReserveConfigEqual(
        IConverter _converter,
        uint16 _type,
        IERC20Token[] memory _reserveTokens,
        uint32[] memory _reserveWeights
    ) private view returns (bool) {
        uint256 reserveTokenCount = _converter.connectorTokenCount();

        if (_type != getConverterType(_converter, reserveTokenCount)) return false;

        if (_reserveTokens.length != reserveTokenCount) return false;

        for (uint256 i = 0; i < _reserveTokens.length; i++) {
            if (_reserveWeights[i] != getReserveWeight(_converter, _reserveTokens[i])) return false;
        }

        return true;
    }

    // utility to get the reserve weight (including from older converters that don't support the new getReserveWeight function)
    function getReserveWeight(IConverter _converter, IERC20Token _reserveToken) private view returns (uint32) {
        (, uint32 weight, , , ) = _converter.connectors(_reserveToken);
        return weight;
    }

    bytes4 private constant CONVERTER_TYPE_FUNC_SELECTOR = bytes4(keccak256("converterType()"));

    // utility to get the converter type (including from older converters that don't support the new converterType function)
    function getConverterType(IConverter _converter, uint256 _reserveTokenCount) private view returns (uint16) {
        (bool success, bytes memory returnData) = address(_converter).staticcall(
            abi.encodeWithSelector(CONVERTER_TYPE_FUNC_SELECTOR)
        );
        if (success && returnData.length == 32) return abi.decode(returnData, (uint16));
        return _reserveTokenCount > 1 ? 1 : 0;
    }

    /**
     * @dev deprecated, backward compatibility, use `getAnchorCount`
     */
    function getSmartTokenCount() public view returns (uint256) {
        return getAnchorCount();
    }

    /**
     * @dev deprecated, backward compatibility, use `getAnchors`
     */
    function getSmartTokens() public view returns (address[] memory) {
        return getAnchors();
    }

    /**
     * @dev deprecated, backward compatibility, use `getAnchor`
     */
    function getSmartToken(uint256 _index) public view returns (IConverterAnchor) {
        return getAnchor(_index);
    }

    /**
     * @dev deprecated, backward compatibility, use `isAnchor`
     */
    function isSmartToken(address _value) public view returns (bool) {
        return isAnchor(_value);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertibleTokenAnchorCount`
     */
    function getConvertibleTokenSmartTokenCount(IERC20Token _convertibleToken) public view returns (uint256) {
        return getConvertibleTokenAnchorCount(_convertibleToken);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertibleTokenAnchors`
     */
    function getConvertibleTokenSmartTokens(IERC20Token _convertibleToken) public view returns (address[] memory) {
        return getConvertibleTokenAnchors(_convertibleToken);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertibleTokenAnchor`
     */
    function getConvertibleTokenSmartToken(IERC20Token _convertibleToken, uint256 _index)
        public
        view
        returns (IConverterAnchor)
    {
        return getConvertibleTokenAnchor(_convertibleToken, _index);
    }

    /**
     * @dev deprecated, backward compatibility, use `isConvertibleTokenAnchor`
     */
    function isConvertibleTokenSmartToken(IERC20Token _convertibleToken, address _value) public view returns (bool) {
        return isConvertibleTokenAnchor(_convertibleToken, _value);
    }

    /**
     * @dev deprecated, backward compatibility, use `getConvertersByAnchors`
     */
    function getConvertersBySmartTokens(address[] memory _smartTokens) public view returns (IConverter[] memory) {
        return getConvertersByAnchors(_smartTokens);
    }

    /**
     * @dev deprecated, backward compatibility, use `getLiquidityPoolByConfig`
     */
    function getLiquidityPoolByReserveConfig(IERC20Token[] memory _reserveTokens, uint32[] memory _reserveWeights)
        public
        view
        returns (IConverterAnchor)
    {
        return getLiquidityPoolByConfig(_reserveTokens.length > 1 ? 1 : 0, _reserveTokens, _reserveWeights);
    }
}