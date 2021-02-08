/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/staking/StakingRewardsAdapterRegistry.sol


pragma solidity ^0.6.0;


/// @notice The stakingRewardsAdapter registry database for Furucombo
contract StakingRewardsAdapterRegistry is Ownable {
    mapping(address => bytes32) public adapters;

    bytes32 constant DEPRECATED = bytes10(0x64657072656361746564);

    /**
     * @notice Transfer ownership to tx.origin since we are
     * using a create2 factory to deploy contract, and the
     * owner will be the factory if we do not transfer.
     * Ref: https://eips.ethereum.org/EIPS/eip-2470
     */
    constructor() public {
        transferOwnership(tx.origin);
    }

    /**
     * @notice Register an adapter with a bytes32 information.
     * @param registration Adapter address.
     * @param info Info string.
     */
    function register(address registration, bytes32 info) external onlyOwner {
        require(registration != address(0), "zero address");
        require(adapters[registration] == bytes32(0), "registered");
        adapters[registration] = info;
    }

    /**
     * @notice Unregister an adapter. The adapter will be deprecated.
     * @param registration The adapter to be unregistered.
     */
    function unregister(address registration) external onlyOwner {
        require(registration != address(0), "zero address");
        require(adapters[registration] != bytes32(0), "no registration");
        require(adapters[registration] != DEPRECATED, "unregistered");
        adapters[registration] = DEPRECATED;
    }

    /**
     * @notice Update the info of a valid adapter.
     * @param adapter The adapter to be updating info.
     * @param info New info to be updated.
     */
    function updateInfo(address adapter, bytes32 info) external onlyOwner {
        require(adapter != address(0), "zero address");
        require(info != bytes32(0), "update info to 0 is prohibited");
        require(adapters[adapter] != bytes32(0), "no registration");
        require(adapters[adapter] != DEPRECATED, "unregistered");
        adapters[adapter] = info;
    }

    /**
     * @notice Check if the adapter is valid.
     * @param adapter The adapter to be verified.
     */
    function isValid(address adapter) external view returns (bool result) {
        if (adapters[adapter] == 0 || adapters[adapter] == DEPRECATED)
            return false;
        else return true;
    }

    /**
     * @notice Get the information of a registration.
     * @param adapter The adapter address to be queried.
     */
    function getInfo(address adapter) external view returns (bytes32 info) {
        return adapters[adapter];
    }
}