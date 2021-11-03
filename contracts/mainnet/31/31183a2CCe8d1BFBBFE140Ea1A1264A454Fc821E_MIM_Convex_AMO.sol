/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/Curve/IStableSwap3Pool.sol


interface IStableSwap3Pool {
	// Deployment
	function __init__(address _owner, address[3] memory _coins, address _pool_token, uint256 _A, uint256 _fee, uint256 _admin_fee) external;

	// ERC20 Standard
	function decimals() external view returns (uint);
	function transfer(address _to, uint _value) external returns (uint256);
	function transferFrom(address _from, address _to, uint _value) external returns (bool);
	function approve(address _spender, uint _value) external returns (bool);
	function totalSupply() external view returns (uint);
	function mint(address _to, uint256 _value) external returns (bool);
	function burnFrom(address _to, uint256 _value) external returns (bool);
	function balanceOf(address _owner) external view returns (uint256);

	// 3Pool
	function A() external view returns (uint);
	function get_virtual_price() external view returns (uint);
	function calc_token_amount(uint[3] memory amounts, bool deposit) external view returns (uint);
	function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
	function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
	function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;
	function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
	function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
	
	// Admin functions
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;
	function commit_new_fee(uint256 new_fee, uint256 new_admin_fee) external;
	function apply_new_fee() external;
	function commit_transfer_ownership(address _owner) external;
	function apply_transfer_ownership() external;
	function revert_transfer_ownership() external;
	function admin_balances(uint256 i) external returns (uint256);
	function withdraw_admin_fees() external;
	function donate_admin_fees() external;
	function kill_me() external;
	function unkill_me() external;
}


// File contracts/Curve/IMetaImplementationUSD.sol


interface IMetaImplementationUSD {

	// Deployment
	function __init__() external;
	function initialize(string memory _name, string memory _symbol, address _coin, uint _decimals, uint _A, uint _fee, address _admin) external;

	// ERC20 Standard
	function decimals() external view returns (uint);
	function transfer(address _to, uint _value) external returns (uint256);
	function transferFrom(address _from, address _to, uint _value) external returns (bool);
	function approve(address _spender, uint _value) external returns (bool);
	function balanceOf(address _owner) external view returns (uint256);
	function totalSupply() external view returns (uint256);


	// StableSwap Functionality
	function get_previous_balances() external view returns (uint[2] memory);
	function get_twap_balances(uint[2] memory _first_balances, uint[2] memory _last_balances, uint _time_elapsed) external view returns (uint[2] memory);
	function get_price_cumulative_last() external view returns (uint[2] memory);
	function admin_fee() external view returns (uint);
	function A() external view returns (uint);
	function A_precise() external view returns (uint);
	function get_virtual_price() external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit) external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit, bool _previous) external view returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount) external returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount, address _receiver) external returns (uint);
	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address _receiver) external returns (uint256[2] memory);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount) external returns (uint256);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i, bool _previous) external view returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver) external returns (uint256);
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;
	function admin_balances(uint256 i) external view returns (uint256);
	function withdraw_admin_fees() external;
}


// File contracts/Misc_AMOs/convex/IConvexBooster.sol


interface IConvexBooster {
  function FEE_DENOMINATOR() external view returns (uint256);
  function MaxFees() external view returns (uint256);
  function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns (bool);
  function claimRewards(uint256 _pid, address _gauge) external returns (bool);
  function crv() external view returns (address);
  function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
  function distributionAddressId() external view returns (uint256);
  function earmarkFees() external returns (bool);
  function earmarkIncentive() external view returns (uint256);
  function earmarkRewards(uint256 _pid) external returns (bool);
  function feeDistro() external view returns (address);
  function feeManager() external view returns (address);
  function feeToken() external view returns (address);
  function gaugeMap(address) external view returns (bool);
  function isShutdown() external view returns (bool);
  function lockFees() external view returns (address);
  function lockIncentive() external view returns (uint256);
  function lockRewards() external view returns (address);
  function minter() external view returns (address);
  function owner() external view returns (address);
  function platformFee() external view returns (uint256);
  function poolInfo(uint256) external view returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
  function poolLength() external view returns (uint256);
  function poolManager() external view returns (address);
  function registry() external view returns (address);
  function rewardArbitrator() external view returns (address);
  function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns (bool);
  function rewardFactory() external view returns (address);
  function setArbitrator(address _arb) external;
  function setFactories(address _rfactory, address _sfactory, address _tfactory) external;
  function setFeeInfo() external;
  function setFeeManager(address _feeM) external;
  function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external;
  function setGaugeRedirect(uint256 _pid) external returns (bool);
  function setOwner(address _owner) external;
  function setPoolManager(address _poolM) external;
  function setRewardContracts(address _rewards, address _stakerRewards) external;
  function setTreasury(address _treasury) external;
  function setVoteDelegate(address _voteDelegate) external;
  function shutdownPool(uint256 _pid) external returns (bool);
  function shutdownSystem() external;
  function staker() external view returns (address);
  function stakerIncentive() external view returns (uint256);
  function stakerRewards() external view returns (address);
  function stashFactory() external view returns (address);
  function tokenFactory() external view returns (address);
  function treasury() external view returns (address);
  function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool);
  function voteDelegate() external view returns (address);
  function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);
  function voteOwnership() external view returns (address);
  function voteParameter() external view returns (address);
  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
  function withdrawAll(uint256 _pid) external returns (bool);
  function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns (bool);
}


// /**
//  * @dev Standard math utilities missing in the Solidity language.
//  */
// library MathUtil {
//     /**
//      * @dev Returns the smallest of two numbers.
//      */
//     function min(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a < b ? a : b;
//     }
// }

// contract ReentrancyGuard {
//     uint256 private _guardCounter;

//     constructor () internal {
//         _guardCounter = 1;
//     }

//     modifier nonReentrant() {
//         _guardCounter += 1;
//         uint256 localCounter = _guardCounter;
//         _;
//         require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
//     }
// }

// interface ICurveGauge {
//     function deposit(uint256) external;
//     function balanceOf(address) external view returns (uint256);
//     function withdraw(uint256) external;
//     function claim_rewards() external;
//     function reward_tokens(uint256) external view returns(address);//v2
//     function rewarded_token() external view returns(address);//v1
// }

// interface ICurveVoteEscrow {
//     function create_lock(uint256, uint256) external;
//     function increase_amount(uint256) external;
//     function increase_unlock_time(uint256) external;
//     function withdraw() external;
//     function smart_wallet_checker() external view returns (address);
// }

// interface IWalletChecker {
//     function check(address) external view returns (bool);
// }

// interface IVoting{
//     function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
//     function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory); 
//     function vote_for_gauge_weights(address,uint256) external;
// }

// interface IMinter{
//     function mint(address) external;
// }

// interface IRegistry{
//     function get_registry() external view returns(address);
//     function get_address(uint256 _id) external view returns(address);
//     function gauge_controller() external view returns(address);
//     function get_lp_token(address) external view returns(address);
//     function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
// }

// interface IStaker{
//     function deposit(address, address) external;
//     function withdraw(address) external;
//     function withdraw(address, address, uint256) external;
//     function withdrawAll(address, address) external;
//     function createLock(uint256, uint256) external;
//     function increaseAmount(uint256) external;
//     function increaseTime(uint256) external;
//     function release() external;
//     function claimCrv(address) external returns (uint256);
//     function claimRewards(address) external;
//     function claimFees(address,address) external;
//     function setStashAccess(address, bool) external;
//     function vote(uint256,address,bool) external;
//     function voteGaugeWeight(address,uint256) external;
//     function balanceOfPool(address) external view returns (uint256);
//     function operator() external view returns (address);
//     function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
// }

// interface IRewards{
//     function stake(address, uint256) external;
//     function stakeFor(address, uint256) external;
//     function withdraw(address, uint256) external;
//     function exit(address) external;
//     function getReward(address) external;
//     function queueNewRewards(uint256) external;
//     function notifyRewardAmount(uint256) external;
//     function addExtraReward(address) external;
//     function stakingToken() external returns (address);
// }

// interface IStash{
//     function stashRewards() external returns (bool);
//     function processStash() external returns (bool);
//     function claimRewards() external returns (bool);
// }

// interface IFeeDistro{
//     function claim() external;
//     function token() external view returns(address);
// }

// interface ITokenMinter{
//     function mint(address,uint256) external;
//     function burn(address,uint256) external;
// }

// interface IDeposit{
//     function isShutdown() external view returns(bool);
//     function balanceOf(address _account) external view returns(uint256);
//     function totalSupply() external view returns(uint256);
//     function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
//     function rewardClaimed(uint256,address,uint256) external;
//     function withdrawTo(uint256,uint256,address) external;
//     function claimRewards(uint256,address) external returns(bool);
//     function rewardArbitrator() external returns(address);
// }

// interface ICrvDeposit{
//     function deposit(uint256, bool) external;
//     function lockIncentive() external view returns(uint256);
// }

// interface IRewardFactory{
//     function setAccess(address,bool) external;
//     function CreateCrvRewards(uint256,address) external returns(address);
//     function CreateTokenRewards(address,address,address) external returns(address);
//     function activeRewardCount(address) external view returns(uint256);
//     function addActiveReward(address,uint256) external returns(bool);
//     function removeActiveReward(address,uint256) external returns(bool);
// }

