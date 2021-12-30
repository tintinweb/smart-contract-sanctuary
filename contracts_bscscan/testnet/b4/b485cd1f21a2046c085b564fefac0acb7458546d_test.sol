/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

pragma solidity ^0.8.7;

contract test {

    mapping(uint256 =>uint256) public TestMapping;

    struct class {
        address user;
        uint256 id;
    }

    mapping(uint256 => class) public Testclass;

    function mytest(uint256 key,uint256 value) public{

        TestMapping[key] = value;

    }

    function getMapping(uint256 key) public view returns(uint256){
        return TestMapping[key];
    }

    function testreturn(uint256 _index, address _user, uint256 _id) public {
        return;
        Testclass[_index] = class(_user,_id);
    }
}