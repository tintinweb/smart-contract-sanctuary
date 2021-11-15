// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AllowedColorsStorage
 * @dev Color indexes need to be restricted per tribe prior to NFT deploy
 */
contract AllowedColorsStorage is Ownable {
    /// @dev Mapping if color is allowed for selected tribe
    mapping(uint256 => mapping(uint256 => bool)) private _tribeColorAllowed;

    constructor() {}

    /**
     * @notice Set allowed on a given a list of colors
     * @param tribe Tribe ID 1-10
     * @param colors List of colors to set for tribe
     * @param allowed Bool if the color list should be made allowed or not
     */
    function setAllowedColorsOnTribe(
        uint256 tribe,
        uint256[] memory colors,
        bool allowed
    ) external onlyOwner {
        require(tribe > 0 && tribe < 10, "Invalid tribe provided");
        for (uint256 i = 0; i < colors.length; i++) {
            _toggleColorAllowed(tribe, colors[i], allowed);
        }
    }

    /**
     * @notice Toggle color allowed on and off for a tribe
     * @param tribe Tribe ID
     * @param color Trait ID
     * @param allowed Bool if the color should be made allowed or not
     * @dev Defaults to false if never set
     */
    function _toggleColorAllowed(
        uint256 tribe,
        uint256 color,
        bool allowed
    ) private {
        _tribeColorAllowed[tribe][color] = allowed;
    }

    /**
     * @notice Check if color is allowed for a tribe
     * @param tribe Tribe ID
     * @param color Trait ID
     * @return True if color is allowed for tribe
     */
    function isAllowedColor(uint256 tribe, uint256 color) public view returns (bool) {
        return _tribeColorAllowed[tribe][color];
    }
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

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

