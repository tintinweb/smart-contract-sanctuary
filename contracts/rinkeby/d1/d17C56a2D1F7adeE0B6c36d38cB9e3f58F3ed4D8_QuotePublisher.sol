// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IFixedRateLoanMarket.sol";
import "./libraries/QVerifier.sol";

contract QuotePublisher {

  /// @notice Emitted when a Quoter posts a Quote
  event Quote(
              address marketAddress,
              address quoter,
              uint8 side,
              uint quoteExpiryTime, //if 0, then quote never expires
              uint principal,
              uint principalPlusInterest,
              uint nonce,
              bytes signature                   
              );

  /// @notice Allows Quoter to publish a Quote onchain as an event
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function createQuote(
                       address marketAddress,
                       address quoter,
                       uint8 side,
                       uint quoteExpiryTime,
                       uint principal,
                       uint principalPlusInterest,
                       uint256 nonce,
                       bytes memory signature
                       ) external {
    
    address signer = QVerifier.getSigner(
                                        marketAddress,
                                        quoter,
                                        side,
                                        quoteExpiryTime,
                                        principal,
                                        principalPlusInterest,
                                        nonce,
                                        signature
                                        );

    // Author of the signature must match the address of the quoter
    require(signer == quoter, "signature mismatch");

    // Must be Quote for positive amount
    require(principal > 0, "invalid principal");

    // Only {0,1} are valid sides. 0 if Quoter is borrower, 1 if Quoter is lender
    require(side <= 1, "invalid side");
    
    // Quote must not be expired. `quoteExpiryTime` of 0 indicates never expiring
    require(quoteExpiryTime == 0 || quoteExpiryTime > block.timestamp, "invalid expiry time");

    // Check if user has enough balance before publishing quote
    address tokenAddress = IFixedRateLoanMarket(marketAddress).principalTokenAddress();
    require(_checkBalance(tokenAddress, quoter, principal), "insufficient token balance");

    // TODO add an allowance check to QodaFixedRateLoan contract
    
    emit Quote(
               marketAddress,
               quoter,
               side,
               quoteExpiryTime,
               principal,
               principalPlusInterest,
               nonce,
               signature
               );
    
  }

  /** Internal Functions **/

  /// @notice Verify if the user has enough token balance
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address tokenAddress,
                         address userAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IFixedRateLoanMarket is IERC20, IERC20Metadata {

  /// @notice Call this function to enter into FixedRateLoan as a borrower
  /// @param amount Amount that the borrower wants to execute, in case its not full size
  /// @param lender Account of the lender
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function borrow(
                  uint amount,
                  address lender,
                  uint quoteExpiryTime,
                  uint principal,
                  uint principalPlusInterest,
                  uint nonce,
                  bytes memory signature
                  ) external;
  
  /// @notice Call this function to enter into FixedRateLoan as a lender
  /// @param amount Amount that the lender wants to execute, in case its not full size
  /// @param borrower Account of the borrower
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function lend(
                uint amount,
                address borrower,
                uint quoteExpiryTime,
                uint principal,
                uint principalPlusInterest,
                uint nonce,
                bytes memory signature
                ) external;

  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint);

  /// @notice Borrower makes repayment with qTokens. The qTokens will automatically
  /// get burned and the accountBorrows deducted accordingly.
  /// @param amount Amount to pay in qTokens
  /// @return uint Remaining account borrow amount
  function repayBorrowWithqToken(uint amount) external returns(uint);
  
  /// @notice By setting the nonce in  `noncesUsed` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external;



  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManagerAddress() external view returns(address);
  
  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function principalTokenAddress() external view returns(address);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);
  
  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function noncesUsed(address account, uint nonce) external view returns(bool);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint);

  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  /* event FixedRateLoan( */
  /*                     address borrower, */
  /*                     address lender, */
  /*                     uint principal, */
  /*                     uint principalPlusInterest); */
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QVerifier {

  /// @notice Recover the signer of a Quote given the plaintext inputs and signature
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return address signer of the message
  function getSigner(
                     address marketAddress,
                     address quoter,
                     uint8 side,
                     uint quoteExpiryTime,
                     uint principal,
                     uint principalPlusInterest,
                     uint nonce,
                     bytes memory signature
                     ) internal pure returns(address){
    bytes32 messageHash = getMessageHash(
                                         marketAddress,
                                         quoter,
                                         side,
                                         quoteExpiryTime,
                                         principal,
                                         principalPlusInterest,
                                         nonce
                                         );
    return  _recoverSigner(messageHash, signature);
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param marketAddress Address `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param principal Size of the loan
  /// @param principalPlusInterest Final amount that must be paid by the borrower
  /// @param nonce For uniqueness of signature
  /// @return bytes32 message hash
  function getMessageHash(
                          address marketAddress,
                          address quoter,
                          uint8 side,
                          uint quoteExpiryTime,
                          uint principal,
                          uint principalPlusInterest,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        marketAddress,
                                                        quoter,
                                                        side,
                                                        quoteExpiryTime,
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