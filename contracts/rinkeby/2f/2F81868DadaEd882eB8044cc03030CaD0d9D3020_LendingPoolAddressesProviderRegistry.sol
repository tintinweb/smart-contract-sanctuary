// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILendingPoolAddressesProviderRegistry.sol";

/**
 * @title LendingPoolAddressesProviderRegistry contract
 * @dev Main registry of LendingPoolAddressesProvider of multiple Aave protocol's markets
 * - Used for indexing purposes of Aave protocol's markets
 * - The id assigned to a LendingPoolAddressesProvider refers to the market it is connected with,
 *   for example with `0` for the Aave main market and `1` for the next created
 * @author Aave
 **/
contract LendingPoolAddressesProviderRegistry is
    Ownable,
    ILendingPoolAddressesProviderRegistry
{
    mapping(address => uint256) private _addressesProviders;
    address[] private _addressesProvidersList;

    /**
     * @dev Returns the list of registered addresses provider
     * @return The list of addresses provider, potentially containing address(0) elements
     **/
    function getAddressesProvidersList()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory addressesProvidersList = _addressesProvidersList;

        uint256 maxLength = addressesProvidersList.length;

        address[] memory activeProviders = new address[](maxLength);

        for (uint256 i = 0; i < maxLength; i++) {
            if (_addressesProviders[addressesProvidersList[i]] > 0) {
                activeProviders[i] = addressesProvidersList[i];
            }
        }

        return activeProviders;
    }

    /**
     * @dev Registers an addresses provider
     * @param provider The address of the new LendingPoolAddressesProvider
     * @param id The id for the new LendingPoolAddressesProvider, referring to the market it belongs to
     **/
    function registerAddressesProvider(address provider, uint256 id)
        external
        override
        onlyOwner
    {
        require(id != 0, "LPAPR_INVALID_ADDRESSES_PROVIDER_ID");

        _addressesProviders[provider] = id;
        _addToAddressesProvidersList(provider);
        emit AddressesProviderRegistered(provider);
    }

    /**
     * @dev Removes a LendingPoolAddressesProvider from the list of registered addresses provider
     * @param provider The LendingPoolAddressesProvider address
     **/
    function unregisterAddressesProvider(address provider)
        external
        override
        onlyOwner
    {
        require(
            _addressesProviders[provider] > 0,
            "LPAPR_PROVIDER_NOT_REGISTERED"
        );
        _addressesProviders[provider] = 0;
        emit AddressesProviderUnregistered(provider);
    }

    /**
     * @dev Returns the id on a registered LendingPoolAddressesProvider
     * @return The id or 0 if the LendingPoolAddressesProvider is not registered
     */
    function getAddressesProviderIdByAddress(address addressesProvider)
        external
        view
        override
        returns (uint256)
    {
        return _addressesProviders[addressesProvider];
    }

    function _addToAddressesProvidersList(address provider) internal {
        uint256 providersCount = _addressesProvidersList.length;

        for (uint256 i = 0; i < providersCount; i++) {
            if (_addressesProvidersList[i] == provider) {
                return;
            }
        }

        _addressesProvidersList.push(provider);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title LendingPoolAddressesProviderRegistry contract
 * @dev Main registry of LendingPoolAddressesProvider of multiple Aave protocol's markets
 * - Used for indexing purposes of Aave protocol's markets
 * - The id assigned to a LendingPoolAddressesProvider refers to the market it is connected with,
 *   for example with `0` for the Aave main market and `1` for the next created
 * @author Aave
 **/
interface ILendingPoolAddressesProviderRegistry {
  event AddressesProviderRegistered(address indexed newAddress);
  event AddressesProviderUnregistered(address indexed newAddress);

  function getAddressesProvidersList() external view returns (address[] memory);

  function getAddressesProviderIdByAddress(address addressesProvider)
    external
    view
    returns (uint256);

  function registerAddressesProvider(address provider, uint256 id) external;

  function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}