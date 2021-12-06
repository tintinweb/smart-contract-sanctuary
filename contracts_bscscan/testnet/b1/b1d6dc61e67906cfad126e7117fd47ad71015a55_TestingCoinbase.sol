/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

pragma solidity ^0.6.12;
contract TestingCoinbase
{
    address public LastCoinbase;
    function getCoinbase() public{
        LastCoinbase=block.coinbase;
    }
}