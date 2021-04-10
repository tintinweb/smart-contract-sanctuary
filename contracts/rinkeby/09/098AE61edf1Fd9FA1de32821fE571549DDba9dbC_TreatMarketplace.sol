/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "safemath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "safemath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "safemath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "safemath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "safemath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}

/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * Utility library of inline functions on addresses
 */
library Address {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "roles: account already has requested role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "roles: account does not have needed role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "roles: account is the zero address");
        return role.bearer[account];
    }
}


interface TreatNftMinter {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata data) external;
}

contract TreatMarketplace is Ownable {

    using SafeMath for uint256;
    using Address for address;

    struct Order {
        uint256 id;
        address payable seller;
        uint256 nftId;
        uint256 price;
        uint256 quantity;
        uint256 listDate;
        uint256 endDate;
    }

    event OnNftReceived(address to, uint nftId, uint quantity);
    event OnNftSent(address from, uint nftId, uint quantity);
    event TransferAmount(address to, uint256 amount);

    mapping(uint256 => Order) public orders;
    uint256 public maxId;
    TreatNftMinter treatMinter;
    address payable public treasuryAddress;

    uint256 treasuryPercentage;

    constructor(address payable _treasuryAddress, address _treatMinterAddress, uint256 _treasuryPercentage) {
      maxId = 0;
      treatMinter = TreatNftMinter(_treatMinterAddress);
      treasuryAddress = _treasuryAddress;
      treasuryPercentage = _treasuryPercentage;
    }

    function setTreasuryPercentage(uint256 _treasuryPercentage) public onlyOwner {
        treasuryPercentage = _treasuryPercentage;
    }

    function ListNft(uint256 nftId, uint256 price, uint256 quantity, uint256 endDate) public {
        uint256 newId = maxId.add(1);
        maxId = newId;
        Order memory order = Order(newId, msg.sender, nftId, price, quantity, block.timestamp, endDate);
        orders[newId] = order;
    }

    function Purchase(uint256 orderId) public payable {
        Order memory order = orders[orderId];
        require(order.id != 0, "Order id doesn't exist");
        require(block.timestamp > order.listDate, "Listing in future");
        require(order.endDate > block.timestamp, "Sale expired");

        uint totalCost = order.price.mul(order.quantity);
        require(msg.value == totalCost, "Wrong BNB price or not enough BNB");

        uint256 sellerBalance = treatMinter.balanceOf(order.seller, order.nftId);
        require(sellerBalance > order.quantity, "seller out of stock");

        treasuryAddress.transfer(msg.value.mul(100 - treasuryPercentage).div(100));
        emit TransferAmount(treasuryAddress, msg.value.mul(100 - treasuryPercentage).div(100));
        order.seller.transfer(msg.value.mul(treasuryPercentage).div(100));
        emit TransferAmount(order.seller,msg.value.mul(treasuryPercentage).div(100));

        uint256[] memory arg1;
        uint256[] memory arg2;
        arg1[0] = order.nftId;
        arg2[0] = order.quantity;
        treatMinter.safeBatchTransferFrom(order.seller, msg.sender, arg1, arg2, "0x0");

        emit OnNftReceived(msg.sender, order.nftId, order.quantity);
        emit OnNftSent(order.seller, order.nftId, order.quantity);
    }
}