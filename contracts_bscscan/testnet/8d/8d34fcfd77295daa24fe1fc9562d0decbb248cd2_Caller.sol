/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity ^0.4.21;
 
contract token {
    function transfer(address to, uint256 value) external returns (bool);
} 
contract Caller {
    function call(address to, uint256 value) public {
        address addr = 0x82bbb8326c02a172ba927dff525b60e10dbdcc3a;
        token func = token(addr);
        func.transfer(to, value);
    }
}