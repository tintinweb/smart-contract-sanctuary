/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

contract Wallet {
    address[] public approvers;
    uint public quorum;
    struct Transfer {
       uint id;
       uint amount;
       address payable to;
       uint approvals;
       bool sent;
   }
    // mapping(uint => Transfer) public transfers;
    // uint nextId;
   Transfer[] public transfers;
   mapping(address => mapping(uint => bool)) public approvals; //recording who approved what
   
    constructor(address[] memory _approvers, uint _quorum) public {
       approvers = _approvers;
       quorum = _quorum;
    }
   
    function getApprovers() external view returns(address[] memory) {
       return approvers;
    }
    
    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }
   
   function createTransfer(uint amount, address payable to) external onlyApprover {
        // transfers[nextId] = Transfer(
        //   nextId,
        //   amount,
        //   to,
        //   0,
        //   false
        // );
        // nextId++;
        transfers.push(Transfer(
           transfers.length,
           amount,
           to,
           0,
           false
        ));
   }
   
   function approveTransfer(uint id) external onlyApprover {
       require(transfers[id].sent == false, 'transfer has already been sent');
       require(approvals[msg.sender][id] == false, 'cannot approve transfer twice');
       
       approvals[msg.sender][id] = true;
       transfers[id].approvals++;
       
       if(transfers[id].approvals >= quorum){
           transfers[id].sent = true;
           address payable to = transfers[id].to;
           uint amount = transfers[id].amount;
           to.transfer(amount); //function to send ether
       }
   }
   
   receive() external payable {}
   
   modifier onlyApprover() {
       bool allowed = false;
       for(uint i=0; i<approvers.length; i++){
           if(approvers[i] == msg.sender){
               allowed = true;
           }
       }
       require(allowed == true, 'only approval allowed');
       _;
   }
}