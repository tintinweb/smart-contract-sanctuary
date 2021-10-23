//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./utils/Clones.sol";
import "./IPalPool.sol";
import "./PalPoolStorage.sol";
import "./IPalLoan.sol";
//import "./PalLoan.sol";
import "./IPalToken.sol";
import "./IPaladinController.sol";
import "./IPalLoanToken.sol";
import "./interests/InterestInterface.sol";
import "./utils/IERC20.sol";
import "./utils/Admin.sol";
import "./utils/ReentrancyGuard.sol";
import {Errors} from  "./utils/Errors.sol";



/** @title PalPool contract  */
/// @author Paladin
contract PalPool is IPalPool, PalPoolStorage, Admin, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    modifier controllerOnly() {
        //allows only the Controller and the admin to call the function
        require(msg.sender == admin || msg.sender == address(controller), Errors.CALLER_NOT_CONTROLLER);
        _;
    }



    //Functions

    constructor(
        address _palToken,
        address _controller, 
        address _underlying,
        address _interestModule,
        address _delegator,
        address _palLoanToken
    ){
        //Set admin
        admin = msg.sender;

        //Set inital values & modules
        palToken = IPalToken(_palToken);
        controller = IPaladinController(_controller);
        underlying = IERC20(_underlying);
        accrualBlockNumber = block.number;
        interestModule = InterestInterface(_interestModule);
        borrowIndex = 1e18;
        delegator = _delegator;
        palLoanToken = IPalLoanToken(_palLoanToken);
    }

    /**
    * @notice Get the underlying balance for this Pool
    * @dev Get the underlying balance of this Pool
    * @return uint : balance of this pool in the underlying token
    */
    function underlyingBalance() public view returns(uint){
        //Return the balance of this contract for the underlying asset
        return underlying.balanceOf(address(this));
    }

    /**
    * @notice Deposit underlying in the Pool
    * @dev Deposit underlying, and mints palToken for the user
    * @param _amount Amount of underlying to deposit
    * @return bool : amount of minted palTokens
    */
    function deposit(uint _amount) public virtual override nonReentrant returns(uint){
        require(_updateInterest());

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();


        //Find the amount to mint depending on the amount to transfer
        uint _num = _amount.mul(mantissaScale);
        uint _toMint = _num.div(_exchRate);

        //Transfer the underlying to this contract
        //The amount of underlying needs to be approved before
        underlying.safeTransferFrom(msg.sender, address(this), _amount);

        //Mint the palToken
        require(palToken.mint(msg.sender, _toMint), Errors.FAIL_MINT);

        //Emit the Deposit event
        emit Deposit(msg.sender, _amount, address(this));

        //Use the controller to check if the minting was successfull
        require(controller.depositVerify(address(this), msg.sender, _toMint), Errors.FAIL_DEPOSIT);

        return _toMint;
    }

    /**
    * @notice Withdraw underliyng token from the Pool
    * @dev Transfer underlying token to the user, and burn the corresponding palToken amount
    * @param _amount Amount of palToken to return
    * @return uint : amount of underlying returned
    */
    function withdraw(uint _amount) public virtual override nonReentrant returns(uint){
        require(_updateInterest());
        require(balanceOf(msg.sender) >= _amount, Errors.INSUFFICIENT_BALANCE);

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();

        //Find the amount to return depending on the amount of palToken to burn
        uint _num = _amount.mul(_exchRate);
        uint _toReturn = _num.div(mantissaScale);

        //Check if the pool has enough underlying to return
        require(_toReturn <= underlyingBalance(), Errors.INSUFFICIENT_CASH);

        //Burn the corresponding palToken amount
        require(palToken.burn(msg.sender, _amount), Errors.FAIL_BURN);

        //Make the underlying transfer
        underlying.safeTransfer(msg.sender, _toReturn);

        //Use the controller to check if the burning was successfull
        require(controller.withdrawVerify(address(this), msg.sender, _toReturn), Errors.FAIL_WITHDRAW);

        //Emit the Withdraw event
        emit Withdraw(msg.sender, _amount, address(this));

        return _toReturn;
    }

    /**
    * @dev Create a Borrow, deploy a Loan Pool and delegate voting power
    * @param _delegatee Address to delegate the voting power to
    * @param _amount Amount of underlying to borrow
    * @param _feeAmount Amount of fee to pay to start the loan
    * @return uint : new PalLoanToken Id
    */
    function borrow(address _delegatee, uint _amount, uint _feeAmount) public virtual override nonReentrant returns(uint){
        //Need the pool to have enough liquidity, and the interests to be up to date
        require(_amount < underlyingBalance(), Errors.INSUFFICIENT_CASH);
        require(_delegatee != address(0), Errors.ZERO_ADDRESS);
        require(_amount > 0, Errors.ZERO_BORROW);
        require(_feeAmount >= minBorrowFees(_amount), Errors.BORROW_INSUFFICIENT_FEES);
        require(_updateInterest());

        address _borrower = msg.sender;

        //Update Total Borrowed & number active Loans
        numberActiveLoans = numberActiveLoans.add(1);
        totalBorrowed = totalBorrowed.add(_amount);

        IPalLoan _newLoan = IPalLoan(Clones.clone(delegator));

        //Send the borrowed amount of underlying tokens to the Loan
        underlying.safeTransfer(address(_newLoan), _amount);

        //And transfer the fees from the Borrower to the Loan
        underlying.safeTransferFrom(_borrower, address(_newLoan), _feeAmount);

        //Start the Loan (and delegate voting power)
        require(_newLoan.initiate(
            address(this),
            _borrower,
            address(underlying),
            _delegatee,
            _amount,
            _feeAmount
        ), Errors.FAIL_LOAN_INITIATE);

        //Add the new Loan to mappings
        loans.push(address(_newLoan));

        //Mint the palLoanToken linked to this new Loan
        uint256 _newTokenId = palLoanToken.mint(_borrower, address(this), address(_newLoan));

        //New Borrow struct for this Loan
        loanToBorrow[address(_newLoan)] = Borrow(
            _newTokenId,
            _delegatee,
            address(_newLoan),
            _amount,
            address(underlying),
            _feeAmount,
            0,
            borrowIndex,
            block.number,
            0,
            false,
            false
        );

        //Check the borrow succeeded
        require(
            controller.borrowVerify(address(this), _borrower, _delegatee, _amount, _feeAmount, address(_newLoan)), 
            Errors.FAIL_BORROW
        );

        //Emit the NewLoan Event
        emit NewLoan(
            _borrower,
            _delegatee,
            address(underlying),
            _amount,
            address(this),
            address(_newLoan),
            _newTokenId,
            block.number
        );

        //Return the PalLoanToken Id
        return _newTokenId;
    }

    /**
    * @notice Transfer the new fees to the Loan, and expand the Loan
    * @param _loan Address of the Loan
    * @param _feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function expandBorrow(address _loan, uint _feeAmount) public virtual override nonReentrant returns(uint){
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_feeAmount > 0);
        require(_updateInterest());
        
        //Load the Loan Pool contract & get Loan owner
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        _borrow.feesAmount = _borrow.feesAmount.add(_feeAmount);

        //Transfer the new fees to the Loan
        //If success, call the expand function of the Loan
        underlying.safeTransferFrom(_loanOwner, _borrow.loan, _feeAmount);

        require(_palLoan.expand(_feeAmount), Errors.FAIL_LOAN_EXPAND);

        emit ExpandLoan(
            _loanOwner,
            _borrow.delegatee,
            address(underlying),
            address(this),
            _borrow.feesAmount,
            _borrow.loan,
            _borrow.tokenId
        );

        return _feeAmount;
    }

    /**
    * @notice Close a Loan, and return the non-used fees to the Borrower.
    * If closed before the minimum required length, penalty fees are taken to the non-used fees
    * @dev Close a Loan, and return the non-used fees to the Borrower
    * @param _loan Address of the Loan
    */
    function closeBorrow(address _loan) public virtual override nonReentrant {
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Get Loan owner from the ERC721 contract
        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        //Load the Loan contract
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        //Calculates the amount of fees used
        uint _feesUsed = (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount);
        uint _penaltyFees = 0;
        uint _totalFees = _feesUsed;

        //If the Borrow is closed before the minimum length, calculates the penalty fees to pay
        // -> Number of block remaining to complete the minimum length * current Borrow Rate
        if(block.number < (_borrow.startBlock.add(minBorrowLength))){
            uint _currentBorrowRate = interestModule.getBorrowRate(address(this), underlyingBalance(), totalBorrowed, totalReserve);
            uint _missingBlocks = (_borrow.startBlock.add(minBorrowLength)).sub(block.number);
            _penaltyFees = _missingBlocks.mul(_borrow.amount.mul(_currentBorrowRate)).div(mantissaScale);
            _totalFees = _totalFees.add(_penaltyFees);
        }
    
        //Security so the Borrow can be closed if there are no more fees
        //(if the Borrow wasn't Killed yet, or the loan is closed before minimum time, and already paid fees aren't enough)
        if(_totalFees > _borrow.feesAmount){
            _totalFees = _borrow.feesAmount;
        }

        //Set the Borrow as closed
        _borrow.closed = true;
        _borrow.feesUsed = _totalFees;
        _borrow.closeBlock = block.number;

        //Remove the borrowed tokens + fees from the TotalBorrowed
        //Add to the Reserve the reserveFactor of Penalty Fees (if there is Penalty Fees)
        //And add the fees counted as potential Killer Fees to the Accrued Fees, since no killing was necessary

        numberActiveLoans = numberActiveLoans.sub(1);

        totalBorrowed = numberActiveLoans == 0 ? 0 : totalBorrowed.sub((_borrow.amount).add(_feesUsed)); //If not current active Loan, we can just reset the totalBorrowed to 0

        uint _realPenaltyFees = _totalFees.sub(_feesUsed);
        uint _killerFees = _feesUsed.mul(killerRatio).div(mantissaScale);
        totalReserve = totalReserve.add(reserveFactor.mul(_realPenaltyFees).div(mantissaScale));
        accruedFees = accruedFees.add(_killerFees).add(reserveFactor.mul(_realPenaltyFees).div(mantissaScale));
        
        //Close and destroy the loan
        _palLoan.closeLoan(_totalFees);

        //Burn the palLoanToken for this Loan
        require(palLoanToken.burn(_borrow.tokenId), Errors.FAIL_LOAN_TOKEN_BURN);

        require(controller.closeBorrowVerify(address(this), _loanOwner, _borrow.loan), Errors.FAIL_CLOSE_BORROW);

        //Emit the CloseLoan Event
        emit CloseLoan(
            _loanOwner,
            _borrow.delegatee,
            address(underlying),
            _borrow.amount,
            address(this),
            _totalFees,
            _loan,
            _borrow.tokenId,
            false
        );
    }

    /**
    * @notice Kill a non-healthy Loan to collect rewards
    * @dev Kill a non-healthy Loan to collect rewards
    * @param _loan Address of the Loan
    */
    function killBorrow(address _loan) public virtual override nonReentrant {
        address killer = msg.sender;
        //Fetch the corresponding Borrow
        //And check that the killer is not the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(!isLoanOwner(_loan, killer), Errors.LOAN_OWNER);
        require(_updateInterest());

        //Get the owner of the Loan through the ERC721 contract
        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        //Calculate the amount of fee used, and check if the Loan is killable
        uint _feesUsed = (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount);
        uint _loanHealthFactor = _feesUsed.mul(uint(1e18)).div(_borrow.feesAmount);
        require(_loanHealthFactor >= killFactor, Errors.NOT_KILLABLE);

        //Load the Loan
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        //Close the Loan, and update storage variables
        _borrow.closed = true;
        _borrow.killed = true;
        _borrow.feesUsed = _borrow.feesAmount;
        _borrow.closeBlock = block.number;

        //Remove the borrowed tokens + fees from the TotalBorrowed
        //Remove the amount paid as killer fees from the Reserve, and any over accrued interest in the Reserve & AccruedFees
        uint _overAccruedInterest = _loanHealthFactor <= mantissaScale ? 0 : _feesUsed.sub(_borrow.feesAmount);
        uint _killerFees = (_borrow.feesAmount).mul(killerRatio).div(mantissaScale);

        numberActiveLoans = numberActiveLoans.sub(1);

        totalBorrowed = numberActiveLoans == 0 ? 0 : totalBorrowed.sub((_borrow.amount).add(_feesUsed)); //If not current active Loan, we can just reset the totalBorrowed to 0

        totalReserve = totalReserve.sub(_killerFees).sub(_overAccruedInterest.mul(reserveFactor).div(mantissaScale));
        accruedFees = accruedFees.sub(_overAccruedInterest.mul(reserveFactor.sub(killerRatio)).div(mantissaScale));

        //Kill the Loan
        _palLoan.killLoan(killer, killerRatio);

        //Burn the palLoanToken for this Loan
        require(palLoanToken.burn(_borrow.tokenId), Errors.FAIL_LOAN_TOKEN_BURN);

        require(controller.killBorrowVerify(address(this), killer, _borrow.loan), Errors.FAIL_KILL_BORROW);

        //Emit the CloseLoan Event
        emit CloseLoan(
            _loanOwner,
            _borrow.delegatee,
            address(underlying),
            _borrow.amount,
            address(this),
            _borrow.feesAmount,
            _loan,
            _borrow.tokenId,
            true
        );
    }



    /**
    * @notice Change the delegatee of a Loan, and delegate him the voting power
    * @dev Change the delegatee in the Borrow struct and in the palLoan, then change the voting power delegation recipient
    * @param _loan Address of the Loan
    * @param _newDelegatee Address of the new voting power recipient
    */
    function changeBorrowDelegatee(address _loan, address _newDelegatee) public virtual override nonReentrant {
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(_newDelegatee != address(0), Errors.ZERO_ADDRESS);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Load the Loan Pool contract
        IPalLoan _palLoan = IPalLoan(_borrow.loan);

        //Update storage data
        _borrow.delegatee = _newDelegatee;

        //Call the delegation logic in the palLoan to change the votong power recipient
        require(_palLoan.changeDelegatee(_newDelegatee), Errors.FAIL_LOAN_DELEGATEE_CHANGE);

        //Emit the Event
        emit ChangeLoanDelegatee(
            palLoanToken.ownerOf(_borrow.tokenId),
            _newDelegatee,
            address(underlying),
            address(this),
            _borrow.loan,
            _borrow.tokenId
        );

    }


    /**
    * @notice Return the user's palToken balance
    * @dev Links the PalToken balanceOf() method
    * @param _account User address
    * @return uint256 : user palToken balance (in wei)
    */
    function balanceOf(address _account) public view override returns(uint){
        return palToken.balanceOf(_account);
    }


    /**
    * @notice Return the corresponding balance of the pool underlying token depending on the user's palToken balance
    * @param _account User address
    * @return uint256 : corresponding balance in the underlying token (in wei)
    */
    function underlyingBalanceOf(address _account) external view override returns(uint){
        uint _balance = palToken.balanceOf(_account);
        if(_balance == 0){
            return 0;
        }
        uint _exchRate = _exchangeRate();
        uint _num = _balance.mul(_exchRate);
        return _num.div(mantissaScale);
    }


    /**
    * @notice Return true is the given address is the owner of the palLoanToken for the given palLoan
    * @param _loanAddress Address of the Loan
    * @param _user User address
    * @return bool : true if owner
    */
    function isLoanOwner(address _loanAddress, address _user) public view override returns(bool){
        return palLoanToken.allOwnerOf(idOfLoan(_loanAddress)) == _user;
    }


    /**
    * @notice Return the token Id of the palLoanToken linked to this palLoan
    * @param _loanAddress Address of the Loan
    * @return uint256 : palLoanToken token Id
    */
    function idOfLoan(address _loanAddress) public view override returns(uint256){
        return loanToBorrow[_loanAddress].tokenId;
    }



    /**
    * @notice Return the list of all Loans for this Pool (closed and active)
    * @return address[] : list of Loans
    */
    function getLoansPools() external view override returns(address [] memory){
        //Return the addresses of all loans (old ones and active ones)
        return loans;
    }
    
    /**
    * @notice Return all the Loans for a given address
    * @param _borrower Address of the user
    * @return address : list of Loans
    */
    function getLoansByBorrower(address _borrower) external view override returns(address [] memory){
        return palLoanToken.allLoansOfForPool(_borrower, address(this));
    }

    
    /**
    * @notice Return the stored Borrow data for a given Loan
    * @dev Return the Borrow data for a given Loan
    * @param _loanAddress Address of the palLoan
    * Composants of a Borrow struct
    */
    function getBorrowData(address _loanAddress) external view override returns(
        address _borrower,
        address _delegatee,
        address _loan,
        uint256 _palLoanTokenId,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        uint _startBlock,
        uint _closeBlock,
        bool _closed,
        bool _killed
    ){
        //Return the data inside a Borrow struct
        Borrow memory _borrow = loanToBorrow[_loanAddress];
        return (
            //Get the Loan owner through the ERC721 contract
            palLoanToken.allOwnerOf(_borrow.tokenId),
            _borrow.delegatee,
            _borrow.loan,
            _borrow.tokenId,
            _borrow.amount,
            _borrow.underlying,
            _borrow.feesAmount,
            //Calculate amount of fees used
            _borrow.closed ? _borrow.feesUsed : (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount),
            _borrow.startBlock,
            _borrow.closeBlock,
            _borrow.closed,
            _borrow.killed
        );

    }
    
    /**
    * @notice Get the Borrow Rate for this Pool
    * @dev Get the Borrow Rate from the Interest Module
    * @return uint : Borrow Rate (scale 1e18)
    */
    function borrowRatePerBlock() external view override returns (uint){
        return interestModule.getBorrowRate(address(this), underlyingBalance(), totalBorrowed, totalReserve);
    }
    
    /**
    * @notice Get the Supply Rate for this Pool
    * @dev Get the Supply Rate from the Interest Module
    * @return uint : Supply Rate (scale 1e18)
    */
    function supplyRatePerBlock() external view override returns (uint){
        return interestModule.getSupplyRate(address(this), underlyingBalance(), totalBorrowed, totalReserve, reserveFactor);
    }

    
    /**
    * @dev Calculates the current exchange rate
    * @return uint : current exchange rate (scale 1e18)
    */
    function _exchangeRate() internal view returns (uint){
        uint _totalSupply = palToken.totalSupply();
        //If no palTokens where minted, use the initial exchange rate
        if(_totalSupply == 0){
            return initialExchangeRate;
        }
        else{
            // Exchange Rate = (Cash + Borrows - Reserve) / Supply
            uint _cash = underlyingBalance();
            uint _availableCash = _cash.add(totalBorrowed).sub(totalReserve);
            return _availableCash.mul(1e18).div(_totalSupply);
        }
    }

    /**
    * @notice Get the current exchange rate for the palToken
    * @dev Updates interest & Calls internal function _exchangeRate
    * @return uint : current exchange rate (scale 1e18)
    */
    function exchangeRateCurrent() external override returns (uint){
        _updateInterest();
        return _exchangeRate();
    }
    
    /**
    * @notice Get the stored exchange rate for the palToken
    * @dev Calls internal function _exchangeRate
    * @return uint : current exchange rate (scale 1e18)
    */
    function exchangeRateStored() external view override returns (uint){
        return _exchangeRate();
    }

    /**
    * @notice Return the minimum of fees to pay to borrow
    * @dev Fees to pay for a Borrow (for the minimum borrow length)
    * @return uint : minimum amount (in wei)
    */
    function minBorrowFees(uint _amount) public view override returns (uint){
        require(_amount < underlyingBalance(), Errors.INSUFFICIENT_CASH);
        //Future Borrow Rate with the amount to borrow counted as already borrowed
        uint _borrowRate = interestModule.getBorrowRate(address(this), underlyingBalance().sub(_amount), totalBorrowed.add(_amount), totalReserve);
        uint _minFees = minBorrowLength.mul(_amount.mul(_borrowRate)).div(mantissaScale);
        return _minFees > 0 ? _minFees : 1;
    }

    function isKillable(address _loan) external view override returns(bool){
        Borrow memory __borrow = loanToBorrow[_loan];
        if(__borrow.closed){
            return false;
        }

        //Calculate the amount of fee used, and check if the Loan is killable
        uint _feesUsed = (__borrow.amount.mul(borrowIndex).div(__borrow.borrowIndex)).sub(__borrow.amount);
        uint _loanHealthFactor = _feesUsed.mul(uint(1e18)).div(__borrow.feesAmount);
        return _loanHealthFactor >= killFactor;
    }

    /**
    * @dev Updates Inetrest and variables for this Pool
    * @return bool : Update success
    */
    function _updateInterest() public returns (bool){
        //Get the current block
        //Check if the Pool has already been updated this block
        uint _currentBlock = block.number;
        if(_currentBlock == accrualBlockNumber){
            return true;
        }

        //Get Pool variables from Storage
        uint _cash = underlyingBalance();
        uint _borrows = totalBorrowed;
        uint _reserves = totalReserve;
        uint _accruedFees = accruedFees;
        uint _oldBorrowIndex = borrowIndex;

        //Get the Borrow Rate from the Interest Module
        uint _borrowRate = interestModule.getBorrowRate(address(this), _cash, _borrows, _reserves);

        //Delta of blocks since the last update
        uint _ellapsedBlocks = _currentBlock.sub(accrualBlockNumber);

        /*
        Interest Factor = Borrow Rate * Ellapsed Blocks
        Accumulated Interests = Interest Factor * Borrows
        Total Borrows = Borrows + Accumulated Interests
        Total Reserve = Reserve + Accumulated Interests * Reserve Factor
        Accrued Fees = Accrued Fees + Accumulated Interests * (Reserve Factor - Killer Ratio) -> (available fees should not count potential fees to send to killers)
        Borrow Index = old Borrow Index + old Borrow Index * Interest Factor 
        */
        uint _interestFactor = _borrowRate.mul(_ellapsedBlocks);
        uint _accumulatedInterest = _interestFactor.mul(_borrows).div(mantissaScale);
        uint _newBorrows = _borrows.add(_accumulatedInterest);
        uint _newReserve = _reserves.add(reserveFactor.mul(_accumulatedInterest).div(mantissaScale));
        uint _newAccruedFees = _accruedFees.add((reserveFactor.sub(killerRatio)).mul(_accumulatedInterest).div(mantissaScale));
        uint _newBorrowIndex = _oldBorrowIndex.add(_interestFactor.mul(_oldBorrowIndex).div(1e18));

        //Update storage
        totalBorrowed = _newBorrows;
        totalReserve = _newReserve;
        accruedFees = _newAccruedFees;
        borrowIndex = _newBorrowIndex;
        accrualBlockNumber = _currentBlock;

        return true;
    }

    


    // Admin Functions

    /**
    * @notice Set a new Controller
    * @dev Loads the new Controller for the Pool
    * @param  _newController address of the new Controller
    */
    function setNewController(address _newController) external override controllerOnly {
        controller = IPaladinController(_newController);
    }

    /**
    * @notice Set a new Interest Module
    * @dev Load a new Interest Module
    * @param _interestModule address of the new Interest Module
    */
    function setNewInterestModule(address _interestModule) external override adminOnly {
        interestModule = InterestInterface(_interestModule);
    }

    /**
    * @notice Set a new Delegator
    * @dev Change Delegator address
    * @param _delegator address of the new Delegator
    */
    function setNewDelegator(address _delegator) external override adminOnly {
        delegator = _delegator;
    }


    /**
    * @notice Set a new Minimum Borrow Length
    * @dev Change Minimum Borrow Length value
    * @param _length new Minimum Borrow Length
    */
    function updateMinBorrowLength(uint _length) external override adminOnly {
        require(_length > 0, Errors.INVALID_PARAMETERS);
        minBorrowLength = _length;
    }


    /**
    * @notice Update the Pool Reserve Factor & Killer Ratio
    * @dev Change Reserve Factor value & Killer Ratio value
    * @param _reserveFactor new % of fees to set as Reserve
    * @param _killerRatio new Ratio of Fees to pay the killer
    */
    function updatePoolFactors(uint _reserveFactor, uint _killerRatio) external override adminOnly {
        require(_reserveFactor > 0 && _killerRatio > 0 && _reserveFactor >= _killerRatio, 
            Errors.INVALID_PARAMETERS
        );
        reserveFactor = _reserveFactor;
        killerRatio = _killerRatio;
    }


    /**
    * @notice Add underlying in the Pool Reserve
    * @dev Transfer underlying token from the admin to the Pool
    * @param _amount Amount of underlying to transfer
    */
    function addReserve(uint _amount) external override adminOnly {
        require(_updateInterest());

        totalReserve = totalReserve.add(_amount);

        //Transfer from the admin to the Pool
        underlying.safeTransferFrom(admin, address(this), _amount);

        emit AddReserve(_amount);
    }

    /**
    * @notice Remove underlying from the Pool Reserve
    * @dev Transfer underlying token from the Pool to the admin
    * @param _amount Amount of underlying to transfer
    */
    function removeReserve(uint _amount) external override adminOnly {
        //Check if there is enough in the reserve
        require(_updateInterest());
        require(_amount <= underlyingBalance() && _amount <= totalReserve, Errors.RESERVE_FUNDS_INSUFFICIENT);

        totalReserve = totalReserve.sub(_amount);

        //Transfer underlying to the admin
        underlying.safeTransfer(admin, _amount);

        emit RemoveReserve(_amount);
    }

    /**
    * @notice Method to allow the Controller (or admin) to withdraw protocol fees
    * @dev Transfer underlying token from the Pool to the controller (or admin)
    * @param _amount Amount of underlying to transfer
    * @param _recipient Address to receive the token
    */
    function withdrawFees(uint _amount, address _recipient) external override controllerOnly {
        //Check if there is enough in the reserve
        require(_updateInterest());
        require(_amount<= accruedFees && _amount <= totalReserve, Errors.FEES_ACCRUED_INSUFFICIENT);

        //Substract from accruedFees (to track how much fees the Controller can withdraw since last time)
        //And also from the REserve, since the fees are part of the Reserve
        accruedFees = accruedFees.sub(_amount);
        totalReserve = totalReserve.sub(_amount);

        //Transfer fees to the recipient
        underlying.safeTransfer(_recipient, _amount);

        emit WithdrawFees(_amount);
    }

}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

