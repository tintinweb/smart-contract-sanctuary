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

    function withdrawBaseToken(uint256 _amount) public onlyOwner {
        payable(_owner).transfer(_amount);
    }
}