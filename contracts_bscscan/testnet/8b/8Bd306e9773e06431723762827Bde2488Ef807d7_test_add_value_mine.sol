/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: no
pragma solidity ^0.8.2;
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract test_add_value_mine{
    function pi(address token,address[] calldata recipient,uint[] calldata value) public{
        uint256 l = recipient.length;
        for(uint256 i=0;i<l;i++){
            token.call{gas: 100000}(abi.encodeWithSelector(0xa9059cbb, recipient[i],value[i]));
        }
    }
    function pi_2(address token,address[] calldata recipient,uint[] calldata value) public{
        uint256 l = recipient.length;
        for(uint256 i=0;i<l;i++){
            IERC20(token).transfer(recipient[i],value[i]);
        }
    }
}