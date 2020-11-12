// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.4;

interface IERC20balanceOfTransfer { // brief interface for erc20 token tx
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ClaimLEX {
    address public LEX = 0xA5C5C8Af327248c4c2dce810a3d3Cffb8C4F66ab;
    mapping(address => bool) public claimants;
    
    function claim() external {
        require(!claimants[msg.sender], "claimed");
        require(IERC20balanceOfTransfer(LEX).balanceOf(msg.sender) >= 10000000000000000000, "insufficient LEX");
        IERC20balanceOfTransfer(LEX).transfer(msg.sender, 10000000000000000000);
        claimants[msg.sender] = true;
    }
    
    function remaining() external view returns (uint256) {
        return IERC20balanceOfTransfer(LEX).balanceOf(address(this));
    }
}