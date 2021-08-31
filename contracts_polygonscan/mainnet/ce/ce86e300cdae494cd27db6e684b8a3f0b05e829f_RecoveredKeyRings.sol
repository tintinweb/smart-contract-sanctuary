/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


struct Pair {
	address smartWallet;
	address keyRing;
}


interface RecoveredKeyRingsInterface {
	function get(address[] calldata wallets) external view returns (address[] memory keyRings);
	function push(Pair[] calldata pairs) external returns (bool);
	function lock() external returns (bool);
	function pop() external returns (address keyRing);
}


contract RecoveredKeyRings is RecoveredKeyRingsInterface {
	bool public locked;
	address private immutable _owner;
	mapping(address => address) private _keyRingsBySmartWallet;

	constructor() {
		_owner = tx.origin;
		locked = false;
	}

	function get(address[] calldata wallets) external view override returns (address[] memory keyRings) {
		keyRings = new address[](wallets.length);

		for (uint256 i = 0; i < wallets.length; i++) {
			keyRings[i] = _keyRingsBySmartWallet[wallets[i]];
		}
	}

	function push(Pair[] calldata pairs) external override returns (bool) {
		require(!locked, "locked");

		require(msg.sender == _owner, "only owner");

		for (uint256 i = 0; i < pairs.length; i++) {
			Pair memory pair = pairs[i];
			_keyRingsBySmartWallet[pair.smartWallet] = pair.keyRing;
		}

		return true;
	}

	function lock() external override returns (bool) {
		require(!locked, "already locked");

		require(msg.sender == _owner, "only owner");

		locked = true;

		return locked;
	}

	function pop() external override returns (address keyRing) {
		keyRing = _keyRingsBySmartWallet[msg.sender];

		delete _keyRingsBySmartWallet[msg.sender];
	}
}