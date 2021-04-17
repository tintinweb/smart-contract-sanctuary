/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity 0.5.9;
// SPDX-License-Identifier: MIT
contract victim {
    function subtractVal(uint value) public returns(uint);
    function addVal(uint value) public returns(uint);
}

contract attacker{
        function attack_subtract(address watch_addr, uint x) public {
            victim vc = victim(watch_addr);
            vc.subtractVal(x);
        }
        function attack_add(address watch_addr, uint x) public {
            victim vc = victim(watch_addr);
            vc.addVal(x);
        }
}