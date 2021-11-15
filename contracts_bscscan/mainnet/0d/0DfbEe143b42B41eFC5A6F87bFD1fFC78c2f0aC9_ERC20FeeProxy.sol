// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20FeeProxy
 * @notice This contract performs an ERC20 token transfer, with a Fee sent to a third address and stores a reference
 */
contract ERC20FeeProxy {
  // Event to declare a transfer with a reference
  event TransferWithReferenceAndFee(
    address tokenAddress,
    address to,
    uint256 amount,
    bytes indexed paymentReference,
    uint256 feeAmount,
    address feeAddress
  );

  // Fallback function returns funds to the sender
  receive() external payable {
    revert("not payable receive");
  }

  /**
    * @notice Performs a ERC20 token transfer with a reference
              and a transfer to a second address for the payment of a fee
    * @param _tokenAddress Address of the ERC20 token smart contract
    * @param _to Transfer recipient
    * @param _amount Amount to transfer
    * @param _paymentReference Reference of the payment related
    * @param _feeAmount The amount of the payment fee
    * @param _feeAddress The fee recipient
    */
  function transferFromWithReferenceAndFee(
    address _tokenAddress,
    address _to,
    uint256 _amount,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address _feeAddress
    ) external
    {
    require(safeTransferFrom(_tokenAddress, _to, _amount), "payment transferFrom() failed");
    if (_feeAmount > 0 && _feeAddress != address(0)) {
      require(safeTransferFrom(_tokenAddress, _feeAddress, _feeAmount), "fee transferFrom() failed");
    }
    emit TransferWithReferenceAndFee(
      _tokenAddress,
      _to,
      _amount,
      _paymentReference,
      _feeAmount,
      _feeAddress
    );
  }

  /**
   * @notice Call transferFrom ERC20 function and validates the return data of a ERC20 contract call.
   * @dev This is necessary because of non-standard ERC20 tokens that don't have a return value.
   * @return result The return value of the ERC20 call, returning true for non-standard tokens
   */
  function safeTransferFrom(address _tokenAddress, address _to, uint256 _amount) internal returns (bool result) {
    /* solium-disable security/no-inline-assembly */
    // check if the address is a contract
    assembly {
      if iszero(extcodesize(_tokenAddress)) { revert(0, 0) }
    }
    
    // solium-disable-next-line security/no-low-level-calls
    (bool success, ) = _tokenAddress.call(abi.encodeWithSignature(
      "transferFrom(address,address,uint256)",
      msg.sender,
      _to,
      _amount
    ));

    assembly {
        switch returndatasize()
        case 0 { // not a standard erc20
            result := 1
        }
        case 32 { // standard erc20
            returndatacopy(0, 0, 32)
            result := mload(0)
        }
        default { // anything else, should revert for safety
            revert(0, 0)
        }
    }

    require(success, "transferFrom() has been reverted");

    /* solium-enable security/no-inline-assembly */
    return result;
  }
}

