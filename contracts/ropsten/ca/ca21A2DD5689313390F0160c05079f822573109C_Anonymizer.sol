// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

pragma solidity ^0.8.0;

/**
 * @title App through which a layer of anonymity is added to peer-to-peer transactions
 * @author Sami Gabor
 * @notice study project which may have security vulnerabilities
 */
contract Anonymizer is Ownable, Pausable {
    /**
     * @dev users balances:
     * The key is the user's address(hashed to increase privacy)
     * The value is the user's balance
     **/
    mapping(address => uint256) private balances;

    /**
     * @dev events:
     * @param balance the updated eth balance for current user
     **/
    event EthDeposit(uint256 indexed balance);
    event DepositerEthBalance(uint256 indexed balance);
    event EthWithdraw(uint256 indexed balance);

    /**
     * @notice Returns the ether balance available inside the contract
     * @return sender's contract balance
     **/
    function getBalance(address _addr) public view returns (uint256) {
        return balances[_addr];
    }

    /**
     * @notice Deposits funds into the contract and assignes them to the receiver
     * @dev increase receiver's contract balance
     * @dev emit the sender's current contract balance
     * @param _to the destination address to which the ether is assigned
     **/
    function depositEth(address _to) public payable whenNotPaused {
        balances[_to] += msg.value;
        emit DepositerEthBalance(balances[msg.sender]);
    }

    /**
     * @notice Deposits funds into the contract and assignes them to the sender and the receiver
     * @notice By sending funds to your own address, it increases the transaction anonymity. The funds are kept within the contract and available for claim
     * @notice DO NOT KEEP LARGE AMOUNTS INTO THE CONTRACT, withdraw them every once in a while
     * @dev increase the receiver's contract balance
     * @dev increase the sender's contract balance
     * @param _to the destination address to which the ether is added
     * @param _toMyselfAmount the amount assigned back to sender(inside the contract) in order to increase the anonymity
     **/
    function depositEth(address _to, uint256 _toMyselfAmount)
        public
        payable
        whenNotPaused
    {
        require(
            msg.value > _toMyselfAmount,
            "The total amount must be greather than the amount deposited back to sender"
        );
        uint256 _toAmount = msg.value - _toMyselfAmount;
        balances[_to] += _toAmount;
        balances[msg.sender] += _toMyselfAmount;
        emit DepositerEthBalance(balances[msg.sender]);
    }

    /**
     * @notice Withdraw funds, assigned to own address, from the contract
     * @notice DO NOT KEEP LARGE AMOUNTS INTO THE CONTRACT, withdraw them every once in a while
     * @dev withwraw from the contract and decrease the sender's balance
     **/
    function withdrawEth(address payable _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient funds.");
        balances[msg.sender] -= _amount;
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        emit EthWithdraw(balances[msg.sender]);
    }

    function freezeDeposits() external onlyOwner {
        _pause();
    }

    function unfreezeDeposits() external onlyOwner {
        _unpause();
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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