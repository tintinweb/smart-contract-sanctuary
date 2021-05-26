/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_19 {
    struct aa {
        string name;
        address k;
        bool tf;
    }
    aa[] pp;
    
    string[] vote_name;
    // mapping(string => uint) vote;
    // mapping(string => string[]) votes;
    uint total;

    function propose(string memory i) public {
        vote_name.push(i);
    }
    
    function Vote(string memory i,bool a) public {
        pp.push(aa(i,msg.sender,a));
        // if(a==true){
        //     votes[i].push(msg.sender)
        // }
        total++;
    }
    function amivote(string memory i) public returns(bool){
        // for(uint j=0; j<pp.length; j++){
        //     if(pp[j].address==msg.sender){
        //         return pp[j].boolean;
        //     }
        // }
    }
}