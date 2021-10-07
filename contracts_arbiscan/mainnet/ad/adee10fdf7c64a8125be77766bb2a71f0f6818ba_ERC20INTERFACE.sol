/**
 *Submitted for verification at arbiscan.io on 2021-09-20
*/

pragma solidity 0.5.17;

contract ERC20INTERFACE {
    mapping (address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public allowance;
    function transfer(address to, uint256 value) public {}
    function approve(address spender, uint256 value) public {}
    function transferFrom(address from, address to, uint256 value) public {}   
    function balanceOf(address account) public view returns (uint256) {}
}