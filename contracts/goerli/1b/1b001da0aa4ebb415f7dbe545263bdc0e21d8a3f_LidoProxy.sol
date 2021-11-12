/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.8.0;

interface LidoInterface {

function approve(address spender, uint256 amount) external returns (bool);
}

contract LidoProxy {

address private lido = 0x209b1C2B038ef377f6f86d33C5Ca94d10ed9C89d;

function approveToken(address _address, uint _amount) external returns (bool) {
LidoInterface(lido).approve(_address, _amount);
return (true);
}

}