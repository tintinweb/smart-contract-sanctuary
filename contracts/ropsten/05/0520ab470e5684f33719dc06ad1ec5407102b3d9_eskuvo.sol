/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract eskuvo {
    
    // valtozok / propertik == storage valtozo == blockchainben lesz lementve
    address public partner1;
    address public partner2;
    bool public partner1IgentMondott;
    bool public partner2IgentMondott;
    address admin;
    address vendeg;
    string hely;
    string ido;
    uint256 meghivottakSzama;

    // accountok metamask (teszt)                       -                (ropsten)
    // admin:0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 - 0x8EdD3fD0088c6931d7be7fc9B0EEfdc29Ca4e8Af
    // partner1: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 - 0xb0eeCD566F1788D6875fc08589b08e80F3A2F901
    // partner2: 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c - 0x59F08ecaBb8648391725C546290cB896908cA648
    
    // constructor
    
    constructor(address _partner1, address _partner2) {
        partner1 = _partner1;
        partner2 = _partner2;
        meghivottakSzama = 100;
        partner1IgentMondott = false;
        partner2IgentMondott = false;
    }

    
    // kiolvaso fuggveny
    
    function getMegihovttakSzama() view public returns (uint256) {
        return meghivottakSzama;
    }
    
    // tranzakcios fuggvenyek
    
    function novelResztvevok(uint256 _pluszResztvevok) public {
        meghivottakSzama += _pluszResztvevok;
    }


    function csokkentResztvevok(uint256 _minuszResztvevok) public {
        
        if(meghivottakSzama >= _minuszResztvevok){
            meghivottakSzama -= _minuszResztvevok;
        }
        else
        {
            meghivottakSzama = 0;
        }
    }    
    
    function partner1IgentMond() public {
        partner1IgentMondott = true;
    }

    function partner2IgentMond() public {
        partner2IgentMondott = true;
    }
    
    
    
}