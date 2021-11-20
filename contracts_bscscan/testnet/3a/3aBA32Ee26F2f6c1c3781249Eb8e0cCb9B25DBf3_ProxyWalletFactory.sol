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

import "./ProxyWallet.sol";
import "./ProxyWalletCache.sol";

// ProxyWalletFactory
// This factory deploys new proxy instances through build()
// Deployed proxy addresses are logged
contract ProxyWalletFactory {
  event LogCreated(address indexed _sender, address indexed _owner, address _proxy, address _cache);
  mapping(address => bool) public isProxy;
  ProxyWalletCache public cache;

  constructor() public {
    cache = new ProxyWalletCache();
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable _proxy) {
    _proxy = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address _owner) public returns (address payable _proxy) {
    _proxy = address(new ProxyWallet(address(cache)));
    emit LogCreated(msg.sender, _owner, address(_proxy), address(cache));
    ProxyWallet(_proxy).setOwner(_owner);
    isProxy[_proxy] = true;
  }
}