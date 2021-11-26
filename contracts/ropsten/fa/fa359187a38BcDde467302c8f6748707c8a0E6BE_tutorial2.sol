/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity >=0.6.0 <0.9.0;

contract tutorial2{

struct Member{
    uint256 usdt;
    string name;
}
Member [] public member;

Member public member1=Member(1,"Rock");
Member public member2=Member(2,"Brock");

function generate_member(uint256 _usdt,string memory _name) public{
    
    member.push(Member({usdt:_usdt,name:_name}));
    
}

}