/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.0;
pragma abicoder v2;

interface IERC20{
    function transferFrom(address sender, address reciepent, uint256 amount) external returns (bool);
}

contract CollectERC20 {
    constructor(){}
 
    function collect(IERC20 _token,address _to,uint256[] calldata _amount, address[] calldata _from) public {
    
    require(_token.transferFrom(_from[0], _to,_amount[0]));
    }
}