/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-21
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/IERC20Detailed.sol



pragma solidity ^0.7.6;

interface IERC20Detailed is IERC20 {

    function decimals() external view returns (uint8);

}


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/math/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File @openzeppelin/contracts/cryptography/[email protected]



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File contracts/Whitelist.sol



pragma solidity ^0.7.6;


contract Whitelist is Ownable {
    using ECDSA for bytes32;

    bool public hasWhitelisting = false;
    address whitelistSigner;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant WHITELIST_TYPEHASH = keccak256("Whitelist(address account)");

    event WhitelistSignerChanged(address  oldSigner, address newSigner);

    modifier onlyWhitelisted(bytes calldata _signature) {
        if (hasWhitelisting) {
            isWhitelisted(_signature);
        }
        _;
    }

    constructor(bool _hasWhitelisting) {
        hasWhitelisting = _hasWhitelisting;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("ConvergenceO")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function setWhitelistSigner(
        address _whitelistSigner
    ) external onlyOwner {

        // Check params
        require(_whitelistSigner != address(0), "Whitelist: zero address");
        address oldSigner = whitelistSigner;
        whitelistSigner = _whitelistSigner;

        emit WhitelistSignerChanged(oldSigner, whitelistSigner);
    }

    function isWhitelisted(bytes calldata signature) internal view{
        require( whitelistSigner != address(0), "Whitelist: whitelist signer not set");
        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender)))
        );
        address recoveredAddress = digest.recover(signature);
        require(
            recoveredAddress != address(0) && recoveredAddress == whitelistSigner,
            "Must be in the whitelist"
        );
    }
}


// File contracts/libraries/TransferHelper.sol


pragma solidity ^0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/FixedSwap.sol



pragma solidity ^0.7.6;






