/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/utils/Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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

// File: contracts/lib/Manageable.sol

pragma solidity ^0.6.2;




contract Manageable is Ownable, Pausable {
    mapping(address => bool) public _operators;

    modifier onlyOperator() {
        require(_operators[msg.sender], "!operator");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addOperator(address _operator) public onlyOwner {
        _operators[_operator] = true;
    }

    function removeOperator(address _operator) public onlyOwner {
        _operators[_operator] = false;
    }

    function fetchBalance(address _tokenAddress, address _receiverAddress) public onlyOwner {
        if (_receiverAddress == address(0)) {
            _receiverAddress = owner();
        }
        if (_tokenAddress == address(0)) {
            require(payable(_receiverAddress).send(address(this).balance));
            return;
        }
        IERC20 token = IERC20(_tokenAddress);
        uint256 _balance = token.balanceOf(address(this));
        token.transfer(_receiverAddress, _balance);
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/interfaces/INFT.sol

pragma solidity ^0.6.2;


interface INFT is IERC721 {

    function mint(address to, uint256 tokenId) external returns (bool);

    function burn(uint256 tokenId) external;

    function addBanToken(uint256 tokenId) external;
}

// File: contracts/interfaces/IPointStore.sol

pragma solidity ^0.6.2;

interface IPointStore {

    function increase(uint256 id, address account, uint256 amount) external;

    function decrease(uint256 id, address account, uint256 amount, string calldata reason) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/interfaces/IBUFactory.sol

pragma solidity ^0.6.2;


interface IBUFactory {

    function getSoldier(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 pob,
        uint256 hp,
        uint256 reg
    );

    function getIgniter(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 magic
    );

    function getDefier(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 extra1,
        uint256 extra2,
        uint256 extra3,
        uint256 extra4
    );

    function getGeneral(uint256 tokenId)
    external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256 extra1,
        uint256 extra2,
        uint256 extra3,
        uint256 extra4,
        uint256 extra5,
        uint256 extra6
    );

    function getBattleUnit(uint256 tokenId) external view
    returns (
        uint256 id,
        uint256 blockNum,
        uint256 ruleId,
        uint256 category,
        uint256 nftType,

        uint256 poc,
        uint256[] memory extras
    );

    function mint(address receiver, uint256 ruleId, uint256 category, uint256 nftType, uint256 level) external returns (uint256);

    function upgrade(uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

// File: contracts/interfaces/IBUFactoryV2.sol

pragma solidity ^0.6.2;



interface IBUFactoryV2 is IBUFactory {

    function increaseHP(uint256 tokenId, uint256 num) external;

    function decreaseHP(uint256 tokenId, uint256 num) external;
}

// File: contracts/SoviBazaarFactory.sol

pragma solidity ^0.6.2;









contract SoviBazaarFactory is Manageable, IERC721Receiver {
    using SafeMath for uint256;

    uint256 constant BU_SOLDIER = 1;
    uint256 constant BU_DEFIER = 2;
    uint256 constant BU_IGNITER = 3;
    uint256 constant BU_GENERAL = 4;
    uint256 constant POINT_TYPE_HONOR = 1;

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event SBURecycle(address indexed user, uint256 tokenId, uint256 points);
    event SBUUpgrade(address indexed user, uint256 tokenId1, uint256 tokenId2, uint256 newCardId);

    IERC20 public _sovi;
    INFT public _sbu;
    IPointStore public _pointStore;
    IBUFactory public _buFactory;
    IBUFactoryV2 public _buFactoryV2;

    uint256 public _upgradeFee;
    uint256 public _recycleFee;

    mapping(uint256 => mapping(uint256 => uint256)) public _upgradeMapping;
    mapping(uint256 => uint256) public _recycleMapping;

    constructor(
        address sovi_,
        address sbu_,
        address pointStore_,
        address buFactory_,
        address buFactoryV2_
    ) public {
        _sovi = IERC20(sovi_);
        _sbu = INFT(sbu_);
        _pointStore = IPointStore(pointStore_);
        _buFactory = IBUFactory(buFactory_);
        _buFactoryV2 = IBUFactoryV2(buFactoryV2_);
        forTest();
    }

    function forTest() internal {
        for (uint256 i = 0; i < 30; i ++) {
            _recycleMapping[i] = i;
            _upgradeMapping[i][i] = i;
        }
        _upgradeFee = 1e18;
    }

    // TODO: 英雄和士兵是否都能升级
    // TODO: 升级费用
    function upgrade(uint256 tokenId1, uint256 tokenId2) external {
        require(
            _pointStore.balanceOf(msg.sender, POINT_TYPE_HONOR) >= _upgradeFee,
            "Bazaar: Insufficient upgrade points"
        );

        uint256 category1;
        uint256 nftType1;
        uint256 category2;
        uint256 nftType2;
        (,,, category1, nftType1,,) = _buFactory.getBattleUnit(tokenId1);
        (,,, category2, nftType2,,) = _buFactory.getBattleUnit(tokenId2);
        require(nftType1 == nftType2, "Bazaar: token type error");

        uint256 newCardType = _upgradeMapping[nftType1][nftType2];
        if (newCardType == 0) {
            newCardType = _upgradeMapping[nftType2][nftType1];
        }
        require(newCardType > 0, "Bazaar: can't upgrade");

        _sbu.safeTransferFrom(msg.sender, address(this), tokenId1);
        _sbu.safeTransferFrom(msg.sender, address(this), tokenId2);

        _sbu.burn(tokenId1);
        _sbu.burn(tokenId2);

        _pointStore.decrease(POINT_TYPE_HONOR, msg.sender, _upgradeFee, "upgrade $SBU");
        uint256 newCardId = _buFactory.mint(msg.sender, 0, category1, newCardType, 1);
        emit SBUUpgrade(msg.sender, tokenId1, tokenId2, newCardId);
    }

    // TODO: 士兵回收细则
    function recycle(uint256[] calldata tokenIds) external {
        require(tokenIds.length > 0, "Bazaar: length=0");

        uint256 tokenId;

        uint256 totalPoints;
        uint256 points;
        for (uint256 i = 0; i < tokenIds.length; i ++) {
            tokenId = tokenIds[i];

            // transfer & destroy
            _sbu.safeTransferFrom(msg.sender, address(this), tokenId);
            _sbu.burn(tokenId);

            // sum(points)
            points = calcRecyclePoints(tokenId);
            totalPoints = totalPoints.add(points);

            emit SBURecycle(msg.sender, tokenId, points);
        }

        _pointStore.increase(POINT_TYPE_HONOR, msg.sender, totalPoints);
    }

    function checkRecyclePoints(uint256[] memory tokenIds) public view returns (uint256 points){
        for (uint256 i = 0; i < tokenIds.length; i++) {
            points = points.add(calcRecyclePoints(tokenIds[i]));
        }
    }

    function calcRecyclePoints(uint256 tokenId) internal view returns (uint256 points){
        uint256 category;
        uint256 nftType;
        uint256[] memory extras;
        (,,, category, nftType,,extras) = _buFactory.getBattleUnit(tokenId);
        points = _recycleMapping[nftType];

        if (category == BU_SOLDIER) {
            uint256[] memory extras2;
            (,,,,,, extras2) = _buFactoryV2.getBattleUnit(tokenId);
            uint256 percent = extras2[1].mul(100).div(extras[1]);
            points = points.mul(percent).div(100);
        }
    }

    function setPointStore(address newPointStore_) external onlyOwner {
        _pointStore = IPointStore(newPointStore_);
    }

    function setBUFactoryV2(address newFactoryV2_) external onlyOwner {
        _buFactoryV2 = IBUFactoryV2(newFactoryV2_);
    }

    function setFee(uint256 newUpgradeFee, uint256 newRecycleFee) external onlyOwner {
        _upgradeFee = newUpgradeFee;
        _recycleFee = newRecycleFee;
    }

    function addUpgradeMapping(uint256 nftType1, uint256 nftType2, uint256 newNftType) external onlyOwner {
        _upgradeMapping[nftType1][nftType2] = newNftType;
    }

    function removeUpgradeMapping(uint256 nftType1, uint256 nftType2) external onlyOwner {
        delete _upgradeMapping[nftType1][nftType2];
    }

    function addRecycleMapping(uint256 nftType, uint256 point) external onlyOwner {
        _recycleMapping[nftType] = point;
    }

    function removeRecycleMapping(uint256 nftType) external onlyOwner {
        delete _recycleMapping[nftType];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) override public returns (bytes4) {
        if (address(this) != operator) {
            return 0;
        }
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}