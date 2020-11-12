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

// File: contracts/interfaces/IDelegable.sol

pragma solidity ^0.6.10;


interface IDelegable {
    function addDelegate(address) external;
    function addDelegateBySignature(address, address, uint, uint8, bytes32, bytes32) external;
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

// File: contracts/Controller.sol

pragma solidity ^0.6.10;












/**
 * @dev The Controller manages collateral and debt levels for all users, and it is a major user entry point for the Yield protocol.
 * Controller keeps track of a number of fyDai contracts.
 * Controller allows users to post and withdraw Chai and Weth collateral.
 * Any transactions resulting in a user weth collateral below dust are reverted.
 * Controller allows users to borrow fyDai against their Chai and Weth collateral.
 * Controller allows users to repay their fyDai debt with fyDai or with Dai.
 * Controller integrates with fyDai contracts for minting fyDai on borrowing, and burning fyDai on repaying debt with fyDai.
 * Controller relies on Treasury for all other asset transfers.
 * Controller allows orchestrated contracts to erase any amount of debt or collateral for an user. This is to be used during liquidations or during unwind.
 * Users can delegate the control of their accounts in Controllers to any address.
 */
contract Controller is IController, Orchestrated(), Delegable(), DecimalMath {
    using SafeMath for uint256;

    event Posted(bytes32 indexed collateral, address indexed user, int256 amount);
    event Borrowed(bytes32 indexed collateral, uint256 indexed maturity, address indexed user, int256 amount);

    bytes32 public constant CHAI = "CHAI";
    bytes32 public constant WETH = "ETH-A";
    uint256 public constant DUST = 50e15; // 0.05 ETH

    IVat public vat;
    IPot public pot;
    ITreasury public override treasury;

    mapping(uint256 => IFYDai) public override series;                 // FYDai series, indexed by maturity
    uint256[] public override seriesIterator;                         // We need to know all the series

    mapping(bytes32 => mapping(address => uint256)) public override posted;                        // Collateral posted by each user
    mapping(bytes32 => mapping(uint256 => mapping(address => uint256))) public override debtFYDai;  // Debt owed by each user, by series

    bool public live = true;

    /// @dev Set up addresses for vat, pot and Treasury.
    constructor (
        address treasury_,
        address[] memory fyDais

    ) public {
        treasury = ITreasury(treasury_);
        vat = treasury.vat();
        pot = treasury.pot();
        for (uint256 i = 0; i < fyDais.length; i += 1) {
            addSeries(fyDais[i]);
        }
    }

    /// @dev Modified functions only callable while the Controller is not unwinding due to a MakerDAO shutdown.
    modifier onlyLive() {
        require(live == true, "Controller: Not available during unwind");
        _;
    }

    /// @dev Only valid collateral types are Weth and Chai.
    modifier validCollateral(bytes32 collateral) {
        require(
            collateral == WETH || collateral == CHAI,
            "Controller: Unrecognized collateral"
        );
        _;
    }

    /// @dev Only series added through `addSeries` are valid.
    modifier validSeries(uint256 maturity) {
        require(
            containsSeries(maturity),
            "Controller: Unrecognized series"
        );
        _;
    }

    /// @dev Safe casting from uint256 to int256
    function toInt256(uint256 x) internal pure returns(int256) {
        require(
            x <= uint256(type(int256).max),
            "Controller: Cast overflow"
        );
        return int256(x);
    }

    /// @dev Disables post, withdraw, borrow and repay. To be called only when Treasury shuts down.
    function shutdown() public override {
        require(
            treasury.live() == false,
            "Controller: Treasury is live"
        );
        live = false;
    }

    /// @dev Return if the borrowing power for a given collateral of a user is equal or greater
    /// than its debt for the same collateral
    /// @param collateral Valid collateral type
    /// @param user Address of the user vault
    function isCollateralized(bytes32 collateral, address user) public view override returns (bool) {
        return powerOf(collateral, user) >= totalDebtDai(collateral, user);
    }

    /// @dev Return if the collateral of an user is between zero and the dust level
    /// @param collateral Valid collateral type
    /// @param user Address of the user vault
    function aboveDustOrZero(bytes32 collateral, address user) public view returns (bool) {
        uint256 postedCollateral = posted[collateral][user];
        return postedCollateral == 0 || DUST < postedCollateral;
    }

    /// @dev Return the total number of series registered
    function totalSeries() public view override returns (uint256) {
        return seriesIterator.length;
    }

    /// @dev Returns if a series has been added to the Controller.
    /// @param maturity Maturity of the series to verify.
    function containsSeries(uint256 maturity) public view override returns (bool) {
        return address(series[maturity]) != address(0);
    }

    /// @dev Adds an fyDai series to this Controller
    /// After deployment, ownership should be renounced, so that no more series can be added.
    /// @param fyDaiContract Address of the fyDai series to add.
    function addSeries(address fyDaiContract) private {
        uint256 maturity = IFYDai(fyDaiContract).maturity();
        require(
            !containsSeries(maturity),
            "Controller: Series already added"
        );
        series[maturity] = IFYDai(fyDaiContract);
        seriesIterator.push(maturity);
    }

    /// @dev Dai equivalent of an fyDai amount.
    /// After maturity, the Dai value of an fyDai grows according to either the stability fee (for WETH collateral) or the Dai Saving Rate (for Chai collateral).
    /// @param collateral Valid collateral type
    /// @param maturity Maturity of an added series
    /// @param fyDaiAmount Amount of fyDai to convert.
    /// @return Dai equivalent of an fyDai amount.
    function inDai(bytes32 collateral, uint256 maturity, uint256 fyDaiAmount)
        public view override
        validCollateral(collateral)
        returns (uint256)
    {
        IFYDai fyDai = series[maturity];
        if (fyDai.isMature()){
            if (collateral == WETH){
                return muld(fyDaiAmount, fyDai.rateGrowth());
            } else if (collateral == CHAI) {
                return muld(fyDaiAmount, fyDai.chiGrowth());
            }
        } else {
            return fyDaiAmount;
        }
    }

    /// @dev fyDai equivalent of a Dai amount.
    /// After maturity, the fyDai value of a Dai decreases according to either the stability fee (for WETH collateral) or the Dai Saving Rate (for Chai collateral).
    /// @param collateral Valid collateral type
    /// @param maturity Maturity of an added series
    /// @param daiAmount Amount of Dai to convert.
    /// @return fyDai equivalent of a Dai amount.
    function inFYDai(bytes32 collateral, uint256 maturity, uint256 daiAmount)
        public view override
        validCollateral(collateral)
        returns (uint256)
    {
        IFYDai fyDai = series[maturity];
        if (fyDai.isMature()){
            if (collateral == WETH){
                return divd(daiAmount, fyDai.rateGrowth());
            } else if (collateral == CHAI) {
                return divd(daiAmount, fyDai.chiGrowth());
            }
        } else {
            return daiAmount;
        }
    }

    /// @dev Debt in dai of an user
    /// After maturity, the Dai debt of a position grows according to either the stability fee (for WETH collateral) or the Dai Saving Rate (for Chai collateral).
    /// @param collateral Valid collateral type
    /// @param maturity Maturity of an added series
    /// @param user Address of the user vault
    /// @return Debt in dai of an user
    //
    //                        rate_now
    // debt_now = debt_mat * ----------
    //                        rate_mat
    //
    function debtDai(bytes32 collateral, uint256 maturity, address user) public view override returns (uint256) {
        return inDai(collateral, maturity, debtFYDai[collateral][maturity][user]);
    }

    /// @dev Total debt of an user across all series, in Dai
    /// The debt is summed across all series, taking into account interest on the debt after a series matures.
    /// This function loops through all maturities, limiting the contract to hundreds of maturities.
    /// @param collateral Valid collateral type
    /// @param user Address of the user vault
    /// @return Total debt of an user across all series, in Dai
    function totalDebtDai(bytes32 collateral, address user) public view override returns (uint256) {
        uint256 totalDebt;
        uint256[] memory _seriesIterator = seriesIterator;
        for (uint256 i = 0; i < _seriesIterator.length; i += 1) {
            if (debtFYDai[collateral][_seriesIterator[i]][user] > 0) {
                totalDebt = totalDebt.add(debtDai(collateral, _seriesIterator[i], user));
            }
        } // We don't expect hundreds of maturities per controller
        return totalDebt;
    }

    /// @dev Borrowing power (in dai) of a user for a specific series and collateral.
    /// @param collateral Valid collateral type
    /// @param user Address of the user vault
    /// @return Borrowing power of an user in dai.
    //
    // powerOf[user](wad) = posted[user](wad) * price()(ray)
    //
    function powerOf(bytes32 collateral, address user) public view returns (uint256) {
        // dai = price * collateral
        if (collateral == WETH){
            (,, uint256 spot,,) = vat.ilks(WETH);  // Stability fee and collateralization ratio for Weth
            return muld(posted[collateral][user], spot);
        } else if (collateral == CHAI) {
            uint256 chi = pot.chi();
            return muld(posted[collateral][user], chi);
        } else {
            revert("Controller: Invalid collateral type");
        }
    }

    /// @dev Returns the amount of collateral locked in borrowing operations.
    /// @param collateral Valid collateral type.
    /// @param user Address of the user vault.
    function locked(bytes32 collateral, address user)
        public view
        validCollateral(collateral)
        returns (uint256)
    {
        if (collateral == WETH){
            (,, uint256 spot,,) = vat.ilks(WETH);  // Stability fee and collateralization ratio for Weth
            return divdrup(totalDebtDai(collateral, user), spot);
        } else if (collateral == CHAI) {
            return divdrup(totalDebtDai(collateral, user), pot.chi());
        }
    }

    /// @dev Takes collateral assets from `from` address, and credits them to `to` collateral account.
    /// `from` can delegate to other addresses to take assets from him. Also needs to use `ERC20.approve`.
    /// Calling ERC20.approve for Treasury contract is a prerequisite to this function
    /// @param collateral Valid collateral type.
    /// @param from Wallet to take collateral from.
    /// @param to Yield vault to put the collateral in.
    /// @param amount Amount of collateral to move.
    // from --- Token ---> us(to)
    function post(bytes32 collateral, address from, address to, uint256 amount)
        public override 
        validCollateral(collateral)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        posted[collateral][to] = posted[collateral][to].add(amount);

        if (collateral == WETH){
            require(
                aboveDustOrZero(collateral, to),
                "Controller: Below dust"
            );
            treasury.pushWeth(from, amount);
        } else if (collateral == CHAI) {
            treasury.pushChai(from, amount);
        }
        
        emit Posted(collateral, to, toInt256(amount));
    }

