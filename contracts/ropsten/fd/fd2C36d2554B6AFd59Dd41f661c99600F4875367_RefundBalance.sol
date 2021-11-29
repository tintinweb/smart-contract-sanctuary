// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RefundBalance {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "You're not allowed to call the function");
        _;
    }

    receive() external payable {}

    fallback() external {
        revert("ce01");
    }
    
    function withdrawBaseToken(address _receiver, uint256 _amount) external onlyOwner {
        require(_receiver != address(0), "The receiver is not valid");
        payable(_receiver).transfer(_amount);
    }
}