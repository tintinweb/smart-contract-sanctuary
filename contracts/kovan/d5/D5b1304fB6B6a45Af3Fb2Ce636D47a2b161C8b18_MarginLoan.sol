pragma solidity ^0.5.0;




interface IMarginLoan {

/**
 * LoanStatus : it will have only follwoing three values. 
 */
enum LoanStatus {NOTFOUND , PENDING , ACTIVE   , COMPLETE , REJECT , CANCEL}
/**
 * LoanRequest: This event will triggered when ever their is request for loan
 */
event LoanRequest(
    address user,
    address bank,
    uint256 loanAmount,
    uint256 interestRate,
    LoanStatus status,
    address tokenAddress,
    uint256 createdAt ,
    uint256 term ,
    uint256 installmentAmount ,
    uint256 installmentDuration,
    uint256 id
);
event UpdateLoan(
 address user ,
 uint256 id,
 LoanStatus status
);



/**
 * called when user request loan from bank
 *   
 */
function requestLoan(address _bank , uint256 _loanAmount , uint256 _interestRate , address _tokenAddress , uint256 createdAt , uint256 term , uint256 installmentAmount , uint256 installmentDuration) external;
 /**
 * only user with a rule of bank can approve loan
 */
function approveLoan( address _user ,uint256 _id) external  returns(bool);

 /**
 * only user with a rule of bank can reject loan
 */
function rejectLoan( address _user , uint256 _id) external  returns(bool);


/**
 * only user with a rule of bank can approve loan
 */
function completeLoan( address _user ,uint256 _id) external  returns(bool);

/**
*getLoanStatus: thsi function return loan status of address provided 
*/
function getLoanStatus(address _user, uint256 _id) external view returns(uint256);
/**
 * only user with a rule of bank can reject loan
 */
function cancelLoan( uint256 _id) external  returns(bool);

/**
 * get Margin loan record of customer 
 */
 function getMarginLoan(address _user , uint256 id) external view returns(address , address , uint256, uint256, LoanStatus , address , uint256 , uint256 , uint256 , uint256);

/**
 * 
 */

}

pragma solidity ^0.5.0;

import "./IMarginLoan.sol";
import "../whitelist/ITokenismWhitelist.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract MarginLoan is IMarginLoan {

ITokenismWhitelist _whitelist;
uint256 id =0;
/**
 * LoanStatus : it will have only follwoing three values. 
 */
// enum LoanStatus {NOTFOUND , PENDING , ACTIVE   , COMPLETE , REJECT , CANCEL}
/**
 * MarginLoan: This struct will Provide the required field of Loan record 
 */
struct MarginLoan {
    address user;
    address bank;
    uint256 loanAmount;
    uint256 interestRate;
    LoanStatus status;
    address tokenAddress;
    uint256 createdAt;
    uint256 term;
    uint256 installmentAmount;
    uint256 installmanetDuration;
}

/**
 * marginLoan: this mapping will store all the marginloan 
 * struct against its user
 */
mapping(address => MarginLoan[]) public marginLoan;
bytes32 [] marginLoanList;


struct UserLoans{
    address user;
    uint256[] loanIds;
}

mapping(address => UserLoans ) public userLoans;


/**
 * constructor :  
 */
constructor(ITokenismWhitelist _whiteListing) public {
    _whitelist = _whiteListing;
}


modifier onlyBank(){
    require(_whitelist.isBank(msg.sender), "Only Bank is allowed");
        _;
}



/**
 * called when user request loan from bank
 *   
 */
function requestLoan(address _bank , uint256 _loanAmount , uint256 _interestRate , address _tokenAddress , uint256 createdAt , uint256 term , uint256 installmentAmount , uint256 installmentDuration) public  {
        // uint256 old_id = id;
        // UserLoans storage newUserLoan = userLoans[msg.sender];

        MarginLoan memory newMarginLoan;     //= marginLoan[newUserLoan.loanIds.length];
        
        // require(newMarginLoan.status != LoanStatus.ACTIVE, "user Already applied");
        // require(newMarginLoan.status != LoanStatus.PENDING, "user Previous request is in Pending");

        require(_whitelist.isBank(_bank),"Bank is not whitelisted" );
        require(Address.isContract(_tokenAddress) , "required erc1400 token address");
        newMarginLoan.bank = _bank;
        newMarginLoan.loanAmount = _loanAmount;
        newMarginLoan.interestRate = _interestRate;
        newMarginLoan.status = LoanStatus.PENDING;
        newMarginLoan.user = msg.sender;
        newMarginLoan.tokenAddress = _tokenAddress;
        newMarginLoan.createdAt = createdAt;
        newMarginLoan.installmanetDuration = installmentDuration;
        newMarginLoan.installmentAmount = installmentAmount;
        marginLoan[msg.sender].push(newMarginLoan);

        // newMarginLoan.term = term;
        // newUserLoan.loanIds.push(id);
        // newUserLoan.user = msg.sender;
        emit LoanRequest(msg.sender , newMarginLoan.bank , newMarginLoan.loanAmount , newMarginLoan.interestRate, newMarginLoan.status ,newMarginLoan.tokenAddress , newMarginLoan.createdAt , newMarginLoan.term, newMarginLoan.installmentAmount , newMarginLoan.installmanetDuration , marginLoan[msg.sender].length-1);
                // id +=1;

        // return old_id;
}
 /**
 * only user with a rule of bank can approve loan
 */
