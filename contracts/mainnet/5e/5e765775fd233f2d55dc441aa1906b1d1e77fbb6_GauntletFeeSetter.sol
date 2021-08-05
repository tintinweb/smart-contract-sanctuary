/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: balancer/GauntletFeeSetter.sol

pragma solidity ^0.7.6;

// todo: add Ownable


/// @title Balancer Weighted Pool Proxy
/// @author Gauntlet
/// @dev This contract is used as a proxy to call the Balancer WeightedPools setSwapFee
interface PoolProxy {
    function setSwapFeePercentage(uint256 _fee) external;
}

/// @title Proxy to batch update Balancer pools
/// @author Gauntlet
/// @dev This contract takes in input the list of pools and fees and loop through them to update the Balancer's WeightedPools calling setSwapFee
contract GauntletFeeSetter is Ownable {

    /// @notice Emitted when setSwapFee is called
    event NewSwapFees(address _address, uint _fee);   // declaring event

    /**
     * @param addresses The list of addresses of the pools we're updating
     * @param fees The list of fees we're updating in the pool
     */
    function setSwapFees(address[] calldata addresses, uint[] calldata fees) public onlyOwner {
        require(addresses.length == fees.length, "Addresses and Fees are not the same length");
        for (uint i = 0; i < addresses.length; i++) {
            PoolProxy(addresses[i]).setSwapFeePercentage(fees[i]);
            emit NewSwapFees(addresses[i], fees[i]);
        }
    }
}