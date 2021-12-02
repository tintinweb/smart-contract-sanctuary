//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './IEgg.sol';
import './IAnts.sol';

interface ICryptoAnts {
  // Errors
  error NoEggs();
  error NotEnoughEther();
  error AntLayEggsDelay();
  // Domain events
  event EggsBought(address buyer, uint256 amount);
  event AntSold(uint256 antTokenId);
  event AntCreated(uint256 antTokenId);
  event LaidEggs(uint256 antTokenId, uint256 amount);
  event AntDied(uint256 antTokenId);
  // Updating parameters
  event EggPriceUpdated(uint256 newValue);
  event EggLayingMinUpdated(uint256 newValue);
  event EggLayingMaxUpdated(uint256 newValue);
  event EggLayingDelayUpdated(uint256 newValue);
  event EggLayingDeathRatioUpdated(uint256 newValue);

  // Domain
  function buyEggs(uint256 amount) external payable;

  function hatchEgg() external;

  function sellAnt(uint256 antTokenId, uint256 sellPrice) external;

  function layEggs(uint256 antTokenId) external;

  // Updating parameters
  function updateEggPrice(uint256 newValue) external;

  function updateEggLayingMin(uint256 newValue) external;

  function updateEggLayingMax(uint256 newValue) external;

  function updateEggLayingDelay(uint256 newValue) external;

  function updateEggLayingDeathRatio(uint256 newValue) external;
}

contract CryptoAnts is ICryptoAnts, ReentrancyGuard, Ownable {
  // EGG ERC0 token
  IEgg public immutable eggs;

  // ANT ERC721 Token
  IAnts public immutable ants;

  // EGG price
  uint256 public eggPrice = 0.01 ether;

  // Ants egg laying.
  uint256 public antLayEggsMin = 1; // Min. amount of eggs laid
  uint256 public antLayEggsMax = 15; // Max. amount of eggs laid
  uint256 public antLayEggsDelay = 10 minutes; // Egg layings cooldown per ant
  uint256 public antLayEggsDeathRatio = 13; // % ants dies when laying eggs

  // Maps ANT token IDs to egg laying timestamps
  mapping(uint256 => uint256) private _lastEggLaid;

  constructor(
    address _eggs,
    address _ants,
    address governance
  ) {
    eggs = IEgg(_eggs);
    ants = IAnts(_ants);
    transferOwnership(governance);
  }

  function buyEggs(uint256 amount) external payable override nonReentrant {
    uint256 eggsCallerCanBuy = msg.value / eggPrice;
    if (eggsCallerCanBuy < amount) {
      revert NotEnoughEther();
    }
    eggs.mint(msg.sender, amount);
    emit EggsBought(msg.sender, amount);
  }

  function hatchEgg() external override {
    if (eggs.balanceOf(msg.sender) < 1) {
      revert NoEggs();
    }
    uint256 antTokenId = ants.totalSupply();
    ants.mint(msg.sender, antTokenId);
    eggs.burn(msg.sender, 1);
    emit AntCreated(antTokenId);
  }

  function sellAnt(uint256 antTokenId, uint256 sellPrice) external override nonReentrant {
    require(ants.ownerOf(antTokenId) == msg.sender, 'Unauthorized');
    require(sellPrice < eggPrice, 'Price higher than eggPrice');
    ants.burn(antTokenId);
    // solhint-disable-next-line
    (bool success, ) = msg.sender.call{value: sellPrice}('');
    require(success, 'Whoops, this call failed!');
    emit AntSold(antTokenId);
  }

  function layEggs(uint256 antTokenId) external override {
    require(ants.ownerOf(antTokenId) == msg.sender, 'Unauthorized');
    if (_antCantLayEggs(antTokenId)) {
      revert AntLayEggsDelay();
    }
    if (_antShouldDie()) {
      ants.burn(antTokenId);
      emit AntDied(antTokenId);
      return;
    }
    _lastEggLaid[antTokenId] = block.timestamp;
    uint256 eggAmount = _randomEggAmount();
    eggs.mint(msg.sender, eggAmount);
    emit LaidEggs(antTokenId, eggAmount);
  }

  // Setters
  function updateEggPrice(uint256 newValue) external override onlyOwner {
    if (newValue != eggPrice) {
      eggPrice = newValue;
    }
    emit EggPriceUpdated(newValue);
  }

  function updateEggLayingMin(uint256 newValue) external override onlyOwner {
    require(newValue < antLayEggsMax, 'Invalid value');
    if (newValue != antLayEggsMin) {
      antLayEggsMin = newValue;
    }
    emit EggLayingMinUpdated(newValue);
  }

  function updateEggLayingMax(uint256 newValue) external override onlyOwner {
    require(newValue > antLayEggsMin, 'Invalid value');
    if (newValue != antLayEggsMax) {
      antLayEggsMax = newValue;
    }
    emit EggLayingMaxUpdated(newValue);
  }

  function updateEggLayingDelay(uint256 newValue) external override onlyOwner {
    if (newValue != antLayEggsDelay) {
      antLayEggsDelay = newValue;
    }
    emit EggLayingDelayUpdated(newValue);
  }

  function updateEggLayingDeathRatio(uint256 newValue) external override onlyOwner {
    require(newValue >= 0 && newValue <= 100, 'Invalid value');
    if (newValue != antLayEggsDeathRatio) {
      antLayEggsDeathRatio = newValue;
    }
    emit EggLayingDeathRatioUpdated(newValue);
  }

  // Private
  function _randomEggAmount() private view returns (uint256) {
    return antLayEggsMin + (block.timestamp % (antLayEggsMax - antLayEggsMin));
  }

  function _antCantLayEggs(uint256 antTokenId) private view returns (bool) {
    return (block.timestamp - _lastEggLaid[antTokenId]) < antLayEggsDelay;
  }

  function _antShouldDie() private view returns (bool) {
    return (block.timestamp % 100) < antLayEggsDeathRatio;
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

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IEgg is IERC20 {
  function mint(address to, uint256 amount) external;
  function burn(address account, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IAnts is IERC721Enumerable {
  function mint(address to, uint256 tokenId) external;
  function burn(uint256 tokenId) external;
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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