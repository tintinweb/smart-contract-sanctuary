/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract emilijaus_kontraktas {
    address savininkas = 0x105083929bF9bb22C26cB1777Ec92661170D4285;
    function inesti() public payable {
        
    }
    function isimti(address pinigine, uint kiekis) public {
        if (msg.sender == savininkas) {
            payable(pinigine).transfer(kiekis);
        }
    }
    function susinaikinimas() public {
        if (msg.sender == savininkas) {
            selfdestruct(payable(0x105083929bF9bb22C26cB1777Ec92661170D4285));
        }
    }
}