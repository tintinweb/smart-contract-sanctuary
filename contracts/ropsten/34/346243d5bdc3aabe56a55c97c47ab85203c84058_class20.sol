/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.4.24;
contract class20{
        // string[12] public strArr;
        // mapping(address=>bool) public info;
        // struct student {
        //     string name;
        //     uint8 age;
        //     uint8 score;
        // }
        // mapping(address=>student) public studentList;
        // student public aaa;
        string name ;
        uint8 score;
        event recordLog(string name,uint8 score);
        constructor() public {
            name = "empty_name";
            score = 0;
            emit recordLog(name, score);
            // info[0xCf14180Bee496378E90D00FF8D020661588f9A07] = true;

            // info[0x81b7E08F65Bdf5648606c89998A9CC8164397647] = false;

            // for(uint8 a = 0 ; a < 2; a++){
            //     strArr[a] = "AAA";
            // }
            // studentList[0xCf14180Bee496378E90D00FF8D020661588f9A07] = student("Tom", 10, 99);
            // studentList[0x81b7E08F65Bdf5648606c89998A9CC8164397647] = student("Jane", 60, 12);
            // aaa = student("Ray", 15, 100);
        }

        function info(string newName) public returns (string){
            // studentList[0xCf14180Bee496378E90D00FF8D020661588f9A07] = student(newName, 10, 99);
            // return studentList[0xCf14180Bee496378E90D00FF8D020661588f9A07];
            name = newName;
            score += 20;
            emit recordLog(newName, score);
            return newName;
        }

}