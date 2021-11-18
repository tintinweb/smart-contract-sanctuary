/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File contracts/insured-bridge/ovm/Optimism_Wrapper.sol


/**
 * @title Optimism Eth Wrapper
 * @dev Any ETH sent to this contract is wrapped into WETH and sent to the set bridge pool. This enables ETH to be sent
 * over the canonical Optimism bridge, which does not support WETH bridging.
 */
interface WETH9Like {
    function deposit() external payable;

    function transfer(address guy, uint256 wad) external;

    function balanceOf(address guy) external view returns (uint256);
}

contract Optimism_Wrapper is Ownable {
    WETH9Like public weth;
    address public bridgePool;

    event ChangedBridgePool(address indexed bridgePool);

    /**
     * @notice Construct Optimism Wrapper contract.
     * @param _weth l1WethContract address. Normally deployed at 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2.
     * @param _bridgePool address of the bridge pool to send Wrapped ETH to when ETH is sent to this contract.
     */
    constructor(WETH9Like _weth, address _bridgePool) {
        weth = _weth;
        bridgePool = _bridgePool;
        emit ChangedBridgePool(bridgePool);
    }

    /**
     * @notice Called by owner of the wrapper to change the destination of the wrapped ETH (bridgePool).
     * @param newBridgePool address of the bridge pool to send Wrapped ETH to when ETH is sent to this contract.
     */
    function changeBridgePool(address newBridgePool) public onlyOwner {
        bridgePool = newBridgePool;
        emit ChangedBridgePool(bridgePool);
    }

    /**
     * @notice Publicly callable function that takes all ETH in this contract, wraps it to WETH and sends it to the
     * bridge pool contract. Function is called by fallback functions to automatically wrap ETH to WETH and send at the
     * conclusion of a canonical ETH bridging action.
     */
    function wrapAndTransfer() public payable {
        weth.deposit{ value: address(this).balance }();
        weth.transfer(bridgePool, weth.balanceOf(address(this)));
    }

    // Fallback functions included to make this contract accept ETH.
    receive() external payable {
        wrapAndTransfer();
    }

    fallback() external payable {
        wrapAndTransfer();
    }
}