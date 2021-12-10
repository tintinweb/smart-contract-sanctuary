// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import './OKLGProduct.sol';

/**
 * @title OKLGRaffle
 * @dev This is the main contract that supports lotteries and raffles.
 */
contract OKLGRaffle is OKLGProduct {
  struct Raffle {
    address owner;
    bool isNft; // rewardToken is either ERC20 or ERC721
    address rewardToken;
    uint256 rewardAmountOrTokenId;
    uint256 start; // timestamp (uint256) of start time (0 if start when raffle is created)
    uint256 end; // timestamp (uint256) of end time (0 if can be entered until owner draws)
    address entryToken; // ERC20 token requiring user to send to enter
    uint256 entryFee; // ERC20 num tokens user must send to enter, or 0 if no entry fee
    uint256 entryFeesCollected; // amount of fees collected by entries and paid to raffle/lottery owner
    uint256 maxEntriesPerAddress; // 0 means unlimited entries
    address[] entries;
    address winner;
    bool isComplete;
    bool isClosed;
  }

  uint8 public entryFeePercentageCharge = 2;

  mapping(bytes32 => Raffle) public raffles;
  bytes32[] public raffleIds;
  mapping(bytes32 => mapping(address => uint256)) public entriesIndexed;

  event CreateRaffle(address indexed creator, bytes32 id);
  event EnterRaffle(
    bytes32 indexed id,
    address raffler,
    uint256 numberOfEntries
  );
  event DrawWinner(bytes32 indexed id, address winner, uint256 amount);
  event CloseRaffle(bytes32 indexed id);

  constructor(address _tokenAddress, address _spendAddress)
    OKLGProduct(uint8(4), _tokenAddress, _spendAddress)
  {}

  function getAllRaffles() external view returns (bytes32[] memory) {
    return raffleIds;
  }

  function getRaffleEntries(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return raffles[_id].entries;
  }

  function createRaffle(
    address _rewardTokenAddress,
    uint256 _rewardAmountOrTokenId,
    bool _isNft,
    uint256 _start,
    uint256 _end,
    address _entryToken,
    uint256 _entryFee,
    uint256 _maxEntriesPerAddress
  ) external payable {
    _validateDates(_start, _end);
    _payForService();

    if (_isNft) {
      IERC721 _rewardToken = IERC721(_rewardTokenAddress);
      _rewardToken.transferFrom(
        msg.sender,
        address(this),
        _rewardAmountOrTokenId
      );
    } else {
      IERC20 _rewardToken = IERC20(_rewardTokenAddress);
      _rewardToken.transferFrom(
        msg.sender,
        address(this),
        _rewardAmountOrTokenId
      );
    }

    bytes32 _id = sha256(abi.encodePacked(msg.sender, block.number));
    address[] memory _entries;
    raffles[_id] = Raffle({
      owner: msg.sender,
      isNft: _isNft,
      rewardToken: _rewardTokenAddress,
      rewardAmountOrTokenId: _rewardAmountOrTokenId,
      start: _start,
      end: _end,
      entryToken: _entryToken,
      entryFee: _entryFee,
      entryFeesCollected: 0,
      maxEntriesPerAddress: _maxEntriesPerAddress,
      entries: _entries,
      winner: address(0),
      isComplete: false,
      isClosed: false
    });
    raffleIds.push(_id);
    emit CreateRaffle(msg.sender, _id);
  }

  function drawWinner(bytes32 _id) external {
    Raffle storage _raffle = raffles[_id];
    require(
      _raffle.end == 0 || block.timestamp > _raffle.end,
      'Raffle entry period is not over yet.'
    );
    require(
      !_raffle.isComplete,
      'Raffle has already been drawn and completed.'
    );

    if (_raffle.entryFeesCollected > 0) {
      IERC20 _entryToken = IERC20(_raffle.entryToken);
      uint256 _feesToSendOwner = _raffle.entryFeesCollected;
      if (entryFeePercentageCharge > 0) {
        uint256 _feeChargeAmount = (_feesToSendOwner *
          entryFeePercentageCharge) / 100;
        _entryToken.transfer(owner(), _feeChargeAmount);
        _feesToSendOwner -= _feeChargeAmount;
      }
      _entryToken.transfer(_raffle.owner, _feesToSendOwner);
    }

    uint256 _winnerIdx = _random(_raffle.entries.length) %
      _raffle.entries.length;
    address _winner = _raffle.entries[_winnerIdx];
    _raffle.winner = _winner;

    if (_raffle.isNft) {
      IERC721 _rewardToken = IERC721(_raffle.rewardToken);
      _rewardToken.transferFrom(
        address(this),
        _winner,
        _raffle.rewardAmountOrTokenId
      );
    } else {
      IERC20 _rewardToken = IERC20(_raffle.rewardToken);
      _rewardToken.transfer(_winner, _raffle.rewardAmountOrTokenId);
    }

    _raffle.isComplete = true;
    emit DrawWinner(_id, _winner, _raffle.rewardAmountOrTokenId);
  }

  function closeRaffleAndRefund(bytes32 _id) external {
    Raffle storage _raffle = raffles[_id];
    require(
      _raffle.owner == msg.sender,
      'Must be the raffle owner to draw winner.'
    );
    require(
      !_raffle.isComplete,
      'Raffle cannot be closed if it is completed already.'
    );

    IERC20 _entryToken = IERC20(_raffle.entryToken);
    for (uint256 _i = 0; _i < _raffle.entries.length; _i++) {
      address _user = _raffle.entries[_i];
      _entryToken.transfer(_user, _raffle.entryFee);
    }

    if (_raffle.isNft) {
      IERC721 _rewardToken = IERC721(_raffle.rewardToken);
      _rewardToken.transferFrom(
        address(this),
        msg.sender,
        _raffle.rewardAmountOrTokenId
      );
    } else {
      IERC20 _rewardToken = IERC20(_raffle.rewardToken);
      _rewardToken.transfer(msg.sender, _raffle.rewardAmountOrTokenId);
    }

    _raffle.isComplete = true;
    _raffle.isClosed = true;
    emit CloseRaffle(_id);
  }

  function enterRaffle(bytes32 _id, uint256 _numEntries) external {
    Raffle storage _raffle = raffles[_id];
    require(_raffle.owner != address(0), 'We do not recognize this raffle.');
    require(
      _raffle.start <= block.timestamp,
      'It must be after the start time to enter the raffle.'
    );
    require(
      _raffle.end == 0 || _raffle.end >= block.timestamp,
      'It must be before the end time to enter the raffle.'
    );
    require(
      _numEntries > 0 &&
        (_raffle.maxEntriesPerAddress == 0 ||
          entriesIndexed[_id][msg.sender] + _numEntries <=
          _raffle.maxEntriesPerAddress),
      'You have entered the maximum number of times you are allowed.'
    );
    require(!_raffle.isComplete, 'Raffle cannot be complete to be entered.');

    if (_raffle.entryFee > 0) {
      IERC20 _entryToken = IERC20(_raffle.entryToken);
      _entryToken.transferFrom(
        msg.sender,
        address(this),
        _raffle.entryFee * _numEntries
      );
      _raffle.entryFeesCollected += _raffle.entryFee * _numEntries;
    }

    for (uint256 _i = 0; _i < _numEntries; _i++) {
      _raffle.entries.push(msg.sender);
    }
    entriesIndexed[_id][msg.sender] += _numEntries;
    emit EnterRaffle(_id, msg.sender, _numEntries);
  }

  function changeRaffleOwner(bytes32 _id, address _newOwner) external {
    Raffle storage _raffle = raffles[_id];
    require(
      _raffle.owner == msg.sender,
      'Must be the raffle owner to change owner.'
    );
    require(
      !_raffle.isComplete,
      'Raffle has already been drawn and completed.'
    );

    _raffle.owner = _newOwner;
  }

  function changeEndDate(bytes32 _id, uint256 _newEnd) external {
    Raffle storage _raffle = raffles[_id];
    require(
      _raffle.owner == msg.sender,
      'Must be the raffle owner to change owner.'
    );
    require(
      !_raffle.isComplete,
      'Raffle has already been drawn and completed.'
    );

    _raffle.end = _newEnd;
  }

  function changeEntryFeePercentageCharge(uint8 _newPercentage)
    external
    onlyOwner
  {
    require(
      _newPercentage >= 0 && _newPercentage < 100,
      'Should be between 0 and 100.'
    );
    entryFeePercentageCharge = _newPercentage;
  }

  function _validateDates(uint256 _start, uint256 _end) private view {
    require(
      _start == 0 || _start >= block.timestamp,
      'start time should be 0 or after the current time'
    );
    require(
      _end == 0 || _end > block.timestamp,
      'end time should be 0 or after the current time'
    );
    if (_start > 0) {
      if (_end > 0) {
        require(_start < _end, 'start time must be before end time');
      }
    }
  }

  function _random(uint256 _entries) private view returns (uint256) {
    return
      uint256(
        keccak256(abi.encodePacked(block.difficulty, block.timestamp, _entries))
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './interfaces/IOKLGSpend.sol';
import './OKLGWithdrawable.sol';

/**
 * @title OKLGProduct
 * @dev Contract that every product developed in the OKLG ecosystem should implement
 */
contract OKLGProduct is OKLGWithdrawable {
  IERC20 private _token; // OKLG
  IOKLGSpend private _spend;

  uint8 public productID;

  constructor(
    uint8 _productID,
    address _tokenAddy,
    address _spendAddy
  ) {
    productID = _productID;
    _token = IERC20(_tokenAddy);
    _spend = IOKLGSpend(_spendAddy);
  }

  function setTokenAddy(address _tokenAddy) external onlyOwner {
    _token = IERC20(_tokenAddy);
  }

  function setSpendAddy(address _spendAddy) external onlyOwner {
    _spend = IOKLGSpend(_spendAddy);
  }

  function setProductID(uint8 _newId) external onlyOwner {
    productID = _newId;
  }

  function getTokenAddress() public view returns (address) {
    return address(_token);
  }

  function getSpendAddress() public view returns (address) {
    return address(_spend);
  }

  function _payForService() internal {
    _spend.spendOnProduct{ value: msg.value }(msg.sender, productID);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IOKLGSpend
 * @dev Logic for spending OKLG on products in the product ecosystem.
 */
interface IOKLGSpend {
  function spendOnProduct(address _payor, uint8 _product) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @title OKLGWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract OKLGWithdrawable is Ownable {
  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).send(address(this).balance);
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