/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity 0.8.10;

contract Deneme {
    function callMe() external pure returns(string memory){
        return "called";
    }
    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
}