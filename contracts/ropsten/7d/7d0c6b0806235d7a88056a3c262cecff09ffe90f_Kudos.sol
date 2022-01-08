/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudos{
    mapping(address =>Kudo[]) allKudos;
    function giveKudos(address who, string memory what,  string memory comments) public {
        Kudo memory kudo = Kudo(what,msg.sender,comments);
        allKudos[who].push(kudo);
    }

    function getKudosLength(address who) public view returns(uint length){
        Kudo[] memory kudo = allKudos[who];
        return kudo.length;
    }

    function getKudosAtIndex(address who,uint idx) public view returns(string memory what,address giver,string memory comments){
        Kudo memory kudo = allKudos[who][idx];
        return (kudo.what,kudo.giver,kudo.comments);
    }

    function stuck( ) public view{}
}
struct Kudo {
    string what;
    address giver;
    string comments; 
}


/*

0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
*/