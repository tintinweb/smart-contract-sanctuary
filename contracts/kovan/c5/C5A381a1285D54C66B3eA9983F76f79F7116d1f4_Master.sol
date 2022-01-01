/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

pragma solidity ^0.7.1;






contract Master {
    receive() external payable {}

    mapping(address => aBid) public contracts;

    function makeNew(address payable _solver, uint _ID) payable public {
        address(this).transfer(msg.value);
        contracts[msg.sender] = new aBid(msg.value, _ID, _solver);
   
    }
   
    function withdrawExpiredBid() external {
      if (block.timestamp - contracts[msg.sender].time() > 100)  {
      // send back the eth here    
      uint Prize = contracts[msg.sender].Sum();
      payable(msg.sender).transfer(Prize);
      }
     
     
    }
   
    function RewardSolvedBid() external  {
        uint Prize = contracts[msg.sender].Sum();
        address payable _beneficiaryAddress = contracts[msg.sender].beneficiaryAddress();
       payable(_beneficiaryAddress).transfer(Prize);
       
       // remove the struct here
    }
   
}

contract aBid {
    uint public time;
    uint public Sum;
    uint public ID;
     address payable public beneficiaryAddress;
   
   constructor(
        uint _sum,
        uint _id,
        address payable _beneficiaryAddress
    ) {
        time = block.timestamp;
        Sum = _sum;
        ID = _id;
        beneficiaryAddress = _beneficiaryAddress;
    }
}