// interface IStashFactory{
//     function CreateStash(uint256,address,address,uint256) external returns(address);
// }

// interface ITokenFactory{
//     function CreateDepositToken(address) external returns(address);
// }

// interface IPools{
//     function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
//     function shutdownPool(uint256 _pid) external returns(bool);
//     function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
//     function poolLength() external view returns (uint256);
//     function gaugeMap(address) external view returns(bool);
//     function setPoolManager(address _poolM) external;
// }

// interface IVestedEscrow{
//     function fund(address[] calldata _recipient, uint256[] calldata _amount) external returns(bool);
// }

// // File: @openzeppelin\contracts\math\SafeMath.sol


// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         uint256 c = a + b;
//         if (c < a) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the substraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b > a) return (false, 0);
//         return (true, a - b);
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) return (true, 0);
//         uint256 c = a * b;
//         if (c / a != b) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a / b);
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a % b);
//     }

//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      *
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b <= a, "SafeMath: subtraction overflow");
//         return a - b;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      *
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         if (a == 0) return 0;
//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: division by zero");
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: modulo by zero");
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         return a - b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryDiv}.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a % b;
//     }
// }

// // File: @openzeppelin\contracts\token\ERC20\IERC20.sol


// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// // File: @openzeppelin\contracts\utils\Address.sol

// /**
//  * @dev Collection of functions related to the address type
//  */
// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * [IMPORTANT]
//      * ====
//      * It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      *
//      * Among others, `isContract` will return false for the following
//      * types of addresses:
//      *
//      *  - an externally-owned account
//      *  - a contract in construction
//      *  - an address where a contract will be created
//      *  - an address where a contract lived, but was destroyed
//      * ====
//      */
//     function isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { size := extcodesize(account) }
//         return size > 0;
//     }

//     /**
//      * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//      * `recipient`, forwarding all available gas and reverting on errors.
//      *
//      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//      * of certain opcodes, possibly making contracts go over the 2300 gas limit
//      * imposed by `transfer`, making them unable to receive funds via
//      * `transfer`. {sendValue} removes this limitation.
//      *
//      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//      *
//      * IMPORTANT: because control is transferred to `recipient`, care must be
//      * taken to not create reentrancy vulnerabilities. Consider using
//      * {ReentrancyGuard} or the
//      * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//      */
//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//         (bool success, ) = recipient.call{ value: amount }("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     /**
//      * @dev Performs a Solidity function call using a low level `call`. A
//      * plain`call` is an unsafe replacement for a function call: use this
//      * function instead.
//      *
//      * If `target` reverts with a revert reason, it is bubbled up by this
//      * function (like regular Solidity function calls).
//      *
//      * Returns the raw returned data. To convert to the expected return value,
//      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
//      *
//      * Requirements:
//      *
//      * - `target` must be a contract.
//      * - calling `target` with `data` must not revert.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//       return functionCall(target, data, "Address: low-level call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
//      * `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, 0, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but also transferring `value` wei to `target`.
//      *
//      * Requirements:
//      *
//      * - the calling contract must have an ETH balance of at least `value`.
//      * - the called Solidity function must be `payable`.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
//      * with `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: value }(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
//         return functionStaticCall(target, data, "Address: low-level static call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
//         require(isContract(target), "Address: static call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.staticcall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         require(isContract(target), "Address: delegate call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.delegatecall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }
// }

// // File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol




// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
// library SafeERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(IERC20 token, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     /**
//      * @dev Deprecated. This function has issues similar to the ones found in
//      * {IERC20-approve}, and its usage is discouraged.
//      *
//      * Whenever possible, use {safeIncreaseAllowance} and
//      * {safeDecreaseAllowance} instead.
//      */
//     function safeApprove(IERC20 token, address spender, uint256 value) internal {
//         // safeApprove should only be called when setting an initial allowance,
//         // or when resetting it to zero. To increase and decrease it, use
//         // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
//         // solhint-disable-next-line max-line-length
//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }

//     function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(value);
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     /**
//      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
//      * on the return value: the return value is optional (but if data is returned, it must not be false).
//      * @param token The token targeted by the call.
//      * @param data The call data (encoded using abi.encode or one of its variants).
//      */
//     function _callOptionalReturn(IERC20 token, bytes memory data) private {
//         // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
//         // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
//         // the target address contains contract code and also asserts for success in the low-level call.

//         bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
//         if (returndata.length > 0) { // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
//         }
//     }
// }

// // File: contracts\Booster.sol




// contract Booster{
//     using SafeERC20 for IERC20;
//     using Address for address;
//     using SafeMath for uint256;

//     address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
//     address public constant registry = address(0x0000000022D53366457F9d5E68Ec105046FC4383);
//     uint256 public constant distributionAddressId = 4;
//     address public constant voteOwnership = address(0xE478de485ad2fe566d49342Cbd03E49ed7DB3356);
//     address public constant voteParameter = address(0xBCfF8B0b9419b9A88c44546519b1e909cF330399);

//     uint256 public lockIncentive = 1000; //incentive to crv stakers
//     uint256 public stakerIncentive = 450; //incentive to native token stakers
//     uint256 public earmarkIncentive = 50; //incentive to users who spend gas to make calls
//     uint256 public platformFee = 0; //possible fee to build treasury
//     uint256 public constant MaxFees = 2000;
//     uint256 public constant FEE_DENOMINATOR = 10000;

//     address public owner;
//     address public feeManager;
//     address public poolManager;
//     address public immutable staker;
//     address public immutable minter;
//     address public rewardFactory;
//     address public stashFactory;
//     address public tokenFactory;
//     address public rewardArbitrator;
//     address public voteDelegate;
//     address public treasury;
//     address public stakerRewards; //cvx rewards
//     address public lockRewards; //cvxCrv rewards(crv)
//     address public lockFees; //cvxCrv vecrv fees
//     address public feeDistro;
//     address public feeToken;

//     bool public isShutdown;

//     struct PoolInfo {
//         address lptoken;
//         address token;
//         address gauge;
//         address crvRewards;
//         address stash;
//         bool shutdown;
//     }

//     //index(pid) -> pool
//     PoolInfo[] public poolInfo;
//     mapping(address => bool) public gaugeMap;

//     event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
//     event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

//     constructor (address _staker, address _minter) public {
//         isShutdown = false;
//         staker = _staker;
//         owner = msg.sender;
//         voteDelegate = msg.sender;
//         feeManager = msg.sender;
//         poolManager = msg.sender;
//         feeDistro = address(0); //address(0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc);
//         feeToken = address(0); //address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
//         treasury = address(0);
//         minter = _minter;
//     }


//     /// SETTER SECTION ///

//     function setOwner(address _owner) external {
//         require(msg.sender == owner, "!auth");
//         owner = _owner;
//     }

//     function setFeeManager(address _feeM) external {
//         require(msg.sender == feeManager, "!auth");
//         feeManager = _feeM;
//     }

//     function setPoolManager(address _poolM) external {
//         require(msg.sender == poolManager, "!auth");
//         poolManager = _poolM;
//     }

//     function setFactories(address _rfactory, address _sfactory, address _tfactory) external {
//         require(msg.sender == owner, "!auth");
        
//         //reward factory only allow this to be called once even if owner
//         //removes ability to inject malicious staking contracts
//         //token factory can also be immutable
//         if(rewardFactory == address(0)){
//             rewardFactory = _rfactory;
//             tokenFactory = _tfactory;
//         }

//         //stash factory should be considered more safe to change
//         //updating may be required to handle new types of gauges
//         stashFactory = _sfactory;
//     }

//     function setArbitrator(address _arb) external {
//         require(msg.sender==owner, "!auth");
//         rewardArbitrator = _arb;
//     }

//     function setVoteDelegate(address _voteDelegate) external {
//         require(msg.sender==voteDelegate, "!auth");
//         voteDelegate = _voteDelegate;
//     }

//     function setRewardContracts(address _rewards, address _stakerRewards) external {
//         require(msg.sender == owner, "!auth");
        
//         //reward contracts are immutable or else the owner
//         //has a means to redeploy and mint cvx via rewardClaimed()
//         if(lockRewards == address(0)){
//             lockRewards = _rewards;
//             stakerRewards = _stakerRewards;
//         }
//     }

//     // Set reward token and claim contract, get from Curve's registry
//     function setFeeInfo() external {
//         require(msg.sender==feeManager, "!auth");
        
//         feeDistro = IRegistry(registry).get_address(distributionAddressId);
//         address _feeToken = IFeeDistro(feeDistro).token();
//         if(feeToken != _feeToken){
//             //create a new reward contract for the new token
//             lockFees = IRewardFactory(rewardFactory).CreateTokenRewards(_feeToken,lockRewards,address(this));
//             feeToken = _feeToken;
//         }
//     }

//     function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external{
//         require(msg.sender==feeManager, "!auth");

//         uint256 total = _lockFees.add(_stakerFees).add(_callerFees).add(_platform);
//         require(total <= MaxFees, ">MaxFees");

//         //values must be within certain ranges     
//         if(_lockFees >= 1000 && _lockFees <= 1500
//             && _stakerFees >= 300 && _stakerFees <= 600
//             && _callerFees >= 10 && _callerFees <= 100
//             && _platform <= 200){
//             lockIncentive = _lockFees;
//             stakerIncentive = _stakerFees;
//             earmarkIncentive = _callerFees;
//             platformFee = _platform;
//         }
//     }

