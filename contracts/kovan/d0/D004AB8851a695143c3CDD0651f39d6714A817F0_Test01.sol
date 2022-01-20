/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity ^0.8.0;

contract Test01 {

    event Test(address sender,string msg);

    function test(string memory message) external{
        emit Test(msg.sender,message);
    }

}