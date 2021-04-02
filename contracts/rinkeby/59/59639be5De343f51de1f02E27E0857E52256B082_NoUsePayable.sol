/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity >=0.6.10;

contract NoUsePayable {
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}