//     function setTreasury(address _treasury) external {
//         require(msg.sender==feeManager, "!auth");
//         treasury = _treasury;
//     }

//     /// END SETTER SECTION ///


//     function poolLength() external view returns (uint256) {
//         return poolInfo.length;
//     }

//     //create a new pool
//     function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool){
//         require(msg.sender==poolManager && !isShutdown, "!add");
//         require(_gauge != address(0) && _lptoken != address(0),"!param");

//         //the next pool's pid
//         uint256 pid = poolInfo.length;

//         //create a tokenized deposit
//         address token = ITokenFactory(tokenFactory).CreateDepositToken(_lptoken);
//         //create a reward contract for crv rewards
//         address newRewardPool = IRewardFactory(rewardFactory).CreateCrvRewards(pid,token);
//         //create a stash to handle extra incentives
//         address stash = IStashFactory(stashFactory).CreateStash(pid,_gauge,staker,_stashVersion);

//         //add the new pool
//         poolInfo.push(
//             PoolInfo({
//                 lptoken: _lptoken,
//                 token: token,
//                 gauge: _gauge,
//                 crvRewards: newRewardPool,
//                 stash: stash,
//                 shutdown: false
//             })
//         );
//         gaugeMap[_gauge] = true;
//         //give stashes access to rewardfactory and voteproxy
//         //   voteproxy so it can grab the incentive tokens off the contract after claiming rewards
//         //   reward factory so that stashes can make new extra reward contracts if a new incentive is added to the gauge
//         if(stash != address(0)){
//             poolInfo[pid].stash = stash;
//             IStaker(staker).setStashAccess(stash,true);
//             IRewardFactory(rewardFactory).setAccess(stash,true);
//         }
//         return true;
//     }

//     //shutdown pool
//     function shutdownPool(uint256 _pid) external returns(bool){
//         require(msg.sender==poolManager, "!auth");
//         PoolInfo storage pool = poolInfo[_pid];

//         //withdraw from gauge
//         try IStaker(staker).withdrawAll(pool.lptoken,pool.gauge){
//         }catch{}

//         pool.shutdown = true;
//         gaugeMap[pool.gauge] = false;
//         return true;
//     }

//     //shutdown this contract.
//     //  unstake and pull all lp tokens to this address
//     //  only allow withdrawals
//     function shutdownSystem() external{
//         require(msg.sender == owner, "!auth");
//         isShutdown = true;

//         for(uint i=0; i < poolInfo.length; i++){
//             PoolInfo storage pool = poolInfo[i];
//             if (pool.shutdown) continue;

//             address token = pool.lptoken;
//             address gauge = pool.gauge;

//             //withdraw from gauge
//             try IStaker(staker).withdrawAll(token,gauge){
//                 pool.shutdown = true;
//             }catch{}
//         }
//     }


//     //deposit lp tokens and stake
//     function deposit(uint256 _pid, uint256 _amount, bool _stake) public returns(bool){
//         require(!isShutdown,"shutdown");
//         PoolInfo storage pool = poolInfo[_pid];
//         require(pool.shutdown == false, "pool is closed");

//         //send to proxy to stake
//         address lptoken = pool.lptoken;
//         IERC20(lptoken).safeTransferFrom(msg.sender, staker, _amount);

//         //stake
//         address gauge = pool.gauge;
//         require(gauge != address(0),"!gauge setting");
//         IStaker(staker).deposit(lptoken,gauge);

//         //some gauges claim rewards when depositing, stash them in a seperate contract until next claim
//         address stash = pool.stash;
//         if(stash != address(0)){
//             IStash(stash).stashRewards();
//         }

//         address token = pool.token;
//         if(_stake){
//             //mint here and send to rewards on user behalf
//             ITokenMinter(token).mint(address(this),_amount);
//             address rewardContract = pool.crvRewards;
//             IERC20(token).safeApprove(rewardContract,0);
//             IERC20(token).safeApprove(rewardContract,_amount);
//             IRewards(rewardContract).stakeFor(msg.sender,_amount);
//         }else{
//             //add user balance directly
//             ITokenMinter(token).mint(msg.sender,_amount);
//         }

        
//         emit Deposited(msg.sender, _pid, _amount);
//         return true;
//     }

//     //deposit all lp tokens and stake
//     function depositAll(uint256 _pid, bool _stake) external returns(bool){
//         address lptoken = poolInfo[_pid].lptoken;
//         uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
//         deposit(_pid,balance,_stake);
//         return true;
//     }

//     //withdraw lp tokens
//     function _withdraw(uint256 _pid, uint256 _amount, address _from, address _to) internal {
//         PoolInfo storage pool = poolInfo[_pid];
//         address lptoken = pool.lptoken;
//         address gauge = pool.gauge;

//         //remove lp balance
//         address token = pool.token;
//         ITokenMinter(token).burn(_from,_amount);

//         //pull from gauge if not shutdown
//         // if shutdown tokens will be in this contract
//         if (!pool.shutdown) {
//             IStaker(staker).withdraw(lptoken,gauge, _amount);
//         }

//         //some gauges claim rewards when withdrawing, stash them in a seperate contract until next claim
//         //do not call if shutdown since stashes wont have access
//         address stash = pool.stash;
//         if(stash != address(0) && !isShutdown && !pool.shutdown){
//             IStash(stash).stashRewards();
//         }
        
//         //return lp tokens
//         IERC20(lptoken).safeTransfer(_to, _amount);

//         emit Withdrawn(_to, _pid, _amount);
//     }

//     //withdraw lp tokens
//     function withdraw(uint256 _pid, uint256 _amount) public returns(bool){
//         _withdraw(_pid,_amount,msg.sender,msg.sender);
//         return true;
//     }

//     //withdraw all lp tokens
//     function withdrawAll(uint256 _pid) public returns(bool){
//         address token = poolInfo[_pid].token;
//         uint256 userBal = IERC20(token).balanceOf(msg.sender);
//         withdraw(_pid, userBal);
//         return true;
//     }

//     //allow reward contracts to send here and withdraw to user
//     function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns(bool){
//         address rewardContract = poolInfo[_pid].crvRewards;
//         require(msg.sender == rewardContract,"!auth");

//         _withdraw(_pid,_amount,msg.sender,_to);
//         return true;
//     }


//     //delegate address votes on dao
//     function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool){
//         require(msg.sender == voteDelegate, "!auth");
//         require(_votingAddress == voteOwnership || _votingAddress == voteParameter, "!voteAddr");
        
//         IStaker(staker).vote(_voteId,_votingAddress,_support);
//         return true;
//     }

//     function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight ) external returns(bool){
//         require(msg.sender == voteDelegate, "!auth");

//         for(uint256 i = 0; i < _gauge.length; i++){
//             IStaker(staker).voteGaugeWeight(_gauge[i],_weight[i]);
//         }
//         return true;
//     }

//     function claimRewards(uint256 _pid, address _gauge) external returns(bool){
//         address stash = poolInfo[_pid].stash;
//         require(msg.sender == stash,"!auth");

//         IStaker(staker).claimRewards(_gauge);
//         return true;
//     }

//     function setGaugeRedirect(uint256 _pid) external returns(bool){
//         address stash = poolInfo[_pid].stash;
//         require(msg.sender == stash,"!auth");
//         address gauge = poolInfo[_pid].gauge;
//         bytes memory data = abi.encodeWithSelector(bytes4(keccak256("set_rewards_receiver(address)")), stash);
//         IStaker(staker).execute(gauge,uint256(0),data);
//         return true;
//     }

//     //claim crv and extra rewards and disperse to reward contracts
//     function _earmarkRewards(uint256 _pid) internal {
//         PoolInfo storage pool = poolInfo[_pid];
//         require(pool.shutdown == false, "pool is closed");

//         address gauge = pool.gauge;

//         //claim crv
//         IStaker(staker).claimCrv(gauge);

//         //check if there are extra rewards
//         address stash = pool.stash;
//         if(stash != address(0)){
//             //claim extra rewards
//             IStash(stash).claimRewards();
//             //process extra rewards
//             IStash(stash).processStash();
//         }

//         //crv balance
//         uint256 crvBal = IERC20(crv).balanceOf(address(this));

//         if (crvBal > 0) {
//             uint256 _lockIncentive = crvBal.mul(lockIncentive).div(FEE_DENOMINATOR);
//             uint256 _stakerIncentive = crvBal.mul(stakerIncentive).div(FEE_DENOMINATOR);
//             uint256 _callIncentive = crvBal.mul(earmarkIncentive).div(FEE_DENOMINATOR);
            
//             //send treasury
//             if(treasury != address(0) && treasury != address(this) && platformFee > 0){
//                 //only subtract after address condition check
//                 uint256 _platform = crvBal.mul(platformFee).div(FEE_DENOMINATOR);
//                 crvBal = crvBal.sub(_platform);
//                 IERC20(crv).safeTransfer(treasury, _platform);
//             }

//             //remove incentives from balance
//             crvBal = crvBal.sub(_lockIncentive).sub(_callIncentive).sub(_stakerIncentive);

//             //send incentives for calling
//             IERC20(crv).safeTransfer(msg.sender, _callIncentive);          

//             //send crv to lp provider reward contract
//             address rewardContract = pool.crvRewards;
//             IERC20(crv).safeTransfer(rewardContract, crvBal);
//             IRewards(rewardContract).queueNewRewards(crvBal);

