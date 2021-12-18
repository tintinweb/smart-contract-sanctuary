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

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Verifier.sol";
import "./libraries/QConst.sol";
import "./libraries/QTypes.sol";

contract FixedRateLoanAgreement {

  using SafeMath for uint;

  /// @notice Address of the current version of Qontroller
  address public qontroller;
  
  /// @notice Address of the ERC20 token which the loan will be denominated
  address public principalTokenAddress;

  /// @notice unique ID for all new FixedRateLoans
  uint public currentLoanId = 0;
  
  /// @notice Storage for all outstanding loans
  /// loanId => FixedRateLoan 
  mapping(uint => QTypes.FixedRateLoan) outstandingLoans;

  /// @notice Storage for all borrows by a user as a list of loanIds
  /// account => loanId[]
  mapping(address => uint[]) accountBorrows;

  /// @notice Storage for all lends by a user as a list of loanIds
  /// account => loanId[]
  mapping(address => uint[]) accountLends; 

  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicate.
  /// account => nonce => bool
  mapping(address => mapping(uint => bool)) public noncesUsed;
  
  /// @notice Storage for the current total partial fill for a Quote
  /// signature => filled
  mapping(bytes => uint) quoteFill;

  constructor(address _qontroller, address _principalTokenAddress) public {
    qontroller = _qontroller;
    principalTokenAddress = _principalTokenAddress;
  }


  /** EXTERNAL FUNCTIONS **/
  
  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param lender Account of the lender
  /// @param expiryTime Timestamp after which the quote is no longer valid
  /// @param endTime Ending timestamp when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function borrow(                  
                  uint amount,
                  address lender,
                  uint expiryTime,
                  uint endTime,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external {
    QTypes.Quote memory quote = QTypes.Quote(
                                             principalTokenAddress,
                                             lender,
                                             1, // side = 1 for lender
                                             expiryTime,
                                             endTime,
                                             principal,
                                             principalPlusInterest,
                                             nonce,
                                             signature
                                             );
    _borrow(amount, quote);
  }

  /// @notice Returns the `loanId` of all borrows for a given account
  /// @param account Address of the account to query
  /// @return uint[] An array of all the `loanId`s pointing to borrows for the account
  function getAccountBorrows(address account) external view returns(uint[] memory) {
    return accountBorrows[account];
  }
 
  /// @notice Returns the `loanId` of all borrows for a given account
  /// @param account Address of the account to query
  /// @return uint[] An array of all the `loanId`s pointing to lends for the account
  function getAccountLends(address account) external view returns(uint[] memory) {
    return accountLends[account];
  }

  /// @notice Returns the FixedRateLoan object for a given `loanId` pointer
  /// @param loanId The unique ID used as the key for `outstandingLoans`
  /// @return FixedRateLoan The FixedRateLoan struct containing all loan details
  function getOutstandingLoan(uint loanId) external view returns(QTypes.FixedRateLoan memory) {
    return outstandingLoans[loanId];
  }







  
  /** INTERNAL FUNCTIONS **/
  function _borrow(uint amount, QTypes.Quote memory quote) internal {
    address signer = Verifier.getSigner(
                                        quote.principalTokenAddress,
                                        quote.quoter,
                                        quote.side,
                                        quote.expiryTime,
                                        quote.endTime,
                                        quote.principal,
                                        quote.principalPlusInterest,
                                        quote.nonce,
                                        quote.signature
                                        );
    // Check if signature is valid
    require(signer == quote.quoter, "invalid signature");
    
    // Check that quote hasn't expired yet
    require(quote.expiryTime == 0 || quote.expiryTime > block.timestamp, "quote expired");

    // Check that the nonce hasn't already been used
    require(!noncesUsed[quote.quoter][quote.nonce], "invalid nonce");

    // The borrow amount cannot be greater than the remaining Quote size
    amount = Math.min(amount, quote.principal - quoteFill[quote.signature]);

    // For partial fills, get the equivalent `amountPlusInterest` to pay at the end
    uint amountPlusInterest = _scaleAmountWithInterest(
                                                       amount,
                                                       quote.principal,
                                                       quote.principalPlusInterest
                                                       );
    
    _createFixedRateLoan(
                         block.timestamp,
                         quote.endTime,
                         amount,
                         amountPlusInterest,
                         quote.quoter,
                         msg.sender
                         );    

    // Update the partial fills for the quote
    quoteFill[quote.signature] = quoteFill[quote.signature] + amount;

    // Nonce is used up once the partial fill equals the original principal amount
    if(quoteFill[quote.signature] == quote.principal){
      noncesUsed[quote.quoter][quote.nonce] = true;
    }
  }

  function _createFixedRateLoan(
                                uint startTime,
                                uint endTime,
                                uint principal,
                                uint principalPlusInterest,
                                address lender,
                                address borrower
                                ) private {

    // Loan amount must be strictly positive
    require(principal > 0, "invalid principal amount");

    // Interest rate needs to be positive
    require(principal < principalPlusInterest, "invalid principalPlusInterest");

    // Cannot borrow from yourself
    require(lender != borrower, "invalid counterparty");

    // Cannot create a loan past its maturity time
    require(block.timestamp < endTime, "invalid endTime");

    require(_checkApproval(lender, principalTokenAddress, principal), "lender insufficient allowance");

    require(_checkBalance(lender, principalTokenAddress, principal), "lender insufficient balance");

    //TODO No checks have been made on borrower collateral yet
    //This check should look like:
    // (depositValue + principalPlusInterest(USD)) / (borrowValue - lendCredits) > 1.0

    // Create FixedRateLoan. By default, `amountRepaid` should be zero at inception
    QTypes.FixedRateLoan memory frl = QTypes.FixedRateLoan(
                                                           startTime,
                                                           endTime,
                                                           principal,
                                                           principalPlusInterest,
                                                           0,
                                                           lender,
                                                           borrower
                                                           );
    
    // Adding `frl` to storage and pointers to `frl` for `accountBorrows` and `accountLends`
    outstandingLoans[currentLoanId] = frl;
    accountBorrows[borrower].push(currentLoanId);
    accountLends[lender].push(currentLoanId);

    // Keep `currentLoanId` unique for the next loan
    currentLoanId++; 

    // Transfer principal from lender to borrower
    IERC20 principalToken = IERC20(principalTokenAddress);
    principalToken.transferFrom(lender, borrower, principal);
  }

  
  function _scaleAmountWithInterest(
                                    uint amount,
                                    uint principal,
                                    uint principalPlusInterest
                                    ) internal pure returns(uint){
    uint rate = principalPlusInterest.mul(QConst.MANTISSA_DEFAULT).div(principal);
    uint amountPlusInterest = amount.mul(rate).div(QConst.MANTISSA_DEFAULT);
    return amountPlusInterest;
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

library QConst {
  
  /// @notice Generic mantissa corresponding to ETH decimals
  uint internal constant MANTISSA_DEFAULT = 1e18;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  struct Market {
    bool isListed;
    address oracleFeed;
  }
  
  /// @notice Struct containing fixed rate loan terms
  /// @member startTime Starting timestamp  when the loan is instantiated
  /// @member endTime Ending timestamp when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startTime;
    uint endTime;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }


  /// @notice Struct for a Quote
  /// @param principalTokenAddress Address of token which the loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param expiryTime Timestamp after which the quote is no longer valid
  /// @param endTime Ending timestamp when the loan terminates
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  struct Quote {
    address principalTokenAddress;
    address quoter;
    uint8 side;
    uint expiryTime;
    uint endTime;
    uint principal;
    uint principalPlusInterest;
    uint nonce;
    bytes signature;
  }
  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Verifier {

  /// @notice Recover the signer of a Quote given the plaintext inputs and signature
  /// @param principalTokenAddress Address of token which loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param expiryTime Timestamp after which the quote is no longer valid
  /// @param endTime Ending timestamp when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return address signer of the message
  function getSigner(
                     address principalTokenAddress,
                     address quoter,
                     uint8 side,
                     uint expiryTime,
                     uint endTime,
                     uint principal,
                     uint principalPlusInterest,
                     uint nonce,
                     bytes memory signature
                     ) internal pure returns(address){
    bytes32 messageHash = getMessageHash(
                                         principalTokenAddress,
                                         quoter,
                                         side,
                                         expiryTime,
                                         endTime,
                                         principal,
                                         principalPlusInterest,
                                         nonce
                                         );
    return  _recoverSigner(messageHash, signature);
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param principalTokenAddress Address oftoken which loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param expiryTime Timestamp after which the quote is no longer valid
  /// @param endTime Ending timestamp when the loan terminates
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @return bytes32 message hash
  function getMessageHash(
                          address principalTokenAddress,
                          address quoter,
                          uint8 side,
                          uint expiryTime,
                          uint endTime,
                          uint principal,
                          uint principalPlusInterest,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        principalTokenAddress,
                                                        quoter,
                                                        side,
                                                        expiryTime,
                                                        endTime,
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