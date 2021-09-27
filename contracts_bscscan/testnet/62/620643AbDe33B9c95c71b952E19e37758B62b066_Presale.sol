// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./whitelist.sol";
import "./configuration.sol";

contract Presale is Configuration, Whitelist {
  constructor(IERC20 _token, IERC20 _usdt) Configuration(_token, _usdt) {}

  uint256 public ONE_BNB_TO_TOKEN = 1000 ether;

  function setOneBNBToToken(uint256 newPrice) public onlyOwner {
    ONE_BNB_TO_TOKEN = newPrice;
  }
  
  uint256 public ONE_USDT_TO_TOKEN = 1000 ether;

  function setOneUsdtToToken(uint256 newPrice) public onlyOwner {
    ONE_USDT_TO_TOKEN = newPrice;
  }
  
  bool public onlyWhitelist = false;
  
  function setOnlyWhitelist(bool _onlyWhitelist) public onlyOwner {
    onlyWhitelist = _onlyWhitelist;
  }

  function buyWithBNB() public payable {
    if (onlyWhitelist) require(whitelist[_msgSender()], "ONLY_WHITELIST");
    token.transfer(_msgSender(), msg.value * ONE_BNB_TO_TOKEN / 1e18);
  }

  function buyWithUsd(uint256 usdValue) public {
    if (onlyWhitelist) require(whitelist[_msgSender()], "ONLY_WHITELIST");
    usd.transferFrom(_msgSender(), address(this), usdValue);
    token.transfer(_msgSender(), usdValue * ONE_BNB_TO_TOKEN / 1e18);
  }
}