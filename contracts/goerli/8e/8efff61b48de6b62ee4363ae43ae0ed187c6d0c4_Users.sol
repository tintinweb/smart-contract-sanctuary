/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/utils/Context.sol



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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: Users.sol


pragma solidity ^0.8.0;

contract Users is Context {
    
    mapping (address => address) private _users;
    
    address constant TEAMFOUNDATION = address(0);
    address constant USERFOUNDATION = address(1);

    
    constructor () {
        _users[USERFOUNDATION] = TEAMFOUNDATION;
        
    }
    
    function isRegister (address account) public view returns (bool) {
        return _users[account] != address(0);
    }
    
    function user () public view returns (address) {
        return _users[USERFOUNDATION];
    }
    
    function team () public view returns (address) {
        return _users[TEAMFOUNDATION];
    }
    
    
    function register (address account) public returns (bool) {
        require(!isRegister(account), "ERROR: User does not exist!");
        require(account != TEAMFOUNDATION, "ERROR: Can not help TEAMFOUNDATION!");
        require(account != _msgSender(), "ERROR: Can not help yourself!");
        _users[_msgSender()] = account;
        return true;
    }
}