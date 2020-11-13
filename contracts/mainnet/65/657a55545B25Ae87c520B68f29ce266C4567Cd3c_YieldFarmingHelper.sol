// File: @openzeppelin\upgrades\contracts\Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin\contracts-ethereum-package\contracts\GSN\Context.sol

pragma solidity ^0.5.0;


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
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts-ethereum-package\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin\contracts-ethereum-package\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts-ethereum-package\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin\contracts-ethereum-package\contracts\token\ERC20\ERC20Detailed.sol

pragma solidity ^0.5.0;



/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

// File: contracts\libs\uniswap\IUniswapV2Pair.sol

pragma solidity ^0.5.5;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\libs\uniswap\UniswapV2Library.sol

pragma solidity ^0.5.5;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        //(uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address pair, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(pair, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts\interfaces\IVolcieToken.sol

pragma solidity ^0.5.5;


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
interface IVolcieToken {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function allTokenOf(address holder) external view returns(uint256[] memory);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function burn(uint256 tokenId) external;
    function mint(address to, address lpToken, uint256 lpAmount)  external returns (uint256);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() external view returns (string name);
    // function symbol() external view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

}

// File: contracts\yieldFarming\YieldFarming.sol

/**
* @title YieldFarming
* @author @Ola, @ziweidream, @Xaleee
* @notice This contract will track uniswap pool contract and addresses that deposit "UNISWAP pool" tokens 
*         and allow each individual address to DEPOSIT and  withdraw percentage of KTY and SDAO tokens 
*         according to number of "pool" tokens they own, relative to total pool tokens.
*         This contract contains two tokens in contract KTY and SDAO. The contract will also return 
*         certain statistics about rates, availability and timing period of the program.
*/
pragma solidity ^0.5.5;







//import "./YieldFarmingHelper.sol";
//import "./YieldsCalculator.sol";

