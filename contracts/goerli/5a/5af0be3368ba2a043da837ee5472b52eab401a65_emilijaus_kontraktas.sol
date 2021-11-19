/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract emilijaus_kontraktas {
    uint skola = 0;
    address savininkas = 0x105083929bF9bb22C26cB1777Ec92661170D4285;
    function pridetiSkola(uint pridejimo_kiekis) public {
        if (msg.sender == savininkas) {
            skola = skola + pridejimo_kiekis;
        }
    }
    function isvalytiSkola() public {
        if (msg.sender == savininkas) {
            skola = 0;
        }
    }
    function atimtiSkola(uint atemimo_kiekis) public {
        if (msg.sender == savininkas) {
            skola = skola - atemimo_kiekis;
        }
    }
    function susinaikinimas() public {
        if (msg.sender == savininkas) {
            selfdestruct(payable(savininkas));
        }
    }
    function tikrintiSkola() public view returns (uint) {
        return skola;
    }
}