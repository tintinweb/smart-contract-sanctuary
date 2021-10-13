/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

contract Context {
    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
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
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface TimeLock {
    function earn(address strategy) external;
}

contract EarnCaller is Ownable {
    
    address public timeLockAddress;
    
    event changeTimeLock(address oldAddress,address newAddress);
    
    constructor(address newTimeLockAddress) public {
        timeLockAddress = newTimeLockAddress;
        emit changeTimeLock(address(0),timeLockAddress);
    }
    
    function changeTimeLockAddress(address newTimeLock) external onlyOwner {
        require(newTimeLock != address(0),"!!NEW TIMELOCK ADDRESS CANNOT BE ZERO");
        address old = timeLockAddress;
        timeLockAddress = newTimeLock;
        emit changeTimeLock(old,timeLockAddress);
    }
    
    function callEarn(address strategy) public onlyOwner {
        TimeLock(timeLockAddress).earn(strategy);
    }
    
    function callEarns(address[] memory strategies) public onlyOwner {
        
        for(uint256 i = 0 ; i < strategies.length ; i++){
        
            address strategy = strategies[i];
            callEarn(strategy);
            
        }
        
    }
    
}