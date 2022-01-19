/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

pragma solidity ^0.4.24;


contract myContract {
    string value ;
    constructor() public {
        value = "Hello Eth World";
        emit Test(value);
    }
    function get() public view returns(string){
        return value;
    }
    function set(string _val) public {
        emit Test(_val);
        value = _val;
    }
    event Test(string indexed new_value);
}