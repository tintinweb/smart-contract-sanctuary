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

// File: contracts/interfaces/IWeth.sol

pragma solidity ^0.6.10;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint) external;
    function approve(address, uint) external returns (bool) ;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
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

// File: contracts/Treasury.sol

pragma solidity ^0.6.10;












/**
 * @dev Treasury manages asset transfers between all contracts in the Yield Protocol and other external contracts such as Chai and MakerDAO.
 * Treasury doesn't have any transactional functions available for regular users.
 * All transactional methods are to be available only for orchestrated contracts.
 * Treasury will ensure that all Weth is always stored as collateral in MAkerDAO.
 * Treasury will use all Dai to pay off system debt in MakerDAO first, and if there is no system debt the surplus Dai will be wrapped as Chai.
 * Treasury will use any Chai it holds when requested to provide Dai. If there isn't enough Chai, it will borrow Dai from MakerDAO.
 */
contract Treasury is ITreasury, Orchestrated(), DecimalMath {
    bytes32 constant WETH = "ETH-A";

    IVat public override vat;
    IWeth public override weth;
    IERC20 public override dai;
    IDaiJoin public override daiJoin;
    IGemJoin public override wethJoin;
    IPot public override pot;
    IChai public override chai;
    address public unwind;

    bool public override live = true;

    /// @dev As part of the constructor:
    /// Treasury allows the `chai` and `wethJoin` contracts to take as many tokens as wanted.
    /// Treasury approves the `daiJoin` and `wethJoin` contracts to move assets in MakerDAO.
    constructor (
        address vat_,
        address weth_,
        address dai_,
        address wethJoin_,
        address daiJoin_,
        address pot_,
        address chai_
    ) public {
        // These could be hardcoded for mainnet deployment.
        dai = IERC20(dai_);
        chai = IChai(chai_);
        pot = IPot(pot_);
        weth = IWeth(weth_);
        daiJoin = IDaiJoin(daiJoin_);
        wethJoin = IGemJoin(wethJoin_);
        vat = IVat(vat_);
        vat.hope(wethJoin_);
        vat.hope(daiJoin_);

        dai.approve(address(chai), uint256(-1));      // Chai will never cheat on us
        dai.approve(address(daiJoin), uint256(-1));   // DaiJoin will never cheat on us
        weth.approve(address(wethJoin), uint256(-1)); // WethJoin will never cheat on us
    }

    /// @dev Only while the Treasury is not unwinding due to a MakerDAO shutdown.
    modifier onlyLive() {
        require(live == true, "Treasury: Not available during unwind");
        _;
    }

    /// @dev Safe casting from uint256 to int256
    function toInt(uint256 x) internal pure returns(int256) {
        require(
            x <= uint256(type(int256).max),
            "Treasury: Cast overflow"
        );
        return int256(x);
    }

    /// @dev Disables pulling and pushing. Can only be called if MakerDAO shuts down.
    function shutdown() public override {
        require(
            vat.live() == 0,
            "Treasury: MakerDAO is live"
        );
        live = false;
    }

    /// @dev Returns the Treasury debt towards MakerDAO, in Dai.
    /// We have borrowed (rate * art)
    /// Borrowing limit (rate * art) <= (ink * spot)
    function debt() public view override returns(uint256) {
        (, uint256 rate,,,) = vat.ilks(WETH);            // Retrieve the MakerDAO stability fee for Weth
        (, uint256 art) = vat.urns(WETH, address(this)); // Retrieve the Treasury debt in MakerDAO
        return muld(art, rate);
    }

    /// @dev Returns the amount of chai in this contract, converted to Dai.
    function savings() public view override returns(uint256){
        return muld(chai.balanceOf(address(this)), pot.chi());
    }

    /// @dev Takes dai from user and pays as much system debt as possible, saving the rest as chai.
    /// User needs to have approved Treasury to take the Dai.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to take Dai from.
    /// @param daiAmount Dai quantity to take.
    function pushDai(address from, uint256 daiAmount)
        public override
        onlyOrchestrated("Treasury: Not Authorized")
        onlyLive
    {
        require(dai.transferFrom(from, address(this), daiAmount));  // Take dai from user to Treasury

        // Due to the DSR being mostly lower than the SF, it is better for us to
        // immediately pay back as much as possible from the current debt to
        // minimize our future stability fee liabilities. If we didn't do this,
        // the treasury would simultaneously owe DAI (and need to pay the SF) and
        // hold Chai, which is inefficient.
        uint256 toRepay = Math.min(debt(), daiAmount);
        if (toRepay > 0) {
            daiJoin.join(address(this), toRepay);
            // Remove debt from vault using frob
            (, uint256 rate,,,) = vat.ilks(WETH); // Retrieve the MakerDAO stability fee
            vat.frob(
                WETH,
                address(this),
                address(this),
                address(this),
                0,                           // Weth collateral to add
                -toInt(divd(toRepay, rate))  // Dai debt to remove
            );
        }

        uint256 toSave = daiAmount - toRepay;         // toRepay can't be greater than dai
        if (toSave > 0) {
            chai.join(address(this), toSave);    // Give dai to Chai, take chai back
        }
    }

    /// @dev Takes Chai from user and pays as much system debt as possible, saving the rest as chai.
    /// User needs to have approved Treasury to take the Chai.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to take Chai from.
    /// @param chaiAmount Chai quantity to take.
    function pushChai(address from, uint256 chaiAmount)
        public override
        onlyOrchestrated("Treasury: Not Authorized")
        onlyLive
    {
        require(chai.transferFrom(from, address(this), chaiAmount));
        uint256 daiAmount = chai.dai(address(this));

        uint256 toRepay = Math.min(debt(), daiAmount);
        if (toRepay > 0) {
            chai.draw(address(this), toRepay);     // Grab dai from Chai, converted from chai
            daiJoin.join(address(this), toRepay);
            // Remove debt from vault using frob
            (, uint256 rate,,,) = vat.ilks(WETH); // Retrieve the MakerDAO stability fee
            vat.frob(
                WETH,
                address(this),
                address(this),
                address(this),
                0,                           // Weth collateral to add
                -toInt(divd(toRepay, rate))  // Dai debt to remove
            );
        }
        // Anything that is left from repaying, is chai savings
    }

    /// @dev Takes Weth collateral from user into the Treasury Maker vault
    /// User needs to have approved Treasury to take the Weth.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param from Wallet to take Weth from.
    /// @param wethAmount Weth quantity to take.
    function pushWeth(address from, uint256 wethAmount)
        public override
        onlyOrchestrated("Treasury: Not Authorized")
        onlyLive
    {
        require(weth.transferFrom(from, address(this), wethAmount));

        wethJoin.join(address(this), wethAmount); // GemJoin reverts if anything goes wrong.
        // All added collateral should be locked into the vault using frob
        vat.frob(
            WETH,
            address(this),
            address(this),
            address(this),
            toInt(wethAmount), // Collateral to add - WAD
            0 // Normalized Dai to receive - WAD
        );
    }

    /// @dev Returns dai using chai savings as much as possible, and borrowing the rest.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to send Dai to.
    /// @param daiAmount Dai quantity to send.
    function pullDai(address to, uint256 daiAmount)
        public override
        onlyOrchestrated("Treasury: Not Authorized")
        onlyLive
    {
        uint256 toRelease = Math.min(savings(), daiAmount);
        if (toRelease > 0) {
            chai.draw(address(this), toRelease);     // Grab dai from Chai, converted from chai
        }

        uint256 toBorrow = daiAmount - toRelease;    // toRelease can't be greater than dai
        if (toBorrow > 0) {
            (, uint256 rate,,,) = vat.ilks(WETH); // Retrieve the MakerDAO stability fee
            // Increase the dai debt by the dai to receive divided by the stability fee
            // `frob` deals with "normalized debt", instead of DAI.
            // "normalized debt" is used to account for the fact that debt grows
            // by the stability fee. The stability fee is accumulated by the "rate"
            // variable, so if you store Dai balances in "normalized dai" you can
            // deal with the stability fee accumulation with just a multiplication.
            // This means that the `frob` call needs to be divided by the `rate`
            // while the `GemJoin.exit` call can be done with the raw `toBorrow`
            // number.
            vat.frob(
                WETH,
                address(this),
                address(this),
                address(this),
                0,
                toInt(divdrup(toBorrow, rate))      // We need to round up, otherwise we won't exit toBorrow
            );
            daiJoin.exit(address(this), toBorrow); // `daiJoin` reverts on failures
        }

        require(dai.transfer(to, daiAmount));                            // Give dai to user
    }

    /// @dev Returns chai using chai savings as much as possible, and borrowing the rest.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to send Chai to.
    /// @param chaiAmount Chai quantity to send.
    function pullChai(address to, uint256 chaiAmount)
        public override
        onlyOrchestrated("Treasury: Not Authorized")
        onlyLive
    {
        uint256 chi = pot.chi();
        uint256 daiAmount = muldrup(chaiAmount, chi);   // dai = price * chai, we round up, otherwise we won't borrow enough dai
        uint256 toRelease = Math.min(savings(), daiAmount);
        // As much chai as the Treasury has, can be used, we borrow dai and convert it to chai for the rest

        uint256 toBorrow = daiAmount - toRelease;    // toRelease can't be greater than daiAmount
        if (toBorrow > 0) {
            (, uint256 rate,,,) = vat.ilks(WETH); // Retrieve the MakerDAO stability fee
            // Increase the dai debt by the dai to receive divided by the stability fee
            vat.frob(
                WETH,
                address(this),
                address(this),
                address(this),
                0,
                toInt(divdrup(toBorrow, rate))       // We need to round up, otherwise we won't exit toBorrow
            ); // `vat.frob` reverts on failure
            daiJoin.exit(address(this), toBorrow);  // `daiJoin` reverts on failures
            chai.join(address(this), toBorrow);     // Grab chai from Chai, converted from dai
        }

        require(chai.transfer(to, chaiAmount));                            // Give dai to user
    }

    /// @dev Moves Weth collateral from Treasury controlled Maker Eth vault to `to` address.
    /// This function can only be called by other Yield contracts, not users directly.
    /// @param to Wallet to send Weth to.
    /// @param wethAmount Weth quantity to send.
    function pullWeth(address to, uint256 wethAmount)
        public override
        onlyOrchestrated("Treasury: Not Authorized")
        onlyLive
    {
        // Remove collateral from vault using frob
        vat.frob(
            WETH,
            address(this),
            address(this),
            address(this),
            -toInt(wethAmount), // Weth collateral to remove - WAD
            0              // Dai debt to add - WAD
        );
        wethJoin.exit(to, wethAmount); // `GemJoin` reverts on failures
    }

    /// @dev Registers the one contract that will take assets from the Treasury if MakerDAO shuts down.
    /// This function can only be called by the contract owner, which should only be possible during deployment.
    /// This function allows Unwind to take all the Chai savings and operate with the Treasury MakerDAO vault.
    /// @param unwind_ The address of the Unwild.sol contract.
    function registerUnwind(address unwind_)
        public
        onlyOwner
    {
        require(
            unwind == address(0),
            "Treasury: Unwind already set"
        );
        unwind = unwind_;
        chai.approve(address(unwind), uint256(-1)); // Unwind will never cheat on us
        vat.hope(address(unwind));                  // Unwind will never cheat on us
    }
}