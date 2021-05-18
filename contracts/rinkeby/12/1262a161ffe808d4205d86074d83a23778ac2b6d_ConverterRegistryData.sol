/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-07
*/

// File: solidity\contracts\utility\interfaces\IOwned.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
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

// File: solidity\contracts\utility\Owned.sol


pragma solidity 0.6.12;


/**
  * @dev Provides support and utilities for contract ownership
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
    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity\contracts\utility\Utils.sol


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

// File: solidity\contracts\utility\interfaces\IContractRegistry.sol


pragma solidity 0.6.12;

/*
    Contract Registry interface
*/
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

// File: solidity\contracts\utility\ContractRegistryClient.sol


pragma solidity 0.6.12;




/**
  * @dev Base contract for ContractRegistry clients
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
    bytes32 internal constant CHAINLINK_ORACLE_WHITELIST = "ChainlinkOracleWhitelist";

    IContractRegistry public registry;      // address of the current contract-registry
    IContractRegistry public prevRegistry;  // address of the previous contract-registry
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

// File: solidity\contracts\converter\interfaces\IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {
}

// File: solidity\contracts\token\interfaces\IERC20Token.sol


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
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity\contracts\converter\interfaces\IConverterRegistryData.sol


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
    function getConvertibleTokenSmartToken(IERC20Token _convertibleToken, uint256 _index) external view returns (IConverterAnchor);
    function isConvertibleTokenSmartToken(IERC20Token _convertibleToken, address _value) external view returns (bool);
}

// File: solidity\contracts\converter\ConverterRegistryData.sol


pragma solidity 0.6.12;



/**
  * @dev The ConverterRegistryData contract is an integral part of the converter registry
  * as it serves as the database contract that holds all registry data.
  *
  * The registry is separated into two different contracts for upgradability - the data contract
  * is harder to upgrade as it requires migrating all registry data into a new contract, while
  * the registry contract itself can be easily upgraded.
  *
  * For that same reason, the data contract is simple and contains no logic beyond the basic data
  * access utilities that it exposes.
*/
contract ConverterRegistryData is IConverterRegistryData, ContractRegistryClient {
    struct Item {
        bool valid;
        uint256 index;
    }

    struct Items {
        address[] array;
        mapping(address => Item) table;
    }

    struct List {
        uint256 index;
        Items items;
    }

    struct Lists {
        address[] array;
        mapping(address => List) table;
    }

    Items private anchors;
    Items private liquidityPools;
    Lists private convertibleTokens;

    /**
      * @dev initializes a new ConverterRegistryData instance
      *
      * @param _registry address of a contract registry contract
    */
    constructor(IContractRegistry _registry) ContractRegistryClient(_registry) public {
    }

    /**
      * @dev adds an anchor
      *
      * @param _anchor anchor
    */
    function addSmartToken(IConverterAnchor _anchor) external override only(CONVERTER_REGISTRY) {
        addItem(anchors, address(_anchor));
    }

    /**
      * @dev removes an anchor
      *
      * @param _anchor anchor
    */
    function removeSmartToken(IConverterAnchor _anchor) external override only(CONVERTER_REGISTRY) {
        removeItem(anchors, address(_anchor));
    }

    /**
      * @dev adds a liquidity pool
      *
      * @param _liquidityPoolAnchor liquidity pool
    */
    function addLiquidityPool(IConverterAnchor _liquidityPoolAnchor) external override only(CONVERTER_REGISTRY) {
        addItem(liquidityPools, address(_liquidityPoolAnchor));
    }

    /**
      * @dev removes a liquidity pool
      *
      * @param _liquidityPoolAnchor liquidity pool
    */
    function removeLiquidityPool(IConverterAnchor _liquidityPoolAnchor) external override only(CONVERTER_REGISTRY) {
        removeItem(liquidityPools, address(_liquidityPoolAnchor));
    }

    /**
      * @dev adds a convertible token
      *
      * @param _convertibleToken    convertible token
      * @param _anchor              associated anchor
    */
    function addConvertibleToken(IERC20Token _convertibleToken, IConverterAnchor _anchor) external override only(CONVERTER_REGISTRY) {
        List storage list = convertibleTokens.table[address(_convertibleToken)];
        if (list.items.array.length == 0) {
            list.index = convertibleTokens.array.length;
            convertibleTokens.array.push(address(_convertibleToken));
        }
        addItem(list.items, address(_anchor));
    }

    /**
      * @dev removes a convertible token
      *
      * @param _convertibleToken    convertible token
      * @param _anchor              associated anchor
    */
    function removeConvertibleToken(IERC20Token _convertibleToken, IConverterAnchor _anchor) external override only(CONVERTER_REGISTRY) {
        List storage list = convertibleTokens.table[address(_convertibleToken)];
        removeItem(list.items, address(_anchor));
        if (list.items.array.length == 0) {
            address lastConvertibleToken = convertibleTokens.array[convertibleTokens.array.length - 1];
            convertibleTokens.table[lastConvertibleToken].index = list.index;
            convertibleTokens.array[list.index] = lastConvertibleToken;
            convertibleTokens.array.pop();
            delete convertibleTokens.table[address(_convertibleToken)];
        }
    }

    /**
      * @dev returns the number of anchors
      *
      * @return number of anchors
    */
    function getSmartTokenCount() external view override returns (uint256) {
        return anchors.array.length;
    }

    /**
      * @dev returns the list of anchors
      *
      * @return list of anchors
    */
    function getSmartTokens() external view override returns (address[] memory) {
        return anchors.array;
    }

    /**
      * @dev returns the anchor at a given index
      *
      * @param _index index
      * @return anchor at the given index
    */
    function getSmartToken(uint256 _index) external view override returns (IConverterAnchor) {
        return IConverterAnchor(anchors.array[_index]);
    }

    /**
      * @dev checks whether or not a given value is an anchor
      *
      * @param _value value
      * @return true if the given value is an anchor, false if not
    */
    function isSmartToken(address _value) external view override returns (bool) {
        return anchors.table[_value].valid;
    }

    /**
      * @dev returns the number of liquidity pools
      *
      * @return number of liquidity pools
    */
    function getLiquidityPoolCount() external view override returns (uint256) {
        return liquidityPools.array.length;
    }

    /**
      * @dev returns the list of liquidity pools
      *
      * @return list of liquidity pools
    */
    function getLiquidityPools() external view override returns (address[] memory) {
        return liquidityPools.array;
    }

    /**
      * @dev returns the liquidity pool at a given index
      *
      * @param _index index
      * @return liquidity pool at the given index
    */
    function getLiquidityPool(uint256 _index) external view override returns (IConverterAnchor) {
        return IConverterAnchor(liquidityPools.array[_index]);
    }

    /**
      * @dev checks whether or not a given value is a liquidity pool
      *
      * @param _value value
      * @return true if the given value is a liquidity pool, false if not
    */
    function isLiquidityPool(address _value) external view override returns (bool) {
        return liquidityPools.table[_value].valid;
    }

    /**
      * @dev returns the number of convertible tokens
      *
      * @return number of convertible tokens
    */
    function getConvertibleTokenCount() external view override returns (uint256) {
        return convertibleTokens.array.length;
    }

    /**
      * @dev returns the list of convertible tokens
      *
      * @return list of convertible tokens
    */
    function getConvertibleTokens() external view override returns (address[] memory) {
        return convertibleTokens.array;
    }

    /**
      * @dev returns the convertible token at a given index
      *
      * @param _index index
      * @return convertible token at the given index
    */
    function getConvertibleToken(uint256 _index) external view override returns (IERC20Token) {
        return IERC20Token(convertibleTokens.array[_index]);
    }

    /**
      * @dev checks whether or not a given value is a convertible token
      *
      * @param _value value
      * @return true if the given value is a convertible token, false if not
    */
    function isConvertibleToken(address _value) external view override returns (bool) {
        return convertibleTokens.table[_value].items.array.length > 0;
    }

    /**
      * @dev returns the number of anchors associated with a given convertible token
      *
      * @param _convertibleToken convertible token
      * @return number of anchors
    */
    function getConvertibleTokenSmartTokenCount(IERC20Token _convertibleToken) external view override returns (uint256) {
        return convertibleTokens.table[address(_convertibleToken)].items.array.length;
    }

    /**
      * @dev returns the list of anchors associated with a given convertible token
      *
      * @param _convertibleToken convertible token
      * @return list of anchors
    */
    function getConvertibleTokenSmartTokens(IERC20Token _convertibleToken) external view override returns (address[] memory) {
        return convertibleTokens.table[address(_convertibleToken)].items.array;
    }

    /**
      * @dev returns the anchor associated with a given convertible token at a given index
      *
      * @param _index index
      * @return anchor
    */
    function getConvertibleTokenSmartToken(IERC20Token _convertibleToken, uint256 _index) external view override returns (IConverterAnchor) {
        return IConverterAnchor(convertibleTokens.table[address(_convertibleToken)].items.array[_index]);
    }

    /**
      * @dev checks whether or not a given value is an anchor of a given convertible token
      *
      * @param _convertibleToken convertible token
      * @param _value value
      * @return true if the given value is an anchor of the given convertible token, false it not
    */
    function isConvertibleTokenSmartToken(IERC20Token _convertibleToken, address _value) external view override returns (bool) {
        return convertibleTokens.table[address(_convertibleToken)].items.table[_value].valid;
    }

    /**
      * @dev adds an item to a list of items
      *
      * @param _items list of items
      * @param _value item's value
    */
    function addItem(Items storage _items, address _value) internal validAddress(_value) {
        Item storage item = _items.table[_value];
        require(!item.valid, "ERR_INVALID_ITEM");

        item.index = _items.array.length;
        _items.array.push(_value);
        item.valid = true;
    }

    /**
      * @dev removes an item from a list of items
      *
      * @param _items list of items
      * @param _value item's value
    */
    function removeItem(Items storage _items, address _value) internal validAddress(_value) {
        Item storage item = _items.table[_value];
        require(item.valid, "ERR_INVALID_ITEM");

        address lastValue = _items.array[_items.array.length - 1];
        _items.table[lastValue].index = item.index;
        _items.array[item.index] = lastValue;
        _items.array.pop();
        delete _items.table[_value];
    }
}