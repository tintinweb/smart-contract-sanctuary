/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract PriorApprovalERC20 {

    event OnPriorApproval (
        address indexed receiver,
        address indexed approver,
        uint256 indexed blockTime
    );

    event OnPriorApprovalRemoval (        
        address indexed receiver,
        address indexed approver,
        uint256 indexed blockTime
    );

    //List of addresses that can approve receivers to receive tokens sent from the Token Contract
    address[] private _approverAddressList; 

    //Minimum number of approvals required for any address to receive tokens sent from the Token Contract
    uint256 private _minimumApprovalCountRequired;
    
    //A map with key as receiver and value as approver. 
    //This map gets an entry when an approver approves a receiver
    //The entry gets removed when approver revokes the approval
    mapping(bytes32 => bool) _receiverApproverMapping;

    constructor(address[] memory approverAddressList, uint256 minimumApprovalCountRequired){
         require(approverAddressList.length == 4, "Approver count does not match the number of assigned approvers");
         require(minimumApprovalCountRequired == 3, "Minimum approval count does not  match the number of assigned approvals");
        _approverAddressList = approverAddressList;
        _minimumApprovalCountRequired = minimumApprovalCountRequired;
    }

    modifier restricted() {
        require(isApprover() == true, "Caller is not an approver");
        _;
    }
    
    function append(address a, address c) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(a, c));
    }

    //This function is called when an approver makes a request to approve a receiver
    function newPriorApprovalERC20(
        address receiver) 
        external
        restricted()
    returns (bool)
    {
        _receiverApproverMapping[append(receiver, msg.sender)] = true;
        emit OnPriorApproval(receiver, msg.sender, block.timestamp);
        return true;
    }
    
    //This function is called when an approval makes a request to revoke an approval
    function removePriorApprovalERC20(address receiver)
        external
        restricted()
        returns (bool)
    {
        _receiverApproverMapping[append(receiver, msg.sender)] = false;
        emit OnPriorApprovalRemoval(receiver, msg.sender, block.timestamp);
        return true;
    }

    //This function is called when you need to check whether the receiver is approved or not
    function verifyPriorApprovalERC20(address receiver)
        public
        view
        returns (bool)
    {
        uint256 approvalCount = 0; 
        uint arrayLength = _approverAddressList.length;
        for (uint i = 0; i < arrayLength; i++) {
            if(_receiverApproverMapping[append(receiver, _approverAddressList[i])] == true) {
                approvalCount = approvalCount + 1;
            }
        }
        
        if(approvalCount >= _minimumApprovalCountRequired){
            return true;
        }
        
        return false;
    }
    
    //This function is called to find whether an approver has approved a receiver or not
    function getPriorApprovalERC20(address receiver, address approver)
        public
        view
        returns (
            bool approved
        )
    {
        approved = _receiverApproverMapping[append(receiver, approver)];
    }


    //This function is called to find whether the message sender is an approver or not
    function isApprover()
        private
        view
        returns (bool)
    {
        uint arrayLength = _approverAddressList.length;
        for (uint i = 0; i < arrayLength; i++) {
            if(_approverAddressList[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
}