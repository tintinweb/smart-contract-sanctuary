// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


import './SafeMath.sol';
import './IERC20Interface.sol';
import './RoyaleInterface.sol';
import './Re.sol';

contract rLoan is ReentrancyGuard{

    using SafeMath for uint256;
    uint8 constant N_COINS = 3;
    
    IERC20[N_COINS] tokens;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => Repayment) public gamingCompanyRepayment;
    mapping(address => uint[])public takenLoan;
    
    uint256 public transactionCount = 0;
    RoyaleInterface public royale;

    address public wallet;

    uint256[N_COINS] public totalLoanTaken;
    uint256[N_COINS] public totalApprovedLoan;
    
    struct Transaction {
        uint256 transactionId;
        address iGamingCompany;
        bool isGamingCompanySigned;
        uint256[N_COINS] tokenAmounts;
        uint256[N_COINS] remAmt;
        bool approved;
        bool executed;
    }

    struct Repayment {
        uint256 transactionID;
        bool isRepaymentDone;
        uint256[N_COINS] remainingTokenAmounts;
    }


    /* Events */

    event loanRequested(
        address by,
        uint[N_COINS] amounts,
        uint loanID
    );

    event approved(
        uint loanID
    );


    event loanWithdrawn(
        address by,
        uint[N_COINS] requestedAmount,
        uint[N_COINS] remainingAmount,
        uint loanID
    );

    event loanFulfilled(
        address by,
        uint[N_COINS] requestedAmount,
        uint[N_COINS] remainingAmount,
        uint loanID
    );

    event loanRepayed(
        address by,
        uint[N_COINS] repayedAmount,
        uint[N_COINS] amountRemaining,
        uint loanID
    );

    event wholeLoanRepayed(
        address by,
        uint[N_COINS] repayedAmount,
        uint[N_COINS] amountRemaining,
        uint loanID
    );

    /* Modifiers */

     modifier onlyWallet(){
      require(wallet==msg.sender, "Not Authorized");
      _;
  }

    

    modifier transactionExists(uint _loanID) {
        require(_loanID > 0 && _loanID <= transactionCount);
        _;
    }
   

    constructor(address[N_COINS] memory _tokens , address _royale,address _wallet) public {
    
        royale = RoyaleInterface(_royale);
        // Set Tokens supported by Pool

        for(uint8 i=0; i<N_COINS; i++) {
            tokens[i] = IERC20(_tokens[i]);
           
        }
        wallet=_wallet;
    }


    function transferOwnership(address _wallet) external onlyWallet(){
        wallet =_wallet;
    }
    /* Internal Functions */

    function _addTransaction(uint256[N_COINS] memory amounts ) internal returns(uint256){
        uint256[N_COINS] memory zero;
        transactionCount++;
        transactions[transactionCount] = Transaction({
            transactionId: transactionCount,
            iGamingCompany: msg.sender,
            tokenAmounts: amounts,
            remAmt: zero,
            isGamingCompanySigned: true,
            approved: false,
            executed: false
        });
        return transactionCount;
        
    }
    /* USER FUNCTIONS (exposed to frontend) */

    // Gaming platforms withdraw using this
    function requestLoan(uint256[N_COINS] calldata amounts) external returns(uint256 loanID) {
       _addTransaction(amounts);
        emit loanRequested(msg.sender, amounts, transactionCount);
        return transactionCount;
       
    }

      function approveLoan(uint _loanID) external onlyWallet() {
       
        for(uint8 i=0;i<N_COINS;i++) {
            uint royaleBalance=royale.selfBalance(i);
            require(totalApprovedLoan[i].add(transactions[_loanID].tokenAmounts[i]).sub(totalLoanTaken[i])<royaleBalance,"Can not approve that much amount");
        }
        transactions[_loanID].approved = true;
        transactions[_loanID].remAmt = transactions[_loanID].tokenAmounts;
        for(uint8 i=0;i<N_COINS;i++){
            totalApprovedLoan[i] =totalApprovedLoan[i].add(transactions[_loanID].tokenAmounts[i]);
        }
        takenLoan[transactions[_loanID].iGamingCompany].push(_loanID);
    }
    

    function checkLoanApproved(uint _loanID) external view returns(bool) {
        return transactions[_loanID].approved;
    }
    

    /* Admin Function */
    
   

    function withdrawLoan( uint256[N_COINS] calldata amounts,uint _loanID) external nonReentrant{
        for(uint8 i=0;i<3;i++){
            require(amounts[i]<=royale.selfBalance(i),"Not Enough Balance");
        }
        require(transactions[_loanID].iGamingCompany == msg.sender, "company not-exist");
        require(transactions[_loanID].approved, "not approved for loan");
        uint256[N_COINS] memory loanAmount;
        for(uint8 i=0; i<N_COINS; i++) {
            require(transactions[_loanID].remAmt[i] >= amounts[i], "amount requested exceeds amount approved");
        }
        uint256 poolBalance;
        uint256[3] memory withdrawAmount;
         for(uint8 i=0;i<3;i++){
             poolBalance=tokens[i].balanceOf(address(royale));
             if(amounts[i]>poolBalance){
                 withdrawAmount[i]=amounts[i].sub(poolBalance);
             }
         }
        bool b = royale._loanWithdraw(amounts,withdrawAmount,transactions[_loanID].iGamingCompany);
        require(b, "Loan Withdraw not succesfull");

        uint check = 0;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                totalLoanTaken[i] =totalLoanTaken[i].add(amounts[i]);
                transactions[_loanID].remAmt[i] =transactions[_loanID].remAmt[i].sub(amounts[i]);
                loanAmount[i]=gamingCompanyRepayment[_loanID].remainingTokenAmounts[i].add(amounts[i]);
            }
            if(transactions[_loanID].remAmt[i] == 0) {
                check++;
            }
        }
        gamingCompanyRepayment[_loanID] = Repayment({
                  transactionID: _loanID,
                  isRepaymentDone: false,
                  remainingTokenAmounts: loanAmount
        });


        emit loanWithdrawn(msg.sender, amounts, transactions[_loanID].remAmt, _loanID);

        if(check == 3) {
            // Loan fulfilled, company used all its loan
            transactions[_loanID].executed = true;
        }
    } 
   
    
    function repayLoan(uint256[N_COINS] calldata _amounts, uint _loanId) external nonReentrant{
        require(_loanId <= transactionCount, "invalid loan id");
        require(transactions[_loanId].iGamingCompany == msg.sender, "company not-exist");
        require(!gamingCompanyRepayment[_loanId].isRepaymentDone, "already repaid");
        for(uint8 i=0;i<N_COINS;i++){
            require(_amounts[i]<=gamingCompanyRepayment[_loanId].remainingTokenAmounts[i],"Don't have that much of remaining repayment");
        }
        bool b = royale._loanRepayment(_amounts,transactions[_loanId].iGamingCompany);
        require(b,"Loan Payment not succesfull");
        uint counter=0;
        for(uint i=0;i<N_COINS;i++) {
            if(_amounts[i]!=0) {
                totalLoanTaken[i] =totalLoanTaken[i].sub(_amounts[i]);
                totalApprovedLoan[i]=totalApprovedLoan[i].sub(_amounts[i]);
                gamingCompanyRepayment[_loanId].remainingTokenAmounts[i] =gamingCompanyRepayment[_loanId].remainingTokenAmounts[i].sub(_amounts[i]);
                if(gamingCompanyRepayment[_loanId].remainingTokenAmounts[i] == 0) {
                    counter++;
                }
            }
        }
        emit loanRepayed(msg.sender,_amounts,  gamingCompanyRepayment[_loanId].remainingTokenAmounts, _loanId);
        if(counter==3){
            gamingCompanyRepayment[_loanId].isRepaymentDone=true;

            emit wholeLoanRepayed( msg.sender, _amounts,  gamingCompanyRepayment[_loanId].remainingTokenAmounts,_loanId);
        }       
    }
}