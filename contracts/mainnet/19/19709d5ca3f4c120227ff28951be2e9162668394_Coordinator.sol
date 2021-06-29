/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Coordinator {

  address public multisig;
  uint256 public minBalance = 1000 ether;
  mapping(address=>uint256) public proposalTimeout;
  mapping(address=>mapping(string=>address)) public proposers;

  IERC20 constant public NFT = IERC20(address(0xcB8d1260F9c92A3A545d409466280fFdD7AF7042));

  // Propose a new instruction
  event InstructionProposed(address proposer, address contractAddress, string uri);

  // DAO approves an instruction into the index
  event InstructionApproved(string checksum, address contractAddress, string uri);

  // TODO: reject proposal (because it's spam) and keep the fee
  event InstructionRejected(address proposer, address contractAddress, string uri);

  // TODO: deferr proposal (because it was voted against) and return fee to proposer
  event InstructionDeferred(address proposer, address contractAddress, string uri);

  constructor() {
    multisig = msg.sender;
  }

  function approveInstruction(address contractAddress, string memory uri, string memory checksum) public {
    require(msg.sender == multisig, "Only multisig can update instruction set");
    emit InstructionApproved(checksum, contractAddress, uri);
  }

  function proposeInstruction(address contractAddress, string memory uri) public {
    require(msg.sender == multisig, "Only multisig can update multisig");

    // TODO: replace with a deposit of NFT tokens to be repaid when proposal is approved or rejected
    require(NFT.balanceOf(msg.sender) > minBalance, "Not enough NFT Protocol tokens");
    require(block.timestamp > proposalTimeout[msg.sender], "Proposing again too soon");
    proposalTimeout[msg.sender] = block.timestamp + 1 days;

    proposers[contractAddress][uri] = msg.sender;
    emit InstructionProposed(msg.sender, contractAddress, uri);
  }

  function rejectInstruction(address contractAddress, string memory uri) public {
    require(msg.sender == multisig, "Only multisig can reject a proposal");
    // TODO: increment a counter of deposited tokens kept
    emit InstructionRejected(msg.sender, contractAddress, uri);
  }

  function deferInstruction(address contractAddress, string memory uri) public {
    require(msg.sender == multisig, "Only multisig can defer a proposal");
    // TODO: return proposer's deposit
    emit InstructionDeferred(proposers[contractAddress][uri], contractAddress, uri);
  }

  function updateMultisig(address _multisig) public {
    require(msg.sender == multisig, "Only multisig can update multisig");
    multisig = _multisig;
  }

  function updateMinBalance(uint256 newBalance) public {
    require(msg.sender == multisig, "Only multisig can update minBalance");
    minBalance = newBalance;
  }

}

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