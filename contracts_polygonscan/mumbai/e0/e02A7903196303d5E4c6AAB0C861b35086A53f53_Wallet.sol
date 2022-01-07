// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";

contract Wallet is Ownable{
    constructor () {
    }

    function tokenBalance(address token) public view returns(uint256){
        IERC20 erc20 = IERC20(token);
        return erc20.balanceOf(address(this));
    }

    function tokenWithdraw(address token,address receiver) public onlyOwner{
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));

        erc20.transfer(receiver,balance);
    }
}