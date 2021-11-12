// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IWhitelistDistributor.sol";

contract Erc721WhitelistDistributor is IWhitelistDistributor, Ownable {
    address public immutable override token;
    // tracks users who can claim the drop
    mapping(address => bool) public minters;
    // tracks users who claimed the drop
    mapping(address => bool) public claimed;

    constructor(address token_, address[] memory accounts) {
        token = token_;
        uint arrayLength = accounts.length;
        for (uint i=0; i<arrayLength; i++) {
          minters[accounts[i]] = true;
        } 
    }

    // User functions
    // Returns true if user can claim a token
    // Returns false if user was whitelisted but has already claimed a token
    function canClaim(address user) public view override returns (bool) {
      return minters[user] && !claimed[user];
    }

    // Returns true if user has claimed a token
    // Returns false if user was never whitelisted to be able to claim
    function hasClaimed(address user) public view override returns (bool) {
        return claimed[user];
    }

    // Claim the token for msg.sender
    function claim() external override {
        require(minters[msg.sender], 'WhitelistDistributor: Not allowed to mint.');
        require(!claimed[msg.sender], 'WhitelistDistributor: Drop already claimed.');
        
        // Mark it claimed and send the token.
        claimed[msg.sender] = true;
        IMinter(token).mint(msg.sender);

        emit Claimed(msg.sender);
    }

    // Owner functions
    // Add account to the whitelist
    function whitelistAccount(address account) external override onlyOwner {
      minters[account] = true;
    }

    // Add multiple accounts to the whitelist
    function batchWhitelistAccounts(address[] calldata accounts) external override onlyOwner {
      uint arrayLength = accounts.length;
      for (uint i=0; i<arrayLength; i++) {
        minters[accounts[i]] = true;
      }
    }

    // Remove account from whitelist if not claimed already
    function blacklistAccount(address account) external override onlyOwner {
      require(!claimed[account], 'WhitelistDistributor: Drop already claimed.');
      minters[account] = false;
    }

    // Remove multiple accounts from whitelist if not already claimed
    function batchBlacklistAccounts(address[] calldata accounts) external override onlyOwner {
      uint arrayLength = accounts.length;
      for (uint i=0; i<arrayLength; i++) {
        require(!claimed[accounts[i]], 'WhitelistDistributor: Drop already claimed by one of the accounts');
        minters[accounts[i]] = false;
      }
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
 * @dev Defines minting functions 
 */
interface IMinter {
    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     */
    function mint(address to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

// Allows whitelisted addresses to claim a token
// Also exposes function from Ownable smart contract openzepplin lib
interface IWhitelistDistributor {
    // User functions
    // Returns the address of the token minted by this contract.
    function token() external view returns (address);
    // Returns true if user can claim a token
    // Returns false if user was whitelisted but has already claimed a token
    function canClaim(address user) external view returns (bool);
    // Returns true if user has claimed a token
    // Returns false if user was never whitelisted to be able to claim
    function hasClaimed(address user) external view returns (bool);
    // Claim the token for msg.sender
    function claim() external;

    // Owner functions
    // Add account to the whitelist
    function whitelistAccount(address account) external;
    // Add multiple accounts to the whitelist
    function batchWhitelistAccounts(address[] calldata accounts) external;
    // Remove account from whitelist
    function blacklistAccount(address account) external;
    // Remove multiple accounts from whitelist
    function batchBlacklistAccounts(address[] calldata accounts) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address account);
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