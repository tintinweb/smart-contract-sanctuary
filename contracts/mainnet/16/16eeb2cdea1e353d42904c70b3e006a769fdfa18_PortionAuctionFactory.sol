/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// File: flattener/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: flattener/openzeppelin-solidity/contracts/introspection/IERC165.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: flattener/openzeppelin-solidity/contracts/token/ERC721/IERC721.sol


pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: flattener/openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: flattener/multi-token-standard/contracts/interfaces/IERC1155.sol

pragma solidity 0.7.4;


interface IERC1155 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// File: flattener/multi-token-standard/contracts/interfaces/IERC1155TokenReceiver.sol

pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// File: flattener/PortionAuction.sol

pragma solidity ^0.7.4;






contract PortionAuction is IERC721Receiver, IERC1155TokenReceiver {
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  address public owner;
  address public controller;
  address public beneficiary;
  address public highestBidder;

  uint public tokenId;
  uint public quantity;
  uint public highestBid;

  bool public cancelled;
  bool public itemClaimed;
  bool public controllerClaimedFunds;
  bool public beneficiaryClaimedFunds;
  bool public acceptPRT;
  bool public isErc1155;

  IERC20 portionTokenContract;
  IERC721 artTokenContract;
  IERC1155 artToken1155Contract;

  mapping(address => uint256) public fundsByBidder;

  constructor(
    address _controller,
    address _beneficiary,
    bool _acceptPRT,
    bool _isErc1155,
    uint _tokenId,
    uint _quantity,
    address portionTokenAddress,
    address artTokenAddress,
    address artToken1155Address
  ) {
    owner = msg.sender;
    controller = _controller;
    beneficiary = _beneficiary;
    acceptPRT = _acceptPRT;
    isErc1155 = _isErc1155;
    tokenId = _tokenId;
    quantity = _quantity;

    if (acceptPRT) {
      portionTokenContract = IERC20(portionTokenAddress);
    }

    if (isErc1155) {
      artToken1155Contract = IERC1155(artToken1155Address);
    } else {
      artTokenContract = IERC721(artTokenAddress);
    }
  }

  function placeBid(address bidder, uint totalAmount)
  onlyOwner
  external
  {
    fundsByBidder[bidder] = totalAmount;

    if (bidder != highestBidder) {
      highestBidder = bidder;
    }

    highestBid = totalAmount;
  }

  function handlePayment()
  payable
  onlyOwner
  external
  {}

  function withdrawFunds(
    address claimer,
    address withdrawalAccount,
    uint withdrawalAmount,
    bool _beneficiaryClaimedFunds,
    bool _controllerClaimedFunds
  )
  onlyOwner
  external
  {
    // send the funds
    if (acceptPRT) {
      require(portionTokenContract.transfer(claimer, withdrawalAmount));
    } else {
      (bool sent, ) = claimer.call{value: withdrawalAmount}("");
      require(sent);
    }

    fundsByBidder[withdrawalAccount] -= withdrawalAmount;
    if (_beneficiaryClaimedFunds) {
      beneficiaryClaimedFunds = true;
    }
    if (_controllerClaimedFunds) {
      controllerClaimedFunds = true;
    }
  }

  function transferItem(
    address claimer
  )
  onlyOwner
  external
  {
    if (isErc1155) {
      artToken1155Contract.safeTransferFrom(address(this), claimer, tokenId, quantity, "");
    } else {
      artTokenContract.safeTransferFrom(address(this), claimer, tokenId);
    }

    itemClaimed = true;
  }

  function cancelAuction()
  onlyOwner
  external
  {
    cancelled = true;
  }

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata data)
  external
  pure
  override
  returns (bytes4)
  {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data)
  external
  pure
  override
  returns(bytes4)
  {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data)
  external
  pure
  override
  returns(bytes4)
  {
    return this.onERC1155BatchReceived.selector;
  }
}

// File: flattener/openzeppelin-solidity/contracts/math/SafeMath.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: flattener/PortionAuctionFactory.sol

pragma solidity ^0.7.4;






