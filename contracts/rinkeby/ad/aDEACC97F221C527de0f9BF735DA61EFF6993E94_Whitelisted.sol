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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Interface describing the required method for a whitelistable project
interface IWhitelistable {

    /// @dev Returns the number of tokens in the owner's account.
    function balanceOf(address owner) external view returns (uint256 balance);
}

/// @title Contract for Whitelisting 100% on-chain projects
/// @dev Since this contract is public, other projects may wish to rely on this list
contract Whitelisted is Ownable {

    /// Holds the list of IWhitelistable (e.g. ERC-721) projects in which ownership affords whitelisting
    IWhitelistable[] private _approvedProjects;

    /// Deploys a new Whitelisted contract with approved projects
    /// @param projects The list of contracts to add to the approved list
    constructor(address[] memory projects) {
        for (uint256 index = 0; index < projects.length; index++) {
            _approvedProjects.push(IWhitelistable(projects[index]));
        }
    }

    /// Adds additional projects to the approved list
    /// @dev Providing valid contract address that implement `balanceOf()` is the responsibility of the caller
    /// @param projects The list of contracts to add to the approved list
    function addApprovedProjects(address[] calldata projects) external onlyOwner {
        for (uint256 index = 0; index < projects.length; index++) {
            _approvedProjects.push(IWhitelistable(projects[index]));
        }
    }

    /// Returns the approved projects whitelisted by this contract
    function getApprovedProjects() external view returns (IWhitelistable[] memory) {
        return _approvedProjects;
    }

    /// Removes an approved project whitelisted by this contract
    /// @param project The address to remove from the list
    function removeApprovedProject(address project) external onlyOwner {
        uint256 length = _approvedProjects.length;
        for (uint256 index = 0; index < length; index++) {
            if (address(_approvedProjects[index]) == project) {
                if (index < length-1) {
                    _approvedProjects[index] = _approvedProjects[length-1];
                }
                _approvedProjects.pop();
                return;
            }
        }
    }

    /// Returns whether the owning address is eligible for whitelisting due to ownership in one of the approved projects
    /// @param owner The owning address to check
    /// @return True if the address at owner owns a token in one of the approved projects
    function isWhitelisted(address owner) external view returns (bool) {
        uint256 projects = _approvedProjects.length;
        for (uint256 index = 0; index < projects; index++) {
            IWhitelistable project = _approvedProjects[index];
            if (project.balanceOf(owner) > 0) {
                return true;
            }
        }
        return false;
    }
}