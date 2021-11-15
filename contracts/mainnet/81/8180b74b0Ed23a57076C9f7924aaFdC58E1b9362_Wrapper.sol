// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@airswap/light/contracts/interfaces/ILight.sol";
import "./interfaces/IWETH.sol";

/**
 * @title Light: Simple atomic swap
 * @notice https://www.airswap.io/
 */
contract Wrapper {
  ILight public lightContract;
  IWETH public wethContract;

  /**
   * @notice Constructor
   * @param _lightContract address
   * @param _wethContract address
   */
  constructor(address _lightContract, address _wethContract) {
    lightContract = ILight(_lightContract);
    wethContract = IWETH(_wethContract);
  }

  /**
   * @notice Required when withdrawing from WETH
   * @dev During unwraps, WETH.withdraw transfers ether to msg.sender (this contract)
   */
  receive() external payable {
    // Ensure the message sender is the WETH contract.
    if (msg.sender != address(wethContract)) {
      revert("DO_NOT_SEND_ETHER");
    }
  }

  /**
   * @notice Atomic ERC20 Swap
   * @param nonce uint256 Unique and should be sequential
   * @param expiry uint256 Expiry in seconds since 1 January 1970
   * @param signerWallet address Wallet of the signer
   * @param signerToken address ERC20 token transferred from the signer
   * @param signerAmount uint256 Amount transferred from the signer
   * @param senderToken address ERC20 token transferred from the sender
   * @param senderAmount uint256 Amount transferred from the sender
   * @param v uint8 "v" value of the ECDSA signature
   * @param r bytes32 "r" value of the ECDSA signature
   * @param s bytes32 "s" value of the ECDSA signature
   */
  function swap(
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public payable {
    if (senderToken == address(wethContract)) {
      // Ensure message value is param
      require(senderAmount == msg.value, "VALUE_MUST_BE_SENT");
      // Wrap (deposit) the ether
      wethContract.deposit{value: msg.value}();
    }

    lightContract.swapWithRecipient(
      msg.sender,
      nonce,
      expiry,
      signerWallet,
      signerToken,
      signerAmount,
      senderToken,
      senderAmount,
      v,
      r,
      s
    );

    if (signerToken == address(wethContract)) {
      // Unwrap (withdraw) the ether
      wethContract.withdraw(signerAmount);
      // Transfer ether to the recipient
      (bool success, ) = msg.sender.call{value: signerAmount}("");
      require(success, "ETH_RETURN_FAILED");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILight {
  event Swap(
    uint256 indexed nonce,
    uint256 timestamp,
    address indexed signerWallet,
    address signerToken,
    uint256 signerAmount,
    uint256 signerFee,
    address indexed senderWallet,
    address senderToken,
    uint256 senderAmount
  );

  event Cancel(uint256 indexed nonce, address indexed signerWallet);

  event Authorize(address indexed signer, address indexed signerWallet);

  event Revoke(address indexed signer, address indexed signerWallet);

  event SetFee(uint256 indexed signerFee);

  event SetFeeWallet(address indexed feeWallet);

  function swap(
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function swapWithRecipient(
    address recipient,
    uint256 nonce,
    uint256 expiry,
    address signerWallet,
    address signerToken,
    uint256 signerAmount,
    address senderToken,
    uint256 senderAmount,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function authorize(address sender) external;

  function revoke() external;

  function cancel(uint256[] calldata nonces) external;

  function nonceUsed(address, uint256) external view returns (bool);

  function authorized(address) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
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

