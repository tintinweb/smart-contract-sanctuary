/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity >=0.4.22 <0.7.0;

contract messageBoard {
    int public num1=0;
    int public num2=0;
    int public num3=0;
    int public persons=0;
    constructor() public {
        num1=0;
        num2=0;
        num3=0;
    }
    function vote(int option) public{
        if (option == 1){ num1 = num1+1; }
        if (option == 2){ num2 = num2+1; }
        if (option == 3){ num3 = num3+1; }
    }
    function showResult(int option) public view returns(int counts){
        if (option == 1){ return num1; }
        if (option == 2){ return num2; }
        if (option == 3){ return num3; }
    }
    function pay() public payable{
        persons = persons+1;
    }
}