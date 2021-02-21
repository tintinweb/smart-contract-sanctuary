// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../interfaces/IdentifierWhitelistInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Stores a whitelist of supported identifiers that the oracle can provide prices for.
 */
contract IdentifierWhitelist is IdentifierWhitelistInterface, Ownable {
    /****************************************
     *     INTERNAL VARIABLES AND STORAGE   *
     ****************************************/

    mapping(bytes32 => bool) private supportedIdentifiers;

    /****************************************
     *                EVENTS                *
     ****************************************/

    event SupportedIdentifierAdded(bytes32 indexed identifier);
    event SupportedIdentifierRemoved(bytes32 indexed identifier);

    /****************************************
     *    ADMIN STATE MODIFYING FUNCTIONS   *
     ****************************************/

    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier unique UTF-8 representation for the feed being added. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external override onlyOwner {
        if (!supportedIdentifiers[identifier]) {
            supportedIdentifiers[identifier] = true;
            emit SupportedIdentifierAdded(identifier);
        }
    }

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier unique UTF-8 representation for the feed being removed. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external override onlyOwner {
        if (supportedIdentifiers[identifier]) {
            supportedIdentifiers[identifier] = false;
            emit SupportedIdentifierRemoved(identifier);
        }
    }

    /****************************************
     *     WHITELIST GETTERS FUNCTIONS      *
     ****************************************/

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier unique UTF-8 representation for the feed being queried. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view override returns (bool) {
        return supportedIdentifiers[identifier];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

pragma solidity ^0.6.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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