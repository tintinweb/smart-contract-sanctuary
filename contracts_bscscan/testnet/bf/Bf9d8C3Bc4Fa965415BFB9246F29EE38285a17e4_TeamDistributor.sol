// Copyright © 2021 Moon Bear Finance Ltd. All Rights Reserved.
// SPDX-License-Identifier: GPL-3.0
//
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░
// ░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░
// ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░
// ░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░
// ░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████▓████▓▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒░░░░░░
// ░░░░░░▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▓███████████▓▓▒▒▒▒▒▒▒░░░░░▒▒▒▒▒░░░░░
// ░░░░░▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒█████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▓▓▓███████████████▓▒▒▒▒▒▒░▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓████████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒▒▒▒▒▒▒▒▒▒▓███████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░▒▒▒░░░░▒▒▒▒▒████████████████████████████▒▒▒▒▒▒▒▒▒▒▒▒░░░░
// ░░░░░▒▒▒▒▒▒▒▒▒▒▒████████████████████████████▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░░▒▒▒▒▒▒▒▒▒▒▒█████████▓▓█████████▓▓▓█████▒▒▒▒▒▒▒▒▒▒▒░░░░░
// ░░░░░░▒▒▒▒▒▒▒▒▒▒██████▓▒▒▒▒▓█████▓▓▒▒▒▓█████▒▒▒▒▒▒▒▒▒▒░░░░░░
// ░░░░░░░▒▒▒▒▒▒▒▒▒██████▓▓▓▓▓██████▓▓▓▓▓▓█████▒▒▒▒▒▒▒▒▒░░░░░░░
// ░░░░░░░░░▒▓▓▓██████████████████████████████████▓▓▓▒▒░░░░░░░░
// ░░░░░░░░░░▓██████████████████████████████████████▓░░░░░░░░░░
// ░░░░░░░░░░░▒▓██████████████████████████████████▓▒░░░░░░░░░░░
// ░░░░░░░░░░░░░░▒▓████████████████████████████▓▒░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░▒▒▓▓████████████████████▓▓▒▒░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░▒▒▓▓▓▓██████▓▓▓▓▒▒░░░░░░░░░░░░░░░░░░░░░
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { DistributeIterableMapping } from "./libs/DistributeIterableMapping.sol";

