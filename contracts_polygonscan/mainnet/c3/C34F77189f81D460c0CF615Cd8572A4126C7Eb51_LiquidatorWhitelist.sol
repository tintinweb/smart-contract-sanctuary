pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.16;

import "./Ownable.sol";

/**
 * @title LiquidatorWhitelist
 * @author Kine
 */
contract LiquidatorWhitelist is Ownable {
    /// @notice liquidator list, use mapping combined with list, to save gas and also track whole whitelist
    mapping(address => bool) public liquidators;
    address[] public whitelist;

    event LiquidatorAdded(address newLiquidator);

    event LiquidatorRemoved(address liquidatorRemoved);

    /// @notice check if valid liquidator
    function isListed(address liquidatorToVerify) external view returns (bool){
        return liquidators[liquidatorToVerify];
    }

    /// @notice get the whole whitelist
    function getWhitelist() public view returns (address[] memory) {
        return whitelist;
    }

    function addLiquidators(address[] memory liquidatorsToAdd) public onlyOwner {
        for(uint i = 0; i < liquidatorsToAdd.length; i++){
            address liquidatorToAdd = liquidatorsToAdd[i];
            require(liquidators[liquidatorToAdd] == false, "existed");
            liquidators[liquidatorToAdd] = true;
            whitelist.push(liquidatorToAdd);
            emit LiquidatorAdded(liquidatorToAdd);
        }
    }

    function removeLiquidator(address liquidatorToRemove) public onlyOwner{
        require(liquidators[liquidatorToRemove], "not existed");

        // remove mapping item
        delete liquidators[liquidatorToRemove];

        // remove in whitelist
        for(uint i = 0; i < whitelist.length; i++){
            if(whitelist[i] == liquidatorToRemove){
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist.pop();
                break;
            }
        }

        emit LiquidatorRemoved(liquidatorToRemove);
    }
}

pragma solidity ^0.5.0;

import "./Context.sol";
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

