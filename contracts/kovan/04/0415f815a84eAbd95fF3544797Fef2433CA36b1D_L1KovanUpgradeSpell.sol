// SPDX-License-Identifier: AGPL-3.0-or-later
// @unsupported: ovm
// Copyright (C) 2021 Dai Foundation
pragma solidity >=0.7.6;

interface EscrowLike {
  function approve(address token, address spender, uint256 value) external;
}

interface GovernanceRelay {
  function relay(address target, bytes calldata targetData, uint32 l2gas) external;
}

interface L2KovanUpgradeSpellLike {
  function upgradeBridge() external;
}

contract L1KovanUpgradeSpell {

  EscrowLike immutable public escrow;
  address immutable public l1Dai;
  address immutable public newBridge;
  GovernanceRelay immutable public govRelay;
  address immutable public l2Spell;
  uint32 immutable public l2Gas;

  constructor(address _escrow, address _l1Dai, address _newBridge, address _govRelay, address _l2Spell, uint32 _l2Gas) {
    escrow = EscrowLike(_escrow);
    l1Dai = _l1Dai;
    newBridge = _newBridge;
    govRelay = GovernanceRelay(_govRelay);
    l2Spell = _l2Spell;
    l2Gas = _l2Gas;
  }

  function upgradeBridge() external {
    bytes memory _l2Data = abi.encodeWithSelector(L2KovanUpgradeSpellLike.upgradeBridge.selector);

    escrow.approve(l1Dai, newBridge, type(uint256).max);
    govRelay.relay(l2Spell, _l2Data, l2Gas);

  }

}

