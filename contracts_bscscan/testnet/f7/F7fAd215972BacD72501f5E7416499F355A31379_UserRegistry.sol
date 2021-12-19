//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";

contract UserRegistry is Context {

    struct User {
        address addr;
        string username;
    }

    mapping(address => User) public registry;
    mapping(string => address) public usernames;
    
    constructor() {

    }

    function register(string memory username) public {
        registry[_msgSender()] = User({
            username: username,
            addr: _msgSender()
        });
    }

    function lookupByAddress(address _addr) public view returns(address addr, string memory username) {
        return (registry[_addr].addr, registry[_addr].username);
    }

    function lookupByUsername(string memory username) public view returns(address) {
        return usernames[username];
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