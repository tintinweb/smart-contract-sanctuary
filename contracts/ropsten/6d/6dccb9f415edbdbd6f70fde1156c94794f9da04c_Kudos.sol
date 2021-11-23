/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity >=0.7.0 <0.9.0;

contract Kudos {
    mapping(address => Kudo[]) allKudos;
    
    function giveKudos( string memory what, address by, string memory comments, address who) public {
        Kudo memory kudo = Kudo(what, by, comments);
        allKudos[who].push(kudo);
    }
      
    
}

struct Kudo {
    string what;
    address by;
    string comments;
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138
// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xf8e81D47203A594245E36C48e151709F0C19fBe8

/*

wno is giving
who is gettting
what
addition comments

Queries:
1) get all kudus given by x to y
2) get all kudus recivce by Y
3) get all kudus for css

*/