// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TimeLockedWallet.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Mplus.sol";
import "./Pausable.sol";

contract TimeLockedWalletFactory is Context, Ownable, Pausable, Mplus {
    mapping(address => address[]) wallets;

    function getWallets(address _user) public view returns (address[] memory) {
        return wallets[_user];
    }

    function newTimeLockedWallet(
        address _owner,
        uint256 _amount,
        uint256 _unlockDate
    ) public returns (address _wallet) {
        // Create new wallet.

        TimeLockedWallet wallet = new TimeLockedWallet(
            _msgSender(),
            _owner,
            _amount,
            _unlockDate
        );

        // Add wallet to sender's wallets.
        wallets[_msgSender()].push(address(wallet));

        // If owner is the same as sender then add wallet to sender's wallets too.
        if (_msgSender() != _owner) {
            wallets[_owner].push(address(wallet));
        }
        // Send ether from this transaction to the created contract.
        // wallet.transfer(msg.value);

        // Emit event.
        emit Created(
            address(wallet),
            _msgSender(),
            _owner,
            block.timestamp,
            _unlockDate,
            _amount
        );
        return address(wallet);
    }

    event Created(
        address wallet,
        address from,
        address to,
        uint256 createdAt,
        uint256 unlockDate,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.4;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Context.sol";
import "./Pausable.sol";

interface IERC20 {
    // functions defined in the IERC20 interface

    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Mplus is Ownable, Pausable {
    // This is the  rinkeby contract address (MPLUS)
    IERC20 mplus = IERC20(address(0x813ddb02184B104166f18c9BE73Af77130558B55));

    // emit events
    event eventSendMplus(address advisor, uint256 amount);

    event eventSendMplusOwner(address advisor, uint256 amount);

    /**
     * @notice transfer is used to transfer funds from the sender to the recipient
     * This function is only callable from outside the contract. For internal usage see
     * _transfer
     *
     * Requires
     * - Caller cannot be zero
     * - Caller must have a balance = or bigger than amount
     *
     */
    function sendMplusOwner(address _address, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        // Send ether from this transaction to the created contract.
        bool sent = mplus.transfer(_address, _amount);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit eventSendMplusOwner(_address, _amount);

        return sent;
    }

    /**
     * @notice transfer is used to transfer funds from the sender to the recipient
     * This function is only callable from outside the contract. For internal usage see
     * _transfer
     *
     * Requires
     * - Caller cannot be zero
     * - Caller must have a balance = or bigger than amount
     *
     */
    function sendMplus(address _address, uint256 _amount)
        internal
        whenNotPaused
        returns (bool)
    {
        // Send ether from this transaction to the created contract.
        bool sent = mplus.transfer(_address, _amount);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit eventSendMplus(_address, _amount);

        return sent;
    }

    /**
     * @notice balanceOf will return the account balance for the given account
     */
    function balanceOf(address _address) public view returns (uint256) {
        return mplus.balanceOf(_address);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.4;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

import "./Mplus.sol";
import "./Context.sol";
import "./Ownable.sol";

contract TimeLockedWallet is Context, Ownable, Mplus {
    address public creator;
    address public walletOwner;
    uint256 public amount;
    uint256 public unlockDate;
    uint256 public createdAt;

    struct Wallet {
        address creator;
        address walletOwner;
        uint256 amount;
        uint256 unlockDate;
        uint256 createdAt;
    }

    modifier _onlyOwner() {
        require(_msgSender() == walletOwner);
        _;
    }

    constructor(
        address _creator,
        address _owner,
        uint256 _amount,
        uint256 _unlockDate
    ) {
        creator = _creator;
        walletOwner = _owner;
        amount = _amount;
        unlockDate = _unlockDate;
        createdAt = block.timestamp;

        emit Received(_msgSender(), amount);
    }

    // @notice Transfer the amount to the owner
    function removeAdvisor(address _account) public onlyOwner {
        //now send the balance
        bool sent = mplus.transfer(_account, amount);
        require(sent, "Failed to transfer token to user");

        emit RemoveAdvisor(_msgSender(), amount);
    }

    // callable by owner only, after specified time
    function withdraw() public _onlyOwner returns (bool) {
        require(block.timestamp >= unlockDate);

        //now send the balance
        bool sent = mplus.transfer(walletOwner, amount);
        require(sent, "Failed to transfer token to user");

        emit Withdrew(_msgSender(), amount);
        return true;
    }

    function info() public view returns (Wallet memory) {
        return Wallet(creator, walletOwner, amount, unlockDate, createdAt);
    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event RemoveAdvisor(address to, uint256 amount);
}