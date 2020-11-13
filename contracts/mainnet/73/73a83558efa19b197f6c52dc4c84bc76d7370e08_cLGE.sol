// SPDX-License-Identifier: MIT
// COPYRIGHT cVault.finance TEAM
// NO COPY
// COPY = BAD
// This code is provided with no assurances or guarantees of any kind. Use at your own responsibility.
//
//  _     _             _     _ _ _           
// | |   (_)           (_)   | (_) |         
// | |    _  __ _ _   _ _  __| |_| |_ _   _  
// | |   | |/ _` | | | | |/ _` | | __| | | | 
// | |___| | (_| | |_| | | (_| | | |_| |_| | 
// \_____/_|\__, |\__,_|_|\__,_|_|\__|\__, |  
//             | |                     __/ |                                                                               
//             |_|                    |___/               
//  _____                           _   _               _____                _                                                                    
// |  __ \                         | | (_)             |  ___|              | |  
// | |  \/ ___ _ __   ___ _ __ __ _| |_ _  ___  _ __   | |____   _____ _ __ | |_ 
// | | __ / _ \ '_ \ / _ \ '__/ _` | __| |/ _ \| '_ \  |  __\ \ / / _ \ '_ \| __|
// | |_\ \  __/ | | |  __/ | | (_| | |_| | (_) | | | | | |___\ V /  __/ | | | |_ 
//  \____/\___|_| |_|\___|_|  \__,_|\__|_|\___/|_| |_| \____/ \_/ \___|_| |_|\__|
//
// \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\                      
//    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\                        
//       \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\                        
//          \\\\\\\\\\\\\\\\\\\\\\\\\\\\\                          
//            \\\\\\\\\\\\\\\\\\\\\\\\\\                           
//               \\\\\\\\\\\\\\\\\\\\\                             
//                  \\\\\\\\\\\\\\\\\                              
//                    \\\\\\\\\\\\\\                               
//                    \\\\\\\\\\\\\                                
//                    \\\\\\\\\\\\                                 
//                   \\\\\\\\\\\\                                  
//                  \\\\\\\\\\\\                                   
//                 \\\\\\\\\\\\                                    
//                \\\\\\\\\\\\                                     
//               \\\\\\\\\\\\                                      
//               \\\\\\\\\\\\                                      
//          `     \\\\\\\\\\\\      `    `                         
//             *    \\\\\\\\\\\\  *   *                            
//      `    *    *   \\\\\\\\\\\\   *  *   `                      
//              *   *   \\\\\\\\\\  *                              
//           `    *   * \\\\\\\\\ *   *   `                        
//        `    `     *  \\\\\\\\   *   `_____                      
//              \ \ \ * \\\\\\\  * /  /\`````\                    
//            \ \ \ \  \\\\\\  / / / /  \`````\                    
//          \ \ \ \ \ \\\\\\ / / / / |[] | [] |
//                                  EqPtz5qN7HM
//
// This contract lets people kickstart pair liquidity on uniswap together
// By pooling tokens together for a period of time
// A bundle of sticks makes one mighty liquidity pool
//

interface ICOREGlobals {
    function CORETokenAddress() external view returns (address);
    function COREGlobalsAddress() external view returns (address);
    function COREDelegatorAddress() external view returns (address);
    function COREVaultAddress() external returns (address);
    function COREWETHUniPair() external view returns (address);
    function UniswapFactory() external view returns (address);
    function transferHandler() external view returns (address);
    function addDelegatorStateChangePermission(address that, bool status) external;
    function isStateChangeApprovedContract(address that)  external view returns (bool);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;


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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/v612/COREv1/ICoreVault.sol

pragma solidity ^0.6.0;


interface ICoreVault {
    function devaddr() external returns (address);
    function addPendingRewards(uint _amount) external;
}

// File: contracts/v612/LGE.sol


pragma solidity 0.6.12;


// import '@uniswap/v2-periphery/contracts/libraries/IUniswapV2Library.sol';

// import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';









// import '@uniswap/v2-core/contracts/UniswapV2Pair.sol';

library COREIUniswapV2Library {
    
    using SafeMath for uint256;

    // Copied from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/IUniswapV2Library.sol
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IUniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'IUniswapV2Library: ZERO_ADDRESS');
    }

        // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal  returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);

        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);

        amountOut = numerator / denominator;
    }

}

