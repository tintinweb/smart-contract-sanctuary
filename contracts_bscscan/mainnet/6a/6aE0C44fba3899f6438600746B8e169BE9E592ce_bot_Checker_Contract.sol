// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "./Ownable.sol";

contract bot_Checker_Contract is Ownable {
  uint256 public antiWhaleTime;
  mapping(address => bool) private _botAddresses;
  mapping(address => bool) private _authorizedAddresses;

  modifier onlyAuthorizedAccount() {
  require(_authorizedAddresses[msg.sender]);
		_;
	}

  constructor() {
      _authorizedAddresses[msg.sender] = true;
      antiWhaleTime = block.timestamp + 6 * 60 * 60;
  }

  function addToBotAddresses(address [] calldata dst) public onlyAuthorizedAccount {
		for (uint i; i < dst.length; i++) {
           _botAddresses[dst[i]] = true;
        }
	}

  function removeFromBotAddresses(address [] calldata dst) public onlyAuthorizedAccount {
		for (uint i; i < dst.length; i++) {
           _botAddresses[dst[i]] = false;
        }
	}

  function botCheck(address from, address to) onlyAuthorizedAccount public view returns (bool) {
      if(_botAddresses[from] || _botAddresses[to])
        return true;
      else
        return false;
  }

  function botAddresses(address account) onlyAuthorizedAccount public view returns (bool) {
      return _botAddresses[account];
  }

  function grantPermission(address account) public onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = true;
	}

	function revokePermission(address account) public onlyOwner {
		require(account != address(0));
		_authorizedAddresses[account] = false;
	}
}