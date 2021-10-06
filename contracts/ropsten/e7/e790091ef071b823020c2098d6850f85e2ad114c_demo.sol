/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.4.4;



contract demo {
  struct IJiGou {
    address jigouAddress;
    uint supportMoneyAmount;
  }

  struct IStudent {
    address studentAddress;
    uint moneyGoal;
    uint numSupporter;
    uint hasGetMoney;
    mapping (uint => IJiGou) JiGous;
  }
  mapping (uint => IStudent) allStudentDic;

  function newCampaign(uint id, address studentAddress, uint moneyAmount) public {
    allStudentDic[id] = IStudent(studentAddress, moneyAmount, 0, 0);
  }

  function contribute(uint id) public payable {
    IStudent storage stu1 = allStudentDic[id];
    stu1.JiGous[stu1.numSupporter] = IJiGou({jigouAddress: msg.sender, supportMoneyAmount: msg.value});
    stu1.hasGetMoney += msg.value;
    stu1.studentAddress.transfer(msg.value);
  }

  


}