// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./libraries/SigVerify.sol";
import "./interfaces/token/IERC20.sol";

contract QodaV1Quote {

  event LenderQuote(
                    address addressLoanToken,
                    address addressLender,
                    uint256 quoteExpiryBlock, //if 0, then quote never expires
                    uint256 endBlock,
                    uint256 notional,
                    uint256 fixedRatePerBlock,
                    uint256 nonce,
                    bytes signature                   
                    );
  
  event BorrowerQuote(
                      address addressLoanToken,
                      address addressBorrower,
                      address addressCollateralToken,
                      uint256 quoteExpiryBlock, //if 0, then quote never expires
                      uint256 endBlock,
                      uint256 notional,
                      uint256 fixedRatePerBlock,
                      uint256 initCollateral,
                      uint256 nonce,
                      bytes signature
                      );

  // When creating a lender quote, addressCollateralToken/initCollateral doesn't
  // need to be specified since the lender does not have to put up any collateral
  function createLenderQuote(
                             address addressLoanToken,
                             address addressLender,
                             uint256 quoteExpiryBlock,
                             uint256 endBlock,
                             uint256 notional,
                             uint256 fixedRatePerBlock,
                             uint256 nonce,
                             bytes memory signature
                             ) public {
    bool isQuoteValid = SigVerify.checkLenderSignature(
                                              addressLoanToken,
                                              addressLender,
                                              quoteExpiryBlock,
                                              endBlock,
                                              notional,
                                              fixedRatePerBlock,
                                              nonce,
                                              signature
                                              );
    require(notional > 0, "notional too small");
    require(isQuoteValid, "signature doesn't match");
    require(checkBalance(addressLender, addressLoanToken, notional), "lender balance too low");
    //require(checkApproval(addressLender, addressLoanToken, notional), "lender must approve contract spend");

    emit LenderQuote(
                     addressLoanToken,
                     addressLender,
                     quoteExpiryBlock,
                     endBlock,
                     notional,
                     fixedRatePerBlock,
                     nonce,
                     signature
                     );
  }

  // INTERNAL FUNCTIONS  
  function checkBalance(
                        address userAddress,
                        address tokenAddress,
                        uint256 amount
                        ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }
  
  function checkApproval(
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library SigVerify {

  function checkLenderSignature(
                                address addressLoanToken,
                                address addressLender,
                                uint256 quoteExpiryBlock,
                                uint256 endBlock,
                                uint256 notional,
                                uint256 fixedRatePerBlock,
                                uint256 nonce,
                                bytes memory signature
                                ) internal pure returns(bool){
    bytes32 messageHash = getLenderMessageHash(
                                               addressLoanToken,
                                               addressLender,
                                               quoteExpiryBlock,
                                               endBlock,
                                               notional,
                                               fixedRatePerBlock,
                                               nonce
                                               );
    bytes32 prefixedMessageHash = getPrefixedMessageHash(messageHash);
    address signer = recoverSigner(prefixedMessageHash, signature);
    return signer == addressLender;
  }

  function getLenderMessageHash(
                                address addressLoanToken,
                                address addressLender,
                                uint256 quoteExpiryBlock,
                                uint256 endBlock,
                                uint256 notional,
                                uint256 fixedRatePerBlock,
                                uint256 nonce
                                ) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(
                                      addressLoanToken,
                                      addressLender,
                                      quoteExpiryBlock,
                                      endBlock,
                                      notional,
                                      fixedRatePerBlock,
                                      nonce
                                      ));
  }





  
  function getPrefixedMessageHash(bytes32 messageHash) internal pure returns(bytes32){
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
  }

  // This function returns the address of the signer of the prefixedMessageHash.
  // Compare this address versus the cleartext address given to verify the
  // message is indeed signed by the owner.
  function recoverSigner(
                         bytes32 prefixedMessageHash,
                         bytes memory signature
                         ) internal pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the prefixedMessageHash and signature
    return ecrecover(prefixedMessageHash, v, r, s);
  }
  
  function splitSignature(bytes memory signature) internal pure returns(
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