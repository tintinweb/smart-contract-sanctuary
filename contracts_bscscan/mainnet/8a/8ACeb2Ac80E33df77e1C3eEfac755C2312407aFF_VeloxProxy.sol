/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// File: contracts/BackingStore.sol

// SPDX-FileCopyrightText: © 2020 Velox <[email protected]>
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity >=0.8.0;

//note do not change this file as the proxy is built on it
abstract contract BackingStore {
    address public MAIN_CONTRACT;//slot storage 0
    address public UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;//slot storage 1
    address public UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//slot storage 2
    address public ADMIN_ADDRESS;//slot storage 3
}


pragma solidity 0.8.0;

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
//note do not change this file as the proxy is built on it
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.8.0;

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

//note do not change this file as the proxy is built on it
abstract contract Ownable is Context {
    address private _owner;//proxy storage slot 4

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



pragma solidity >=0.8.0;

/**
  * @title VeloxProxy (Proxy Contract)
  *
  * @dev Call:
  *
  * VeloxProxy.at(VeloxProxy.address).setContract(VeloxSwap.address)
  * VeloxSwap.at(VeloxProxy.address).sellTokenForETH(seller, token, tokenAmount, deadline
  * VeloxSwap.at(VeloxProxy.address).setUniswapRouter(0xbeefc0debeefbeef)
  *
  */
contract VeloxProxy is BackingStore, Ownable {

    function setAdminAddress(address _c) public onlyOwner returns (bool succeeded) {
        require(_c != owner(), "VELOXPROXY_ADMIN_OWNER");
        ADMIN_ADDRESS = _c;
        return true;
    }

    // Set main Velox contract address
    function setMainContract(address _c) public onlyOwner returns (bool succeeded) {
        require(_c != address(this), "VELOXPROXY_CIRCULAR_REFERENCE");
        require(isContract(_c), "VELOXPROXY_NOT_CONTRACT");
        MAIN_CONTRACT = _c;
        return true;
    }

    // ASM fallback function
    function _fallback () internal {
        address target = MAIN_CONTRACT;

        assembly {
            // Copy the data sent to the memory address starting free mem position
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            // Proxy the call to the contract address with the provided gas and data
            let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)

            // Copy the data returned by the proxied call to memory
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            // Check what the result is, return and revert accordingly
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }

    // ASM fallback function
    fallback () external {
        _fallback();
    }

    receive () payable external {
        _fallback();
    }
    
    function isContract (address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}