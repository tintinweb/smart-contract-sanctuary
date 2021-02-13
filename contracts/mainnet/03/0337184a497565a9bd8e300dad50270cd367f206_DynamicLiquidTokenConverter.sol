/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: Bprotocol Foundation (Bancor) LICENSE

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

// File: solidity/contracts/token/interfaces/IERC20Token.sol

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

// File: solidity/contracts/utility/interfaces/IWhitelist.sol

pragma solidity 0.6.12;

/*
    Whitelist interface
*/
interface IWhitelist {
    function isWhitelisted(address _address) external view returns (bool);
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

    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) external view returns (uint256, uint256);
    function convert(IERC20Token _sourceToken,
                     IERC20Token _targetToken,
                     uint256 _amount,
                     address _trader,
                     address payable _beneficiary) external payable returns (uint256);

    function conversionWhitelist() external view returns (IWhitelist);
    function conversionFee() external view returns (uint32);
    function maxConversionFee() external view returns (uint32);
    function reserveBalance(IERC20Token _reserveToken) external view returns (uint256);
    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;
    function acceptAnchorOwnership() external;
    function setConversionFee(uint32 _conversionFee) external;
    function setConversionWhitelist(IWhitelist _whitelist) external;
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
    function withdrawETH(address payable _to) external;
    function addReserve(IERC20Token _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);
    function transferTokenOwnership(address _newOwner) external;
    function acceptTokenOwnership() external;
    function connectors(IERC20Token _address) external view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) external view returns (uint256);
    function connectorTokens(uint256 _index) external view returns (IERC20Token);
    function connectorTokenCount() external view returns (uint16);
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

// File: solidity/contracts/converter/interfaces/IBancorFormula.sol

pragma solidity 0.6.12;

/*
    Bancor Formula interface
*/
interface IBancorFormula {
    function purchaseTargetAmount(uint256 _supply,
                                  uint256 _reserveBalance,
                                  uint32 _reserveWeight,
                                  uint256 _amount)
                                  external view returns (uint256);

    function saleTargetAmount(uint256 _supply,
                              uint256 _reserveBalance,
                              uint32 _reserveWeight,
                              uint256 _amount)
                              external view returns (uint256);

    function crossReserveTargetAmount(uint256 _sourceReserveBalance,
                                      uint32 _sourceReserveWeight,
                                      uint256 _targetReserveBalance,
                                      uint32 _targetReserveWeight,
                                      uint256 _amount)
                                      external view returns (uint256);

    function fundCost(uint256 _supply,
                      uint256 _reserveBalance,
                      uint32 _reserveRatio,
                      uint256 _amount)
                      external view returns (uint256);

    function fundSupplyAmount(uint256 _supply,
                              uint256 _reserveBalance,
                              uint32 _reserveRatio,
                              uint256 _amount)
                              external view returns (uint256);

    function liquidateReserveAmount(uint256 _supply,
                                    uint256 _reserveBalance,
                                    uint32 _reserveRatio,
                                    uint256 _amount)
                                    external view returns (uint256);

    function balancedWeights(uint256 _primaryReserveStakedBalance,
                             uint256 _primaryReserveBalance,
                             uint256 _secondaryReserveBalance,
                             uint256 _reserveRateNumerator,
                             uint256 _reserveRateDenominator)
                             external view returns (uint32, uint32);
}

// File: solidity/contracts/utility/Owned.sol

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

// File: solidity/contracts/utility/ReentrancyGuard.sol

pragma solidity 0.6.12;

/**
  * @dev ReentrancyGuard
  *
  * The contract provides protection against re-entrancy - calling a function (directly or
  * indirectly) from within itself.
*/
contract ReentrancyGuard {
    // true while protected code is being executed, false otherwise
    bool private locked = false;

    /**
      * @dev ensures instantiation only by sub-contracts
    */
    constructor() internal {}

    // protects a function against reentrancy attacks
    modifier protected() {
        _protected();
        locked = true;
        _;
        locked = false;
    }

    // error message binary size optimization
    function _protected() internal view {
        require(!locked, "ERR_REENTRANCY");
    }
}

// File: solidity/contracts/utility/SafeMath.sol

pragma solidity 0.6.12;

/**
  * @dev Library for basic math operations with overflow/underflow protection
*/
library SafeMath {
    /**
      * @dev returns the sum of _x and _y, reverts if the calculation overflows
      *
      * @param _x   value 1
      * @param _y   value 2
      *
      * @return sum
    */
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev returns the difference of _x minus _y, reverts if the calculation underflows
      *
      * @param _x   minuend
      * @param _y   subtrahend
      *
      * @return difference
    */
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y, "ERR_UNDERFLOW");
        return _x - _y;
    }

    /**
      * @dev returns the product of multiplying _x by _y, reverts if the calculation overflows
      *
      * @param _x   factor 1
      * @param _y   factor 2
      *
      * @return product
    */
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // gas optimization
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      *
      * @param _x   dividend
      * @param _y   divisor
      *
      * @return quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
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
    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_APPROVE_FAILED');
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
    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FAILED');
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
    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FROM_FAILED');
    }
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol

pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
}

// File: solidity/contracts/utility/TokenHolder.sol

pragma solidity 0.6.12;





/**
  * @dev We consider every contract to be a 'token holder' since it's currently not possible
  * for a contract to deny receiving tokens.
  *
  * The TokenHolder's contract sole purpose is to provide a safety mechanism that allows
  * the owner to send tokens that were sent to the contract by mistake back to their sender.
  *
  * Note that we use the non standard ERC-20 interface which has no return value for transfer
  * in order to support both non standard as well as standard token contracts.
  * see https://github.com/ethereum/solidity/issues/4116
*/
contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {
    /**
      * @dev withdraws tokens held by the contract and sends them to an account
      * can only be called by the owner
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        virtual
        override
        ownerOnly
        validAddress(address(_token))
        validAddress(_to)
        notThis(_to)
    {
        safeTransfer(_token, _to, _amount);
    }
}

// File: solidity/contracts/token/interfaces/IEtherToken.sol

pragma solidity 0.6.12;


/*
    Ether Token interface
*/
interface IEtherToken is IERC20Token {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
    function depositTo(address _to) external payable;
    function withdrawTo(address payable _to, uint256 _amount) external;
}

// File: solidity/contracts/bancorx/interfaces/IBancorX.sol

pragma solidity 0.6.12;


interface IBancorX {
    function token() external view returns (IERC20Token);
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) external;
    function getXTransferAmount(uint256 _xTransferId, address _for) external view returns (uint256);
}

// File: solidity/contracts/converter/ConverterBase.sol

pragma solidity 0.6.12;











