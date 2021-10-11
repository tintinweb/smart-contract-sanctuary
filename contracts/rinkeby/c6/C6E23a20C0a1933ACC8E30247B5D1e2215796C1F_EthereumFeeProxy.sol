// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title EthereumFeeProxy
 * @notice This contract performs an Ethereum transfer with a Fee sent to a third address and stores a reference
 */
contract EthereumFeeProxy is ReentrancyGuard{
  // Event to declare a transfer with a reference
  event TransferWithReferenceAndFee(
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
  * @notice Performs an Ethereum transfer with a reference
  * @param _to Transfer recipient
  * @param _paymentReference Reference of the payment related
  * @param _feeAmount The amount of the payment fee (part of the msg.value)
  * @param _feeAddress The fee recipient
  */
  function transferWithReferenceAndFee(
    address payable _to,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address payable _feeAddress
  )
    external
    payable
  {
    transferExactEthWithReferenceAndFee(
      _to,
      msg.value - _feeAmount,
      _paymentReference,
      _feeAmount,
      _feeAddress
    );
  }


  /**
  * @notice Performs an Ethereum transfer with a reference with an exact amount of eth
  * @param _to Transfer recipient
  * @param _amount Amount to transfer
  * @param _paymentReference Reference of the payment related
  * @param _feeAmount The amount of the payment fee (part of the msg.value)
  * @param _feeAddress The fee recipient
  */
  function transferExactEthWithReferenceAndFee(
    address payable _to,
    uint256 _amount,
    bytes calldata _paymentReference,
    uint256 _feeAmount,
    address payable _feeAddress
  )
    nonReentrant
    public
    payable
  {
    _to.transfer(_amount);
    _feeAddress.transfer(_feeAmount);
    // transfer the remaining ethers to the sender
    payable(msg.sender).transfer(msg.value - _amount - _feeAmount);

    emit TransferWithReferenceAndFee(_to, _amount, _paymentReference, _feeAmount, _feeAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}