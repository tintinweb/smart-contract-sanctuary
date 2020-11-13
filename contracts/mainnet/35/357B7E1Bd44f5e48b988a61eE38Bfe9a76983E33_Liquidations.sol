// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/Math.sol


pragma solidity ^0.6.0;

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

// File: contracts/interfaces/IDelegable.sol

pragma solidity ^0.6.10;


interface IDelegable {
    function addDelegate(address) external;
    function addDelegateBySignature(address, address, uint, uint8, bytes32, bytes32) external;
}

// File: contracts/interfaces/IVat.sol

pragma solidity ^0.6.10;


/// @dev Interface to interact with the vat contract from MakerDAO
/// Taken from https://github.com/makerdao/developerguides/blob/master/devtools/working-with-dsproxy/working-with-dsproxy.md
interface IVat {
    // function can(address, address) external view returns (uint);
    function hope(address) external;
    function nope(address) external;
    function live() external view returns (uint);
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function gem(bytes32, address) external view returns (uint);
    // function dai(address) external view returns (uint);
    function frob(bytes32, address, address, address, int, int) external;
    function fork(bytes32, address, address, int, int) external;
    function move(address, address, uint) external;
    function flux(bytes32, address, address, uint) external;
}

// File: contracts/interfaces/IWeth.sol

pragma solidity ^0.6.10;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint) external;
    function approve(address, uint) external returns (bool) ;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

// File: contracts/interfaces/IGemJoin.sol

pragma solidity ^0.6.10;


/// @dev Interface to interact with the `Join.sol` contract from MakerDAO using ERC20
interface IGemJoin {
    function rely(address usr) external;
    function deny(address usr) external;
    function cage() external;
    function join(address usr, uint WAD) external;
    function exit(address usr, uint WAD) external;
}

// File: contracts/interfaces/IDaiJoin.sol

pragma solidity ^0.6.10;


/// @dev Interface to interact with the `Join.sol` contract from MakerDAO using Dai
interface IDaiJoin {
    function rely(address usr) external;
    function deny(address usr) external;
    function cage() external;
    function join(address usr, uint WAD) external;
    function exit(address usr, uint WAD) external;
}

// File: contracts/interfaces/IPot.sol

pragma solidity ^0.6.10;


/// @dev interface for the pot contract from MakerDao
/// Taken from https://github.com/makerdao/developerguides/blob/master/dai/dsr-integration-guide/dsr.sol
interface IPot {
    function chi() external view returns (uint256);
    function pie(address) external view returns (uint256); // Not a function, but a public variable.
    function rho() external returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

// File: contracts/interfaces/IChai.sol

pragma solidity ^0.6.10;


/// @dev interface for the chai contract
/// Taken from https://github.com/makerdao/developerguides/blob/master/dai/dsr-integration-guide/dsr.sol
interface IChai {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address dst, uint wad) external returns (bool);
    function move(address src, address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function approve(address usr, uint wad) external returns (bool);
    function dai(address usr) external returns (uint wad);
    function join(address dst, uint wad) external;
    function exit(address src, uint wad) external;
    function draw(address src, uint wad) external;
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address account) external view returns (uint256);
}

// File: contracts/interfaces/ITreasury.sol

pragma solidity ^0.6.10;








interface ITreasury {
    function debt() external view returns(uint256);
    function savings() external view returns(uint256);
    function pushDai(address user, uint256 dai) external;
    function pullDai(address user, uint256 dai) external;
    function pushChai(address user, uint256 chai) external;
    function pullChai(address user, uint256 chai) external;
    function pushWeth(address to, uint256 weth) external;
    function pullWeth(address to, uint256 weth) external;
    function shutdown() external;
    function live() external view returns(bool);

    function vat() external view returns (IVat);
    function weth() external view returns (IWeth);
    function dai() external view returns (IERC20);
    function daiJoin() external view returns (IDaiJoin);
    function wethJoin() external view returns (IGemJoin);
    function pot() external view returns (IPot);
    function chai() external view returns (IChai);
}