contract FixedSwap is Pausable, Whitelist {
    using SafeMath for uint256;
    uint256 increment = 0;

    mapping(uint256 => Purchase) public purchases; /* Purchasers mapping */
    address[] public buyers; /* Current Buyers Addresses */
    uint256[] public purchaseIds; /* All purchaseIds */
    mapping(address => uint256[]) public myPurchases; /* Purchasers mapping */

    IERC20 public erc20;
    bool public isSaleFunded = false;
    uint public decimals = 0;
    bool public unsoldTokensRedeemed = false;
    uint256 public tradeValue; /* Price in Wei */
    uint256 public startDate; /* Start Date  */
    uint256 public endDate; /* End Date  */
    uint256 public individualMinimumAmount = 0; /* Minimum Amount Per Address */
    uint256 public individualMaximumAmount = 0; /* Maximum Amount Per Address */
    uint256 public minimumRaise = 0; /* Minimum Amount of Tokens that have to be sold */
    uint256 public tokensAllocated = 0; /* Tokens Available for Allocation - Dynamic */
    uint256 public tokensForSale = 0; /* Tokens Available for Sale */
    bool public isTokenSwapAtomic; /* Make token release atomic (at the same time of swap) or not */
    address payable public feeAddress; /* Default Address for Fee Percentage */
    uint256 public feePercentage = 1; /* Default Fee 1% */
    bool private locked;
    //  whether the IDO is purchase with platform token (e.g. ETH, GLMR, MOVR) or ERC20 token, default is true
    bool public isSwapWithPlatformToken = true;
    // address of the token to be used in swap is isSwapWithPlatformToken is false
    address public paymentToken;

    struct Purchase {
        uint256 amount;
        address purchaser;
        uint256 paymentAmount;
        uint256 timestamp;
        bool wasFinalized; /* Confirm the tokens were sent already */
        bool reverted; /* Confirm the tokens were sent already */
    }

    event PurchaseEvent(
        uint256 indexed purchaseId,
        uint256 amount,
        address indexed purchaser,
        uint256 paymentAmount,
        uint256 timestamp,
        bool wasFinalized
    );
    event FundEvent(address indexed funder, uint256 amount, address indexed contractAddress, uint256 timestamp);
    event RedeemTokenEvent(
        uint256 indexed purchaseId,
        uint256 amount,
        address indexed purchaser,
        uint256 paymentAmount,
        bool wasFinalized,
        bool reverted
    );

    constructor(
        address _tokenAddress,
        address payable _feeAddress,
        uint256 _tradeValue,
        uint256 _tokensForSale,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _individualMinimumAmount,
        uint256 _individualMaximumAmount,
        bool _isTokenSwapAtomic,
        uint256 _minimumRaise,
        uint256 _feeAmount,
        bool _hasWhitelisting,
        bool _isSwapWithPlatformToken,
        address _paymentToken
    ) Whitelist(_hasWhitelisting) {
        /* Confirmations */
        require(block.timestamp < _endDate, "End Date should be further than current date");
        require(block.timestamp < _startDate, "Start Date should be further than current date");
        require(_startDate < _endDate, "End Date higher than Start Date");
        require(_tokensForSale > 0, "Tokens for Sale should be > 0");
        require(_tokensForSale > _individualMinimumAmount, "Tokens for Sale should be > Individual Minimum Amount");
        require(_individualMaximumAmount >= _individualMinimumAmount, "Individual Maximum Amount should be > Individual Minimum Amount");
        require(_minimumRaise <= _tokensForSale, "Minimum Raise should be < Tokens For Sale");
        require(_feeAmount >= feePercentage, "Fee Percentage has to be >= 1");
        require(_feeAmount <= 99, "Fee Percentage has to be < 100");
        require(_feeAddress != address(0), "Fee Address has to be not ZERO");
        require(_tokenAddress != address(0), "Token Address has to be not ZERO");
        require(_paymentToken != address(0) || _isSwapWithPlatformToken, 
            "Trade token address has to be not ZERO if not swap with platform token");

        startDate = _startDate;
        endDate = _endDate;
        tokensForSale = _tokensForSale;
        tradeValue = _tradeValue;

        individualMinimumAmount = _individualMinimumAmount;
        individualMaximumAmount = _individualMaximumAmount;
        isTokenSwapAtomic = _isTokenSwapAtomic;
        isSwapWithPlatformToken = _isSwapWithPlatformToken;

        if (!_isSwapWithPlatformToken){
            paymentToken = _paymentToken;
        }

        decimals = IERC20Detailed(_tokenAddress).decimals();

        if (!_isTokenSwapAtomic) {
            /* If raise is not atomic swap */
            minimumRaise = _minimumRaise;
        }

        erc20 = IERC20(_tokenAddress);
        feePercentage = _feeAmount;
        feeAddress = _feeAddress;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isNotAtomicSwap() {
        require(!isTokenSwapAtomic, "Has to be non Atomic swap");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isSaleFinalized() {
        require(hasFinalized(), "Has to be finalized");
        _;
    }

    /**
     * Modifier to make a function callable only when the swap time is open.
     */
    modifier isSaleOpen() {
        require(isOpen(), "Has to be open");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isSalePreStarted() {
        require(isPreStart(), "Has to be pre-started");
        _;
    }

    /**
     * Modifier to make a function callable only when the contract has Atomic Swaps not available.
     */
    modifier isFunded() {
        require(isSaleFunded, "Has to be funded");
        _;
    }

    /**
     * Modifier for block reentrancy
     */
    modifier blockReentrancy {
        require(!locked, "Reentrancy is blocked");
        locked = true;
        _;
        locked = false;
    } 

    /* Get Functions */
    function isBuyer(uint256 purchase_id) public view returns (bool) {
        return (msg.sender == purchases[purchase_id].purchaser);
    }

    /* Get Functions */
    function totalRaiseCost() public view returns (uint256) {
        return (cost(tokensForSale));
    }

    function availableTokens() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function tokensLeft() public view returns (uint256) {
        return tokensForSale - tokensAllocated;
    }

    function hasMinimumRaise() public view returns (bool) {
        return (minimumRaise != 0);
    }

    /* Verify if minimum raise was not achieved */
    function minimumRaiseNotAchieved() public view returns (bool) {
        require(cost(tokensAllocated) < cost(minimumRaise), "TotalRaise is bigger than minimum raise amount");
        return true;
    }

    /* Verify if minimum raise was achieved */
    function minimumRaiseAchieved() public view returns (bool) {
        if (hasMinimumRaise()) {
            require(cost(tokensAllocated) >= cost(minimumRaise), "TotalRaise is less than minimum raise amount");
        }
        return true;
    }

    function hasFinalized() public view returns (bool) {
        return block.timestamp > endDate;
    }

    function hasStarted() public view returns (bool) {
        return block.timestamp >= startDate;
    }

    function isPreStart() public view returns (bool) {
        return block.timestamp < startDate;
    }

    function isOpen() public view returns (bool) {
        return hasStarted() && !hasFinalized();
    }

    function hasMinimumAmount() public view returns (bool) {
        return (individualMinimumAmount != 0);
    }

    function cost(uint256 _amount) public view returns (uint256) {
        return _amount.mul(tradeValue).div(10**decimals);
    }

    function getPurchase(uint256 _purchase_id)
        external
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        Purchase memory purchase = purchases[_purchase_id];
        return (purchase.amount, purchase.purchaser, purchase.paymentAmount, purchase.timestamp, purchase.wasFinalized, purchase.reverted);
    }

    function getPurchaseIds() public view returns (uint256[] memory) {
        return purchaseIds;
    }

    function getBuyers() public view returns (address[] memory) {
        return buyers;
    }

    function getMyPurchases(address _address) public view returns (uint256[] memory) {
        return myPurchases[_address];
    }

    /* Fund - Pre Sale Start */
    function fund(uint256 _amount) public isSalePreStarted {
        /* Confirm transferred tokens is no more than needed */
        require(availableTokens().add(_amount) <= tokensForSale, "Transferred tokens have to be equal or less than proposed");

        /* Transfer Funds */
        TransferHelper.safeTransferFrom(address(erc20), msg.sender, address(this), _amount);
        /* If Amount is equal to needed - sale is ready */
        if (availableTokens() == tokensForSale) {
            isSaleFunded = true;
        }
        emit FundEvent(msg.sender, _amount, address(this), block.timestamp);
    }

    /* Action Functions */
    function swapEth(uint256 _amount, bytes calldata _signature) external payable whenNotPaused isFunded isSaleOpen onlyWhitelisted(_signature) blockReentrancy {
        require(isSwapWithPlatformToken, "IDO is not swap with platform token");

        /* Confirm Amount is positive */
        require(_amount > 0, "Amount has to be positive");

        /* Confirm Amount is less than tokens available */
        require(_amount <= tokensLeft(), "Amount is less than tokens available");

        /* Confirm the user has funds for the transfer, confirm the value is equal */
        require(msg.value == cost(_amount), "User swap amount has to equal to cost of token in ETH");

        /* Confirm Amount is bigger than minimum Amount */
        require(_amount >= individualMinimumAmount, "Amount is bigger than minimum amount");

        /* Confirm Amount is smaller than maximum Amount */
        require(_amount <= individualMaximumAmount, "Amount is smaller than maximum amount");

        /* Verify all user purchases, loop thru them */
        uint256[] memory _purchases = getMyPurchases(msg.sender);
        uint256 purchaserTotalAmountPurchased = 0;
        for (uint i = 0; i < _purchases.length; i++) {
            Purchase memory _purchase = purchases[_purchases[i]];
            purchaserTotalAmountPurchased = purchaserTotalAmountPurchased.add(_purchase.amount);
        }
        require(purchaserTotalAmountPurchased.add(_amount) <= individualMaximumAmount, "Address has already passed the max amount of swap");

        if (isTokenSwapAtomic) {
            /* Confirm transfer */
            TransferHelper.safeTransfer(address(erc20), msg.sender, _amount);
        }

        uint256 purchase_id = increment;
        increment = increment.add(1);

        /* Create new purchase */
        Purchase memory purchase =
            Purchase(
                _amount,
                msg.sender,
                msg.value,
                block.timestamp,
                isTokenSwapAtomic, /* If Atomic Swap */
                false
            );
        purchases[purchase_id] = purchase;
        purchaseIds.push(purchase_id);
        myPurchases[msg.sender].push(purchase_id);
        buyers.push(msg.sender);
        tokensAllocated = tokensAllocated.add(_amount);
        emit PurchaseEvent(purchase_id, _amount, msg.sender, msg.value, block.timestamp, isTokenSwapAtomic);
    }

    function swapERC20(
        uint256 _amount, 
        bytes calldata _signature) 
    external whenNotPaused isFunded isSaleOpen onlyWhitelisted(_signature) blockReentrancy {
        require(!isSwapWithPlatformToken, "IDO is swap with platform token");

        /* Confirm Amount is positive */
        require(_amount > 0, "Amount has to be positive");

        /* Confirm Amount is less than tokens available */
        require(_amount <= tokensLeft(), "Amount is less than tokens available");

        /* Confirm Amount is bigger than minimum Amount */
        require(_amount >= individualMinimumAmount, "Amount is bigger than minimum amount");

        /* Confirm Amount is smaller than maximum Amount */
        require(_amount <= individualMaximumAmount, "Amount is smaller than maximum amount");

        // Get user token
        TransferHelper.safeTransferFrom(paymentToken, msg.sender, address(this), cost(_amount));

        /* Verify all user purchases, loop thru them */
        uint256[] memory _purchases = getMyPurchases(msg.sender);
        uint256 purchaserTotalAmountPurchased = 0;
        for (uint i = 0; i < _purchases.length; i++) {
            Purchase memory _purchase = purchases[_purchases[i]];
            purchaserTotalAmountPurchased = purchaserTotalAmountPurchased.add(_purchase.amount);
        }
        require(purchaserTotalAmountPurchased.add(_amount) <= individualMaximumAmount, 
            "Address has already passed the max amount of swap");

        if (isTokenSwapAtomic) {
            /* Confirm transfer */
            TransferHelper.safeTransfer(address(erc20), msg.sender, _amount);
        }

        uint256 purchase_id = increment;
        increment = increment.add(1);

        /* Create new purchase */
        Purchase memory purchase =
            Purchase(
                _amount,
                msg.sender,
                cost(_amount),
                block.timestamp,
                isTokenSwapAtomic, /* If Atomic Swap */
                false
            );
        purchases[purchase_id] = purchase;
        purchaseIds.push(purchase_id);
        myPurchases[msg.sender].push(purchase_id);
        buyers.push(msg.sender);
        tokensAllocated = tokensAllocated.add(_amount);
        emit PurchaseEvent(purchase_id, _amount, msg.sender, cost(_amount), block.timestamp, isTokenSwapAtomic);
    }

    /* Redeem tokens when the sale was finalized */
    function redeemTokens(uint256 purchase_id) external isNotAtomicSwap isSaleFinalized whenNotPaused blockReentrancy {
        /* Confirm it exists and was not finalized */
        require((purchases[purchase_id].amount != 0) && !purchases[purchase_id].wasFinalized, "Purchase is either 0 or finalized");
        require(isBuyer(purchase_id), "Address is not buyer");
        purchases[purchase_id].wasFinalized = true;
        TransferHelper.safeTransfer(address(erc20), msg.sender, purchases[purchase_id].amount);
        emit RedeemTokenEvent(purchase_id, purchases[purchase_id].amount, msg.sender, 0, purchases[purchase_id].wasFinalized, false);
    }

    /* Retrieve Minimum Amount */
    function redeemGivenMinimumGoalNotAchieved(uint256 purchase_id) external isSaleFinalized isNotAtomicSwap whenNotPaused blockReentrancy {
        require(hasMinimumRaise(), "Minimum raise has to exist");
        require(minimumRaiseNotAchieved(), "Minimum raise has to be reached");
        /* Confirm it exists and was not finalized */
        require((purchases[purchase_id].amount != 0) && !purchases[purchase_id].wasFinalized, "Purchase is either 0 or finalized");
        require(isBuyer(purchase_id), "Address is not buyer");
        purchases[purchase_id].wasFinalized = true;
        purchases[purchase_id].reverted = true;
        if (isSwapWithPlatformToken){
            msg.sender.transfer(purchases[purchase_id].paymentAmount);
        } else {
            TransferHelper.safeTransfer(paymentToken, msg.sender, purchases[purchase_id].paymentAmount);
        }
        emit RedeemTokenEvent(
            purchase_id,
            0,
            msg.sender,
            purchases[purchase_id].paymentAmount,
            purchases[purchase_id].wasFinalized,
            purchases[purchase_id].reverted
        );
    }

    /* Admin Functions */
    function withdrawFunds() external onlyOwner whenNotPaused isSaleFinalized {
        require(minimumRaiseAchieved(), "Minimum raise has to be reached");
        if (isSwapWithPlatformToken){
            uint256 fee = address(this).balance.mul(feePercentage).div(100);
            feeAddress.transfer(fee); /* Fee Address */
            uint256 funds = address(this).balance;
            msg.sender.transfer(funds);
        } else {
            uint256 totalBal = IERC20Detailed(paymentToken).balanceOf(address(this));
            uint256 fee = totalBal.mul(feePercentage).div(100);
            TransferHelper.safeTransfer(paymentToken, feeAddress, fee);
            uint256 funds = IERC20Detailed(paymentToken).balanceOf(address(this));
            TransferHelper.safeTransfer(paymentToken, msg.sender, funds);
        }
    }

    function withdrawUnsoldTokens() external onlyOwner isSaleFinalized {
        require(!unsoldTokensRedeemed);
        uint256 unsoldTokens;
        if (hasMinimumRaise() && (cost(tokensAllocated) < cost(minimumRaise))) {
            /* Minimum Raise not reached */
            unsoldTokens = tokensForSale;
        } else {
            /* If minimum Raise Achieved Redeem All Tokens minus the ones */
            unsoldTokens = tokensForSale.sub(tokensAllocated);
        }

        if (unsoldTokens > 0) {
            unsoldTokensRedeemed = true;
            TransferHelper.safeTransfer(address(erc20), msg.sender, unsoldTokens);
        }
    }

    function removeOtherERC20Tokens(address _tokenAddress, address _to) external onlyOwner isSaleFinalized {
        require(_tokenAddress != address(erc20), "Token Address has to be diff than the erc20 subject to sale"); // Confirm tokens addresses are different from main sale one
        require(isSwapWithPlatformToken || _tokenAddress != paymentToken, 
            "Token Address has to be diff than the payment token");
        IERC20Detailed erc20Token = IERC20Detailed(_tokenAddress);
        TransferHelper.safeTransfer(address(erc20Token), _to, erc20Token.balanceOf(address(this)));
    }

    function removeEthForNonPlatformTokenSwap() external onlyOwner isSaleFinalized {
        require(!isSwapWithPlatformToken, "IDO is swap with platform token");
        msg.sender.transfer(address(this).balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    /* Safe Pull function */
    function safePull() external payable onlyOwner whenPaused {
        msg.sender.transfer(address(this).balance);
        TransferHelper.safeTransfer(address(erc20), msg.sender, erc20.balanceOf(address(this)));
        if (!isSwapWithPlatformToken){
            TransferHelper.safeTransfer(
                paymentToken, 
                msg.sender, 
                IERC20Detailed(paymentToken).balanceOf(address(this))
            );
        }
    }
}