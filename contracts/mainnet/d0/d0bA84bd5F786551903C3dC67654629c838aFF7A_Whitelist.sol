// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '../interfaces/IWhitelist.sol';
import '../access/Ownable.sol';

contract Whitelist is IWhitelist, Ownable {

    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _minters;

    modifier onlyMinterOrOwner() {
        require(msg.sender == owner() || _minters[msg.sender] == true, "NotUserAllowed");
        _;
    }

    function addToWhitelist(address account) external override onlyMinterOrOwner {
        _whitelist[account] = true;
    }

    function removeFromWhitelist(address account) external override onlyMinterOrOwner {
        _whitelist[account] = false;
    }

    function isWhitelisted(address account) external view override returns (bool) {
        return _whitelist[account];
    }

    function addMinter(address account) external override onlyMinterOrOwner {
        _minters[account] = true;
    }

    function removeMinter(address account) external override onlyOwner {
        _minters[account] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IWhitelist {

    function addToWhitelist(address account) external;

    function removeFromWhitelist(address account) external;

    function isWhitelisted(address account) external view returns (bool);

    function addMinter(address account) external;

    function removeMinter(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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
abstract contract Ownable {
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

