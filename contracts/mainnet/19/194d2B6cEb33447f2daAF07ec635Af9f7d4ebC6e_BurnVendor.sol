/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT
/*
     _    _    _ _        ____                                _
    / \  | | _(_) |_ __ _|  _ \ ___  ___  ___ _   _  ___   __| | ___   __ _
   / _ \ | |/ / | __/ _` | |_) / _ \/ __|/ __| | | |/ _ \ / _` |/ _ \ / _` |
  / ___ \|   <| | || (_| |  _ <  __/\__ \ (__| |_| |  __/| (_| | (_) | (_| |
 /_/   \_\_|\_\_|\__\__,_|_| \_\___||___/\___|\__,_|\___(_)__,_|\___/ \__, |
                                                                      |___/

 🐕 AkitaRescue.dog

 🏗 scaffold-eth

 🖨 https://github.com/austintgriffith/scaffold-eth/tree/akita-rescue-dog

 ⚠️ Warning: not formally audited!

 👨🏻‍🔬 @austingriffith

*/

interface TOKEN {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BurnVendor {

  TOKEN public akitaToken;

  uint256 constant public tokensPerEth = 2038370000 * 70 / 100;// 30% discounted from 2038370000?

  uint256 constant public burnMultiplier = 10;

  address payable constant public gitcoinAddress = payable(0x1048EcC822C1E13aC327De3C11F160CAF10DB86C);//edited to be my SAFE

  address constant public burnAddress = 0xDead000000000000000000000000000000000d06;

  constructor(address akitaAddress) {
    akitaToken = TOKEN(akitaAddress);
  }

  receive() external payable {
    buy();
  }

  event Buy(address who, uint256 value, uint256 amount, uint256 burn);

  function buy() public payable {

    uint256 amountOfTokensToBuy = msg.value * tokensPerEth;

    uint256 amountOfTokensToBurn = amountOfTokensToBuy * burnMultiplier;

    akitaToken.transferFrom(gitcoinAddress, burnAddress, amountOfTokensToBurn);

    akitaToken.transferFrom(gitcoinAddress, msg.sender, amountOfTokensToBuy);

    (bool sent, ) = gitcoinAddress.call{value: msg.value}("");
    require(sent, "Failed to send ETH to Gitcoin Multisig");

    emit Buy(msg.sender, msg.value, amountOfTokensToBuy, amountOfTokensToBurn);

  }

}