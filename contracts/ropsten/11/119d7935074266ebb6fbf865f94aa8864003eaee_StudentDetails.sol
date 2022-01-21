/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
contract StudentDetails{
    address public admin;

    struct Record{
    int regno;
    string name;
    string class;
    int javamark;
  //  address studAddr;
    bool jobGurantee;
    int avgCount; 
    }

    modifier onlyOwner {
        require (admin == msg.sender);
        _;
    }

     constructor() public {
        admin=msg.sender;
    }

    mapping (int=> Record) public Viewrecord;
    event recordSigned(int regno, string name, string class, int javamark);

    function newRegisteration(int newRegno, string memory newName, string memory newClass, int newJavamark) public onlyOwner {
        Record storage newRecord = Viewrecord[newRegno];
        require(!Viewrecord[newRegno].jobGurantee, "Record Already Exsist.");
        newRecord.regno = newRegno;
        newRecord.name = newName;
        newRecord.class = newClass;
        newRecord.javamark = newJavamark;
        //newRecord.studAddr = newStudAddr;
        newRecord.jobGurantee = false;
        newRecord.avgCount = 0;
    }

    function dailyMarks(int newRegno, int newJmark) onlyOwner public{
        Record storage finalRecord = Viewrecord[newRegno];
      //  require(address(0) != finalRecord.studAddr);
        finalRecord.javamark = (Viewrecord[newRegno].javamark + newJmark)/2;
        if(finalRecord.javamark >= 80) {
        finalRecord.avgCount++; 
        } else {
            finalRecord.avgCount--;
        }
        if(finalRecord.avgCount >=7) {
        finalRecord.jobGurantee = true;
        }else {
            finalRecord.jobGurantee = false;
        }
    }
}