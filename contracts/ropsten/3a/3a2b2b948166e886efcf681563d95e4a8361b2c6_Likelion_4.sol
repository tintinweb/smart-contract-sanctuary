/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity 0.8.0;


contract Likelion_4 {
    //YunJun Lee
    string grade;
    uint[][] students = [ [0] , [0], [0], [0]] ;
    uint[] sum = [0,0,0,0];

    function setGrade(uint score) public returns(string memory){

        if(score >= 90) {
            students[1].push(score);
            sum[1]+=score;

        } else if(score >=80){
            students[1].push(score);
            sum[1]+=score;

        }else if(score >=70){
            students[1].push(score);
            sum[1]+=score;

        }else if(score >=60){
            students[3].push(score);
            sum[3]+=score;

        } else if(score <=40){
            students[2].push(score);
            sum[2]+=score;

        } 
        else{
            sum[3]+=score;
            students[3].push(score);

        }

        students[0].push(score);
        sum[0]+=score;
    }
    function getAverage() public view returns(uint, uint, uint, uint){


        return (sum[0]/students[0].length, sum[1]/students[1].length, sum[2]/students[2].length, sum[3]/students[3].length) ;
    }



}