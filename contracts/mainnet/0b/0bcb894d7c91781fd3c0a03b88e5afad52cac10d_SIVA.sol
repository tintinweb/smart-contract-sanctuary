/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: MIT

// SIVA Pre-Sale Contract | T3M

pragma solidity ^0.7.6;

contract SIVA {
    address payable public controller;
    uint256 public totalRaised;
    mapping (address => uint256) private _amountSent;
    uint256 public deadline;
    bool private status;
    uint256 public salePriceETH;
    address private SIVAcontract;
    
    constructor() payable {
        controller = payable(msg.sender);
        deadline = 1625943600;
        status = true;
        salePriceETH = 153531709095794;
        SIVAcontract = 0xFD18E5BCfbc2f898ab00b430C2059f1389e1B55a;
    }

    function buySIVA() public payable {
        require (block.timestamp < deadline, "Pre-Sale no Longer Active.");
        totalRaised += msg.value;
        _amountSent[msg.sender] += msg.value;
    }

    function conclude() public {
        require (msg.sender == controller, "Unable.");
        uint amount = address(this).balance;
        (bool success,) = controller.call{value: amount}("");
        require(success, "Failed to send Ether");
        status = false;
    }
    
    function presaleBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function userETH(address _useraddress) public view returns (uint256) {
        return _amountSent[_useraddress];
    }
    
    function userShare(address _useraddress) public view returns (uint256) {
        uint256 tokens = _amountSent[_useraddress] / salePriceETH * 10 ** 18;
        return tokens;
    }
    
    function adjustDeadline(uint256 _deadline) public virtual returns (bool) {
        require (msg.sender == controller, "Unable.");
        deadline = _deadline;
        return true;
    }
    
    function adjustPrice(uint256 _price) public virtual returns (bool) {
        require (msg.sender == controller, "Unable.");
        salePriceETH = _price;
        return true;
    }

    function isLive() public view returns (bool) {
        return status;
    }
}