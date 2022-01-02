/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

//SPDX-License-Identifier: MIT
 

pragma solidity ^0.6.0;

contract myStorage{


    uint256   myBalance;
    

    struct People {
        uint256 myBalance;
        string fname;
    }

    People public person1=People({myBalance: 333, fname:"Tomi"});
    People[] public clients;

    mapping (string => uint256) public personToBalance;

    function store(uint256 _myBalance) public {
        myBalance=_myBalance;
    }

    function retrieve() public view returns(uint256){
         return myBalance+1000;
    }

    function addPerson(uint256 _myBalance, string memory _fname) public{
        clients.push(People(_myBalance, _fname));
        personToBalance[_fname]=_myBalance;
    }

}