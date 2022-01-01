/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract AirDrop {
    event Transfer(address from, address to, uint256 amount);
    function drop(address[] calldata users, uint256[] calldata amounts) external {
        require(users.length == amounts.length, 'Length Mismatch');
        for (uint i = 0; i < users.length; i++) {
            //IERC20(token).transfer(users[i], amounts[i]);
            emit Transfer(address(this), users[i], amounts[i]);
        }
    }
}