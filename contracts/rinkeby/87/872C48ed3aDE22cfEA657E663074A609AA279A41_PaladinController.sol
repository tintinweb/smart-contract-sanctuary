//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./utils/SafeMath.sol";
import "./PaladinControllerInterface.sol";
import "./PalPool.sol";
import "./utils/IERC20.sol";

/** @title Paladin Controller contract  */
/// @author Paladin
contract PaladinController is PaladinControllerInterface {
    using SafeMath for uint;
    

    /** @dev Admin address for this contract */
    address payable internal admin;

    /** @notice List of current active palToken Pools */
    address[] public palTokens;
    address[] public palPools;

    bool private initialized = false;

    constructor(){
        admin = msg.sender;
    }

    //Check if an address is a valid palPool
    function isPalPool(address _pool) public view override returns(bool){
        //Check if the given address is in the palPools list
        for(uint i = 0; i < palPools.length; i++){
            if(palPools[i] == _pool){
                return true;
            }
        }
        return false;
    }


    /**
    * @notice Get all the PalTokens listed in the controller
    * @return address[] : List of PalToken addresses
    */
    function getPalTokens() external view override returns(address[] memory){
        return palTokens;
    }


    /**
    * @notice Get all the PalPools listed in the controller
    * @return address[] : List of PalPool addresses
    */
    function getPalPools() external view override returns(address[] memory){
        return palPools;
    }

    /**
    * @notice Set the basic PalPools/PalTokens controller list
    * @param _palTokens array of address of PalToken contracts
    * @param _palPools array of address of PalPool contracts
    * @return bool : Success
    */ 
    function setInitialPools(address[] memory _palTokens, address[] memory _palPools) external override returns(bool){
        require(msg.sender == admin, "Admin function");
        require(!initialized, "Lists already set");
        palPools = _palPools;
        palTokens = _palTokens;
        initialized = true;
        return true;
    }
    
    /**
    * @notice Add a new PalPool/PalToken couple to the controller list
    * @param _palToken address of the PalToken contract
    * @param _palPool address of the PalPool contract
    * @return bool : Success
    */ 
    function addNewPool(address _palToken, address _palPool) external override returns(bool){
        //Add a new address to the palToken & palPool list
        require(msg.sender == admin, "Admin function");
        require(!isPalPool(_palPool), "Already added");
        palTokens.push(_palToken);
        palPools.push(_palPool);
        return true;
    }


    /**
    * @notice Check if the given PalPool has enough cash to make a withdraw
    * @param palPool address of PalPool
    * @param amount amount withdrawn
    * @return bool : true if possible
    */
    function withdrawPossible(address palPool, uint amount) external view override returns(bool){
        //Get the underlying balance of the palPool contract to check if the action is possible
        PalPool _palPool = PalPool(palPool);
        IERC20 underlying = _palPool.underlying();
        return(underlying.balanceOf(palPool) >= amount);
    }
    

    /**
    * @notice Check if the given PalPool has enough cash to borrow
    * @param palPool address of PalPool
    * @param amount amount ot borrow
    * @return bool : true if possible
    */
    function borrowPossible(address palPool, uint amount) external view override returns(bool){
        //Get the underlying balance of the palPool contract to check if the action is possible
        PalPool _palPool = PalPool(palPool);
        IERC20 underlying = _palPool.underlying();
        return(underlying.balanceOf(palPool) >= amount);
    }
    

    /**
    * @notice Check if Deposit was correctly done
    * @param palPool address of PalPool
    * @param dest address to send the minted palTokens
    * @param amount amount of underlying tokens deposited
    * @return bool : Verification Success
    */
    function depositVerify(address palPool, address dest, uint amount) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");

        palPool;
        dest;
        amount;
        
        //no method yet 
        return true;
    }


    /**
    * @notice Check if Withdraw was correctly done
    * @param palPool address of PalPool
    * @param dest address to send the underlying tokens
    * @param amount amount of PalToken returned
    * @return bool : Verification Success
    */
    function withdrawVerify(address palPool, address dest, uint amount) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        dest;
        amount;

        //no method yet 
        return true;
    }
    

    /**
    * @notice Check if Borrow was correctly done
    * @param palPool address of PalPool
    * @param borrower borrower's address 
    * @param amount amount of token borrowed
    * @param feesAmount amount of fees paid by the borrower
    * @param loanPool address of the new deployed PalLoan
    * @return bool : Verification Success
    */
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanPool) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        //Check if the borrow was successful
        PalPoolInterface _palPool = PalPoolInterface(palPool);
        (
            address _borrower,
            address _delegatee,
            address _loan,
            uint _tokenId,
            uint _amount,
            address _underlying,
            uint _feesAmount,
            ,
            ,
            ,
            bool _closed,
        ) = _palPool.getBorrowData(loanPool);

        _underlying;
        _loan;
        _tokenId;

        return(borrower == _borrower && delegatee == _delegatee && amount == _amount && feesAmount == _feesAmount && !_closed);
    }


    /**
    * @notice Check if Borrow Closing was correctly done
    * @param palPool address of PalPool
    * @param borrower borrower's address
    * @param loanPool address of the PalLoan contract to close
    * @return bool : Verification Success
    */
    function closeBorrowVerify(address palPool, address borrower, address loanPool) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        borrower;
        loanPool;
        
        //no method yet 
        return true;
    }


    /**
    * @notice Check if Borrow Killing was correctly done
    * @param palPool address of PalPool
    * @param killer killer's address
    * @param loanPool address of the PalLoan contract to kill
    * @return bool : Verification Success
    */
    function killBorrowVerify(address palPool, address killer, address loanPool) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        killer;
        loanPool;
        
        //no method yet 
        return true;
    }

        
    
    //Admin function

    /**
    * @notice Set a new Controller Admin
    * @dev Changes the address for the admin parameter
    * @param _newAdmin address of the new Controller Admin
    * @return bool : Update success
    */
    function setNewAdmin(address payable _newAdmin) external override returns(bool){
        require(msg.sender == admin, "Admin function");
        admin = _newAdmin;
        return true;
    }


    function setPoolsNewController(address _newController) external override returns(bool){
        require(msg.sender == admin, "Admin function");
        for(uint i = 0; i < palPools.length; i++){
            PalPoolInterface _palPool = PalPoolInterface(palPools[i]);
            _palPool.setNewController(_newController);
        }
        return true;
    }


    function removeReserveFromPool(address _pool, uint _amount, address _recipient) external override returns(bool){
        require(msg.sender == admin, "Admin function");
        PalPoolInterface _palPool = PalPoolInterface(_pool);
        _palPool.removeReserve(_amount, _recipient);
        return true;
    }


    function removeReserveFromAllPools(address _recipient) external override returns(bool){
        //TO DO
        //Do we swap all the funds into 1 coin ?
        //Do we send each of them, and another contract takes care of that ?
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
interface PaladinControllerInterface {
    
    //Events

    /** @notice Event emitted when a new token & pool are added to the list */
    event NewPalPool(address palPool);

    /** @notice Event emitted when the contract admni is updated */
    event NewAdmin(address oldAdmin, address newAdmin);


    //Functions
    function isPalPool(address pool) external view returns(bool);
    function getPalTokens() external view returns(address[] memory);
    function getPalPools() external view returns(address[] memory);
    function setInitialPools(address[] memory palTokens, address[] memory palPools) external returns(bool);
    function addNewPool(address palToken, address palPool) external returns(bool);

    function withdrawPossible(address palPool, uint amount) external view returns(bool);
    function borrowPossible(address palPool, uint amount) external view returns(bool);

    function depositVerify(address palPool, address dest, uint amount) external view returns(bool);
    function withdrawVerify(address palPool, address dest, uint amount) external view returns(bool);
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanPool) external view returns(bool);
    function closeBorrowVerify(address palPool, address borrower, address loanPool) external view returns(bool);
    function killBorrowVerify(address palPool, address killer, address loanPool) external view returns(bool);

    //Admin functions
    function setNewAdmin(address payable _newAdmin) external returns(bool);
    function setPoolsNewController(address _newController) external returns(bool);
    function removeReserveFromPool(address _pool, uint _amount, address _recipient) external returns(bool);
    function removeReserveFromAllPools(address _recipient) external returns(bool);

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

import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./PalPoolInterface.sol";
import "./PalPoolStorage.sol";
import "./PalLoanInterface.sol";
import "./PalLoan.sol";
import "./PalToken.sol";
import "./PaladinControllerInterface.sol";
import "./PalLoanTokenInterface.sol";
import "./InterestInterface.sol";
import "./utils/IERC20.sol";
import "./utils/Admin.sol";
import {Errors} from  "./utils/Errors.sol";



/** @title palPool contract  */
/// @author Paladin
contract PalPool is PalPoolInterface, PalPoolStorage, Admin {
    using SafeMath for uint;
    using SafeERC20 for IERC20;



    modifier preventReentry() {
        //modifier to prevent reentry in some functions
        require(!entered);
        entered = true;
        _;
        entered = false;
    }


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
        palToken = PalToken (_palToken);
        controller = PaladinControllerInterface(_controller);
        underlying = IERC20(_underlying);
        accrualBlockNumber = block.number;
        interestModule = InterestInterface(_interestModule);
        borrowIndex = 1e36;
        delegator = _delegator;
        palLoanToken = PalLoanTokenInterface(_palLoanToken);

        //Set base values
        totalBorrowed = 0;
        totalReserve = 0;
    }

    /**
    * @notice Get the underlying balance for this Pool
    * @dev Get the underlying balance of this Pool
    * @return uint : balance of this pool in the underlying token
    */
    function _underlyingBalance() public view returns(uint){
        //Return the balance of this contract for the underlying asset
        return underlying.balanceOf(address(this));
    }

    /**
    * @notice Deposit underlying in the Pool
    * @dev Deposit underlying, and mints palToken for the user
    * @param _amount Amount of underlying to deposit
    * @return bool : amount of minted palTokens
    */
    function deposit(uint _amount) public virtual override preventReentry returns(uint){
        require(_updateInterest());

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();

        //Transfer the underlying to this contract
        //The amount of underlying needs to be approved before
        underlying.safeTransferFrom(msg.sender, address(this), _amount);


        //Find the amount to mint depending of the previous transfer
        uint _num = _amount.mul(mantissaScale);
        uint _toMint = _num.div(_exchRate);

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
    function withdraw(uint _amount) public virtual override preventReentry returns(uint){
        require(_updateInterest());
        require(balanceOf(msg.sender) >= _amount, Errors.INSUFFICIENT_BALANCE);

        //Retrieve the current exchange rate palToken:underlying
        uint _exchRate = _exchangeRate();

        //Find the amount to return depending on the amount of palToken to burn
        uint _num = _amount.mul(_exchRate);
        uint _toReturn = _num.div(mantissaScale);

        //Check if the pool has enough underlying to return
        require(_toReturn <= _underlyingBalance(), Errors.INSUFFICIENT_CASH);

        //Burn the corresponding palToken amount
        require(palToken.burn(msg.sender, _amount), Errors.FAIL_BURN);

        //Make the underlying transfer
        underlying.safeTransfer(msg.sender, _toReturn);

        //Use the controller to check if the burning was successfull
        require(controller.withdrawVerify(address(this), msg.sender, _amount), Errors.FAIL_WITHDRAW);

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
    function borrow(address _delegatee, uint _amount, uint _feeAmount) public virtual override preventReentry returns(uint){
        //Need the pool to have enough liquidity, and the interests to be up to date
        require(_amount < _underlyingBalance(), Errors.INSUFFICIENT_CASH);
        require(_delegatee != address(0), Errors.ZERO_ADDRESS);
        require(_amount > 0, Errors.ZERO_BORROW);
        require(_feeAmount >= minBorrowFees(_amount), Errors.BORROW_INSUFFICIENT_FEES);
        require(_updateInterest());

        address _borrower = msg.sender;

        //Deploy a new Loan Pool contract
        PalLoan _newLoan = new PalLoan(
            address(this),
            _borrower,
            address(underlying),
            delegator
        );

        //Send the borrowed amount of underlying tokens to the Loan
        underlying.safeTransfer(address(_newLoan), _amount);

        //And transfer the fees from the Borrower to the Loan
        underlying.safeTransferFrom(_borrower, address(_newLoan), _feeAmount);

        //Start the Loan (and delegate voting power)
        require(_newLoan.initiate(_delegatee, _amount, _feeAmount), Errors.FAIL_LOAN_INITIATE);

        //Update Total Borrowed, and add the new Loan to mappings
        totalBorrowed = totalBorrowed.add(_amount);

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
    function expandBorrow(address _loan, uint _feeAmount) public virtual override preventReentry returns(uint){
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_feeAmount > 0);
        require(_updateInterest());
        
        //Load the Loan Pool contract & get Loan owner
        PalLoanInterface _palLoan = PalLoanInterface(_borrow.loan);

        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        //Transfer the new fees to the Loan
        //If success, update the Borrow data, and call the expand fucntion of the Loan
        underlying.safeTransferFrom(_loanOwner, _borrow.loan, _feeAmount);

        require(_palLoan.expand(_feeAmount), Errors.FAIL_LOAN_EXPAND);

        _borrow.feesAmount = _borrow.feesAmount.add(_feeAmount);

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
    function closeBorrow(address _loan) public virtual override preventReentry {
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Get Loan owner from the ERC721 contract
        address _loanOwner = palLoanToken.ownerOf(_borrow.tokenId);

        //Load the Loan contract
        PalLoanInterface _palLoan = PalLoanInterface(_borrow.loan);

        //Calculates the amount of fees used
        uint _feesUsed = (_borrow.amount.mul(borrowIndex).div(_borrow.borrowIndex)).sub(_borrow.amount);
        uint _penaltyFees = 0;
        uint _totalFees = _feesUsed;

        //If the Borrow is closed before the minimum length, calculates the penalty fees to pay
        // -> Number of block remaining to complete the minimum length * current Borrow Rate
        if(block.number < (_borrow.startBlock.add(minBorrowLength))){
            uint _currentBorrowRate = interestModule.getBorrowRate(_underlyingBalance(), totalBorrowed, totalReserve);
            uint _missingBlocks = (_borrow.startBlock.add(minBorrowLength)).sub(block.number);
            _penaltyFees = _missingBlocks.mul(_borrow.amount.mul(_currentBorrowRate)).div(mantissaScale);
            _totalFees = _totalFees.add(_penaltyFees);
        }
    
        //Security so the Borrow can be closed if there are no more fees
        //(if the Borrow wasn't Killed yet, or the loan is closed before minimum time, and already paid fees aren't enough)
        if(_totalFees > _borrow.feesAmount){
            _totalFees = _borrow.feesAmount;
        }
        
        //Close and destroy the loan
        _palLoan.closeLoan(_totalFees);

        //Burn the palLoanToken for this Loan
        require(palLoanToken.burn(_borrow.tokenId), Errors.FAIL_LOAN_TOKEN_BURN);

        //Set the Borrow as closed
        _borrow.closed = true;
        _borrow.feesUsed = _totalFees;
        _borrow.closeBlock = block.number;

        //Update the storage variables
        totalBorrowed = totalBorrowed.sub((_borrow.amount).add(_feesUsed));
        uint _realPenaltyFees = _totalFees.sub(_feesUsed);
        totalReserve = totalReserve.add(reserveFactor.mul(_realPenaltyFees).div(mantissaScale));

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
    function killBorrow(address _loan) public virtual override preventReentry {
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
        PalLoanInterface _palLoan = PalLoanInterface(_borrow.loan);

        //Kill the Loan
        _palLoan.killLoan(killer, killerRatio);

        //Burn the palLoanToken for this Loan
        require(palLoanToken.burn(_borrow.tokenId), Errors.FAIL_LOAN_TOKEN_BURN);

        //Close the Loan, and update storage variables
        _borrow.closed = true;
        _borrow.killed = true;
        _borrow.feesUsed = _borrow.feesAmount;
        _borrow.closeBlock = block.number;

        uint _killerFees = (_borrow.feesAmount).mul(killerRatio).div(uint(1e18));
        totalBorrowed = totalBorrowed.sub((_borrow.amount).add(_feesUsed));
        totalReserve = totalReserve.sub(_killerFees);

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
    function changeBorrowDelegatee(address _loan, address _newDelegatee) public virtual override preventReentry {
        //Fetch the corresponding Borrow
        //And check that the caller is the Borrower, and the Loan is still active
        Borrow storage _borrow = loanToBorrow[_loan];
        require(!_borrow.closed, Errors.LOAN_CLOSED);
        require(_newDelegatee != address(0), Errors.ZERO_ADDRESS);
        require(isLoanOwner(_loan, msg.sender), Errors.NOT_LOAN_OWNER);
        require(_updateInterest());

        //Load the Loan Pool contract
        PalLoanInterface _palLoan = PalLoanInterface(_borrow.loan);

        //Call the delegation logic in the palLoan to change the votong power recipient
        require(_palLoan.changeDelegatee(_newDelegatee), Errors.FAIL_LOAN_DELEGATEE_CHANGE);

        //Update storage data
        _borrow.delegatee = _newDelegatee;

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
        return palLoanToken.loansOfForPool(_borrower, address(this));
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
        return interestModule.getBorrowRate(_underlyingBalance(), totalBorrowed, totalReserve);
    }
    
    /**
    * @notice Get the Supply Rate for this Pool
    * @dev Get the Supply Rate from the Interest Module
    * @return uint : Supply Rate (scale 1e18)
    */
    function supplyRatePerBlock() external view override returns (uint){
        return interestModule.getSupplyRate(_underlyingBalance(), totalBorrowed, totalReserve, reserveFactor);
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
            uint _cash = _underlyingBalance();
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
        require(_amount < _underlyingBalance(), Errors.INSUFFICIENT_CASH);
        //Future Borrow Rate with the amount to borrow counted as already borrowed
        uint _borrowRate = interestModule.getBorrowRate(_underlyingBalance().sub(_amount), totalBorrowed.add(_amount), totalReserve);
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
        uint _cash = _underlyingBalance();
        uint _borrows = totalBorrowed;
        uint _reserves = totalReserve;
        uint _oldBorrowIndex = borrowIndex;

        //Get the Borrow Rate from the Interest Module
        uint _borrowRate = interestModule.getBorrowRate(_cash, _borrows, _reserves);

        //Delta of blocks since the last update
        uint _ellapsedBlocks = _currentBlock.sub(accrualBlockNumber);

        /*
        Interest Factor = Borrow Rate * Ellapsed Blocks
        Accumulated Interests = Interest Factor * Borrows
        Total Borrows = Borrows + Accumulated Interests
        Total Reserve = Reserve + Accumulated Interests * Reserve Factor
        Borrow Index = old Borrow Index + old Borrow Index * Interest Factor 
        */
        uint _interestFactor = _borrowRate.mul(_ellapsedBlocks);
        uint _accumulatedInterest = _interestFactor.mul(_borrows).div(mantissaScale);
        uint _newBorrows = _borrows.add(_accumulatedInterest);
        uint _newReserve = _reserves.add(reserveFactor.mul(_accumulatedInterest).div(mantissaScale));
        uint _newBorrowIndex = _oldBorrowIndex.add((_interestFactor.mul(1e18)).mul(_oldBorrowIndex).div(1e36));

        //Update storage
        totalBorrowed = _newBorrows;
        totalReserve = _newReserve;
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
        controller = PaladinControllerInterface(_newController);
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
    function removeReserve(uint _amount, address _recipient) external override controllerOnly { //add system so Controller can also fetch Fees
        //Check if there is enough in the reserve
        require(_updateInterest());
        require(_amount <= _underlyingBalance() && _amount <= totalReserve, Errors.RESERVE_FUNDS_INSUFFICIENT);

        totalReserve = totalReserve.sub(_amount);

        //Transfer underlying to the admin
        underlying.safeTransfer(_recipient, _amount);

        emit RemoveReserve(_amount);
    }

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

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./PaladinControllerInterface.sol";

/** @title palPool Interface  */
/// @author Paladin
interface PalPoolInterface {

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
    function removeReserve(uint _amount, address _recipient) external;

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./PaladinControllerInterface.sol";
import "./PalLoanTokenInterface.sol";
import "./InterestInterface.sol";
import "./PalPoolInterface.sol";
import "./PalToken.sol";
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
    PalLoanTokenInterface public palLoanToken;

    /** @notice Underlying ERC20 token of this Pool */
    IERC20 public underlying;

    /** @notice ERC20 palToken for this Pool */
    PalToken public palToken;

    /** @dev Boolean to prevent reentry in some functions */
    bool internal entered = false;

    /** @notice Total of the current Reserve */
    uint public totalReserve;
    /** @notice Total of underlying tokens "borrowed" (in Loan Pool contracts) */
    uint public totalBorrowed;

    /** @notice Minimum duration of a Borrow (in blocks) */
    uint public minBorrowLength = 45290;
    

    /** @dev Health Factor to kill a loan */
    uint public constant killFactor = 0.96e18;
    /** @dev Ratio of the borrow fees to pay the killer of a loan */
    uint public killerRatio = 0.15e18;

    /** @dev Base value to mint palTokens */
    uint internal constant initialExchangeRate = 1e18;
    /** @notice Part of the borrows interest to set as Reserves */
    uint public reserveFactor = 0.2e18;
    /** @notice Last block where the interest where updated for this pool */
    uint public accrualBlockNumber;
    /** @notice Borrow Index : increase at each interest update to represent borrows interests increasing (scaled 1e36) */
    uint public borrowIndex;

    /** @dev Scale used to represent decimal values */
    uint constant internal mantissaScale = 1e18;

    /** @dev Mapping of Loan Pool contract address to Borrow struct */
    mapping (address => Borrow) internal loanToBorrow;
    /** @dev List of all loans (current & closed) */
    address[] internal loans;


    //Modules

    /** @notice Paladin Controller contract */
    PaladinControllerInterface public controller;
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
interface PalLoanInterface {
    //Functions
    function initiate(address _delegatee, uint _amount, uint _feesAmount) external returns(bool);
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

import "./PalLoanInterface.sol";
import "./utils/IERC20.sol";
import "./utils/SafeERC20.sol";
import "./utils/SafeMath.sol";
import {Errors} from  "./utils/Errors.sol";

/** @title PalToken Loan Pool contract (deployed by PalToken contract)  */
/// @author Paladin
contract PalLoan is PalLoanInterface {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //Variables

    /** @notice Address of the underlying token for this loan */
    address public underlying;
    /** @notice Amount of the underlying token in this loan */
    uint public amount;
    /** @notice Address of the borrower */
    address public borrower;
    /** @notice Address of the delegatee for the voting power */
    address public delegatee;
    /** @notice PalPool that created this loan */
    address payable public motherPool;
    /** @notice Amount of fees paid for this loan */
    uint public feesAmount;
    /** @notice Address of the delegator for the underlying token */
    address public delegator;

    //Functions
    constructor(address _motherPool, address _borrower, address _underlying, address _delegator){
        //Set up initial values
        motherPool = payable(_motherPool);
        borrower = _borrower;
        underlying = _underlying;
        delegator = _delegator;
    }

    modifier motherPoolOnly() {
        require(msg.sender == motherPool);
        _;
    }

    /**
    * @notice Starts the Loan and Delegate the voting Power to the Delegatee
    * @dev Sets the amount values for the Loan, then delegate the voting power to the Delegatee
    * @param _delegatee Address to delegate the voting power to
    * @param _amount Amount of the underlying token for this loan
    * @param _feesAmount Amount of fees (in the underlying token) paid by the borrower
    * @return bool : Power Delagation success
    */
    function initiate(address _delegatee, uint _amount, uint _feesAmount) external override motherPoolOnly returns(bool){
        (bool success, ) = delegator.delegatecall(msg.data);
        require(success);
        return success;
    }

    /**
    * @notice Increases the amount of fees paid to expand the Loan
    * @dev Updates the feesAmount value for this Loan
    * @param _newFeesAmount new Amount of fees paid by the Borrower
    * @return bool : Expand success
    */
    function expand(uint _newFeesAmount) external override motherPoolOnly returns(bool){
        (bool success, ) = delegator.delegatecall(msg.data);
        require(success);
        return success;
    }

    /**
    * @notice Closes a Loan, and returns the non-used fees to the Borrower
    * @dev Return the non-used fees to the Borrower, the loaned tokens and the used fees to the PalPool, then destroy the contract
    * @param _usedAmount Amount of fees to be used as interest for the Loan
    */
    function closeLoan(uint _usedAmount) external motherPoolOnly override {
        (bool success, ) = delegator.delegatecall(msg.data);
        require(success);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }

    /**
    * @notice Kills a Loan, and reward the Killer a part of the fees of the Loan
    * @dev Send the reward fees to the Killer, then return the loaned tokens and the fees to the PalPool, and destroy the contract
    * @param _killer Address of the Loan Killer
    * @param _killerRatio Percentage of the fees to reward to the killer (scale 1e18)
    */
    function killLoan(address _killer, uint _killerRatio) external override motherPoolOnly {
        (bool success, ) = delegator.delegatecall(msg.data);
        require(success);

        //Destruct the contract (to get gas refund on the transaction)
        selfdestruct(motherPool);
    }


    /**
    * @notice Change the voring power delegatee
    * @dev Update the delegatee and delegate him the voting power
    * @param _delegatee Address to delegate the voting power to
    * @return bool : Power Delagation success
    */
    function changeDelegatee(address _delegatee) external override motherPoolOnly returns(bool){
        (bool success, ) = delegator.delegatecall(msg.data);
        require(success);
        return success;
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

import "./utils/SafeMath.sol";
import "./utils/IERC20.sol";
import {Errors} from  "./utils/Errors.sol";

/** @title palToken ERC20 contract  */
/// @author Paladin
contract PalToken is IERC20 {
    using SafeMath for uint;

    //ERC20 Variables & Mappings :

    /** @notice ERC20 token Name */
    string public name;
    /** @notice ERC20 token Symbol */
    string public symbol;
    /** @notice ERC20 token Decimals */
    uint public decimals;

    // ERC20 total Supply
    uint private _totalSupply;


    //don't want to initiate the contract twice
    bool private initialized;


    /** @notice PalPool contract that can Mint/Burn this token */
    address public palPool;


    /** @dev Balances for this ERC20 token */
    mapping(address => uint) internal balances;
    /** @dev Allowances for this ERC20 token, sorted by user */
    mapping(address => mapping (address => uint)) internal transferAllowances;


    /** @dev Modifier so only the PalPool linked to this contract can Mint/Burn tokens */
    modifier onlyPool() {
        require(msg.sender == palPool);

        _;
    }


    //Functions : 


    constructor (string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        decimals = 18;
        _totalSupply = 0;
        initialized = false;
    }


    function initiate(address _palPool) external returns (bool){
        require(!initialized);

        initialized = true;
        palPool = _palPool;

        return true;
    }


    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }


    function transfer(address dest, uint amount) external override returns(bool){
        return _transfer(msg.sender, dest, amount);
    }


    function transferFrom(address src, address dest, uint amount) external override returns(bool){
        require(transferAllowances[src][msg.sender] >= amount, Errors.ALLOWANCE_TOO_LOW);

        _transfer(src, dest, amount);

        transferAllowances[src][msg.sender] = transferAllowances[src][msg.sender].sub(amount);

        return true;
    }


    function _transfer(address src, address dest, uint amount) internal returns(bool){
        //Check if the transfer is possible
        require(balances[src] >= amount, Errors.BALANCE_TOO_LOW);
        require(dest != src, Errors.SELF_TRANSFER);
        require(src != address(0) && dest != address(0), Errors.ZERO_ADDRESS);

        //Update balances & allowance
        balances[src] = balances[src].sub(amount);
        balances[dest] = balances[dest].add(amount);

        //emit the Transfer Event
        emit Transfer(src,dest,amount);
        return true;
    }


    function approve(address spender, uint amount) external override returns(bool){
        address src = msg.sender;
        require(spender != address(0), Errors.ZERO_ADDRESS);

        //Update allowance and emit the Approval event
        transferAllowances[src][spender] = amount;

        emit Approval(src, spender, amount);

        return true;
    }


    function allowance(address owner, address spender) external view override returns(uint){
        return transferAllowances[owner][spender];
    }


    function balanceOf(address owner) external view override returns(uint){
        return balances[owner];
    }


    function mint(address _user, uint _toMint) external onlyPool returns(bool){
        require(_user != address(0), Errors.ZERO_ADDRESS);

        _totalSupply = _totalSupply.add(_toMint);
        balances[_user] = balances[_user].add(_toMint);

        emit Transfer(address(0),_user,_toMint);

        return true;
    }


    function burn(address _user, uint _toBurn) external onlyPool returns(bool){
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(balances[_user] >= _toBurn, Errors.INSUFFICIENT_BALANCE);

        _totalSupply = _totalSupply.sub(_toBurn);
        balances[_user] = balances[_user].sub(_toBurn);

        emit Transfer(_user,address(0),_toBurn);

        return true;
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

import "./utils/IERC721.sol";

/** @title palLoanToken Interface  */
/// @author Paladin
interface PalLoanTokenInterface is IERC721 {

    //Events

    /** @notice Event when a new Loan Token is minted */
    event NewLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);
    /** @notice Event when a Loan Token is burned */
    event BurnLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);


    //Functions
    function mint(address to, address palPool, address palLoan) external returns(uint256);
    function burn(uint256 tokenId) external returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

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

    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external view returns(uint);
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns(uint);
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
        //allows onyl the admin of this contract to call the function
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
    string public constant CALLER_NOT_ALLOWED_POOL = '30';  // 'The caller must be a palPool listed in tle controller'
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

