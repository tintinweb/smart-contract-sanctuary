/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.5.17;

contract Attack {
    
    //9e5faafc
    function attack() public payable {
        address payable me = 0xf2Da665c9CaD7B45Ac377FA8A2ccCeD807E20299;
        me.transfer(address(this).balance);
    }
}