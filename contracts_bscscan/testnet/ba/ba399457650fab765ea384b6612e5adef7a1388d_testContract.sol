/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
    
contract testContract {


    struct funcResultType {
        uint var1;
        string var2;
        string message;
    }

    funcResultType[] private funcResults;


    function testSetFunc(string memory inputVar,uint inputInt) public  {
        funcResultType memory funcResult;
        funcResult.var1=inputInt;
        funcResult.var2=inputVar;
        funcResult.message = "Done!";
        funcResults.push(funcResult);
    }


    function testGetFunc() public view returns (funcResultType[] memory){
        return funcResults;
    }
}