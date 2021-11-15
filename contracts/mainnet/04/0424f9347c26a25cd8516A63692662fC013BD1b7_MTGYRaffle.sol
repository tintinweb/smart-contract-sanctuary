// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import './MTGYSpend.sol';

/**
 * @title MTGYRaffle
 * @dev This is the main contract that supports lotteries and raffles.
 */
contract MTGYRaffle is Ownable {
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

  IERC20 private _mtgy;
  MTGYSpend private _spend;

  uint256 public mtgyServiceCost = 5000 * 10**18;
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
  event DrawWinner(bytes32 indexed id, address winner);
  event CloseRaffle(bytes32 indexed id);

  constructor(address _mtgyAddress, address _mtgySpendAddress) {
    _mtgy = IERC20(_mtgyAddress);
    _spend = MTGYSpend(_mtgySpendAddress);
  }

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
  ) external {
    _validateDates(_start, _end);

    _mtgy.transferFrom(msg.sender, address(this), mtgyServiceCost);
    _mtgy.approve(address(_spend), mtgyServiceCost);
    _spend.spendOnProduct(mtgyServiceCost);

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
      _raffle.owner == msg.sender,
      'Must be the raffle owner to draw winner.'
    );
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
    emit DrawWinner(_id, _winner);
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

  function changeMtgyTokenAddy(address _tokenAddy) external onlyOwner {
    _mtgy = IERC20(_tokenAddy);
  }

  function changeSpendAddress(address _spendAddress) external onlyOwner {
    _spend = MTGYSpend(_spendAddress);
  }

  function changeMtgyServiceCost(uint256 _newCost) external onlyOwner {
    mtgyServiceCost = _newCost;
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

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/**
 * @title MTGYSpend
 * @dev Logic for spending $MTGY on products in the moontography ecosystem.
 */
contract MTGYSpend is Ownable {
  ERC20 private _mtgy;

  struct SpentInfo {
    uint256 timestamp;
    uint256 tokens;
  }

  address public constant burnWallet =
    0x000000000000000000000000000000000000dEaD;
  address public devWallet = 0x3A3ffF4dcFCB7a36dADc40521e575380485FA5B8;
  address public rewardsWallet = 0x87644cB97C1e2Cc676f278C88D0c4d56aC17e838;
  address public mtgyTokenAddy;

  SpentInfo[] public spentTimestamps;
  uint256 public totalSpent = 0;

  event Spend(address indexed owner, uint256 value);

  constructor(address _mtgyTokenAddy) {
    mtgyTokenAddy = _mtgyTokenAddy;
    _mtgy = ERC20(_mtgyTokenAddy);
  }

  function changeMtgyTokenAddy(address _mtgyAddy) external onlyOwner {
    mtgyTokenAddy = _mtgyAddy;
    _mtgy = ERC20(_mtgyAddy);
  }

  function changeDevWallet(address _newDevWallet) external onlyOwner {
    devWallet = _newDevWallet;
  }

  function changeRewardsWallet(address _newRewardsWallet) external onlyOwner {
    rewardsWallet = _newRewardsWallet;
  }

  function getSpentByTimestamp() external view returns (SpentInfo[] memory) {
    return spentTimestamps;
  }

  /**
   * spendOnProduct: used by a moontography product for a user to spend their tokens on usage of a product
   *   25% goes to dev wallet
   *   25% goes to rewards wallet for rewards
   *   50% burned
   */
  function spendOnProduct(uint256 _productCostTokens) external returns (bool) {
    totalSpent += _productCostTokens;
    spentTimestamps.push(
      SpentInfo({ timestamp: block.timestamp, tokens: _productCostTokens })
    );
    uint256 _half = _productCostTokens / uint256(2);
    uint256 _quarter = _half / uint256(2);

    // 50% burn
    _mtgy.transferFrom(msg.sender, burnWallet, _half);
    // 25% rewards wallet
    _mtgy.transferFrom(msg.sender, rewardsWallet, _quarter);
    // 25% dev wallet
    _mtgy.transferFrom(
      msg.sender,
      devWallet,
      _productCostTokens - _half - _quarter
    );
    emit Spend(msg.sender, _productCostTokens);
    return true;
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