//             //send lockers' share of crv to reward contract
//             IERC20(crv).safeTransfer(lockRewards, _lockIncentive);
//             IRewards(lockRewards).queueNewRewards(_lockIncentive);

//             //send stakers's share of crv to reward contract
//             IERC20(crv).safeTransfer(stakerRewards, _stakerIncentive);
//             IRewards(stakerRewards).queueNewRewards(_stakerIncentive);
//         }
//     }

//     function earmarkRewards(uint256 _pid) external returns(bool){
//         require(!isShutdown,"shutdown");
//         _earmarkRewards(_pid);
//         return true;
//     }

//     //claim fees from curve distro contract, put in lockers' reward contract
//     function earmarkFees() external returns(bool){
//         //claim fee rewards
//         IStaker(staker).claimFees(feeDistro, feeToken);
//         //send fee rewards to reward contract
//         uint256 _balance = IERC20(feeToken).balanceOf(address(this));
//         IERC20(feeToken).safeTransfer(lockFees, _balance);
//         IRewards(lockFees).queueNewRewards(_balance);
//         return true;
//     }

//     //callback from reward contract when crv is received.
//     function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns(bool){
//         address rewardContract = poolInfo[_pid].crvRewards;
//         require(msg.sender == rewardContract || msg.sender == lockRewards, "!auth");

//         //mint reward tokens
//         ITokenMinter(minter).mint(_address,_amount);
        
//         return true;
//     }

// }


// File contracts/Misc_AMOs/convex/IConvexBaseRewardPool.sol


interface IConvexBaseRewardPool {
  function addExtraReward(address _reward) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function currentRewards() external view returns (uint256);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward() external returns (bool);
  function getReward(address _account, bool _claimExtras) external returns (bool);
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function pid() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external returns (bool);
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external returns (bool);
  function stakeAll() external returns (bool);
  function stakeFor(address _for, uint256 _amount) external returns (bool);
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 amount, bool claim) external returns (bool);
  function withdrawAll(bool claim) external;
  function withdrawAllAndUnwrap(bool claim) external;
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}


// File contracts/Misc_AMOs/convex/IVirtualBalanceRewardPool.sol


interface IVirtualBalanceRewardPool {
    function balanceOf(address account) external view returns (uint256);
    function currentRewards() external view returns (uint256);
    function deposits() external view returns (address);
    function donate(uint256 _amount) external returns (bool);
    function duration() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getReward(address _account) external;
    function historicalRewards() external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function newRewardRatio() external view returns (uint256);
    function operator() external view returns (address);
    function periodFinish() external view returns (uint256);
    function queueNewRewards(uint256 _rewards) external;
    function queuedRewards() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardToken() external view returns (address);
    function rewards(address) external view returns (uint256);
    function stake(address _account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function userRewardPerTokenPaid(address) external view returns (uint256);
    function withdraw(address _account, uint256 amount) external;
}


// File contracts/Misc_AMOs/convex/IConvexClaimZap.sol


interface IConvexClaimZap {
  function chefRewards() external view returns (address);
  function claimRewards(address[] calldata rewardContracts, uint256[] calldata chefIds, bool claimCvx, bool claimCvxStake, bool claimcvxCrv, uint256 depositCrvMaxAmount, uint256 depositCvxMaxAmount) external;
  function crv() external view returns (address);
  function crvDeposit() external view returns (address);
  function cvx() external view returns (address);
  function cvxCrv() external view returns (address);
  function cvxCrvRewards() external view returns (address);
  function cvxRewards() external view returns (address);
  function owner() external view returns (address);
  function setApprovals() external;
  function setChefRewards(address _rewards) external;
}



// /**
//  * @dev Collection of functions related to the address type
//  */
// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * [IMPORTANT]
//      * ====
//      * It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      *
//      * Among others, `isContract` will return false for the following
//      * types of addresses:
//      *
//      *  - an externally-owned account
//      *  - a contract in construction
//      *  - an address where a contract will be created
//      *  - an address where a contract lived, but was destroyed
//      * ====
//      */
//     function isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { size := extcodesize(account) }
//         return size > 0;
//     }

//     /**
//      * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//      * `recipient`, forwarding all available gas and reverting on errors.
//      *
//      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//      * of certain opcodes, possibly making contracts go over the 2300 gas limit
//      * imposed by `transfer`, making them unable to receive funds via
//      * `transfer`. {sendValue} removes this limitation.
//      *
//      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//      *
//      * IMPORTANT: because control is transferred to `recipient`, care must be
//      * taken to not create reentrancy vulnerabilities. Consider using
//      * {ReentrancyGuard} or the
//      * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//      */
//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//         (bool success, ) = recipient.call{ value: amount }("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     /**
//      * @dev Performs a Solidity function call using a low level `call`. A
//      * plain`call` is an unsafe replacement for a function call: use this
//      * function instead.
//      *
//      * If `target` reverts with a revert reason, it is bubbled up by this
//      * function (like regular Solidity function calls).
//      *
//      * Returns the raw returned data. To convert to the expected return value,
//      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
//      *
//      * Requirements:
//      *
//      * - `target` must be a contract.
//      * - calling `target` with `data` must not revert.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//       return functionCall(target, data, "Address: low-level call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
//      * `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, 0, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but also transferring `value` wei to `target`.
//      *
//      * Requirements:
//      *
//      * - the calling contract must have an ETH balance of at least `value`.
//      * - the called Solidity function must be `payable`.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
//      * with `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: value }(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
//         return functionStaticCall(target, data, "Address: low-level static call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
//         require(isContract(target), "Address: static call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.staticcall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         require(isContract(target), "Address: delegate call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.delegatecall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }
// }

// // File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }


// // File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         uint256 c = a + b;
//         if (c < a) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the substraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b > a) return (false, 0);
//         return (true, a - b);
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) return (true, 0);
//         uint256 c = a * b;
//         if (c / a != b) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a / b);
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a % b);
//     }

//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      *
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b <= a, "SafeMath: subtraction overflow");
//         return a - b;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      *
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         if (a == 0) return 0;
//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: division by zero");
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: modulo by zero");
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         return a - b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryDiv}.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a % b;
//     }
// }


// // File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol




// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
// library SafeERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(IERC20 token, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     /**
//      * @dev Deprecated. This function has issues similar to the ones found in
//      * {IERC20-approve}, and its usage is discouraged.
//      *
//      * Whenever possible, use {safeIncreaseAllowance} and
//      * {safeDecreaseAllowance} instead.
//      */
//     function safeApprove(IERC20 token, address spender, uint256 value) internal {
//         // safeApprove should only be called when setting an initial allowance,
//         // or when resetting it to zero. To increase and decrease it, use
//         // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
//         // solhint-disable-next-line max-line-length
//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }

//     function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(value);
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     /**
//      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
//      * on the return value: the return value is optional (but if data is returned, it must not be false).
//      * @param token The token targeted by the call.
//      * @param data The call data (encoded using abi.encode or one of its variants).
//      */
//     function _callOptionalReturn(IERC20 token, bytes memory data) private {
//         // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
//         // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
//         // the target address contains contract code and also asserts for success in the low-level call.

//         bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
//         if (returndata.length > 0) { // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
//         }
//     }
// }

// // File: contracts\ClaimZap.sol


// library Math {
//     /**
//      * @dev Returns the smallest of two numbers.
//      */
//     function min(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a < b ? a : b;
//     }
// }

// interface IBasicRewards{
//     function getReward(address _account, bool _claimExtras) external;
//     function stakeFor(address, uint256) external;
// }

// interface ICvxRewards{
//     function getReward(address _account, bool _claimExtras, bool _stake) external;
// }

// interface IChefRewards{
//     function claim(uint256 _pid, address _account) external;
// }

// interface ICvxCrvDeposit{
//     function deposit(uint256, bool) external;
// }

// contract ClaimZap{
//     using SafeERC20 for IERC20;
//     using Address for address;
//     using SafeMath for uint256;

//     address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
//     address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
//     address public constant cvxCrv = address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
//     address public constant crvDeposit = address(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);
//     address public constant cvxCrvRewards = address(0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
//     address public constant cvxRewards = address(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);

//     address public immutable owner;
//     address public chefRewards;

//     constructor () public {
//         owner = msg.sender;
//         chefRewards = address(0x5F465e9fcfFc217c5849906216581a657cd60605);
//     }

//     function setChefRewards(address _rewards) external {
//         require(msg.sender == owner, "!auth");
//         chefRewards = _rewards;
//     }

//     function setApprovals() external {
//         require(msg.sender == owner, "!auth");
//         IERC20(crv).safeApprove(crvDeposit, 0);
//         IERC20(crv).safeApprove(crvDeposit, uint256(-1));
//         IERC20(cvx).safeApprove(cvxRewards, 0);
//         IERC20(cvx).safeApprove(cvxRewards, uint256(-1));
//         IERC20(cvxCrv).safeApprove(cvxCrvRewards, 0);
//         IERC20(cvxCrv).safeApprove(cvxCrvRewards, uint256(-1));
//     }

//     function claimRewards(
//         address[] calldata rewardContracts,
//         uint256[] calldata chefIds,
//         bool claimCvx,
//         bool claimCvxStake,
//         bool claimcvxCrv,
//         uint256 depositCrvMaxAmount,
//         uint256 depositCvxMaxAmount
//         ) external{

