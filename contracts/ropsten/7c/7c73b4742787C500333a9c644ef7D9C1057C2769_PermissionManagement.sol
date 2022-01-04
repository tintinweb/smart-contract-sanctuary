// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * Author: Kumar Abhirup (kumareth)
 * Version: 1.0.1
 * Compiles best with: 0.7.6

 * Many contracts have ownerOnly functions, 
 * but I believe it's safer to have multiple owner addresses
 * to fallback to, in case you lose one.

 * You can inherit this PermissionManagement contract
 * to let multiple people do admin operations on your contract effectively.

 * You can add & remove admins and moderators.
 * You can transfer ownership (basically you can change the founder).
 * You can change the beneficiary (the prime payable wallet) as well.

 * You can also ban & unban addresses,
 * to restrict certain features on your contract for certain addresses.

 * Use modifiers like "founderOnly", "adminOnly", "moderatorOnly" & "adhereToBan"
 * in your contract to put the permissions to use.

 * Code: https://ipfs.io/ipfs/QmbVZevdhRwXfoeVti9GLo7tESUrSg7b2psHxugz9Dx1cg
 * IPFS Metadata: https://ipfs.io/ipfs/Qmdh8DC3FHxCPEVEvhXzZWMHZ8y3Dbavzvtib7s7rEBmcs

 * Access the Contract on the Ethereum Ropsten Testnet Network
 * https://ropsten.etherscan.io/address/0xceaef9490f7516914c056bc5902633e76790a999
 */

