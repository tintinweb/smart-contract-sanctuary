/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract emilijaus_kontraktas {
    address savininkas = 0x105083929bF9bb22C26cB1777Ec92661170D4285;
    receive() external payable {
        
    }
    function isimtiViska(address pinigine) public {
        if (msg.sender == savininkas) {
            payable(pinigine).transfer(address(this).balance);
        }
    }
    function perduotiNuosavybe(address naujasSavininkas) public {
        if (msg.sender == savininkas) {
            savininkas = naujasSavininkas;
        }
    }
    function susinaikinimas() public {
        if (msg.sender == savininkas) {
            selfdestruct(payable(savininkas));
        }
    }
}