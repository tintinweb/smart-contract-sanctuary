/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

//yeong hea

pragma solidity 0.8.0;

contract Likelion_3_1 {
uint[] scores;

function setGrade(uint score) public {
scores.push(score);
}

function calScore_view() public view returns(uint, uint, uint, uint){
uint a = 0;
uint b = 0;
uint c = 0;
uint Acount = 0;
uint Bcount = 0;
uint Ccount = 0;
uint buffer = 0;
uint total = 0;


for (uint i = 0; i < scores.length; i++){
    if(scores[i] >= 70){
        a += scores[i];
        Acount += 1;
    }
    else if(scores[i] <= 40){
        b += scores[i];
        Bcount += 1;
    }
    else if(scores[i] > 40 && scores[i] < 70){
        c += scores[i];
        Ccount += 1;
    }
    else{
        return (404, 404, 404, 404);
    }

}
total = (a+b+c)/(Acount+Bcount+Ccount);

buffer = a / Acount;
a = buffer;

 buffer = b / Bcount;
 b = buffer;

 buffer = c / Ccount;
 c = buffer;

return (total, a, b, c);

}

}