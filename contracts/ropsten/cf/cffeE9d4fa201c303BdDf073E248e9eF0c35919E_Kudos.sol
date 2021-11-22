/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudos {
    
    mapping(address => Kudo[]) allKudos;
    
    function giveKudos(string memory what, string memory comment,address who) public{
        Kudo memory kudo = Kudo(what,comment,msg.sender);
        allKudos[who].push(kudo);
    }
    
    function getKudosLength(address who) public view returns(uint){
        Kudo[] memory kudos = allKudos[who];
        return kudos.length;
    }
    
    function getKudosAtIndex(address who, uint idx) public view returns(string memory, string memory,address) {
        Kudo memory kudo = allKudos[who][idx];
        return (kudo.what,kudo.comment,kudo.giver);
    }
}


struct Kudo{
    string what;
    string comment;
    address giver;
}