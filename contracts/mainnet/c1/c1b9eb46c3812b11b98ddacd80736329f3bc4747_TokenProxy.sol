/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// File: contracts/OwnableProxy.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract OwnableProxy {
    address private _proxyOwner;
    address private _pendingProxyOwner;

    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewPendingOwner(address indexed currentOwner, address indexed pendingOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _proxyOwner = msg.sender;
        emit ProxyOwnershipTransferred(address(0), _proxyOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function proxyOwner() public view returns (address) {
        return _proxyOwner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function pendingProxyOwner() public view returns (address) {
        return _pendingProxyOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(isProxyOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isProxyOwner() public view returns (bool) {
        return msg.sender == _proxyOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        _transferProxyOwnership(newOwner);
        emit NewPendingOwner(_proxyOwner, newOwner);
    }

    function claimProxyOwnership() public {
        _claimProxyOwnership(msg.sender);
    }

    function initProxyOwnership(address newOwner) public {
        require(_proxyOwner == address(0), "Ownable: already owned");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferProxyOwnership(newOwner);
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferProxyOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _pendingProxyOwner = newOwner;
    }

    function _claimProxyOwnership(address newOwner) internal {
        require(newOwner == _pendingProxyOwner, "Claimed by wrong address");
        emit ProxyOwnershipTransferred(_proxyOwner, newOwner);
        _proxyOwner = newOwner;
        _pendingProxyOwner = address(0);
    }

}

// File: contracts/TokenProxy.sol

pragma solidity ^0.5.0;



/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract TokenProxy is OwnableProxy {
    event Upgraded(address indexed implementation);
    address public implementation;

    function upgradeTo(address _address) public onlyProxyOwner{
        require(_address != implementation, "New implementation cannot be the same as old");
        implementation = _address;
        emit Upgraded(_address);
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    
    function () external payable {
        address _impl = implementation;
        require(_impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, returndatasize, returndatasize)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
    /*
    function() external payable {
        address position = implementation;
        
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize, calldatasize)
            let result := delegatecall(gas, sload(position), ptr, calldatasize, returndatasize, returndatasize)
            returndatacopy(ptr, 0, returndatasize)

            switch result
            case 0 { revert(ptr, returndatasize) }
            default { return(ptr, returndatasize) }
        }
    }
    */

}