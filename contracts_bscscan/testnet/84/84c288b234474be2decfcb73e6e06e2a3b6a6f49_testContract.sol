/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
    
contract testContract {


    struct funcResultType {
        uint[] var1;
        string[] var2;
        string message;
    }

    funcResultType private funcResult;


    function testSetFunc(string memory inputVar) public payable {
        funcResult.var1.push(123);
        funcResult.var2.push(inputVar);
        funcResult.message = "Done!";
    }

    function testResetFunc() public payable {
        delete funcResult; // reset variales
    }

    function testGetFunc() public view returns (funcResultType memory){
        return funcResult;
    }
}