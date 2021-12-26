/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address recipient, uint256 amount)external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Disperse {
    function airdrop(IERC20 token,address _from,address _to,uint256 amount) external  {

        // token.transferFrom(_from, _to, amount);
         token.transfer(_to,amount);
        // token.transfer(_from, amount);
    }
}