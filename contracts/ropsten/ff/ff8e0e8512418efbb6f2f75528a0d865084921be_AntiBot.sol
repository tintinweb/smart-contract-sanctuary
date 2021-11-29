/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: AntiBotInterface.sol


pragma solidity ^0.8.0;

interface AntiBotInterface{
    function _transfer(address sender,address recipient,uint256 amount) external returns (bool);
    function addBotAddress(address _address) external;
    function antiBot(uint256 amount) external;
}
// File: AntiBot.sol


pragma solidity ^0.8.0;



contract AntiBot is AntiBotInterface,Ownable{
    mapping(address => bool) botAddresses;
    // Anti bot-trade
    bool public antiBotEnabled = true;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime = 1629038064;
    uint256 public antiBotAmount = 1000000000000;
    /**
     * To prevent bot trading, limit the number of tokens that can be transferred.
     */
    function antiBot(uint256 amount) external override onlyOwner {
        require(amount > 0, "not accept 0 value");
        require(!antiBotEnabled);
        antiBotAmount = amount;
        antiBotTime = block.timestamp + antiBotDuration;
        antiBotEnabled = true;
    }

    function addBotAddress (address _address) external override onlyOwner {
        require(!botAddresses[_address]);
        botAddresses[_address] = true;
    }

        /**
     * Add a bot prevention feature by overriding the _transfer function.
     */
    function _transfer(address sender,address recipient,uint256 amount) external override view returns(bool) {
        recipient = address(this);
        if (
            antiBotTime > block.timestamp &&
            amount > antiBotAmount &&
            botAddresses[sender]
        ) {
            return false;
        }
        return true;
    }
    
}