// File: contracts/interfaces/IERC2612.sol

// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// File: contracts/interfaces/IFYDai.sol

pragma solidity ^0.6.10;



interface IFYDai is IERC20, IERC2612 {
    function isMature() external view returns(bool);
    function maturity() external view returns(uint);
    function chi0() external view returns(uint);
    function rate0() external view returns(uint);
    function chiGrowth() external view returns(uint);
    function rateGrowth() external view returns(uint);
    function mature() external;
    function unlocked() external view returns (uint);
    function mint(address, uint) external;
    function burn(address, uint) external;
    function flashMint(uint, bytes calldata) external;
    function redeem(address, address, uint256) external returns (uint256);
    // function transfer(address, uint) external returns (bool);
    // function transferFrom(address, address, uint) external returns (bool);
    // function approve(address, uint) external returns (bool);
}

// File: contracts/interfaces/IController.sol

pragma solidity ^0.6.10;





interface IController is IDelegable {
    function treasury() external view returns (ITreasury);
    function series(uint256) external view returns (IFYDai);
    function seriesIterator(uint256) external view returns (uint256);
    function totalSeries() external view returns (uint256);
    function containsSeries(uint256) external view returns (bool);
    function posted(bytes32, address) external view returns (uint256);
    function debtFYDai(bytes32, uint256, address) external view returns (uint256);
    function debtDai(bytes32, uint256, address) external view returns (uint256);
    function totalDebtDai(bytes32, address) external view returns (uint256);
    function isCollateralized(bytes32, address) external view returns (bool);
    function inDai(bytes32, uint256, uint256) external view returns (uint256);
    function inFYDai(bytes32, uint256, uint256) external view returns (uint256);
    function erase(bytes32, address) external returns (uint256, uint256);
    function shutdown() external;
    function post(bytes32, address, address, uint256) external;
    function withdraw(bytes32, address, address, uint256) external;
    function borrow(bytes32, uint256, address, address, uint256) external;
    function repayFYDai(bytes32, uint256, address, address, uint256) external returns (uint256);
    function repayDai(bytes32, uint256, address, address, uint256) external returns (uint256);
}

// File: contracts/interfaces/ILiquidations.sol

pragma solidity ^0.6.10;



interface ILiquidations {
    function shutdown() external;
    function totals() external view returns(uint128, uint128);
    function erase(address) external returns(uint128, uint128);

    function controller() external returns(IController);
}

// File: @openzeppelin/contracts/math/SafeMath.sol


pragma solidity ^0.6.0;

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

// File: contracts/helpers/DecimalMath.sol

pragma solidity ^0.6.10;



/// @dev Implements simple fixed point math mul and div operations for 27 decimals.
contract DecimalMath {
    using SafeMath for uint256;

    uint256 constant public UNIT = 1e27;

    /// @dev Multiplies x and y, assuming they are both fixed point with 27 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y).div(UNIT);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 27 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT).div(y);
    }

    /// @dev Multiplies x and y, rounding up to the closest representable number.
    /// Assumes x and y are both fixed point with `decimals` digits.
    function muldrup(uint256 x, uint256 y) internal pure returns (uint256)
    {
        uint256 z = x.mul(y);
        return z.mod(UNIT) == 0 ? z.div(UNIT) : z.div(UNIT).add(1);
    }

    /// @dev Divides x between y, rounding up to the closest representable number.
    /// Assumes x and y are both fixed point with `decimals` digits.
    function divdrup(uint256 x, uint256 y) internal pure returns (uint256)
    {
        uint256 z = x.mul(UNIT);
        return z.mod(y) == 0 ? z.div(y) : z.div(y).add(1);
    }
}

// File: contracts/helpers/Delegable.sol

pragma solidity ^0.6.10;



