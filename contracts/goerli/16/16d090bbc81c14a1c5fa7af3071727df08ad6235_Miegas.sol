/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.4.11;
contract Miegas {
    address savininkas = 0x105083929bF9bb22C26cB1777Ec92661170D4285;
    int miego_valandos = 0;
    function duotiMiegoValandu(int kiekis) public {
        if (msg.sender == savininkas) {
            miego_valandos = miego_valandos + kiekis;
        }
    }
    function miegoValanduLikutis() public view returns(int likutis) {
        return miego_valandos;
    }
    function susinaikinimas() public {
        if (msg.sender == savininkas) {
            selfdestruct(savininkas);
        }
    }
}