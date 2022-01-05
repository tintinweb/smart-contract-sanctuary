/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0

// linkdin,twitter,github username: @imHukam

pragma solidity ^0.8.7;
pragma abicoder v2;

contract MultisigWallet{

    address[] public owners;
    uint limit;

    struct Transfer{
        uint amount;
        address payable receiver;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }

    Transfer[] transferRequests;
    mapping(address=> mapping(uint=>bool)) approvals; // approvals[address][uint]= true/false;

    // to get owners list and approval limit
    constructor(address[] memory _owners, uint _limit){
        owners=_owners;
        limit=_limit;
    }

    // only allow owners list to continue the execution.
    modifier onlyOwners{
        bool owner = false;

        for(uint i=0;i<owners.length;i++){
            if(msg.sender==owners[i]){
                owner= true;
            }
        }
        require(owner==true, "only owners have authority to excute this");
        _;
    }

    //events emit:
    event TransferRequestCreated(uint _amount,address payable _receiver , address _initiator, uint _id);
    event ApprovalReceived(uint _id, uint _approvals, address _approver);
    event TransferApproved(uint _id);

    //1:deposit fund
    function deposit() public payable{} //empty function,only for deposit fund into contract

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    //2: create transfer requests
    function createTransfer(uint _amount, address payable _receiver) public onlyOwners {
       
       emit TransferRequestCreated(_amount,_receiver,msg.sender,transferRequests.length);

        transferRequests.push(
            Transfer(_amount,_receiver,0,false,transferRequests.length)
            );
    }

    //3 to approve transfer requests by owners;
    function approve(uint _id) public onlyOwners{
        require(approvals[msg.sender][_id]==false);
        require(transferRequests[_id].hasBeenSent== false);

        approvals[msg.sender][_id]= true;
        transferRequests[_id].approvals++;

        emit ApprovalReceived(_id,transferRequests[_id].approvals,msg.sender);
    
        if(transferRequests[_id].approvals>=limit){
            transferRequests[_id].hasBeenSent=true;
            transferRequests[_id].receiver.transfer(transferRequests[_id].amount);

            emit TransferApproved(_id);
        }
    }

    //4 to return all transfer requests;
    function getTransferRequests() public view onlyOwners returns(Transfer[] memory){
        return transferRequests;
    }
}