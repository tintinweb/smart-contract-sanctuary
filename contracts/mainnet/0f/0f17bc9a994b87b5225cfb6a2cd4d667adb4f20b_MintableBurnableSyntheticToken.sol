// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
import '../../common/implementation/MintableBurnableERC20.sol';
import '../../common/implementation/Lockable.sol';

contract MintableBurnableSyntheticToken is MintableBurnableERC20, Lockable {
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  )
    public
    MintableBurnableERC20(tokenName, tokenSymbol, tokenDecimals)
    nonReentrant()
  {}

  function addMinter(address account) public override nonReentrant() {
    super.addMinter(account);
  }

  function addBurner(address account) public override nonReentrant() {
    super.addBurner(account);
  }

  function addAdmin(address account) public override nonReentrant() {
    super.addAdmin(account);
  }

  function addAdminAndMinterAndBurner(address account)
    public
    override
    nonReentrant()
  {
    super.addAdminAndMinterAndBurner(account);
  }

  function renounceMinter() public override nonReentrant() {
    super.renounceMinter();
  }

  function renounceBurner() public override nonReentrant() {
    super.renounceBurner();
  }

  function renounceAdmin() public override nonReentrant() {
    super.renounceAdmin();
  }

  function renounceAdminAndMinterAndBurner() public override nonReentrant() {
    super.renounceAdminAndMinterAndBurner();
  }

  function isMinter(address account)
    public
    view
    nonReentrantView()
    returns (bool)
  {
    return hasRole(MINTER_ROLE, account);
  }

  function isBurner(address account)
    public
    view
    nonReentrantView()
    returns (bool)
  {
    return hasRole(BURNER_ROLE, account);
  }

  function isAdmin(address account)
    public
    view
    nonReentrantView()
    returns (bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  function getAdminMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function getMinterMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(MINTER_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(MINTER_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  function getBurnerMembers() external view returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(BURNER_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(BURNER_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }
}