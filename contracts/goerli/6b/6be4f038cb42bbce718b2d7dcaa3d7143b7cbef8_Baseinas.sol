/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.4.11;
contract Baseinas {
    address savininkas = 0x105083929bF9bb22C26cB1777Ec92661170D4285;
    int baseino_valandos = 0;
    function duotiBaseinoValandu(int kiekis) public {
        if (msg.sender == savininkas) {
            baseino_valandos = baseino_valandos + kiekis;
        }
    }
    function baseinoValanduLikutis() public view returns(int likutis) {
        return baseino_valandos;
    }
    function perduotiNuosavybe(address naujas_savininkas) public {
        if (msg.sender == savininkas) {
            savininkas = naujas_savininkas;
        }
    }
    function susinaikinimas() public {
        if (msg.sender == savininkas) {
            selfdestruct(savininkas);
        }
    }
}