/** @title palPool Interface  */
/// @author Paladin
interface IPalPool {

    //Events
    /** @notice Event when an user deposit tokens in the pool */
    event Deposit(address user, uint amount, address palPool);
    /** @notice Event when an user withdraw tokens from the pool */
    event Withdraw(address user, uint amount, address palPool);
    /** @notice Event when a loan is started */
    event NewLoan(
        address borrower,
        address delegatee,
        address underlying,
        uint amount,
        address palPool,
        address loanAddress,
        uint256 palLoanTokenId,
        uint startBlock);
    /** @notice Event when the fee amount in the loan is updated */
    event ExpandLoan(
        address borrower,
        address delegatee,
        address underlying,
        address palPool,
        uint newFeesAmount,
        address loanAddress,
        uint256 palLoanTokenId
    );
    /** @notice Event when the delegatee of the loan is updated */
    event ChangeLoanDelegatee(
        address borrower,
        address newDelegatee,
        address underlying,
        address palPool,
        address loanAddress,
        uint256 palLoanTokenId
    );
    /** @notice Event when a loan is ended */
    event CloseLoan(
        address borrower,
        address delegatee,
        address underlying,
        uint amount,
        address palPool,
        uint usedFees,
        address loanAddress,
        uint256 palLoanTokenId,
        bool wasKilled
    );

