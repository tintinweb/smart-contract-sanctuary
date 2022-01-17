// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.10;

import "../interfaces/AddressBookInterface.sol";
import "../packages/oz/Ownable.sol";

/**
 * @author Opyn Team
 * @title Whitelist Module
 * @notice The whitelist module keeps track of all valid oToken addresses, product hashes, collateral addresses, and callee addresses.
 */
contract Whitelist is Ownable {
    /// @notice AddressBook module address
    address public addressBook;
    /// @dev mapping to track whitelisted products
    mapping(bytes32 => bool) internal whitelistedProduct;
    /// @dev mapping to track whitelisted collateral
    mapping(address => bool) internal whitelistedCollateral;
    /// @dev mapping to track whitelisted oTokens
    mapping(address => bool) internal whitelistedOtoken;
    /// @dev mapping to track whitelisted callee addresses for the call action
    mapping(address => bool) internal whitelistedCallee;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) public {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event a product is whitelisted by the owner address
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by the owner address
    event CollateralWhitelisted(address indexed collateral);
    /// @notice emits an event when a collateral address is blacklist by the owner address
    event CollateralBlacklisted(address indexed collateral);
    /// @notice emits an event when an oToken is whitelisted by the OtokenFactory module
    event OtokenWhitelisted(address indexed otoken);
    /// @notice emits an event when an oToken is blacklisted by the OtokenFactory module
    event OtokenBlacklisted(address indexed otoken);
    /// @notice emits an event when a callee address is whitelisted by the owner address
    event CalleeWhitelisted(address indexed _callee);
    /// @notice emits an event when a callee address is blacklisted by the owner address
    event CalleeBlacklisted(address indexed _callee);

    /**
     * @notice check if the sender is the oTokenFactory module
     */
    modifier onlyFactory() {
        require(
            msg.sender == AddressBookInterface(addressBook).getOtokenFactory(),
            "Whitelist: Sender is not OtokenFactory"
        );

        _;
    }

    /**
     * @notice check if a product is whitelisted
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return whitelistedProduct[productHash];
    }

    /**
     * @notice check if a collateral asset is whitelisted
     * @param _collateral asset that is held as collateral against short/written options
     * @return boolean, True if the collateral is whitelisted
     */
    function isWhitelistedCollateral(address _collateral) external view returns (bool) {
        return whitelistedCollateral[_collateral];
    }

    /**
     * @notice check if an oToken is whitelisted
     * @param _otoken oToken address
     * @return boolean, True if the oToken is whitelisted
     */
    function isWhitelistedOtoken(address _otoken) external view returns (bool) {
        return whitelistedOtoken[_otoken];
    }

    /**
     * @notice check if a callee address is whitelisted for the call action
     * @param _callee callee destination address
     * @return boolean, True if the address is whitelisted
     */
    function isWhitelistedCallee(address _callee) external view returns (bool) {
        return whitelistedCallee[_callee];
    }

    /**
     * @notice allows the owner to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external onlyOwner {
        require(whitelistedCollateral[_collateral], "Whitelist: Collateral is not whitelisted");
        require(
            (_isPut && (_strike == _collateral)) || (!_isPut && (_collateral == _underlying)),
            "Whitelist: Only allow fully collateralized products"
        );

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allow the owner to blacklist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external onlyOwner {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = false;

        emit ProductBlacklisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allows the owner to whitelist a collateral address
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than Otoken as collateral. WhitelistOtoken() is used to whitelist Otoken contracts.
     * @param _collateral collateral asset address
     */
    function whitelistCollateral(address _collateral) external onlyOwner {
        whitelistedCollateral[_collateral] = true;

        emit CollateralWhitelisted(_collateral);
    }

    /**
     * @notice allows the owner to blacklist a collateral address
     * @dev can only be called from the owner address
     * @param _collateral collateral asset address
     */
    function blacklistCollateral(address _collateral) external onlyOwner {
        whitelistedCollateral[_collateral] = false;

        emit CollateralBlacklisted(_collateral);
    }

    /**
     * @notice allows the OtokenFactory module to whitelist a new option
     * @dev can only be called from the OtokenFactory address
     * @param _otokenAddress oToken
     */
    function whitelistOtoken(address _otokenAddress) external onlyFactory {
        whitelistedOtoken[_otokenAddress] = true;

        emit OtokenWhitelisted(_otokenAddress);
    }

    /**
     * @notice allows the owner to blacklist an option
     * @dev can only be called from the owner address
     * @param _otokenAddress oToken
     */
    function blacklistOtoken(address _otokenAddress) external onlyOwner {
        whitelistedOtoken[_otokenAddress] = false;

        emit OtokenBlacklisted(_otokenAddress);
    }

    /**
     * @notice allows the owner to whitelist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function whitelistCallee(address _callee) external onlyOwner {
        whitelistedCallee[_callee] = true;

        emit CalleeWhitelisted(_callee);
    }

    /**
     * @notice allows the owner to blacklist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function blacklistCallee(address _callee) external onlyOwner {
        whitelistedCallee[_callee] = false;

        emit CalleeBlacklisted(_callee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface AddressBookInterface {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity 0.6.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// openzeppelin-contracts v3.1.0

pragma solidity 0.6.10;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}