/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity >=0.6.10;

contract selfDestruct {
    function kill(address addr) public payable{
        selfdestruct(address(uint160(addr)));
    }
}