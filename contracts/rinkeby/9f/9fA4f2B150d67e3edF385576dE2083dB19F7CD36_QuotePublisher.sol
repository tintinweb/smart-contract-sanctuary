// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IEIP20.sol";
import "./libraries/Verifier.sol";
import "./interfaces/IFixedRateLoanMarket.sol";

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
    
    address signer = Verifier.getSigner(
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
    address tokenAddress = IFixedRateLoanMarket(marketAddress).getPrincipalTokenAddress();
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
    if(IEIP20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

}

pragma solidity ^0.8.9;

interface IEIP20 {
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

pragma solidity ^0.8.9;

import "./IEIP20.sol";

interface IFixedRateLoanMarket is IEIP20 {

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
  function repayBorrow(uint amount) external;

  /// @notice By setting the nonce in  `noncesUsed` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external;

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function getPrincipalTokenAddress() external view returns(address);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function getMaturity() external view returns(uint);
  
  /// @notice True if a nonce has been used for a Quote, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function getNoncesUsed(address account, uint nonce) external view returns(bool);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function getAccountBorrows(address account) external view returns(uint);

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function getQuoteFill(bytes memory signature) external view returns(uint);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Verifier {

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