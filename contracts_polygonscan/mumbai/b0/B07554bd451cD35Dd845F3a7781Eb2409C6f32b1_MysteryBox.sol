/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

// File: contracts/MysteryBox.sol

pragma solidity ^0.8.2;




contract MysteryBox is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _boxId;

    address public synTokenAddress;
    address public esynTokenAddress;

    mapping (uint256 => Box) boxes;
    mapping (uint256 => address) tokenOwners;

    event BoxCreated(uint256 boxId);
    event BoxBought(address buyer, uint256 boxId, uint256 tokenId);

    struct Box {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 synPrice;
        uint256 esyncPrice;
        uint256 fromTokenId;
        uint256 tillTokenId; //not inclusive
        uint256 curAvailableTokenId;
    }

    constructor(address _synTokenAddress, address _esynTokenAddress) {
        synTokenAddress = _synTokenAddress;
        esynTokenAddress = _esynTokenAddress;

        _boxId.increment(); //so boxId will start from 1
    }

//    The assumption is that tokens are generated in advance in database, but not revealed yet. When user buy token, he gets tokenid, but does not know what items he gets.
//    After all items are sold or available time finished, we update data in database and show what assets user got.
//    For example mystery box has 100 items. Then we can generate 100 items in db, for example from 0x288eff3b977db1a75833078f8efe8a5dced20bde2887105485676b2c43f1259f till 0x288eff3b977db1a75833078f8efe8a5dced20bde2887105485676b2c43f1259f+100
    function newBox(
        uint256 _base,
        uint256 _amount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _synPrice,
        uint256 _esyncPrice
    ) public onlyOwner {
        Box storage box = boxes[_boxId.current()];
        box.id = _boxId.current();
        box.startTime = _startTime;
        box.endTime = _endTime;
        box.synPrice = _synPrice;
        box.esyncPrice = _esyncPrice;
        box.fromTokenId = _base;
        box.tillTokenId = _base + _amount;
        box.curAvailableTokenId = _base;

        _boxId.increment();

        emit BoxCreated(box.id);
    }

    function buy(uint256 boxId, bool useSynToken) public {
        Box storage box = boxes[boxId];

        require(box.id != 0, "mystery box with such id does not exist");

        if (box.startTime != 0) {
            require(box.startTime <= block.timestamp, "give away not started yet");
        }

        if (box.endTime != 0) {
            require(block.timestamp < box.endTime, "give away not started yet");
        }

        require(box.curAvailableTokenId < box.tillTokenId, "no more available tokens left");
        require(tokenOwners[box.curAvailableTokenId] == address(0), "token already used by someone");

        tokenOwners[box.curAvailableTokenId] = msg.sender;
        box.curAvailableTokenId += 1;

        if (useSynToken && box.synPrice > 0) {
            require(IERC20(synTokenAddress).transferFrom(msg.sender, address(this), box.synPrice), "unable to transfer syn tokens");
        } else if (box.esyncPrice > 0) {
            require(IERC20(esynTokenAddress).transferFrom(msg.sender, address(this), box.synPrice), "unable to transfer esyn tokens");
        }

        emit BoxBought(msg.sender, boxId, box.curAvailableTokenId - 1);
    }
}