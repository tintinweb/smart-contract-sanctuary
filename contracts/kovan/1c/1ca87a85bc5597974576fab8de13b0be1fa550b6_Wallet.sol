/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Wallet {
    
    address[] public approvers;

    uint256 public quorum;

    struct Transfer {
        uint256 id;
        uint256 amount;
        address payable to;
        uint256 approvers;
        bool sent;
    }

    Transfer[] public transfers;

    mapping(address => mapping(uint256 => bool)) public approvals;

    constructor(address[] memory _approvers, uint256 _quorum) {
        approvers = _approvers;
        quorum = _quorum;
    }

    function getApprovers() external view  returns(address[] memory) {
        return approvers;
    }

    function createTransfer(uint256 amount, address payable to) external onlyApprover {
        transfers.push(Transfer(
            transfers.length,
            amount,
            to,
            0,
            false
        ));
    }

    function getTransfers() external view returns(Transfer[] memory) {
        return transfers;
    }

    function approveTransfer(uint256 id) external onlyApprover {
        require(transfers[id].sent == false, 'transfer has already been sent');
        require(approvals[msg.sender][id] == false, 'transfer has already been approved');
        approvals[msg.sender][id] = true;
        transfers[id].approvers++;

        if (transfers[id].approvers >= quorum) {
            transfers[id].sent = true;
            address payable to = transfers[id].to;
            to.transfer(transfers[id].amount);
        }
    }

    receive() external payable {}

    modifier onlyApprover() {
        bool allowed = false;
        for(uint256 i=0; i< approvers.length; i++) {
            if(approvers[i] == msg.sender) {
                allowed = true;
            }
        }
        require(allowed == true, 'only approver allowed');
        _;
    }
}