/**
  * @dev ConverterBase
  *
  * The converter contains the main logic for conversions between different ERC20 tokens.
  *
  * It is also the upgradable part of the mechanism (note that upgrades are opt-in).
  *
  * The anchor must be set on construction and cannot be changed afterwards.
  * Wrappers are provided for some of the anchor's functions, for easier access.
  *
  * Once the converter accepts ownership of the anchor, it becomes the anchor's sole controller
  * and can execute any of its functions.
  *
  * To upgrade the converter, anchor ownership must be transferred to a new converter, along with
  * any relevant data.
  *
  * Note that the converter can transfer anchor ownership to a new converter that
  * doesn't allow upgrades anymore, for finalizing the relationship between the converter
  * and the anchor.
  *
  * Converter types (defined as uint16 type) -
  * 0 = liquid token converter
  * 1 = liquidity pool v1 converter
  * 2 = liquidity pool v2 converter
  *
  * Note that converters don't currently support tokens with transfer fees.
*/
abstract contract ConverterBase is IConverter, TokenHandler, TokenHolder, ContractRegistryClient, ReentrancyGuard {
    using SafeMath for uint256;

    uint32 internal constant PPM_RESOLUTION = 1000000;
    IERC20Token internal constant ETH_RESERVE_ADDRESS = IERC20Token(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    struct Reserve {
        uint256 balance;    // reserve balance
        uint32 weight;      // reserve weight, represented in ppm, 1-1000000
        bool deprecated1;   // deprecated
        bool deprecated2;   // deprecated
        bool isSet;         // true if the reserve is valid, false otherwise
    }

    /**
      * @dev version number
    */
    uint16 public constant version = 40;

    IConverterAnchor public override anchor;            // converter anchor contract
    IWhitelist public override conversionWhitelist;     // whitelist contract with list of addresses that are allowed to use the converter
    IERC20Token[] public reserveTokens;                 // ERC20 standard token addresses (prior version 17, use 'connectorTokens' instead)
    mapping (IERC20Token => Reserve) public reserves;   // reserve token addresses -> reserve data (prior version 17, use 'connectors' instead)
    uint32 public reserveRatio = 0;                     // ratio between the reserves and the market cap, equal to the total reserve weights
    uint32 public override maxConversionFee = 0;        // maximum conversion fee for the lifetime of the contract,
                                                        // represented in ppm, 0...1000000 (0 = no fee, 100 = 0.01%, 1000000 = 100%)
    uint32 public override conversionFee = 0;           // current conversion fee, represented in ppm, 0...maxConversionFee
    bool public constant conversionsEnabled = true;     // deprecated, backward compatibility

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
      * @param _amount          amount converted, in the source token
      * @param _return          amount returned, minus conversion fee
      * @param _conversionFee   conversion fee
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
      * note that prior to version 28, you should use the 'PriceDataUpdate' event instead
      *
      * @param  _token1 address of the first token
      * @param  _token2 address of the second token
      * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
      * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
    */
    event TokenRateUpdate(
        IERC20Token indexed _token1,
        IERC20Token indexed _token2,
        uint256 _rateN,
        uint256 _rateD
    );

    /**
      * @dev triggered when the conversion fee is updated
      *
      * @param  _prevFee    previous fee percentage, represented in ppm
      * @param  _newFee     new fee percentage, represented in ppm
    */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);

    /**
      * @dev used by sub-contracts to initialize a new converter
      *
      * @param  _anchor             anchor governed by the converter
      * @param  _registry           address of a contract registry contract
      * @param  _maxConversionFee   maximum conversion fee, represented in ppm
    */
    constructor(
        IConverterAnchor _anchor,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    )
        validAddress(address(_anchor))
        ContractRegistryClient(_registry)
        internal
        validConversionFee(_maxConversionFee)
    {
        anchor = _anchor;
        maxConversionFee = _maxConversionFee;
    }

    // ensures that the converter is active
    modifier active() {
        _active();
        _;
    }

    // error message binary size optimization
    function _active() internal view {
        require(isActive(), "ERR_INACTIVE");
    }

    // ensures that the converter is not active
    modifier inactive() {
        _inactive();
        _;
    }

    // error message binary size optimization
    function _inactive() internal view {
        require(!isActive(), "ERR_ACTIVE");
    }

    // validates a reserve token address - verifies that the address belongs to one of the reserve tokens
    modifier validReserve(IERC20Token _address) {
        _validReserve(_address);
        _;
    }

    // error message binary size optimization
    function _validReserve(IERC20Token _address) internal view {
        require(reserves[_address].isSet, "ERR_INVALID_RESERVE");
    }

    // validates conversion fee
    modifier validConversionFee(uint32 _conversionFee) {
        _validConversionFee(_conversionFee);
        _;
    }

    // error message binary size optimization
    function _validConversionFee(uint32 _conversionFee) internal pure {
        require(_conversionFee <= PPM_RESOLUTION, "ERR_INVALID_CONVERSION_FEE");
    }

    // validates reserve weight
    modifier validReserveWeight(uint32 _weight) {
        _validReserveWeight(_weight);
        _;
    }

    // error message binary size optimization
    function _validReserveWeight(uint32 _weight) internal pure {
        require(_weight > 0 && _weight <= PPM_RESOLUTION, "ERR_INVALID_RESERVE_WEIGHT");
    }

    // overrides interface declaration
    function converterType() public pure virtual override returns (uint16);

    // overrides interface declaration
    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256, uint256);

    /**
      * @dev deposits ether
      * can only be called if the converter has an ETH reserve
    */
    receive() external override payable {
        require(reserves[ETH_RESERVE_ADDRESS].isSet, "ERR_INVALID_RESERVE"); // require(hasETHReserve(), "ERR_INVALID_RESERVE");
        // a workaround for a problem when running solidity-coverage
        // see https://github.com/sc-forks/solidity-coverage/issues/487
    }

    /**
      * @dev withdraws ether
      * can only be called by the owner if the converter is inactive or by upgrader contract
      * can only be called after the upgrader contract has accepted the ownership of this contract
      * can only be called if the converter has an ETH reserve
      *
      * @param _to  address to send the ETH to
    */
    function withdrawETH(address payable _to)
        public
        override
        virtual
        protected
        ownerOnly
        validReserve(ETH_RESERVE_ADDRESS)
    {
        address converterUpgrader = addressOf(CONVERTER_UPGRADER);

        // verify that the converter is inactive or that the owner is the upgrader contract
        require(!isActive() || owner == converterUpgrader, "ERR_ACCESS_DENIED");
        _to.transfer(address(this).balance);

        // sync the ETH reserve balance
        syncReserveBalance(ETH_RESERVE_ADDRESS);
    }

    /**
      * @dev checks whether or not the converter version is 28 or higher
      *
      * @return true, since the converter version is 28 or higher
    */
    function isV28OrHigher() public pure returns (bool) {
        return true;
    }

    /**
      * @dev allows the owner to update & enable the conversion whitelist contract address
      * when set, only addresses that are whitelisted are actually allowed to use the converter
      * note that the whitelist check is actually done by the BancorNetwork contract
      *
      * @param _whitelist    address of a whitelist contract
    */
    function setConversionWhitelist(IWhitelist _whitelist)
        public
        override
        ownerOnly
        notThis(address(_whitelist))
    {
        conversionWhitelist = _whitelist;
    }

    /**
      * @dev returns true if the converter is active, false otherwise
      *
      * @return true if the converter is active, false otherwise
    */
    function isActive() public view virtual override returns (bool) {
        return anchor.owner() == address(this);
    }

    /**
      * @dev transfers the anchor ownership
      * the new owner needs to accept the transfer
      * can only be called by the converter upgrder while the upgrader is the owner
      * note that prior to version 28, you should use 'transferAnchorOwnership' instead
      *
      * @param _newOwner    new token owner
    */
    function transferAnchorOwnership(address _newOwner)
        public
        virtual
        override
        ownerOnly
        only(CONVERTER_UPGRADER)
    {
        anchor.transferOwnership(_newOwner);
    }

    /**
      * @dev accepts ownership of the anchor after an ownership transfer
      * most converters are also activated as soon as they accept the anchor ownership
      * can only be called by the contract owner
      * note that prior to version 28, you should use 'acceptTokenOwnership' instead
    */
    function acceptAnchorOwnership() public virtual override ownerOnly {
        // verify the the converter has at least one reserve
        require(reserveTokenCount() > 0, "ERR_INVALID_RESERVE_COUNT");
        anchor.acceptOwnership();
        syncReserveBalances();
    }

    /**
      * @dev updates the current conversion fee
      * can only be called by the contract owner
      *
      * @param _conversionFee new conversion fee, represented in ppm
    */
    function setConversionFee(uint32 _conversionFee) public override ownerOnly {
        require(_conversionFee <= maxConversionFee, "ERR_INVALID_CONVERSION_FEE");
        emit ConversionFeeUpdate(conversionFee, _conversionFee);
        conversionFee = _conversionFee;
    }

    /**
      * @dev withdraws tokens held by the converter and sends them to an account
      * can only be called by the owner
      * note that reserve tokens can only be withdrawn by the owner while the converter is inactive
      * unless the owner is the converter upgrader contract
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        virtual
        override(IConverter, TokenHolder)
        protected
        ownerOnly
    {
        address converterUpgrader = addressOf(CONVERTER_UPGRADER);

        // if the token is not a reserve token, allow withdrawal
        // otherwise verify that the converter is inactive or that the owner is the upgrader contract
        require(!reserves[_token].isSet || !isActive() || owner == converterUpgrader, "ERR_ACCESS_DENIED");
        super.withdrawTokens(_token, _to, _amount);

        // if the token is a reserve token, sync the reserve balance
        if (reserves[_token].isSet)
            syncReserveBalance(_token);
    }

    /**
      * @dev upgrades the converter to the latest version
      * can only be called by the owner
      * note that the owner needs to call acceptOwnership on the new converter after the upgrade
    */
    function upgrade() public ownerOnly {
        IConverterUpgrader converterUpgrader = IConverterUpgrader(addressOf(CONVERTER_UPGRADER));

        // trigger de-activation event
        emit Activation(converterType(), anchor, false);

        transferOwnership(address(converterUpgrader));
        converterUpgrader.upgrade(version);
        acceptOwnership();
    }

    /**
      * @dev returns the number of reserve tokens defined
      * note that prior to version 17, you should use 'connectorTokenCount' instead
      *
      * @return number of reserve tokens
    */
    function reserveTokenCount() public view returns (uint16) {
        return uint16(reserveTokens.length);
    }

    /**
      * @dev defines a new reserve token for the converter
      * can only be called by the owner while the converter is inactive
      *
      * @param _token   address of the reserve token
      * @param _weight  reserve weight, represented in ppm, 1-1000000
    */
    function addReserve(IERC20Token _token, uint32 _weight)
        public
        virtual
        override
        ownerOnly
        inactive
        validAddress(address(_token))
        notThis(address(_token))
        validReserveWeight(_weight)
    {
        // validate input
        require(address(_token) != address(anchor) && !reserves[_token].isSet, "ERR_INVALID_RESERVE");
        require(_weight <= PPM_RESOLUTION - reserveRatio, "ERR_INVALID_RESERVE_WEIGHT");
        require(reserveTokenCount() < uint16(-1), "ERR_INVALID_RESERVE_COUNT");

        Reserve storage newReserve = reserves[_token];
        newReserve.balance = 0;
        newReserve.weight = _weight;
        newReserve.isSet = true;
        reserveTokens.push(_token);
        reserveRatio += _weight;
    }

    /**
      * @dev returns the reserve's weight
      * added in version 28
      *
      * @param _reserveToken    reserve token contract address
      *
      * @return reserve weight
    */
    function reserveWeight(IERC20Token _reserveToken)
        public
        view
        validReserve(_reserveToken)
        returns (uint32)
    {
        return reserves[_reserveToken].weight;
    }

    /**
      * @dev returns the reserve's balance
      * note that prior to version 17, you should use 'getConnectorBalance' instead
      *
      * @param _reserveToken    reserve token contract address
      *
      * @return reserve balance
    */
    function reserveBalance(IERC20Token _reserveToken)
        public
        override
        view
        validReserve(_reserveToken)
        returns (uint256)
    {
        return reserves[_reserveToken].balance;
    }

    /**
      * @dev checks whether or not the converter has an ETH reserve
      *
      * @return true if the converter has an ETH reserve, false otherwise
    */
    function hasETHReserve() public view returns (bool) {
        return reserves[ETH_RESERVE_ADDRESS].isSet;
    }

    /**
      * @dev converts a specific amount of source tokens to target tokens
      * can only be called by the bancor network contract
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of tokens received (in units of the target token)
    */
    function convert(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount, address _trader, address payable _beneficiary)
        public
        override
        payable
        protected
        only(BANCOR_NETWORK)
        returns (uint256)
    {
        // validate input
        require(_sourceToken != _targetToken, "ERR_SAME_SOURCE_TARGET");

        // if a whitelist is set, verify that both and trader and the beneficiary are whitelisted
        require(address(conversionWhitelist) == address(0) ||
                (conversionWhitelist.isWhitelisted(_trader) && conversionWhitelist.isWhitelisted(_beneficiary)),
                "ERR_NOT_WHITELISTED");

        return doConvert(_sourceToken, _targetToken, _amount, _trader, _beneficiary);
    }

    /**
      * @dev converts a specific amount of source tokens to target tokens
      * called by ConverterBase and allows the inherited contracts to implement custom conversion logic
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of tokens received (in units of the target token)
    */
    function doConvert(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary)
        internal
        virtual
        returns (uint256);

    /**
      * @dev returns the conversion fee for a given target amount
      *
      * @param _targetAmount  target amount
      *
      * @return conversion fee
    */
    function calculateFee(uint256 _targetAmount) internal view returns (uint256) {
        return _targetAmount.mul(conversionFee).div(PPM_RESOLUTION);
    }

    /**
      * @dev syncs the stored reserve balance for a given reserve with the real reserve balance
      *
      * @param _reserveToken    address of the reserve token
    */
    function syncReserveBalance(IERC20Token _reserveToken) internal validReserve(_reserveToken) {
        if (_reserveToken == ETH_RESERVE_ADDRESS)
            reserves[_reserveToken].balance = address(this).balance;
        else
            reserves[_reserveToken].balance = _reserveToken.balanceOf(address(this));
    }

    /**
      * @dev syncs all stored reserve balances
    */
    function syncReserveBalances() internal {
        uint256 reserveCount = reserveTokens.length;
        for (uint256 i = 0; i < reserveCount; i++)
            syncReserveBalance(reserveTokens[i]);
    }

    /**
      * @dev helper, dispatches the Conversion event
      *
      * @param _sourceToken     source ERC20 token
      * @param _targetToken     target ERC20 token
      * @param _trader          address of the caller who executed the conversion
      * @param _amount          amount purchased/sold (in the source token)
      * @param _returnAmount    amount returned (in the target token)
    */
    function dispatchConversionEvent(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        address _trader,
        uint256 _amount,
        uint256 _returnAmount,
        uint256 _feeAmount)
        internal
    {
        // fee amount is converted to 255 bits -
        // negative amount means the fee is taken from the source token, positive amount means its taken from the target token
        // currently the fee is always taken from the target token
        // since we convert it to a signed number, we first ensure that it's capped at 255 bits to prevent overflow
        assert(_feeAmount < 2 ** 255);
        emit Conversion(_sourceToken, _targetToken, _trader, _amount, _returnAmount, int256(_feeAmount));
    }

    /**
      * @dev deprecated since version 28, backward compatibility - use only for earlier versions
    */
    function token() public view override returns (IConverterAnchor) {
        return anchor;
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function transferTokenOwnership(address _newOwner) public override ownerOnly {
        transferAnchorOwnership(_newOwner);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function acceptTokenOwnership() public override ownerOnly {
        acceptAnchorOwnership();
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function connectors(IERC20Token _address) public view override returns (uint256, uint32, bool, bool, bool) {
        Reserve memory reserve = reserves[_address];
        return(reserve.balance, reserve.weight, false, false, reserve.isSet);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function connectorTokens(uint256 _index) public view override returns (IERC20Token) {
        return ConverterBase.reserveTokens[_index];
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function connectorTokenCount() public view override returns (uint16) {
        return reserveTokenCount();
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function getConnectorBalance(IERC20Token _connectorToken) public view override returns (uint256) {
        return reserveBalance(_connectorToken);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function getReturn(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) public view returns (uint256, uint256) {
        return targetAmountAndFee(_sourceToken, _targetToken, _amount);
    }
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

// File: solidity/contracts/converter/types/liquid-token/LiquidTokenConverter.sol

pragma solidity 0.6.12;


/**
  * @dev Liquid Token Converter
  *
  * The liquid token converter is a specialized version of a converter that manages a liquid token.
  *
  * The converters govern a token with a single reserve and allow converting between the two.
  * Liquid tokens usually have fractional reserve (reserve ratio smaller than 100%).
*/
contract LiquidTokenConverter is ConverterBase {
    /**
      * @dev initializes a new LiquidTokenConverter instance
      *
      * @param  _token              liquid token governed by the converter
      * @param  _registry           address of a contract registry contract
      * @param  _maxConversionFee   maximum conversion fee, represented in ppm
    */
    constructor(
        IDSToken _token,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    )
        ConverterBase(_token, _registry, _maxConversionFee)
        public
    {
    }

    /**
      * @dev returns the converter type
      *
      * @return see the converter types in the the main contract doc
    */
    function converterType() public pure override returns (uint16) {
        return 0;
    }

    /**
      * @dev accepts ownership of the anchor after an ownership transfer
      * also activates the converter
      * can only be called by the contract owner
      * note that prior to version 28, you should use 'acceptTokenOwnership' instead
    */
    function acceptAnchorOwnership() public override ownerOnly {
        super.acceptAnchorOwnership();

        emit Activation(converterType(), anchor, true);
    }

    /**
      * @dev defines the reserve token for the converter
      * can only be called by the owner while the converter is inactive and the
      * reserve wasn't defined yet
      *
      * @param _token   address of the reserve token
      * @param _weight  reserve weight, represented in ppm, 1-1000000
    */
    function addReserve(IERC20Token _token, uint32 _weight) public override ownerOnly {
        // verify that the converter doesn't have a reserve yet
        require(reserveTokenCount() == 0, "ERR_INVALID_RESERVE_COUNT");
        super.addReserve(_token, _weight);
    }

    /**
      * @dev returns the expected target amount of converting the source token to the
      * target token along with the fee
      *
      * @param _sourceToken contract address of the source token
      * @param _targetToken contract address of the target token
      * @param _amount      amount of tokens received from the user
      *
      * @return expected target amount
      * @return expected fee
    */
    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) public view override returns (uint256, uint256) {
        if (_targetToken == IDSToken(address(anchor)) && reserves[_sourceToken].isSet)
            return purchaseTargetAmount(_amount);
        if (_sourceToken == IDSToken(address(anchor)) && reserves[_targetToken].isSet)
            return saleTargetAmount(_amount);

        // invalid input
        revert("ERR_INVALID_TOKEN");
    }

    /**
      * @dev converts between the liquid token and its reserve
      * can only be called by the bancor network contract
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of tokens received (in units of the target token)
    */
    function doConvert(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount, address _trader, address payable _beneficiary)
        internal
        override
        returns (uint256)
    {
        uint256 targetAmount;
        IERC20Token reserveToken;

        if (_targetToken == IDSToken(address(anchor)) && reserves[_sourceToken].isSet) {
            reserveToken = _sourceToken;
            targetAmount = buy(_amount, _trader, _beneficiary);
        }
        else if (_sourceToken == IDSToken(address(anchor)) && reserves[_targetToken].isSet) {
            reserveToken = _targetToken;
            targetAmount = sell(_amount, _trader, _beneficiary);
        }
        else {
            // invalid input
            revert("ERR_INVALID_TOKEN");
        }

        // dispatch rate update for the liquid token
        uint256 totalSupply = IDSToken(address(anchor)).totalSupply();
        uint32 reserveWeight = reserves[reserveToken].weight;
        emit TokenRateUpdate(IDSToken(address(anchor)), reserveToken, reserveBalance(reserveToken).mul(PPM_RESOLUTION), totalSupply.mul(reserveWeight));

        return targetAmount;
    }

    /**
      * @dev returns the expected target amount of buying with a given amount of tokens
      *
      * @param _amount  amount of reserve tokens to get the target amount for
      *
      * @return amount of liquid tokens that the user will receive
      * @return amount of liquid tokens that the user will pay as fee
    */
    function purchaseTargetAmount(uint256 _amount)
        internal
        view
        active
        returns (uint256, uint256)
    {
        uint256 totalSupply = IDSToken(address(anchor)).totalSupply();
        IERC20Token reserveToken = reserveTokens[0];

        // if the current supply is zero, then return the input amount divided by the normalized reserve-weight
        if (totalSupply == 0)
            return (_amount.mul(PPM_RESOLUTION).div(reserves[reserveToken].weight), 0);

        uint256 amount = IBancorFormula(addressOf(BANCOR_FORMULA)).purchaseTargetAmount(
            totalSupply,
            reserveBalance(reserveToken),
            reserves[reserveToken].weight,
            _amount
        );

        // return the amount minus the conversion fee and the conversion fee
        uint256 fee = calculateFee(amount);
        return (amount - fee, fee);
    }

    /**
      * @dev returns the expected target amount of selling a given amount of tokens
      *
      * @param _amount  amount of liquid tokens to get the target amount for
      *
      * @return expected reserve tokens
      * @return expected fee
    */
    function saleTargetAmount(uint256 _amount)
        internal
        view
        active
        returns (uint256, uint256)
    {
        uint256 totalSupply = IDSToken(address(anchor)).totalSupply();

        IERC20Token reserveToken = reserveTokens[0];

        // if selling the entire supply, then return the entire reserve
        if (totalSupply == _amount)
            return (reserveBalance(reserveToken), 0);

        uint256 amount = IBancorFormula(addressOf(BANCOR_FORMULA)).saleTargetAmount(
            totalSupply,
            reserveBalance(reserveToken),
            reserves[reserveToken].weight,
            _amount
        );

        // return the amount minus the conversion fee and the conversion fee
        uint256 fee = calculateFee(amount);
        return (amount - fee, fee);
    }

    /**
      * @dev buys the liquid token by depositing in its reserve
      *
      * @param _amount      amount of reserve token to buy the token for
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of liquid tokens received
    */
    function buy(uint256 _amount, address _trader, address _beneficiary) internal returns (uint256) {
        // get expected target amount and fee
        (uint256 amount, uint256 fee) = purchaseTargetAmount(_amount);

        // ensure the trade gives something in return
        require(amount != 0, "ERR_ZERO_TARGET_AMOUNT");

        IERC20Token reserveToken = reserveTokens[0];

        // ensure that the input amount was already deposited
        if (reserveToken == ETH_RESERVE_ADDRESS)
            require(msg.value == _amount, "ERR_ETH_AMOUNT_MISMATCH");
        else
            require(msg.value == 0 && reserveToken.balanceOf(address(this)).sub(reserveBalance(reserveToken)) >= _amount, "ERR_INVALID_AMOUNT");

        // sync the reserve balance
        syncReserveBalance(reserveToken);

        // issue new funds to the beneficiary in the liquid token
        IDSToken(address(anchor)).issue(_beneficiary, amount);

        // dispatch the conversion event
        dispatchConversionEvent(reserveToken, IDSToken(address(anchor)), _trader, _amount, amount, fee);

        return amount;
    }

    /**
      * @dev sells the liquid token by withdrawing from its reserve
      *
      * @param _amount      amount of liquid tokens to sell
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of reserve tokens received
    */
    function sell(uint256 _amount, address _trader, address payable _beneficiary) internal returns (uint256) {
        // ensure that the input amount was already deposited
        require(_amount <= IDSToken(address(anchor)).balanceOf(address(this)), "ERR_INVALID_AMOUNT");

        // get expected target amount and fee
        (uint256 amount, uint256 fee) = saleTargetAmount(_amount);

        // ensure the trade gives something in return
        require(amount != 0, "ERR_ZERO_TARGET_AMOUNT");

        IERC20Token reserveToken = reserveTokens[0];

        // ensure that the trade will only deplete the reserve balance if the total supply is depleted as well
        uint256 tokenSupply = IDSToken(address(anchor)).totalSupply();
        uint256 rsvBalance = reserveBalance(reserveToken);
        assert(amount < rsvBalance || (amount == rsvBalance && _amount == tokenSupply));

        // destroy the tokens from the converter balance in the liquid token
        IDSToken(address(anchor)).destroy(address(this), _amount);

        // update the reserve balance
        reserves[reserveToken].balance = reserves[reserveToken].balance.sub(amount);

        // transfer funds to the beneficiary in the reserve token
        if (reserveToken == ETH_RESERVE_ADDRESS)
            _beneficiary.transfer(amount);
        else
            safeTransfer(reserveToken, _beneficiary, amount);

        // dispatch the conversion event
        dispatchConversionEvent(IDSToken(address(anchor)), reserveToken, _trader, _amount, amount, fee);

        return amount;
    }
}

// File: solidity/contracts/converter/types/liquid-token/DynamicLiquidTokenConverter.sol

pragma solidity 0.6.12;

/**
  * @dev Liquid Token Converter
  *
  * The dynamic liquid token converter is a specialized version of a converter that manages a liquid token
  * and allows for a reduction in reserve weight within a predefined set of boundaries.
  *
  * The converters govern a token with a single reserve and allow converting between the two.
  * Liquid tokens usually have fractional reserve (reserve ratio smaller than 100%).
  * The weight can be reduced by the defined stepWeight any time the defined marketCapThreshold
  * has been reached.
*/
contract DynamicLiquidTokenConverter is LiquidTokenConverter {
    uint32 public minimumWeight = 30000;
    uint32 public stepWeight = 10000;
    uint256 public marketCapThreshold = 10000 ether;
    uint256 lastWeightAdjustmentMarketCap = 0;

    event ReserveTokenWeightUpdate(uint32 _prevWeight, uint32 _newWeight, uint256 _percentage, uint256 _balance);

    /**
      * @dev initializes a new DyamicLiquidTokenConverter instance
      *
      * @param  _token              liquid token governed by the converter
      * @param  _registry           address of a contract registry contract
      * @param  _maxConversionFee   maximum conversion fee, represented in ppm
    */
    constructor(
        IDSToken _token,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    )
        LiquidTokenConverter(_token, _registry, _maxConversionFee)
        public
    {
    }

    /**
      * @dev updates the market cap threshold
      * can only be called by the owner while inactive
      * 
      * @param _marketCapThreshold new threshold
    */
    function setMarketCapThreshold(uint256 _marketCapThreshold)
        public
        ownerOnly
        inactive
    {
        marketCapThreshold = _marketCapThreshold;
    }

    /**
      * @dev updates the current minimum weight
      * can only be called by the owner while inactive
      * 
      * @param _minimumWeight new minimum weight, represented in ppm
    */
    function setMinimumWeight(uint32 _minimumWeight)
        public
        ownerOnly
        inactive
    {
        minimumWeight = _minimumWeight;
    }

    /**
      * @dev updates the current step weight
      * can only be called by the owner while inactive
      * 
      * @param _stepWeight new step weight, represented in ppm
    */
    function setStepWeight(uint32 _stepWeight)
        public
        ownerOnly
        inactive
    {
        stepWeight = _stepWeight;
    }

    /**
      * @dev updates the token reserve weight
      * can only be called by the owner
      * 
      * @param _reserveToken    address of the reserve token
    */
    function reduceWeight(IERC20Token _reserveToken)
        public
        validReserve(_reserveToken)
        ownerOnly
    {
        uint256 currentMarketCap = getMarketCap(_reserveToken);
        require(currentMarketCap > (lastWeightAdjustmentMarketCap.add(marketCapThreshold)), "ERR_MARKET_CAP_BELOW_THRESHOLD");

        Reserve storage reserve = reserves[_reserveToken];
        uint256 newWeight = uint256(reserve.weight).sub(stepWeight);
        uint32 oldWeight = reserve.weight;
        require(newWeight >= minimumWeight, "ERR_INVALID_RESERVE_WEIGHT");

        uint256 percentage = uint256(PPM_RESOLUTION).sub(newWeight.mul(1e6).div(reserve.weight));

        uint32 weight = uint32(newWeight);
        reserve.weight = weight;
        reserveRatio = weight;

        uint256 balance = reserveBalance(_reserveToken).mul(percentage).div(1e6);

        if (_reserveToken == ETH_RESERVE_ADDRESS)
          msg.sender.transfer(balance);
        else
          safeTransfer(_reserveToken, msg.sender, balance);

        lastWeightAdjustmentMarketCap = currentMarketCap;

        syncReserveBalance(_reserveToken);

        emit ReserveTokenWeightUpdate(oldWeight, weight, percentage, reserve.balance);
    }

    function getMarketCap(IERC20Token _reserveToken)
        public
        view
        returns(uint256)
    {
        Reserve storage reserve = reserves[_reserveToken];
        return reserveBalance(_reserveToken).mul(1e6).div(reserve.weight);
    }

    /**
      * Upgrade functions. Overriden to allow upgrades by owner.
    **/

    /**
      * @dev withdraws ether
      * can only be called by the owner
      * can only be called if the converter has an ETH reserve
      *
      * @param _to  address to send the ETH to
    */
    function withdrawETH(address payable _to)
        public
        override
        protected
        ownerOnly
        validReserve(ETH_RESERVE_ADDRESS)
    {
        _to.transfer(address(this).balance);

        // sync the ETH reserve balance
        syncReserveBalance(ETH_RESERVE_ADDRESS);
    }

    /**
      * @dev transfers the anchor ownership
      * the new owner needs to accept the transfer
      *
      * @param _newOwner    new token owner
    */
    function transferAnchorOwnership(address _newOwner)
        public
        override
        ownerOnly
    {
        anchor.transferOwnership(_newOwner);
    }

    /**
      * @dev withdraws tokens held by the converter and sends them to an account
      * can only be called by the owner
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        override
        protected
        ownerOnly
    {
        TokenHolder.withdrawTokens(_token, _to, _amount);

        // if the token is a reserve token, sync the reserve balance
        if (reserves[_token].isSet)
            syncReserveBalance(_token);
    }

}