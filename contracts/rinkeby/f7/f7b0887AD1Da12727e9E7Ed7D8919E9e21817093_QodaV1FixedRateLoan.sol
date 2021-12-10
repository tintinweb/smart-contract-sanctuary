// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ErrorCode {

  enum Error {
              NO_ERROR,
              UNAUTHORIZED,
              SIGNATURE_MISMATCH,
              INVALID_PRINCIPAL,
              INVALID_ENDBLOCK,
              INVALID_SIDE,
              INVALID_NONCE,
              INVALID_QUOTE_EXPIRY_BLOCK,
              TOKEN_INSUFFICIENT_BALANCE,
              TOKEN_INSUFFICIENT_ALLOWANCE,
              MAX_RATE_PER_BLOCK_EXCEEDED,
              QUOTE_EXPIRED,
              LOAN_CONTRACT_NOT_FOUND,
              ASSET_NOT_SUPPORTED,
              ASSET_ALREADY_EXISTS,
              INVALID_RISK_FACTOR
  }

  /// @notice Emitted when a failure occurs
  event Failure(uint error);


  /// @notice Emits a failure and returns the error code. WARNING: This function 
  /// returns failure without reverting causing non-atomic transactions. Be sure
  /// you are using the checks-effects-interaction pattern properly with this.
  /// @param err Error code as enum
  /// @return uint Error code cast as uint
  function fail(Error err) internal returns (uint){
    emit Failure(uint(err));
    return uint(err);
  }
  
  /// @notice Emits a failure and returns the error code. WARNING: This function 
  /// returns failure without reverting causing non-atomic transactions. Be sure
  /// you are using the checks-effects-interaction pattern properly with this.
  /// @param err Error code as enum
  /// @return uint Error code cast as uint
  function fail(uint err) internal returns (uint) {
    emit Failure(err);
    return err;
  }
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IQodaV1FixedRateLoan.sol";
import "./libraries/SigVerify.sol";
import "./libraries/QodaStructs.sol";
import "./ErrorCode.sol";

