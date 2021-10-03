// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./configuration.sol";

contract Airdrop is Configuration {
  constructor(IERC20 _token, IERC20 _usd) Configuration(_token, _usd) {}
  
  function claim() public {
    uint256 prize = prizes[_msgSender()];
    require(prize > 0, "NO_PRIZE");
    token.transfer(_msgSender(), prize);
    prizes[_msgSender()] = 0;
  }

  struct PrizeConfig {
    address account;
    uint256 value;
  }

  mapping(address => uint256) public prizes;

  function setClaimed(PrizeConfig[] memory prizeConfigs) public onlyOwner {
    uint256 length = prizeConfigs.length;
    for (uint256 index = 0; index < length; index++) {
      prizes[prizeConfigs[index].account] = prizeConfigs[index].value;
    }
  }
}