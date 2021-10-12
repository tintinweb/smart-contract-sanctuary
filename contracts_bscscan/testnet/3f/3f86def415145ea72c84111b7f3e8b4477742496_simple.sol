/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

pragma solidity 0.8.0;

contract simple{
    int number1;
    uint number2;
    string name;

    function getinput(int a, uint b, string memory c)public {
        number1 = a;
        number2 = b;
        name = c;
    }
    function retrieve()public view returns(int, uint, string memory){
        return(number1, number2, name);
    }
}