contract QodaV1FixedRateLoan is IQodaV1FixedRateLoan, ErrorCode {

  using SafeMath for uint;

  /// @notice Address of the current version of QodaV1Controller
  address public controller;
  
  /// @notice Address of the ERC20 token which the loan will be denominated
  address public principalTokenAddress;
  
  /// @notice Mapping from the signature to its corresponding FixedRateLoan
  mapping(bytes => QodaStructs.FixedRateLoan) outstandingLoans;

  /// @notice Record of all borrows by user as a list of signatures
  mapping(address => bytes[]) accountBorrows;

  /// @notice Record of all lends by user as a list of signatures
  mapping(address => bytes[]) accountLends;    
  
  /// @notice Mapping of user to nonce to true if nonce has been used, false otherwise.
  /// Used for checking if a Quote is a duplicate.
  mapping(address => mapping(uint => bool)) public noncesUsed;
  
  constructor(address _controller, address _principalTokenAddress) public {
    controller = _controller;
    principalTokenAddress = _principalTokenAddress;
  }

  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param principalTokenAddress Address of token which loan will be denominated
  /// @param lender Account of the lender
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint 0 if successful otherwise error code
  function borrow(
                  address principalTokenAddress,
                  address lender,
                  uint quoteExpiryBlock,
                  uint endBlock,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external returns(uint){

    //`side` must be 1 if Quoter is lending, so we hardcode this into the signature match
    bool isSignatureMatch = SigVerify.checkQuoterSignature(
                                                           principalTokenAddress,
                                                           lender,
                                                           1,
                                                           quoteExpiryBlock,
                                                           endBlock,
                                                           principal,
                                                           principalPlusInterest,
                                                           nonce,
                                                           signature
                                                           );
    
    if(quoteExpiryBlock != 0 && quoteExpiryBlock < block.number){
      return fail(Error.QUOTE_EXPIRED);
    }
    
    if(noncesUsed[lender][nonce]){
      return fail(Error.INVALID_NONCE);
    }
    
    if(!isSignatureMatch){
      return fail(Error.SIGNATURE_MISMATCH);
    }
    
    uint err = _createFixedRateLoan(
                                    block.number,
                                    endBlock,
                                    principal,
                                    principalPlusInterest,
                                    lender,
                                    msg.sender,
                                    signature
                                    );
    
    if(err != uint(Error.NO_ERROR)){
      return fail(err);
    }

    // This nonce has been used. Set to true so it cannot be used again.
    noncesUsed[lender][nonce] = true;
    
    return err;
  }

  /// @notice Use this function as a borrower to repay borrows, either in full or partially
  /// @param signature Signature of the Quote, used as a key to retrieve the loan details
  /// @param amount Amount to repay
  /// @return uint 0 if successful otherwise return error code
  function repayBorrow(bytes memory signature, uint amount) external returns(uint){
    QodaStructs.FixedRateLoan storage frl = outstandingLoans[signature];
    
    // Read the current unpaid amount
    uint unpaid = frl.principalPlusInterest - frl.amountRepaid;

    // Don't let borrower overpay
    amount = Math.min(amount, unpaid);
    
    //`startBlock` can never be zero for an initialized `FixedRateLoan`
    if(frl.startBlock == 0){
      return fail(Error.LOAN_CONTRACT_NOT_FOUND);
    }

    //Only the original borrower can repay borrow
    if(msg.sender != frl.borrower){
      return fail(Error.UNAUTHORIZED);
    }
    
    if(!_checkApproval(msg.sender, principalTokenAddress, amount)){
      return fail(Error.TOKEN_INSUFFICIENT_ALLOWANCE);
    }
    
    if(!_checkBalance(msg.sender, principalTokenAddress, amount)){
      return fail(Error.TOKEN_INSUFFICIENT_BALANCE);
    }

    // Store the amount repaid
    frl.amountRepaid += amount;

    // Need to store this in-memory since we will be deleting the loan object first
    address lender = frl.lender;
    
    // Delete the loan if its been fully repaid
    if(frl.amountRepaid == frl.principalPlusInterest){
      _deleteFixedRateLoan(signature);
    }
    
    // Transfer amount from borrower to lender
    IERC20 principalToken = IERC20(principalTokenAddress);
    principalToken.transferFrom(msg.sender, lender, amount);

    return uint(Error.NO_ERROR);
  }

  /// @notice Call this function to enter into FixedRateLoan as a lender
  /// @param principalTokenAddress Address of token which loan will be denominated
  /// @param borrower Account of the borrower
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint 0 if successful otherwise error code
  function lend(
                address principalTokenAddress,
                address borrower,
                uint quoteExpiryBlock,
                uint endBlock,
                uint principal,
                uint principalPlusInterest,
                uint nonce,
                bytes memory signature
                ) external returns(uint){
    
    //`side` must be 0 if Quoter is borrowing, so we hardcode this into the signature match
    bool isSignatureMatch = SigVerify.checkQuoterSignature(
                                                           principalTokenAddress,
                                                           borrower,
                                                           0,
                                                           quoteExpiryBlock,
                                                           endBlock,
                                                           principal,
                                                           principalPlusInterest,
                                                           nonce,
                                                           signature
                                                           );
    
    if(quoteExpiryBlock != 0 && quoteExpiryBlock < block.number){
      return fail(Error.QUOTE_EXPIRED);
    }
    
    if(noncesUsed[borrower][nonce]){
      return fail(Error.INVALID_NONCE);
    }
    
    if(!isSignatureMatch){
      return fail(Error.SIGNATURE_MISMATCH);
    }
    
    uint err = _createFixedRateLoan(
                                    block.number,
                                    endBlock,
                                    principal,
                                    principalPlusInterest,
                                    msg.sender,
                                    borrower,
                                    signature
                                    );
    
    if(err != uint(Error.NO_ERROR)){
      return fail(err);
    }
    
    // This nonce has been used. Set to true so it cannot be used again.
    noncesUsed[borrower][nonce] = true;
    
    return err;
  }

  /** READ FUNCTIONS **/
  
  function getOutstandingLoanRaw(bytes memory signature) external view returns(
                                                                            uint,
                                                                            uint,
                                                                            uint,
                                                                            uint,
                                                                            uint,
                                                                            address,
                                                                            address
                                                                            ) {
    QodaStructs.FixedRateLoan memory frl = outstandingLoans[signature];
    return (
            frl.startBlock,
            frl.endBlock,
            frl.principal,
            frl.principalPlusInterest,
            frl.amountRepaid,
            frl.lender,
            frl.borrower
            );
  }

  function getAccountBorrows(address account) external view returns(bytes[] memory) {
    return accountBorrows[account];
  }
  
  function getAccountLends(address account) external view returns(bytes[] memory) {
    return accountLends[account];
  }

  function getOutstandingLoan(
                              bytes memory signature
                              ) external view returns(QodaStructs.FixedRateLoan memory) {
    return outstandingLoans[signature];
  }
  
  /* /// @notice Mapping from the signature to its corresponding FixedRateLoan */
  /* mapping(bytes => QodaStructs.FixedRateLoan) public outstandingLoans; */

  /* /// @notice Record of all borrows by user as a list of signatures */
  /* mapping(address => bytes[]) public accountBorrows; */

  /* /// @notice Record of all lends by user as a list of signatures */
  /* mapping(address => bytes[]) public accountLends;     */



  
  
  /** Internal Functions **/

  /// @notice Transfer the loan principal from lender to borrower and instantiate
  /// the FixedRateLoan object
  /// @param startBlock Starting block when the loan is instantiated
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param lender Account of the lender
  /// @param borrower Account of the borrower
  /// @return uint 0 if successful otherwise error code
  function _createFixedRateLoan(
                                uint startBlock,
                                uint endBlock,
                                uint principal,
                                uint principalPlusInterest,
                                address lender,
                                address borrower,
                                bytes memory signature
                                ) private returns(uint) {

    if(principal == 0){
      return fail(Error.INVALID_PRINCIPAL);
    }

    //TODO Should we cap the max endBlock as well? (eg block.number + 1 year)
    if(endBlock < block.number){
      return fail(Error.INVALID_ENDBLOCK);
    }

    if(!_checkApproval(lender, principalTokenAddress, principal)){
      return fail(Error.TOKEN_INSUFFICIENT_ALLOWANCE);
    }
    
    if(!_checkBalance(lender, principalTokenAddress, principal)){
      return fail(Error.TOKEN_INSUFFICIENT_BALANCE);
    }
    
    //TODO No checks have been made on borrower collateral yet
            
    // Create FixedRateLoan. By default, amountRepaid should be 0 at inception
    QodaStructs.FixedRateLoan memory frl = QodaStructs.FixedRateLoan(
                                                                     startBlock,
                                                                     endBlock,
                                                                     principal,
                                                                     principalPlusInterest,
                                                                     0,
                                                                     lender,
                                                                     borrower
                                                                     );

    // Adding `frl` to storage and pointers to `frl` for `accountBorrows` and `accountLends`
    outstandingLoans[signature] = frl;
    accountBorrows[borrower].push(signature);
    accountLends[lender].push(signature);
    
    // Transfer principal from lender to borrower
    IERC20 principalToken = IERC20(principalTokenAddress);
    principalToken.transferFrom(lender, borrower, principal);

    return uint(Error.NO_ERROR);
  }

  /// @notice Delete an existing FixedRateLoan. The order of operations is we
  /// first need to remove the `signature` element from the `accountBorrows` 
  /// and `accountLenders` of the the borrower and lender respectively, then 
  /// we delete the actual FixedRateLoan from `outstandingLoans` mapping
  /// @param signature The key for the `outstandingLoans` mapping to get the FixedRateLoan
  function _deleteFixedRateLoan(bytes memory signature) internal{
    QodaStructs.FixedRateLoan storage loan = outstandingLoans[signature];

    // Remove the matching signature pointing to the FixedRateLoan from borrower's account
    bytes[] storage borrows = accountBorrows[loan.borrower];
    for(uint i=0; i<borrows.length; i++){
      if(keccak256(borrows[i]) == keccak256(signature)){
        borrows[i] = borrows[borrows.length - 1];
        borrows.pop();
        break;
      }
    }

    // Remove the matching signature pointing to the FixedRateLoan from lender's account
    bytes[] storage lends = accountLends[loan.lender];
    for(uint i=0; i<lends.length; i++){
      if(keccak256(lends[i]) == keccak256(signature)){
        lends[i] = lends[lends.length - 1];
        lends.pop();
        break;
      }
    }

    // Finally delete the FixedRateLoan itself
    delete outstandingLoans[signature];
  }

  /// @notice Verify if the user has enough token balance
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address userAddress,
                         address tokenAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

  /// @notice Verify if the user has approved the smart contract for spend
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address userAddress,
                          address tokenAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IERC20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }  
}

pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../libraries/QodaStructs.sol";

interface IQodaV1FixedRateLoan {

  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param principalTokenAddress Address of ERC20 token which loan will be denominated
  /// @param lender Accoutn of the lender
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint 0 if successful otherwise error code
  function borrow(
                  address principalTokenAddress,
                  address lender,
                  uint quoteExpiryBlock,
                  uint endBlock,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external returns(uint);

  /// @notice Use this function as a borrower to repay borrows, either in full or partially
  /// @param signature Signature of the Quote, used as a key to retrieve the loan details
  /// @param amount Amount to repay
  /// @return uint 0 if successful otherwise return error code
  function repayBorrow(bytes memory signature, uint amount) external returns(uint);
  
  /// @notice Call this function to enter into FixedRateLoan as a lender
  /// @param principalTokenAddress Address of ERC20 token which loan will be denominated
  /// @param borrower Account of the borrower
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint 0 if successful otherwise error code
  function lend(
                address principalTokenAddress,
                address borrower,
                uint quoteExpiryBlock,
                uint endBlock,
                uint principal,
                uint principalPlusInterest,
                uint nonce,
                bytes memory signature
                ) external returns(uint);

  function getAccountBorrows(address account) external view returns(bytes[] memory);
 
  function getAccountLends(address account) external view returns(bytes[] memory);
 
  function getOutstandingLoan(
                              bytes memory signature
                              ) external view returns(QodaStructs.FixedRateLoan memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library QodaStructs {

  /// @notice Struct containing fixed rate loan terms
  /// @member startBlock Starting block when the loan is instantiated
  /// @member endBlock Ending block when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startBlock;
    uint endBlock;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }
  
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

library SigVerify {

  /// @notice Checks whether the hash of the plaintext input parameters matches the signature
  /// @param principalTokenAddress Address of token which loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return bool true if signed hash matches signature otherwise false
  function checkQuoterSignature(
                                address principalTokenAddress,
                                address quoter,
                                uint8 side,
                                uint quoteExpiryBlock,
                                uint endBlock,
                                uint principal,
                                uint principalPlusInterest,
                                uint nonce,
                                bytes memory signature
                                ) internal pure returns(bool){
    bytes32 messageHash = getMessageHash(
                                         principalTokenAddress,
                                         quoter,
                                         side,
                                         quoteExpiryBlock,
                                         endBlock,
                                         principal,
                                         principalPlusInterest,
                                         nonce
                                         );
    address signer = _recoverSigner(messageHash, signature);
    return signer == quoter;
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param principalTokenAddress Address oftoken which loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @return bytes32 message hash
  function getMessageHash(
                          address principalTokenAddress,
                          address quoter,
                          uint8 side,
                          uint quoteExpiryBlock,
                          uint endBlock,
                          uint principal,
                          uint principalPlusInterest,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        principalTokenAddress,
                                                        quoter,
                                                        side,
                                                        quoteExpiryBlock,
                                                        endBlock,
                                                        principal,
                                                        principalPlusInterest,
                                                        nonce
                                                        ));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", unprefixedHash));
  }

  /// @notice Recovers the address of the signer of the `messageHash` from the signature. It should be used to check versus the cleartext address given to verify the message is indeed signed by the owner
  /// @param messageHash Hash of the loan fields
  /// @param signature The candidate signature to recover the signer from
  /// @return address This is the recovered signer of the `messageHash` using the signature
  function _recoverSigner(
                         bytes32 messageHash,
                         bytes memory signature
                         ) private pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the messageHash and signature
    return ecrecover(messageHash, v, r, s);
  }

  
  /// @notice Helper function that splits the signature into r,s,v components
  /// @param signature The candidate signature to recover the signer from
  /// @return r bytes32, s bytes32, v uint8
  function _splitSignature(bytes memory signature) private pure returns(
                                                                      bytes32 r,
                                                                      bytes32 s,
                                                                      uint8 v) {
    require(signature.length == 65, "invalid signature length");
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }
}