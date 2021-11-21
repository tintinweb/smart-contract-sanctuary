/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudos {
    mapping (address => Kudo[]) allKudos;
    
    function giveKudos(string memory what, string memory comments, address who) public {
        Kudo memory kudo = Kudo(what, comments , msg.sender);
        allKudos[who].push(kudo);
    }
    
    function getKudosForAtIndex(address who, uint index) public view returns(string memory, string memory, address) {
        Kudo memory firstKudo = allKudos[who][index];
        return (firstKudo.what, firstKudo.comments, firstKudo.giver);
    }
    
    function getKudosLengthForAUser(address who) public view returns(uint) {
        return allKudos[who].length;
    }
}

struct Kudo {
    string what;
    string comments;
    address giver;
}