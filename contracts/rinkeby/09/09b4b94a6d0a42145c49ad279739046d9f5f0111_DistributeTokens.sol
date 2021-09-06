/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract DistributeTokens {
    using SafeMath for *;
    
    address public owner; // gets set somewhere
    // address[] public investors; // array of investors
    uint private round = 0;
    struct roundStruct{
        uint starttime;
        uint endtime;
        address winner;
        uint plycount;
        uint poolOfMoney;
        // address startPlayer;
        address[] player;
    }
    
    mapping (uint => roundStruct) public map_rounD;
    

    function play() public payable { 
        // require(msg.value == 1 ether);
        if(map_rounD[round].starttime == 0 || map_rounD[round].endtime < now){
            round = round.add(1);
            map_rounD[round].starttime = now;
            map_rounD[round].endtime = now + 10 minutes;
            map_rounD[round].winner = msg.sender;
            map_rounD[round].player.push(msg.sender);
            map_rounD[round].plycount = map_rounD[round].player.length;
        }
        else{
            map_rounD[round].player.push(msg.sender);
            map_rounD[round].winner = msg.sender;
            map_rounD[round].plycount = map_rounD[round].player.length;
        }
        
        map_rounD[round].poolOfMoney = map_rounD[round].poolOfMoney.add(100000000000000000);
    }
    
    
    function getLast() public view returns(uint len){
        return map_rounD[round].player.length;
    }
    
    function getround() public view returns(uint){
        return round;
    }
    
    constructor() public {
        owner = msg.sender;
        round = 0 ; 
    }
    
}