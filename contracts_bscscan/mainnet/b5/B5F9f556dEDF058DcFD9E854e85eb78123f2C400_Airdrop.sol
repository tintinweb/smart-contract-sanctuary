/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    address public owner;
    IERC20 private token;

    constructor(IERC20 _token) {
        owner = msg.sender;
        token = _token;
    }
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    function airdrop(address recipient, uint256 amount) external {
        require(owner == msg.sender, "-_-");

        token.transfer(recipient, amount * 10**18);
    }
}