contract TeamDistributor is Ownable, ReentrancyGuard {
    using DistributeIterableMapping for DistributeIterableMapping.Map;

    DistributeIterableMapping.Map private members;

    uint256 public totalAllocation; //Default: 1000: 100%, 10: 1%

    IERC20 public token; // ERC20 token address
    address public baseAccount; // baseAccount: (total - Members' amount) will be distributed to this account

    uint256 public totalReleased; // totalRelease Amount of Token (sent to members)
    uint256 public totalDistributed; // total Distributed Amount of Token
    uint256 public allocationSum; // sum of members' allocation, should be less than 1000

    uint256 public lastDistributedTimeStamp;

    event DistributeWalletCreated(address indexed addr, address indexed baseAccount);
    event DistributeBaseAccountChanged(address indexed baseAccount);
    event DistributeMemberAdded(address indexed member, uint256 allocation);
    event DistributeMemberRemoved(address indexed member);
    event TokenDistributed(uint256 amount);
    event TokenReleased(address indexed member, uint256 amount);
    event DistributeMemberAddressChanged(address indexed oldAddr, address indexed newAddr);
    event DistributeMemberAllocationChanged(address indexed member, uint256 newAllocation);

    constructor(IERC20 _token, address _baseAccount) {
        require(_baseAccount != address(0), "BaseAccount can't be empty address");
        require(address(_token) != address(0), "Token address can't be empty address");
        token = _token;
        baseAccount = _baseAccount;

        members.set(baseAccount, DistributeIterableMapping.DistributeMember(baseAccount, 0, 0, 0));

        lastDistributedTimeStamp = block.timestamp;
        totalAllocation = 1000;

        emit DistributeWalletCreated(address(this), baseAccount);
    }

    function getTotalMembers() external view returns (uint256) {
        return members.size();
    }

    function getMemberInfo(address _member)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        require(members.inserted[_member], "Member doesn't exist!");
        DistributeIterableMapping.DistributeMember storage member = members.get(_member);

        if (_member == baseAccount) {
            // baseAccount
            return (member.addr, 1000 - allocationSum, member.pending, member.totalReleased);
        }

        return (member.addr, member.allocation, member.pending, member.totalReleased);
    }

    function getMemberInfoAtIndex(uint256 memberIndex)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        require(memberIndex < members.size(), "MemberIndex invalid!");
        address memberAddress = members.getKeyAtIndex(memberIndex);
        require(members.inserted[memberAddress], "Member doesn't exist!");
        DistributeIterableMapping.DistributeMember storage member = members.get(memberAddress);

        if (memberIndex == 0) {
            // baseAccount
            return (member.addr, 1000 - allocationSum, member.pending, member.totalReleased);
        }

        return (member.addr, member.allocation, member.pending, member.totalReleased);
    }

    function getReleasableAmount(address member) external view returns (uint256) {
        require(members.inserted[member], "Member doesn't exist!");
        uint256 pendingAmount = token.balanceOf(address(this)) + totalReleased - totalDistributed;
        if (member == baseAccount) {
            return members.get(member).pending + (pendingAmount * (totalAllocation - allocationSum)) / totalAllocation;
        } else {
            return members.get(member).pending + (pendingAmount * members.get(member).allocation) / totalAllocation;
        }
    }

    // msg.sender is member and trying to change address
    function updateMemberAddress(address newAddr) external {
        address member = msg.sender;
        require(newAddr != address(0), "New address can't be a ZERO address!");
        require(members.inserted[member], "You're not a member!");
        require(!members.inserted[newAddr], "NewAddr already exist!");

        members.set(
            newAddr,
            DistributeIterableMapping.DistributeMember(
                newAddr,
                members.get(member).allocation,
                members.get(member).pending,
                0
            )
        );

        members.remove(member);

        emit DistributeMemberAddressChanged(member, newAddr);
    }

    // admin changes allocation of a member
    function updateMemberAllocation(address member, uint256 allocation) external onlyOwner {
        require(allocation > 0, "Allocation can't be ZERO!");
        require(members.inserted[member], "Member is not a member!");

        allocationSum = allocationSum + allocation - members.get(member).allocation;

        require(allocationSum <= totalAllocation, "Allocation is too big!");

        updatePendingAmounts();

        members.get(member).allocation = allocation;

        emit DistributeMemberAllocationChanged(member, allocation);
    }

    function _release(address _member) private nonReentrant {
        require(members.inserted[_member], "Member doesn't exist!");
        DistributeIterableMapping.DistributeMember storage member = members.get(_member);
        uint256 pendingAmount = member.pending;
        if (pendingAmount > 0) {
            member.totalReleased = member.totalReleased + pendingAmount;
            member.pending = 0;
            totalReleased = totalReleased + pendingAmount;
            token.transfer(_member, pendingAmount);
        }
        emit TokenReleased(_member, pendingAmount);
    }

    function updatePendingAmounts() public {
        if (lastDistributedTimeStamp < block.timestamp) {
            uint256 pendingAmount = token.balanceOf(address(this)) + totalReleased - totalDistributed;
            if (pendingAmount > 0) {
                // updatePendingAmounts to members, and restAmount to baseAccount
                uint256 distributedAmount = 0;
                uint256 memberLength = members.size();
                for (uint256 index = 1; index < memberLength; index++) {
                    address memberAddress = members.getKeyAtIndex(index);
                    DistributeIterableMapping.DistributeMember storage member = members.get(memberAddress);
                    uint256 amount = (pendingAmount * member.allocation) / totalAllocation;
                    member.pending = member.pending + amount;
                    distributedAmount = distributedAmount + amount;
                }

                DistributeIterableMapping.DistributeMember storage baseMember = members.get(baseAccount);
                uint256 restAmount = pendingAmount - distributedAmount;
                baseMember.pending = baseMember.pending + restAmount;

                totalDistributed = totalDistributed + pendingAmount;
            }
        }
        lastDistributedTimeStamp = block.timestamp;
    }

    function addMember(address _member, uint256 _allocation) external onlyOwner {
        require(_member != address(0), "Member address can't be empty address");
        require(!members.inserted[_member], "Member already exist!");
        require(_allocation > 0, "Allocation can't be zero!");
        allocationSum = allocationSum + _allocation;
        require(allocationSum < totalAllocation, "Allocation is too big!");
        // updatePendingAmounts current pending tokens to existing members and then add new member
        updatePendingAmounts();
        members.set(_member, DistributeIterableMapping.DistributeMember(_member, _allocation, 0, 0));
        emit DistributeMemberAdded(_member, _allocation);
    }

    function removeMember(address _member) external onlyOwner {
        require(_member != baseAccount, "You can't remove baseAccount!");
        require(members.inserted[_member], "Member doesn't exist!");
        // updatePendingAmounts pending Amount to members and send necessary amount to that member, and then remove
        updatePendingAmounts();
        _release(_member);
        allocationSum = allocationSum - members.get(_member).allocation;
        members.remove(_member);

        emit DistributeMemberRemoved(_member);
    }

    function release() external {
        // updatePendingAmounts pendingAmount first and release
        updatePendingAmounts();
        _release(msg.sender);
    }

    function releaseToMember(address member) external {
        // updatePendingAmounts pendingAmount first and release
        updatePendingAmounts();
        _release(member);
    }

    function releaseToMemberAll() external onlyOwner {
        updatePendingAmounts();

        uint256 memberLength = members.size();
        for (uint256 index = 0; index < memberLength; index++) {
            address memberAddress = members.getKeyAtIndex(index);
            _release(memberAddress);
        }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DistributeIterableMapping {
    struct DistributeMember {
        address addr;
        uint256 allocation;
        uint256 pending;
        uint256 totalReleased;
    }

    // Iterable mapping from address to DistributeMember;
    struct Map {
        address[] keys;
        mapping(address => DistributeMember) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (DistributeMember storage) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        DistributeMember memory val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}