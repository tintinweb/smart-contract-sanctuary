/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SendVia {

    function send(address[] memory addresses, uint256[] memory values) public payable {
        require(addresses.length == values.length && msg.value > 0, "");
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && values[i] > 0, "");
                payable(addresses[i]).transfer(values[i]);
        }
    }

    function sendERC20(address[] memory tokens, address[] memory addresses, uint256[] memory values) public {
        require(addresses.length == values.length && tokens.length == values.length, "");
        for (uint256 i = 0; i < addresses.length; i++){
            IERC20 Token = IERC20(tokens[i]);
            require(addresses[i] != address(0) && values[i] > 0, "");
            Token.transferFrom(msg.sender, addresses[i], values[i]);
        }
    }
}