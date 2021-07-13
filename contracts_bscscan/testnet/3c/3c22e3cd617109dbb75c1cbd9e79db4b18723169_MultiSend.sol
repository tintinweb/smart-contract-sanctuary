/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
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
contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract MultiSend is Context, Ownable {

    address SERVICE_ADDRESS;
    uint256 SERVICE_COST = 0.04 * 10**18;

    constructor() {
        SERVICE_ADDRESS = address(0xbe44ddE2875D023D8de11518b4b4e351d6A7bC58);
    }

   // Simple transfer function, just wraps the normal transfer
    function transfer(address token, address _to, uint256 _value) public payable virtual returns (bool) {
      IERC20(token).transfer(_to, _value);
      payable(SERVICE_ADDRESS).transfer(SERVICE_COST);
      return true;
    }

    function _estFeeTransferBulk(uint256 noOfTxs) internal view returns (uint256) {
       if(noOfTxs < 5) {
           return SERVICE_COST * 1;
       }
       return SERVICE_COST * 10;
    }

   // The same as the simple transfer function
   // But for multiple transfer instructions
   function transferBulk(address token, address[] memory _tos, uint256[] memory _values, uint256 serviceCost) public virtual returns(bool) {
      require(_estFeeTransferBulk(_tos.length) < (serviceCost), "MultiSend Bulk: Service cost is too low");
      
      for(uint256 i=0; i < _tos.length; i++) {
         // If one fails, revert the tx, including previous transfers
         require(!IERC20(token).transfer(_tos[i], _values[i]), "MultiSend Bulk: Transfer failed");
      }
      
      payable(SERVICE_ADDRESS).transfer(serviceCost);
      return true;
   }
   
   function estFeeTransferBulk(uint256 noOfTxs) external view returns(uint256) {
      return _estFeeTransferBulk(noOfTxs);
   }
   
   
   function setService(address newSerAdd) public virtual onlyOwner returns (bool) {
      SERVICE_ADDRESS = newSerAdd;
      return true;
   }
}