contract PortionAuctionFactory {
  using SafeMath for uint;

  struct AuctionParameters {
    uint startingBid;
    uint bidStep;
    uint startBlock;
    uint endBlock;
    uint overtimeBlocksSize;
    uint feeRate;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  bytes32 public name = "PortionAuctionFactory";
  address owner;
  IERC20 public portionTokenContract;
  IERC721 public artTokenContract;
  IERC1155 public artToken1155Contract;
  mapping(address => AuctionParameters) public auctionParameters;

  event AuctionCreated(address indexed auctionContract, address indexed beneficiary, uint indexed tokenId);
  event BidPlaced (address indexed bidder, uint bid);
  event FundsClaimed (address indexed claimer, address withdrawalAccount, uint withdrawalAmount);
  event ItemClaimed (address indexed claimer);
  event AuctionCancelled ();

  constructor(address portionTokenAddress, address artTokenAddress, address artToken1155Address) {
    owner = msg.sender;
    portionTokenContract = IERC20(portionTokenAddress);
    artTokenContract = IERC721(artTokenAddress);
    artToken1155Contract = IERC1155(artToken1155Address);
  }

  function createAuction(
    address beneficiary,
    uint tokenId,
    uint bidStep,
    uint startingBid,
    uint startBlock,
    uint endBlock,
    bool acceptPRT,
    bool isErc1155,
    uint quantity,
    uint feeRate,
    uint overtimeBlocksSize
  )
  onlyOwner
  external
  {
    require(beneficiary != address(0));
    require(bidStep > 0);
    require(startingBid >= 0);
    require(startBlock < endBlock);
    require(startBlock >= block.number);
    require(feeRate <= 100);
    if (isErc1155) {
      require(quantity > 0);
    }

    PortionAuction newAuction = new PortionAuction(
      msg.sender,
      beneficiary,
      acceptPRT,
      isErc1155,
      tokenId,
      quantity,
      address(portionTokenContract),
      address(artTokenContract),
      address(artToken1155Contract)
    );

    auctionParameters[address(newAuction)] = AuctionParameters(
      startingBid,
      bidStep,
      startBlock,
      endBlock,
      overtimeBlocksSize,
      feeRate
    );

    if (isErc1155) {
      artToken1155Contract.safeTransferFrom(msg.sender, address(newAuction), tokenId, quantity, "");
    } else {
      artTokenContract.safeTransferFrom(msg.sender, address(newAuction), tokenId);
    }

    emit AuctionCreated(address(newAuction), beneficiary, tokenId);
  }

  function placeBid(
    address auctionAddress
  )
  payable
  external
  {
    PortionAuction auction = PortionAuction(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(block.number >= parameters.startBlock);
    require(block.number < parameters.endBlock);
    require(!auction.cancelled());
    require(!auction.acceptPRT());
    require(msg.sender != auction.controller());
    require(msg.sender != auction.beneficiary());
    require(msg.value > 0);

    // calculate the user's total bid
    uint totalBid = auction.fundsByBidder(msg.sender) + msg.value;

    if (auction.highestBid() == 0) {
      // reject if user did not overbid
      require(totalBid >= parameters.startingBid);
    } else {
      // reject if user did not overbid
      require(totalBid >= auction.highestBid() + parameters.bidStep);
    }

    auction.handlePayment{value:msg.value}();
    auction.placeBid(msg.sender, totalBid);

    // if bid was placed within specified number of blocks before the auction's end
    // extend auction time
    if (parameters.overtimeBlocksSize > parameters.endBlock - block.number) {
      auctionParameters[auctionAddress].endBlock += parameters.overtimeBlocksSize;
    }

    emit BidPlaced(msg.sender, totalBid);
  }

  function placeBidPRT(address auctionAddress, uint amount)
  external
  {
    PortionAuction auction = PortionAuction(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(block.number >= parameters.startBlock);
    require(block.number < parameters.endBlock);
    require(!auction.cancelled());
    require(auction.acceptPRT());
    require(msg.sender != auction.controller());
    require(msg.sender != auction.beneficiary());
    require(amount > 0);

    // calculate the user's total bid
    uint totalBid = auction.fundsByBidder(msg.sender) + amount;

    if (auction.highestBid() == 0) {
      // reject if user did not overbid
      require(totalBid >= parameters.startingBid);
    } else {
      // reject if user did not overbid
      require(totalBid >= auction.highestBid() + parameters.bidStep);
    }

    require(portionTokenContract.transferFrom(msg.sender, auctionAddress, amount));
    auction.placeBid(msg.sender, totalBid);

    // if bid was placed within specified number of blocks before the auction's end
    // extend auction time
    if (parameters.overtimeBlocksSize > parameters.endBlock - block.number) {
      auctionParameters[auctionAddress].endBlock += parameters.overtimeBlocksSize;
    }

    emit BidPlaced(msg.sender, totalBid);
  }

  function claimFunds(address auctionAddress)
  external
  {
    PortionAuction auction = PortionAuction(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(auction.cancelled() || block.number >= parameters.endBlock);

    address withdrawalAccount;
    uint withdrawalAmount;
    bool beneficiaryClaimedFunds;
    bool controllerClaimedFunds;

    if (auction.cancelled()) {
      // if the auction was cancelled, everyone should be allowed to withdraw their funds
      withdrawalAccount = msg.sender;
      withdrawalAmount = auction.fundsByBidder(withdrawalAccount);
    } else {
      // the auction finished without being cancelled

      // reject when auction winner claims funds
      require(msg.sender != auction.highestBidder());

      // everyone except auction winner should be allowed to withdraw their funds
      if (msg.sender == auction.beneficiary()) {
        require(parameters.feeRate < 100 && !auction.beneficiaryClaimedFunds());
        withdrawalAccount = auction.highestBidder();
        withdrawalAmount = auction.highestBid().mul(100 - parameters.feeRate).div(100);
        beneficiaryClaimedFunds = true;
      } else if (msg.sender == auction.controller()) {
        require(parameters.feeRate > 0 && !auction.controllerClaimedFunds());
        withdrawalAccount = auction.highestBidder();
        withdrawalAmount = auction.highestBid().mul(parameters.feeRate).div(100);
        controllerClaimedFunds = true;
      } else {
        withdrawalAccount = msg.sender;
        withdrawalAmount = auction.fundsByBidder(withdrawalAccount);
      }
    }

    // reject when there are no funds to claim
    require(withdrawalAmount != 0);

    auction.withdrawFunds(msg.sender, withdrawalAccount, withdrawalAmount, beneficiaryClaimedFunds, controllerClaimedFunds);

    emit FundsClaimed(msg.sender, withdrawalAccount, withdrawalAmount);
  }

  function claimItem(address auctionAddress)
  external
  {
    PortionAuction auction = PortionAuction(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(!auction.itemClaimed());
    require(auction.cancelled() || block.number >= parameters.endBlock);

    if (auction.cancelled()
      || (auction.highestBidder() == address(0) && block.number >= parameters.endBlock)) {
      require(msg.sender == auction.beneficiary());
    } else {
      require(msg.sender == auction.highestBidder());
    }

    auction.transferItem(msg.sender);

    emit ItemClaimed(msg.sender);
  }

  function cancelAuction(address auctionAddress)
  onlyOwner
  external
  {
    PortionAuction auction = PortionAuction(auctionAddress);
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(!auction.cancelled());
    require(block.number < parameters.endBlock);

    auction.cancelAuction();
    emit AuctionCancelled();
  }
}