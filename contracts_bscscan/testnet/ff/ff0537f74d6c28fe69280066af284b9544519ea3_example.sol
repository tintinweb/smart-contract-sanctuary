/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

pragma solidity ^0.8.0;


contract example {

   uint[] public array;
   struct person_detail{
       uint8 person_age;
       string person_name;
   }
    string public title;
    uint256 public number;


    event recordParams(string str,uint256 number,person_detail detail,uint[] arr);

    function setRecordParams(string memory str,uint256 num,uint8 age,string memory name,uint rand) public {
       person_detail memory    detail;
       detail.person_age = age;
       detail.person_name = name;
       array.push(rand);
       title = str;
       number = num;
    }
}