pragma solidity 0.6.11;

import "AggregatorV3Interface.sol";
import "IERC20.sol";
import "IWETH.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ILQTYTreasury.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniswapV2Pair {
    function mint(address to) external;
}

contract InitialLiquidityPool is Ownable {
    using SafeMath for uint256;

    // token that this contract accepts from contributors
    IWETH public WETH;
    // new token given as a reward to contributors
    IERC20 public rewardToken;
    // uniswap LP token for WETH and `rewardToken`
    address public lpToken;
    // address that receives the LP tokens
    address public treasury;
    // chainlink price oracle for ETH/USD
    AggregatorV3Interface public oracle;

    // initial whitelist root, valid immediately
    bytes32 public immutable whitelistRoot1;
    // second whitelist root, valid after two hours
    bytes32 public immutable whitelistRoot2;

    // amount of `rewardToken` that will be added as liquidity
    uint256 public rewardTokenLpAmount;
    // amount of `rewardToken` that will be distributed to contributors
    uint256 public rewardTokenSaleAmount;

    // hardcoded soft and hard caps in USD
    // the ETH equivalent is calculated when deposits open
    uint256 public constant softCapInUSD = 1000000;
    uint256 public constant hardCapInUSD = 5000000;
    uint256 public immutable initialContributionCapInUSD;

    // the minimum amount of ETH that must be received,
    // if this amount is not reached all contributions may withdraw
    uint256 public softCapInETH;
    // the maximum ETH amount that the contract will accept
    uint256 public hardCapInETH;
    // the maximum ETH amount that each contributor can send during the first hour
    // this amount doubles each hour, until hour 4 at which point the per-contributor
    // limit is removed altogether
    uint256 public initialContributionCapInETH;

    // total amount of ETH received from all contributors
    uint256 public totalReceived;

    // epoch time when contributors may begin to deposit
    uint256 public depositStartTime;
    // epoch time when the contract no longer accepts deposits
    uint256 public depositEndTime;
    // length of the "grace period" - time that deposits continue
    // after the contributed amount exceeds the soft cap
    uint256 public constant gracePeriod = 3600 * 6;

    // epoch time when `rewardToken` begins streaming to buyers
    uint256 public streamStartTime;
    // epoch time when `rewardToken` streaming has completed
    uint256 public streamEndTime;
    // time over which `rewardToken` is streamed
    uint256 public constant streamDuration = 86400 * 30;

    // dynamic values tracking total contributor balances
    // and `rewardToken` based on calls to `earlyExit`
    uint256 public currentDepositTotal;
    uint256 public currentRewardTotal;

    bool public liquidityAdded;
    bool public isKilled;

    struct UserDeposit {
        uint256 amount;
        uint256 streamed;
    }

    mapping(address => UserDeposit) public userAmounts;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event EarlyExit(address indexed user, uint256 amount);

    constructor(
        IWETH _weth,
        IERC20 _rewardToken,
        AggregatorV3Interface _oracle,
        IUniswapV2Factory _factory,
        address _treasury,
        uint256 _startTime,
        uint256 _initialCap,
        bytes32 _whitelistRoot1,
        bytes32 _whitelistRoot2
    ) public Ownable() {
        WETH = _weth;
        rewardToken = _rewardToken;
        oracle = _oracle;
        treasury = _treasury;
        lpToken = _factory.getPair(address(_weth), address(_rewardToken));
        require(lpToken != address(0));

        depositStartTime = _startTime;
        depositEndTime = _startTime.add(86400);
        initialContributionCapInUSD = _initialCap;

        whitelistRoot1 = _whitelistRoot1;
        whitelistRoot2 = _whitelistRoot2;

        streamStartTime = ILQTYTreasury(_treasury).issuanceStartTime();
        streamEndTime = streamStartTime.add(streamDuration);
        require(streamStartTime > block.timestamp);
    }

    // `rewardToken` should be transferred into the contract prior to calling this method
    // this must be called prior to `depositStartTime`
    function notifyRewardAmount() public onlyOwner {
        require(block.timestamp < depositStartTime, "Too late");
        uint amount = rewardToken.balanceOf(address(this));
        rewardTokenLpAmount = amount.mul(2).div(5);
        rewardTokenSaleAmount = amount.sub(rewardTokenLpAmount);
    }

    // if there is an issue during the deposits or when adding liquidity
    // the owner can kill and contributors may withdraw their funds
    function kill() public onlyOwner {
        require(!liquidityAdded, "Liquidity already added");
        isKilled = true;
    }

    function setPriceFromOracle() external onlyOwner {
        require(softCapInETH == 0, "Already set");
        require(block.timestamp >= depositStartTime.sub(300), "Too soon");
        setPrice();
    }

    function setPrice() internal {
        uint256 answer = uint256(oracle.latestAnswer());
        uint256 decimals = oracle.decimals();
        softCapInETH = softCapInUSD.mul(1e18).mul(10**decimals).div(answer);
        hardCapInETH = hardCapInUSD.mul(1e18).mul(10**decimals).div(answer);
        initialContributionCapInETH = initialContributionCapInUSD.mul(1e18).mul(10**decimals).div(answer);
    }

    function currentContributorCapInETH() public view returns (uint256) {
        if (block.timestamp < depositStartTime.add(14400)) {
            uint256 cap = initialContributionCapInETH;
            uint256 exp = block.timestamp.sub(depositStartTime).div(3600);
            return cap.mul(2 ** exp);
        } else {
            return hardCapInETH;
        }
    }

    // contributors call this method to deposit ETH during the deposit period
    function deposit(bytes32[] calldata _claimProof) external payable {
        require(!isKilled, "Killed");
        require(rewardTokenLpAmount > 0, "No reward tokens added");
        require(block.timestamp >= depositStartTime, "Not yet started");
        require(block.timestamp < depositEndTime, "Already finished");
        require(msg.value > 0, "Cannot deposit 0");
        verify(_claimProof);

        if (softCapInETH == 0) {
            // on the first deposit, use chainlink to determine
            // the ETH equivalant for the soft and hard caps
            setPrice();
        }

        // check contributor cap and update user contribution amount
        uint256 userContribution = userAmounts[msg.sender].amount.add(msg.value);
        require(userContribution <= currentContributorCapInETH(), "Exceeds contributor cap");
        userAmounts[msg.sender].amount = userContribution;

        // check soft/hard cap and update total contribution amount
        uint256 oldTotal = totalReceived;
        uint256 newTotal = oldTotal.add(msg.value);
        require(newTotal <= hardCapInETH, "Hard cap reached");
        if (oldTotal < softCapInETH && newTotal >= softCapInETH) {
            depositEndTime = block.timestamp.add(gracePeriod);
        }
        totalReceived = newTotal;
        emit Deposit(msg.sender, msg.value);
    }

    function verify(bytes32[] calldata proof) internal view {
        bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        // only the first root is accepted in the first two hours, afterwards both are valid
        require(
            computedHash == whitelistRoot1 ||
            (block.timestamp.sub(depositStartTime) >= 7200 && computedHash == whitelistRoot2),
            "Invalid claim proof"
        );
    }

    // after the deposit period is finished and the soft cap has been reached,
    // call this method to add liquidity and begin reward streaming for contributors
    function addLiquidity() public onlyOwner {
        require(!isKilled, "Killed");
        require(block.timestamp >= depositEndTime, "Deposits are still open");
        require(totalReceived >= softCapInETH, "Soft cap not reached");
        require(!liquidityAdded, "Liquidity already added");
        uint256 amount = address(this).balance;
        WETH.deposit{ value: amount }();
        WETH.transfer(lpToken, amount);
        rewardToken.transfer(lpToken, rewardTokenLpAmount);
        IUniswapV2Pair(lpToken).mint(treasury);

        currentDepositTotal = totalReceived;
        currentRewardTotal = rewardTokenSaleAmount;
        liquidityAdded = true;
    }

    // if the deposit period finishes and the soft cap was not reached, contributors
    // may call this method to withdraw their deposited balance
    function withdraw() public {
        if (!isKilled) {
            require(block.timestamp >= depositEndTime, "Deposits are still open");
            require(totalReceived < softCapInETH, "Cap was reached");
        }
        uint256 amount = userAmounts[msg.sender].amount;
        require(amount > 0, "Nothing to withdraw");
        userAmounts[msg.sender].amount = 0;
        msg.sender.transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    // once the streaming period begins, this returns the currently claimable
    // balance of `rewardToken` for a contributor
    function claimable(address _user) public view returns (uint256) {
        if (block.timestamp < streamStartTime || !liquidityAdded) {
            return 0;
        }
        uint256 totalClaimable = currentRewardTotal.mul(userAmounts[_user].amount).div(
            currentDepositTotal
        );
        if (block.timestamp >= streamEndTime) {
            return totalClaimable.sub(userAmounts[_user].streamed);
        }
        uint256 duration = block.timestamp.sub(streamStartTime);
        uint256 claimableToDate = totalClaimable.mul(duration).div(streamDuration);
        return claimableToDate.sub(userAmounts[_user].streamed);
    }

    // claim a pending `rewardToken` balance
    function claimReward() external {
        require(!isKilled, "Killed");
        require(liquidityAdded, "Liquidity was not added");
        uint256 amount = claimable(msg.sender);
        userAmounts[msg.sender].streamed = userAmounts[msg.sender].streamed.add(
            amount
        );
        rewardToken.transfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    // withdraw all available `rewardToken` balance immediately
    // calling this method forfeits 33% of the balance which is not yet available
    // to withdraw using `claimReward`. the extra tokens are then distributed to
    // other contributors who have not yet exitted. If the last contributor exits
    // early, any remaining tokens are are burned.
    function earlyExit() external {
        require(!isKilled, "Killed");
        require(liquidityAdded, "Liquidity was not added");
        require(block.timestamp > streamStartTime, "Streaming not active");
        require(block.timestamp < streamEndTime, "Streaming has finished");
        require(userAmounts[msg.sender].amount > 0, "No balance");

        uint256 claimableWithBonus = currentRewardTotal
            .mul(userAmounts[msg.sender].amount)
            .div(currentDepositTotal);
        uint256 claimableBase = rewardTokenLpAmount
            .mul(userAmounts[msg.sender].amount)
            .div(totalReceived);

        uint256 durationFromStart = block.timestamp.sub(streamStartTime);
        uint256 durationToEnd = streamEndTime.sub(block.timestamp);
        uint256 claimable = claimableWithBonus.mul(durationFromStart).div(
            streamDuration
        );
        claimable = claimable.add(
            claimableBase.mul(durationToEnd).div(streamDuration)
        );

        currentDepositTotal = currentDepositTotal.sub(userAmounts[msg.sender].amount);
        currentRewardTotal = currentRewardTotal.sub(claimable);
        claimable = claimable.sub(userAmounts[msg.sender].streamed);
        delete userAmounts[msg.sender];
        rewardToken.transfer(msg.sender, claimable);

        if (currentDepositTotal == 0) {
            uint256 remaining = rewardToken.balanceOf(address(this));
            rewardToken.transfer(address(0xdead), remaining);
        }
        emit EarlyExit(msg.sender, claimable);
    }
}

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.6.11;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function latestAnswer() external view returns (int256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity 0.6.11;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256) external;
    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;
    address public nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(_owner, nominatedOwner);
        _owner = nominatedOwner;
        nominatedOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ILQTYTreasury {
    function issuanceStartTime() external view returns (uint);
}