// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


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
contract Godable {
    address private _god;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _god = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function god() public view returns (address) {
        return _god;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGod() {
        require(_god == msg.sender, "Godable: caller is not the god");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferGod(address newOwner) public virtual onlyGod {
        require(newOwner != address(0), "Godable: new owner is the zero address");
        emit OwnershipTransferred(_god, newOwner);
        _god = newOwner;
    }
}