    /** @notice Reserve Events */
    event AddReserve(uint amount);
    event RemoveReserve(uint amount);
    event WithdrawFees(uint amount);


    //Functions
    function deposit(uint _amount) external returns(uint);
    function withdraw(uint _amount) external returns(uint);
    
    function borrow(address _delegatee, uint _amount, uint _feeAmount) external returns(uint);
    function expandBorrow(address _loanPool, uint _feeAmount) external returns(uint);
    function closeBorrow(address _loanPool) external;
    function killBorrow(address _loanPool) external;
    function changeBorrowDelegatee(address _loanPool, address _newDelegatee) external;

    function balanceOf(address _account) external view returns(uint);
    function underlyingBalanceOf(address _account) external view returns(uint);

    function isLoanOwner(address _loanAddress, address _user) external view returns(bool);
    function idOfLoan(address _loanAddress) external view returns(uint256);

    function getLoansPools() external view returns(address [] memory);
    function getLoansByBorrower(address _borrower) external view returns(address [] memory);
    function getBorrowData(address _loanAddress) external view returns(
        address _borrower,
        address _delegatee,
        address _loanPool,
        uint256 _palLoanTokenId,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        uint _startBlock,
        uint _closeBlock,
        bool _closed,
        bool _killed
    );

    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    function minBorrowFees(uint _amount) external view returns (uint);

