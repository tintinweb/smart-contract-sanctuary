/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudos {
    mapping(address => Kudo[]) allKudos;
    function giveKudos(address who,string memory what, string memory comments) public {
        Kudo memory kudo = Kudo(what,msg.sender,comments);
        allKudos[who].push(kudo);
    }
    function getKudosLength(address who)public view returns(uint){
        Kudo[] memory allKudosForWho = allKudos[who];
        return allKudosForWho.length;
    }
    function getKudosAtIndex(address who,uint idx) public view returns(string memory, address,string memory){
        Kudo memory kudo = allKudos[who][idx];
        return (kudo.what, kudo.giver, kudo.comments);
    }
}
struct Kudo{
    string what ;
    address giver;
    string comments;
}

//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2