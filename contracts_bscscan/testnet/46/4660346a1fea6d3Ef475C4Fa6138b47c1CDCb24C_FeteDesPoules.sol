/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity ^0.4.19;
// SPDX-License-Identifier: Unlicensed


contract FeteDesPoules {
    event newPoule(string name, string taille, string couleurPlumes);
    uint NbPoules = 0;

    struct Poule {
        string name;
        string taille;
        string couleurPlumes;
    }
    Poule[] public listePoules;

    function createPoule(string _name ,string _taille,string _couleurPlumes) public {
        NbPoules++;
        newPoule(_name,_taille,_couleurPlumes);

    }

    function TotalPoules() public view returns(uint) {
        return(NbPoules);
    }

}