    function isKillable(address _loan) external view returns(bool);

    //Admin functions : 
    function setNewController(address _newController) external;
    function setNewInterestModule(address _interestModule) external;
    function setNewDelegator(address _delegator) external;

    function updateMinBorrowLength(uint _length) external;
    function updatePoolFactors(uint _reserveFactor, uint _killerRatio) external;

    function addReserve(uint _amount) external;
    function removeReserve(uint _amount) external;
    function withdrawFees(uint _amount, address _recipient) external;

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./IPaladinController.sol";
import "./IPalLoanToken.sol";
import "./interests/InterestInterface.sol";
import "./IPalPool.sol";
import "./IPalToken.sol";
import "./utils/IERC20.sol";

/** @title palPool Storage contract  */
/// @author Paladin
contract PalPoolStorage {

    /** @notice Struct of a Borrow */
    struct Borrow {
        //id of the palLoanToken
        uint256 tokenId;
        //address of the delegatee
        address delegatee;
        //address of the Loan Pool contract holding the loan
        address loan;
        //amount of the loan
        uint amount;
        //address of the underlying for this loan
        address underlying;
        //amount of fees (in the underlying token) paid by the borrower
        uint feesAmount;
        //amount of fees (in the underlying token) already used
        uint feesUsed;
        //borrow index at the loan creation
        uint borrowIndex;
        //start block for the Borrow
        uint startBlock;
        //block where the Borrow was closed
        uint closeBlock;
        //false if the loan is active, true if loan was closed or killed
        bool closed;
        //false when the loan is active, true if the loan was killed
        bool killed;
    }

    //palPool variables & Mappings

    /** @notice ERC721 palLoanToken */
    IPalLoanToken public palLoanToken;

    /** @notice Underlying ERC20 token of this Pool */
    IERC20 public underlying;

    /** @notice ERC20 palToken for this Pool */
    IPalToken public palToken;

    /** @dev Boolean to prevent reentry in some functions */
    bool internal entered = false;

    /** @notice Total of the current Reserve */
    uint public totalReserve;
    /** @notice Total of underlying tokens "borrowed" (in Loan Pool contracts) */
    uint public totalBorrowed;
    /** @notice Total fees accrued since last withdraw */
    /** (this amount id part of the Reserve : we should always have totalReserve >= accruedFees) */
    uint public accruedFees;

    /** @notice Minimum duration of a Borrow (in blocks) */
    uint public minBorrowLength = 45290;
    

    /** @dev Health Factor to kill a loan */
    uint public constant killFactor = 0.95e18;
    /** @dev Ratio of the borrow fees to pay the killer of a loan */
    uint public killerRatio = 0.1e18;

    /** @dev Base value to mint palTokens */
    uint internal constant initialExchangeRate = 1e18;
    /** @notice Part of the borrows interest to set as Reserves */
    uint public reserveFactor = 0.2e18;
    /** @notice Last block where the interest where updated for this pool */
    uint public accrualBlockNumber;
    /** @notice Borrow Index : increase at each interest update to represent borrows interests increasing */
    uint public borrowIndex;

    /** @dev Scale used to represent decimal values */
    uint constant internal mantissaScale = 1e18;

    /** @dev Mapping of Loan Pool contract address to Borrow struct */
    mapping (address => Borrow) internal loanToBorrow;
    /** @dev List of all Loans (active & closed) */
    address[] internal loans;
    /** @dev Current number of active Loans */
    uint public numberActiveLoans;

    //Modules

    /** @notice Paladin Controller contract */
    IPaladinController public controller;
    /** @dev Current Inetrest Module */
    InterestInterface internal interestModule;

    /** @dev Delegator for the underlying governance token */
    address internal delegator;
    
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Interface for PalLoan contract  */
/// @author Paladin
interface IPalLoan {

    // Variables
    function underlying() external view returns(address);
    function amount() external view returns(uint);
    function borrower() external view returns(address);
    function delegatee() external view returns(address);
    function motherPool() external view returns(address);
    function feesAmount() external view returns(uint);

    // Functions
    function initiate(
        address _motherPool,
        address _borrower,
        address _underlying,
        address _delegatee,
        uint _amount,
        uint _feesAmount
    ) external returns(bool);
    function expand(uint _newFeesAmount) external returns(bool);
    function closeLoan(uint _usedAmount) external;
    function killLoan(address _killer, uint _killerRatio) external;
    function changeDelegatee(address _delegatee) external returns(bool);
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


/** @title simple PalToken Interface to be used inside the PalPool contract  */
/// @author Paladin
interface IPalToken {

    function mint(address _user, uint _toMint) external returns(bool);

    function burn(address _user, uint _toBurn) external returns(bool);

    function balanceOf(address owner) external view returns(uint);

    function totalSupply() external view returns (uint256);

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Paladin Controller Interface  */
/// @author Paladin
interface IPaladinController {
    
    //Events

    /** @notice Event emitted when a new token & pool are added to the list */
    event NewPalPool(address palPool, address palToken);
    /** @notice Event emitted when a token & pool are removed from the list */
    event RemovePalPool(address palPool, address palToken);


    //Functions
    function isPalPool(address pool) external view returns(bool);
    function getPalTokens() external view returns(address[] memory);
    function getPalPools() external view returns(address[] memory);
    function setInitialPools(address[] memory palTokens, address[] memory palPools) external returns(bool);
    function addNewPool(address palToken, address palPool) external returns(bool);
    function removePool(address _palPool) external returns(bool);

    function withdrawPossible(address palPool, uint amount) external view returns(bool);
    function borrowPossible(address palPool, uint amount) external view returns(bool);

    function depositVerify(address palPool, address dest, uint amount) external view returns(bool);
    function withdrawVerify(address palPool, address dest, uint amount) external view returns(bool);
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanAddress) external view returns(bool);
    function expandBorrowVerify(address palPool, address loanAddress, uint newFeesAmount) external view returns(bool);
    function closeBorrowVerify(address palPool, address borrower, address loanAddress) external view returns(bool);
    function killBorrowVerify(address palPool, address killer, address loanAddress) external view returns(bool);

    //Admin functions
    function setPoolsNewController(address _newController) external returns(bool);
    function withdrawFromPool(address _pool, uint _amount, address _recipient) external returns(bool);

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/IERC721.sol";

/** @title palLoanToken Interface  */
/// @author Paladin
interface IPalLoanToken is IERC721 {

    //Events

    /** @notice Event when a new Loan Token is minted */
    event NewLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);
    /** @notice Event when a Loan Token is burned */
    event BurnLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);


    //Functions
    function mint(address to, address palPool, address palLoan) external returns(uint256);
    function burn(uint256 tokenId) external returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenOfByIndex(address owner, uint256 tokenIdex) external view returns (uint256);
    function loanOf(uint256 tokenId) external view returns(address);
    function poolOf(uint256 tokenId) external view returns(address);
    function loansOf(address owner) external view returns(address[] memory);
    function tokensOf(address owner) external view returns(uint256[] memory);
    function loansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allTokensOf(address owner) external view returns(uint256[] memory);
    function allLoansOf(address owner) external view returns(address[] memory);
    function allLoansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allOwnerOf(uint256 tokenId) external view returns(address);

    function isBurned(uint256 tokenId) external view returns(bool);

    //Admin functions
    function setNewController(address _newController) external;
    function setNewBaseURI(string memory _newBaseURI) external;

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Interest Module Interface  */
/// @author Paladin
interface InterestInterface {

    function getSupplyRate(address palPool, uint cash, uint borrows, uint reserves, uint reserveFactor) external view returns(uint);
    function getBorrowRate(address palPool, uint cash, uint borrows, uint reserves) external view returns(uint);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


/** @title Admin contract  */
/// @author Paladin
contract Admin {

    /** @notice (Admin) Event when the contract admin is updated */
    event NewAdmin(address oldAdmin, address newAdmin);

    /** @dev Admin address for this contract */
    address payable internal admin;
    
    modifier adminOnly() {
        //allows only the admin of this contract to call the function
        require(msg.sender == admin, '1');
        _;
    }

        /**
    * @notice Set a new Admin
    * @dev Changes the address for the admin parameter
    * @param _newAdmin address of the new Controller Admin
    */
    function setNewAdmin(address payable _newAdmin) external adminOnly {
        address _oldAdmin = admin;
        admin = _newAdmin;

        emit NewAdmin(_oldAdmin, _newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

library Errors {
    // Admin error
    string public constant CALLER_NOT_ADMIN = '1'; // 'The caller must be the admin'
    string public constant CALLER_NOT_CONTROLLER = '29'; // 'The caller must be the admin or the controller'
    string public constant CALLER_NOT_ALLOWED_POOL = '30';  // 'The caller must be a palPool listed in the controller'
    string public constant CALLER_NOT_MINTER = '31';

    // ERC20 type errors
    string public constant FAIL_TRANSFER = '2';
    string public constant FAIL_TRANSFER_FROM = '3';
    string public constant BALANCE_TOO_LOW = '4';
    string public constant ALLOWANCE_TOO_LOW = '5';
    string public constant SELF_TRANSFER = '6';

    // PalPool errors
    string public constant INSUFFICIENT_CASH = '9';
    string public constant INSUFFICIENT_BALANCE = '10';
    string public constant FAIL_DEPOSIT = '11';
    string public constant FAIL_LOAN_INITIATE = '12';
    string public constant FAIL_BORROW = '13';
    string public constant ZERO_BORROW = '27';
    string public constant BORROW_INSUFFICIENT_FEES = '23';
    string public constant LOAN_CLOSED = '14';
    string public constant NOT_LOAN_OWNER = '15';
    string public constant LOAN_OWNER = '16';
    string public constant FAIL_LOAN_EXPAND = '17';
    string public constant NOT_KILLABLE = '18';
    string public constant RESERVE_FUNDS_INSUFFICIENT = '19';
    string public constant FAIL_MINT = '20';
    string public constant FAIL_BURN = '21';
    string public constant FAIL_WITHDRAW = '24';
    string public constant FAIL_CLOSE_BORROW = '25';
    string public constant FAIL_KILL_BORROW = '26';
    string public constant ZERO_ADDRESS = '22';
    string public constant INVALID_PARAMETERS = '28'; 
    string public constant FAIL_LOAN_DELEGATEE_CHANGE = '32';
    string public constant FAIL_LOAN_TOKEN_BURN = '33';
    string public constant FEES_ACCRUED_INSUFFICIENT = '34';

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}