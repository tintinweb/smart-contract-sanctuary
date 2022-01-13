/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.0;

interface IERC20{
    function transferFrom(address sender, address reciepent, uint256 amount) external returns (bool);
}

contract CollectERC20 {
    constructor(){}
 
    function collect(IERC20 _token, address[] calldata _from,address _to,uint256[] calldata _amount) public {

    require(_from.length == _amount.length, "fail");
    for (uint256 i = 0; i< _from.length; i++){
    require(_token.transferFrom(_from[i], _to,_amount[i]));
    }
    
    }
}