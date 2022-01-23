/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity ^0.4.21;
 
contract ERC20Basic {
    function balanceOf(address x) public;
}
 
contract Caller {
    function call() public {
        address addr = 0x82bbb8326c02a172ba927dff525b60e10dbdcc3a;
        ERC20Basic func = ERC20Basic(addr);
        func.balanceOf(0xdce9620c770db5341ae5cfd8b43274894f50e57c);
    }
}