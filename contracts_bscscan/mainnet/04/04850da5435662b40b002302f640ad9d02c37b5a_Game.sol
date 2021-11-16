/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

pragma solidity 0.6.8;

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

/**
 *Submitted for verification at BscScan.com on 2021-03-16
*/



interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// A contract where users lock a specified amount of LP tokens to get activated as players, they also earn transfer fees
// Also it holds the tokens played so they only are unlocked every week on sunday, including game rewards
// It also distributes rewards per game, which is calculated from games played and amount bet, regardless of whether they win or lose








interface ILockLiquidity {
    function lockLiquidityTo(address _to, uint256 _amount) external;
}

// We don't need safemath since we use 0.8.0
contract Game is Initializable, OwnableUpgradeSafe {
    using SafeMath for uint256;

    // CREATED: When the first player creates the game, paying the bet
    // STARTED: When the second player joins the game, paying the bet
    // CANCELLED: When the first player cancels before anybody joins to recover the Yeldio
    enum GameStatus { CREATED, STARTED, CANCELLED, ENDED_WINNER_ONE, ENDED_WINNER_TWO }

    struct GameData {
        uint256 id;
        uint256 timestamp;
        address one;
        address two;
        uint256 bet;
        GameStatus status;
    }

    mapping (address => bool) public activatedPlayer;
    mapping (address => uint256) public unclaimedRewards;
    mapping (address => uint256) public claimedRewards;
    mapping (address => bool) public isPlayerInAGame; // To make sure you can't create a game or join when you have an active game
    mapping (uint256 => GameData) public games; // By id
    address public serverSigner;
    address public devTreasury;
    uint256 public devTreasuryPercentage; // 2.5% times 2 bets = 5% total per game from the winner
    uint256 public minimumTokensLockedToBeActivated; // 1000 YELDIO tokens + BNB locked as liquidity to be activated
    address public yeldio;
    address public wbnb;
    address public pancakeRouter;
    address public lockLiquidityContract;
    address public liquidityProviderToken;
    uint256 public lastGameId;
    uint256 public gameReward; // 100 tokens for both players

    receive() external payable {}

    function initialize(
        address _yeldio,
        address _wbnb,
        address _pancakeRouter,
        address _lockLiquidityContract,
        address _liquidityProviderToken
    ) public initializer {
        __Ownable_init();
        yeldio = _yeldio;
        wbnb = _wbnb;
        pancakeRouter = _pancakeRouter;
        lockLiquidityContract = _lockLiquidityContract;
        liquidityProviderToken = _liquidityProviderToken;
        serverSigner = msg.sender;
        devTreasury = msg.sender;
        lastGameId = 1;
        gameReward = 100e18; // 100 tokens for both players
        devTreasuryPercentage = 2.5e18;
        minimumTokensLockedToBeActivated = 1000e18;
    }

    function setGameReward(uint256 _gameReward) public onlyOwner {
        gameReward = _gameReward;
    }

    function setLockLiquidityContract(address _lockLiquidityContract) public onlyOwner {
        lockLiquidityContract = _lockLiquidityContract;
    }

    // Important: since there's a 1% transfer fee built in, remember to calculate the actual amount received vs sent
    function createGame(uint256 _bet) public {
        require(activatedPlayer[msg.sender], 'GameLock: not activated');
        require(!isPlayerInAGame[msg.sender], 'GameLock: user busy in a game');
        games[lastGameId] = GameData(lastGameId, now, msg.sender, address(0), _bet, GameStatus.CREATED);
        IERC20(yeldio).transferFrom(msg.sender, address(this), _bet); // Send the actual bet amount where the transfer fee will be applied
        isPlayerInAGame[msg.sender] = true;
        lastGameId++;
    }

    function joinGame(uint256 _id) public {
        require(activatedPlayer[msg.sender], 'GameLock: not activated');
        require(!isPlayerInAGame[msg.sender], 'GameLock: user busy in a game');
        require(games[_id].status == GameStatus.CREATED, 'GameLock: not created status');
        games[_id].two = msg.sender;
        games[_id].status = GameStatus.STARTED;
        IERC20(yeldio).transferFrom(msg.sender, address(this), games[_id].bet);
        isPlayerInAGame[msg.sender] = true;
    }

    function cancelGame(uint256 _id) public {
        require(games[_id].status == GameStatus.CREATED, 'GameLock: must be created and not started');
        require(games[_id].one == msg.sender, 'GameLock: must be the owner');
        require(isPlayerInAGame[msg.sender], 'GameLock: must have a game');
        games[_id].status = GameStatus.CANCELLED;
        uint256 betAfterTransferFee = games[_id].bet.mul(99).div(100); // This is how much the contract received, it's also a way to punish game cancellers since that's something we want to avoid
        IERC20(yeldio).transferFrom(address(this), games[_id].one, betAfterTransferFee);
        isPlayerInAGame[games[_id].one] = false;
    }

    function endGame(
        uint256 _id,
        bytes memory _signedFinalMessage,
        uint8 _winner // can be 1 or 2
    ) public {
        require(games[_id].status == GameStatus.STARTED, 'GameLock: must be started');
        require(_signedFinalMessage.length == 65, 'GameLock: invalid message length');

        // Recreate the signed message for the first player to verify that the parameters are correct
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_id, _winner, address(this)))));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signedFinalMessage, 32))
            s := mload(add(_signedFinalMessage, 64))
            v := byte(0, mload(add(_signedFinalMessage, 96)))
        }

        { // Block to avoid stack to deep issues
            address originalSigner = ecrecover(message, v, r, s);
            require(originalSigner == serverSigner, 'GameLock: signer must be the server');
            uint256 betsAfterTransferFee = games[_id].bet.mul(99).div(100);
            uint256 devReward = betsAfterTransferFee.mul(2).mul(devTreasuryPercentage).div(1e18).div(100); // 5 / 100 = 0.05 which is 5%
            uint256 winnerReward = betsAfterTransferFee.mul(2).sub(devReward);

            if(_winner == 1) {
                games[_id].status = GameStatus.ENDED_WINNER_ONE;
                IERC20(yeldio).transfer(games[_id].one, winnerReward);
            } else {
                games[_id].status = GameStatus.ENDED_WINNER_TWO;
                IERC20(yeldio).transfer(games[_id].two, winnerReward);
            }
        }

        // This only applies when a game ends
        unclaimedRewards[games[_id].one] = unclaimedRewards[games[_id].one].add(games[_id].bet);
        unclaimedRewards[games[_id].two] = unclaimedRewards[games[_id].two].add(games[_id].bet);
        isPlayerInAGame[games[_id].one] = false;
        isPlayerInAGame[games[_id].two] = false;
    }

    // function loq() public payable {
    //     IERC20(yeldio).approve(pancakeRouter, ~uint256(0));
    //     // console.log('Before balance', IERC20(yeldio).balanceOf(address(this)));
    //     (,, uint liquidityTokensReceived) = IPancakeRouter02(pancakeRouter).addLiquidityETH{
    //         value: msg.value.div(2)
    //     }(yeldio, minimumTokensLockedToBeActivated, 0, 0, address(this), now.mul(2));
    //     // console.log('After balance', IERC20(yeldio).balanceOf(address(this)));
    // }

    // Buys liquidiy and locks it to activate the player. You need 1000 tokens locked so we'll get the price per token and calculate how many tokens to buy and how many of the BNB is necessary
    function buyLiquidityAndLockIt() public payable {
        // We send BNB in excess to guarantee the tokens. The unused tokens will be automatically refunded
        uint256 bnbRequired = calculateHowManyCoinsAreNeeded().mul(2);
        require(msg.value >= bnbRequired, 'Game: must send the required value');
        uint256 initialThisBalance = address(this).balance.sub(msg.value);
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = yeldio;

        // Buy Yeldio, we get exactly `minimumTokensLockedToBeActivated` + an extra 5% used for the 1% tranfer fee since it will be required later to add liquidity
        IPancakeRouter02(pancakeRouter).swapETHForExactTokens{
            value: msg.value.div(2)
        }(
            minimumTokensLockedToBeActivated.mul(105).div(100),
            path,
            address(this),
            now.mul(2)
        );

        // Provide liquidity
        if (IERC20(yeldio).allowance(address(this), pancakeRouter) < minimumTokensLockedToBeActivated) {
            IERC20(yeldio).approve(pancakeRouter, ~uint256(0));
        }
        (,, uint liquidityTokensReceived) = IPancakeRouter02(pancakeRouter).addLiquidityETH{
            value: msg.value.div(2)
        }(yeldio, minimumTokensLockedToBeActivated, 0, 0, address(this), now.mul(2));

        // Lock it
        if (IERC20(liquidityProviderToken).allowance(address(this), lockLiquidityContract) < liquidityTokensReceived) {
            IERC20(liquidityProviderToken).approve(lockLiquidityContract, ~uint256(0));
        }
        ILockLiquidity(lockLiquidityContract).lockLiquidityTo(msg.sender, liquidityTokensReceived);

        // Send the remanining BNB back to the user
        msg.sender.transfer(address(this).balance.sub(initialThisBalance));
        activatedPlayer[msg.sender] = true;
    }

    // Returns how many BNB you need to buy 1200 YELDIO tokens for the liquidity lock
    function calculateHowManyCoinsAreNeeded() public view returns(uint256) {
        // Use get amount out and check if what you get here is the same as what you get in pancake testnet. Check it on a build file
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = yeldio;
        // Router v2 function
        // Calculate how much BNB is required to buy 1200 yeldio (20% more for potential slippage issues and the 1% transfer fee)
        // function getAmountsIn(uint amountOut, address[] memory path) public view returns (uint[] memory amounts);
        uint256[] memory amountBNBRequired = IPancakeRouter02(pancakeRouter).getAmountsIn(minimumTokensLockedToBeActivated.mul(120).div(100), path);
        return amountBNBRequired[0]; // Returns an array of amounts
    }

    function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function extractETHIfStruck() public onlyOwner {
        payable(address(owner())).transfer(address(this).balance);
    }
}