contract YieldFarming is Ownable {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    IVolcieToken public volcie;                          // VolcieToken contract
    IERC20 public kittieFightToken;                      // KittieFightToken contract variable
    IERC20 public superDaoToken;                         // SuperDaoToken contract variable
    YieldFarmingHelper public yieldFarmingHelper;        // YieldFarmingHelper contract variable
    YieldsCalculator public yieldsCalculator;            // YieldFarmingHelper contract variable

    uint256 constant internal base18 = 1000000000000000000;
    uint256 constant internal base6 = 1000000;

    uint256 constant public MONTH = 30 days;// 30 * 24 * 60 * 60;  // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 1 days;// 24 * 60 * 60;

    uint256 public totalNumberOfPairPools;              // Total number of Uniswap V2 pair pools associated with YieldFarming

    uint256 public EARLY_MINING_BONUS;
    //uint256 public totalLockedLPinEarlyMining;
    uint256 public adjustedTotalLockedLPinEarlyMining;

    //uint256 public totalDepositedLP;                    // Total Uniswap Liquidity tokens deposited
    uint256 public totalLockedLP;                       // Total Uniswap Liquidity tokens locked
    uint256 public totalRewardsKTY;                     // Total KittieFightToken rewards
    uint256 public totalRewardsSDAO;                    // Total SuperDaoToken rewards
    uint256 public totalRewardsKTYclaimed;              // KittieFightToken rewards already claimed
    uint256 public totalRewardsSDAOclaimed;             // SuperDaoToken rewards already claimed

    uint256 public programDuration;                     // Total time duration for Yield Farming Program
    uint256 public programStartAt;                      // Start Time of Yield Farming Program 
    uint256 public programEndAt;                        // End Time of Yield Farming Program 
    uint256[6] public monthsStartAt;                    // an array of the start time of each month.
  
    uint256[6] public KTYunlockRates;                   // Reward Unlock Rates of KittieFightToken for eahc of the 6 months for the entire program duration
    uint256[6] public SDAOunlockRates;                  // Reward Unlock Rates of KittieFightToken for eahc of the 6 months for the entire program duration

    // Properties of a Staker
    struct Staker {
        uint256[2][] totalDeposits;                      // A 2d array of total deposits [[pairCode, batchNumber], [[pairCode, batchNumber], ...]]
        uint256[][200] batchLockedLPamount;              // A 2d array showing the locked amount of Liquidity tokens in each batch of each Pair Pool
        uint256[][200] adjustedBatchLockedLPamount;      // A 2d array showing the locked amount of Liquidity tokens in each batch of each Pair Pool, adjusted to LP bubbling factor
        uint256[][200] adjustedStartingLPamount;
        uint256[][200] factor;                           // A 2d array showing the LP bubbling factor in each batch of each Pair Pool
        uint256[][200] batchLockedAt;                    // A 2d array showing the locked time of each batch in each Pair Pool
        uint256[200] totalLPlockedbyPairCode;            // Total amount of Liquidity tokens locked by this stader from all pair pools
        //uint256 rewardsKTYclaimed;                     // Total amount of KittieFightToken rewards already claimed by this Staker
        //uint256 rewardsSDAOclaimed;                    // Total amount of SuperDaoToken rewards already claimed by this Staker
        uint256[] depositNumberForEarlyBonus;            // An array of all the deposit number eligible for early bonus for this staker
    }

    /// @dev a VOLCIE Token NFT's associated properties
    struct VolcieToken {
        address originalOwner;   // the owner of this token at the time of minting
        uint256 generation;      // the generation of this token, between number 0 and 5
        uint256 depositNumber;   // the deposit number associated with this token and the original owner
        uint256 LP;              // the original LP locked in this volcie token
        uint256 pairCode;        // the pair code of the uniswap pair pool from which the LP come from
        uint256 lockedAt;        // the unix time at which this funds is locked
        bool tokenBurnt;         // true if this token has been burnt
        uint256 tokenBurntAt;    // the time when this token was burnt, 0 if token is not burnt
        address tokenBurntBy;    // who burnt this token (if this token was burnt)
        uint256 ktyRewards;      // KTY rewards distributed upon burning this token
        uint256 sdaoRewards;     // SDAO rewards distributed upon burning this token
    }

    mapping(address => Staker) internal stakers;

    mapping(uint256 => address) internal pairPoolsInfo;

    /// @notice mapping volcieToken NFT to its properties
    mapping(uint256 => VolcieToken) internal volcieTokens;

    /// @notice mapping of every month to the total deposits made during that month, adjusted to the bubbling factor
    mapping(uint256 => uint256) public adjustedMonthlyDeposits;

    /// @notice mapping staker to the rewards she has already claimed
    mapping(address => uint256[2]) internal rewardsClaimed;

    /// @notice mapping of pair code to total deposited LPs associated with this pair code
    mapping(uint256 => uint256) internal totalDepositedLPbyPairCode;

    uint256 private unlocked;

    uint256 public calculated;
    uint256 public calculated1;

    /*                                                   MODIFIERS                                                    */
    /* ============================================================================================================== */
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }          

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */
    function initialize
    (
        address[] calldata _pairPoolAddr,
        IVolcieToken _volcie,
        IERC20 _kittieFightToken,
        IERC20 _superDaoToken,
        YieldFarmingHelper _yieldFarmingHelper,
        YieldsCalculator _yieldsCalculator,
        uint256[6] calldata _ktyUnlockRates,
        uint256[6] calldata _sdaoUnlockRates,
        uint256 _programStartTime
    )
        external initializer
    {
        Ownable.initialize(_msgSender());
        setVolcieToken(_volcie);
        setRewardsToken(_kittieFightToken, true);
        setRewardsToken(_superDaoToken, false);

        for (uint256 i = 0; i < _pairPoolAddr.length; i++) {
            addNewPairPool(_pairPoolAddr[i]);
        }

        // setKittieFightToken(_kittieFightToken);
        // setSuperDaoToken(_superDaoToken);
        setYieldFarmingHelper(_yieldFarmingHelper);
        setYieldsCalculator(_yieldsCalculator);

        // Set total rewards in KittieFightToken and SuperDaoToken
        totalRewardsKTY = 7000000 * base18; // 7000000 * base18;
        totalRewardsSDAO = 7000000 * base18; //7000000 * base18;

        // Set early mining bonus
        EARLY_MINING_BONUS = 700000 * base18; //700000 * base18;

        // Set reward unlock rate for the program duration
        for (uint256 j = 0; j < 6; j++) {
            setRewardUnlockRate(j, _ktyUnlockRates[j], true);
            setRewardUnlockRate(j, _sdaoUnlockRates[j], false);
        }

        // Set program duration (for a period of 6 months). Month starts at time of program deployment/initialization
        setProgramDuration(6, _programStartTime);

        //Reentrancy lock
        unlocked = 1;
    }

    /*                                                      EVENTS                                                    */
    /* ============================================================================================================== */
    event Deposited(
        address indexed sender,
        uint256 indexed volcieTokenID,
        uint256 depositNumber,
        uint256 indexed pairCode,
        uint256 lockedLP,
        uint256 depositTime
    );

    event VolcieTokenBurnt(
        address indexed burner,
        address originalOwner,
        uint256 indexed volcieTokenID,
        uint256 indexed depositNumber,
        uint256 pairCode,
        uint256 batchNumber,
        uint256 KTYamount,
        uint256 SDAOamount,
        uint256 LPamount,
        uint256 withdrawTime
    );

    // event WithDrawn(
    //     address indexed sender,
    //     uint256 indexed pairCode,
    //     uint256 KTYamount,
    //     uint256 SDAOamount,
    //     uint256 LPamount,
    //     uint256 startBatchNumber,
    //     uint256 endBatchNumber, 
    //     uint256 withdrawTime
    // );

    /*                                                 YIELD FARMING FUNCTIONS                                        */
    /* ============================================================================================================== */

    /**
     * @notice Deposit Uniswap Liquidity tokens
     * @param _amountLP the amount of Uniswap Liquidity tokens to be deposited
     * @param _pairCode the Pair Code associated with the Pair Pool of which the Liquidity tokens are to be deposited
     * @return bool true if the deposit is successful
     * @dev    Each new deposit of a staker makes a new deposit with Deposit Number for this staker.
     *         Deposit Number for each staker starts from 0 (for the first deposit), and increment by 1 for 
     *         subsequent deposits. Each deposit with a Deposit Number is associated with a Pair Code 
     *         and a Batch Number.
     *         For each staker, each Batch Number in each Pair Pool associated with a Pair Code starts 
     *         from 0 (for the first deposit), and increment by 1 for subsequent batches each.
     */
    function deposit(uint256 _amountLP, uint256 _pairCode) external lock returns (bool) {
        require(block.timestamp >= programStartAt && block.timestamp <= programEndAt, "Program is not active");
        
        require(_amountLP > 0, "Cannot deposit 0 tokens");

        require(IUniswapV2Pair(pairPoolsInfo[_pairCode]).transferFrom(msg.sender, address(this), _amountLP), "Fail to deposit liquidity tokens");

        uint256 _depositNumber = stakers[msg.sender].totalDeposits.length;

        _addDeposit(msg.sender, _depositNumber, _pairCode, _amountLP, block.timestamp);

        (,address _LPaddress,) = getPairPool(_pairCode);

        uint256 _volcieTokenID = _mint(msg.sender, _LPaddress, _amountLP);

        _updateMint(msg.sender, _depositNumber, _amountLP, _pairCode, _volcieTokenID);

        emit Deposited(msg.sender, _volcieTokenID, _depositNumber, _pairCode, _amountLP, block.timestamp);

        return true;
    }

    /**
     * @notice Withdraw Uniswap Liquidity tokens locked in a batch with _batchNumber specified by the staker
     * @notice Three tokens (Uniswap Liquidity Tokens, KittieFightTokens, and SuperDaoTokens) are transferred
     *         to the user upon successful withdraw
     * @param _volcieID the deposit number of the deposit from which the user wishes to withdraw the Uniswap Liquidity tokens locked 
     * @return bool true if the withdraw is successful
     */
    function withdrawByVolcieID(uint256 _volcieID) external lock returns (bool) {
        (bool _isPayDay,) = yieldFarmingHelper.isPayDay();
        require(_isPayDay, "Can only withdraw on pay day");

        address currentOwner = volcie.ownerOf(_volcieID);
        require(currentOwner == msg.sender, "Only the owner of this token can burn it");

        // require this token has not been burnt already
        require(volcieTokens[_volcieID].tokenBurnt == false, "This Volcie Token has already been burnt");

        address _originalOwner = volcieTokens[_volcieID].originalOwner;
        uint256 _depositNumber = volcieTokens[_volcieID].depositNumber;

        uint256 _pairCode = stakers[_originalOwner].totalDeposits[_depositNumber][0];
        uint256 _batchNumber = stakers[_originalOwner].totalDeposits[_depositNumber][1];

        // get the locked Liquidity token amount in this batch
        uint256 _amountLP = stakers[_originalOwner].batchLockedLPamount[_pairCode][_batchNumber];
        require(_amountLP > 0, "No locked tokens in this deposit");

        uint256 _lockDuration = block.timestamp.sub(volcieTokens[_volcieID].lockedAt);
        require(_lockDuration > MONTH, "Need to stake at least 30 days");

        volcie.burn(_volcieID);

        (uint256 _KTY, uint256 _SDAO) = yieldsCalculator.calculateRewardsByBatchNumber(_originalOwner, _batchNumber, _pairCode);

        _updateWithdrawByBatchNumber(_originalOwner, _pairCode, _batchNumber, _amountLP, _KTY, _SDAO);

        _updateBurn(msg.sender, _volcieID, _KTY, _SDAO);

        _transferTokens(msg.sender, _pairCode, _amountLP, _KTY, _SDAO);

        emit VolcieTokenBurnt(
            msg.sender, _originalOwner, _volcieID, _depositNumber, _pairCode,
            _batchNumber, _KTY, _SDAO, _amountLP, block.timestamp
        );

        return true;
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    /**
     * @dev Add new pairPool
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function addNewPairPool(address _pairPoolAddr) public onlyOwner {
        uint256 _pairCode = totalNumberOfPairPools;

        IUniswapV2Pair pair = IUniswapV2Pair(_pairPoolAddr);
        address token0 = pair.token0();
        address token1 = pair.token1();
        require(token0 == address(kittieFightToken) || token1 == address(kittieFightToken), "Pair should contain KTY");

        pairPoolsInfo[_pairCode] = _pairPoolAddr;

        totalNumberOfPairPools = totalNumberOfPairPools.add(1);
    }

    /**
     * @dev Set VOLCIE contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setVolcieToken(IVolcieToken _volcie) public onlyOwner {
        volcie = _volcie;
    }

    /**
     * @dev Set KittieFightToken contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setRewardsToken(IERC20 _rewardsToken, bool forKTY) public onlyOwner {
        if (forKTY) {
            kittieFightToken = _rewardsToken;
        } else {
            superDaoToken = _rewardsToken;
        }   
    }

    /**
     * @dev Set YieldFarmingHelper contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarmingHelper(YieldFarmingHelper _yieldFarmingHelper) public onlyOwner {
        yieldFarmingHelper = _yieldFarmingHelper;
    }

    /**
     * @dev Set YieldsCalculator contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldsCalculator(YieldsCalculator _yieldsCalculator) public onlyOwner {
        yieldsCalculator = _yieldsCalculator;
    }

    /**
     * @notice This function transfers tokens out of this contract to a new address
     * @dev This function is used to transfer unclaimed KittieFightToken or SuperDaoToken Rewards to a new address,
     *      or transfer other tokens erroneously tranferred to this contract back to their original owner
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function returnTokens(address _token, uint256 _amount, address _newAddress) external onlyOwner {
        require(block.timestamp > programEndAt.add(MONTH.mul(2)), "Owner can only return tokens after two months after program ends");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(_amount <= balance, "Exceeds balance");
        require(IERC20(_token).transfer(_newAddress, _amount), "Fail to transfer tokens");
    }

    /**
     * @notice Modify Reward Unlock Rate for KittieFightToken and SuperDaoToken for any month (from 0 to 5)
     *         within the program duration (a period of 6 months)
     * @param _month uint256 the month (from 0 to 5) for which the unlock rate is to be modified
     * @param _rate  uint256 the unlock rate
     * @param forKTY bool true if this modification is for KittieFightToken, false if it is for SuperDaoToken
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setRewardUnlockRate(uint256 _month, uint256 _rate, bool forKTY) public onlyOwner {
        if (forKTY) {
            KTYunlockRates[_month] = _rate;
        } else {
            SDAOunlockRates[_month] = _rate;
        }
    }

    /**
     * @notice Set Yield Farming Program time duration
     * @param _totalNumberOfMonths uint256 total number of months in the entire program duration
     * @param _programStartAt uint256 time when Yield Farming Program starts
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setProgramDuration(uint256 _totalNumberOfMonths, uint256 _programStartAt) public onlyOwner {
        programDuration = _totalNumberOfMonths.mul(MONTH);
        programStartAt = _programStartAt;
        programEndAt = programStartAt.add(MONTH.mul(6));

        monthsStartAt[0] = _programStartAt;
        for (uint256 i = 1; i < _totalNumberOfMonths; i++) {
            monthsStartAt[i] = monthsStartAt[i.sub(1)].add(MONTH); 
        }
    }

    /**
     * @notice Set total KittieFightToken rewards and total SuperDaoToken rewards for the entire program duration
     * @param _rewardsKTY uint256 total KittieFightToken rewards for the entire program duration
     * @param _rewardsSDAO uint256 total SuperDaoToken rewards for the entire program duration
     * @dev    This function can only be carreid out by the owner of this contract.
     */
    function setTotalRewards(uint256 _rewardsKTY, uint256 _rewardsSDAO) public onlyOwner {
        totalRewardsKTY = _rewardsKTY;
        totalRewardsSDAO = _rewardsSDAO;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */
    
    /**
     * @param _pairCode uint256 Pair Code assocated with the Pair Pool 
     * @return the address of the pair pool associated with _pairCode
     */
    function getPairPool(uint256 _pairCode)
        public view
        returns (string memory, address, address)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairPoolsInfo[_pairCode]);
        address token0 = pair.token0();
        address token1 = pair.token1();
        address otherToken = (token0 == address(kittieFightToken))?token1:token0;
        string memory pairName = string(abi.encodePacked(ERC20Detailed(address(kittieFightToken)).symbol(),"-",ERC20Detailed(address(otherToken)).symbol()));
        return (pairName, pairPoolsInfo[_pairCode], otherToken);
    }

    /**
     * @param _volcieTokenID uint256 Volcie Token ID 
     * @return the properties of this Volcie Token 
     */
    function getVolcieToken(uint256 _volcieTokenID) public view
        returns (
            address originalOwner, uint256 depositNumber, uint256 generation,
            uint256 LP, uint256 pairCode, uint256 lockTime, bool tokenBurnt,
            address tokenBurntBy, uint256 ktyRewardsDistributed, uint256 sdaoRewardsDistributed
        )
    {
        originalOwner = volcieTokens[_volcieTokenID].originalOwner;
        depositNumber = volcieTokens[_volcieTokenID].depositNumber;
        generation = volcieTokens[_volcieTokenID].generation;
        LP = volcieTokens[_volcieTokenID].LP;
        pairCode = volcieTokens[_volcieTokenID].pairCode;
        lockTime = volcieTokens[_volcieTokenID].lockedAt;
        tokenBurnt = volcieTokens[_volcieTokenID].tokenBurnt;
        tokenBurntBy = volcieTokens[_volcieTokenID].tokenBurntBy;
        ktyRewardsDistributed = volcieTokens[_volcieTokenID].ktyRewards;
        sdaoRewardsDistributed = volcieTokens[_volcieTokenID].sdaoRewards;

    }

    /**
     * @return uint[2][2] a 2d array containing all the deposits made by the staker in this contract,
     *         each item in the 2d array consisting of the Pair Code and the Batch Number associated this
     *         the deposit. The Deposit Number of the deposit is the same as its index in the 2d array.
     */
    function getAllDeposits(address _staker)
        external view returns (uint256[2][] memory)
    {
        return stakers[_staker].totalDeposits;
    }

    /**
     * @return the total number of deposits this _staker has made
     */
    function getNumberOfDeposits(address _staker)
        external view returns (uint256)
    {
        return stakers[_staker].totalDeposits.length;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _depositNumber deposit number for the _staker
     * @return pair pool code and batch number associated with this _depositNumber for the _staker
     */

    function getBatchNumberAndPairCode(address _staker, uint256 _depositNumber)
        public view returns (uint256, uint256)
    {
        uint256 _pairCode = stakers[_staker].totalDeposits[_depositNumber][0];
        uint256 _batchNumber = stakers[_staker].totalDeposits[_depositNumber][1];
        return (_pairCode, _batchNumber);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool from whichh the batches are to be shown
     * @return uint256[] an array of the amount of locked Lquidity tokens in every batch of the _staker in
     *         the _pairCode. The index of the array is the Batch Number associated with the batch, since
     *         batch for a stakder starts from batch 0, and increment by 1 for subsequent batches each.
     * @dev    Each new deposit of a staker makes a new batch in _pairCode.
     */
    function getAllBatchesPerPairPool(address _staker, uint256 _pairCode)
        external view returns (uint256[] memory)
    {
        return stakers[_staker].batchLockedLPamount[_pairCode];
    }

    // function getAllDepositedLPs(address _staker)
    //     external view returns (uint256)
    // {
    //     return stakers[_staker].totalDepositedLPs;
    // }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @return uint256 the amount of Uniswap Liquidity tokens locked,
     *         and its adjusted amount, and the time when this batch was locked,
     *         in the batch with _batchNumber in _pairCode by the staker 
     */
    function getLPinBatch(address _staker, uint256 _pairCode, uint256 _batchNumber)
        external view returns (uint256, uint256, uint256, uint256)
    {
        uint256 _LP = stakers[_staker].batchLockedLPamount[_pairCode][_batchNumber];
        uint256 _adjustedLP = stakers[_staker].adjustedBatchLockedLPamount[_pairCode][_batchNumber];
        uint256 _adjustedStartingLP = stakers[_staker].adjustedStartingLPamount[_pairCode][_batchNumber];        
        uint256 _lockTime = stakers[_staker].batchLockedAt[_pairCode][_batchNumber];
        
        return (_LP, _adjustedLP, _adjustedStartingLP, _lockTime);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @return uint256 the bubble factor of LP associated with this batch
     */
    function getFactorInBatch(address _staker, uint256 _pairCode, uint256 _batchNumber)
        external view returns (uint256)
    {
        return stakers[_staker].factor[_pairCode][_batchNumber];
    }

    /**
     * @return uint256 the total amount of locked liquidity tokens of a staker assocaited with _pairCode
     */
    function getLockedLPbyPairCode(address _staker, uint256 _pairCode)
        external view returns (uint256)
    {
        return stakers[_staker].totalLPlockedbyPairCode[_pairCode];
    }

    function getDepositsForEarlyBonus(address _staker) external view returns(uint256[] memory) {
        return stakers[_staker].depositNumberForEarlyBonus;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return bool true if the batch with the _batchNumber in the _pairCode of the _staker is eligible for Early Bonus, false if it is not eligible.
     * @dev    A batch needs to be locked within 7 days since contract deployment to be eligible for claiming yields.
     */
    function isBatchEligibleForEarlyBonus(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view returns (bool)
    {
        // get locked time
        uint256 lockedAt = stakers[_staker].batchLockedAt[_pairCode][_batchNumber];
        if (lockedAt > 0 && lockedAt <= programStartAt.add(DAY.mul(21))) {
            return true;
        }
        return false;
    }

    /**
     * @param _staker address the staker who has received the rewards
     * @return uint256 the total amount of KittieFightToken that have been claimed by this _staker
     * @return uint256 the total amount of SuperDaoToken that have been claimed by this _staker
     */
    function getTotalRewardsClaimedByStaker(address _staker) external view returns (uint256[2] memory) {
        return rewardsClaimed[_staker];
    }

    /**
     * @return unit256 the total monthly deposits of LPs, adjusted to LP factor.
     * @dev    LP factor reflects the difference of the intrinsic value of LP from different uniswap pair contracts
     */
    function getAdjustedTotalMonthlyDeposits(uint256 _month) external view returns (uint256) {
        return adjustedMonthlyDeposits[_month];
    }

    /**
     * @return unit256 the current month 
     * @dev    There are 6 months in this program in total, starting from month 0 to month 5.
     */
    function getCurrentMonth() public view returns (uint256) {
        uint256 currentMonth;
        for (uint256 i = 5; i >= 0; i--) {
            if (block.timestamp >= monthsStartAt[i]) {
                currentMonth = i;
                break;
            }
        }
        return currentMonth;
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the Reward Unlock Rate for KittieFightToken for the _month
     * @return uint256 the Reward Unlock Rate for SuperDaoToken for the _month
     */
    function getRewardUnlockRateByMonth(uint256 _month) external view returns (uint256, uint256) {
        uint256 _KTYunlockRate = KTYunlockRates[_month];
        uint256 _SDAOunlockRate = SDAOunlockRates[_month];
        return (_KTYunlockRate, _SDAOunlockRate);
    }

    /**
     * @return unit256 the starting time of a month
     * @dev    There are 6 months in this program in total, starting from month 0 to month 5.
     */

    function getMonthStartAt(uint256 month) external view returns (uint256) {
        return monthsStartAt[month];
    }

    function getTotalDepositsPerPairCode(uint256 _pairCode) external view returns (uint256) {
        return totalDepositedLPbyPairCode[_pairCode];
    }

    /**
     * This function is returning APY of yieldFarming program.
     * @return uint256 APY
     */
    function getAPY(address _pair_KTY_SDAO) external view returns (uint256) {
        if(totalLockedLP == 0)
            return 0;
        uint256 rateKTYSDAO = getExpectedPrice_KTY_SDAO(_pair_KTY_SDAO);

        uint256 totalRewardsInKTY = totalRewardsKTY.add(totalRewardsSDAO.mul(rateKTYSDAO).div(base18));

        uint256 lockedKTYs;

        for(uint256 i = 0; i < totalNumberOfPairPools; i++) {
            if(totalDepositedLPbyPairCode[i] == 0)
                continue;
            uint256 balance = kittieFightToken.balanceOf(pairPoolsInfo[i]);
            uint256 supply = IERC20(pairPoolsInfo[i]).totalSupply();
            uint256 KTYs = balance.mul(totalDepositedLPbyPairCode[i]).mul(2).div(supply);
            lockedKTYs = lockedKTYs.add(KTYs);
        }

        return base18.mul(200).mul(lockedKTYs.add(totalRewardsInKTY)).div(lockedKTYs);
    }

    /**
     * @dev returns the SDAO KTY price on uniswap, that is, how many KTYs for 1 SDAO
     */
    function getExpectedPrice_KTY_SDAO(address _pair_KTY_SDAO) public view returns (uint256) {
        // uint256 KTYbalance = kittieFightToken.balanceOf(_pair_KTY_SDAO);
        // uint256 SDAObalance = superDaoToken.balanceOf(_pair_KTY_SDAO);
        // return KTYbalance.mul(base18).div(SDAObalance);

        uint256 _amountSDAO = 1e18;  // 1 SDAO
        (uint256 _reserveKTY, uint256 _reserveSDAO) = yieldFarmingHelper.getReserve(
            address(kittieFightToken), address(superDaoToken), _pair_KTY_SDAO
            );
        return UniswapV2Library.getAmountIn(_amountSDAO, _reserveKTY, _reserveSDAO);
    }

    /*                                                 PRIVATE FUNCTIONS                                             */
    /* ============================================================================================================== */

    /**
     * @dev    Internal functions used in function deposit()
     * @param _sender address the address of the sender
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _amount uint256 the amount of Uniswap Liquidity tokens to be deposited
     * @param _lockedAt uint256 the time when this depoist is made
     */
    function _addDeposit
    (
        address _sender, uint256 _depositNumber, uint256 _pairCode, uint256 _amount, uint256 _lockedAt
    ) private {
        // uint256 _depositNumber = stakers[_sender].totalDeposits.length;
        uint256 _batchNumber = stakers[_sender].batchLockedLPamount[_pairCode].length;
        uint256 _currentMonth = getCurrentMonth();
        uint256 _factor = yieldFarmingHelper.bubbleFactor(_pairCode);
        uint256 _adjustedAmount = _amount.mul(base6).div(_factor);

        stakers[_sender].totalDeposits.push([_pairCode, _batchNumber]);
        stakers[_sender].batchLockedLPamount[_pairCode].push(_amount);
        stakers[_sender].adjustedBatchLockedLPamount[_pairCode].push(_adjustedAmount);
        stakers[_sender].factor[_pairCode].push(_factor);
        stakers[_sender].batchLockedAt[_pairCode].push(_lockedAt);
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].add(_amount);
        //stakers[_sender].totalDepositedLPs = stakers[_sender].totalDepositedLPs.add(_amount);

        uint256 _currentDay = yieldsCalculator.getCurrentDay();

        if (yieldsCalculator.getElapsedDaysInMonth(_currentDay, _currentMonth) > 0) {
            uint256 currentDepositedAmount = yieldsCalculator.getFirstMonthAmount(
                _currentDay,
                _currentMonth,
                adjustedMonthlyDeposits[_currentMonth],
                _adjustedAmount
            );

            stakers[_sender].adjustedStartingLPamount[_pairCode].push(currentDepositedAmount);
            adjustedMonthlyDeposits[_currentMonth] = adjustedMonthlyDeposits[_currentMonth].add(currentDepositedAmount);
        } else {
            stakers[_sender].adjustedStartingLPamount[_pairCode].push(_adjustedAmount);
            adjustedMonthlyDeposits[_currentMonth] = adjustedMonthlyDeposits[_currentMonth]
                                                     .add(_adjustedAmount);
        }

        if (_currentMonth < 5) {
            for (uint256 i = _currentMonth.add(1); i < 6; i++) {
                adjustedMonthlyDeposits[i] = adjustedMonthlyDeposits[i]
                                             .add(_adjustedAmount);
            }
        }

        //totalDepositedLP = totalDepositedLP.add(_amount);
        totalDepositedLPbyPairCode[_pairCode] = totalDepositedLPbyPairCode[_pairCode].add(_amount);
        totalLockedLP = totalLockedLP.add(_amount);

        if (block.timestamp <= programStartAt.add(DAY.mul(21))) {
            adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining.add(_adjustedAmount);
            stakers[_sender].depositNumberForEarlyBonus.push(_depositNumber);
        }
    }

    /**
     * @dev Updates funder profile when minting a new token to a funder
     */
    function _updateMint
    (
        address _originalOwner,
        uint256 _depositNumber,
        uint256 _LP,
        uint256 _pairCode,
        uint256 _volcieTokenID
    )
        internal
    {
        volcieTokens[_volcieTokenID].generation = getCurrentMonth();
        volcieTokens[_volcieTokenID].depositNumber = _depositNumber;
        volcieTokens[_volcieTokenID].LP = _LP;
        volcieTokens[_volcieTokenID].pairCode = _pairCode;
        volcieTokens[_volcieTokenID].lockedAt = now;
        volcieTokens[_volcieTokenID].originalOwner = _originalOwner;
    }

    /**
     * @param _sender address the address of the sender
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _KTY uint256 the amount of KittieFightToken
     * @param _SDAO uint256 the amount of SuperDaoToken
     * @param _LP uint256 the amount of Uniswap Liquidity tokens
     */
    function _updateWithdrawByBatchNumber
    (
        address _sender, uint256 _pairCode, uint256 _batchNumber,
        uint256 _LP, uint256 _KTY, uint256 _SDAO
    ) 
        private
    {
        // ========= update staker info =========
        // batch info
        uint256 adjustedLP = stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_batchNumber];
        stakers[_sender].batchLockedLPamount[_pairCode][_batchNumber] = 0;
        stakers[_sender].adjustedBatchLockedLPamount[_pairCode][_batchNumber] = 0;
        stakers[_sender].adjustedStartingLPamount[_pairCode][_batchNumber] = 0;
        stakers[_sender].batchLockedAt[_pairCode][_batchNumber] = 0;

        // all batches in pair code info
        stakers[_sender].totalLPlockedbyPairCode[_pairCode] = stakers[_sender].totalLPlockedbyPairCode[_pairCode].sub(_LP);

        // ========= update public variables =========
        totalRewardsKTYclaimed = totalRewardsKTYclaimed.add(_KTY);
        totalRewardsSDAOclaimed = totalRewardsSDAOclaimed.add(_SDAO);
        totalLockedLP = totalLockedLP.sub(_LP);

        uint256 _currentMonth = getCurrentMonth();

        if (_currentMonth < 5) {
            for (uint i = _currentMonth; i < 6; i++) {
                adjustedMonthlyDeposits[i] = adjustedMonthlyDeposits[i]
                                             .sub(adjustedLP);
            }
        }

        // if eligible for Early Mining Bonus but unstake before program end, deduct it from totalLockedLPinEarlyMining
        if (block.timestamp < programEndAt && isBatchEligibleForEarlyBonus(_sender, _batchNumber, _pairCode)) {
            adjustedTotalLockedLPinEarlyMining = adjustedTotalLockedLPinEarlyMining.sub(adjustedLP);
        }
    }

    /**
     * @dev Updates funder profile when an existing Ethie Token NFT is burnt
     * @param _burner address who burns this NFT
     * @param _volcieTokenID uint256 the ID of the burnt Ethie Token NFT
     */
    function _updateBurn
    (
        address _burner,
        uint256 _volcieTokenID,
        uint256 _ktyRewards,
        uint256 _sdaoRewards
    )
        internal
    {
        // set values to 0 can get gas refund
        volcieTokens[_volcieTokenID].LP = 0;
        volcieTokens[_volcieTokenID].lockedAt = 0;
        volcieTokens[_volcieTokenID].tokenBurnt = true;
        volcieTokens[_volcieTokenID].tokenBurntAt = now;
        volcieTokens[_volcieTokenID].tokenBurntBy = _burner;
        volcieTokens[_volcieTokenID].ktyRewards = _ktyRewards;
        volcieTokens[_volcieTokenID].sdaoRewards = _sdaoRewards;

        rewardsClaimed[_burner][0] = rewardsClaimed[_burner][0].add(_ktyRewards);
        rewardsClaimed[_burner][1] = rewardsClaimed[_burner][1].add(_sdaoRewards);
    }

    /**
     * @param _user address the address of the _user to whom the tokens are transferred
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @param _amountLP uint256 the amount of Uniswap Liquidity tokens to be transferred to the _user
     * @param _amountKTY uint256 the amount of KittieFightToken to be transferred to the _user
     * @param _amountSDAO uint256 the amount of SuperDaoToken to be transferred to the _user
     */
    function _transferTokens(address _user, uint256 _pairCode, uint256 _amountLP, uint256 _amountKTY, uint256 _amountSDAO)
        private
    {
        // transfer liquidity tokens
        require(IUniswapV2Pair(pairPoolsInfo[_pairCode]).transfer(_user, _amountLP), "Fail to transfer liquidity token");

        // transfer rewards
        require(kittieFightToken.transfer(_user, _amountKTY), "Fail to transfer KTY");
        require(superDaoToken.transfer(_user, _amountSDAO), "Fail to transfer SDAO");
    }

     /**
     * @dev Called by deposit(), pass values to generate Volcie Token NFT with all atrributes as listed in params
     * @param _to address who this Ethie Token NFT is minted to
     * @param _LPaddress address of the uniswap pair contract of which the LPs are 
     * @param _LPamount uint256 the amount of LPs associated with this NFT
     * @return uint256 ID of the LP Token NFT minted
     */
    function _mint
    (
        address _to,
        address _LPaddress,
        uint256 _LPamount
    )
        private
        returns (uint256)
    {
        return volcie.mint(_to, _LPaddress, _LPamount);
    }
}

contract YieldFarmingHelper is Ownable {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    YieldFarming public yieldFarming;
    YieldsCalculator public yieldsCalculator;

    address public ktyWethPair;
    address public daiWethPair;

    address public kittieFightTokenAddr;
    address public superDaoTokenAddr;
    address public wethAddr;
    address public daiAddr;

    uint256 constant public base18 = 1000000000000000000;
    uint256 constant public base6 = 1000000;

    uint256 constant public MONTH = 30 days;// 30 * 24 * 60 * 60;  // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 1 days;// 24 * 60 * 60;

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */

    function initialize
    (
        YieldFarming _yieldFarming,
        YieldsCalculator _yieldsCalculator,
        address _ktyWethPair,
        address _daiWethPair,
        address _kittieFightToken,
        address _superDaoToken,
        address _weth,
        address _dai
    ) 
        public initializer
    {
        Ownable.initialize(_msgSender());
        setYieldFarming(_yieldFarming);
        setYieldsCalculator(_yieldsCalculator);
        setKtyWethPair(_ktyWethPair);
        setDaiWethPair(_daiWethPair);
        setRwardsTokenAddress(_kittieFightToken, true);
        setRwardsTokenAddress(_superDaoToken, false);
        setWethAddress(_weth);
        setDaiAddress(_dai);
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarming(YieldFarming _yieldFarming) public onlyOwner {
        yieldFarming = _yieldFarming;
    }

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldsCalculator(YieldsCalculator _yieldsCalculator) public onlyOwner {
        yieldsCalculator= _yieldsCalculator;
    }

    /**
     * @dev Set Uniswap KTY-Weth Pair contract address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setKtyWethPair(address _ktyWethPair) public onlyOwner {
        ktyWethPair = _ktyWethPair;
    }

    /**
     * @dev Set Uniswap Dai-Weth Pair contract address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setDaiWethPair(address _daiWethPair) public onlyOwner {
        daiWethPair = _daiWethPair;
    }

    /**
     * @dev Set tokens address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setRwardsTokenAddress(address _rewardToken, bool forKTY) public onlyOwner {
        if (forKTY) {
            kittieFightTokenAddr = _rewardToken;
        } else {
            superDaoTokenAddr = _rewardToken;
        }        
    }

    /**
     * @dev Set Weth contract address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setWethAddress(address _weth) public onlyOwner {
        wethAddr = _weth;
    }

    /**
     * @dev Set Dai contract address
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setDaiAddress(address _dai) public onlyOwner {
        daiAddr = _dai;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    // Getters YieldFarming

    /**
     * @return KTY reserves and the total supply of LPs from a uniswap pair contract associated with a
              pair code in Yield Farming.
     */
    function getLPinfo(uint256 _pairCode)
        public view returns (uint256 reserveKTY, uint256 totalSupplyLP) 
    {
        (,address pairPoolAddress, address _tokenAddr) = yieldFarming.getPairPool(_pairCode);
        (reserveKTY,) = getReserve(kittieFightTokenAddr, _tokenAddr, pairPoolAddress);
        totalSupplyLP = IUniswapV2Pair(pairPoolAddress).totalSupply();
    }

    /**
     * @return returns the LP “Bubble Factor” of LP from a uniswap pair contract associate with a pair code. 
     * @dev calculation is based on formula: LP1 / LP =  (T1 x R) / (T x R1)
     * @dev returned value is amplified 1000000 times to avoid float imprecision
     */
    function bubbleFactor(uint256 _pairCode) external view returns (uint256)
    {
        (uint256 reserveKTY, uint256 totalSupply) = getLPinfo(0);
        (uint256 reserveKTY_1, uint256 totalSupply_1) = getLPinfo(_pairCode);

        uint256 factor = totalSupply_1.mul(reserveKTY).mul(base6).div(totalSupply.mul(reserveKTY_1));
        return factor;
    }

    /**
     * @return true and 0 if now is pay day, false if now is not pay day and the time until next pay day
     * @dev Pay Day is the first day of each month, starting from the second month.
     * @dev After program ends, every day is Pay Day.
     */
    function isPayDay()
        public view
        returns (bool, uint256)
    {
        uint256 month1StartTime = yieldFarming.getMonthStartAt(1);
        if (block.timestamp < month1StartTime) {
            return (false, month1StartTime.sub(block.timestamp));
        }
        if (block.timestamp >= yieldFarming.programEndAt()) {
            return (true, 0);
        }
        uint256 currentMonth = yieldFarming.getCurrentMonth();
        if (block.timestamp >= yieldFarming.getMonthStartAt(currentMonth)
            && block.timestamp <= yieldFarming.getMonthStartAt(currentMonth).add(DAY)) {
            return (true, 0);
        }
        if (block.timestamp > yieldFarming.getMonthStartAt(currentMonth).add(DAY)) {
            uint256 nextPayDay = yieldFarming.getMonthStartAt(currentMonth.add(1));
            return (false, nextPayDay.sub(block.timestamp));
        }
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens locked in this contract
     */
    function getTotalLiquidityTokenLocked() external view returns (uint256) {
        return yieldFarming.totalLockedLP();
    }

    /**
     * @return uint256 the total locked LPs in Yield Farming in DAI value
     */
    function totalLockedLPinDAI() external view returns (uint256) {
        uint256 _totalLockedLPinDAI = 0;
        uint256 _LPinDai;
        uint256 totalNumberOfPairPools = yieldFarming.totalNumberOfPairPools();
        for (uint256 i = 0; i < totalNumberOfPairPools; i++) {
            _LPinDai = getTotalLiquidityTokenLockedInDAI(i);
            _totalLockedLPinDAI = _totalLockedLPinDAI.add(_LPinDai);
        }

        return _totalLockedLPinDAI;
    }

    /**
     * @return bool true if this _staker has made any deposit, false if this _staker has no deposit
     * @return uint256 the deposit number for this _staker associated with the _batchNumber and _pairCode
     */
    function getDepositNumber(address _staker, uint256 _pairCode, uint256 _batchNumber)
        external view returns (bool, uint256)
    {
        uint256 _pair;
        uint256 _batch;

        uint256 _totalDeposits = yieldFarming.getNumberOfDeposits(_staker);
        if (_totalDeposits == 0) {
            return (false, 0);
        }
        for (uint256 i = 0; i < _totalDeposits; i++) {
            (_pair, _batch) = yieldFarming.getBatchNumberAndPairCode(_staker, i);
            if (_pair == _pairCode && _batch == _batchNumber) {
                return (true, i);
            }
        }
    }

    /**
     * @return A staker's total LPs locked associated with a pair code, qualifying for claiming early bonus, and its values adjusted
     *         to the LP “Bubble Factor”.
     */
    function totalLPforEarlyBonusPerPairCode(address _staker, uint256 _pairCode)
        public view returns (uint256, uint256) {
        uint256[] memory depositsEarlyBonus = yieldFarming.getDepositsForEarlyBonus(_staker);
        uint256 totalLPEarlyBonus = 0;
        uint256 adjustedTotalLPEarlyBonus = 0;
        uint256 depositNum;
        uint256 batchNum;
        uint256 pairCode;
        uint256 lockTime;
        uint256 lockedLP;
        uint256 adjustedLockedLP;
        for (uint256 i = 0; i < depositsEarlyBonus.length; i++) {
            depositNum = depositsEarlyBonus[i];
            (pairCode, batchNum) = yieldFarming.getBatchNumberAndPairCode(_staker, depositNum);
            (lockedLP,adjustedLockedLP,, lockTime) = yieldFarming.getLPinBatch(_staker, pairCode, batchNum);
            if (pairCode == _pairCode && lockTime > 0 && lockedLP > 0) {
                totalLPEarlyBonus = totalLPEarlyBonus.add(lockedLP);
                adjustedTotalLPEarlyBonus = adjustedTotalLPEarlyBonus.add(adjustedLockedLP);
            }
        }

        return (totalLPEarlyBonus, adjustedTotalLPEarlyBonus);
    }

    /**
     * @return A staker's total LPs locked qualifying for claiming early bonus, and its values adjusted
     *         to the LP “Bubble Factor”.
     */
    function totalLPforEarlyBonus(address _staker) public view returns (uint256, uint256) {
        uint256[] memory _depositsEarlyBonus = yieldFarming.getDepositsForEarlyBonus(_staker);
        if (_depositsEarlyBonus.length == 0) {
            return (0, 0);
        }
        uint256 _totalLPEarlyBonus = 0;
        uint256 _adjustedTotalLPEarlyBonus = 0;
        uint256 _depositNum;
        uint256 _batchNum;
        uint256 _pair;
        uint256 lockTime;
        uint256 lockedLP;
        uint256 adjustedLockedLP;
        for (uint256 i = 0; i < _depositsEarlyBonus.length; i++) {
            _depositNum = _depositsEarlyBonus[i];
            (_pair, _batchNum) = yieldFarming.getBatchNumberAndPairCode(_staker, _depositNum);
            (lockedLP,adjustedLockedLP,, lockTime) = yieldFarming.getLPinBatch(_staker, _pair, _batchNum);
            if (lockTime > 0 && lockedLP > 0) {
                _totalLPEarlyBonus = _totalLPEarlyBonus.add(lockedLP);
                _adjustedTotalLPEarlyBonus = _adjustedTotalLPEarlyBonus.add(adjustedLockedLP);
            }
        }

        return (_totalLPEarlyBonus, _adjustedTotalLPEarlyBonus);
    }

    /**
     * @return uint256, uint256 a staker's total early bonus (KTY and SDAO) he/she has accrued.
     */
    function getTotalEarlyBonus(address _staker) external view returns (uint256, uint256) {
        (, uint256 totalEarlyLP) = totalLPforEarlyBonus(_staker);
        uint256 earlyBonus = yieldsCalculator.getEarlyBonus(totalEarlyLP);
        // early bonus for KTY is the same amount as early bonus for SDAO
        return (earlyBonus, earlyBonus);
    }

    /**
     * @return uint256 the total amount of KittieFightToken that have been claimed
     * @return uint256 the total amount of SuperDaoToken that have been claimed
     */
    function getTotalRewardsClaimed() external view returns (uint256, uint256) {
        uint256 totalKTYclaimed = yieldFarming.totalRewardsKTYclaimed();
        uint256 totalSDAOclaimed = yieldFarming.totalRewardsSDAOclaimed();
        return (totalKTYclaimed, totalSDAOclaimed);
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards
     * @return uint256 the total amount of SuperDaoFightToken rewards
     */
    function getTotalRewards() public view returns (uint256, uint256) {
        uint256 rewardsKTY = yieldFarming.totalRewardsKTY();
        uint256 rewardsSDAO = yieldFarming.totalRewardsSDAO();
        return (rewardsKTY, rewardsSDAO);
    }

    /**
     * @return uint256 the total amount of Uniswap Liquidity tokens deposited
     *         including both locked tokens and withdrawn tokens
     */
    function getTotalDeposits() public view returns (uint256) {
        uint256 totalPools = yieldFarming.totalNumberOfPairPools();
        uint256 totalDeposits = 0;
        uint256 deposits;
        for (uint256 i = 0; i < totalPools; i++) {
            deposits = yieldFarming.getTotalDepositsPerPairCode(i);
            totalDeposits = totalDeposits.add(deposits);
        }
        return totalDeposits;
    }

    /**
     * @return uint256 the dai value of the total amount of Uniswap Liquidity tokens deposited 
     *         including both locked tokens and withdrawn tokens 
     */
    function getTotalDepositsInDai() external view returns (uint256) {
        uint256 totalPools = yieldFarming.totalNumberOfPairPools();
        uint256 totalDepositsInDai = 0;
        uint256 deposits;
        uint256 depositsInDai;
        for (uint256 i = 0; i < totalPools; i++) {
            deposits = yieldFarming.getTotalDepositsPerPairCode(i);
            depositsInDai = deposits > 0 ? getLPvalueInDai(i, deposits) : 0;
            totalDepositsInDai = totalDepositsInDai.add(depositsInDai);
        }
        return totalDepositsInDai;
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards yet to be distributed
     * @return uint256 the total amount of SuperDaoFightToken rewards yet to be distributed
     */
    function getLockedRewards() public view returns (uint256, uint256) {
        (uint256 totalRewardsKTY, uint256 totalRewardsSDAO) = getTotalRewards();
        (uint256 unlockedKTY, uint256 unlockedSDAO) = getUnlockedRewards();
        uint256 lockedKTY = totalRewardsKTY.sub(unlockedKTY);
        uint256 lockedSDAO = totalRewardsSDAO.sub(unlockedSDAO);
        return (lockedKTY, lockedSDAO);
    }

    /**
     * @return uint256 the total amount of KittieFightToken rewards already distributed
     * @return uint256 the total amount of SuperDaoFightToken rewards already distributed
     */
    function getUnlockedRewards() public view returns (uint256, uint256) {
        uint256 unlockedKTY = IERC20(kittieFightTokenAddr).balanceOf(address(yieldFarming));
        uint256 unlockedSDAO = IERC20(superDaoTokenAddr).balanceOf(address(yieldFarming));
        return (unlockedKTY, unlockedSDAO);
    }

    /**
     * @dev get info on program duration and month
     */
    function getProgramDuration() external view 
    returns
    (
        uint256 entireProgramDuration,
        uint256 monthDuration,
        uint256 startMonth,
        uint256 endMonth,
        uint256 currentMonth,
        uint256 daysLeft,
        uint256 elapsedMonths
    ) 
    {
        uint256 currentDay = yieldsCalculator.getCurrentDay();
        entireProgramDuration = yieldFarming.programDuration();
        monthDuration = yieldFarming.MONTH();
        startMonth = 0;
        endMonth = 5;
        currentMonth = yieldFarming.getCurrentMonth();
        daysLeft = currentDay >= 180 ? 0 : 180 - currentDay;
        elapsedMonths = currentMonth == 0 ? 0 : currentMonth;
    }

     /**
     * @return uint256 the amount of total Rewards for KittieFightToken for early mining bonnus
     * @return uint256 the amount of total Rewards for SuperDaoToken for early mining bonnus
     */
    function getTotalEarlyMiningBonus() external view returns (uint256, uint256) {
        // early mining bonus is the same amount in KTY and SDAO
        return (yieldFarming.EARLY_MINING_BONUS(), yieldFarming.EARLY_MINING_BONUS());
    }

    /**
     * @return uint256 the amount of locked liquidity tokens,
     *         and its adjusted amount, and when this deposit was made,
     *         in a deposit of a staker assocaited with _depositNumber
     */
    function getLockedLPinDeposit(address _staker, uint256 _depositNumber)
        external view returns (uint256, uint256, uint256)
    {
        (uint256 _pairCode, uint256 _batchNumber) = yieldFarming.getBatchNumberAndPairCode(_staker, _depositNumber); 
        (uint256 _LP, uint256 _adjustedLP,, uint256 _lockTime) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
        return (_LP, _adjustedLP, _lockTime);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit the staker wishes to see the locked amount
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return bool true if the batch with the _batchNumber in the _pairCode of the _staker is a valid batch, false if it is non-valid.
     * @dev    A valid batch is a batch which has locked Liquidity tokens in it. 
     * @dev    A non-valid batch is an empty batch which has no Liquidity tokens in it.
     */
    function isBatchValid(address _staker, uint256 _pairCode, uint256 _batchNumber)
        public view returns (bool)
    {
        (uint256 _LP,,,) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
        return _LP > 0;
    }

    /**
     * @return uint256 DAI value representation of ETH in uniswap KTY - ETH pool, according to 
     *         all Liquidity tokens locked in this contract.
     */
    function getTotalLiquidityTokenLockedInDAI(uint256 _pairCode) public view returns (uint256) {
        (,address pairPoolAddress,) = yieldFarming.getPairPool(_pairCode);
        uint256 balance = IUniswapV2Pair(pairPoolAddress).balanceOf(address(yieldFarming));
        uint256 totalSupply = IUniswapV2Pair(pairPoolAddress).totalSupply();
        uint256 percentLPinYieldFarm = balance.mul(base18).div(totalSupply);
        
        uint256 totalKtyInPairPool = IERC20(kittieFightTokenAddr).balanceOf(pairPoolAddress);

        return totalKtyInPairPool.mul(2).mul(percentLPinYieldFarm).mul(KTY_DAI_price())
               .div(base18).div(base18);
    }

    /**
     * @param _pairCode uint256 the pair code of which the LPs are 
     * @param _LP uint256 the amount of LPs
     * @return uint256 DAI value of the amount LPs which are from a pair pool associated with the pair code
     * @dev the calculations is as below:
     *      For example, if I have 1 of 1000 LP of KTY-WETH, and there is total 10000 KTY and 300 ETH 
     *      staked in this pair, then 1 have 10 KTY + 0.3 ETH. And that is equal to 20 KTY or 0.6 ETH total.
     */
    function getLPvalueInDai(uint256 _pairCode, uint256 _LP) public view returns (uint256) {
        (,address pairPoolAddress,) = yieldFarming.getPairPool(_pairCode);
    
        uint256 totalSupply = IUniswapV2Pair(pairPoolAddress).totalSupply();
        uint256 percentLPinYieldFarm = _LP.mul(base18).div(totalSupply);
        
        uint256 totalKtyInPairPool = IERC20(kittieFightTokenAddr).balanceOf(pairPoolAddress);

        return totalKtyInPairPool.mul(2).mul(percentLPinYieldFarm).mul(KTY_DAI_price())
               .div(base18).div(base18);
    }

    function getWalletBalance(address _staker, uint256 _pairCode) external view returns (uint256) {
        (,address pairPoolAddress,) = yieldFarming.getPairPool(_pairCode);
        return IUniswapV2Pair(pairPoolAddress).balanceOf(_staker);
    }

    function isProgramActive() external view returns (bool) {
        return block.timestamp >= yieldFarming.programStartAt() && block.timestamp <= yieldFarming.programEndAt();
    }

    // Getters Uniswap

    /**
     * @dev returns the amount of reserves for the two tokens in uniswap pair contract.
     */
    function getReserve(address _tokenA, address _tokenB, address _pairPool)
        public view returns (uint256 reserveA, uint256 reserveB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairPool);
        address token0 = pair.token0();
        if (token0 == _tokenA) {
            (reserveA,,) = pair.getReserves();
            (,reserveB,) = pair.getReserves();
        } else if (token0 == _tokenB) {
            (,reserveA,) = pair.getReserves();
            (reserveB,,) = pair.getReserves();
        }
    }

    /**
     * @dev returns the KTY to ether price on uniswap, that is, how many ether for 1 KTY
     */
    function KTY_ETH_price() public view returns (uint256) {
        uint256 _amountKTY = 1e18;  // 1 KTY
        (uint256 _reserveKTY, uint256 _reserveETH) = getReserve(kittieFightTokenAddr, wethAddr, ktyWethPair);
        return UniswapV2Library.getAmountIn(_amountKTY, _reserveETH, _reserveKTY);
    } 

    /**
     * @dev returns the ether KTY price on uniswap, that is, how many KTYs for 1 ether
     */
    function ETH_KTY_price() public view returns (uint256) {
        uint256 _amountETH = 1e18;  // 1 KTY
        (uint256 _reserveKTY, uint256 _reserveETH) = getReserve(kittieFightTokenAddr, wethAddr, ktyWethPair);
        return UniswapV2Library.getAmountIn(_amountETH, _reserveKTY, _reserveETH);
    }

    /**
     * @dev returns the DAI to ether price on uniswap, that is, how many ether for 1 DAI
     */
    function DAI_ETH_price() public view returns (uint256) {
        uint256 _amountDAI = 1e18;  // 1 KTY
        (uint256 _reserveDAI, uint256 _reserveETH) = getReserve(daiAddr, wethAddr, daiWethPair);
        return UniswapV2Library.getAmountIn(_amountDAI, _reserveETH, _reserveDAI);
    }

    /**
     * @dev returns the ether to DAI price on uniswap, that is, how many DAI for 1 ether
     */
    function ETH_DAI_price() public view returns (uint256) {
        uint256 _amountETH = 1e18;  // 1 KTY
        (uint256 _reserveDAI, uint256 _reserveETH) = getReserve(daiAddr, wethAddr, daiWethPair);
        return UniswapV2Library.getAmountIn(_amountETH, _reserveDAI, _reserveETH);
    }

    /**
     * @dev returns the KTY to DAI price derived from uniswap price in pair contracts, that is, how many DAI for 1 KTY
     */
    function KTY_DAI_price() public view returns (uint256) {
        // get the amount of ethers for 1 KTY
        uint256 etherPerKTY = KTY_ETH_price();
        // get the amount of DAI for 1 ether
        uint256 daiPerEther = ETH_DAI_price();
        // get the amount of DAI for 1 KTY
        uint256 daiPerKTY = etherPerKTY.mul(daiPerEther).div(base18);
        return daiPerKTY;
    }

    /**
     * @dev returns the DAI to KTY price derived from uniswap price in pair contracts, that is, how many KTY for 1 DAI
     */
    function DAI_KTY_price() public view returns (uint256) {
        // get the amount of ethers for 1 DAI
        uint256 etherPerDAI = DAI_ETH_price();
        // get the amount of KTY for 1 ether
        uint256 ktyPerEther = ETH_KTY_price();
        // get the amount of KTY for 1 DAI
        uint256 ktyPerDAI = etherPerDAI.mul(ktyPerEther).div(base18);
        return ktyPerDAI;
    }
   
}
contract YieldsCalculator is Ownable {
    using SafeMath for uint256;

    /*                                               GENERAL VARIABLES                                                */
    /* ============================================================================================================== */

    YieldFarming public yieldFarming;
    YieldFarmingHelper public yieldFarmingHelper;
    IVolcieToken public volcie;                                           // VolcieToken contract

    uint256 constant public base18 = 1000000000000000000;
    uint256 constant public base6 = 1000000;

    uint256 constant public MONTH = 30 days;// 30 * 24 * 60 * 60;  // MONTH duration is 30 days, to keep things standard
    uint256 constant public DAY = 1 days;// 24 * 60 * 60;
    uint256 constant DAILY_PORTION_IN_MONTH = 33333;

    // proportionate a month over days
    uint256 constant public monthDays = MONTH / DAY;

    // total amount of KTY sold
    uint256 internal tokensSold;

    /*                                                   INITIALIZER                                                  */
    /* ============================================================================================================== */

    function initialize
    (
        uint256 _tokensSold,
        YieldFarming _yieldFarming,
        YieldFarmingHelper _yieldFarmingHelper,
        IVolcieToken _volcie
    ) 
        public initializer
    {
        Ownable.initialize(_msgSender());
        tokensSold = _tokensSold;
        setYieldFarming(_yieldFarming);
        setYieldFarmingHelper(_yieldFarmingHelper);
        setVolcieToken(_volcie);
    }

    /*                                                 SETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarming(YieldFarming _yieldFarming) public onlyOwner {
        yieldFarming = _yieldFarming;
    }

    /**
     * @dev Set Uniswap KTY-Weth Pair contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setYieldFarmingHelper(YieldFarmingHelper _yieldFarmingHelper) public onlyOwner {
        yieldFarmingHelper = _yieldFarmingHelper;
    }

    /**
     * @dev Set VOLCIE contract
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setVolcieToken(IVolcieToken _volcie) public onlyOwner {
        volcie = _volcie;
    }

    /**
     * @dev Set the amount of tokens sold on private sales
     * @dev This function can only be carreid out by the owner of this contract.
     */
    function setTokensSold(uint256 _tokensSold) public onlyOwner {
        tokensSold = _tokensSold;
    }

    /*                                                 GETTER FUNCTIONS                                               */
    /* ============================================================================================================== */

    /**
     * @param _time uint256 The time point for which the month number is enquired
     * @return uint256 the month in which the time point _time is
     */
    function getMonth(uint256 _time) public view returns (uint256) {
        uint256 month;
        uint256 monthStartTime;

        for (uint256 i = 5; i >= 0; i--) {
            monthStartTime = yieldFarming.getMonthStartAt(i);
            if (_time >= monthStartTime) {
                month = i;
                break;
            }
        }
        return month;
    }

    /**
     * @param _time uint256 The time point for which the day number is enquired
     * @return uint256 the day in which the time point _time is
     */
    function getDay(uint256 _time) public view returns (uint256) {
        uint256 _programStartAt = yieldFarming.programStartAt();
        if (_time <= _programStartAt) {
            return 0;
        }
        uint256 elapsedTime = _time.sub(_programStartAt);
        return elapsedTime.div(DAY);
    }

    /**
     * @dev Get the starting month, ending month, and days in starting month during which the locked Liquidity
     *      tokens in _staker's _batchNumber associated with _pairCode are locked and eligible for rewards.
     * @dev The ending month is the month preceding the current month.
     */
    function getLockedPeriod(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view
        returns (
            uint256 _startingMonth,
            uint256 _endingMonth,
            uint256 _daysInStartMonth
        )
    {
        uint256 _currentMonth = yieldFarming.getCurrentMonth();
        (,,,uint256 _lockedAt) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
        uint256 _startingDay = getDay(_lockedAt);
        uint256 _programEndAt = yieldFarming.programEndAt();

        _startingMonth = getMonth(_lockedAt); 
        _endingMonth = _currentMonth == 0 ? 0 : block.timestamp > _programEndAt ? 5 : _currentMonth.sub(1);
        _daysInStartMonth = 30 - getElapsedDaysInMonth(_startingDay, _startingMonth);
    }

    /**
     * @return unit256 the current day
     * @dev    There are 180 days in this program in total, starting from day 0 to day 179.
     */
    function getCurrentDay() public view returns (uint256) {
        uint256 programStartTime = yieldFarming.programStartAt();
        if (block.timestamp <= programStartTime) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp.sub(programStartTime);
        uint256 currentDay = elapsedTime.div(DAY);
        return currentDay;
    }

    /**
     * @param _days uint256 which day since this program starts
     * @param _month uint256 which month since this program starts
     * @return unit256 the number of days that have elapsed in this _month
     */
    function getElapsedDaysInMonth(uint256 _days, uint256 _month) public view returns (uint256) {
        // In the first month
        if (_month == 0) {
            return _days;
        }

        // In the other months
        // Get the unix time for _days
        uint256 month0StartTime = yieldFarming.getMonthStartAt(0);
        uint256 dayInUnix = _days.mul(DAY).add(month0StartTime);
        // If _days are before the start of _month, then no day has been elapsed
        uint256 monthStartTime = yieldFarming.getMonthStartAt(_month);
        if (dayInUnix <= monthStartTime) {
            return 0;
        }
        // get time elapsed in seconds
        uint256 timeElapsed = dayInUnix.sub(monthStartTime);
        return timeElapsed.div(DAY);
    }

     /**
     * @return unit256 time in seconds until the current month ends
     */
    function timeUntilCurrentMonthEnd() public view returns (uint) {
        uint256 nextMonth = yieldFarming.getCurrentMonth().add(1);
        if (nextMonth > 5) {
            if (block.timestamp >= yieldFarming.getMonthStartAt(5).add(MONTH)) {
                return 0;
            }
            return MONTH.sub(block.timestamp.sub(yieldFarming.getMonthStartAt(5)));
        }
        return yieldFarming.getMonthStartAt(nextMonth).sub(block.timestamp);
    }

    function calculateYields2(address _staker, uint256 _pairCode, uint256 startBatchNumber, uint256 lockedLP, uint256 startingLP)
        internal view
        returns (uint256 yieldsKTY, uint256 yieldsSDAO) {
        (uint256 _startingMonth, uint256 _endingMonth,) = getLockedPeriod(_staker, startBatchNumber, _pairCode);
        return calculateYields(_startingMonth, _endingMonth, lockedLP, startingLP);
    }

    /**
     * @return unit256, uint256 the KTY and SDAO rewards calculated based on starting month, ending month,
               locked LP, and starting LP.
     */
    function calculateYields(uint256 startMonth, uint256 endMonth, uint256 lockedLP, uint256 startingLP)
        internal view
        returns (uint256 yieldsKTY, uint256 yieldsSDAO)
    {
        (uint256 yields_part_1_KTY, uint256 yields_part_1_SDAO) = calculateYields_part_1(startMonth, startingLP);
        uint256 yields_part_2_KTY;
        uint256 yields_part_2_SDAO;
        if (endMonth > startMonth) {
            (yields_part_2_KTY, yields_part_2_SDAO) = calculateYields_part_2(startMonth, endMonth, lockedLP);
        }        
        return (yields_part_1_KTY.add(yields_part_2_KTY), yields_part_1_SDAO.add(yields_part_2_SDAO));
    }

    /**
     * @return unit256, uint256 the KTY and SDAO rewards for the starting month, which are calculated based on
               starting month, and starting LP.
     */
    function calculateYields_part_1(uint256 startMonth, uint256 startingLP)
        internal view
        returns (uint256 yields_part_1_KTY, uint256 yields_part_1_SDAO)
    {
        // yields KTY in startMonth
        uint256 rewardsKTYstartMonth = getTotalKTYRewardsByMonth(startMonth);
        uint256 rewardsSDAOstartMonth = getTotalSDAORewardsByMonth(startMonth);
        uint256 adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(startMonth);

        yields_part_1_KTY = rewardsKTYstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
        yields_part_1_SDAO = rewardsSDAOstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
    }

    /**
     * @return unit256, uint256 the KTY and SDAO rewards in the months following the starting month until the end month,
               calculated based on starting month, ending month, and locked LP
     */
    function calculateYields_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP)
        internal view
        returns (uint256 yields_part_2_KTY, uint256 yields_part_2_SDAO)
    {
        uint256 adjustedMonthlyDeposit;
        // yields KTY in endMonth and other month between startMonth and endMonth
        for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
            uint256 monthlyRewardsKTY = getTotalKTYRewardsByMonth(i);
            uint256 monthlyRewardsSDAO = getTotalSDAORewardsByMonth(i);
            adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(i);
            yields_part_2_KTY = yields_part_2_KTY.add(monthlyRewardsKTY.mul(lockedLP).div(adjustedMonthlyDeposit));
            yields_part_2_SDAO = yields_part_2_SDAO.add(monthlyRewardsSDAO.mul(lockedLP).div(adjustedMonthlyDeposit));
        }
         
    }

    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the batch number of deposits
     *         made by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _batchNumber the batch number of the deposis made by _staker
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool in this batch
     * @return unit256 the amount of KittieFightToken rewards associated with the _batchNumber of this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _batchNumber of this _staker
     */
    function calculateRewardsByBatchNumber(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view
        returns (uint256, uint256)
    {
        uint256 rewardKTY;
        uint256 rewardSDAO;

        // If the batch is locked less than 30 days, rewards are 0.
        if (!isBatchEligibleForRewards(_staker, _batchNumber, _pairCode)) {
            return(0, 0);
        }

        (,uint256 adjustedLockedLP, uint256 adjustedStartingLP,) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);

        // calculate KittieFightToken rewards
        (rewardKTY, rewardSDAO) = calculateYields2(_staker, _pairCode, _batchNumber, adjustedLockedLP, adjustedStartingLP);

        // If the program ends
        if (block.timestamp >= yieldFarming.programEndAt()) {
            // if eligible for Early Mining Bonus, add the rewards for early bonus
            if (yieldFarming.isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode)) {
                uint256 _earlyBonus = getEarlyBonus(adjustedLockedLP);
                rewardKTY = rewardKTY.add(_earlyBonus);
                rewardSDAO = rewardSDAO.add(_earlyBonus);
            }
        }

        return (rewardKTY, rewardSDAO);
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _batchNumber uint256 the batch number of which deposit 
     * @param _pairCode uint256 Pair Code assocated with a Pair Pool 
     * @return bool true if the batch with the _batchNumber in the _pairCode of the _staker is eligible for claiming yields, false if it is not eligible.
     * @dev    A batch needs to be locked for at least 30 days to be eligible for claiming yields.
     * @dev    A batch locked for less than 30 days has 0 rewards
     */
    function isBatchEligibleForRewards(address _staker, uint256 _batchNumber, uint256 _pairCode)
        public view returns (bool)
    {
        // get locked time
        (,,,uint256 lockedAt) = yieldFarming.getLPinBatch(_staker, _pairCode, _batchNumber);
      
        if (lockedAt == 0) {
            return false;
        }
        // get total locked duration
        uint256 lockedPeriod = block.timestamp.sub(lockedAt);
        // a minimum of 30 days of staking is required to be eligible for claiming rewards
        if (lockedPeriod >= MONTH) {
            return true;
        }
        return false;
    }

    /**
     * @param _staker address the staker who has deposited Uniswap Liquidity tokens
     * @param _depositNumber uint256 the deposit number of which deposit 
     * @dev    A deposit needs to be locked for at least 30 days to be eligible for claiming yields.
     * @dev    A deposit locked for less than 30 days has 0 rewards
     */
    function isDepositEligibleForEarlyBonus(address _staker, uint256 _depositNumber)
        public view returns (bool)
    {
        (uint256 _pairCode, uint256 _batchNumber) = yieldFarming.getBatchNumberAndPairCode(_staker, _depositNumber); 
        return yieldFarming.isBatchEligibleForEarlyBonus(_staker, _batchNumber, _pairCode);
    }

    /**
     * @param _volcieID uint256 the ID of the Volcie Token
     * @dev    A Volcie Token needs to have its associated LP locked for at least 30 days to be eligible 
     *         for claiming yields.
     */
    function isVolcieEligibleForEarlyBonus(uint256 _volcieID)
        external view returns (bool)
    {
         (address _originalOwner, uint256 _depositNumber,,,,,,,,) = yieldFarming.getVolcieToken(_volcieID);
         return isDepositEligibleForEarlyBonus(_originalOwner, _depositNumber);
    }

    /**
     * @return two arrays, the first array contains the monthly KTY rewards for the 6 months, 
     *         and the second array contains the monthly SDAO rewards for the 6 months, respectively.
     */
    function getTotalRewards()
        external view
       returns (uint256[6] memory ktyRewards, uint256[6] memory sdaoRewards)
    {
        uint256 _ktyReward;
        uint256 _sdaoReward;
        for (uint256 i = 0; i < 6; i++) {
            _ktyReward = getTotalKTYRewardsByMonth(i);
            _sdaoReward = getTotalSDAORewardsByMonth(i);
            ktyRewards[i] = _ktyReward;
            sdaoRewards[i] = _sdaoReward;
        }
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the amount of total Rewards for KittieFightToken for the _month
     */
    function getTotalKTYRewardsByMonth(uint256 _month)
        public view 
        returns (uint256)
    {
        uint256 _totalRewardsKTY = yieldFarming.totalRewardsKTY();
        (uint256 _KTYunlockRate,) = yieldFarming.getRewardUnlockRateByMonth(_month);
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        return (_totalRewardsKTY.sub(_earlyBonus)).mul(_KTYunlockRate).div(base6);
    }

    /**
     * @param _month uint256 the month (from 0 to 5) for which the Reward Unlock Rate is returned
     * @return uint256 the amount of total Rewards for SuperDaoToken for the _month
     */
    function getTotalSDAORewardsByMonth(uint256 _month)
        public view 
        returns (uint256)
    {
        uint256 _totalRewardsSDAO = yieldFarming.totalRewardsSDAO();
        (,uint256 _SDAOunlockRate) = yieldFarming.getRewardUnlockRateByMonth(_month);
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        return (_totalRewardsSDAO.sub(_earlyBonus)).mul(_SDAOunlockRate).div(base6);
    }

    /**
     * @param _amountLP the amount of locked Liquidity token eligible for claiming early bonus
     * @return uint256 the amount of early bonus for this _staker. Since the amount of early bonus is the same
     *         for KittieFightToken and SuperDaoToken, only one number is returned.
     * @dev    KTY early bonus of the returned value and SDAO early bonus of the returned value are the early bonus accrued for the _amountLP
     */
    function getEarlyBonus(uint256 _amountLP)
        public view returns (uint256)
    {
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        uint256 _adjustedTotalLockedLPinEarlyMining = yieldFarming.adjustedTotalLockedLPinEarlyMining();
    
        return _amountLP.mul(_earlyBonus).div(_adjustedTotalLockedLPinEarlyMining);
    }

    /**
     * @param _volcieID the ID of the Volcie token eligible for claiming early bonus
     * @return uint256 the amount of early bonus for this volcie token. Since the amount of early bonus is the same
     *         for KittieFightToken and SuperDaoToken, only one number is returned.
     * @dev    KTY early bonus of the returned value and SDAO early bonus of the returned value are the early bonus accrued for the volcie token
     */
    function getEarlyBonusForVolcie(uint256 _volcieID) external view returns (uint256) {
        (,,,uint256 _LP,,,,,,) = yieldFarming.getVolcieToken(_volcieID);
        return getEarlyBonus(_LP);
    }

    /**
     * @notice Calculate the rewards (KittieFightToken and SuperDaoToken) by the deposit number of the deposit
     *         made by a staker
     * @param _staker address the address of the staker for whom the rewards are calculated
     * @param _depositNumber the deposit number of the deposits made by _staker
     * @return unit256 the amount of KittieFightToken rewards associated with the _depositNumber of this _staker
     * @return unit256 the amount of SuperDaoToken rewards associated with the _depositNumber of this _staker
     */
    function calculateRewardsByDepositNumber(address _staker, uint256 _depositNumber)
        public view
        returns (uint256, uint256)
    {
        (uint256 _pairCode, uint256 _batchNumber) = yieldFarming.getBatchNumberAndPairCode(_staker, _depositNumber); 
        (uint256 _rewardKTY, uint256 _rewardSDAO) = calculateRewardsByBatchNumber(_staker, _batchNumber, _pairCode);
        return (_rewardKTY, _rewardSDAO);
    }

    function getTotalLPsLocked(address _staker) public view returns (uint256) {
        uint256 _totalPools = yieldFarming.totalNumberOfPairPools();
        uint256 _totalLPs;
        uint256 _LP;
        for (uint256 i = 0; i < _totalPools; i++) {
            _LP = yieldFarming.getLockedLPbyPairCode(_staker, i);
            _totalLPs = _totalLPs.add(_LP);
        }
        return _totalLPs;
    }

    /**
     * This should actually take users address as parameter to check total LP tokens locked.
       Its same as apy for individual but in number form, i.e Total tokens allocated in the duration
       of the yield farming program, divided by estimated personal allocation based on How much the
       total personal lp tokens locked
     * @return uint256 the Reward Multiplier for KittieFightToken, amplified 1000000 times to avoid float imprecision
     * @return uint256 the Reward Multiplier for SuperDaoFightToken, amplified 1000000 times to avoid float imprecision
     */
    function getRewardMultipliers(address _staker) external view returns (uint256, uint256) {
        uint256 totalLPs = getTotalLPsLocked(_staker);
        if (totalLPs == 0) {
            return (0, 0);
        }
        uint256 totalRewards = yieldFarming.totalRewardsKTY();
        (uint256 rewardsKTY, uint256 rewardsSDAO) = getRewardsToClaim(_staker);
        uint256 rewardMultiplierKTY = rewardsKTY.mul(base6).mul(totalRewards).div(tokensSold).div(totalLPs);
        uint256 rewardMultiplierSDAO = rewardsSDAO.mul(base6).mul(totalRewards).div(tokensSold).div(totalLPs);
        return (rewardMultiplierKTY, rewardMultiplierSDAO);
    }

    /**
     * @notice This function returns already earned tokens by the _staker
     * @return uint256 the accrued KittieFightToken rewards
     * @return uint256 the accrued SuperDaoFightToken rewards
     */
    function getAccruedRewards(address _staker) public view returns (uint256, uint256) {
        // get rewards already claimed
        uint256[2] memory rewardsClaimed = yieldFarming.getTotalRewardsClaimedByStaker(_staker);
        uint256 _claimedKTY = rewardsClaimed[0];
        uint256 _claimedSDAO = rewardsClaimed[1];

        // get rewards earned but yet to be claimed
        (uint256 _KTYtoClaim, uint256 _SDAOtoClaim) = getRewardsToClaim(_staker);

        return (_claimedKTY.add(_KTYtoClaim), _claimedSDAO.add(_SDAOtoClaim));  
    }

    /**
     * @return the KTY and SDAO rewards earned but yet to claim by a staker
     */
    function getRewardsToClaim(address _staker) internal view returns (uint256, uint256) {
        uint256 _KTY = 0;
        uint256 _SDAO = 0;
        uint256 _ktyRewards;
        uint256 _sdaoRewards;
       
        // get rewards earned but yet to be claimed
        uint256[] memory allVolcies = volcie.allTokenOf(_staker);
        for (uint256 i = 0; i < allVolcies.length; i++) {
            (,, _ktyRewards, _sdaoRewards) = getVolcieValues(allVolcies[i]);
            _KTY = _KTY.add(_ktyRewards);
            _SDAO = _SDAO.add(_sdaoRewards);
        }

        return (_KTY, _SDAO);  
    }

    function getFirstMonthAmount(
        uint256 startDay,
        uint256 startMonth,
        uint256 adjustedMonthlyDeposit,
        uint256 _LP
    )
    public view returns(uint256)
    {        
        uint256 monthlyProportion = getElapsedDaysInMonth(startDay, startMonth);
        return adjustedMonthlyDeposit
            .mul(_LP.mul(monthDays.sub(monthlyProportion)))
            .div(adjustedMonthlyDeposit.add(monthlyProportion.mul(_LP).div(monthDays)))
            .div(monthDays);
    }

    /**
     * @return estimated KTY and SDAO rewards or any hypothetical amount of LPs from a pair code,
     *         if staking starts from now and keep locked until program ends.
     * @dev This function is only used for estimating rewards only
     */
    function estimateRewards(uint256 _LP, uint256 _pairCode) external view returns (uint256, uint256) {
        uint256 startMonth = yieldFarming.getCurrentMonth();
        uint256 startDay = getCurrentDay();
        uint256 factor = yieldFarmingHelper.bubbleFactor(_pairCode);
        uint256 adjustedLP = _LP.mul(base6).div(factor);
        
        uint256 adjustedMonthlyDeposit = yieldFarming.getAdjustedTotalMonthlyDeposits(startMonth);

        adjustedMonthlyDeposit = adjustedMonthlyDeposit.add(adjustedLP);

        uint256 currentDepositedAmount = getFirstMonthAmount(startDay, startMonth, adjustedMonthlyDeposit, adjustedLP);

        (uint256 _KTY, uint256 _SDAO) = estimateYields(startMonth, 5, adjustedLP, currentDepositedAmount, adjustedMonthlyDeposit);

        // if eligible for Early Mining Bonus, add the rewards for early bonus
        uint256 startTime = yieldFarming.programStartAt();
        if (block.timestamp <= startTime.add(DAY.mul(21))){
            uint256 _earlyBonus = _estimateEarlyBonus(adjustedLP);
            _KTY = _KTY.add(_earlyBonus);
            _SDAO = _SDAO.add(_earlyBonus);
        }

        return (_KTY, _SDAO);
    }

    /**
     * @return estimated KTY and SDAO rewards
     * @dev This function is only used for estimating rewards only
     */
    function estimateYields(uint256 startMonth, uint256 endMonth, uint256 lockedLP, uint256 startingLP, uint256 adjustedMonthlyDeposit)
        internal view
        returns (uint256, uint256)
    {
        (uint256 yields_part_1_KTY, uint256 yields_part_1_SDAO)= estimateYields_part_1(startMonth, startingLP, adjustedMonthlyDeposit);
        uint256 yields_part_2_KTY;
        uint256 yields_part_2_SDAO;
        if (endMonth > startMonth) {
            (yields_part_2_KTY, yields_part_2_SDAO) = estimateYields_part_2(startMonth, endMonth, lockedLP, adjustedMonthlyDeposit);
        }
        return (yields_part_1_KTY.add(yields_part_2_KTY), yields_part_1_SDAO.add(yields_part_2_SDAO));
    }

    /**
     * @return estimated KTY and SDAO rewards for the starting month
     * @dev This function is only used for estimating rewards only
     */
    function estimateYields_part_1(uint256 startMonth, uint256 startingLP, uint256 adjustedMonthlyDeposit)
        internal view
        returns (uint256 yieldsKTY_part_1, uint256 yieldsSDAO_part_1)
    {
        uint256 rewardsKTYstartMonth = getTotalKTYRewardsByMonth(startMonth);
        uint256 rewardsSDAOstartMonth = getTotalSDAORewardsByMonth(startMonth);

        yieldsKTY_part_1 = rewardsKTYstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
        yieldsSDAO_part_1 = rewardsSDAOstartMonth.mul(startingLP).div(adjustedMonthlyDeposit);
    }

    /**
     * @return estimated KTY and SDAO rewards for the for the months following the starting month until the end month
     * @dev This function is only used for estimating rewards only
     */
    function estimateYields_part_2(uint256 startMonth, uint256 endMonth, uint256 lockedLP, uint256 adjustedMonthlyDeposit)
        internal view
        returns (uint256 yieldsKTY_part_2, uint256 yieldsSDAO_part_2)
    {
        for (uint256 i = startMonth.add(1); i <= endMonth; i++) {
            uint256 monthlyRewardsKTY = getTotalKTYRewardsByMonth(i);
            uint256 monthlyRewardsSDAO = getTotalSDAORewardsByMonth(i);

            yieldsKTY_part_2 = yieldsKTY_part_2
                .add(monthlyRewardsKTY.mul(lockedLP).div(adjustedMonthlyDeposit));
            yieldsSDAO_part_2 = yieldsSDAO_part_2
                .add(monthlyRewardsSDAO.mul(lockedLP).div(adjustedMonthlyDeposit));
        }
         
    }

    /**
     * @return estimated early bonus for any hypothetical amount of LPs locked
     */
    function estimateEarlyBonus(uint256 _LP, uint256 _pairCode)
        public view returns (uint256)
    {
        uint256 factor = yieldFarmingHelper.bubbleFactor(_pairCode);
        uint256 adjustedLP = _LP.mul(base6).div(factor);
        return _estimateEarlyBonus(adjustedLP);
    }

    function _estimateEarlyBonus(uint256 adjustedLP)
        internal view returns (uint256)
    {
        uint256 _earlyBonus = yieldFarming.EARLY_MINING_BONUS();
        uint256 _adjustedTotalLockedLPinEarlyMining = yieldFarming.adjustedTotalLockedLPinEarlyMining();
        _adjustedTotalLockedLPinEarlyMining = _adjustedTotalLockedLPinEarlyMining.add(adjustedLP);
        return adjustedLP.mul(_earlyBonus).div(_adjustedTotalLockedLPinEarlyMining);
    }

    /**
     * @return the LP locked, LP locked value in DAI, accrued KTY rewards, and accrued SDAO rewards 
     *         of a Volcie token until the current moment.
     */
    function getVolcieValues(uint256 _volcieID)
        public view returns (uint256, uint256, uint256, uint256)
    {
        (address _originalOwner, uint256 _depositNumber,,uint256 _LP,uint256 _pairCode,,,,,) = yieldFarming.getVolcieToken(_volcieID);
        uint256 _LPvalueInDai = yieldFarmingHelper.getLPvalueInDai(_pairCode, _LP);
        (uint256 _KTY, uint256 _SDAO) = calculateRewardsByDepositNumber(_originalOwner, _depositNumber);
        return (_LP, _LPvalueInDai, _KTY, _SDAO);
    }

}