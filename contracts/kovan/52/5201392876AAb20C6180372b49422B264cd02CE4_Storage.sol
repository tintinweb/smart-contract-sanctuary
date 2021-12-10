/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract OwnableX {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /*
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/* @title ControlledAccess
 * @dev The ControlledAccess contract allows function to be restricted to users
 * that possess a signed authorization from the owner of the contract. This signed
 * message includes the user to give permission to and the contract address to prevent
 * reusing the same authorization message on different contract with same owner. 
 */

contract ControlledAccess is OwnableX {
    
    // mapping(address => bool) whitelisted;

    // function addValidAccess() {
    //     //add to mapping
    // }

   /* 
    * @dev Requires msg.sender to have valid access message.
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    */
    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) 
    {
        require( isValidAccessMessage(msg.sender,_v,_r,_s), "CHAL BHAG YEH SCHEME TERE LIYE NAI HAI");
        _;
    }
 
    /* 
    * @dev Verifies if message was signed by owner to give access to _add for this contract.
    *      Assumes Geth signature prefix.
    * @param _add Address of agent with access
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    * @return Validity of access message for a given address.
    */
    function isValidAccessMessage(
        address _add,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s) 
        view public returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(this, _add));
        return owner == ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            _v,
            _r,
            _s
        );
    }
}

contract Storage is ControlledAccess {
    
    uint256 public storedValue = 0;
    
    function store(uint256 _num, uint8 _v, bytes32 _r, bytes32 _s)
        onlyValidAccess(_v,_r,_s)
        public
    {
        storedValue = _num;
    }
    
}