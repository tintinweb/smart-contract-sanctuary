/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Owner {

   

    struct Transaction
    {
         uint time;
         uint256 amount;
    }

    Transaction[] arraytransactionHistory;

    struct LoanDeatils
    {
        uint256 amount;
        string name;
        address addr_Lone;
        Status status;
        uint time;
    }
  
    enum Status
    {
        APPLIED,
        APPROVED,
        REJECT
    }
   
    event NewApplyLone(
        LoanDeatils userLoneDetails
    );
   
    address bankOwner;
  
    mapping(address => uint256) public balanceOf;  

    LoanDeatils[] arrayLoanUserHistory;

    constructor() public {
         bankOwner = msg.sender;
    }
     
     modifier onlyOwner {
         require(msg.sender == bankOwner);
         _;
     }

     function transferOwnership(address newOwner) public onlyOwner {
         bankOwner = newOwner;
     }
    
    function investment() public payable onlyOwner{

        balanceOf[bankOwner] += msg.value;

       // Transaction memory history = Transaction(block.timestamp,amount);
        arraytransactionHistory.push(Transaction(block.timestamp,msg.value));
    }

    function applyLoan(string memory _name, uint256 _amount) external returns(bool) {
       
        for(uint i= 0; i < arrayLoanUserHistory.length; i++)
        {
            if ((arrayLoanUserHistory[i].addr_Lone == msg.sender) && (arrayLoanUserHistory[i].status == Status.REJECT))
            {
                return false;
            }
        }

        arrayLoanUserHistory.push(LoanDeatils(_amount,_name,msg.sender,Status.APPLIED,block.timestamp));

        emit NewApplyLone(LoanDeatils(_amount,_name,msg.sender,Status.APPLIED,block.timestamp));
        
        return true;

    }
    
    function getUserLoanDetails(address _address) public view returns (LoanDeatils memory) {

        for (uint i= 0; i < arrayLoanUserHistory.length; i++) {
            if (arrayLoanUserHistory[i].addr_Lone == _address) {
                return arrayLoanUserHistory[i];
            }
        }
    }
    
    function getBalance() public onlyOwner view returns (uint256) {
        return balanceOf[bankOwner];
    }
    
    function AppovedApplyedLone(address payable recipient) external onlyOwner{

        for (uint i= 0; i < arrayLoanUserHistory.length; i++) {
            if ((arrayLoanUserHistory[i].addr_Lone == recipient) && (arrayLoanUserHistory[i].status == Status.APPLIED)){
                
                if (arrayLoanUserHistory[i].amount < balanceOf[bankOwner])
                {
                    arrayLoanUserHistory[i].status = Status.APPROVED;
                    arrayLoanUserHistory[i].time = block.timestamp;
                    balanceOf[bankOwner] -= arrayLoanUserHistory[i].amount;
                    recipient.transfer(arrayLoanUserHistory[i].amount);
                }
            }
        }
    }
    
    function rejectApplyedLone(address _address) external onlyOwner{

        for (uint i= 0; i < arrayLoanUserHistory.length; i++){
            if ((arrayLoanUserHistory[i].addr_Lone == _address) && (arrayLoanUserHistory[i].status == Status.APPLIED)){
                arrayLoanUserHistory[i].status = Status.REJECT;
                arrayLoanUserHistory[i].time = block.timestamp;
            }
        }
    }
}