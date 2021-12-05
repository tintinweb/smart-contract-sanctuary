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
              LOAN_CONTRACT_NOT_FOUND
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./libraries/SigVerify.sol";
import "./interfaces/token/IERC20.sol";
import "./interfaces/IQodaV1Quote.sol";
import "./ErrorCode.sol";

contract QodaV1Quote is ErrorCode {
  
  /// @notice Emitted when a Quoter posts a Quote
  event Quote(
              address principalTokenAddress,
              address quoter,
              uint8 side,
              uint quoteExpiryBlock, //if 0, then quote never expires
              uint endBlock,
              uint principal,
              uint principalPlusInterest,
              uint nonce,
              bytes signature                   
              );

  /**
     @notice Allows Quoter to post a Quote onchain as an event
     @param principalTokenAddress Address of token which the loan will be denominated
     @param quoter Account of the Quoter
     @param side 0 if Quoter is borrowing, 1 if Quoter is lending
     @param quoteExpiryBlock Block after which the quote is no longer valid
     @param endBlock Ending block when the loan terminates
     @param principal Initial size of the loan
     @param principalPlusInterest Final amount that must be paid by borrower
     @param nonce For uniqueness of signature
     @param signature signed hash of the Quote message
     @return uint 0 if successful otherwise error code
  */
  function createQuote(
                       address principalTokenAddress,
                       address quoter,
                       uint8 side,
                       uint quoteExpiryBlock,
                       uint endBlock,
                       uint principal,
                       uint principalPlusInterest,
                       uint256 nonce,
                       bytes memory signature
                       ) external returns(uint){
    
    bool isSignatureMatch = SigVerify.checkQuoterSignature(
                                                           principalTokenAddress,
                                                           quoter,
                                                           side,
                                                           quoteExpiryBlock,
                                                           endBlock,
                                                           principal,
                                                           principalPlusInterest,
                                                           nonce,
                                                           signature
                                                           );

    if(principal == 0){
      return fail(Error.INVALID_PRINCIPAL);
    }

    if(side > 1){
      return fail(Error.INVALID_SIDE);
    }
    
    if(quoteExpiryBlock != 0 && quoteExpiryBlock < block.number){
      return fail(Error.INVALID_QUOTE_EXPIRY_BLOCK);
    }

    if(!_checkApproval(quoter, principalTokenAddress, principal)){
      return fail(Error.TOKEN_INSUFFICIENT_ALLOWANCE);
    }

    if(!_checkBalance(quoter, principalTokenAddress, principal)){
      return fail(Error.TOKEN_INSUFFICIENT_BALANCE);
    }

    if(!isSignatureMatch){
      return fail(Error.SIGNATURE_MISMATCH);
    }
      
    emit Quote(
               principalTokenAddress,
               quoter,
               side,
               quoteExpiryBlock,
               endBlock,
               principal,
               principalPlusInterest,
               nonce,
               signature
               );

    return uint(Error.NO_ERROR);
  }

  /** Internal Functions **/

  /**
     @notice Verify if the user has enough token balance
     @param userAddress Address of the account to check
     @param tokenAddress Address of the ERC20 token
     @param amount Balance must be greater than or equal to this amount
     @return bool true if sufficient balance otherwise false
  */
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

  /**
     @notice Verify if the user has approved the smart contract for spend
     @param userAddress Address of the account to check
     @param tokenAddress Address of the ERC20 token
     @param amount Allowance  must be greater than or equal to this amount
     @return bool true if sufficient allowance otherwise false
  */
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IQodaV1Quote {
  
  /// @notice Allows Quoter to post a Quote onchain as an event
  /// @param principalTokenAddress Address of token which loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quote is lending
  /// @param quoteExpiryBlock Block after which the quote is no longer valid
  /// @param endBlock Ending block when the loan terminates
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint 0 if successful otherwise error code
  function createQuote(
                       address principalTokenAddress,
                       address quoter,
                       uint8 side,
                       uint quoteExpiryBlock,
                       uint endBlock,
                       uint principal,
                       uint principalPlusInterest,
                       uint nonce,
                       bytes memory signature
                       ) external returns(uint);

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