function approveLoan( address _user , uint256 _id) public onlyBank returns(bool) {
    MarginLoan storage newMarginLoan = marginLoan[_user][_id];
    newMarginLoan.status = LoanStatus.ACTIVE;
    emit UpdateLoan(_user , _id ,newMarginLoan.status);
    return true;
}

 /**
 * only user with a rule of bank can reject loan
 */
function rejectLoan( address _user , uint256 _id) public onlyBank returns(bool) {
  MarginLoan storage newMarginLoan = marginLoan[_user][_id];
    newMarginLoan.status = LoanStatus.REJECT;
     emit UpdateLoan(_user , _id, newMarginLoan.status);
    return true;
}
/**
 * only user with a rule of bank can approve loan
 */
function completeLoan( address _user , uint256 _id) public onlyBank returns(bool) {
     MarginLoan storage newMarginLoan = marginLoan[_user][_id];
     newMarginLoan.status = LoanStatus.COMPLETE;
     emit UpdateLoan(_user , _id, newMarginLoan.status);
    return true;
}

// function getUser(address _user, uint256 _id ) public view returns(UserLoans memory) {
//     UserLoans memory userloans = userLoans[_id];
//     return userloans;  
// }


/**
*getLoanStatus: thsi function return loan status of address provided 
*/
function getLoanStatus(address _user , uint256 _id) public view returns(uint256){   
    MarginLoan storage newMarginLoan = marginLoan[_user][_id];
    if(newMarginLoan.status == LoanStatus.NOTFOUND) return 0;
    if(newMarginLoan.status == LoanStatus.PENDING) return 1;
    if(newMarginLoan.status == LoanStatus.ACTIVE) return 2;
    if(newMarginLoan.status == LoanStatus.COMPLETE) return 3;
    if(newMarginLoan.status == LoanStatus.REJECT) return 4;
    if(newMarginLoan.status == LoanStatus.CANCEL) return 5;

     
}
/**
 * only user can cancel bank
 */
function cancelLoan(uint256 _id) public  returns(bool) {
    MarginLoan storage newMarginLoan = marginLoan[msg.sender][_id];
    newMarginLoan.status = LoanStatus.CANCEL;
    emit UpdateLoan(msg.sender , _id,newMarginLoan.status);
    return true;
}

/**
 * get Margin Loan of customer
 */
 function getMarginLoan(address _user , uint256 id) external view returns(address , address , uint256, uint256, LoanStatus , address , uint256 , uint256 , uint256,uint256){
          UserLoans storage userloans = userLoans[_user];
          MarginLoan storage newMarginLoan = marginLoan[_user][id];
         return(newMarginLoan.user , newMarginLoan.bank, newMarginLoan.loanAmount,newMarginLoan.interestRate , newMarginLoan.status , newMarginLoan.tokenAddress, newMarginLoan.createdAt , newMarginLoan.installmanetDuration , newMarginLoan.installmentAmount , newMarginLoan.term);

 }
}

pragma solidity ^0.5.0;


interface ITokenismWhitelist {
    function addWhitelistedUser(address _wallet, bool _kycVerified, bool _accredationVerified, uint256 _accredationExpiry) external;
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    function suspendUser(address _wallet) external;

    function activeUser(address _wallet) external;

    function updateUserType(address _wallet, string calldata _userType) external;
    function isWhitelistedUser(address wallet) external view returns (uint);
    function removeWhitelistedUser(address _wallet) external;

 function removeSymbols(string calldata _symbols) external returns(bool);
 function closeTokenismWhitelist() external;
 function addSymbols(string calldata _symbols)external returns(bool);

  function isAdmin(address _admin) external view returns(bool);
  function isBank(address _bank) external view returns(bool);
  function isSuperAdmin(address _calle) external view returns(bool);
  function getFeeStatus() external returns(uint8);
  function getFeePercent() external view returns(uint8);
  function getFeeAddress()external returns(address);

    function isManager(address _calle)external returns(bool);
    function userType(address _caller) external view returns(bool);

}

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

