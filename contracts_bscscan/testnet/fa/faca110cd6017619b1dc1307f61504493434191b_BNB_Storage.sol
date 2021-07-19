/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.8.4;

contract BNB_Storage {
        uint bnbStored = 0;
        function deposit(uint bnbAmount) public payable {
            bnbStored = bnbStored + bnbAmount;
        }
}