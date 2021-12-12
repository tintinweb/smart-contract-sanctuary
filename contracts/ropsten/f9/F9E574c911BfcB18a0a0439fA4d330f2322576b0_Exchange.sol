//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IEgg is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(address to, uint256 amount) external;
}

interface IAnt is IERC721 {
  function safeMint(address to) external returns (uint256);
  function burn(uint256 tokenId) external;
}

interface IVote is IERC20 {
  function mint(address to, uint256 amount) external;
}

contract Exchange {
  IEgg public immutable eggs;
  IAnt public immutable ants;
  IVote public immutable votes;

  address public governance;
  mapping(uint256 => uint256) public antHatchLastRun;
  uint256 public eggPrice = 0.01 ether;
  uint8 public maxEggsToHatch = 20;
  uint256 public antDieChance = 5;
  uint256 public minHatchIntervalTime = 10 minutes;

  event EggPriceChanged(uint256 newPrice);
  event EggsBought(address indexed buyer, uint256 amount);
  event EggsHatched(address indexed buyer, uint256 amount);
  event AntCreated(address indexed creator, uint256 id);
  event AntSold(address indexed seller, uint256 amount, uint256 price);
  event AntDied(uint256 id);

  constructor(
    address _eggs,
    address _ants,
    address _governance,
    address _votes
  ) {
    eggs = IEgg(_eggs);
    ants = IAnt(_ants);
    governance = _governance;
    votes = IVote(_votes);
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, 'Governance only!');
    _;
  }

  function changeEggPrice(uint256 _eggPrice) external onlyGovernance {
    eggPrice = _eggPrice;
    emit EggPriceChanged(eggPrice);
  }

  function buyEggs(uint256 _amount) external payable {
    require(msg.value >= (_amount * eggPrice), 'Value sent is not enough.');
    eggs.mint(msg.sender, _amount);
    emit EggsBought(msg.sender, eggs.balanceOf(msg.sender));
  }

  function createAnt() external returns (uint256 tokenId) {
    require(eggs.balanceOf(msg.sender) >= 1, 'You need to buy eggs first.');
    eggs.burn(msg.sender, 1);
    tokenId = ants.safeMint(msg.sender);
    require(tokenId >= 0, 'Could not mint Ant.');
    votes.mint(msg.sender, 1);
    emit AntCreated(msg.sender, tokenId);
  }

  function sellAnt(uint256 _antId, uint256 price) external {
    require(price < eggPrice, 'Price is too high.');
    ants.burn(_antId);
    payable(msg.sender).transfer(price);
    emit AntSold(msg.sender, 1, price);
  }

  function hatchEggs(uint256 antId) external minHatchInterval(antId) {
    require(ants.ownerOf(antId) == msg.sender, 'You are not the owner of this ant.');
    _mintHatchedEggs();
    if (_shouldDie()) {
      _killAnt(antId); /* The ant dies after hatching eggs */
    }
  }

  modifier minHatchInterval(uint256 antId) {
    require(block.timestamp - antHatchLastRun[antId] > minHatchIntervalTime, 'Should wait hatch interval.');
    antHatchLastRun[antId] = block.timestamp;
    _;
  }

  function _mintHatchedEggs() internal {
    uint8 eggsToHatch = uint8(_random() % uint256(maxEggsToHatch));
    eggs.mint(msg.sender, eggsToHatch);
    emit EggsHatched(msg.sender, eggsToHatch);
  }

  function _killAnt(uint256 antId) internal {
    ants.burn(antId);
    emit AntDied(antId);
  }

  function _shouldDie() internal view returns (bool) {
    return _random() % antDieChance == 0; /* e.g. 1/5 chance */
  }

  function _random() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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