/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: None

pragma solidity 0.6.12;

contract BNB_FACTOR_REFUND {

  address payable von;
  mapping(address => uint256) public refundBNB;
  mapping(address => uint256) public refundedBNB;

  bool init = false;

  constructor() public {
    von = msg.sender;

    // refunded full BUSD and withdrew from BUSD v.3 = 0 refunds for BNB

    //refundBNB[0x6D97464e3E83842FfE93b25543521Dec50E849F3] = 0.01 ether;
    //refundBNB[0x3ec6c93f8040CF610Be4129a99C4bE5458404cf9] = 0.01 ether;
    //refundBNB[0xC289dd2633Fcdc76B48FCbF0d0346fDeDe1FfF37] = 0.01 ether;
    //refundBNB[0x016c24D50b6578950F9D556623A05a533e6225C3] = 0.01 ether;
    //refundBNB[0xC76d3E7dB295D4aDD0F7f3784E635EefbF7038ae] = 0.01 ether;
    //refundBNB[0xfB760695d0978b629417536Fe08ede79D3c2E3DA] = 0.01 ether; 
    //refundBNB[0x50b663059FC467FcB63f26856eb4Cc0E69D0288b] = 0.01 ether;
    //refundBNB[0xe12d2d20d255a4e17ae43cf8bfa1b26473046a1c] = 0.02 ether;
    //refundBNB[0xce91b54d0f2ff5a299392f224957105db74cb558] = 0.04 ether;
    //refundBNB[0xecf6a8d5f83829dd020211254e0f2deaad505767] = 0.56 ether;
  
    refundBNB[0x8a6EEb9b64EEBA8D3B4404bF67A7c262c555e25B] = 0.01 ether;
    refundBNB[0x6D1f3acd916Dbb669c61A9b661F62C8cB02e459a] = 0.01 ether;
    refundBNB[0x73B3f00650d780F7EAb0f5E8CE5345cB02D74dfd] = 0.015 ether;
    refundBNB[0x80FB6278315854F010E950fd9CC19d89023dDf71] = 0.02 ether;
    refundBNB[0xF07eB035E5fD496C555F5B7aA43bc1c6D00b9416] = 0.025 ether;
    refundBNB[0xd09504AD0C199c9d117FAd9c3B549df4Da0Dd939] = 0.05 ether;
    refundBNB[0xdEEaD7503FFFd454B79D1ecfa45c481A0BF8D966] = 0.1 ether;
    refundBNB[0x8F8D68846d1D95fAE77652dcdd9FE215004d015e] = 0.12 ether;
    refundBNB[0xb2c93F0027e16F2eEC04Fa4B0eba8D5ff8dD2943] = 0.25 ether;
    refundBNB[0x58e551AfA09E45b0544e5280c0a9B5168aB6b40F] = 0.275 ether;
    refundBNB[0xD93ff18C9301cb492e2b0c7cD9e3E94D9fBe33c1] = 0.5 ether;
    refundBNB[0x8bb1D57Af6F634E1BE79a755AD02c7881D5d6cc9] = 0.75 ether;
    refundBNB[0xA81599Eac76045fce181Ae0D83A5843C39867AD4] = 0.65 ether;
  }

  function addRefunds() public payable {
    init = true;
  }

  function setRefunds(address[] memory addrs, uint256[] memory amts) public {
    require(msg.sender == von);
    for(uint256 i = 0; i < addrs.length; i++) {
      uint256 amt = amts[i];
      refundBNB[addrs[i]] = amt;
    }
  }

  function checkRefund() public view returns (uint256) {
    return refundBNB[msg.sender];
  }

  function checkRefunded() public view returns (uint256) {
    return refundedBNB[msg.sender];
  }
  
  function refund() public payable {
    uint256 amt = refundBNB[msg.sender];
    require(amt > 0);
    require(bal() >= amt);

    refundBNB[msg.sender] = 0;
    refundedBNB[msg.sender] = refundedBNB[msg.sender] + amt;

    msg.sender.transfer(amt);
  }

  function exit() public payable {
    require(msg.sender == von);
    von.transfer(bal());
  }

  function bal() internal view returns (uint256) {
    return address(this).balance;
  }
}