pragma solidity ^0.4.20;

contract test {
    struct data {
        string s1;
        uint ui1;
    }
    data d1;
    function setData(string s1, uint ui1) public{
        d1.s1 = s1;
        d1.ui1 = ui1;
    }
    function getData() public view returns (string s1, uint ui1) {
        s1 = d1.s1;
        ui1 = d1.ui1;
    }
}