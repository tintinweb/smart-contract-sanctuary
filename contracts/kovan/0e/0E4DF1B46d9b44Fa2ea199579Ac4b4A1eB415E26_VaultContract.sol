/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: VaultContract.sol

contract VaultContract {

  struct Vault {
    address creator;
    string name;
    address[] users;
    uint256 amount;
  }

  uint256 totalVaults;
  
  mapping(uint256 => Vault) public vaults;
  mapping(address => uint256) public balance;

  event VaultDistribution
  (
    uint256 vaultId,
    uint256 amount
  );

  constructor() public {
  }

  function createVault
  (
    string memory _name, 
    address[] memory _users, 
    uint256 _amount
  ) public 
    returns (uint256 vaultId) 
  {
    Vault storage vault = vaults[totalVaults];
 
    vault.creator = msg.sender;
    vault.name = _name;
    vault.users = _users;
    vault.amount = _amount;

    totalVaults += 1;

    return totalVaults - 1;
  }

  function addAmount
  (
    uint256 _vaultId, 
    uint256 _amount
  ) 
    public 
  {
    Vault storage vault = vaults[_vaultId];
    require(msg.sender == vault.creator, "not creator");
    vault.amount = _amount;
  }

  function distribute
  (
    uint256 _vaultId
  ) 
    public 
  {
    Vault storage vault = vaults[_vaultId];
    require(vault.amount > 0, "0 amount");
    uint256 _amountPerUser = vault.amount / vault.users.length;
    for (uint8 i; i < vault.users.length; i++) {
      vault.amount -= _amountPerUser;
      balance[vault.users[i]] = _amountPerUser;
    }
    emit VaultDistribution(_vaultId, _amountPerUser * vault.users.length);
  }

}