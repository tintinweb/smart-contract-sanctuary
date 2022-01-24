/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function permit(     
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) external ;

    function transferFrom(address from, address to, address amount) external;

    function transfer(address to, address amount) external;
}

contract IncentoRelayer {
    function transfer(  
        address token,   
        address amount,   
        address to,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
        ) external {
            IERC20(token).permit(owner, spender, value, deadline, v, r, s);
            IERC20(token).transferFrom(owner, address(this), amount);
            IERC20(token).transfer(to, amount);
    }
}