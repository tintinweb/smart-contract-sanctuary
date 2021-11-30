/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity 0.8.0;

contract Check {

    function justCheck() public view returns(address){
        return msg.sender;
    }
}