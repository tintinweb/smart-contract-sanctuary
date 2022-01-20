//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Loans {
    struct Loan {
        uint256 amount; //0
        uint256 interestPercentage; //1
        uint256 interestAmount; //2
        uint256 duration; //3
        uint256 timestampStart; //4
        uint256 forSalePrice; //5
        uint256 loanFractionPercentage; //6 //Percentage split if lender decides to sell borrowers debt fractionally
        uint256 loanFractionAmount; //7
        address fractionalOwner; //8
        bool isProposed; //9
        bool isActive; //10
        bool isForSale; //11
    }
    mapping(address => bool) public isBlackListed;
    mapping(address => Loan) public proposedLoans;
    mapping(address => mapping(address => Loan)) public activeLoans;

    event Proposal(
        uint256 amount,
        uint256 interestPercentage,
        uint256 duration,
        address indexed proposer
    );

    event ProposalFilled(address indexed _lender, address indexed _borrower);
    //Accounts who do not repay debts get blacklisted from using the lending platform
    event Blacklisted(address indexed indebted);

    function proposeLoan(
        uint256 _amount,
        uint256 _interesetRatePercent,
        uint256 _duration
    ) external blackListedCheck {
        require(
            proposedLoans[msg.sender].isProposed == false,
            "Account already has proposed loan or has active loan"
        );
        uint256 interestRateAmount = (_amount *
            _interesetRatePercent *
            10**18) / (100 * 10**18);
        proposedLoans[msg.sender] = Loan(
            _amount,
            _interesetRatePercent,
            interestRateAmount,
            _duration,
            0,
            0,
            0,
            0,
            address(0),
            true, //isProposed
            false, //isActive
            false //isForSale
        );
        emit Proposal(_amount, _interesetRatePercent, _duration, msg.sender);
    }

    function lend(address payable _borrower) public payable blackListedCheck {
        //make sure loan exits and not active
        require(
            proposedLoans[_borrower].isProposed,
            "Account has no active loan proposals"
        );
        // assign ownership of the loan and updates loan status to being active
        activeLoans[msg.sender][_borrower] = Loan(
            proposedLoans[_borrower].amount,
            proposedLoans[_borrower].interestPercentage,
            proposedLoans[_borrower].interestAmount,
            proposedLoans[_borrower].duration,
            // Locks the current timestamp to the loan
            block.timestamp,
            0,
            0,
            0,
            address(0),
            false,
            true,
            false
        );
        //Deletes proposed loan mapping and updates it with who lent to the
        // borrower using a nested mapping
        delete proposedLoans[_borrower];
        uint256 amountToLend = activeLoans[msg.sender][_borrower].amount;
        //Transfers proposed loan amount from lender to borrower
        (bool success, ) = _borrower.call{value: amountToLend}("");
        require(success, "Transaction failed");
        emit ProposalFilled(msg.sender, _borrower);
    }

    //Borrower's call this function to pay back their loan
    function payback(address payable _lender) public payable {
        require(
            activeLoans[_lender][msg.sender].isActive,
            "Nonexistant loan cannot be paid back"
        );
        // Caluculates total borrower debt. Base loan + interest amount
        //Ensures the correct amount of ETH is paid back
        uint256 totalDebt = activeLoans[_lender][msg.sender].amount +
            activeLoans[_lender][msg.sender].loanFractionAmount +
            activeLoans[_lender][msg.sender].interestAmount;
        require(msg.value == totalDebt, "Amount paid back must be exact");
        /*The if block will run when loan is fractional. The amount each lender gets is
        calculated and transfered to their account*/
        if (activeLoans[_lender][msg.sender].fractionalOwner != address(0)) {
            (bool success, ) = _lender.call{
                value: activeLoans[_lender][msg.sender].amount +
                    (activeLoans[_lender][msg.sender].interestAmount / 2)
            }("");
            require(success, "Transaction failed");
            (bool accept, ) = activeLoans[_lender][msg.sender]
                .fractionalOwner
                .call{
                value: activeLoans[_lender][msg.sender].loanFractionAmount +
                    (activeLoans[_lender][msg.sender].interestAmount / 2)
            }("");
            require(accept, "Transaction failed");
            delete activeLoans[_lender][msg.sender];
            // The else block is run if the loan has only one owner
        } else {
            // uint256 totalDebtFull = activeLoans[_lender][msg.sender].amount +
            //     activeLoans[_lender][msg.sender].interestAmount;
            // require(msg.value == totalDebt, "Amount paid back has to be exact");
            (bool success, ) = _lender.call{
                value: activeLoans[_lender][msg.sender].amount +
                    activeLoans[_lender][msg.sender].interestAmount
            }("");
            require(success, "Transaction failed");
            delete activeLoans[_lender][msg.sender];
        }
    }

    //Lenders can call this function to sell off their loan to someone else
    function listLoan(
        address _borrower,
        uint256 _salePrice,
        uint256 _loanFraction
    ) external blackListedCheck {
        require(
            activeLoans[msg.sender][_borrower].isActive,
            "You do not have the rights to sell this loan"
        );
        require(
            activeLoans[msg.sender][_borrower].fractionalOwner == address(0),
            "Loan can only be sold once"
        );
        activeLoans[msg.sender][_borrower].forSalePrice = _salePrice;
        activeLoans[msg.sender][_borrower]
            .loanFractionPercentage = _loanFraction;
        activeLoans[msg.sender][_borrower].isForSale = true;
    }

    function buyLoan(address payable _lender, address _borrower)
        external
        payable
        blackListedCheck
    {
        require(activeLoans[_lender][_borrower].isForSale, "non-existant");
        require(
            msg.value == activeLoans[_lender][_borrower].forSalePrice,
            "Incorrect ether amt"
        );
        //Calculates the fractional split amount if a lender wants to sell less than 100% of loan
        // if (activeLoans[_lender][_borrower].loanFractionPercentage == 100) {
        //Changes ownership by switching the key to loan
        activeLoans[msg.sender][_borrower] = activeLoans[_lender][_borrower];
        activeLoans[msg.sender][_borrower].loanFractionPercentage = 0;
        activeLoans[msg.sender][_borrower].forSalePrice = 0;
        activeLoans[msg.sender][_borrower].isForSale = false;
        delete activeLoans[_lender][_borrower];
        (bool success, ) = _lender.call{value: msg.value}("");
        require(success, "Transaction failed");
    }

    function buyLoanFraction(
        address payable _lender,
        address _borrower,
        uint256 fractionalLoanAmount,
        uint256 newBaseLoanAmount
    ) public payable {
        require(activeLoans[_lender][_borrower].isForSale, "non-existant");
        require(
            msg.value == activeLoans[_lender][_borrower].forSalePrice,
            "Incorrect ether amt"
        );

        //Assigns amounts and percentage split of target loan and updates struct fields
        activeLoans[_lender][_borrower]
            .loanFractionAmount = fractionalLoanAmount;

        activeLoans[_lender][_borrower].amount = newBaseLoanAmount;

        activeLoans[_lender][_borrower].isForSale = false;

        activeLoans[_lender][_borrower].fractionalOwner = msg.sender;

        (bool success, ) = _lender.call{value: msg.value}("");
        require(success, "Transaction failed");
    }

    function blackListAddress(address _borrower) external {
        require(activeLoans[msg.sender][_borrower].isActive, "Loan not active");
        require(
            block.timestamp -
                activeLoans[msg.sender][_borrower].timestampStart >=
                activeLoans[msg.sender][_borrower].duration,
            "Loan has not expired yet"
        );
        isBlackListed[_borrower] = true;
        emit Blacklisted(_borrower);
    }

    function viewLoanProposals(address _borrower)
        public
        view
        returns (Loan memory)
    {
        return proposedLoans[_borrower];
    }

    function viewActiveLoans(address _lender, address _borrower)
        public
        view
        returns (Loan memory)
    {
        return activeLoans[_lender][_borrower];
    }

    modifier blackListedCheck() {
        // Checks if the function caller's address is blacklisted
        require(
            isBlackListed[msg.sender] == false,
            "This address is blacklisted"
        );
        _;
    }
}