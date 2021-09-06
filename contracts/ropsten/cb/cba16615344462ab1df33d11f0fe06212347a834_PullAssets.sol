/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function balanceOf(address account) external view returns(uint);
    function transfer(address recipient, uint amount) external returns(bool);
}

contract PullAssets {

    function pullETH(address payable _to) public {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
    }

    function pullERC20(address _to, address _token) public {
        IERC20 token = IERC20(_token);
        token.transfer(_to, token.balanceOf(address(this)));
    }

}