interface IERC95 {
    function wrapAtomic(address) external;
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function skim(address to) external;
    function unpauseTransfers() external;

}

interface CERC95 {
    function wrapAtomic(address) external;
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function skim(address to) external;
    function name() external view returns (string memory);
}


interface ICORETransferHandler {
    function sync(address) external;
}

contract cLGE is Initializable, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {

    using SafeMath for uint256;


    /// CORE gets deposited straight never sold - refunded if balance is off at end
    // Others get sold if needed
    // ETH always gets sold into XXX from CORE/XXX
    
    IERC20 public tokenBeingWrapped;
    address public coreEthPair;
    address public wrappedToken;
    address public preWrapEthPair;
    address public COREToken;
    address public _WETH;
    address public wrappedTokenUniswapPair;
    address public uniswapFactory;

    ///////////////////////////////////////
    // Note this 3 are not supposed to be actual contributed because of the internal swaps
    // But contributed by people, before internal swaps
    uint256 public totalETHContributed;
    uint256 public totalCOREContributed;
    uint256 public totalWrapTokenContributed;
    ////////////////////////////////////////



    ////////////////////////////////////////
    // Internal balances user to calculate canges
    // Note we dont have WETH here because it all goes out
    uint256 private wrappedTokenBalance;
    uint256 private COREBalance;
    ////////////////////////////////////////

    ////////////////////////////////////////
    // Variables for calculating LP gotten per each user
    // Note all contributions get "flattened" to CORE 
    // This means we just calculate how much CORE it would buy with the running average
    // And use that as the counter
    uint256 public totalCOREToRefund; // This is in case there is too much CORE in the contract we refund people who contributed CORE proportionally
                                      // Potential scenario where someone swapped too much ETH/WBTC into CORE causing too much CORE to be in the contract
                                      // and subsequently being not refunded because he didn't contribute CORE but bought CORE for his ETH/WETB
                                      // Was noted and decided that the impact of this is not-significant
    uint256 public totalLPCreated;    
    uint256 private totalUnitsContributed;
    uint256 public LPPerUnitContributed; // stored as 1e8 more - this is done for change
    ////////////////////////////////////////


    event Contibution(uint256 COREvalue, address from);
    event COREBought(uint256 COREamt, address from);

    mapping (address => uint256) public COREContributed; // We take each persons core contributed to calculate units and 
                                                        // to calculate refund later from totalCoreRefund + CORE total contributed
    mapping (address => uint256) public unitsContributed; // unit to keep track how much each person should get of LP
    mapping (address => uint256) public unitsClaimed; 
    mapping (address => bool) public CORERefundClaimed; 
    mapping (address => address) public pairWithWETHAddressForToken; 

    mapping (address => uint256) public wrappedTokenContributed; // To calculate units
                                                                 // Note eth contributed will turn into this and get counted
    ICOREGlobals public coreGlobals;
    bool public LGEStarted;
    uint256 public contractStartTimestamp;
    uint256 public LGEDurationDays;
    bool public LGEFinished;

    function initialize(uint256 daysLong, address _wrappedToken, address _coreGlobals, address _preWrapEthPair) public initializer {
        require(msg.sender == address(0x5A16552f59ea34E44ec81E58b3817833E9fD5436));
        OwnableUpgradeSafe.__Ownable_init();
        ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();

        contractStartTimestamp = uint256(-1); // wet set it here to max so checks fail
        LGEDurationDays = daysLong.mul(1 days);
        coreGlobals = ICOREGlobals(_coreGlobals);
        coreEthPair = coreETHPairGetter();
        (COREToken, _WETH) = (IUniswapV2Pair(coreEthPair).token0(), IUniswapV2Pair(coreEthPair).token1()); // bb
        address tokenBeingWrappedAddress = IUniswapV2Pair(_preWrapEthPair).token1(); // bb
        tokenBeingWrapped =  IERC20(tokenBeingWrappedAddress);

        pairWithWETHAddressForToken[address(tokenBeingWrapped)] = _preWrapEthPair;
        pairWithWETHAddressForToken[IUniswapV2Pair(coreEthPair).token0()] = coreEthPair;// bb 


        wrappedToken = _wrappedToken;
        preWrapEthPair = _preWrapEthPair;
        uniswapFactory = coreGlobals.UniswapFactory();
    }
    
    function setTokenBeingWrapped(address token, address tokenPairWithWETH) public onlyOwner {
        tokenBeingWrapped = IERC20(token);
        pairWithWETHAddressForToken[token] = tokenPairWithWETH;
    }
    
    /// Starts LGE by admin call
    function startLGE() public onlyOwner {
        require(LGEStarted == false, "Already started");
        contractStartTimestamp = block.timestamp;
        LGEStarted = true;

        updateRunningAverages();
    }
    
    function isLGEOver() public view returns (bool) {
        return block.timestamp > contractStartTimestamp.add(LGEDurationDays);
    }


    function claimLP() nonReentrant public { 
        require(LGEFinished == true, "LGE : Liquidity generation not finished");
        require(unitsContributed[msg.sender].sub(unitsClaimed[msg.sender]) > 0, "LEG : Nothing to claim");

        IUniswapV2Pair(wrappedTokenUniswapPair)
            .transfer(msg.sender, unitsContributed[msg.sender].mul(LPPerUnitContributed).div(1e8));
            // LPPerUnitContributed is stored at 1e8 multiplied

        unitsClaimed[msg.sender] = unitsContributed[msg.sender];
    }

    function buyToken(address tokenTarget, uint256 amtToken, address tokenSwapping, uint256 amtTokenSwappingInput, address pair) internal {
        (address token0, address token1) = COREIUniswapV2Library.sortTokens(tokenSwapping, tokenTarget);
        IERC20(tokenSwapping).transfer(pair, amtTokenSwappingInput); 
        if(tokenTarget == token0) {
             IUniswapV2Pair(pair).swap(amtToken, 0, address(this), "");
        }
        else {
            IUniswapV2Pair(pair).swap(0, amtToken, address(this), "");
        }

        if(tokenTarget == COREToken){
            emit COREBought(amtToken, msg.sender);
        }
        
        updateRunningAverages();
    }

    function updateRunningAverages() internal{
         if(_averagePrices[address(tokenBeingWrapped)].lastBlockOfIncrement != block.number) {
            _averagePrices[address(tokenBeingWrapped)].lastBlockOfIncrement = block.number;
            updateRunningAveragePrice(address(tokenBeingWrapped), false);
          }
         if(_averagePrices[COREToken].lastBlockOfIncrement != block.number) {
            _averagePrices[COREToken].lastBlockOfIncrement = block.number;
            updateRunningAveragePrice(COREToken, false);
         }
    }


    function coreETHPairGetter() public view returns (address) {
        return coreGlobals.COREWETHUniPair();
    }


    function getPairReserves(address pair) internal view returns (uint256 wethReserves, uint256 tokenReserves) {
        address token0 = IUniswapV2Pair(pair).token0();
        (uint256 reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (wethReserves, tokenReserves) = token0 == _WETH ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function finalizeTokenWrapAddress(address _wrappedToken) onlyOwner public {
        wrappedToken = _wrappedToken;
    }

    // If LGE doesn't trigger in 24h after its complete its possible to withdraw tokens
    // Because then we can assume something went wrong since LGE is a publically callable function
    // And otherwise everything is stuck.
    function safetyTokenWithdraw(address token) onlyOwner public {
        require(block.timestamp > contractStartTimestamp.add(LGEDurationDays).add(1 days));
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    function safetyETHWithdraw() onlyOwner public {
        require(block.timestamp > contractStartTimestamp.add(LGEDurationDays).add(1 days));
        msg.sender.call.value(address(this).balance)("");
    }


    function addLiquidityAtomic() public {
        require(LGEStarted == true, "LGE Didn't start");
        require(LGEFinished == false, "LGE : Liquidity generation finished");
        require(isLGEOver() == false, "LGE is over.");

        // require(token == _WETH || token == COREToken || token == address(tokenBeingWrapped) || token == preWrapEthPair, "Unsupported deposit token");

        if(IUniswapV2Pair(preWrapEthPair).balanceOf(address(this)) > 0) {
            // Special carveout because unwrap calls this funciton
            // Since unwrap will add both WETH and tokenwrapped
            unwrapLiquidityTokens();
        } else{
            ( uint256 tokenBeingWrappedPer1ETH, uint256 coreTokenPer1ETH) = getHowMuch1WETHBuysOfTokens();


             // Check WETH if there is swap for CORRE or WBTC depending
             // Check WBTC and swap for core or not depending on peg
            uint256 balWETH = IERC20(_WETH).balanceOf(address(this));
            // No need to upate it because we dont retain WETH

            uint256 totalCredit; // In core units

            // Handling weth
            if(balWETH > 0){
                totalETHContributed = totalETHContributed.add(balWETH);
                totalCredit = handleWETHLiquidityAddition(balWETH,tokenBeingWrappedPer1ETH,coreTokenPer1ETH);
                // No other number should be there since it just started a line above
                COREBalance = IERC20(COREToken).balanceOf(address(this)); /// CHANGE
            }

            // Handling core wrap deposits
            // we check change from reserves
            uint256 tokenBeingWrappedBalNow = IERC20(tokenBeingWrapped).balanceOf(address(this));
            uint256 tokenBeingWrappedBalChange = tokenBeingWrappedBalNow.sub(wrappedTokenBalance);
            // If its bigger than 0 we handle
            if(tokenBeingWrappedBalChange > 0) {
                totalWrapTokenContributed = totalWrapTokenContributed.add(tokenBeingWrappedBalChange);
      
                // We add wrapped token contributionsto the person this is for stats only
                wrappedTokenContributed[msg.sender] = wrappedTokenContributed[msg.sender].add(tokenBeingWrappedBalChange);
                // We check how much credit he got that returns from this function
                totalCredit = totalCredit.add(  handleTokenBeingWrappedLiquidityAddition(tokenBeingWrappedBalChange,tokenBeingWrappedPer1ETH,coreTokenPer1ETH) );
                // We update reserves
                wrappedTokenBalance = IERC20(tokenBeingWrapped).balanceOf(address(this));
                COREBalance = IERC20(COREToken).balanceOf(address(this)); /// CHANGE

           }           

            // we check core balance against reserves
            // Note this is FoT token safe because we check balance of this 
            // And not accept user input
            uint256 COREBalNow = IERC20(COREToken).balanceOf(address(this));
            uint256 balCOREChange = COREBalNow.sub(COREBalance);
            if(balCOREChange > 0) {
                COREContributed[msg.sender] = COREContributed[msg.sender].add(balCOREChange);
                totalCOREContributed = totalCOREContributed.add(balCOREChange);
            }
            // Reset reserves
            COREBalance = COREBalNow;

            uint256 unitsChange = totalCredit.add(balCOREChange);
            // Gives people balances based on core units, if Core is contributed then we just append it to it without special logic
            unitsContributed[msg.sender] = unitsContributed[msg.sender].add(unitsChange);
            totalUnitsContributed = totalUnitsContributed.add(unitsChange);
            emit Contibution(totalCredit, msg.sender);
        
        }
    }

    function handleTokenBeingWrappedLiquidityAddition(uint256 amt,uint256 tokenBeingWrappedPer1ETH,uint256 coreTokenPer1ETH) internal  returns (uint256 coreUnitsCredit) {
        // VERY IMPRECISE TODO
        uint256 outWETH;
        (uint256 reserveWETHofWrappedTokenPair, uint256 reserveTokenofWrappedTokenPair) = getPairReserves(preWrapEthPair);

        if(COREBalance.div(coreTokenPer1ETH) <= wrappedTokenBalance.div(tokenBeingWrappedPer1ETH)) {
            // swap for eth
            outWETH = COREIUniswapV2Library.getAmountOut(amt, reserveTokenofWrappedTokenPair, reserveWETHofWrappedTokenPair);
            buyToken(_WETH, outWETH, address(tokenBeingWrapped) , amt, preWrapEthPair);
            // buy core
            (uint256 buyReserveWeth, uint256 reserveCore) = getPairReserves(coreEthPair);
            uint256 outCore = COREIUniswapV2Library.getAmountOut(outWETH, buyReserveWeth, reserveCore);
            buyToken(COREToken, outCore, _WETH ,outWETH,coreEthPair);
        } else {
            // Dont swap just calculate out and credit and leave as is
            outWETH = COREIUniswapV2Library.getAmountOut(amt, reserveTokenofWrappedTokenPair , reserveWETHofWrappedTokenPair);
        }

        // Out weth is in 2 branches
        // We give credit to user contributing
        coreUnitsCredit = outWETH.mul(coreTokenPer1ETH).div(1e18);
    }

    function handleWETHLiquidityAddition(uint256 amt,uint256 tokenBeingWrappedPer1ETH,uint256 coreTokenPer1ETH) internal returns (uint256 coreUnitsCredit) {
        // VERY IMPRECISE TODO

        // We check if corebalance in ETH is smaller than wrapped token balance in eth
        if(COREBalance.div(coreTokenPer1ETH) <= wrappedTokenBalance.div(tokenBeingWrappedPer1ETH)) {
            // If so we buy core
            (uint256 reserveWeth, uint256 reserveCore) = getPairReserves(coreEthPair);
            uint256 outCore = COREIUniswapV2Library.getAmountOut(amt, reserveWeth, reserveCore);
            //we buy core
            buyToken(COREToken, outCore,_WETH,amt, coreEthPair);

            // amt here is weth contributed
        } else {
            (uint256 reserveWeth, uint256 reserveToken) = getPairReserves(preWrapEthPair);
            uint256 outToken = COREIUniswapV2Library.getAmountOut(amt, reserveWeth, reserveToken);
            // we buy wrappedtoken
            buyToken(address(tokenBeingWrapped), outToken,_WETH, amt,preWrapEthPair);
            wrappedTokenBalance = IERC20(tokenBeingWrapped).balanceOf(address(this));


           //We buy outToken of the wrapped token and add it here
            wrappedTokenContributed[msg.sender] = wrappedTokenContributed[msg.sender].add(outToken);
        }
        // we credit user for ETH/ multiplied per core per 1 eth and then divided by 1 weth meaning we get exactly how much core it would be
        // in the running average
        coreUnitsCredit = amt.mul(coreTokenPer1ETH).div(1e18);

    }


    function getHowMuch1WETHBuysOfTokens() public view returns (uint256 tokenBeingWrappedPer1ETH, uint256 coreTokenPer1ETH) {
        return (getAveragePriceLast20Blocks(address(tokenBeingWrapped)), getAveragePriceLast20Blocks(COREToken));
    }


    //TEST TASK : Check if liquidity is added via just ending ETH to contract
    fallback() external payable {
        if(msg.sender != _WETH) {
             addLiquidityETH();
        }
    }

    //TEST TASK : Check if liquidity is added via calling this function
    function addLiquidityETH() nonReentrant public payable {
        // wrap weth
        IWETH(_WETH).deposit{value: msg.value}();
        addLiquidityAtomic();
    }

    // TEST TASK : check if this function deposits tokens
    function addLiquidityWithTokenWithAllowance(address token, uint256 amount) public nonReentrant {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        addLiquidityAtomic();
    }   

    // We burn liquiidyt from WBTC/ETH pair
    // And then send it to this ontract
    // Wrap atomic will handle both deposits of WETH and wrappedtoken
    function unwrapLiquidityTokens() internal {
        IUniswapV2Pair pair = IUniswapV2Pair(preWrapEthPair);
        pair.transfer(preWrapEthPair, pair.balanceOf(address(this)));
        pair.burn(address(this));
        addLiquidityAtomic();
    }



    // TODO

    mapping(address => PriceAverage) _averagePrices;
    struct PriceAverage{
       uint8 lastAddedHead;
       uint256[20] price;
       uint256 cumulativeLast20Blocks;
       bool arrayFull;
       uint lastBlockOfIncrement; // Just update once per block ( by buy token function )
    }

    // This is out tokens per 1WETH (1e18 units)
    function getAveragePriceLast20Blocks(address token) public view returns (uint256){

       return _averagePrices[token].cumulativeLast20Blocks.div(_averagePrices[token].arrayFull ? 20 : _averagePrices[token].lastAddedHead);
       // We check if the "array is full" because 20 writes might not have happened yet
       // And therefor the average would be skewed by dividing it by 20
    }


    // NOTE outTokenFor1WETH < lastQuote.mul(150).div(100) check
    function updateRunningAveragePrice(address token, bool isRescue) public returns (uint256) {
        PriceAverage storage currentAveragePrices =  _averagePrices[token];
        address pairWithWETH = pairWithWETHAddressForToken[token];
        (uint256 wethReserves, uint256 tokenReserves) = getPairReserves(address(pairWithWETH));
        // Get amt you would get for 1eth
        uint256 outTokenFor1WETH = COREIUniswapV2Library.getAmountOut(1e18, wethReserves, tokenReserves);

        uint8 i = currentAveragePrices.lastAddedHead;
        
        ////////////////////
        /// flash loan safety
        //we check the last quote for comparing to this one
        uint256 lastQuote;
        if(i == 0) {
            lastQuote = currentAveragePrices.price[19];
        }
        else {
            lastQuote = currentAveragePrices.price[i - 1];
        }

        // Safety flash loan revert
        // If change is above 50%
        // This can be rescued by the bool "isRescue"
        if(lastQuote != 0 && isRescue == false){
            require(outTokenFor1WETH < lastQuote.mul(15000).div(10000), "Change too big from previous price");
        }
        ////////////////////
        
        currentAveragePrices.cumulativeLast20Blocks = currentAveragePrices.cumulativeLast20Blocks.sub(currentAveragePrices.price[i]);
        currentAveragePrices.price[i] = outTokenFor1WETH;
        currentAveragePrices.cumulativeLast20Blocks = currentAveragePrices.cumulativeLast20Blocks.add(outTokenFor1WETH);
        currentAveragePrices.lastAddedHead++;
        if(currentAveragePrices.lastAddedHead > 19) {
            currentAveragePrices.lastAddedHead = 0;
            currentAveragePrices.arrayFull = true;
        }
        return currentAveragePrices.cumulativeLast20Blocks;
    }

    // Because its possible that price of someting legitimately goes +50%
    // Then the updateRunningAveragePrice would be stuck until it goes down,
    // This allows the admin to "rescue" it by writing a new average
    // skiping the +50% check
    function rescueRatioLock(address token) public onlyOwner{
        updateRunningAveragePrice(token, true);
    }



    // Protect form people atomically calling for LGE generation [x]
    // Price manipulation protections
    // use TWAP [x] custom 20 blocks
    // Set max diviation from last trade - not needed [ ]
    // re-entrancy protection [x]
    // dev tax [x]
    function addLiquidityToPairPublic() nonReentrant public{
        addLiquidityToPair(true);
    }

    // Safety function that can call public add liquidity before
    // This is in case someone manipulates the 20 liquidity addition blocks 
    // and screws up the ratio
    // Allows admins 2 hours to rescue the contract.
    function addLiquidityToPairAdmin() nonReentrant onlyOwner public{
        addLiquidityToPair(false);
    }

    function getCOREREfund() nonReentrant public {
        require(LGEFinished == true, "LGE not finished");
        require(totalCOREToRefund > 0 , "No refunds");
        require(COREContributed[msg.sender] > 0, "You didn't contribute anything");
        // refund happens just once
        require(CORERefundClaimed[msg.sender] == false , "You already claimed");
        
        // To get refund we get the core contributed of this user
        // divide it by total core to get the percentage of total this user contributed
        // And then multiply that by total core
        uint256 COREToRefundToThisPerson = COREContributed[msg.sender].mul(1e12).div(totalCOREContributed).
            mul(totalCOREToRefund).div(1e12);
        // Let 50% of total core is refunded, total core contributed is 5000
        // So refund amount it 2500
        // Lets say this user contributed 100, so he needs to get 50 back
        // 100*1e12 = 100000000000000
        // 100000000000000/5000 is 20000000000
        // 20000000000*2500 is 50000000000000
        // 50000000000000/1e21 = 50
        CORERefundClaimed[msg.sender] = true;
        IERC20(COREToken).transfer(msg.sender,COREToRefundToThisPerson);

    }

    function addLiquidityToPair(bool publicCall)  internal {
        require(block.timestamp > contractStartTimestamp.add(LGEDurationDays).add(publicCall ? 2 hours : 0), "LGE : Liquidity generaiton ongoing");
        require(LGEFinished == false, "LGE : Liquidity generation finished");
        
        // !!!!!!!!!!!
        //unlock wrapping
        IERC95(wrappedToken).unpauseTransfers();
        //!!!!!!!!!


        // wrap token
        tokenBeingWrapped.transfer(wrappedToken, tokenBeingWrapped.balanceOf(address(this)));
        IERC95(wrappedToken).wrapAtomic(address(this));
        IERC95(wrappedToken).skim(address(this)); // In case

        // Optimistically get pair
        wrappedTokenUniswapPair = IUniswapV2Factory(coreGlobals.UniswapFactory()).getPair(COREToken , wrappedToken);
        if(wrappedTokenUniswapPair == address(0)) { // Pair doesn't exist yet 
            // create pair returns address
            wrappedTokenUniswapPair = IUniswapV2Factory(coreGlobals.UniswapFactory()).createPair(
                COREToken,
                wrappedToken
            );
        }

        //send dev fee
        // 7.24% 
        uint256 DEV_FEE = 724; // TODO: DEV_FEE isn't public //ICoreVault(coreGlobals.COREVault).DEV_FEE();
        address devaddress = ICoreVault(coreGlobals.COREVaultAddress()).devaddr();
        IERC95(wrappedToken).transfer(devaddress, IERC95(wrappedToken).balanceOf(address(this)).mul(DEV_FEE).div(10000));
        IERC20(COREToken).transfer(devaddress, IERC20(COREToken).balanceOf(address(this)).mul(DEV_FEE).div(10000));

        //calculate core refund
        uint256 balanceCORENow = IERC20(COREToken).balanceOf(address(this));
        uint256 balanceCOREWrappedTokenNow = IERC95(wrappedToken).balanceOf(address(this));

        ( uint256 tokenBeingWrappedPer1ETH, uint256 coreTokenPer1ETH)  = getHowMuch1WETHBuysOfTokens();

        uint256 totalValueOfWrapper = balanceCOREWrappedTokenNow.div(tokenBeingWrappedPer1ETH).mul(1e18);
        uint256 totalValueOfCORE =  balanceCORENow.div(coreTokenPer1ETH).mul(1e18);

        totalCOREToRefund = totalValueOfWrapper >= totalValueOfCORE ? 0: 
                    totalValueOfCORE.sub(totalValueOfWrapper).div(coreTokenPer1ETH).mul(1e18);


        // send tokenwrap
        IERC95(wrappedToken).transfer(wrappedTokenUniswapPair, IERC95(wrappedToken).balanceOf(address(this)));

        // send core without the refund
        IERC20(COREToken).transfer(wrappedTokenUniswapPair, balanceCORENow.sub(totalCOREToRefund));

        // mint LP to this adddress
        IUniswapV2Pair(wrappedTokenUniswapPair).mint(address(this));

        // check how much was minted
        totalLPCreated = IUniswapV2Pair(wrappedTokenUniswapPair).balanceOf(address(this));

        // calculate minted per contribution
        LPPerUnitContributed = totalLPCreated.mul(1e8).div(totalUnitsContributed); // Stored as 1e8 more for round erorrs and change

        // set LGE to complete
        LGEFinished = true;

        //sync the tokens
        ICORETransferHandler(coreGlobals.transferHandler()).sync(wrappedToken);
        ICORETransferHandler(coreGlobals.transferHandler()).sync(COREToken);

    }
    


    
}