//         //claim from main curve LP pools
//         for(uint256 i = 0; i < rewardContracts.length; i++){
//             if(rewardContracts[i] == address(0)) break;
//             IBasicRewards(rewardContracts[i]).getReward(msg.sender,true);
//         }

//         //claim from master chef
//         for(uint256 i = 0; i < chefIds.length; i++){
//             IChefRewards(chefRewards).claim(chefIds[i],msg.sender);
//         }

//         //claim (and stake) from cvx rewards
//         if(claimCvxStake){
//             ICvxRewards(cvxRewards).getReward(msg.sender,true,true);
//         }else if(claimCvx){
//             ICvxRewards(cvxRewards).getReward(msg.sender,true,false);
//         }

//         //claim from cvxCrv rewards
//         if(claimcvxCrv){
//             IBasicRewards(cvxCrvRewards).getReward(msg.sender,true);
//         }

//         //lock upto given amount of crv and stake
//         if(depositCrvMaxAmount > 0){
//             uint256 crvBalance = IERC20(crv).balanceOf(msg.sender);
//             crvBalance = Math.min(crvBalance, depositCrvMaxAmount);
//             if(crvBalance > 0){
//                 //pull crv
//                 IERC20(crv).safeTransferFrom(msg.sender, address(this), crvBalance);
//                 //deposit
//                 ICvxCrvDeposit(crvDeposit).deposit(crvBalance,true);
//                 //get cvxamount
//                 uint256 cvxCrvBalance = IERC20(cvxCrv).balanceOf(address(this));
//                 //stake for msg.sender
//                 IBasicRewards(cvxCrvRewards).stakeFor(msg.sender, cvxCrvBalance);
//             }
//         }

//         //stake upto given amount of cvx
//         if(depositCvxMaxAmount > 0){
//             uint256 cvxBalance = IERC20(cvx).balanceOf(msg.sender);
//             cvxBalance = Math.min(cvxBalance, depositCvxMaxAmount);
//             if(cvxBalance > 0){
//                 //pull cvx
//                 IERC20(cvx).safeTransferFrom(msg.sender, address(this), cvxBalance);
//                 //stake for msg.sender
//                 IBasicRewards(cvxRewards).stakeFor(msg.sender, cvxBalance);
//             }
//         }
//     }
// }


// File contracts/Misc_AMOs/convex/IcvxRewardPool.sol


interface IcvxRewardPool {
  function FEE_DENOMINATOR() external view returns (uint256);
  function addExtraReward(address _reward) external;
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function crvDeposits() external view returns (address);
  function currentRewards() external view returns (uint256);
  function cvxCrvRewards() external view returns (address);
  function cvxCrvToken() external view returns (address);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward(bool _stake) external;
  function getReward(address _account, bool _claimExtras, bool _stake) external;
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external;
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external;
  function stakeAll() external;
  function stakeFor(address _for, uint256 _amount) external;
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 _amount, bool claim) external;
  function withdrawAll(bool claim) external;
}


// /**
//  * @dev Standard math utilities missing in the Solidity language.
//  */
// library MathUtil {
//     /**
//      * @dev Returns the smallest of two numbers.
//      */
//     function min(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a < b ? a : b;
//     }
// }

// contract ReentrancyGuard {
//     uint256 private _guardCounter;

//     constructor () internal {
//         _guardCounter = 1;
//     }

//     modifier nonReentrant() {
//         _guardCounter += 1;
//         uint256 localCounter = _guardCounter;
//         _;
//         require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
//     }
// }

// interface ICurveGauge {
//     function deposit(uint256) external;
//     function balanceOf(address) external view returns (uint256);
//     function withdraw(uint256) external;
//     function claim_rewards() external;
//     function reward_tokens(uint256) external view returns(address);//v2
//     function rewarded_token() external view returns(address);//v1
// }

// interface ICurveVoteEscrow {
//     function create_lock(uint256, uint256) external;
//     function increase_amount(uint256) external;
//     function increase_unlock_time(uint256) external;
//     function withdraw() external;
//     function smart_wallet_checker() external view returns (address);
// }

// interface IWalletChecker {
//     function check(address) external view returns (bool);
// }

// interface IVoting{
//     function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
//     function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory); 
//     function vote_for_gauge_weights(address,uint256) external;
// }

// interface IMinter{
//     function mint(address) external;
// }

// interface IRegistry{
//     function get_registry() external view returns(address);
//     function get_address(uint256 _id) external view returns(address);
//     function gauge_controller() external view returns(address);
//     function get_lp_token(address) external view returns(address);
//     function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
// }

// interface IStaker{
//     function deposit(address, address) external;
//     function withdraw(address) external;
//     function withdraw(address, address, uint256) external;
//     function withdrawAll(address, address) external;
//     function createLock(uint256, uint256) external;
//     function increaseAmount(uint256) external;
//     function increaseTime(uint256) external;
//     function release() external;
//     function claimCrv(address) external returns (uint256);
//     function claimRewards(address) external;
//     function claimFees(address,address) external;
//     function setStashAccess(address, bool) external;
//     function vote(uint256,address,bool) external;
//     function voteGaugeWeight(address,uint256) external;
//     function balanceOfPool(address) external view returns (uint256);
//     function operator() external view returns (address);
//     function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
// }

// interface IRewards{
//     function stake(address, uint256) external;
//     function stakeFor(address, uint256) external;
//     function withdraw(address, uint256) external;
//     function exit(address) external;
//     function getReward(address) external;
//     function queueNewRewards(uint256) external;
//     function notifyRewardAmount(uint256) external;
//     function addExtraReward(address) external;
//     function stakingToken() external returns (address);
// }

// interface IStash{
//     function stashRewards() external returns (bool);
//     function processStash() external returns (bool);
//     function claimRewards() external returns (bool);
// }

// interface IFeeDistro{
//     function claim() external;
//     function token() external view returns(address);
// }

// interface ITokenMinter{
//     function mint(address,uint256) external;
//     function burn(address,uint256) external;
// }

// interface IDeposit{
//     function isShutdown() external view returns(bool);
//     function balanceOf(address _account) external view returns(uint256);
//     function totalSupply() external view returns(uint256);
//     function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
//     function rewardClaimed(uint256,address,uint256) external;
//     function withdrawTo(uint256,uint256,address) external;
//     function claimRewards(uint256,address) external returns(bool);
//     function rewardArbitrator() external returns(address);
// }

// interface ICrvDeposit{
//     function deposit(uint256, bool) external;
//     function lockIncentive() external view returns(uint256);
// }

// interface IRewardFactory{
//     function setAccess(address,bool) external;
//     function CreateCrvRewards(uint256,address) external returns(address);
//     function CreateTokenRewards(address,address,address) external returns(address);
//     function activeRewardCount(address) external view returns(uint256);
//     function addActiveReward(address,uint256) external returns(bool);
//     function removeActiveReward(address,uint256) external returns(bool);
// }

// interface IStashFactory{
//     function CreateStash(uint256,address,address,uint256) external returns(address);
// }

// interface ITokenFactory{
//     function CreateDepositToken(address) external returns(address);
// }

// interface IPools{
//     function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
//     function shutdownPool(uint256 _pid) external returns(bool);
//     function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
//     function poolLength() external view returns (uint256);
//     function gaugeMap(address) external view returns(bool);
//     function setPoolManager(address _poolM) external;
// }



// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         uint256 c = a + b;
//         if (c < a) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the substraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b > a) return (false, 0);
//         return (true, a - b);
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) return (true, 0);
//         uint256 c = a * b;
//         if (c / a != b) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a / b);
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a % b);
//     }

//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      *
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b <= a, "SafeMath: subtraction overflow");
//         return a - b;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      *
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         if (a == 0) return 0;
//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: division by zero");
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: modulo by zero");
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         return a - b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryDiv}.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a % b;
//     }
// }

// // File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// // File: @openzeppelin\contracts\utils\Address.sol


// /**
//  * @dev Collection of functions related to the address type
//  */
// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * [IMPORTANT]
//      * ====
//      * It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      *
//      * Among others, `isContract` will return false for the following
//      * types of addresses:
//      *
//      *  - an externally-owned account
//      *  - a contract in construction
//      *  - an address where a contract will be created
//      *  - an address where a contract lived, but was destroyed
//      * ====
//      */
//     function isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { size := extcodesize(account) }
//         return size > 0;
//     }

//     /**
//      * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//      * `recipient`, forwarding all available gas and reverting on errors.
//      *
//      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//      * of certain opcodes, possibly making contracts go over the 2300 gas limit
//      * imposed by `transfer`, making them unable to receive funds via
//      * `transfer`. {sendValue} removes this limitation.
//      *
//      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//      *
//      * IMPORTANT: because control is transferred to `recipient`, care must be
//      * taken to not create reentrancy vulnerabilities. Consider using
//      * {ReentrancyGuard} or the
//      * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//      */
//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//         (bool success, ) = recipient.call{ value: amount }("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     /**
//      * @dev Performs a Solidity function call using a low level `call`. A
//      * plain`call` is an unsafe replacement for a function call: use this
//      * function instead.
//      *
//      * If `target` reverts with a revert reason, it is bubbled up by this
//      * function (like regular Solidity function calls).
//      *
//      * Returns the raw returned data. To convert to the expected return value,
//      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
//      *
//      * Requirements:
//      *
//      * - `target` must be a contract.
//      * - calling `target` with `data` must not revert.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//       return functionCall(target, data, "Address: low-level call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
//      * `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, 0, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but also transferring `value` wei to `target`.
//      *
//      * Requirements:
//      *
//      * - the calling contract must have an ETH balance of at least `value`.
//      * - the called Solidity function must be `payable`.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
//      * with `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: value }(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
//         return functionStaticCall(target, data, "Address: low-level static call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
//         require(isContract(target), "Address: static call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.staticcall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         require(isContract(target), "Address: delegate call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.delegatecall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }
// }


