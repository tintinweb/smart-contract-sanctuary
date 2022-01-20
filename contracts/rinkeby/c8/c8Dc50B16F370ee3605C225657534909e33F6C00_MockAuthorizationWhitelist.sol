/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Whitelisted.sol



pragma solidity ^0.8.9;


/**
 * @title Whitelisted transfer restriction example
 * @dev Example of simple transfer rule, having a list
 * of whitelisted addresses manged by owner, and checking
 * that from and to address in src20 transfer are whitelisted.
 */
contract Whitelisted is Ownable {
    mapping (address => bool) private _whitelisted;

    function whitelistAccount(address account) external onlyOwner {
        _whitelisted[account] = true;
    }

    function bulkWhitelistAccount(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length ; i++) {
            address account = accounts[i];
            _whitelisted[account] = true;
        }
    }

    function unWhitelistAccount(address account) external onlyOwner {
         delete _whitelisted[account];
    }

    function bulkUnWhitelistAccount(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length ; i++) {
            address account = accounts[i];
            delete _whitelisted[account];
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisted[account];
    }
}

// File: contracts/interfaces/IAuthorizationContract.sol



pragma solidity ^0.8.9;

interface IAuthorizationContract {
    function isAccountAuthorized(
        address _account,
        uint256 id,
        bytes memory data
    ) external view returns (bool);
}

// File: contracts/MockAuthorizationContract.sol



pragma solidity ^0.8.9;



// @notice An authorization contract to fail all transfers
contract MockAuthorizationFail is IAuthorizationContract {
    function isAccountAuthorized(
        address,
        uint256,
        bytes memory
    ) external pure returns (bool) {
        return false;
    }
}

// @notice An authorization contract to pass all transfers
contract MockAuthorizationSuccess is IAuthorizationContract {
    function isAccountAuthorized(
        address,
        uint256,
        bytes memory
    ) external pure returns (bool) {
        return true;
    }
}

// @notice An authorization contract which doesn't implement IAuthorizationContract interface
contract MockAuthorizationInvalid {
    function test() public pure {}
}

// @notice A authorization contract which reverts without returning false/true.
// This is to test mustBeAuthorized function with an autorization
// contract which doesn't return false/true instead reverts
contract MockAuthorizationRevert {
    function isAccountAuthorized(
        address,
        uint256,
        bytes memory
    ) external pure returns (bool) {
        revert("Not possible");
    }
}

// @notice A authorization contract which takes transfer decisions based on
// blocked/allowed list
contract MockAuthorizationWhitelist is IAuthorizationContract, Whitelisted {
    function isAccountAuthorized(
        address account,
        uint256,
        bytes memory
    ) external view returns (bool) {
        return isWhitelisted(account);
    }
}