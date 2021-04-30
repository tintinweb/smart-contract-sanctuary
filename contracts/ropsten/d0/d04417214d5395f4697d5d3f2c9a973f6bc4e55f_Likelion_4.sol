/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

//young do Jang

pragma solidity 0.8.0;

contract Likelion_4 {
    uint [] Ga;
    uint [] Na;
    uint [] Da;
    uint [] La;
    
    function setClass(uint score) public  {
        Ga.push(score);
        if(score >= 70) {
            Na.push(score);
        } else if(score <= 40) {
            Da.push(score);
        } else if(40 < score && score < 70) {
            La.push(score);
        }
    }
    function getAverage() public view returns(uint, uint, uint, uint) {
                uint a;
                uint b;
                uint c;
                uint d;
                 for(uint i =0; i < Ga.length; i++) {
                a += Ga[i];
            }     for(uint i =0; i < Na.length; i++) {
                b += Na[i];
            }     for(uint i =0; i < Da.length; i++) {
                c += Da[i];
            }     for(uint i =0; i < La.length; i++) {
                d += La[i];
            }
                return(a/Ga.length,b/Na.length,c/Da.length, d/La.length); 
}
}