// // File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol



// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
// library SafeERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(IERC20 token, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     /**
//      * @dev Deprecated. This function has issues similar to the ones found in
//      * {IERC20-approve}, and its usage is discouraged.
//      *
//      * Whenever possible, use {safeIncreaseAllowance} and
//      * {safeDecreaseAllowance} instead.
//      */
//     function safeApprove(IERC20 token, address spender, uint256 value) internal {
//         // safeApprove should only be called when setting an initial allowance,
//         // or when resetting it to zero. To increase and decrease it, use
//         // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
//         // solhint-disable-next-line max-line-length
//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }

//     function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(value);
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     /**
//      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
//      * on the return value: the return value is optional (but if data is returned, it must not be false).
//      * @param token The token targeted by the call.
//      * @param data The call data (encoded using abi.encode or one of its variants).
//      */
//     function _callOptionalReturn(IERC20 token, bytes memory data) private {
//         // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
//         // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
//         // the target address contains contract code and also asserts for success in the low-level call.

//         bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
//         if (returndata.length > 0) { // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
//         }
//     }
// }

// // File: contracts\cvxRewardPool.sol

// /**
//  *Submitted for verification at Etherscan.io on 2020-07-17
//  */

// /*
//    ____            __   __        __   _
//   / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
//  _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
// /___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
//      /___/

// * Synthetix: cvxRewardPool.sol
// *
// * Docs: https://docs.synthetix.io/
// *
// *
// * MIT License
// * ===========
// *
// * Copyright (c) 2020 Synthetix
// *
// * Permission is hereby granted, free of charge, to any person obtaining a copy
// * of this software and associated documentation files (the "Software"), to deal
// * in the Software without restriction, including without limitation the rights
// * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// * copies of the Software, and to permit persons to whom the Software is
// * furnished to do so, subject to the following conditions:
// *
// * The above copyright notice and this permission notice shall be included in all
// * copies or substantial portions of the Software.
// *
// * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// */



// contract cvxRewardPool{
//     using SafeERC20 for IERC20;
//     using SafeMath for uint256;

//     IERC20 public immutable rewardToken;
//     IERC20 public immutable stakingToken;
//     uint256 public constant duration = 7 days;
//     uint256 public constant FEE_DENOMINATOR = 10000;

//     address public immutable operator;
//     address public immutable crvDeposits;
//     address public immutable cvxCrvRewards;
//     IERC20 public immutable cvxCrvToken;
//     address public immutable rewardManager;

//     uint256 public periodFinish = 0;
//     uint256 public rewardRate = 0;
//     uint256 public lastUpdateTime;
//     uint256 public rewardPerTokenStored;
//     uint256 public queuedRewards = 0;
//     uint256 public currentRewards = 0;
//     uint256 public historicalRewards = 0;
//     uint256 public constant newRewardRatio = 830;
//     uint256 private _totalSupply;
//     mapping(address => uint256) private _balances;
//     mapping(address => uint256) public userRewardPerTokenPaid;
//     mapping(address => uint256) public rewards;

//     address[] public extraRewards;

//     event RewardAdded(uint256 reward);
//     event Staked(address indexed user, uint256 amount);
//     event Withdrawn(address indexed user, uint256 amount);
//     event RewardPaid(address indexed user, uint256 reward);

//     constructor (
//         address stakingToken_,
//         address rewardToken_,
//         address crvDeposits_,
//         address cvxCrvRewards_,
//         address cvxCrvToken_,
//         address operator_,
//         address rewardManager_
//     ) public {
//         stakingToken = IERC20(stakingToken_);
//         rewardToken = IERC20(rewardToken_);
//         operator = operator_;
//         rewardManager = rewardManager_;
//         crvDeposits = crvDeposits_;
//         cvxCrvRewards = cvxCrvRewards_;
//         cvxCrvToken = IERC20(cvxCrvToken_);
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address account) public view returns (uint256) {
//         return _balances[account];
//     }

//     function extraRewardsLength() external view returns (uint256) {
//         return extraRewards.length;
//     }

//     function addExtraReward(address _reward) external {
//         require(msg.sender == rewardManager, "!authorized");
//         require(_reward != address(0),"!reward setting");

//         extraRewards.push(_reward);
//     }
//     function clearExtraRewards() external{
//         require(msg.sender == rewardManager, "!authorized");
//         delete extraRewards;
//     }

//     modifier updateReward(address account) {
//         rewardPerTokenStored = rewardPerToken();
//         lastUpdateTime = lastTimeRewardApplicable();
//         if (account != address(0)) {
//             rewards[account] = earnedReward(account);
//             userRewardPerTokenPaid[account] = rewardPerTokenStored;
//         }
//         _;
//     }

//     function lastTimeRewardApplicable() internal view returns (uint256) {
//         return MathUtil.min(block.timestamp, periodFinish);
//     }

//     function rewardPerToken() internal view returns (uint256) {
//         uint256 supply = totalSupply();
//         if (supply == 0) {
//             return rewardPerTokenStored;
//         }
//         return
//             rewardPerTokenStored.add(
//                 lastTimeRewardApplicable()
//                     .sub(lastUpdateTime)
//                     .mul(rewardRate)
//                     .mul(1e18)
//                     .div(supply)
//             );
//     }

//     function earnedReward(address account) internal view returns (uint256) {
//         return
//             balanceOf(account)
//                 .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
//                 .div(1e18)
//                 .add(rewards[account]);
//     }

//     function earned(address account) external view returns (uint256) {
//         uint256 depositFeeRate = ICrvDeposit(crvDeposits).lockIncentive();

//         uint256 r = earnedReward(account);
//         uint256 fees = r.mul(depositFeeRate).div(FEE_DENOMINATOR);
        
//         //fees dont apply until whitelist+vecrv lock begins so will report
//         //slightly less value than what is actually received.
//         return r.sub(fees);
//     }

//     function stake(uint256 _amount)
//         public
//         updateReward(msg.sender)
//     {
//         require(_amount > 0, 'RewardPool : Cannot stake 0');

//         //also stake to linked rewards
//         uint256 length = extraRewards.length;
//         for(uint i=0; i < length; i++){
//             IRewards(extraRewards[i]).stake(msg.sender, _amount);
//         }

//         //add supply
//         _totalSupply = _totalSupply.add(_amount);
//         //add to sender balance sheet
//         _balances[msg.sender] = _balances[msg.sender].add(_amount);
//         //take tokens from sender
//         stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

//         emit Staked(msg.sender, _amount);
//     }

//     function stakeAll() external{
//         uint256 balance = stakingToken.balanceOf(msg.sender);
//         stake(balance);
//     }

//     function stakeFor(address _for, uint256 _amount)
//         public
//         updateReward(_for)
//     {
//         require(_amount > 0, 'RewardPool : Cannot stake 0');

//         //also stake to linked rewards
//         uint256 length = extraRewards.length;
//         for(uint i=0; i < length; i++){
//             IRewards(extraRewards[i]).stake(_for, _amount);
//         }

//          //add supply
//         _totalSupply = _totalSupply.add(_amount);
//         //add to _for's balance sheet
//         _balances[_for] = _balances[_for].add(_amount);
//         //take tokens from sender
//         stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

//         emit Staked(msg.sender, _amount);
//     }

//     function withdraw(uint256 _amount, bool claim)
//         public
//         updateReward(msg.sender)
//     {
//         require(_amount > 0, 'RewardPool : Cannot withdraw 0');

//         //also withdraw from linked rewards
//         uint256 length = extraRewards.length;
//         for(uint i=0; i < length; i++){
//             IRewards(extraRewards[i]).withdraw(msg.sender, _amount);
//         }

//         _totalSupply = _totalSupply.sub(_amount);
//         _balances[msg.sender] = _balances[msg.sender].sub(_amount);
//         stakingToken.safeTransfer(msg.sender, _amount);
//         emit Withdrawn(msg.sender, _amount);

//         if(claim){
//             getReward(msg.sender,true,false);
//         }
//     }

//     function withdrawAll(bool claim) external{
//         withdraw(_balances[msg.sender],claim);
//     }

//     function getReward(address _account, bool _claimExtras, bool _stake) public updateReward(_account){
//         uint256 reward = earnedReward(_account);
//         if (reward > 0) {
//             rewards[_account] = 0;
//             rewardToken.safeApprove(crvDeposits,0);
//             rewardToken.safeApprove(crvDeposits,reward);
//             ICrvDeposit(crvDeposits).deposit(reward,false);

//             uint256 cvxCrvBalance = cvxCrvToken.balanceOf(address(this));
//             if(_stake){
//                 IERC20(cvxCrvToken).safeApprove(cvxCrvRewards,0);
//                 IERC20(cvxCrvToken).safeApprove(cvxCrvRewards,cvxCrvBalance);
//                 IRewards(cvxCrvRewards).stakeFor(_account,cvxCrvBalance);
//             }else{
//                 cvxCrvToken.safeTransfer(_account, cvxCrvBalance);
//             }
//             emit RewardPaid(_account, cvxCrvBalance);
//         }

//         //also get rewards from linked rewards
//         if(_claimExtras){
//             uint256 length = extraRewards.length;
//             for(uint i=0; i < length; i++){
//                 IRewards(extraRewards[i]).getReward(_account);
//             }
//         }
//     }

//     function getReward(bool _stake) external{
//         getReward(msg.sender,true, _stake);
//     }

//     function donate(uint256 _amount) external returns(bool){
//         IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
//         queuedRewards = queuedRewards.add(_amount);
//     }

//     function queueNewRewards(uint256 _rewards) external{
//         require(msg.sender == operator, "!authorized");

//         _rewards = _rewards.add(queuedRewards);

//         if (block.timestamp >= periodFinish) {
//             notifyRewardAmount(_rewards);
//             queuedRewards = 0;
//             return;
//         }

//         //et = now - (finish-duration)
//         uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
//         //current at now: rewardRate * elapsedTime
//         uint256 currentAtNow = rewardRate * elapsedTime;
//         uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
//         if(queuedRatio < newRewardRatio){
//             notifyRewardAmount(_rewards);
//             queuedRewards = 0;
//         }else{
//             queuedRewards = _rewards;
//         }
//     }

//     function notifyRewardAmount(uint256 reward)
//         internal
//         updateReward(address(0))
//     {
//         historicalRewards = historicalRewards.add(reward);
//         if (block.timestamp >= periodFinish) {
//             rewardRate = reward.div(duration);
//         } else {
//             uint256 remaining = periodFinish.sub(block.timestamp);
//             uint256 leftover = remaining.mul(rewardRate);
//             reward = reward.add(leftover);
//             rewardRate = reward.div(duration);
//         }
//         currentRewards = reward;
//         lastUpdateTime = block.timestamp;
//         periodFinish = block.timestamp.add(duration);
//         emit RewardAdded(reward);
//     }
// }


// File contracts/Frax/IFrax.sol


interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}


