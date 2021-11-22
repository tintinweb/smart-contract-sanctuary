/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudos {
    mapping ( address => Kudo[] ) allKudos;
    function giveKudos(address toWhom, string memory what, string memory comments) public { //memory because we dont know the length of variable, while for address it is fixed
        Kudo memory kudo = Kudo(what, msg.sender, comments);
        allKudos[toWhom].push(kudo);
    }
    function getKudosLength(address who) public view returns(uint) {
        return allKudos[who].length;
    }
    function getKudosAtIndex(address who, uint index) public view returns(string memory, address, string memory) {
        Kudo memory kudo = allKudos[who][index];
        return (kudo.what, kudo.giver, kudo.comments);
    }
    function hello() public view {}
}

struct Kudo {
    string what;
    address giver;
    string comments;
}