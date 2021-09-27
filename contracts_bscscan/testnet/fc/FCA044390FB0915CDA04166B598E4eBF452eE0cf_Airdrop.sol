// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./whitelist.sol";
import "./configuration.sol";

contract Airdrop is Configuration, Whitelist {
  constructor(IERC20 _token, IERC20 _usdt) Configuration(_token, _usdt) {}

  uint256 public TOKEN_AMOUNT_FOR_EACH_CLAIM = 1000 ether;

  function setTokenValueForEachClaim(uint256 newValue) public onlyOwner {
    TOKEN_AMOUNT_FOR_EACH_CLAIM = newValue;
  }

  mapping(address => bool) public claimed;
  
  function claim() public {
    require(!claimed[_msgSender()], "ALREADY_CLAIMED");
    require(whitelist[_msgSender()], "ONLY_WHITELIST");
    token.transfer(_msgSender(), TOKEN_AMOUNT_FOR_EACH_CLAIM);
  }
  
  function setClaimed(address[] memory accounts, bool newClaimed) public onlyOwner {
    uint256 length = accounts.length;
    for (uint256 index = 0; index < length; index++) {
      claimed[accounts[index]] = newClaimed;
    }
  }
}