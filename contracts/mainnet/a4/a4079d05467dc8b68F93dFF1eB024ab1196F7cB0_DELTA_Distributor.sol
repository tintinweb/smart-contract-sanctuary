// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma abicoder v2;
import "../libs/SafeMath.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IDeltaToken.sol";
import "../../interfaces/IDeepFarmingVault.sol";// TODO REMOVE

interface ICORE_VAULT {
    function addPendingRewards(uint256) external;
}

contract DELTA_Distributor {
    using SafeMath for uint256;

    // Immutableas and constants

    // defacto burn address, this one isnt used commonly so its easy to see burned amounts on just etherscan
    address constant internal DEAD_BEEF = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
    address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant public CORE = 0x62359Ed7505Efc61FF1D56fEF82158CcaffA23D7;
    address constant public CORE_WETH_PAIR = 0x32Ce7e48debdccbFE0CD037Cc89526E4382cb81b;
    address constant public DELTA_MULTISIG = 0xB2d834dd31816993EF53507Eb1325430e67beefa;
    address constant public CORE_VAULT = 0xC5cacb708425961594B63eC171f4df27a9c0d8c9;
    // We sell 20% and distribute it thus
    uint256 constant public PERCENT_BURNED = 16;
    uint256 constant public PERCENT_DEV_FUND= 8;
    uint256 constant public PERCENT_DEEP_FARMING_VAULT = 56;
    uint256 constant public PERCENT_SOLD = 20;

    uint256 constant public PERCENT_OF_SOLD_DEV = 50;
    uint256 constant public PERCENT_OF_SOLD_CORE_BUY = 25;
    uint256 constant public PERCENT_OF_SOLD_DELTA_WETH_DEEP_FARMING_VAULT = 25;
    address immutable public DELTA_WETH_PAIR_UNISWAP;
    IDeltaToken immutable public DELTA_TOKEN;

    // storage variables
    address public deepFarmingVault; 
    uint256 public pendingBurn;
    uint256 public pendingDev;
    uint256 public pendingTotal;

    mapping(address => uint256) public pendingCredits;
    mapping(address => bool) public isApprovedLiquidator;

    receive() external payable {
        revert("ETH not allowed");
    }



    function distributeAndBurn() public {
        // Burn
        DELTA_TOKEN.transfer(DEAD_BEEF, pendingBurn);
        pendingTotal = pendingTotal.sub(pendingBurn);
        delete pendingBurn;
        // Transfer dev
        address deltaMultisig = DELTA_TOKEN.governance();
        DELTA_TOKEN.transfer(deltaMultisig, pendingDev);
        pendingTotal = pendingTotal.sub(pendingDev);
        delete pendingDev;
    }

    /// @notice a function that distributes pending to all the vaults etdc
    // This is able to be called by anyone.
    // And is simply just here to save gas on the distribution math
    function distribute() public {
        uint256 amountDeltaNow = DELTA_TOKEN.balanceOf(address(this));

        uint256 _pendingTotal = pendingTotal;

        uint256 amountAdded = amountDeltaNow.sub(_pendingTotal); // pendingSell stores in this variable and is not counted

        if(amountAdded < 1e18) { // We only add 1 DELTA + of rewards to save gas from the DFV calls.
            return;
        }

        uint256 toBurn = amountAdded.mul(PERCENT_BURNED).div(100);
        uint256 toDev = amountAdded.mul(PERCENT_DEV_FUND).div(100);
        uint256 toVault = amountAdded.mul(PERCENT_DEEP_FARMING_VAULT).div(100); // Not added to pending case we transfer it now

        pendingBurn = pendingBurn.add(toBurn);
        pendingDev = pendingDev.add(toDev);
        pendingTotal = _pendingTotal.add(amountAdded).sub(toVault);

        // We send to the vault and credit it
        IDeepFarmingVault(deepFarmingVault).addNewRewards(toVault, 0);
        // Reserve is how much we can sell thats remaining 20%
    }


    function setDeepFarmingVault(address _deepFarmingVault) public {
        onlyMultisig();
        deepFarmingVault = _deepFarmingVault;
        // set infinite approvals
        refreshApprovals();
        UserInformation memory ui = DELTA_TOKEN.userInformation(address(this));
        require(ui.noVestingWhitelisted, "DFV :: Set no vesting whitelist!");
        require(ui.fullSenderWhitelisted, "DFV :: Set full sender whitelist!");
        require(ui.immatureReceiverWhitelisted, "DFV :: Set immature whitelist!");
    }

    function refreshApprovals() public {
        DELTA_TOKEN.approve(deepFarmingVault, uint(-1));
        IERC20(WETH).approve(deepFarmingVault, uint(-1));
    }

    constructor (address _deltaToken) {
        DELTA_TOKEN = IDeltaToken(_deltaToken);
    
        // we check for a correct config
        require(PERCENT_SOLD + PERCENT_BURNED + PERCENT_DEV_FUND + PERCENT_DEEP_FARMING_VAULT == 100, "Amounts not proper");
        require(PERCENT_OF_SOLD_DEV + PERCENT_OF_SOLD_CORE_BUY + PERCENT_OF_SOLD_DELTA_WETH_DEEP_FARMING_VAULT == 100 , "Amount of weth split not proper");

        // calculate pair
        DELTA_WETH_PAIR_UNISWAP = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, // Mainned uniswap factory
                keccak256(abi.encodePacked(_deltaToken, WETH)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
        ))));
    }   

    function getWETHForDeltaAndDistribute(uint256 amountToSellFullUnits, uint256 minAmountWETHForSellingDELTA, uint256 minAmountCOREUnitsPer1WETH) public {
        require(isApprovedLiquidator[msg.sender] == true, "!approved liquidator");
        distribute(); // we call distribute to get rid of all coins that are not supposed to be sold
        distributeAndBurn();
        // We swap and make sure we can get enough out
        // require(address(this) < wethAddress, "Invalid Token Address"); in DELTA token constructor
        IUniswapV2Pair pairDELTA = IUniswapV2Pair(DELTA_WETH_PAIR_UNISWAP);
        (uint256 reservesDELTA, uint256 reservesWETHinDELTA, ) = pairDELTA.getReserves();
        uint256 deltaUnitsToSell = amountToSellFullUnits * 1 ether;
        uint256 balanceDelta = DELTA_TOKEN.balanceOf(address(this));

        require(balanceDelta >= deltaUnitsToSell, "Amount is greater than reserves");
        uint256 amountETHOut = getAmountOut(deltaUnitsToSell, reservesDELTA, reservesWETHinDELTA);
        require(amountETHOut >= minAmountWETHForSellingDELTA * 1 ether, "Did not get enough ETH to cover min");

        // We swap for eth
        DELTA_TOKEN.transfer(DELTA_WETH_PAIR_UNISWAP, deltaUnitsToSell);
        pairDELTA.swap(0, amountETHOut, address(this), "");
        address dfv = deepFarmingVault;

        // We transfer the splits of WETH
        IERC20 weth = IERC20(WETH);
        weth.transfer(DELTA_MULTISIG, amountETHOut.div(2));
        IDeepFarmingVault(dfv).addNewRewards(0, amountETHOut.div(4));
        /// Transfer here doesnt matter cause its taken from reserves and this does nto update
        weth.transfer(CORE_WETH_PAIR, amountETHOut.div(4));
        // We swap WETH for CORE and send it to the vault and update the pending inside the vault
        IUniswapV2Pair pairCORE = IUniswapV2Pair(CORE_WETH_PAIR);

        (uint256 reservesCORE, uint256 reservesWETHCORE, ) = pairCORE.getReserves();
         // function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal  pure returns (uint256 amountOut) {

        uint256 coreOut = getAmountOut(amountETHOut.div(4), reservesWETHCORE, reservesCORE);
        uint256 coreOut1WETH = getAmountOut(1 ether, reservesWETHCORE, reservesCORE);

        require(coreOut1WETH >= minAmountCOREUnitsPer1WETH, "Did not get enough CORE check amountCOREUnitsBoughtFor1WETH() fn");
        pairCORE.swap(coreOut, 0, CORE_VAULT, "");
        // uint passed is deprecated
        ICORE_VAULT(CORE_VAULT).addPendingRewards(0);

        pendingTotal = pendingTotal.sub(deltaUnitsToSell); // we adjust the reserves // since we might had nto swapped everything
    }   

    function editApprovedLiquidator(address liquidator, bool isLiquidator) public {
        onlyMultisig();
        isApprovedLiquidator[liquidator] = isLiquidator;
    }

    function deltaGovernance() public view returns (address) {
        if(address(DELTA_TOKEN) == address(0)) {return address (0); }
        return DELTA_TOKEN.governance();
    }

    function onlyMultisig() private view {
        require(msg.sender == deltaGovernance(), "!governance");
    }
    
    function amountCOREUnitsBoughtFor1WETH() public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(CORE_WETH_PAIR);
        // CORE is token0
        (uint256 reservesCORE, uint256 reservesWETH, ) = pair.getReserves();
        return getAmountOut(1 ether, reservesWETH, reservesCORE);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal  pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function rescueTokens(address token) public {
        onlyMultisig();
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    // Allows users to claim free credit
    function claimCredit() public {
        uint256 pending = pendingCredits[msg.sender];
        require(pending > 0, "Nothing to claim");
        pendingCredits[msg.sender] = 0;
        IDeepFarmingVault(deepFarmingVault).addPermanentCredits(msg.sender, pending);
    }

    /// Credits user for burning tokens
    // Can only be called by the delta token
    // Note this is a inherently trusted function that does not do balance checks.
    function creditUser(address user, uint256 amount) public {
        require(msg.sender == address(DELTA_TOKEN), "KNOCK KNOCK");
        pendingCredits[user] = pendingCredits[user].add(amount.mul(PERCENT_BURNED).div(100)); //  we add the burned amount to perma credit
    }

    function addDevested(address user, uint256 amount) public {
        require(DELTA_TOKEN.transferFrom(msg.sender, address(this), amount), "Did not transfer enough");
        pendingCredits[user] = pendingCredits[user].add(amount.mul(PERCENT_BURNED).div(100)); //  we add the burned amount to perma credit
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

import "../common/OVLTokenTypes.sol";

interface IDeltaToken is IERC20 {
    function vestingTransactions(address, uint256) external view returns (VestingTransaction memory);
    function getUserInfo(address) external view returns (UserInformationLite memory);
    function getMatureBalance(address, uint256) external view returns (uint256);
    function liquidityRebasingPermitted() external view returns (bool);
    function lpTokensInPair() external view returns (uint256);
    function governance() external view returns (address);
    function performLiquidityRebasing() external;
    function distributor() external view returns (address);
    function totalsForWallet(address ) external view returns (WalletTotals memory totals);
    function adjustBalanceOfNoVestingAccount(address, uint256,bool) external;
    function userInformation(address user) external view returns (UserInformation memory);

}

pragma abicoder v2;

struct RecycleInfo {
    uint256 booster;
    uint256 farmedDelta;
    uint256 farmedETH;
    uint256 recycledDelta;
    uint256 recycledETH;
}



interface IDeepFarmingVault {
    function addPermanentCredits(address,uint256) external;
    function addNewRewards(uint256 amountDELTA, uint256 amountWETH) external;
    function adminRescueTokens(address token, uint256 amount) external;
    function setCompundBurn(bool shouldBurn) external;
    function compound(address person) external;
    function exit() external;
    function withdrawRLP(uint256 amount) external;
    function realFarmedOfPerson(address person) external view returns (RecycleInfo memory);
    function deposit(uint256 numberRLP, uint256 numberDELTA) external;
    function depositFor(address person, uint256 numberRLP, uint256 numberDELTA) external;
    function depositWithBurn(uint256 numberDELTA) external;
    function depositForWithBurn(address person, uint256 numberDELTA) external;
}

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

// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY

pragma solidity ^0.7.6;

struct VestingTransaction {
    uint256 amount;
    uint256 fullVestingTimestamp;
}

struct WalletTotals {
    uint256 mature;
    uint256 immature;
    uint256 total;
}

struct UserInformation {
    // This is going to be read from only [0]
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
    uint256 maturedBalance;
    uint256 maxBalance;
    bool fullSenderWhitelisted;
    // Note that recieving immature balances doesnt mean they recieve them fully vested just that senders can do it
    bool immatureReceiverWhitelisted;
    bool noVestingWhitelisted;
}

struct UserInformationLite {
    uint256 maturedBalance;
    uint256 maxBalance;
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
}

struct VestingTransactionDetailed {
    uint256 amount;
    uint256 fullVestingTimestamp;
    // uint256 percentVestedE4;
    uint256 mature;
    uint256 immature;
}


uint256 constant QTY_EPOCHS = 7;

uint256 constant SECONDS_PER_EPOCH = 172800; // About 2days

uint256 constant FULL_EPOCH_TIME = SECONDS_PER_EPOCH * QTY_EPOCHS;

// Precision Multiplier -- this many zeros (23) seems to get all the precision needed for all 18 decimals to be only off by a max of 1 unit
uint256 constant PM = 1e23;

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}