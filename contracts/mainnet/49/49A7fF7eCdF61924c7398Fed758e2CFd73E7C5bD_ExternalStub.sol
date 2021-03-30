/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// File: contracts/access/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/access/Ownable.sol


//pragma solidity ^0.6.0;
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/ExternalStub.sol


pragma solidity ^0.8.0;


/**
 * @title Stub for BSC connection
 * @dev Can be accessed by an authorized bridge/ValueHolder
 */

contract ExternalStub is Ownable {
    bool private initialized;

    address public ValueHolder;

    address public enterToken; //= DAI_ADDRESS;
    uint256 private PoolValue;

    event LogValueHolderUpdated(address Manager);

    /**
     * @dev main init function
     */

    function init(address _enterToken) external {
        require(!initialized, "Initialized");
        initialized = true;
        Ownable.initialize(); // Do not forget this call!
        _init(_enterToken);
    }

    /**
     * @dev internal variable initialization
     */
    function _init(address _enterToken) internal {
        enterToken = _enterToken;
        ValueHolder = msg.sender;
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit(address _enterToken) external onlyOwner {
        _init(_enterToken);
    }

    /**
     * @dev this modifier is only for methods that should be called by ValueHolder contract
     */
    modifier onlyValueHolder() {
        require(msg.sender == ValueHolder, "Not Value Holder");
        _;
    }

    /**
     * @dev Sets new ValueHolder address
     */
    function setValueHolder(address _ValueHolder) external onlyOwner {
        ValueHolder = _ValueHolder;
        emit LogValueHolderUpdated(_ValueHolder);
    }

    /**
     * @dev Main function to enter Compound supply/borrow position using the available [DAI] token balance
     */
    function addPosition() external pure {
        revert("Stub");
    }

    /**
     * @dev Main function to exit position - partially or completely
     */
    function exitPosition(uint256) external pure {
        revert("Stub");
    }

    /**
     * @dev Get the total amount of enterToken value of the pool
     */
    function getTokenStaked() external view returns (uint256) {
        return (PoolValue);
    }

    /**
     * @dev Get the total value the Pool in [denominateTo] tokens [DAI?]
     */

    function getPoolValue(address) external view returns (uint256 totalValue) {
        return (PoolValue);
    }

    /**
     * @dev Get the total value the Pool in [denominateTo] tokens [DAI?]
     */

    function setPoolValue(uint256 _PoolValue) external onlyValueHolder {
        PoolValue = _PoolValue;
    }

    /**
     * @dev Claim all available CRV from compound and convert to DAI as needed
     */
    function claimValue() external pure {
        revert("Stub");
    }
}