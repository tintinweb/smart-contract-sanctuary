// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {Sunsetable} from "./Sunsetable.sol";
import {Constants} from "./Constants.sol";

contract Metalend is IERC721Receiver, Ownable, Pausable, Sunsetable {
  /** -----------------------------------------------------------------------------
   *   State variable definitions
   *   -----------------------------------------------------------------------------
   */
  // struct object that represents a single instance of a loan:
  struct LoanItem {
    // Storage packing - try and use the smallest number of slots!
    // (One slot is 32 bytes, or 256 bits, and you have to declare
    // these in order for the EVM to pack them together. . .)
    // Addresses are 20 bytes.
    // Slot 1, 256:
    uint128 loanId;
    uint128 currentBalance;
    // Slot 2, 248:
    bool isCurrent;
    address payable borrower;
    uint32 startDate;
    uint32 endDate;
    uint16 tokenId;
  }

  // Slot 1 192 (160 + 16 + 16)
  // This designates the eligible NFT address, i.e. the address from which NFTs can
  // receive loans in exchange for custodied collateral (the NFT itself):
  // Contract implementation of ERC721
  IERC721 public tokenContract;
  // Term in days:
  uint16 public termInDays;
  // How close to the end date do we need to be to extend in days?
  uint16 public extensionHorizon;

  // Slot 2 256 (128 + 64 + 64)
  // In this version the loan amount is a fixed amount:
  uint128 public loanAmount;
  // Each loan attracts a lending fee. The amount the borrower has to repay to redeem the
  // NFT is the loan amount plus the lending fee:
  uint64 public lendingFee;
  // A fee to extend the loan by another loan term:
  uint64 public extensionFee;

  // Slot 3 - 160 (160)
  // Reposession address - this is the address that NFTs will be send to on the expiry
  // of the loan term.
  address public repoAddress;

  // The array of items under loan:
  LoanItem[] public itemsUnderLoan;

  /** -----------------------------------------------------------------------------
   *   Contract event definitions
   *   -----------------------------------------------------------------------------
   */
  // Events are broadcast and can be watched and tracked on chain:
  event lendingTransaction(
    uint128 indexed loanId,
    uint256 indexed transactionCode,
    address indexed borrower,
    uint16 tokenId,
    uint256 transactionValue,
    uint256 transactionFee,
    uint256 loanEndDate,
    uint256 effectiveDate
  );
  event eligibleNFTAddressSet(address indexed nftAddress);
  event repoAddressSet(address indexed repoAddress);
  event loanAmountSet(uint128 indexed loanAmount);
  event lendingFeeSet(uint64 indexed lendingFee);
  event extensionFeeSet(uint64 indexed extensionFee);
  event termInDaysSet(uint16 indexed termInDays);
  event extensionHorizonSet(uint16 indexed extensionHorizon);
  event ethWithdrawn(uint256 indexed withdrawal, uint256 effectiveDate);
  event ethDeposited(uint256 indexed deposit, uint256 effectiveDate);

  constructor(
    address _tokenAddress,
    uint128 _loanAmount,
    uint16 _termInDays,
    address _repoAddress,
    uint64 _lendingFee,
    uint64 _extensionFee,
    uint16 _extensionHorizon
  ) {
    tokenContract = IERC721(_tokenAddress);
    loanAmount = _loanAmount;
    termInDays = _termInDays;
    repoAddress = _repoAddress;
    lendingFee = _lendingFee;
    extensionFee = _extensionFee;
    extensionHorizon = _extensionHorizon;
    pause();
  }

  /** -----------------------------------------------------------------------------
   *   Modifier definitions
   *   -----------------------------------------------------------------------------
   */

  // Check to see if the array item has the borrower as the calling address:
  modifier OnlyItemBorrower(uint128 _loanId) {
    require(
      itemsUnderLoan[_loanId].borrower == msg.sender,
      "Payments can only be made by the borrower"
    );
    _;
  }

  // Check to see if the array item returned is no longer current:
  modifier IsUnderLoan(uint128 _loanId) {
    require(
      itemsUnderLoan[_loanId].isCurrent == true,
      "Item is not currently under loan"
    );
    _;
  }

  // Check to see if loan can be extended:
  modifier LoanEligibleForExtension(uint128 _loanId) {
    require(
      extensionsAllowed() == true,
      "Extensions currently not allowed"
    );
    require(
      isWithinExtensionHorizon(_loanId) == true,
      "Loan is not within extension horizon"
    );
    _;
  }

  // Check to see if loan is within term:
  modifier LoanWithinLoanTerm(uint128 _loanId) {
    require(
      isWithinLoanTerm(_loanId) == true,
      "Loan term has expired");
    _;
  }

  /** -----------------------------------------------------------------------------
   *   Set routines - these routines allow the owner to set parameters on this contract:
   *   -----------------------------------------------------------------------------
   */

  // Set the address that assets are transfered to on repossession:
  function setRepoAddress(address _repoAddress)
    external
    onlyOwner
    returns (bool)
  {
    repoAddress = _repoAddress;
    emit repoAddressSet(_repoAddress);
    return true;
  }

  // Set the loan amount:
  function setLoanAmount(uint128 _loanAmount)
    external
    onlyOwner
    returns (bool)
  {
    require(_loanAmount != loanAmount, "No change to loan amount");
    if (_loanAmount > loanAmount) {
        require(
            (_loanAmount - loanAmount) <=
                Constants.LOAN_AMOUNT_MAX_INCREMENT,
            "Change exceeds max increment"
        );
    } else {
        require(
            (loanAmount - _loanAmount) <=
                Constants.LOAN_AMOUNT_MAX_INCREMENT,
            "Change exceeds max increment"
        );
    }
    loanAmount = _loanAmount;
    emit loanAmountSet(_loanAmount);
    return true;
  }

  // Set the lending fee:
  function setLendingFee(uint64 _lendingFee) external onlyOwner returns (bool) {
    require(_lendingFee != lendingFee, "No change to lending fee");
    if (_lendingFee > lendingFee) {
      require(
        (_lendingFee - lendingFee) <= Constants.FEE_MAX_INCREMENT,
        "Change exceeds max increment"
      );
      } else {
        require(
          (lendingFee - _lendingFee) <= Constants.FEE_MAX_INCREMENT,
          "Change exceeds max increment"
          );
      }
    lendingFee = _lendingFee;
    emit lendingFeeSet(_lendingFee);
    return true;
  }

  // Set the extension fee:
  function setExtensionFee(uint64 _extensionFee)
    external
    onlyOwner
    returns (bool)
  {
    require(_extensionFee != extensionFee, "No change to extension fee");
    if (_extensionFee > extensionFee) {
        require(
            (_extensionFee - extensionFee) <= Constants.FEE_MAX_INCREMENT,
            "Change exceeds max increment"
        );
    } else {
        require(
            (extensionFee - _extensionFee) <= Constants.FEE_MAX_INCREMENT,
            "Change exceeds max increment"
        );
    }
    extensionFee = _extensionFee;
    emit extensionFeeSet(_extensionFee);
    return true;
  }

  // Set the term in days:
  function setTermInDays(uint16 _termInDays) external onlyOwner returns (bool) {
    require(_termInDays != termInDays, "No change to term");
    require(
      _termInDays <= Constants.LOAN_TERM_MAX,
      "Change is more than max term"
    );
    require(
      _termInDays >= Constants.LOAN_TERM_MIN,
      "Change is less than min term"
    );
    require(
      _termInDays >= extensionHorizon,
      "Term must be greater than or equal to extension horizon"
    );
    termInDays = _termInDays;
    emit termInDaysSet(_termInDays);
    return true;
  }

  // Set extension horizon in days:
  function setExtensionHorizon(uint16 _extensionHorizon)
    external
    onlyOwner
    returns (bool)
  {
    require(_extensionHorizon != extensionHorizon, "No change to horizon");
    require(
      _extensionHorizon <= Constants.LOAN_TERM_MAX,
      "Change is more than max term"
    );
    require(
      _extensionHorizon >= Constants.LOAN_TERM_MIN,
      "Change is less than min term"
    );
    require(
      _extensionHorizon <= termInDays,
      "Extension horizon must be less than or equal to term"
    );
    extensionHorizon = _extensionHorizon;
    emit extensionHorizonSet(_extensionHorizon);
    return true;
  }

  /** -----------------------------------------------------------------------------
   *   Contract routines - these do all the work:
   *   -----------------------------------------------------------------------------
   */
  //Always returns `IERC721Receiver.onERC721Received.selector`. We need this to custody NFTs on the contract:
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  // Allow contract to receive ETH:
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract.");
    require(msg.value > 0, "No ether was sent.");
    emit ethDeposited(msg.value, block.timestamp);
  }

  // The fallback function is executed on a call to the contract if
  // none of the other functions match the given function signature.
  fallback() external payable {
    revert();
  }

  function getParameters()
    external
    view
    returns (
      address _tokenAddress,
      uint32 _loanTerm,
      uint128 _loanAmount,
      uint128 _loanFee,
      uint64 _extensionHorizon,
      uint128 _extensionFee,
      bool _isPaused,
      bool _isSunset
    )
  {
    return (
      address(tokenContract),
      termInDays,
      loanAmount,
      lendingFee,
      extensionHorizon,
      extensionFee,
      paused(),
      sunsetModeActive()
    );
  }

  function getLoans() external view returns (LoanItem[] memory) {
    return itemsUnderLoan;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function sunset() external onlyOwner {
    _sunset();
  }

  function sunrise() external onlyOwner {
    _sunrise();
  }

  function extensionsAllowed() public view returns (bool) {
    return (extensionFee > 0);
  }

  function isWithinExtensionHorizon(uint128 _loanId) public view returns (bool) {
    return
      (block.timestamp +
      (extensionHorizon * Constants.SECONDS_TO_DAYS_FACTOR) >=
      itemsUnderLoan[_loanId].endDate);
  }

  function isWithinLoanTerm(uint128 _loanId) public view returns (bool) {
    return (block.timestamp <= itemsUnderLoan[_loanId].endDate);
  }

  // Ensure that the owner can withdraw deposited ETH:
  function withdraw(uint256 _withdrawal) external onlyOwner returns (bool) {
    (bool success, ) = msg.sender.call{value: _withdrawal}("");
    require(success, "Transfer failed.");
    emit ethWithdrawn(_withdrawal, block.timestamp);
    return true;
  }

  // This function is called to advance the borrower ETH in exchange for taking
  // custody of the asset.
  function takeLoan(uint16 tokenId) external whenNotPaused whenSun {
    // The id is the length of the current array as this is the next item:
    uint256 newItemId = itemsUnderLoan.length;
    uint32 endDate = uint32(block.timestamp) +
      (termInDays * Constants.SECONDS_TO_DAYS_FACTOR);
    // Add this to the array:
    itemsUnderLoan.push(
      LoanItem(
        uint128(newItemId),
        loanAmount + lendingFee,
        true,
        payable(msg.sender),
        uint32(block.timestamp),
        endDate,
        tokenId
      )
    );
    // Custody the asset to this contract:
    tokenContract.safeTransferFrom(msg.sender, address(this), tokenId);
    // Send the borrower their ETH:
    payable(msg.sender).transfer(loanAmount);
    emit lendingTransaction(
      uint128(newItemId),
      Constants.TXNCODE_LOAN_ADVANCED,
      msg.sender,
      tokenId,
      loanAmount,
      lendingFee,
      endDate,
      block.timestamp
    );
  }

  // This function is called when the borrower makes a payment. If the payment
  // clears the balance of the loan this routine will also return the NFT to the
  // borrower:
  function makeLoanPayment(uint128 _loanId)
    external
    payable
    IsUnderLoan(_loanId)
    OnlyItemBorrower(_loanId)
    LoanWithinLoanTerm(_loanId)
    whenNotPaused
  {
    require(
      msg.value <= itemsUnderLoan[_loanId].currentBalance,
      "Payment exceeds current balance"
    );
    // Reduce the balance outstanding by the amount of ETH received:
    itemsUnderLoan[_loanId].currentBalance -= uint128(msg.value);

    // See if this payment means the loan is done and we can return the asset:
    if (itemsUnderLoan[_loanId].currentBalance == 0) {
      _closeLoan(_loanId, msg.sender);

      emit lendingTransaction(
        _loanId,
        Constants.TXNCODE_ASSET_REDEEMED,
        msg.sender,
        itemsUnderLoan[_loanId].tokenId,
        msg.value,
        0,
        itemsUnderLoan[_loanId].endDate,
        block.timestamp
      );
    } else {
      // Emit this payment event:
      emit lendingTransaction(
        _loanId,
        Constants.TXNCODE_LOAN_PAYMENT_MADE,
        msg.sender,
        itemsUnderLoan[_loanId].tokenId,
        msg.value,
        0,
        itemsUnderLoan[_loanId].endDate,
        block.timestamp
      );
    }
  }

  // This function is called when the borrower extends a loan. The loan can be extended
  // by the original term in days for payment of the extension fee (if allowed):
  function extendLoan(uint128 _loanId)
    external
    payable
    IsUnderLoan(_loanId)
    OnlyItemBorrower(_loanId)
    LoanWithinLoanTerm(_loanId)
    LoanEligibleForExtension(_loanId)
    whenNotPaused
    whenSun
  {
    require(msg.value == extensionFee, "Payment must equal the extension fee");
    // Extend the term, that's all we need to do
    itemsUnderLoan[_loanId].endDate += (termInDays *
      Constants.SECONDS_TO_DAYS_FACTOR);
    // Emit the extension events:
    emit lendingTransaction(
      _loanId,
      Constants.TXNCODE_ASSET_EXTENDED,
      msg.sender,
      itemsUnderLoan[_loanId].tokenId,
      msg.value,
      msg.value,
      itemsUnderLoan[_loanId].endDate,
      block.timestamp
    );
  }

  // This function is called when an item is repossessed. This is ONLY possible when the
  // loan has lapsed.
  function repossessItem(uint128 _loanId) public IsUnderLoan(_loanId) {
    require(
      itemsUnderLoan[_loanId].endDate < block.timestamp,
      "Loan term has not yet elapsed"
    );

    _closeLoan(_loanId, repoAddress);

    emit lendingTransaction(
      _loanId,
      Constants.TXNCODE_ASSET_REPOSSESSED,
      itemsUnderLoan[_loanId].borrower,
      itemsUnderLoan[_loanId].tokenId,
      itemsUnderLoan[_loanId].currentBalance,
      0,
      itemsUnderLoan[_loanId].endDate,
      block.timestamp
    );
  }

  // Repossess eligible items in batches:
  function repossessItems(uint128[] calldata repoItems) external {
    for (uint256 i = 0; i < repoItems.length; i++) {
      repossessItem(repoItems[i]);
    }
  }

  // Handle loan closure and asset transfer:
  function _closeLoan(uint128 _closeLoanId, address _tokenTransferTo) internal {
    itemsUnderLoan[_closeLoanId].isCurrent = false;
    tokenContract.safeTransferFrom(
      address(this),
      _tokenTransferTo,
      itemsUnderLoan[_closeLoanId].tokenId
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an sunset
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenSun` and `whenMoon`, which can be applied to
 * the functions of your contract. Note that they will not be useable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Sunsetable is Context {
    /**
     * @dev Emitted when the sunset is triggered by `account`.
     */
    event Sunset(address account);

    /**
     * @dev Emitted when the sunrise is triggered by `account`.
     */
    event Sunrise(address account);

    bool private _sunsetModeActive;

    /**
     * @dev Initializes the contract in sunrised state.
     */
    constructor() {
        _sunsetModeActive = false;
    }

    /**
     * @dev Returns true if the sun has set, and false otherwise.
     */
    function sunsetModeActive() public view virtual returns (bool) {
        return _sunsetModeActive;
    }

    /**
     * @dev Modifier to make a function callable only when the sun is up.
     *
     * Requirements:
     *
     * - The contract must not be in sunset mode.
     */
    modifier whenSun() {
        require(!sunsetModeActive(), "Sunset: Sun has set on this contract");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the sun has set.
     *
     * Requirements:
     *
     * - The contract must be in sunset mode.
     */
    modifier whenMoon() {
        require(sunsetModeActive(), "Sunset: Sun has not set on this contract");
        _;
    }

    /**
     * @dev Triggers sunset state.
     *
     * Requirements:
     *
     * - The contract must not be in sunset already.
     */
    function _sunset() internal virtual whenSun {
        _sunsetModeActive = true;
        emit Sunset(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be in sunset mode.
     */
    function _sunrise() internal virtual whenMoon {
        _sunsetModeActive = false;
        emit Sunrise(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library Constants {
    // Transaction events
    uint256 constant TXNCODE_LOAN_ADVANCED = 1000;
    uint256 constant TXNCODE_LOAN_PAYMENT_MADE = 2000;
    uint256 constant TXNCODE_ASSET_REDEEMED = 3000;
    uint256 constant TXNCODE_ASSET_EXTENDED = 4000;
    uint256 constant TXNCODE_ASSET_REPOSSESSED = 5000;
    uint32 constant SECONDS_TO_DAYS_FACTOR = 86400;
    uint128 constant LOAN_AMOUNT_MAX_INCREMENT = 300000000000000000;
    uint64 constant FEE_MAX_INCREMENT = 30000000000000000;
    uint16 constant LOAN_TERM_MAX = 180;
    uint16 constant LOAN_TERM_MIN = 14;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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