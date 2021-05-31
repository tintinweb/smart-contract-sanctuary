pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./PalPool.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IStakedAave.sol";
import {Errors} from  "./Errors.sol";



/** @title palStkAave Pool contract  */
/// @author Paladin
contract PalStkAave is PalPool {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /** @dev stkAAVE token address */
    address private stkAaveAddress;
    /** @dev AAVE token address */
    address private aaveAddress;
    /** @dev Block number of the last reward claim */
    uint public claimBlockNumber = 0;


    constructor( 
        address _palToken,
        address _controller, 
        address _underlying,
        address _interestModule,
        address _delegator,
        address _aaveAddress
    ) PalPool(
            _palToken, 
            _controller,
            _underlying,
            _interestModule,
            _delegator
        )
    {
        stkAaveAddress = _underlying;
        aaveAddress = _aaveAddress;
    }


    /**
    * @dev Claim AAVE tokens from the AAVE Safety Module and stake them back in the Module
    * @return bool : Success
    */
    function claimFromAave() internal returns(bool) {
        //Load contracts
        IERC20 aave = IERC20(aaveAddress);
        IStakedAave stkAave = IStakedAave(stkAaveAddress);

        //Get pending rewards amount
        uint pendingRewards = stkAave.getTotalRewardsBalance(address(this));

        //If there is reward to claim
        if(pendingRewards > 0 && claimBlockNumber != block.number){

            //claim the AAVE tokens
            stkAave.claimRewards(address(this), pendingRewards);

            //Stake the AAVE tokens to get stkAAVE tokens
            aave.safeApprove(stkAaveAddress, pendingRewards);
            stkAave.stake(address(this), pendingRewards);

            //update the block number
            claimBlockNumber = block.number;

            return true;
        }
        return true;
    }


    /**
    * @notice Deposit underlying in the Pool
    * @dev Deposit underlying, and mints palToken for the user
    * @param amount Amount of underlying to deposit
    * @return bool : amount of minted palTokens
    */
    function deposit(uint amount) external override(PalPool) preventReentry returns(uint){
        require(claimFromAave());
        require(_updateInterest());

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();

        //Transfer the underlying to this contract
        //The amount of underlying needs to be approved before
        underlying.safeTransferFrom(msg.sender, address(this), amount);


        //Find the amount to mint depending of the previous transfer
        uint _num = amount.mul(mantissaScale);
        uint _toMint = _num.div(_exchRate);

        //Mint the palToken
        require(palToken.mint(msg.sender, _toMint), Errors.FAIL_MINT);

        //Emit the Deposit event
        emit Deposit(msg.sender, amount, address(this));

        //Use the controller to check if the minting was successfull
        require(controller.depositVerify(address(this), msg.sender, _toMint), Errors.FAIL_DEPOSIT);

        return _toMint;
    }

    /**
    * @notice Withdraw underliyng token from the Pool
    * @dev Transfer underlying token to the user, and burn the corresponding palToken amount
    * @param amount Amount of palToken to return
    * @return uint : amount of underlying returned
    */
    function withdraw(uint amount) external override(PalPool) preventReentry returns(uint){
        require(claimFromAave());
        require(_updateInterest());
        require(balanceOf(msg.sender) >= amount, Errors.INSUFFICIENT_BALANCE);

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();

        //Find the amount to return depending on the amount of palToken to burn
        uint _num = amount.mul(_exchRate);
        uint _toReturn = _num.div(mantissaScale);

        //Check if the pool has enough underlying to return
        require(_toReturn < _underlyingBalance(), Errors.INSUFFICIENT_CASH);

        //Burn the corresponding palToken amount
        require(palToken.burn(msg.sender, amount), Errors.FAIL_BURN);

        //Make the underlying transfer
        underlying.safeTransfer(msg.sender, _toReturn);

        //Use the controller to check if the burning was successfull
        require(controller.depositVerify(address(this), msg.sender, amount), Errors.FAIL_DEPOSIT);

        //Emit the Withdraw event
        emit Withdraw(msg.sender, amount, address(this));

        return _toReturn;
    }

    /**
    * @dev Create a Borrow, deploy a Loan Pool and delegate voting power
    * @param _amount Amount of underlying to borrow
    * @param _feeAmount Amount of fee to pay to start the loan
    * @return uint : amount of paid fees
    */
    function borrow(uint _amount, uint _feeAmount) external override(PalPool) preventReentry returns(uint){
        require(claimFromAave());
        //Need the pool to have enough liquidity, and the interests to be up to date
        require(_amount < _underlyingBalance(), Errors.INSUFFICIENT_CASH);
        require(_updateInterest());
        require(_feeAmount >= minBorrowFees(_amount), Errors.BORROW_INSUFFICIENT_FEES);

        address _dest = msg.sender;

        //Deploy a new Loan Pool contract
        PalLoan _newLoan = new PalLoan(
            address(this),
            _dest,
            address(underlying),
            delegator
        );

        //Create a new Borrow struct for this new Loan
        Borrow memory _newBorrow = Borrow(
            _dest,
            address(_newLoan),
            _amount,
            address(underlying),
            _feeAmount,
            0,
            borrowIndex,
            block.number,
            false
        );


        //Send the borrowed amount of underlying tokens to the Loan
        underlying.safeTransfer(address(_newLoan), _amount);

        //And transfer the fees from the Borrower to the Loan
        underlying.safeTransferFrom(_dest, address(_newLoan), _feeAmount);

        //Start the Loan (and delegate voting power)
        require(_newLoan.initiate(_amount, _feeAmount), Errors.FAIL_LOAN_INITIATE);

        //Update Total Borrowed, and add the new Loan to mappings
        totalBorrowed = totalBorrowed.add(_amount);
        borrows.push(address(_newLoan));
        loanToBorrow[address(_newLoan)] = _newBorrow;
        borrowsByUser[_dest].push(address(_newLoan));

        //Check the borrow succeeded
        require(controller.borrowVerify(address(this), _dest, _amount, _feeAmount, address(_newLoan)), Errors.FAIL_BORROW);

        //Emit the NewLoan Event
        emit NewLoan(_dest, address(underlying), _amount, address(this), address(_newLoan), block.number);

        //Return the borrowed amount
        return _amount;
    }

    /**
    * @notice Transfer the new fees to the Loan, and expand the Loan
    * @param loan Address of the Loan
    * @param feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function expandBorrow(address loan, uint feeAmount) external override(PalPool) preventReentry returns(uint){
        require(claimFromAave());
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow memory __borrow = loanToBorrow[loan];
        require(!__borrow.closed, Errors.LOAN_CLOSED);
        require(__borrow.borrower == msg.sender, Errors.NOT_LOAN_OWNER);
        require(_updateInterest());
        
        //Load the Loan Pool contract
        PalLoanInterface _loan = PalLoanInterface(__borrow.loan);

        //Transfer the new fees to the Loan
        //If success, update the Borrow data, and call the expand fucntion of the Loan
        underlying.safeTransferFrom(__borrow.borrower, __borrow.loan, feeAmount);

        require(_loan.expand(feeAmount), Errors.FAIL_LOAN_EXPAND);

        __borrow.feesAmount = __borrow.feesAmount.add(feeAmount);

        loanToBorrow[loan]= __borrow;

        emit ExpandLoan(__borrow.borrower, address(underlying), address(this), __borrow.feesAmount, __borrow.loan);

        return feeAmount;
    }

    /**
    * @notice Close a Loan, and return the non-used fees to the Borrower.
    * If closed before the minimum required length, penalty fees are taken to the non-used fees
    * @dev Close a Loan, and return the non-used fees to the Borrower
    * @param loan Address of the Loan
    */
    function closeBorrow(address loan) external override(PalPool) preventReentry {
        require(claimFromAave());
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow memory __borrow = loanToBorrow[loan];
        require(!__borrow.closed, Errors.LOAN_CLOSED);
        require(__borrow.borrower == msg.sender, Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Load the Loan contract
        PalLoanInterface _loan = PalLoanInterface(__borrow.loan);

        //Calculates the amount of fees used
        uint _feesUsed = (__borrow.amount.mul(borrowIndex).div(__borrow.borrowIndex)).sub(__borrow.amount);
        uint _penaltyFees = 0;
        uint _totalFees = _feesUsed;

        //If the Borrow is closed before the minimum length, calculates the penalty fees to pay
        // -> Number of block remaining to complete the minimum length * current Borrow Rate
        if(block.number < (__borrow.startBlock.add(minBorrowLength))){
            uint _currentBorrowRate = interestModule.getBorrowRate(_underlyingBalance(), totalBorrowed, totalReserve);
            uint _missingBlocks = (__borrow.startBlock.add(minBorrowLength)).sub(block.number);
            _penaltyFees = _missingBlocks.mul(__borrow.amount.mul(_currentBorrowRate)).div(mantissaScale);
            _totalFees = _totalFees.add(_penaltyFees);
        }
    
        //Security so the Borrow can be closed if there are no more fees
        //(if the Borrow wasn't Killed yet, or the loan is closed before minimum time, and already paid fees aren't enough)
        if(_totalFees > __borrow.feesAmount){
            _totalFees = __borrow.feesAmount;
        }
        
        //Close and destroy the loan
        _loan.closeLoan(_totalFees);

        //Set the Borrow as closed
        __borrow.closed = true;
        __borrow.feesUsed = _totalFees;

        //Update the storage variables
        totalBorrowed = totalBorrowed.sub((__borrow.amount).add(_feesUsed));
        uint _realPenaltyFees = _totalFees.sub(_feesUsed);
        totalReserve = totalReserve.add(reserveFactor.mul(_realPenaltyFees).div(mantissaScale));

        loanToBorrow[loan]= __borrow;
        __borrow.feesUsed = __borrow.feesAmount;

        require(controller.closeBorrowVerify(address(this), __borrow.borrower, __borrow.loan), Errors.FAIL_CLOSE_BORROW);

        //Emit the CloseLoan Event
        emit CloseLoan(__borrow.borrower, address(underlying), __borrow.amount, address(this), _totalFees, loan, false);
    }

    /**
    * @notice Kill a non-healthy Loan to collect rewards
    * @dev Kill a non-healthy Loan to collect rewards
    * @param loan Address of the Loan
    */
    function killBorrow(address loan) external override(PalPool) preventReentry {
        require(claimFromAave());
        address killer = msg.sender;
        //Fetch the corresponding Borrow
        //And check that the killer is not the Borrower, and the Loan is still active
        Borrow memory __borrow = loanToBorrow[loan];
        require(!__borrow.closed, Errors.LOAN_CLOSED);
        require(__borrow.borrower != killer, Errors.LOAN_OWNER);
        require(_updateInterest());

        //Calculate the amount of fee used, and check if the Loan is killable
        uint _feesUsed = (__borrow.amount.mul(borrowIndex).div(__borrow.borrowIndex)).sub(__borrow.amount);
        uint _loanHealthFactor = _feesUsed.mul(uint(1e18)).div(__borrow.feesAmount);
        require(_loanHealthFactor >= killFactor, Errors.NOT_KILLABLE);

        //Load the Loan
        PalLoanInterface _loan = PalLoanInterface(__borrow.loan);

        //Kill the Loan
        _loan.killLoan(killer, killerRatio);

        //Close the Loan, and update storage variables
        __borrow.closed = true;

        uint _killerFees = (__borrow.feesAmount).mul(killerRatio).div(uint(1e18));
        totalBorrowed = totalBorrowed.sub((__borrow.amount).add(_feesUsed));
        totalReserve = totalReserve.sub(_killerFees);

        loanToBorrow[loan]= __borrow;

        require(controller.killBorrowVerify(address(this), killer, __borrow.loan), Errors.FAIL_KILL_BORROW);

        //Emit the CloseLoan Event
        emit CloseLoan(__borrow.borrower, address(underlying), __borrow.amount, address(this), __borrow.feesAmount, loan, true);
    }
}