/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

contract Wallet {
    address[] public approvers;
    uint public quorum;
    struct Transfers{
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    
    Transfers[] public transfers;
    mapping(address => mapping(uint => bool)) public approvals;
    
    constructor(address[] memory _approvers, uint _quorum) public {
        approvers = _approvers;
        quorum = _quorum;
    }
    
    function getApprovers() external view returns(address[] memory) {
        return approvers;
    }
    
    function getTransfers() external view returns(Transfers[] memory) {
        return transfers;
    }
    
    function createTransfers(uint amount, address payable to) external onlyApprover() {
     transfers.push(
            Transfers(transfers.length,
            amount,
            to,
            0,
            false
            )
         );
    }
    
    function approveTransfers(uint id) external onlyApprover() {
        require(transfers[id].sent == false, 'tranfers already sent');
        require(approvals[msg.sender][id] == false, 'already approved');
        
        approvals[msg.sender][id] = true;
        transfers[id].approvals++;
        
        if(transfers[id].approvals >= quorum){
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            to.transfer(amount);
        }
    }
    
    receive() external payable{}
    
    modifier onlyApprover() {
        bool allowed = false;
        for(uint i=0; i<approvers.length; i++){
            if(approvers[i] == msg.sender){
                allowed=true;
            }
        }
        require(allowed == true, 'not allowed');
        _;
    }
}