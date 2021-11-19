/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: None

pragma solidity 0.6.12;

contract BUSD_FACTOR_REFUND {

  address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  IBEP20 token;
  address payable von;
  mapping(address => uint256) public refundBUSD;
  mapping(address => uint256) public refundedBUSD;

  constructor() public {
    token = IBEP20(busd);
    von = msg.sender;
  }
  function addRefunds(uint256 amt) public payable {
    token.transferFrom(msg.sender, address(this), amt);
  }
  function setRefunds(address[] memory addrs, uint256[] memory amts) public {
    require(msg.sender == von);
    for(uint256 i = 0; i < addrs.length; i++) {
      uint256 amt = amts[i] * 1e18;
      refundBUSD[addrs[i]] = amt;
    }
  }
  function checkRefund() public view returns (uint256) {
    return refundBUSD[msg.sender];
  }
function checkRefunded() public view returns (uint256) {
    return refundedBUSD[msg.sender];
  }
  function refund() public payable {
    uint256 amt = refundBUSD[msg.sender];
    require(amt > 0);
    require(bal() >= amt);
    refundedBUSD[msg.sender] = refundedBUSD[msg.sender] + amt;
    token.transfer(msg.sender, amt);
  }
  function exit() public payable {
    require(msg.sender == von);
    token.transfer(von, bal());
  }
  function bal() internal view returns (uint256) {
    return token.balanceOf(address(this));
  }
}



interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}