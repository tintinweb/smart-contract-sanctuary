// SPDX-License-Identifier: MIT
// COPYRIGHT cVault.finance TEAM
// NO COPY
// COPY = BAD
// This code is provided with no assurances or guarantees of any kind. Use at your own responsibility.

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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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

// File: contracts/v612/ICOREGlobals.sol

interface ICOREGlobals {
    function CORETokenAddress() external view returns (address);
    function COREGlobalsAddress() external view returns (address);
    function COREDelegatorAddress() external view returns (address);
    function COREVaultAddress() external returns (address);
    function COREWETHUniPair() external view returns (address);
    function UniswapFactory() external view returns (address);
    function TransferHandler() external view returns (address);
    function addDelegatorStateChangePermission(address that, bool status) external;
    function isStateChangeApprovedContract(address that)  external view returns (bool);
}

// File: contracts/v612/TransferHandler01.sol



/// Transfer handler v0.1
// The basic needed for double coins to work
// While we wait for TransferHandler 1.0 to be properly tested.

pragma solidity ^0.6.0;







contract TransferHandler01 is OwnableUpgradeSafe {

    using SafeMath for uint256;
    ICOREGlobals coreGlobals;
    address tokenUniswapPairCORE;
    address[] public trackedPairs;
    uint8 public feePercentX100;  // max 255 = 25.5% artificial clamp
    bool public transfersPaused;
    mapping (address => bool) public noFeeList;
    mapping (address => bool) public isPair;


    function initialize(
        address _coreGlobals
    ) public initializer {
        require(tx.origin == address(0x5A16552f59ea34E44ec81E58b3817833E9fD5436));
        OwnableUpgradeSafe.__Ownable_init();
        coreGlobals = ICOREGlobals(_coreGlobals);

        feePercentX100 = 10; //1%
        transfersPaused = true;  // pause transfers until we change the contract address to this one
                                // Then unpause will sync all pairs
        tokenUniswapPairCORE = coreGlobals.COREWETHUniPair();
        _editNoFeeList(coreGlobals.COREVaultAddress(), true); // corevault proxy needs to have no sender fee
        _addPairToTrack(coreGlobals.COREWETHUniPair());

        // minFinney = 5000;
    }

    // No need to remove pairs
    function addPairToTrack(address pair) onlyOwner public {
        _addPairToTrack(pair);
    }

    function _addPairToTrack(address pair) internal {

        uint256 length = trackedPairs.length;
        for (uint256 i = 0; i < length; i++) {
            require(trackedPairs[i] != pair, "Pair already tracked");
        }
        // we sync
        sync(pair);
        // we add to array so we can loop over it
        trackedPairs.push(pair);
        // we add pair to no fee sender list
        _editNoFeeList(pair, true);
        // we add it to pair mapping to lookups
        isPair[pair] = true;

    }


    // CORE token is pausable 
    function setPaused(bool _pause) public onlyOwner {

        transfersPaused = _pause;

        // Sync all tracked pairs
        uint256 length = trackedPairs.length;
        for (uint256 i = 0; i < length; i++) {
            sync(trackedPairs[i]);
        }
    
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        feePercentX100 = _feeMultiplier;
    }

    function editNoFeeList(address _address, bool noFee) public onlyOwner {
        _editNoFeeList(_address,noFee);
    }
    function _editNoFeeList(address _address, bool noFee) internal{
        noFeeList[_address] = noFee;
    }

    // uint minFinney; // 2x for $ liq amount

    // function setMinimumLiquidityToTriggerStop(uint finneyAmnt) public onlyOwner{ // 1000 = 1eth
    //     minFinney = finneyAmnt;
    // }


    // Old sync for backwards compatibility - syncs COREtokenEthPair
    function sync() public returns (bool lastIsMint, bool lpTokenBurn) {

        (lastIsMint,  lpTokenBurn) = sync(tokenUniswapPairCORE);

        // This will update the state of lastIsMint, when called publically
        // So we have to sync it before to the last LP token value.

        // uint256 _balanceWETH = IERC20(WETHAddress).balanceOf(tokenUniswapPair);
        // uint256 _balanceCORE = IERC20(coreTokenAddress).balanceOf(tokenUniswapPair);

        // Do not block after small liq additions
        // you can only withdraw 350$ now with front running
        // And cant front run buys with liq add ( adversary drain )

        // lastIsMint = _balanceCORE > lastSupplyOfCoreInPair && _balanceWETH > lastSupplyOfWETHInPair.add(minFinney.mul(1 finney));


        // lastSupplyOfCoreInPair = _balanceCORE;
        // lastSupplyOfWETHInPair = _balanceWETH;
    }

    mapping(address => uint256) private lpSupplyOfPair;

    function sync(address pair) public returns (bool lastIsMint, bool lpTokenBurn) {

        // This will update the state of lastIsMint, when called publically
        // So we have to sync it before to the last LP token value.
        uint256 _LPSupplyOfPairNow = IERC20(pair).totalSupply();

        lpTokenBurn = lpSupplyOfPair[pair] > _LPSupplyOfPairNow;
        lpSupplyOfPair[pair] = _LPSupplyOfPairNow;

        lastIsMint = false;
    }


    // Called by ERC95
    // They are not pausable
    //  or have a fee
    // at least right now
    // Note ERC95 will make it impossible to withdraw liq at all
    // Because CORE will sync, or it will sync while the transfer is happening
    // and revert
    // Note 2 : it would be cool to have own WETH but that woudnt be supported by uniswap 
    function handleTransfer
        (address sender, 
        address recipient, 
        uint256 amount
        ) public {
            
            // If the pair is sender it might be a burn
            // So we sync and then check
        
            if(isPair[sender]) {
                (bool lastIsMint, bool lpTokenBurn) = sync(sender);
                require(lastIsMint == false, "CORE TransferHandler v0.1 : Liquidity withdrawals forbidden");
                require(lpTokenBurn == false, "CORE TransferHandler v0.1 : Liquidity withdrawals forbidden");
            }
            // If recipent is pair we just sync
            else if(isPair[recipient]) {
               sync(recipient);
            }

        }


    function calculateAmountsAfterFee(        
        address sender, 
        address recipient, 
        uint256 amount
        ) public  returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount) 
        {
            require(transfersPaused == false, "CORE TransferHandler v0.1 : Transfers Paused");

            // If the sender is pair
            // We sync and check for a burn happening
            if(isPair[sender]) {
                (bool lastIsMint, bool lpTokenBurn) = sync(sender);
                require(lastIsMint == false, "CORE TransferHandler v0.1 : Liquidity withdrawals forbidden");
                require(lpTokenBurn == false, "CORE TransferHandler v0.1 : Liquidity withdrawals forbidden");
            }
            // If recipient is pair we just sync
            else if(isPair[recipient]) {
               sync(recipient);
            }
            
            // Because CORE isn't double controlled we should sync it on normal transfers as well
            if(!isPair[recipient] && !isPair[sender])
                sync();


            if(noFeeList[sender]) { // Dont have a fee when corevault is sending, or infinite loop  // And when pair is sending ( buys are happening, no tax on it)
                transferToFeeDistributorAmount = 0;
                transferToAmount = amount;
            } 
            else {
                transferToFeeDistributorAmount = amount.mul(feePercentX100).div(1000);
                transferToAmount = amount.sub(transferToFeeDistributorAmount);
            }

        }


}