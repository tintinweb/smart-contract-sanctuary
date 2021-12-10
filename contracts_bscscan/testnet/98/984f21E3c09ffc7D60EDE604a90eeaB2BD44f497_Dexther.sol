pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;


// SPDX-License-Identifier: MIT
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

 
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

 
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

 
contract Dexther {
  enum Status { Available, Swapped, Finalized, Canceled }

  struct Offer {
    address creator;
    uint256 estimateAmount;
    address estimateTokenAddress;
    address[] offerTokensAddresses;
    uint256[] offerTokensIds;
    uint256[] offerTokensValues;
    address[] expectedTokens;
    address restrictedTo;
    address swapper;
    uint256 swappedAt;
    address[] swapTokensAddresses;
    uint256[] swapTokensIds;
    uint256[] swapTokensValues;
    Status status;
  }

  Offer[] public offers;
  uint256 public choicePeriod = 60 * 60 * 24 * 10;

  address public owner;
  uint256 public currentFee;
  mapping (address => uint256) public availableFees;

  event Created(
    address indexed creator,
    uint256 indexed offerId,
    uint256 estimateAmount,
    address indexed estimateTokenAddress,
    address[] offerTokensAddresses,
    uint256[] offersTokensIds,
    uint256[] offerTokensValues,
    address[] expectedTokens,
    address restrictedTo
  );

  event Canceled(
    uint256 indexed offerId
  );

  event Swapped(
    address indexed swapper,
    uint256 indexed offerId
  );

  constructor(
    uint256 initialFee
  ) {
    currentFee = initialFee;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  function updateOwner(address newOwner) external onlyOwner() {
    owner = newOwner;
  }

  function updateFee(uint256 newCurrentFee) external onlyOwner() {
    require(newCurrentFee < 100, "Fee too high");
    currentFee = newCurrentFee;
  }

  function withdrawFees(
    address tokenAddress,
    uint256 amount
  ) external onlyOwner() {
    require(amount <= availableFees[tokenAddress], "Amount too high");

    availableFees[tokenAddress] = SafeMath.sub(
      availableFees[tokenAddress],
      amount
    );

    IERC20 token = IERC20(tokenAddress);
    token.transfer(msg.sender, amount);
  }

  function createOffer(
    uint256 estimateAmount,
    address estimateTokenAddress,
    address[] memory offerTokensAddresses,
    uint256[] memory offerTokensIds,
    uint256[] memory offerTokensValues,
    address[] memory expectedTokens,
    address restrictedTo
  ) external {
    require(offerTokensAddresses.length > 0, "No assets");
    require(offerTokensAddresses.length == offerTokensIds.length, "Tokens addresses or ids error");
    require(offerTokensAddresses.length == offerTokensValues.length, "Tokens addresses or values error");

    _transferAssets(
      msg.sender,
      address(this),
      offerTokensAddresses,
      offerTokensIds,
      offerTokensValues
    );

    offers.push(
      Offer(
        msg.sender,
        estimateAmount,
        estimateTokenAddress,
        offerTokensAddresses,
        offerTokensIds,
        offerTokensValues,
        expectedTokens,
        restrictedTo,
        address(0),
        0,
        new address[](0),
        new uint256[](0),
        new uint256[](0),
        Status.Available
      )
    );

    emit Created(
      msg.sender,
      offers.length - 1,
      estimateAmount,
      estimateTokenAddress,
      offerTokensAddresses,
      offerTokensIds,
      offerTokensValues,
      expectedTokens,
      restrictedTo
    );
  }

  function cancelOffer(
    uint256 offerId
  ) external {
    require(offers[offerId].creator == msg.sender, "Not creator");
    require(offers[offerId].status == Status.Available, "Already used");

    offers[offerId].status = Status.Canceled;

    emit Canceled(offerId);

    _transferAssets(
      address(this),
      msg.sender,
      offers[offerId].offerTokensAddresses,
      offers[offerId].offerTokensIds,
      offers[offerId].offerTokensValues
    );
  }

  function swap(
    uint256 offerId,
    address[] memory swapTokensAddresses,
    uint256[] memory swapTokensIds,
    uint256[] memory swapTokensValues
  ) external {
    require(offers[offerId].status == Status.Available, "Offer not available");

    if (offers[offerId].restrictedTo != address(0)) {
      require(offers[offerId].restrictedTo == msg.sender, "Not authorized");
    }

    if (offers[offerId].expectedTokens.length > 0) {
      for (uint256 i = 0; i < swapTokensAddresses.length; i += 1) {
        require(
          _includes(offers[offerId].expectedTokens, swapTokensAddresses[i]),
          "Swap token not expected"
        );
      }
    }

    IERC20 estimateToken = IERC20(offers[offerId].estimateTokenAddress);
    estimateToken.transferFrom(msg.sender, address(this), offers[offerId].estimateAmount);

    _transferAssets(
      msg.sender,
      address(this),
      swapTokensAddresses,
      swapTokensIds,
      swapTokensValues
    );

    _transferAssets(
      address(this),
      msg.sender,
      offers[offerId].offerTokensAddresses,
      offers[offerId].offerTokensIds,
      offers[offerId].offerTokensValues
    );

    offers[offerId].swapper = msg.sender;
    offers[offerId].swappedAt = block.timestamp;
    offers[offerId].status = Status.Swapped;
    offers[offerId].swapTokensAddresses = swapTokensAddresses;
    offers[offerId].swapTokensIds = swapTokensIds;
    offers[offerId].swapTokensValues = swapTokensValues;

    emit Swapped(
      msg.sender,
      offerId
    );
  }

  function finalize(
    uint256 offerId,
    bool claimingAssets
  ) external {
    require(msg.sender == offers[offerId].creator, "Not creator");
    require(offers[offerId].status == Status.Swapped, "Not swapped");

    address assetsReceiver = claimingAssets ? msg.sender : offers[offerId].swapper;
    address collateralReceiver = claimingAssets ? offers[offerId].swapper : msg.sender;

    _transferAssets(
      address(this),
      assetsReceiver,
      offers[offerId].swapTokensAddresses,
      offers[offerId].swapTokensIds,
      offers[offerId].swapTokensValues
    );

    IERC20 estimateToken = IERC20(offers[offerId].estimateTokenAddress);

    uint256 fee = SafeMath.mul(
      SafeMath.div(
        offers[offerId].estimateAmount,
        10000
      ),
      currentFee
    );

    availableFees[offers[offerId].estimateTokenAddress] = SafeMath.add(
      availableFees[offers[offerId].estimateTokenAddress],
      fee
    );

    uint256 estimateAmountMinusFee = SafeMath.sub(
      offers[offerId].estimateAmount,
      fee
    );

    estimateToken.transfer(collateralReceiver, estimateAmountMinusFee);
    offers[offerId].status = Status.Finalized;
  }

  function forceChoice(
    uint256 offerId,
    bool claimingAssets
  ) external {
    require(msg.sender == offers[offerId].swapper, "Not swapper");
    require(offers[offerId].status == Status.Swapped, "Not swapped");
    require(block.timestamp + choicePeriod >= offers[offerId].swappedAt, "Too soon");

    address assetsReceiver = claimingAssets ? offers[offerId].swapper : msg.sender;
    address collateralReceiver = claimingAssets ? msg.sender : offers[offerId].swapper;

    _transferAssets(
      address(this),
      assetsReceiver,
      offers[offerId].swapTokensAddresses,
      offers[offerId].swapTokensIds,
      offers[offerId].swapTokensValues
    );

    IERC20 estimateToken = IERC20(offers[offerId].estimateTokenAddress);

    uint256 fee = SafeMath.mul(
      SafeMath.div(
        offers[offerId].estimateAmount,
        10000
      ),
      currentFee
    );

    availableFees[offers[offerId].estimateTokenAddress] = SafeMath.add(
      availableFees[offers[offerId].estimateTokenAddress],
      fee
    );

    uint256 estimateAmountMinusFee = SafeMath.sub(
      offers[offerId].estimateAmount,
      fee
    );

    estimateToken.transfer(collateralReceiver, estimateAmountMinusFee);
    offers[offerId].status = Status.Finalized;
  }

  function getOffer(
    uint256 offerId
  ) external view returns (Offer memory) {
    return offers[offerId];
  }

  function _transferAssets(
    address from,
    address to,
    address[] memory tokensAddresses,
    uint256[] memory tokensIds,
    uint256[] memory tokensValues
  ) private {
    for (uint256 i = 0; i < tokensAddresses.length; i += 1) {
      IERC165 tokenWithoutInterface = IERC165(tokensAddresses[i]);

      try tokenWithoutInterface.supportsInterface(0xd9b67a26) returns (bool hasInterface) {
          if (hasInterface) {
              IERC1155 token = IERC1155(tokensAddresses[i]);
              bytes memory data;
              token.safeTransferFrom(from, to, tokensIds[i], tokensValues[i], data);
          } else {
              IERC721 token = IERC721(tokensAddresses[i]);
              try token.transferFrom(from, to, tokensIds[i]) {
                // Success
              } catch {
                // address(token).transfer(to, tokensIds[i]);
              }
          }
      } catch {
        IERC20 token = IERC20(tokensAddresses[i]);
        try token.transferFrom(from, to, tokensIds[i]) {
          //
        } catch {
          token.transfer(to, tokensIds[i]);
        }
      }
    }
  }

  function _includes(
    address[] memory source,
    address value
  ) private pure returns (bool) {
    bool isIncluded = false;

    for (uint256 i = 0; i < source.length; i += 1) {
      if (source[i] == value) {
        isIncluded = true;
      }
    }

    return isIncluded;
  }
}