// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import './interfaces/ILoanPool.sol';
import './interfaces/ILandRegistration.sol';

contract LoanPool is ILoanPool, IERC20 {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    // pool setting
    uint public minRate;     // min interest rate
    uint public maxRate;     // max interest rate
    poolStatus public status;   // default Opening, once terminated Closed
    uint public myId;

    // pool data
    uint public poolReserve;     // current pool avaliable fund
    uint public poolDebt;        // total withdraed fund
    uint public rateToBorrow;    // interest rate for borrower

    // due to uint -> all rate related have a DECIMALBASE 100000
    uint public DECIMALBASE = 10**5;
    uint public DAYSPERYEAR = 365;
    // for util rate: 12345 <=> 0.12345 <=> 12.345%
    uint public currentUltilizationRate;    // utilization rate
    uint public ultilizationLimitRate;      // highest utilization rate

    address public override currency;    // accepted principal token
    address public LRSCAddress; // land registration smart contract address
    address public LOSCAddress; // loan origination smart contract address

    // loan entity related
    uint nextLoanEntityID = 0;  // next one id
    uint[] activeLoanEntityIDs;     // current active loan entities
    mapping(uint => LoanEntity) getLoanEntityByID;  // from loanEntityID -> LoanEntity struct
    mapping(uint => uint) indexOfLoanEntity;        // from loanEntityID -> index in activeLoanEntity array
    mapping(uint => bool) isLoanEntityIDValid;      // check if loan is valid or not

    mapping(uint => uint[]) public getLoanEntityIDsByLandID;   // from landID -> all related loan entities IDs
    mapping(uint => mapping(uint => uint)) public getLoanEntityIDIndex;   // from landID -> (loanEntityID -> index in array above) all related loan entities IDs
    // limit only loan origination contract can call
    modifier onlyLOSC() {
        require(msg.sender == LOSCAddress, "LoanPool: ONLY LRSC can call");
        _;
    }

    // set address of loan originator sc 
    constructor () public {
        LOSCAddress = msg.sender;
        activeLoanEntityIDs.push(0);    // set the first element of the loan entity to 0
        status = poolStatus.Opening;
    }


    function initialize(uint _minRate, uint _maxRate, address _currency, address _lrscAddress, uint _myId) external override onlyLOSC {
        minRate = _minRate;
        maxRate = _maxRate;
        currency = _currency;
        LRSCAddress = _lrscAddress;
        myId = _myId;
    }


    function getLengthOfActiveLoanEntityIDs() external view override returns (uint) {
        return activeLoanEntityIDs.length;
    }

    function callgetLoanEntityIDsByLandID(uint landID) external view override returns (uint[] memory) {
        return getLoanEntityIDsByLandID[landID];
    }
    
    function getTotalDebtByLandID(uint landID) external view override returns (uint totalDebt) {
        //if you want to update the interets obligated for all loans in a land, call updateAllLoansForTotalDebtByLandID()
        uint length = getLoanEntityIDsByLandID[landID].length;
        totalDebt = 0;
        for (uint i = 0; i < length; i++){
            totalDebt = totalDebt.add(
                     getLoanEntityByID[getLoanEntityIDsByLandID[landID][i]].principal
                .add(getLoanEntityByID[getLoanEntityIDsByLandID[landID][i]].interestObligated));
        }
    }

    function refreshAllLoansByLandID(uint landID) external override returns (uint totalDebt) {
        uint length = getLoanEntityIDsByLandID[landID].length;
        for (uint i = 0; i < length; i++){
            LoanEntity storage _loan = getLoanEntityByID[getLoanEntityIDsByLandID[landID][i]];

            // update update interest obligated
            uint256 newInterestGenerated =  _loan.principal.mul(_loan.interestRateAPY.div(DAYSPERYEAR))
                                            .mul(block.timestamp.div(1 days) - _loan.lastUpdateDate).div(DECIMALBASE);
            if(newInterestGenerated > 0) {
                _loan.lastUpdateDate = block.timestamp.div(1 days);
                _loan.interestObligated = _loan.interestObligated.add(newInterestGenerated);
            }
        }
    }

    function getLoanEntityDebtInfo(uint loanID) external view override returns (uint) {
        return getLoanEntityByID[loanID].principal.add(getLoanEntityByID[loanID].interestObligated);
    }
    
    function getloanEntityLandID(uint loanEntityID) external view override returns (uint) {
        return getLoanEntityByID[loanEntityID].landID;
    }

    /// @dev lenders need to "approve" this contract to transferFrom in token contract
    function deposit(address from, uint amount) external override onlyLOSC {
        require(
            status == poolStatus.Opening,
            "LoanPool: CURRENT POOL CLOSED"
        );
        require(
            amount > 0 && amount <= IERC20(currency).balanceOf(msg.sender), 
            "LoanPool: PLEASE INPUT CORRECT AMOUNT"
        );

        // if NAV at beginning is zero, then set token mint 1:1 to principal token
        if (poolDebt.add(poolReserve) == 0){
            _mint(from, amount);
        } else {
            // mint pool token to lender
            _mint(from, _fromCurrencyToTokenCalculation(amount));
        }

        // transfer fund
        IERC20(currency).safeTransferFrom(from, address(this), amount);
        // update pool data
        poolReserve = poolReserve.add(amount);                // update pool reserve
        currentUltilizationRate = poolDebt.mul(DECIMALBASE).div(poolDebt.add(poolReserve));   // update util rate
        
        emit LenderDeposited(address(this), from, currency, amount);
    }


    /// @notice lenders need to enter amount of pool tokens want to withdraw
    function withdraw(address to, uint amountOfPoolToken) external override onlyLOSC {
        /*
            when pool status is closed, user can still withdraw the principal
            since when status is closed, activeLoanEntityIDs have to be length = 1
            So -> in _fromTokenToCurrencyCalculation, the inner for loop will not be called
            total interest will be 0 and poolDebt has to be 0:

                       Zero                       Zero          
                        |                           |
            return (totalInterest + poolReserve + poolDebt).mul(amountOfToken).div(_totalSupply);

            therefore in this case, _fromTokenToCurrencyCalculation will just return:
            
               x = poolReserve x amountOfPoolToken / totalSupply
            -> 
               x / amountOfPoolToken = poolReserve / totalSupply
            
            pool token is not stable to principal in reserve, therefore no special code need to update
            in withdraw function
        */
        require(
            amountOfPoolToken > 0 && amountOfPoolToken <= _balances[to], 
            "LoanPool: PLEASE INPUT CORRECT AMOUNT"
        );
        uint amountOfCurrency = _fromTokenToCurrencyCalculation(amountOfPoolToken);
        require( // ideally should never be used
            amountOfCurrency <= poolReserve, 
            "LoanPool: CURRENT POOL RESERVE IS INSUFFICIENT"
        );

        // update pool data
        poolReserve = poolReserve.sub(amountOfCurrency);  // deduce pool reserve
        currentUltilizationRate = poolDebt.mul(DECIMALBASE).div(poolDebt.add(poolReserve));   // update util rate
        // burn pool token from lender
        _burn(to, amountOfPoolToken);
        // transfer principal token
        IERC20(currency).safeTransfer(to, amountOfCurrency); 

        emit LenderWithdrawed(address(this), to, currency, amountOfCurrency);
    }


    ///@dev before calling this, contract needs to check land and developer validity
    function drawFund(uint landID, uint developerID, uint amount, address spvwallet) external override onlyLOSC returns (uint loanEntityID) {
        // check pool status: 0. pool status must be opening
        //                    1. pool reserve enough money to withdraw
        //                    2. after withdraw utilization rate limit
        require(
            status == poolStatus.Opening,
            "LoanPool: CURRENT POOL CLOSED"
        );
        require(
            amount <= poolReserve,             
            "LoanPool: AMOUNT HIGHER THAN RESERVE FUND"
        );
        require(
            spvwallet != address(0),
            "LoanPool: SPV WALLET ADDRESS IS INVALID"
        );
        require(
            // after amount been drawed, the utlization ratio should be lower than limit
            // (current poolDebt + amount)/(poolReserve + current poolDebt) < limit
            (poolDebt.add(amount)).mul(DECIMALBASE).div(poolReserve.add(poolDebt)) <= ultilizationLimitRate,
            "LoanPool: AFTER LOAN DRAWED, UTILIZATION RATE IS HIGHER THAN LIMIT"
        );
        // check land and developer validity
        require(
            ILandRegistration(LRSCAddress).isDeveloperIDValid(developerID) == true,
             "LoanPool: DEVELOPER ID IS NOT VALID"
        );
        require(
            ILandRegistration(LRSCAddress).isLandIDValid(landID) == true,
             "LoanPool: LAND ID IS NOT VALID"
        );

        // create loan entity
        loanEntityID = createLoanEntity(landID, developerID, amount);
        // update pool data
        poolReserve = poolReserve.sub(amount);
        poolDebt = poolDebt.add(amount);
        currentUltilizationRate = poolDebt.mul(DECIMALBASE).div(poolDebt.add(poolReserve));   // update util rate
        // transfer fund
        IERC20(currency).safeTransfer(spvwallet, amount);
        
        emit SPVDrawed(address(this), spvwallet, currency, amount);
    }


    // managementCompany pay loan
    function payLoan(uint amount, uint loanEntityID, address managementCompany) external override onlyLOSC {
        // check pool status: 0. pool status must be opening
        //                    1. managementCompany must have enough amount
        //                    2. loanEntity must be valid
        require(
            amount > 0 && amount <= IERC20(currency).balanceOf(managementCompany), 
            "LoanPool: PLEASE INPUT CORRECT AMOUNT"
        );
        require(
            getLoanEntityByID[loanEntityID].status == true,
            "LoanPool: LOAN ENTITY IS NOT VALID"
        );
        require(
            isLoanEntityIDValid[loanEntityID],
            "LoanPool: LOAN ENTITY ID IS NOT VALID"
        );
        // transfer fund
        // update loan entity data
        LoanEntity storage _loan = getLoanEntityByID[loanEntityID];

        // update update interest obligated
        uint256 newInterestGenerated =  _loan.principal.mul(_loan.interestRateAPY.div(DAYSPERYEAR))
                                        .mul(block.timestamp.div(1 days) - _loan.lastUpdateDate).div(DECIMALBASE);
        if(newInterestGenerated > 0) {
            _loan.lastUpdateDate = block.timestamp.div(1 days);
            _loan.interestObligated = _loan.interestObligated.add(newInterestGenerated);
        }

        if (amount >= _loan.principal.add(_loan.interestObligated)){
            //loan is pay out, we will remove this loan, so update the loan is not necessary
            amount = _loan.principal.add(_loan.interestObligated);
            poolDebt = poolDebt.sub(_loan.principal);
            // update activeLoans
            uint _indexOfLoanEntity = indexOfLoanEntity[loanEntityID];
            uint _lengthOfArray = activeLoanEntityIDs.length;
            // replace cleared loan entity by the last element
            activeLoanEntityIDs[_indexOfLoanEntity] = activeLoanEntityIDs[_lengthOfArray - 1];
            indexOfLoanEntity[loanEntityID] = 0;    // reset it to point to 0
            activeLoanEntityIDs.pop();  // pop last element
            isLoanEntityIDValid[loanEntityID] = false;
            // once debt is clean remove the loan from getLoanEntityIDsByLandID
            _indexOfLoanEntity = getLoanEntityIDIndex[_loan.landID][loanEntityID];
            require(_indexOfLoanEntity > 0, "LOANPOOL: Wrong Index, should be greater than 0, 0 index should never be used.");
            _lengthOfArray = getLoanEntityIDsByLandID[_loan.landID].length;
            getLoanEntityIDsByLandID[_loan.landID][_indexOfLoanEntity] = getLoanEntityIDsByLandID[_loan.landID][_lengthOfArray - 1];
            getLoanEntityIDsByLandID[_loan.landID].pop(); // move last one to the front and delete last one
            getLoanEntityIDIndex[_loan.landID][loanEntityID] = 0;
            ILandRegistration(LRSCAddress).removeUniqueLoanEntityId(_loan.developerID, myId,loanEntityID);
        } else if (amount >= _loan.interestObligated) {
            // this case has enough money to cover interest
            _loan.totalPaid = _loan.totalPaid.add(amount);  // accumulate total money paid
            _loan.interestObligated = 0;    // cover interest generated.
            _loan.lastUpdateDate = block.timestamp.div(1 days);
            _loan.principal = _loan.principal.sub(amount.sub(_loan.interestObligated));  // deduce the principal
            poolDebt = poolDebt.sub(amount.sub(_loan.interestObligated));
        } else {//amount < _loan.interestObligated
            _loan.totalPaid = _loan.totalPaid.add(amount); 
            _loan.interestObligated = _loan.interestObligated.sub(amount);
            _loan.lastUpdateDate = block.timestamp.div(1 days);
        }

        poolReserve = poolReserve.add(amount);
        // transfer principal token to loan pool
        require(
            IERC20(currency).balanceOf(managementCompany) >= amount,
            "LoanPool: INSUFFICIENT FUND IN MANAGEMENT COMPANY WHEN PAYLOAN."
        );
        require(
            IERC20(currency).allowance(managementCompany, address(this)) >= amount,
            "LoanPool: INSUFFICIENT ALLOWANCE FROM MANAGEMENT COMPANY WHEN PAYLOAN."
        );
        IERC20(currency).safeTransferFrom(managementCompany, address(this), amount);
        currentUltilizationRate = poolDebt.mul(DECIMALBASE).div(poolDebt.add(poolReserve));   // update util rate

        emit SPVRepayed(address(this), managementCompany, currency, amount);
    }


    function debtVoid(uint loanEntityID, uint payableDebtAmount, address managementCompany) external override onlyLOSC {
        require(
            getLoanEntityByID[loanEntityID].status == true,
            "LoanPool: LOAN ENTITY IS NOT VALID"
        );
        require(
            payableDebtAmount > 0 && payableDebtAmount <= IERC20(currency).balanceOf(managementCompany), 
            "LoanPool: PLEASE INPUT CORRECT AMOUNT"
        );

        require(
            IERC20(currency).allowance(managementCompany, address(this)) >= payableDebtAmount, 
            "LoanPool: INSUFFICIENT ALLOWANCE FROM MANAGEMENT COMPANY WHEN PAYLOAN."
        );
         
        // transfer principal token to loan pool
        IERC20(currency).safeTransferFrom(managementCompany, address(this), payableDebtAmount);

        // update pool info
        LoanEntity storage _loan = getLoanEntityByID[loanEntityID];
        poolReserve = poolReserve.add(payableDebtAmount);
        poolDebt = poolDebt.sub(_loan.principal);   

        // // update loan entity data
        // _loan.principal = 0;    // set principal to 0, developer is not been able to pay the debt
        // _loan.interestObligated = 0;
        // _loan.totalPaid = _loan.totalPaid.add(payableDebtAmount);
        // _loan.status = false;   // set status to false, so NAV calculation will not count this
        // _loan.closeDate = block.timestamp.div(1 days);
        // _loan.lastUpdateDate = _loan.closeDate;

        // remove it from activeLoanEntity array
        // replace cleared loan entity by the last element
        uint256 _indexOfLoanEntity = indexOfLoanEntity[loanEntityID];
        uint256 _lengthOfActive = activeLoanEntityIDs.length;
        activeLoanEntityIDs[_indexOfLoanEntity] = activeLoanEntityIDs[_lengthOfActive - 1];
        indexOfLoanEntity[loanEntityID] = 0;    // reset it to point to 0
        activeLoanEntityIDs.pop();  // pop last element
        isLoanEntityIDValid[loanEntityID] = false;

        uint index = getLoanEntityIDIndex[_loan.landID][loanEntityID];
        uint length = getLoanEntityIDsByLandID[_loan.landID].length;
        getLoanEntityIDsByLandID[_loan.landID][index] = getLoanEntityIDsByLandID[_loan.landID][length-1];
        getLoanEntityIDsByLandID[_loan.landID].pop();
        getLoanEntityIDIndex[_loan.landID][loanEntityID] = 0;
       
        ILandRegistration(LRSCAddress).removeUniqueLoanEntityId(_loan.developerID, myId,loanEntityID);
    }


    // create a loan entity to record loan data
    function createLoanEntity(uint landID, uint developerID, uint principal) internal returns (uint nextLoanEntityID){
        // increment the loan entity
        nextLoanEntityID++;

        // update loan entity data
        LoanEntity storage _loan = getLoanEntityByID[nextLoanEntityID];
        _loan.loanEntityID = nextLoanEntityID;
        _loan.landID = landID;
        _loan.loanPoolAddress = address(this);
        _loan.developerID = developerID;
        // to calculate the interest rate apy, we need use the below formula
        // interestRateAPY = average ( current utilization rate, after drawn utilization rate)
        // current utilization rate ->  currentUltilizationRate
        // after drawn utilization rate -> (debt + principal) / (debt + reserve)
        uint afterUtilizationRate = poolDebt.add(principal).mul(DECIMALBASE).div(poolDebt.add(poolReserve));
        _loan.interestRateAPY = afterUtilizationRate;
        _loan.startDate = block.timestamp.div(1 days);
        _loan.principal = principal;
        _loan.interestObligated = 0;
        _loan.totalPaid = 0;
        _loan.status = true;
        _loan.lastUpdateDate = _loan.startDate;

        // update active loan entity
        activeLoanEntityIDs.push(_loan.loanEntityID);
        isLoanEntityIDValid[_loan.loanEntityID] = true;
        indexOfLoanEntity[_loan.loanEntityID] = activeLoanEntityIDs.length - 1;
        if ( getLoanEntityIDsByLandID[landID].length == 0) {
            getLoanEntityIDsByLandID[landID].push(0);
        }
        getLoanEntityIDsByLandID[landID].push(_loan.loanEntityID);
        getLoanEntityIDIndex[landID][_loan.loanEntityID] = getLoanEntityIDsByLandID[landID].length - 1;

        ILandRegistration(LRSCAddress).addUniqueLoanEntityId(_loan.developerID, myId, _loan.loanEntityID);
    }
    

    function close() external override onlyLOSC {
        require(
            status == poolStatus.Opening,
            "LoanPool: CURRENT POOL CLOSED"
        );
        status = poolStatus.Closed;
    }

    function open() external override onlyLOSC {
        require(
            status == poolStatus.Closed,
            "LoanPool: CURRENT POOL Open"
        );
        status = poolStatus.Opening;
    }

    /// all loan pool token related functions in below
    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (_allowances[from][msg.sender] != uint(-1)) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // The function should be called when a lender would like to lend money into a loan pool.
    // According to the NAV, we should mint a number of tokens send give the tokens to the lender.
    // The function is an internal function to be called before mint the token.
    function _fromCurrencyToTokenCalculation(uint amountOfCurrency) internal returns (uint256) {
        //Before the currency received, denote the total number of tokens mint in ERC20 as t1
        //Denote the NAV of the loan pool is A1
        //After the currency received, denote the total number of tokens mint in ERC20 is t2
        //Deteno the NAV of the loan pool is A2
        //We have to keep t1/A1 = t2/A2
        // t2 = t1xA2/A1 = t1x(A1+ammountOfCurrency)/A1=t1+t1xamountOfCurrency/A1
        // t2 - t1 = t1xamountOfCurrency/A1 this is the amount of new tokens to be mint.
        uint totalInterest  = 0;
        for(uint i = 1; i < activeLoanEntityIDs.length; i++) {
            LoanEntity storage loanEntity = getLoanEntityByID[i];
            uint newInterestGenerated = 
                loanEntity.principal.mul(loanEntity.interestRateAPY.div(DAYSPERYEAR))
                .mul(block.timestamp.div(1 days) - loanEntity.lastUpdateDate).div(DECIMALBASE);
            if(newInterestGenerated > 0) {    
                loanEntity.interestObligated = loanEntity.interestObligated.add(newInterestGenerated);
                loanEntity.lastUpdateDate = block.timestamp.div(1 days);
            }
            totalInterest = totalInterest.add(loanEntity.interestObligated);
        } 
        // nav: A1 = totalInterest + poolReserved + poolDebt;
        return _totalSupply.mul(amountOfCurrency).div(totalInterest.add(poolDebt).add(poolReserve));

    }


    // The function should be called when a lender would like to withdraw from a loan pool.
    // According to the NAV, we should burn the given number of tokens sent back by the lender 
    // and send the currency with the generated interest back to the lender.
    // The function is an internal function to be called before burning the token and sending back the currency.
    function _fromTokenToCurrencyCalculation(uint amountOfToken) internal returns (uint256) {

        // return the currency in this amount: amountOfToken/totalSupply*NAV
        uint totalInterest  = 0;
        for(uint i = 1; i < activeLoanEntityIDs.length; i++) {
            LoanEntity storage loanEntity = getLoanEntityByID[i];
            uint newInterestGenerated = 
                loanEntity.principal.mul(loanEntity.interestRateAPY.div(DAYSPERYEAR))
                .mul(block.timestamp.div(1 days) - loanEntity.lastUpdateDate).div(DECIMALBASE);
            if(newInterestGenerated > 0) { 
                loanEntity.interestObligated = loanEntity.interestObligated.add(newInterestGenerated);
                loanEntity.lastUpdateDate = block.timestamp;
            }
            totalInterest = totalInterest.add(loanEntity.interestObligated);
        } 
        // nav: A1 = totalInterest + poolReserved + poolDebt;
        return (totalInterest.add(poolReserve).add(poolDebt)).mul(amountOfToken).div(_totalSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

interface ILoanPool {

   // When SPV call drawFund
   struct LoanEntity {
      uint loanEntityID;
      uint landID;
      string landName;
      address loanPoolAddress;
      uint developerID;
      string developerName;
      uint interestRateAPY;
      uint startDate;
      uint principal;
      uint interestObligated;
      uint totalPaid;
      bool status;
      uint closeDate;
      uint lastUpdateDate; // should be initialized by startDate when created.
      // TODO: add more data
      // duration of loan
      // type of loaning 
      // project type - rezoning
      // project stage 
      // project duration
   }

   // an enum to show the current status
   // once loan origination contract called close loan pool
   // lender cannot deposit anymore but can withdraw
   // spv cannot payLoan and cannot drawFund
   enum poolStatus {Opening, Closed}

   event LenderDeposited(address indexed loanPool_address, address indexed lender, address indexed token, uint amount);
   event LenderWithdrawed(address indexed loanPool_address, address indexed lender, address indexed token, uint amount);
   event SPVDrawed(address indexed loanPool_address, address indexed borrower, address indexed token, uint amount);
   event SPVRepayed(address indexed loanPool_address, address indexed borrower, address indexed token, uint amount);

   function initialize(uint _minRate, uint _maxRate, address _currency, address _lrscAddress, uint _myId) external;
   function close() external;
   function open() external;
   
   ///@notice lender operations
   function deposit(address from, uint amount) external;
   function withdraw(address to, uint amount) external;
   
   ///@notice SPV operations, only spv wallet can call
   function payLoan(uint amount, uint loanEntityID, address spvwallet) external;
   function drawFund(uint landID, uint developerID, uint amount, address spvwallet) external returns(uint);
   function debtVoid(uint loanEntityID, uint payableDebtAmount, address spvwallet) external;

   /// some helper functions to allow other contracts to interact
   function getLengthOfActiveLoanEntityIDs() external returns (uint);
   function callgetLoanEntityIDsByLandID(uint landID) external view returns (uint[] memory);
   function getTotalDebtByLandID(uint landID) external view returns (uint totalDebt);
   function getLoanEntityDebtInfo(uint loanID) external view returns (uint);
   function getloanEntityLandID(uint landID) external view returns (uint);
   function currency() external view returns (address);
   function refreshAllLoansByLandID(uint landID) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILandRegistration {

    // Land Developer Info
    struct Developer {
        string  companyName;
        string location;
        string note;
        uint    developerID;
        uint    totalBorrowableValue;
        uint    totalAmountBorrowed;
        uint[]  myActiveLandIDs;    // active land ID array
        mapping(uint => uint) myIndexOfLands;   // using landID -> index in the above land ID array
        // 128 bits LoanPool ID followed by 128 bits LoanEntity ID, 
        // called unique loan pool id 
        // (assume we have less than 2^128 loan pools and less than 2^128 loan entities per loan pool)
        uint[]  myUniqueLoanEntityID;    
        // unique loanpool ID -> index in the myUniqueLoanEntityID array
        mapping(uint => uint) myUniqueLoanEntityIDIndex;  
    }

    // Land Info
    struct Land {
        // basic info
        uint    propertyIdentificationNumber;
        string  legalDescriptionOfProperty;
        string  typeOfOwnership;
        string  registeredItems;
        bool    isReady;
        // vote related
        address[] votedAddresses;
        uint    landID;
        uint    developerID;
        // appraisal related
        uint    appraisalAmount;
        uint    appraisalDiscountPercent;
        uint    amountBorrowedByDeveloper; 
    }

    // CMP for info publication purposes
    // struct CommitmentMortgagePackage {
    //     uint    landID;
    //     uint    developerID;
    //     string  companyName;
    //     uint    propertyIdentificationNumber;
    //     string  legalDescriptionOfProperty; 
    //     uint    startDate;
    //     uint    closeDate;
    //     string  Notes;
    // }


    /// Developer Related Events
    event NewDeveloperAdded       (
        uint indexed developerID, 
        string  companyName,
        string  location,
        string  note);
    event DeveloperUpdated        (
        uint indexed developerID, 
        string  companyName,
        string  location,
        string  note);
    /// Land Related Events
    event NewLandAdded            (
        uint indexed landID, 
        uint propertyIdentificationNumber, 
        string legalDescriptionOfProperty, 
        string typeOfOwnership, 
        string registeredItems, 
        uint developerID);
    event LandBasicInfoUpdated    (
        uint indexed landID, 
        uint propertyIdentificationNumber, 
        string legalDescriptionOfProperty, 
        string typeOfOwnership, 
        string registeredItems);
    event LandAppraisalAddedorUpdated           (
        uint indexed landID, 
        uint appraisalAmount, 
        uint appraisalDiscountInPercent);
    event AmountBorrowedByDeveloperUpdated   (
        uint indexed landID, 
        uint amountBorrowedByDeveloper);
    event LandAppraisalApproved   (
        uint indexed landID, 
        uint newAppraisal);
    /// Developer & Land Delete
    event DeveloperDeleted  (uint indexed developerID); 
    event LandDeleted       (uint indexed landID);
    /// CMP Event
    // event CMPAnnounced      (
    //     uint indexed landID, 
    //     uint indexed developerID, 
    //     string companyName, 
    //     uint indexed propertyIdentificationNumber, 
    //     string legalDescriptionOfProperty, 
    //     uint startDate, 
    //     uint closeDate, 
    //     string Notes);

    /// Developer add & update & delete
    /// for developers: no approval needed from MC
    function addNewDeveloper(
        string calldata _companyName, 
        string calldata _location,
        string calldata _note) external;
    function updateDeveloper(
        uint _developerID, 
        string calldata _companyName, 
        string calldata _location,
        string calldata _note) external;

    /// Land add & update & appraisal update
    /// for lands: update basic info and uupdateAppraisalBorrowedByDeveloper() no need to approve
    ///            but for appraisal info update needs approval
    function addNewLand(
        uint _propertyIdentificationNumber, 
        string calldata _legalDescriptionOfProperty, 
        string calldata _typeOfOwnership, 
        string calldata _registeredItems, 
        uint _developerID) external;
    function updateLandBasicInfo(
        uint _landID, 
        uint _propertyIdentificationNumber, 
        string calldata _legalDescriptionOfProperty, 
        string calldata _typeOfOwnership, 
        string calldata _registeredItems) external;
    function addOrUpdateLandAppraisal(
        uint _landID, 
        uint _appraisalAmount, 
        uint _appraisalDiscountInPercent) external;
    // when SPV request draw fund -> accumulate in land info
    function updateAmountBorrowedByDeveloper(uint _landID, uint _amountAdded) external;
    function approveLandAppraisal(uint _landID) external;
    
    /// delete developer / land
    function deleteDeveloper(uint _developerID) external;
    function deleteLand(uint _landID) external;

    /// CMP function, create notice to boardcast
    // function createCMPAnnouncement(
    //     uint landID, 
    //     uint developerID, 
    //     uint startDate, 
    //     uint endDate, 
    //     string calldata notes) external;

    /// some helper functions to allow other contracts to interact
    function isDeveloperIDValid(uint developerID) external view returns (bool);
    function isLandIDValid(uint landID) external view returns (bool);
    function getLandAppraisalAmount(uint landID) external view returns (uint);
    function removeUniqueLoanEntityId(uint developerId, uint myId, uint loanEntityId) external;
    function addUniqueLoanEntityId(uint developerId, uint myId, uint loanEntityId) external;
}

