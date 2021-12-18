// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./libraries/Verifier.sol";

contract QuotePublisher {

  /// @notice Emitted when a Quoter posts a Quote
  event Quote(
              address principalTokenAddress,
              address quoter,
              uint8 side,
              uint expiryTime, //if 0, then quote never expires
              uint endTime,
              uint principal,
              uint principalPlusInterest,
              uint nonce,
              bytes signature                   
              );

  /// @notice Allows Quoter to publish a Quote onchain as an event
  /// @param principalTokenAddress Address of token which the loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param expiryTime Timestamp after which the quote is no longer valid
  /// @param endTime Ending timestamp when the loan terminates
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  function createQuote(
                       address principalTokenAddress,
                       address quoter,
                       uint8 side,
                       uint expiryTime,
                       uint endTime,
                       uint principal,
                       uint principalPlusInterest,
                       uint256 nonce,
                       bytes memory signature
                       ) external {
    
    address signer = Verifier.getSigner(
                                        principalTokenAddress,
                                        quoter,
                                        side,
                                        expiryTime,
                                        endTime,
                                        principal,
                                        principalPlusInterest,
                                        nonce,
                                        signature
                                        );
    
    require(signer == quoter, "signature mismatch");
    require(principal > 0, "invalid principal");
    require(side <= 1, "invalid side");
    require(expiryTime == 0 || expiryTime > block.timestamp, "invalid expiry time");
    require(endTime > block.timestamp, "invalid end time");
    // TODO add an allowance check to QodaFixedRateLoan contract
    require(_checkBalance(principalTokenAddress, quoter, principal), "insufficient token balance");
      
    emit Quote(
               principalTokenAddress,
               quoter,
               side,
               expiryTime,
               endTime,
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