/// @dev Delegable enables users to delegate their account management to other users.
/// Delegable implements addDelegateBySignature, to add delegates using a signature instead of a separate transaction.
contract Delegable is IDelegable {
    event Delegate(address indexed user, address indexed delegate, bool enabled);

    // keccak256("Signature(address user,address delegate,uint256 nonce,uint256 deadline)");
    bytes32 public immutable SIGNATURE_TYPEHASH = 0x0d077601844dd17f704bafff948229d27f33b57445915754dfe3d095fda2beb7;
    bytes32 public immutable DELEGABLE_DOMAIN;
    mapping(address => uint) public signatureCount;

    mapping(address => mapping(address => bool)) public delegated;

    constructor () public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DELEGABLE_DOMAIN = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('Yield')),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Require that msg.sender is the account holder or a delegate
    modifier onlyHolderOrDelegate(address holder, string memory errorMessage) {
        require(
            msg.sender == holder || delegated[holder][msg.sender],
            errorMessage
        );
        _;
    }

    /// @dev Enable a delegate to act on the behalf of caller
    function addDelegate(address delegate) public override {
        _addDelegate(msg.sender, delegate);
    }

    /// @dev Stop a delegate from acting on the behalf of caller
    function revokeDelegate(address delegate) public {
        _revokeDelegate(msg.sender, delegate);
    }

    /// @dev Add a delegate through an encoded signature
    function addDelegateBySignature(address user, address delegate, uint deadline, uint8 v, bytes32 r, bytes32 s) public override {
        require(deadline >= block.timestamp, 'Delegable: Signature expired');

        bytes32 hashStruct = keccak256(
            abi.encode(
                SIGNATURE_TYPEHASH,
                user,
                delegate,
                signatureCount[user]++,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DELEGABLE_DOMAIN,
                hashStruct
            )
        );
        address signer = ecrecover(digest, v, r, s);
        require(
            signer != address(0) && signer == user,
            'Delegable: Invalid signature'
        );

        _addDelegate(user, delegate);
    }

    /// @dev Enable a delegate to act on the behalf of an user
    function _addDelegate(address user, address delegate) internal {
        require(!delegated[user][delegate], "Delegable: Already delegated");
        delegated[user][delegate] = true;
        emit Delegate(user, delegate, true);
    }

    /// @dev Stop a delegate from acting on the behalf of an user
    function _revokeDelegate(address user, address delegate) internal {
        require(delegated[user][delegate], "Delegable: Already undelegated");
        delegated[user][delegate] = false;
        emit Delegate(user, delegate, false);
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;

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
contract Ownable is Context {
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

// File: contracts/helpers/Orchestrated.sol

pragma solidity ^0.6.10;



/**
 * @dev Orchestrated allows to define static access control between multiple contracts.
 * This contract would be used as a parent contract of any contract that needs to restrict access to some methods,
 * which would be marked with the `onlyOrchestrated` modifier.
 * During deployment, the contract deployer (`owner`) can register any contracts that have privileged access by calling `orchestrate`.
 * Once deployment is completed, `owner` should call `transferOwnership(address(0))` to avoid any more contracts ever gaining privileged access.
 */

contract Orchestrated is Ownable {
    event GrantedAccess(address access, bytes4 signature);

    mapping(address => mapping (bytes4 => bool)) public orchestration;

    constructor () public Ownable() {}

    /// @dev Restrict usage to authorized users
    /// @param err The error to display if the validation fails 
    modifier onlyOrchestrated(string memory err) {
        require(orchestration[msg.sender][msg.sig], err);
        _;
    }

    /// @dev Add orchestration
    /// @param user Address of user or contract having access to this contract.
    /// @param signature bytes4 signature of the function we are giving orchestrated access to.
    /// It seems to me a bad idea to give access to humans, and would use this only for predictable smart contracts.
    function orchestrate(address user, bytes4 signature) public onlyOwner {
        orchestration[user][signature] = true;
        emit GrantedAccess(user, signature);
    }

    /// @dev Adds orchestration for the provided function signatures
    function batchOrchestrate(address user, bytes4[] memory signatures) public onlyOwner {
        for (uint256 i = 0; i < signatures.length; i++) {
            orchestrate(user, signatures[i]);
        }
    }
}

// File: contracts/Liquidations.sol

pragma solidity ^0.6.10;










/**
 * @dev The Liquidations contract allows to liquidate undercollateralized weth vaults in a reverse Dutch auction.
 * Undercollateralized vaults can be liquidated by calling `liquidate`. This will result in debt and collateral records
 * being read and removed from the Controller using `controller.erase`.
 * Collateral from vaults can be bought with Dai using `buy`.
 * Dai taken in payment will be handed over to Treasury, and collateral assets bought will be taken from Treasury as well.
 */
contract Liquidations is ILiquidations, Orchestrated(), Delegable(), DecimalMath {

    event Liquidation(address indexed user, uint256 started, uint256 collateral, uint256 debt);

    bytes32 public constant WETH = "ETH-A";
    uint256 public constant AUCTION_TIME = 3600;
    uint256 public constant DUST = 25e15; // 0.025 ETH

    ITreasury public treasury;
    IController public override controller;

    struct Vault {
        uint128 collateral;
        uint128 debt;
    }

    mapping(address => uint256) public liquidations;
    mapping(address => Vault) public vaults;
    Vault public override totals;

    bool public live = true;

    /// @dev The Liquidations constructor links it to the Treasury and Controller contracts.
    constructor (
        address controller_
    ) public {
        controller = IController(controller_);
        treasury = controller.treasury();
    }

    /// @dev Only while Liquidations is not unwinding due to a MakerDAO shutdown.
    modifier onlyLive() {
        require(live == true, "Controller: Not available during unwind");
        _;
    }

    /// @dev Overflow-protected addition, from OpenZeppelin
    function add(uint128 a, uint128 b)
        internal pure returns (uint128)
    {
        uint128 c = a + b;
        require(c >= a, "Liquidations: Addition overflow");

        return c;
    }

    /// @dev Overflow-protected substraction, from OpenZeppelin
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "Liquidations: Substraction overflow");
        uint128 c = a - b;

        return c;
    }

    /// @dev Safe casting from uint256 to uint128
    function toUint128(uint256 x) internal pure returns(uint128) {
        require(
            x <= type(uint128).max,
            "Liquidations: Cast overflow"
        );
        return uint128(x);
    }

    /// @dev Disables buying at liquidations. To be called only when Treasury shuts down.
    function shutdown() public override {
        require(
            treasury.live() == false,
            "Liquidations: Treasury is live"
        );
        live = false;
    }


    /// @dev Return if the debt of an user is between zero and the dust level
    /// @param user Address of the user vault
    function aboveDustOrZero(address user) public view returns (bool) {
        uint256 collateral = vaults[user].collateral;
        return collateral == 0 || DUST < collateral;
    }

    /// @dev Starts a liquidation process for an undercollateralized vault.
    /// @param user Address of the user vault to liquidate.
    function liquidate(address user)
        public onlyLive
    {
        require(
            !controller.isCollateralized(WETH, user),
            "Liquidations: Vault is not undercollateralized"
        );
        // A user in liquidation can be liquidated again, but doesn't restart the auction clock
        // solium-disable-next-line security/no-block-members
        if (liquidations[user] == 0) liquidations[user] = now;

        (uint256 userCollateral, uint256 userDebt) = controller.erase(WETH, user);
        totals = Vault({
            collateral: add(totals.collateral, toUint128(userCollateral)),
            debt: add(totals.debt, toUint128(userDebt))
        });

        Vault memory vault = Vault({ // TODO: Test a user that is liquidated twice
            collateral: add(vaults[user].collateral, toUint128(userCollateral)),
            debt: add(vaults[user].debt, toUint128(userDebt))
        });
        vaults[user] = vault;

        emit Liquidation(user, now, userCollateral, userDebt);
    }

    /// @dev Buy a portion of a position under liquidation.
    /// The caller pays the debt of `user`, and `from` receives an amount of collateral.
    /// `from` can delegate to other addresses to buy for him. Also needs to use `ERC20.approve`.
    /// @param liquidated Address of the user vault to liquidate.
    /// @param from Address of the wallet paying Dai for liquidated collateral.
    /// @param to Address of the wallet to send the obtained collateral to.
    /// @param daiAmount Amount of Dai to give in exchange for liquidated collateral.
    /// @return The amount of collateral obtained.
    function buy(address from, address to, address liquidated, uint256 daiAmount)
        public onlyLive
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        returns (uint256)
    {
        require(
            vaults[liquidated].debt > 0,
            "Liquidations: Vault is not in liquidation"
        );
        treasury.pushDai(from, daiAmount);

        // calculate collateral to grab. Using divdrup stops rounding from leaving 1 stray wei in vaults.
        uint256 tokenAmount = divdrup(daiAmount, price(liquidated));

        totals = Vault({
            collateral: sub(totals.collateral, toUint128(tokenAmount)),
            debt: sub(totals.debt, toUint128(daiAmount))
        });

        Vault memory vault = Vault({
            collateral: sub(vaults[liquidated].collateral, toUint128(tokenAmount)),
            debt: sub(vaults[liquidated].debt, toUint128(daiAmount))
        });
        vaults[liquidated] = vault;

        if (vaults[liquidated].debt == 0) delete liquidations[liquidated];

        treasury.pullWeth(to, tokenAmount);

        require(
            aboveDustOrZero(liquidated),
            "Liquidations: Below dust"
        );

        return tokenAmount;
    }

    /// @dev Retrieve weth from a liquidations account. This weth could be a remainder from liquidations.
    /// If any weth is not withdrawn, it will be auctioned if the user gets liquidated again.
    /// `from` can delegate to other addresses to withdraw from him.
    /// @param from Address of the liquidations user vault to withdraw weth from.
    /// @param to Address of the wallet receiving the withdrawn weth.
    /// @param tokenAmount Amount of Weth to withdraw.
    function withdraw(address from, address to, uint256 tokenAmount)
        public onlyLive
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
    {
        Vault storage vault = vaults[from];
        require(
            vault.debt == 0,
            "Liquidations: User still in liquidation"
        );

        totals.collateral = sub(totals.collateral, toUint128(tokenAmount));
        vault.collateral = sub(vault.collateral, toUint128(tokenAmount));

        treasury.pullWeth(to, tokenAmount);
    }

    /// @dev Removes all collateral and debt for an user.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param user Address of the user vault
    /// @return The amounts of collateral and debt removed from Liquidations.
    function erase(address user)
        public override
        onlyOrchestrated("Liquidations: Not Authorized")
        returns (uint128, uint128)
    {
        Vault storage vault = vaults[user];
        uint128 collateral = vault.collateral;
        uint128 debt = vault.debt;

        totals = Vault({
            collateral: sub(totals.collateral, collateral),
            debt: sub(totals.debt, debt)
        });
        delete vaults[user];

        return (collateral, debt);
    }

    /// @dev Return price of a collateral unit, in dai, at the present moment, for a given user
    /// @param user Address of the user vault in liquidation.
    // dai = price * collateral
    //
    //                collateral      1      min(auction, elapsed)
    // price = 1 / (------------- * (--- + -----------------------))
    //                   debt         2       2 * auction
    function price(address user) public view returns (uint256) {
        require(
            liquidations[user] > 0,
            "Liquidations: Vault is not targeted"
        );
        uint256 dividend1 = uint256(vaults[user].collateral);
        uint256 divisor1 = uint256(vaults[user].debt);
        uint256 term1 = dividend1.mul(UNIT).div(divisor1);
        uint256 dividend3 = Math.min(AUCTION_TIME, now - liquidations[user]); // - unlikely to overflow
        uint256 divisor3 = AUCTION_TIME.mul(2);
        uint256 term2 = UNIT.div(2);
        uint256 term3 = dividend3.mul(UNIT).div(divisor3);
        return divd(UNIT, muld(term1, term2 + term3)); // + unlikely to overflow
    }
}