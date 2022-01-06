/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/access/Ownable.sol

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/PolyLocker.sol

pragma solidity 0.7.6;

// Requirements

// Any POLY holder can lock POLY (Issuers, Investors, WL, Polymath Founders, etc.)
// The amount of POLY to be locked must be >=1, otherwise, fail with insufficient funds
// There is no max limit on how much POLY can be locked
// POLY will be locked forever, no one can unlock it (ignore the upgradable contract bit)
// Granularity for locked POLY should be restricted to Polymesh granularity (10^6)
// User must provide their Mesh address when locking POLY
// Emit an event for locked POLY including Mesh address & timestamp
// Mesh address must be of valid length




/**
 * @title Contract used to lock POLY corresponds to locked amount user can claim same
 * amount of POLY on Polymesh blockchain
 */
contract PolyLocker is Ownable {
    using SafeMath for uint256;

    // Tracks the total no. of events emitted by the contract.
    uint256 public noOfeventsEmitted;

    // Address of the token that is locked by the contract. i.e. PolyToken contract address.
    IERC20 public immutable polyToken;

    // Controls if locking Poly is frozen.
    bool public frozen;

    // Granularity Polymesh blockchain in 10^6 but it's 10^18 on Ethereum.
    // This is used to truncate 18 decimal places to 6.
    uint256 constant public TRUNCATE_SCALE = 10 ** 12;

    // Valid address length of Polymesh blockchain.
    uint256 constant public VALID_ADDRESS_LENGTH = 48;

    uint256 constant internal E18 = uint256(10) ** 18;

    // Emit an event when the poly gets lock
    event PolyLocked(uint256 indexed _id, address indexed _holder, string _meshAddress, uint256 _polymeshBalance, uint256 _polyTokenBalance);
    // Emitted when locking is frozen
    event Frozen();
    // Emitted when locking is unfrozen
    event Unfrozen();


    constructor(address _polyToken) public {
        require(_polyToken != address(0), "Invalid address");
        polyToken = IERC20(_polyToken);
    }

    /**
     * @notice Used for freezing locking of POLY token
     */
    function freezeLocking() external onlyOwner {
        require(!frozen, "Already frozen");
        frozen = true;
        emit Frozen();
    }

    /**
     * @notice Used for unfreezing locking of POLY token
     */
    function unfreezeLocking() external onlyOwner {
        require(frozen, "Already unfrozen");
        frozen = false;
        emit Unfrozen();
    }

    /**
     * @notice used to set the nonce
     * @param _newNonce New nonce to set with the contract
     */
    function setEventsNonce(uint256 _newNonce) external onlyOwner {
        noOfeventsEmitted = _newNonce;
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     */
    function lock(string calldata _meshAddress) external {
        _lock(_meshAddress, msg.sender, polyToken.balanceOf(msg.sender));
    }

    /**
     * @notice Used for locking the POLY token
     * @param _meshAddress Address that compatible the Polymesh blockchain
     * @param _lockedValue Amount of tokens need to locked
     */
    function limitLock(string calldata _meshAddress, uint256 _lockedValue) external {
        _lock(_meshAddress, msg.sender, _lockedValue);
    }

    function _lock(string memory _meshAddress, address _holder, uint256 _polyAmount) internal {
        // Make sure locking is not frozen
        require(!frozen, "Locking frozen");
        // Validate the MESH address
        require(bytes(_meshAddress).length == VALID_ADDRESS_LENGTH, "Invalid length of mesh address");

        // Make sure the minimum `_polyAmount` is 1.
        require(_polyAmount >= E18, "Insufficient amount");

        // Polymesh balances have 6 decimal places.
        // 1 POLY on Ethereum has 18 decimal places. 1 POLYX on Polymesh has 6 decimal places.
        // i.e. 10^18 POLY = 10^6 POLYX.
        uint256 polymeshBalance = _polyAmount / TRUNCATE_SCALE;
        _polyAmount = polymeshBalance * TRUNCATE_SCALE;

        // Transfer funds to this contract.
        require(polyToken.transferFrom(_holder, address(this), _polyAmount), "Insufficient allowance");
        uint256 cachedNoOfeventsEmitted = noOfeventsEmitted + 1;  // Caching number of events in memory, saves 1 SLOAD.
        noOfeventsEmitted = cachedNoOfeventsEmitted;              // Increment the event counter in storage.

        // The event does not need to contain both `polymeshBalance` and `_polyAmount` as one can be derived from other.
        // However, we are still keeping them for easier integrations.
        emit PolyLocked(cachedNoOfeventsEmitted, _holder, _meshAddress, polymeshBalance, _polyAmount);
    }
}