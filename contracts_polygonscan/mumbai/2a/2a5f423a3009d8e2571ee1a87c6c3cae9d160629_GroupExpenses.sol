/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

//made by Mr.Peer//

pragma solidity ^0.4.10;
contract GroupExpenses {
    
    struct Participant {
        string name;
        address waddress;
        int balance;
    }

    struct Expense {
        string title;
        uint amount;
        address payer; 
        address[] payees; 
        mapping(address => bool) agreements; 
    }

    struct Payment {
        string title;
        uint amount;
        address payer;
        address payee;
    }
    
    /// This declares a state variable that stores a `Participant` struct for each possible address.
    mapping(address => Participant) public participants;
    
    // A dynamically-sized array of `Expenses` structs.
    Expense[] public expenses;

    // A dynamically-sized array of `Payments` structs.
    Payment[] public payments;
    
    mapping(address => uint) public withdrawals;

    
    function GroupExpenses() public {

    }
    
    function createParticipant(string _name, address _waddress) public {
        require(_waddress != participants[_waddress].waddress); //only one address per participant
        Participant memory participant = Participant({name: _name, waddress: _waddress, balance: 0});
        participants[_waddress] = participant;
    }
    
        function createExpense(string _title, uint _amount, address[] _payees) public {
        require(_amount > 0);
        require(_payees.length > 0 && _payees.length <= 20);
        require(msg.sender == participants[msg.sender].waddress);
        require(isParticipants(_payees));

        Expense memory expense = Expense(_title, _amount, msg.sender, _payees);
        expenses.push(expense);
    }
    
    function createPayment(string _title, address _payee) public payable {   
        require(msg.value > 0);
        require(_payee != msg.sender);
        require(msg.sender == participants[msg.sender].waddress);
        require(_payee == participants[_payee].waddress);
        Payment memory payment = Payment({title: _title, amount: msg.value, payer: msg.sender, payee: _payee});
        payments.push(payment);
        withdrawals[_payee] += msg.value;
        syncBalancePayment(payment);
    }
    
    function withdraw() public {
        require(withdrawals[msg.sender] > 0);
        uint amount = withdrawals[msg.sender];
        withdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function setAgreement(uint indexExpense, bool agree) public {
        Expense storage expense = expenses[indexExpense];
        require(expense.agreements[msg.sender] != agree);
        uint numberOfAgreeBefore = getNumberOfAgreements(indexExpense);
        /// Warning : There is no agreements when the expense is created. That's mean the balance did not synchronize.
        /// If the number of agreements before is not 0, we revert the balance to the previous state without the expense
        if (numberOfAgreeBefore != 0) {
            revertBalance(indexExpense);
        }

        /// Update the number of agreements
        expense.agreements[msg.sender] = agree;
        uint numberOfAgreeAfter = getNumberOfAgreements(indexExpense);

        /// If the number of agreements after is not 0, we syncrhonize the balance
        if (numberOfAgreeAfter != 0) {
            syncBalance(indexExpense);
        }
    }
    
    function getNumberOfAgreements(uint indexExpense) public returns (uint) {
        Expense storage expense = expenses[indexExpense];
        uint numberOfAgreements = 0;
        for (uint i = 0; i < expense.payees.length; i++) {
            if (expense.agreements[expense.payees[i]] == true) {
                numberOfAgreements++;
            }                
        }
        return numberOfAgreements;  
    }
    
        function syncBalance(uint indexExpense) internal {
        calculateBalance(indexExpense, false);
    }

    function revertBalance(uint indexExpense) internal {
        calculateBalance(indexExpense, true);
    }

    function calculateBalance(uint indexExpense, bool isRevert) internal {
        uint contributors = getNumberOfAgreements(indexExpense);
        require(contributors > 0);
        Expense storage expense = expenses[indexExpense];
        int _portion = int(expense.amount / contributors);
        int _amount = int(expense.amount);
        
        if (isRevert) {
            _portion = -(_portion);
            _amount = -(_amount);
        }

        participants[expense.payer].balance += _amount;
        for (uint i = 0; i < expense.payees.length; i++) {
            if (expense.agreements[expense.payees[i]]) {
                participants[expense.payees[i]].balance -= _portion;
            }   
        }       
    }
    
        // Synchronize the balance after each new Payment
    function syncBalancePayment(Payment payment) internal {
        participants[payment.payee].balance -= int(payment.amount);
        participants[payment.payer].balance += int(payment.amount);
    }

    
        /// @notice Check if each address of the list is registred as participant
    /// @param list the list of address to check 
    /// @return true if all the list is registred as participant, false otherwise
    function isParticipants(address[] list) internal returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            if (!isParticipant(list[i])) {
                return false;
            }
        }
        return true;
    }

    /// @notice Check if each address of the list is registred as participant
    /// @param _waddress the address to check 
    /// @return true if all the list is registred as participant, false otherwise
    function isParticipant(address _waddress) internal returns (bool) {
        if (_waddress == participants[_waddress].waddress) {
            return true;
        }else {
            return false;
        }
    }

}