pragma solidity ^0.4.24;
/**
Write an Ethereum smart contract that can record a user&#39;s public address as having granted permission to another user’s public address. 
Assume that the contract will eventually be used by a DApp where users can grant permission and other users can check if they have permission for some entity(Token).

Only the user calling the contract can grant permission for its public address. 
Permission can be granted for any public address.
Only the user calling the contract can check the recorded permission for its public address.
Any user can call the contract with an address to check if they have got permission from that address.
The Ethereum smart contract should maintains and record these permissions. 
Contract should expose a public method for any user to grant permission to another public address. This will accept a public address parameter and return a true if successful. 
Contract should expose a public method for any user to check if they have permission from any user. This will accept a public address parameter and return a true if user has permission. 
The contract should be deployed to an Ethereum Rinkeby network.
Happy for you to elaborate and modify the rules above with more detail if you wish as long as you have a valid reason.
 **/

 
contract Shiv{

  mapping (address => mapping (address => bool)) private allowed;

  /**
  * @dev Any user (calling this contract) to check if he has permission from another public address (user).
  * @param user The address to query permission.
  * @return Return true if found operation successful.
   **/
   
    function hasPermissionFrom( address user )    public    view    returns (bool)
  {
      require(user != address(0));
      
    return allowed[user][msg.sender] ;
  }


  /**
  * @dev Any user to grant permission to another public address. state :  _allowed[user1][user2]=true 
  * @param user The address to grant Permission to.
  * @return Return true if found operation successful.
   **/
   
  function grantPermissionTo(address user ) public returns (bool){
              require(user != address(0));

   allowed[msg.sender][user] = true;

    return true;
      }

  /**
  * @dev Any user to revoke permission from another public address. state :  _allowed[user1][user2]=false 
  * @param user The address to revoke Permission
  * @return Return true if found operation successful.
   **/
  function revokePermissionFrom(address user ) public returns (bool){
              require(user != address(0));

    allowed[msg.sender][user] = false;

    return true;
      }

}