//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";
import "Counters.sol";

contract ERC20EscrowCounter is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _depositIds;

    event Deposited(
        uint256 indexed depositId,
        string cid,
        address tokenAddress,
        uint256 amount,
        string action
    );

    event PayeeSet(
        uint256 indexed depositId,
        string cid,
        address payee,
        string action
    );

    event Withdrawn(
        uint256 indexed depositId,
        string cid,
        address tokenAddress,
        uint256 amount,
        string action
    );

    // deposit id => token address => amount
    mapping(uint256 => mapping(address => uint256)) public deposits;

    // deposit id => token address => expiration time
    mapping(uint256 => mapping(address => uint256)) public expirations;

    // deposit id => payee address
    mapping(uint256 => address) public payees;

    constructor() {}

    function deposit(
        string memory _cid,
        uint256 _amount,
        uint256 _expiration,
        IERC20 token
    ) public onlyOwner {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Could not transfer amount"
        );

        _depositIds.increment();
        uint256 newDepositId = _depositIds.current();

        deposits[newDepositId][address(token)] += _amount;
        expirations[newDepositId][address(token)] =
            block.timestamp +
            _expiration;
        emit Deposited(
            newDepositId,
            _cid,
            address(token),
            _amount,
            "deposited"
        );
    }

    function setPayee(
        uint256 _depositId,
        string memory _cid,
        address payable _payee
    ) public onlyOwner {
        payees[_depositId] = _payee;
        emit PayeeSet(_depositId, _cid, _payee, "payeeSet");
    }

    function withdraw(
        uint256 _depositId,
        string memory _cid,
        uint256 _amount,
        IERC20 token
    ) public {
        uint256 totalPayment = deposits[_depositId][address(token)];
        require(totalPayment >= _amount, "Not enough value");

        address _payee = payees[_depositId];
        require(msg.sender == _payee, "Don't have permission to withdraw");

        token.approve(_payee, _amount);
        require(token.transfer(_payee, _amount));
        deposits[_depositId][address(token)] = totalPayment - _amount;

        emit Withdrawn(_depositId, _cid, address(token), _amount, "completed");
    }

    function refund(
        uint256 _depositId,
        string memory _cid,
        IERC20 token
    ) public onlyOwner {
        require(
            block.timestamp > expirations[_depositId][address(token)],
            "The payment is still in escrow."
        );
        uint256 payment = deposits[_depositId][address(token)];
        token.approve(msg.sender, payment);
        require(token.transfer(msg.sender, payment), "Transfer failed");
        deposits[_depositId][address(token)] = 0;
        emit Withdrawn(_depositId, _cid, address(token), payment, "refunded");
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

/*
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