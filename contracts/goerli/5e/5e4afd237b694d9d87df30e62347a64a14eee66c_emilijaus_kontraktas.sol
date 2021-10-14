/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
contract emilijaus_kontraktas {
    mapping(address => string) public failuSaugykla;
    address savininkas = 0x105083929bF9bb22C26cB1777Ec92661170D4285;
    receive() external payable {
        
    }
    function issaugotiFaila(string memory failas) public {
        failuSaugykla[msg.sender] = failas;
    }
    function perduotiNuosavybe(address naujasSavininkas) public {
        if (msg.sender == savininkas) {
            savininkas = naujasSavininkas;
        }
    }
    function patikrintiSavininka() public view returns(address) {
        return savininkas;
    }
    function susinaikinimas() public {
        if (msg.sender == savininkas) {
            selfdestruct(payable(savininkas));
        }
    }
}