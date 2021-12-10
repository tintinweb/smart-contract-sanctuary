// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

contract RoyaltiesPayment is Ownable {

    struct PlayerBalance {
        uint256 userIndex;
        uint256 balance;
    }

    address[] public payees;
    mapping(address => PlayerBalance) public balances;

    constructor(address[] memory _payees) {
        payees = _payees;
        for (uint256 i = 0; i < payees.length; i++) {
            balances[payees[i]] = PlayerBalance({userIndex : i+1,
            balance : 0});
        }
    }

    receive() external payable {
        uint256 amount = msg.value;
        uint256 sharePerPayee = amount / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            balances[payees[i]].balance += sharePerPayee;
        }

    }

    function _isPayee(address user) internal view
    returns(bool) {
        return balances[user].userIndex > 0;
    }

    function withdraw(uint256 amount) external isPayee(msg.sender) {
        require(amount > 0);
        require(amount <= balances[msg.sender].balance,
            "Insufficient balance");
        balances[msg.sender].balance -= amount;
        (bool success,) = msg.sender.call{value: amount}('');
        require(success);
    }

    function withdrawAll() external isPayee(msg.sender) {
        require(balances[msg.sender].balance > 0);
        uint256 balance = balances[msg.sender].balance;
        balances[msg.sender].balance = 0;
        (bool success,)=msg.sender.call{value: balance}('');
        require(success);
    }

    function _payAll() internal {
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            uint256 availableBalance = balances[payee].balance;
            if (availableBalance > 0) {
                balances[payee].balance = 0;
                (bool success,)=payee.call{value: availableBalance}('');
                require(success);
            }
        }
    }

    function payAll() external onlyOwner {
        _payAll();
    }

    function removePayee(address payee) external onlyOwner {
        require(_isPayee(payee));
        _payAll();
        uint256 removalIndex = balances[payee].userIndex - 1;
        payees[removalIndex] = payees[payees.length - 1];
        payees.pop();
        if (removalIndex != payees.length) {
            balances[payees[removalIndex]].userIndex = removalIndex + 1;
        }
        delete (balances[payee]);
    }

    function addPayee(address payee) external onlyOwner {
        require(!_isPayee(payee));
        _payAll();
        payees.push(payee);
        balances[payee] = PlayerBalance(payees.length, 0);
    }

    function withdrawErc20(IERC20 token) external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0);
        uint256 payeeShare = tokenBalance / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            token.transfer(payees[i], payeeShare);
        }
    }

    modifier isPayee(address user) {
        require(_isPayee(user),
            "Not payee");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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