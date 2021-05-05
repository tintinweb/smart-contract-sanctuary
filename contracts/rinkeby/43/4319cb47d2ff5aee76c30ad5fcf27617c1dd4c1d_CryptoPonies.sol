/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity <=0.8.1;

contract CryptoPonies {
    enum PonieSex {Male, Female}
    
    // Ponies struct
    struct Ponie {
        string name;
        PonieSex ponieSex;
        string father;
        string mother;
        // address owner;
    }

    // Ponies Mapping
    mapping(string => Ponie) public ponies;
    
    function newPonie(string memory _name,  PonieSex _ponieSex) public {
        Ponie storage p = ponies[_name];
        p.name = _name;
        p.ponieSex = _ponieSex;
    }
    
    function getPonie(string memory _name) public view returns (string memory ponieName, PonieSex ponieSex,string memory father, string memory mother) {
        return (ponies[_name].name, ponies[_name].ponieSex, ponies[_name].father, ponies[_name].mother);
    }
    
    function matePonies(string memory ponieName1, string memory ponieName2, string memory newPonieName, PonieSex newPonieSex) public{
        require(ponies[ponieName1].ponieSex != ponies[ponieName2].ponieSex, "Cannot breed ponies with the same sex");
        // create ponie
        Ponie storage p = ponies[newPonieName];
        // define ponie lineage
        if (ponies[ponieName1].ponieSex == PonieSex.Male) {
            p.father = ponieName1;
            p.mother = ponieName2;
        } else {
            p.father = ponieName2;
            p.mother = ponieName2;
        }
        // define ponie gender
        p.ponieSex = newPonieSex;
    }
}