/// @title PermissionManagement Contract
/// @author [email protected]
/// @notice Like Openzepplin Ownable, but with many Admins and Moderators.
/// @dev Like Openzepplin Ownable, but with many Admins and Moderators.
/// In Relayshun context, It's recommended that all the admins except the Market Contract give up their admin perms later down the road, or maybe delegate those powers to another transparent contract to ensure trust.
contract PermissionManagement {
  address public founder = msg.sender;
  address payable public beneficiary = payable(msg.sender);

  mapping(address => bool) public admins;
  mapping(address => bool) public moderators;
  mapping(address => bool) public bannedAddresses;

  enum RoleChange { 
    MADE_FOUNDER, 
    MADE_BENEFICIARY, 
    PROMOTED_TO_ADMIN, 
    PROMOTED_TO_MODERATOR, 
    DEMOTED_TO_MODERATOR, 
    KICKED_FROM_TEAM, 
    BANNED, 
    UNBANNED 
  }

  event PermissionsModified(address _address, RoleChange _roleChange);

  constructor (
    address[] memory _admins, 
    address[] memory _moderators
  ) {
    // require more admins for safety and backup
    require(_admins.length > 0, "Admin addresses not provided");

    // make founder the admin and moderator
    admins[founder] = true;
    moderators[founder] = true;
    emit PermissionsModified(founder, RoleChange.MADE_FOUNDER);

    // give admin privileges, and also make admins moderators.
    for (uint256 i = 0; i < _admins.length; i++) {
      admins[_admins[i]] = true;
      moderators[_admins[i]] = true;
      emit PermissionsModified(_admins[i], RoleChange.PROMOTED_TO_ADMIN);
    }

    // give moderator privileges
    for (uint256 i = 0; i < _moderators.length; i++) {
      moderators[_moderators[i]] = true;
      emit PermissionsModified(_moderators[i], RoleChange.PROMOTED_TO_MODERATOR);
    }
  }

  modifier founderOnly() {
    require(
      msg.sender == founder,
      "This function is restricted to the contract's founder."
    );
    _;
  }

  modifier adminOnly() {
    require(
      admins[msg.sender] == true,
      "This function is restricted to the contract's admins."
    );
    _;
  }

  modifier moderatorOnly() {
    require(
      moderators[msg.sender] == true,
      "This function is restricted to the contract's moderators."
    );
    _;
  }

  modifier adhereToBan() {
    require(
      bannedAddresses[msg.sender] != true,
      "You are banned from accessing this function in the contract."
    );
    _;
  }

  modifier addressMustNotBeFounder(address _address) {
    require(
      _address != founder,
      "Address must not be the Founder's address."
    );
    _;
  }

  modifier addressMustNotBeAdmin(address _address) {
    require(
      admins[_address] != true,
      "Address must not be an Admin's address."
    );
    _;
  }

  modifier addressMustNotBeModerator(address _address) {
    require(
      moderators[_address] != true,
      "Address must not be a Moderator's address."
    );
    _;
  }

  modifier addressMustNotBeBeneficiary(address _address) {
    require(
      _address != beneficiary,
      "Address must not be a Beneficiary's address."
    );
    _;
  }

  function founderOnlyMethod(address _address) public view {
    require(
      _address == founder,
      "This function is restricted to the contract's founder."
    );
  }

  function adminOnlyMethod(address _address) public view {
    require(
      admins[_address] == true,
      "This function is restricted to the contract's admins."
    );
  }

  function moderatorOnlyMethod(address _address) public view {
    require(
      moderators[_address] == true,
      "This function is restricted to the contract's moderators."
    );
  }

  function adhereToBanMethod(address _address) public view {
    require(
      bannedAddresses[_address] != true,
      "You are banned from accessing this function in the contract."
    );
  }

  function addressMustNotBeFounderMethod(address _address) public view {
    require(
      _address != founder,
      "Address must not be the Founder's address."
    );
  }

  function addressMustNotBeAdminMethod(address _address) public view {
    require(
      admins[_address] != true,
      "Address must not be an Admin's address."
    );
  }

  function addressMustNotBeModeratorMethod(address _address) public view {
    require(
      moderators[_address] != true,
      "Address must not be a Moderator's address."
    );
  }

  function addressMustNotBeBeneficiaryMethod(address _address) public view {
    require(
      _address != beneficiary,
      "Address must not be a Beneficiary's address."
    );
  }

  function transferFoundership(address payable _founder) 
    public 
    founderOnly
    addressMustNotBeFounder(_founder)
    returns(address)
  {
    require(_founder != msg.sender, "You cant make yourself the founder.");
    
    founder = _founder;
    admins[_founder] = true;
    moderators[_founder] = true;

    emit PermissionsModified(_founder, RoleChange.MADE_FOUNDER);

    return founder;
  }

  function changeBeneficiary(address payable _beneficiary) 
    public
    adminOnly
    returns(address)
  {
    require(_beneficiary != msg.sender, "You cant make yourself the beneficiary.");
    
    beneficiary = _beneficiary;
    emit PermissionsModified(_beneficiary, RoleChange.MADE_BENEFICIARY);

    return beneficiary;
  }

  function addAdmin(address _admin) 
    public 
    adminOnly
    returns(address) 
  {
    admins[_admin] = true;
    moderators[_admin] = true;
    emit PermissionsModified(_admin, RoleChange.PROMOTED_TO_ADMIN);
    return _admin;
  }

  function removeAdmin(address _admin) 
    public 
    adminOnly
    addressMustNotBeFounder(_admin)
    returns(address) 
  {
    require(_admin != msg.sender, "You cant remove yourself from the admin role.");
    delete admins[_admin];
    emit PermissionsModified(_admin, RoleChange.DEMOTED_TO_MODERATOR);
    return _admin;
  }

  function addModerator(address _moderator) 
    public 
    adminOnly
    returns(address) 
  {
    moderators[_moderator] = true;
    emit PermissionsModified(_moderator, RoleChange.PROMOTED_TO_MODERATOR);
    return _moderator;
  }

  function removeModerator(address _moderator) 
    public 
    adminOnly
    addressMustNotBeFounder(_moderator)
    addressMustNotBeAdmin(_moderator)
    returns(address) 
  {
    require(_moderator != msg.sender, "You cant remove yourself from the moderator role.");
    delete moderators[_moderator];
    emit PermissionsModified(_moderator, RoleChange.KICKED_FROM_TEAM);
    return _moderator;
  }

  function ban(address _ban) 
    public 
    moderatorOnly
    addressMustNotBeFounder(_ban)
    addressMustNotBeAdmin(_ban)
    addressMustNotBeModerator(_ban)
    addressMustNotBeBeneficiary(_ban)
    returns(address) 
  {
    bannedAddresses[_ban] = true;
    emit PermissionsModified(_ban, RoleChange.BANNED);
    return _ban;
  }

  function unban(address _ban) 
    public 
    moderatorOnly
    returns(address) 
  {
    bannedAddresses[_ban] = false;
    emit PermissionsModified(_ban, RoleChange.UNBANNED);
    return _ban;
  }
}