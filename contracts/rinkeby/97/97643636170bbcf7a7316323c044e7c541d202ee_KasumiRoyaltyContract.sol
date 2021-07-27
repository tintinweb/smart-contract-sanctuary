/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// File: contracts/KasumiRoyaltyContract.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract KasumiRoyaltyContract {  
  struct Shareholder {
    uint share;
    address payable shareholder_address;
  }

  // keep track of how many shares an individual shareholder owns
  // in this model the shareholders cannot change
  Shareholder[] public shareholders;

  event Payout(address indexed _to, uint _value);

  constructor(uint[] memory _shares, address payable[] memory _shareholder_addresses) {
    // there should be at least one shareholder
    assert(_shareholder_addresses.length > 0);

    // the _shares and _shareholder_addresses provided should be the same length
    assert(_shares.length == _shareholder_addresses.length);

    // keep track of the total number of shares
    uint _total_number_of_shares = 0;
    for (uint i = 0; i < _shares.length; i++) {
      _total_number_of_shares += _shares[i];
      Shareholder memory x = Shareholder({share: _shares[i], shareholder_address: _shareholder_addresses[i]});
      shareholders.push(x);
    }

    // there should be exactly 10,000 shares, this amount is used to calculate payouts
    assert(_total_number_of_shares == 10000);
  }

  // once the royalty contract has a balance, call this to payout to the shareholders
  function payout() public payable returns (bool) {
    // the balance must be greater than 0
    assert(address(this).balance > 0);

    // get the balance of ETH held by the royalty contract
    uint balance = address(this).balance;
    for (uint i = 0; i < shareholders.length; i++) {

      // 10,000 shares represents 100.00% ownership
      uint amount = balance * shareholders[i].share / 10000;

      // https://solidity-by-example.org/sending-ether/
      // this considered the safest way to send ETH
      (bool success, ) = shareholders[i].shareholder_address.call{value: amount}("");

      // it should not fail
      require(success, "Transfer failed.");

      emit Payout(shareholders[i].shareholder_address, amount);
    }
    return true;
  }

  // https://solidity-by-example.org/sending-ether/
  // receive is called when msg.data is empty.
  receive() external payable {}

  // https://solidity-by-example.org/sending-ether/
  // fallback function is called when msg.data is not empty.
  fallback() external payable {}
}