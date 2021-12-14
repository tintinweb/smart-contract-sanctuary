/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract Skimmer {
    address public owner;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function getBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function skim(address token, address to, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            _safeTransfer(token, to, amount);
        }
    }

    function skimAll(address token, address to) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(address(this).balance);
        } else {
            _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        }
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
}