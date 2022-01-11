pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Bridge {
  address public owner;
  address private tokenAddress;
  uint private crossFee = 1; // in gwei

  mapping(address => mapping(uint => bool)) public sendNonces;
  mapping(address => mapping(uint => bool)) public recvNonces;

  enum Step { Send, Recv }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

  constructor(uint crossFee_, address tokenAddress_) {
    owner = msg.sender;
    crossFee = crossFee_;
    tokenAddress = tokenAddress_;
  }

  // transfer from msg.sender to contract
  function crossSend(
    address recipient,
    uint tokenAmount,
    uint nonce) external payable {
    // check fee
    require(msg.value >= crossFee, 'Insufficient fee.');
    require(sendNonces[msg.sender][nonce] == false, 'transfer already processed');

    sendNonces[msg.sender][nonce] = true;

    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(msg.sender, owner, tokenAmount);

    emit Transfer(
      msg.sender,
      recipient,
      tokenAmount,
      block.timestamp,
      nonce,
      Step.Send
    );
  }

  // transfer from contract to recipient
  function crossRecv(
    address sender,
    address recipient, 
    uint tokenAmount,
    uint nonce) external onlyOwner {
    require(recvNonces[msg.sender][nonce] == false, 'transfer already processed');
    recvNonces[msg.sender][nonce] = true;

    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(owner, recipient, tokenAmount);

    emit Transfer(
      sender,
      recipient,
      tokenAmount,
      block.timestamp,
      nonce,
      Step.Recv
    );
  }

  // withdraw from contract to owner
  function withdraw() external onlyOwner {
    // get the amount of Ether stored in this contract
    uint amount = address(this).balance;

    // send all Ether to owner
    // Owner can receive Ether since the address of owner is payable
    (bool success, ) = payable(owner).call{value: amount}("");
    require(success, "Failed to send balance");
  }

  // set fee
  function setFee(uint fee) external onlyOwner {
    crossFee = fee;
  }

  // get fee
  function getFee() external view returns (uint) {
    return crossFee;
  }

  // set owner
  function setOwner(address owner_) external onlyOwner {
    require(owner_ != address(0), 'Owner can not be null.');
    owner = owner_;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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