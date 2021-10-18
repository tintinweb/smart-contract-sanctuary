/******************************************************************************************************************************************
*                                                                                                                                         *
*                                                     Multi-Sig Wallet                                                                    *
*                                                                                                                                         *
*******************************************************************************************************************************************/


pragma solidity 0.8.0;

contract wallet{
    address[] public approvers;
    uint public quorum; //number of approvers we need to approve a transfer
    struct Transfer{
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    Transfer[] public transfers;
    mapping(address => mapping(uint => bool)) public approvals;
    event etherReceived(address indexed sender, uint amount);
    event etherSent(address indexed receiver, uint amount);
    
    constructor(address[] memory _approvers, uint _quorum) public {
        approvers = _approvers;
        quorum = _quorum;
    }
    
    //get list of approvers
    function getApprovers() external view returns(address[] memory){
        return approvers;
    } 
    
    //called by one of the approvers when they need to suggest a new transfer of ether
     function createTransfer(uint amount, address payable to) external onlyApprover {
        transfers.push(Transfer(
          transfers.length,
          amount,
          to,
          0,
          false
        )
        );
        emit etherSent(to, amount);
    }
    
    function approveTransfer(uint id) external onlyApprover {
        require(transfers[id].sent ==false, 'Transfers has already taken place.');
        require(approvals[msg.sender][id] == false, 'Cannot approve transfer twice.');
        
        approvals[msg.sender][id] == true;
        transfers[id].approvals++;
        
        if(transfers[id].approvals >= quorum){
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            uint amount = transfers[id].amount;
            to.transfer(amount);
        }
        
    }
    
    //return list of transfers
    function getTransfers() external view returns(Transfer[] memory){
        return transfers;
    } 
    
    //receive ether
    receive() external payable{
        emit etherReceived (msg.sender, msg.value);
    }
    
    modifier onlyApprover() {
        bool allowed = false;
        for(uint i=0; i<approvers.length; i++){
            if(approvers[i] == msg.sender){
                allowed = true;
            }
        }
        require(allowed == true, 'Only approver allowed.');
        _;
    }
}