// File contracts/Frax/IFraxAMOMinter.sol


// MAY need to be updated
interface IFraxAMOMinter {
  function FRAX() external view returns(address);
  function FXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amos_array(uint256) external view returns(address);
  function burnFraxFromAMO(uint256 frax_amount) external;
  function burnFxsFromAMO(uint256 fxs_amount) external;
  function col_idx() external view returns(uint256);
  function collatDollarBalance() external view returns(uint256);
  function collatDollarBalanceStored() external view returns(uint256);
  function collat_borrow_cap() external view returns(int256);
  function collat_borrowed_balances(address) external view returns(int256);
  function collat_borrowed_sum() external view returns(int256);
  function collateral_address() external view returns(address);
  function collateral_token() external view returns(address);
  function correction_offsets_amos(address, uint256) external view returns(int256);
  function custodian_address() external view returns(address);
  function dollarBalances() external view returns(uint256 frax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function fraxDollarBalanceStored() external view returns(uint256);
  function fraxTrackedAMO(address amo_address) external view returns(int256);
  function fraxTrackedGlobal() external view returns(int256);
  function frax_mint_balances(address) external view returns(int256);
  function frax_mint_cap() external view returns(int256);
  function frax_mint_sum() external view returns(int256);
  function fxs_mint_balances(address) external view returns(int256);
  function fxs_mint_cap() external view returns(int256);
  function fxs_mint_sum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function min_cr() external view returns(uint256);
  function mintFraxForAMO(address destination_amo, uint256 frax_amount) external;
  function mintFxsForAMO(address destination_amo, uint256 fxs_amount) external;
  function missing_decimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 frax_amount) external;
  function old_pool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 frax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setFraxMintCap(uint256 _frax_mint_cap) external;
  function setFraxPool(address _pool_address) external;
  function setFxsMintCap(uint256 _fxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncDollarBalances() external;
  function timelock_address() external view returns(address);
}


// File contracts/Uniswap/TransferHelper.sol


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


// File contracts/Common/Context.sol


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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/Math/SafeMath.sol


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


// File contracts/ERC20/IERC20.sol



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


// File contracts/Utils/Address.sol


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/ERC20/ERC20.sol





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File contracts/Proxy/Initializable.sol


// solhint-disable-next-line compiler-version

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/Staking/Owned.sol


// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// File contracts/Misc_AMOs/MIM_Convex_AMO.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== MIM_Convex_AMO ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Jason Huan: https://github.com/jasonhuan

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett














contract MIM_Convex_AMO is Owned {
    using SafeMath for uint256;
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    IFrax private FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    ERC20 private collateral_token = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IFraxAMOMinter private amo_minter;

    // Curve-related
    IMetaImplementationUSD private mim3crv_metapool;
    IStableSwap3Pool private three_pool;
    ERC20 private three_pool_erc20;

    // MIM-related
    ERC20 private MIM = ERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    IConvexBooster private convex_booster;
    IConvexBaseRewardPool private convex_base_reward_pool;
    IConvexClaimZap private convex_claim_zap;
    IVirtualBalanceRewardPool private convex_spell_rewards_pool;
    IcvxRewardPool private cvx_reward_pool;
    ERC20 private cvx;
    address private cvx_crv_address;
    uint256 private lp_deposit_pid;

    address private crv_address;
    address private constant spell_address = 0x090185f2135308BaD17527004364eBcC2D37e5F6;
    address private mim3crv_metapool_address;

    address public timelock_address;
    address public custodian_address;

    // Number of decimals under 18, for collateral token
    uint256 private missing_decimals;

    // Precision related
    uint256 private PRICE_PRECISION;

    // Min ratio of collat <-> 3crv conversions via add_liquidity / remove_liquidity; 1e6
    uint256 public liq_slippage_3crv;

    // Min ratio of (MIM + 3CRV) <-> MIMCRV-f-2 metapool conversions via add_liquidity / remove_liquidity; 1e6
    uint256 public slippage_metapool;

    // Discount
    bool public set_discount;
    uint256 public discount_rate;

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _owner_address,
        address _amo_minter_address
    ) Owned(_owner_address) {
        owner = _owner_address;
        missing_decimals = 12;

        mim3crv_metapool_address = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
        mim3crv_metapool = IMetaImplementationUSD(mim3crv_metapool_address);
        three_pool = IStableSwap3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
        three_pool_erc20 = ERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
        amo_minter = IFraxAMOMinter(_amo_minter_address);

        // Convex MIM-related 
        convex_booster = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
        convex_base_reward_pool = IConvexBaseRewardPool(0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771);
        convex_claim_zap = IConvexClaimZap(0x4890970BB23FCdF624A0557845A29366033e6Fa2);
        cvx_reward_pool = IcvxRewardPool(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
        cvx = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
        cvx_crv_address = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
        crv_address = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        convex_spell_rewards_pool = IVirtualBalanceRewardPool(0x69a92f1656cd2e193797546cFe2EaF32EACcf6f7);
        lp_deposit_pid = 40;

        // Other variable initializations
        PRICE_PRECISION = 1e6;
        liq_slippage_3crv = 800000;
        slippage_metapool = 950000;

        // Get the custodian and timelock addresses from the minter
        custodian_address = amo_minter.custodian_address();
        timelock_address = amo_minter.timelock_address();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyByMinter() {
        require(msg.sender == address(amo_minter), "Not minter");
        _;
    }

    /* ========== VIEWS ========== */

    function showAllocations() public view returns (uint256[10] memory return_arr) {
        // ------------LP Balance------------

        // Free LP
        uint256 lp_owned = (mim3crv_metapool.balanceOf(address(this)));

        // Staked in the vault
        uint256 lp_value_in_vault = MIM3CRVInVault();
        lp_owned = lp_owned.add(lp_value_in_vault);

        // ------------3pool Withdrawable------------
        uint256 mim3crv_supply = mim3crv_metapool.totalSupply();

        uint256 mim_withdrawable = 0;
        uint256 _3pool_withdrawable = 0;
        if (lp_owned > 0) _3pool_withdrawable = mim3crv_metapool.calc_withdraw_one_coin(lp_owned, 1); // 1: 3pool index
         
        // ------------MIM Balance------------
        // MIM sums
        uint256 mim_in_contract = MIM.balanceOf(address(this));

        // ------------Collateral Balance------------
        // Free Collateral
        uint256 usdc_in_contract = collateral_token.balanceOf(address(this));

        // Returns the dollar value withdrawable of USDC if the contract redeemed its 3CRV from the metapool; assume 1 USDC = $1
        uint256 usdc_withdrawable = _3pool_withdrawable.mul(three_pool.get_virtual_price()).div(1e18).div(10 ** missing_decimals);

        // USDC subtotal
        uint256 usdc_subtotal = usdc_in_contract.add(usdc_withdrawable);

        return [
            mim_in_contract, // [0] Free MIM in the contract
            mim_withdrawable, // [1] MIM withdrawable from the MIM3CRV tokens
            mim_withdrawable.add(mim_in_contract), // [2] MIM withdrawable + free MIM in the the contract
            usdc_in_contract, // [3] Free USDC
            usdc_withdrawable, // [4] USDC withdrawable from the MIM3CRV tokens
            usdc_subtotal, // [5] USDC Total
            lp_owned, // [6] MIM3CRV free or in the vault
            mim3crv_supply, // [7] Total supply of MIM3CRV tokens
            _3pool_withdrawable, // [8] 3pool withdrawable from the MIM3CRV tokens
            lp_value_in_vault // [9] MIM3CRV in the vault
        ];
    }

    function dollarBalances() public view returns (uint256 frax_val_e18, uint256 collat_val_e18) {
        // Get the allocations
        uint256[10] memory allocations = showAllocations();

        frax_val_e18 = 1e18; // don't have FRAX in this contract
        collat_val_e18 = allocations[2].add((allocations[5]).mul(10 ** missing_decimals)); // all MIM (valued at $1) plus USDC in this contract
    }

    function showRewards() public view returns (uint256[4] memory return_arr) {
        return_arr[0] = convex_base_reward_pool.earned(address(this)); // CRV claimable
        return_arr[1] = 0; // CVX claimable. PITA to calculate. See https://docs.convexfinance.com/convexfinanceintegration/cvx-minting
        return_arr[2] = cvx_reward_pool.earned(address(this)); // cvxCRV claimable
        return_arr[3] = convex_spell_rewards_pool.earned(address(this)); // SPELL claimable
    }

    function MIM3CRVInVault() public view returns (uint256) {
        return convex_base_reward_pool.balanceOf(address(this));
    }

    // Backwards compatibility
    function mintedBalance() public view returns (int256) {
        return amo_minter.frax_mint_balances(address(this));
    }

    function usdValueInVault() public view returns (uint256) {
        uint256 vault_balance = MIM3CRVInVault();
        return vault_balance.mul(mim3crv_metapool.get_virtual_price()).div(1e18);
    }
    
    /* ========== RESTRICTED FUNCTIONS ========== */

    function metapoolDeposit(uint256 _MIM_Convex_AMOunt, uint256 _collateral_amount) external onlyByOwnGov returns (uint256 metapool_LP_received) {
        uint256 threeCRV_received = 0;
        if (_collateral_amount > 0) {
            // Approve the collateral to be added to 3pool
            collateral_token.approve(address(three_pool), _collateral_amount);

            // Convert collateral into 3pool
            uint256[3] memory three_pool_collaterals;
            three_pool_collaterals[1] = _collateral_amount;
            {
                uint256 min_3pool_out = (_collateral_amount * (10 ** missing_decimals)).mul(liq_slippage_3crv).div(PRICE_PRECISION);
                three_pool.add_liquidity(three_pool_collaterals, min_3pool_out);
            }

            // Approve the 3pool for the metapool
            threeCRV_received = three_pool_erc20.balanceOf(address(this));

            // WEIRD ISSUE: NEED TO DO three_pool_erc20.approve(address(three_pool), 0); first before every time
            // May be related to https://github.com/vyperlang/vyper/blob/3e1ff1eb327e9017c5758e24db4bdf66bbfae371/examples/tokens/ERC20.vy#L85
            three_pool_erc20.approve(mim3crv_metapool_address, 0);
            three_pool_erc20.approve(mim3crv_metapool_address, threeCRV_received);
        }
        
        // Approve the MIM for the metapool
        MIM.approve(mim3crv_metapool_address, _MIM_Convex_AMOunt);

        {
            // Add the FRAX and the collateral to the metapool
            uint256 min_lp_out = (_MIM_Convex_AMOunt.add(threeCRV_received)).mul(slippage_metapool).div(PRICE_PRECISION);
            metapool_LP_received = mim3crv_metapool.add_liquidity([_MIM_Convex_AMOunt, threeCRV_received], min_lp_out);
        }

        return metapool_LP_received;
    }

    function metapoolWithdrawMIM(uint256 _metapool_lp_in) external onlyByOwnGov returns (uint256 mim_received) {
        // Withdraw MIM from the metapool
        uint256 min_mim_out = _metapool_lp_in.mul(slippage_metapool).div(PRICE_PRECISION);
        mim_received = mim3crv_metapool.remove_liquidity_one_coin(_metapool_lp_in, 0, min_mim_out);
    }

    function metapoolWithdraw3pool(uint256 _metapool_lp_in) internal onlyByOwnGov {
        // Withdraw 3pool from the metapool
        uint256 min_3pool_out = _metapool_lp_in.mul(slippage_metapool).div(PRICE_PRECISION);
        mim3crv_metapool.remove_liquidity_one_coin(_metapool_lp_in, 1, min_3pool_out);
    }

    function three_pool_to_collateral(uint256 _3pool_in) internal onlyByOwnGov {
        // Convert the 3pool into the collateral
        // WEIRD ISSUE: NEED TO DO three_pool_erc20.approve(address(three_pool), 0); first before every time
        // May be related to https://github.com/vyperlang/vyper/blob/3e1ff1eb327e9017c5758e24db4bdf66bbfae371/examples/tokens/ERC20.vy#L85
        three_pool_erc20.approve(address(three_pool), 0);
        three_pool_erc20.approve(address(three_pool), _3pool_in);
        uint256 min_collat_out = _3pool_in.mul(liq_slippage_3crv).div(PRICE_PRECISION * (10 ** missing_decimals));
        three_pool.remove_liquidity_one_coin(_3pool_in, 1, min_collat_out);
    }

    function metapoolWithdrawAndConvert3pool(uint256 _metapool_lp_in) external onlyByOwnGov {
        metapoolWithdraw3pool(_metapool_lp_in);
        three_pool_to_collateral(three_pool_erc20.balanceOf(address(this)));
    }

    /* ========== Burns and givebacks ========== */

    // Give USDC profits back. Goes through the minter
    function giveCollatBack(uint256 collat_amount) external onlyByOwnGovCust {
        collateral_token.approve(address(amo_minter), collat_amount);
        amo_minter.receiveCollatFromAMO(collat_amount);
    }

    /* ========== Convex: Deposit / Claim / Withdraw MIM3CRV Metapool LP ========== */

    // Deposit Metapool LP tokens, convert them to Convex LP, and deposit into their vault
    function depositMIM3CRV(uint256 _metapool_lp_in) external onlyByOwnGovCust{
        // Approve the metapool LP tokens for the vault contract
        mim3crv_metapool.approve(address(convex_booster), _metapool_lp_in);
        
        // Deposit the metapool LP into the vault contract
        convex_booster.deposit(lp_deposit_pid, _metapool_lp_in, true);
    }

    // Withdraw Convex LP, convert it back to Metapool LP tokens, and give them back to the sender
    function withdrawAndUnwrapMIM3CRV(uint256 amount, bool claim) external onlyByOwnGovCust{
        convex_base_reward_pool.withdrawAndUnwrap(amount, claim);
    }

    // Claim CVX, CRV, and SPELL rewards
    function claimRewardsMIM3CRV() external onlyByOwnGovCust {
        address[] memory rewardContracts = new address[](1);
        rewardContracts[0] = address(convex_base_reward_pool);

        uint256[] memory chefIds = new uint256[](0);

        convex_claim_zap.claimRewards(
            rewardContracts, 
            chefIds, 
            false, 
            false, 
            false, 
            0, 
            0
        );
    }

    /* ========== Convex: Stake / Claim / Withdraw CVX ========== */

    // Stake CVX tokens
    // E18
    function stakeCVX(uint256 _cvx_in) external onlyByOwnGovCust {
        // Approve the CVX tokens for the staking contract
        cvx.approve(address(cvx_reward_pool), _cvx_in);
        
        // Stake the CVX tokens into the staking contract
        cvx_reward_pool.stakeFor(address(this), _cvx_in);
    }

    // Claim cvxCRV rewards
    function claimRewards_cvxCRV(bool stake) external onlyByOwnGovCust {
        cvx_reward_pool.getReward(address(this), true, stake);
    }

    // Unstake CVX tokens
    // E18
    function withdrawCVX(uint256 cvx_amt, bool claim) external onlyByOwnGovCust {
        cvx_reward_pool.withdraw(cvx_amt, claim);
    }

    function withdrawRewards(
        uint256 crv_amt,
        uint256 cvx_amt,
        uint256 cvxCRV_amt,
        uint256 spell_amt
    ) external onlyByOwnGovCust {
        if (crv_amt > 0) TransferHelper.safeTransfer(crv_address, msg.sender, crv_amt);
        if (cvx_amt > 0) TransferHelper.safeTransfer(address(cvx), msg.sender, cvx_amt);
        if (cvxCRV_amt > 0) TransferHelper.safeTransfer(cvx_crv_address, msg.sender, cvxCRV_amt);
        if (spell_amt > 0) TransferHelper.safeTransfer(spell_address, msg.sender, spell_amt);
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    function setAMOMinter(address _amo_minter_address) external onlyByOwnGov {
        amo_minter = IFraxAMOMinter(_amo_minter_address);

        // Get the custodian and timelock addresses from the minter
        custodian_address = amo_minter.custodian_address();
        timelock_address = amo_minter.timelock_address();

        // Make sure the new addresses are not address(0)
        require(custodian_address != address(0) && timelock_address != address(0), "Invalid custodian or timelock");
    }

    // in terms of 1e6 (overriding global_collateral_ratio)
    function setDiscountRate(bool _state, uint256 _discount_rate) external onlyByOwnGov {
        set_discount = _state;
        discount_rate = _discount_rate;
    }

    function setSlippages(uint256 _liq_slippage_3crv, uint256 _slippage_metapool) external onlyByOwnGov {
        liq_slippage_3crv = _liq_slippage_3crv;
        slippage_metapool = _slippage_metapool;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Can only be triggered by owner or governance, not custodian
        // Tokens are sent to the custodian, as a sort of safeguard
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }
}