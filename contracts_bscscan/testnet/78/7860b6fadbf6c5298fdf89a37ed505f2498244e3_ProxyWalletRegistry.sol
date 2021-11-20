// SPDX-License-Identifier: AGPL-3.0-or-later
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.12;

import "./OwnableUpgradeable.sol";

import "./ProxyWallet.sol";
import "./ProxyWalletFactory.sol";

// This Registry deploys new proxy instances through ProxyWalletFactory.build(address) and keeps a registry of owner => proxy
contract ProxyWalletRegistry is OwnableUpgradeable {
  mapping(address => ProxyWallet) public proxies;
  ProxyWalletFactory factory;

  // --- Init ---
  function initialize(address _factory) external initializer {
    OwnableUpgradeable.__Ownable_init();

    factory = ProxyWalletFactory(_factory);
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() external returns (address payable _proxy) {
    _proxy = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address owner) public returns (address payable _proxy) {
    require(proxies[owner] == ProxyWallet(0)); // Not allow new proxy if the user already has one
    _proxy = factory.build(owner);
    proxies[owner] = ProxyWallet(_proxy);
  }

  function setOwner(address _newOwner) external {
    require(proxies[_newOwner] == ProxyWallet(0));
    ProxyWallet _proxy = proxies[msg.sender];
    require(_proxy.owner() == _newOwner);
    proxies[_newOwner] = _proxy;
    proxies[msg.sender] = ProxyWallet(0);
  }
}