    /// @dev Returns collateral to `to` wallet, taking it from `from` Yield vault account.
    /// `from` can delegate to other addresses to take assets from him.
    /// @param collateral Valid collateral type.
    /// @param from Yield vault to take collateral from.
    /// @param to Wallet to put the collateral in.
    /// @param amount Amount of collateral to move.
    // us(from) --- Token ---> to
    function withdraw(bytes32 collateral, address from, address to, uint256 amount)
        public override
        validCollateral(collateral)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        posted[collateral][from] = posted[collateral][from].sub(amount); // Will revert if not enough posted

        require(
            isCollateralized(collateral, from),
            "Controller: Too much debt"
        );

        if (collateral == WETH){
            require(
                aboveDustOrZero(collateral, from),
                "Controller: Below dust"
            );
            treasury.pullWeth(to, amount);
        } else if (collateral == CHAI) {
            treasury.pullChai(to, amount);
        }

        emit Posted(collateral, from, -toInt256(amount));
    }

    /// @dev Mint fyDai for a given series for wallet `to` by increasing the user debt in Yield vault `from`
    /// `from` can delegate to other addresses to borrow using his vault.
    /// The collateral needed changes according to series maturity and MakerDAO rate and chi, depending on collateral type.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param from Yield vault that gets an increased debt.
    /// @param to Wallet to put the fyDai in.
    /// @param fyDaiAmount Amount of fyDai to borrow.
    //
    // posted[user](wad) >= (debtFYDai[user](wad)) * amount (wad)) * collateralization (ray)
    //
    // us(from) --- fyDai ---> to
    // debt++
    function borrow(bytes32 collateral, uint256 maturity, address from, address to, uint256 fyDaiAmount)
        public override
        validCollateral(collateral)
        validSeries(maturity)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        IFYDai fyDai = series[maturity];

        debtFYDai[collateral][maturity][from] = debtFYDai[collateral][maturity][from].add(fyDaiAmount);

        require(
            isCollateralized(collateral, from),
            "Controller: Too much debt"
        );

        fyDai.mint(to, fyDaiAmount);
        emit Borrowed(collateral, maturity, from, toInt256(fyDaiAmount));
    }

    /// @dev Burns fyDai from `from` wallet to repay debt in a Yield Vault.
    /// User debt is decreased for the given collateral and fyDai series, in Yield vault `to`.
    /// `from` can delegate to other addresses to take fyDai from him for the repayment.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param from Wallet providing the fyDai for repayment.
    /// @param to Yield vault to repay debt for.
    /// @param fyDaiAmount Amount of fyDai to use for debt repayment.
    //
    //                                                  debt_nominal
    // debt_discounted = debt_nominal - repay_amount * ---------------
    //                                                  debt_now
    //
    // user(from) --- fyDai ---> us(to)
    // debt--
    function repayFYDai(bytes32 collateral, uint256 maturity, address from, address to, uint256 fyDaiAmount)
        public override
        validCollateral(collateral)
        validSeries(maturity)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
        returns (uint256)
    {
        uint256 toRepay = Math.min(fyDaiAmount, debtFYDai[collateral][maturity][to]);
        series[maturity].burn(from, toRepay);
        _repay(collateral, maturity, to, toRepay);
        return toRepay;
    }

    /// @dev Burns Dai from `from` wallet to repay debt in a Yield Vault.
    /// User debt is decreased for the given collateral and fyDai series, in Yield vault `to`.
    /// The amount of debt repaid changes according to series maturity and MakerDAO rate and chi, depending on collateral type.
    /// `from` can delegate to other addresses to take Dai from him for the repayment.
    /// Calling ERC20.approve for Treasury contract is a prerequisite to this function
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param from Wallet providing the Dai for repayment.
    /// @param to Yield vault to repay debt for.
    /// @param daiAmount Amount of Dai to use for debt repayment.
    //
    //                                                  debt_nominal
    // debt_discounted = debt_nominal - repay_amount * ---------------
    //                                                  debt_now
    //
    // user --- dai ---> us
    // debt--
    function repayDai(bytes32 collateral, uint256 maturity, address from, address to, uint256 daiAmount)
        public override
        validCollateral(collateral)
        validSeries(maturity)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
        returns (uint256)
    {
        uint256 toRepay = Math.min(daiAmount, debtDai(collateral, maturity, to));
        treasury.pushDai(from, toRepay);                                      // Have Treasury process the dai
        _repay(collateral, maturity, to, inFYDai(collateral, maturity, toRepay));
        return toRepay;
    }

    /// @dev Removes an amount of debt from an user's vault.
    /// Internal function.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param user Yield vault to repay debt for.
    /// @param fyDaiAmount Amount of fyDai to use for debt repayment.

    //
    //                                                principal
    // principal_repayment = gross_repayment * ----------------------
    //                                          principal + interest
    //    
    function _repay(bytes32 collateral, uint256 maturity, address user, uint256 fyDaiAmount) internal {
        debtFYDai[collateral][maturity][user] = debtFYDai[collateral][maturity][user].sub(fyDaiAmount);

        emit Borrowed(collateral, maturity, user, -toInt256(fyDaiAmount));
    }

    /// @dev Removes all collateral and debt for an user, for a given collateral type.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param collateral Valid collateral type.
    /// @param user Address of the user vault
    /// @return The amounts of collateral and debt removed from Controller.
    function erase(bytes32 collateral, address user)
        public override
        validCollateral(collateral)
        onlyOrchestrated("Controller: Not Authorized")
        returns (uint256, uint256)
    {
        uint256 userCollateral = posted[collateral][user];
        delete posted[collateral][user];

        uint256 userDebt;
        uint256[] memory _seriesIterator = seriesIterator;
        for (uint256 i = 0; i < _seriesIterator.length; i += 1) {
            uint256 maturity = _seriesIterator[i];
            userDebt = userDebt.add(debtDai(collateral, maturity, user)); // SafeMath shouldn't be needed
            delete debtFYDai[collateral][maturity][user];
        } // We don't expect hundreds of maturities per controller

        return (userCollateral, userDebt);
    }
}