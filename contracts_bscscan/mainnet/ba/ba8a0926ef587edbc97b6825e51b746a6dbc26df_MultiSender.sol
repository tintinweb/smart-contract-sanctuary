// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IERC20.sol";

contract MultiSender {




    function Holders(Tokentwt token, address[] memory holders, uint256 amount) public  payable {
        for (uint i=0; i<holders.length; i++) {
            token.transferFrom(address(this), holders[i], amount);
        }
    }
}