pragma solidity 0.6.12;

/**
 * Staking Pool
 * 6,300 PAYOU Fully Locked with smart contract for 15 Days
 * 
 */


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address public pendingOwner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyPendingOwner() {
    assert(msg.sender != address(0));
    require(msg.sender == pendingOwner);
    _;
  }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    pendingOwner = _newOwner;
  }
  
  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    _transferOwnership(pendingOwner);
    pendingOwner = address(0);
  }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface token {
    function transfer(address, uint) external returns (bool);
}

contract TokenLock is Ownable {
    
    // enter beneficiary checksum address here
    address public constant beneficiary = 0xCa868B9a83fF6D5a3581B7245faF4e67b35c9542;

    
    // enter unlock timestamp in seconds here
    uint public constant unlockTime = 1604275199;

    function isUnlocked() public view returns (bool) {
        return now > unlockTime;
    }
    
    function claim(address _tokenAddr, uint _amount) public onlyOwner {
        require(isUnlocked());
        token(_tokenAddr).transfer(beneficiary, _amount);
    }
}