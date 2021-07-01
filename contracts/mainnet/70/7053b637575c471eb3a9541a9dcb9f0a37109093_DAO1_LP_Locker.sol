/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: BSD-3-Clause
/**
 * Vaults Reward Fund Locked till 20th Oct 2020 
 * Farming vault token will transfer on Vaults smart contrcat after unlock which will be without withdrawal permission
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
    constructor ()  {
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
    modifier onlyCaller() {
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
  function transferOwnership(address _newOwner) public onlyCaller {
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
contract DAO1_LP_Locker is Ownable {
    address public constant beneficiary = 0x920ae8A9c224d554d9642292670a684a1466ED16; // DAO1 Token Owner address
    // unlocks on Dec 07 2022
    uint public constant unlockTime = 1670351400;
    function isUnlocked() public view returns (bool) {
        return block.timestamp > unlockTime;
    }
    function claim(address _tokenAddr, uint _amount) public onlyCaller {
        require(isUnlocked(), "Cannot transfer tokens while locked.");
        token(_tokenAddr).transfer(beneficiary, _amount);
    }
}