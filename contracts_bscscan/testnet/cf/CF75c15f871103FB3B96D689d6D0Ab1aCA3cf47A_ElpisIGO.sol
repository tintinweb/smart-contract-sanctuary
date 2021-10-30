// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IElpisHero.sol";

contract ElpisIGO is Pausable, Ownable {
    using SafeMath for uint256;

    bytes4 private constant InterfaceSignature_ERC721 = 0x80ac58cd;
    //maximum number of tokens in transaction
    uint256 public maxTokensPerTransaction = 20;
    //the nft price
    uint256 public immutable nftPrice;
    //the amount of nft that has been paid
    uint256 public nftsPaid;
    //the amount of nft for pre-sale
    uint256 public nftsPreSale;
    //the amount of nft for public-sale
    uint256 public nftsPublicSale;
    //the elpis-hero addres
    IElpisHero public immutable elpisHero;
    //The block number when the presale was opened
    uint256 public immutable blockStartPreSale;
    //The block number when the store finish pre-sale
    uint256 public immutable blockFinishPreSale;
    //The block number when the store is open for public-sale
    uint256 public immutable blockStartPublicSale;
    //The block number when the store finish public-sale
    uint256 public immutable blockFinishPublicSale;
    //Whitelist of addresses that can be purchased in pre-sale
    mapping(address => uint256) public whiteListPreSale;
    //Whitelist of prepaid addresses
    mapping(address => uint256) public whiteListPaid;

    constructor(
        IElpisHero _elpisHero,
        uint256 _nftsPaid,
        uint256 _nftsPreSale,
        uint256 _nftsPublicSale,
        uint256 _nftPrice,
        uint256 _blockStartPreSale,
        uint256 _blockFinishPreSale,
        uint256 _blockStartPublicSale,
        uint256 _blockFinishPublicSale
    ) public {
        require(
            address(_elpisHero) != address(0),
            "constructor: elpisHero is the zero address"
        );
        require(
            _elpisHero.supportsInterface(InterfaceSignature_ERC721),
            "constructor: elpisHero does not support ERC-721"
        );
        require(_nftsPublicSale > 0, "constructor: nftsPublicSale is the zero");
        require(_nftPrice > 0, "constructor: nftsPublicSale is the zero");
        require(
            _blockStartPreSale >= block.number,
            "constructor: invalid pre-sale time"
        );
        require(
            _blockFinishPreSale > _blockStartPreSale,
            "constructor: invalid pre-sale time"
        );
        require(
            _blockStartPublicSale > _blockFinishPreSale,
            "constructor: invalid public sale time"
        );
        require(
            _blockFinishPublicSale > _blockStartPublicSale,
            "constructor: invalid public sale time"
        );

        elpisHero = _elpisHero;
        nftsPaid = _nftsPaid;
        nftsPreSale = _nftsPreSale;
        nftsPublicSale = _nftsPublicSale;
        nftPrice = _nftPrice;
        blockStartPreSale = _blockStartPreSale;
        blockFinishPreSale = _blockFinishPreSale;
        blockStartPublicSale = _blockStartPublicSale;
        blockFinishPublicSale = _blockFinishPublicSale;
    }

    modifier onlyBeforePreSale() {
        require(blockStartPreSale > block.number, "ElpisIGO: pre-sale has started");
        _;
    }

    modifier onlyPreSaleTimes() {
        require(
            block.number >= blockStartPreSale,
            "ElpisIGO: the pre sale is not open yet"
        );
        require(
            block.number <= blockFinishPreSale,
            "ElpisIGO: the pre sale period has ended"
        );
        _;
    }

    modifier onlyPublicSaleTimes() {
        require(
            block.number >= blockStartPublicSale,
            "ElpisIGO: the public sale is not open yet"
        );
        require(
            block.number <= blockFinishPublicSale,
            "ElpisIGO: the public sale period has ended"
        );
        _;
    }

    modifier validTransaction(uint256 amount) {
        require(amount > 0, "ElpisIGO: wrong amount");
        require(
            amount <= maxTokensPerTransaction,
            "ElpisIGO: max tokens per transaction amount exceeded"
        );
        _;
    }

    modifier onlyFullPayment(uint256 amount) {
        require(
            nftPrice.mul(amount) <= msg.value,
            "ElpisIGO: the ether value sent is not enough for payment"
        );
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateMaxTokensPerTransaction(uint256 _maxTokensPerTransaction)
        external
        onlyOwner
    {
        require(
            _maxTokensPerTransaction > 0,
            "updateMaxTokensPerTransaction: maxTokensPerTransaction is the zero"
        );
        maxTokensPerTransaction = _maxTokensPerTransaction;
    }

    function setWhiteListPreSale(
        address[] calldata _addressWhiteList,
        uint256[] calldata _allowances
    ) external onlyOwner onlyBeforePreSale {
        require(
            _addressWhiteList.length == _allowances.length,
            "setWhiteListPreSale: addressWhiteList and allowances length mismatch"
        );
        for (uint256 i = 0; i < _addressWhiteList.length; ++i) {
            whiteListPreSale[_addressWhiteList[i]] = _allowances[i];
        }
    }

    function setWhiteListPaid(
        address[] calldata _addressWhiteList,
        uint256[] calldata _allowances
    ) external onlyOwner onlyBeforePreSale{
        require(
            _addressWhiteList.length == _allowances.length,
            "setWhiteListPaid: addressWhiteList and allowances length mismatch"
        );
        for (uint256 i = 0; i < _addressWhiteList.length; ++i) {
            whiteListPaid[_addressWhiteList[i]] = _allowances[i];
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function claimHeroPreSale(uint256 amount)
        external
        whenNotPaused
        onlyPreSaleTimes
        validTransaction(amount)
    {
        require(
            whiteListPaid[address(msg.sender)] > 0,
            "claimHeroPreSale: caller is not whitelisted"
        );
        whiteListPaid[address(msg.sender)] = whiteListPaid[address(msg.sender)]
            .sub(
                amount,
                "claimHeroPreSale: the amount of purchase exceeds allowance"
            );
        transferHero(address(msg.sender), amount);
    }

    function buyHeroesPreSale(uint256 amount)
        external
        payable
        whenNotPaused
        onlyPreSaleTimes
        validTransaction(amount)
        onlyFullPayment(amount)
    {
        require(
            whiteListPreSale[address(msg.sender)] > 0,
            "buyHeroesPreSale: caller is not whitelisted"
        );
        nftsPreSale = nftsPreSale.sub(
            amount,
            "buyHeroesPreSale: amount of token to mint exceeds the amount of pre sale tokens"
        );
        whiteListPreSale[address(msg.sender)] = whiteListPreSale[
            address(msg.sender)
        ].sub(
                amount,
                "buyHeroesPreSale: the amount of purchase exceeds allowance"
            );
        transferHero(address(msg.sender), amount);
    }

    function buyHeroesPublicSale(uint256 amount)
        external
        payable
        whenNotPaused
        onlyPublicSaleTimes
        validTransaction(amount)
        onlyFullPayment(amount)
    {
        nftsPublicSale = nftsPublicSale.sub(
            amount,
            "buyHeroesPublicSale: amount of token to mint exceeds the amount of public tokens"
        );
        transferHero(address(msg.sender), amount);
    }

    // Claim heroes for prepaid adddresses. NECESSARY ONLY
    function necessaryClaim(address recipient)
        external
        whenNotPaused
        onlyPreSaleTimes
        onlyOwner
    {
        uint256 amount;
        uint256 allowance = whiteListPaid[recipient];
        require(allowance > 0, "necessaryClaim: recipient is not whitelisted");
        if (allowance > maxTokensPerTransaction) {
            amount = maxTokensPerTransaction;
        } else {
            amount = allowance;
        }
        whiteListPaid[recipient] = whiteListPaid[recipient].sub(amount);
        transferHero(recipient, amount);
    }

    function transferHero(address to, uint256 amount) internal {
        for (uint256 i = 0; i < amount; ++i) {
            elpisHero.mint(to);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IElpisHero is IERC721 {
    function mint(address to) external;

    function supportsInterface(bytes4 interfaceId)
        view
        override
        external
        returns (bool);
}