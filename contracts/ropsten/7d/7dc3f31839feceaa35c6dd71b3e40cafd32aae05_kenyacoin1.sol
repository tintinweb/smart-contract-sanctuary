pragma solidity ^0.4.18;

contract kenyacoin1{
    //array with all balances
    //associative array associate addresses with balances
    //public means it will be accessible by everyone on blkchn
    mapping (address => uint256) public balanceOf;
}