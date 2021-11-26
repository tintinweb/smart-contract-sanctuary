// From Solidity ^0.6.8 SPDX license is introduced. So you need to use SPDX-License-Identifier in the code.
// SPDX-License-Identifier: MIT

// Solidity version used by compiler.
pragma solidity ^0.8.0;

import "./Ownable.sol";

// Main building block for smart contracts.
contract OPEC is Ownable {
    // Token identifiers name and symbol.
    string public name = 'OPEC Token';
    string public symbol = 'OPEC';

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
    address public deployer;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;

    // Contract initialization. The constructor is executed only once when the contract is created.
    constructor() {
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        // Check if the transaction sender has enough tokens. If require's first argument evaluates to false, then the transaction will revert.
        require(balances[msg.sender] >= amount, "Insufficient funds");
        
        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    /*
        Read only function to retrieve the token balance of a given account. 
        The view modifier indicates that it doesn't modify the contracts state, which allows us to call it without executing a transaction.
    */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/*
    @dev Contract module which provides a basic access control mechanism, where
    there is an account (an owner) that can be granted exclusive access to
    specific functions.
 
    By default, the owner account will be the one that deploys the contract. This
    can later be changed with {transferOwnership}.
 
    This module is used through inheritance. It will make available the modifier
    `onlyOwner`, which can be applied to your functions to restrict their use to
    the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*
        @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /*
        @dev Returns the address of the current owner.
    */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /*
        @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /*
        @dev Leaves the contract without owner. It will not be possible to call
        `onlyOwner` functions anymore. Can only be called by the current owner.
    
        NOTE: Renouncing ownership will leave the contract without an owner,
        thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /*
        @dev Transfers ownership of the contract to a new account (`newOwner`).
        Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /*
        @dev Transfers ownership of the contract to a new account (`newOwner`).
        Internal function without access restriction.
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

/*
    @dev Provides information about the current execution context, including the
    sender of the transaction and its data. While these are generally available
    via msg.sender and msg.data, they should not be accessed in such a direct
    manner, since when dealing with meta-transactions the account sending and
    paying for execution may not be the actual sender (as far as an application
    is concerned).
 */

 // This contract is only required for intermediate, library-like contracts.
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}