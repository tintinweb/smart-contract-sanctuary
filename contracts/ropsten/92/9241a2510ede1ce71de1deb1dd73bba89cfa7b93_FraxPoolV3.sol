/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.6.2 https://hardhat.org

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


// File contracts/FXS/IFxs.sol


interface IFxs {
    function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
    function FRAXStablecoinAdd() external view returns(address);
    function FXS_DAO_min() external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns(uint256);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function checkpoints(address, uint32) external view returns(uint32 fromBlock, uint96 votes);
    function decimals() external view returns(uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
    function genesis_supply() external view returns(uint256);
    function getCurrentVotes(address account) external view returns(uint96);
    function getPriorVotes(address account, uint256 blockNumber) external view returns(uint96);
    function getRoleAdmin(bytes32 role) external view returns(bytes32);
    function getRoleMember(bytes32 role, uint256 index) external view returns(address);
    function getRoleMemberCount(bytes32 role) external view returns(uint256);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns(bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns(bool);
    function mint(address to, uint256 amount) external;
    function name() external view returns(string memory);
    function numCheckpoints(address) external view returns(uint32);
    function oracle_address() external view returns(address);
    function owner_address() external view returns(address);
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function renounceRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function setFRAXAddress(address frax_contract_address) external;
    function setFXSMinDAO(uint256 min_FXS) external;
    function setOracle(address new_oracle) external;
    function setOwner(address _owner_address) external;
    function setTimelock(address new_timelock) external;
    function symbol() external view returns(string memory);
    function timelock_address() external view returns(address);
    function toggleVotes() external;
    function totalSupply() external view returns(uint256);
    function trackingVotes() external view returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}


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


// File contracts/Oracle/AggregatorV3Interface.sol


interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

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


// File contracts/Frax/IFraxAMOMinter.sol


interface IFraxAMOMinter {
    function FRAX() external view returns(address);
    function FXS() external view returns(address);
    function acceptOwnership() external;
    function addAMO(address amo_address, bool sync_too) external;
    function allAMOAddresses() external view returns(address[] memory);
    function allAMOsLength() external view returns(uint256);
    function amoProfit(address amo_address) external view returns(int256);
    function amos(address) external view returns(bool);
    function amos_array(uint256) external view returns(address);
    function burnFXS(uint256 amount) external;
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
    function custodian_address() external view returns(address);
    function fraxDollarBalanceStored() external view returns(uint256);
    function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
    function min_cr() external view returns(uint256);
    function mintFraxForAMO(address destination_amo, uint256 frax_amount) external;
    function mint_balances(address) external view returns(int256);
    function mint_cap() external view returns(int256);
    function mint_sum() external view returns(int256);
    function missing_decimals() external view returns(uint256);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns(address);
    function override_collat_balance() external view returns(bool);
    function override_collat_balance_amount() external view returns(uint256);
    function owner() external view returns(address);
    function pool() external view returns(address);
    function receiveCollatFromAMO(uint256 usdc_amount) external;
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function removeAMO(address amo_address, bool sync_too) external;
    function setCustodian(address _custodian_address) external;
    function setFraxPool(address _pool_address) external;
    function setMinimumCollateralRatio(uint256 _min_cr) external;
    function setMintCap(uint256 _mint_cap) external;
    function setOverrideCollatBalance(bool _state, uint256 _balance) external;
    function setTimelock(address new_timelock) external;
    function syncDollarBalances() external;
    function timelock_address() external view returns(address);
    function unspentProfitGlobal() external view returns(int256);
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


// File contracts/Frax/Pools/FraxPoolV3.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ FraxPoolV3 ============================
// ====================================================================
// Allows multiple stablecoins (fixed amount at initialization) as collateral
// LUSD, sUSD, USDP, Wrapped UST, and FEI initially
// For this pool, the goal is to accept crypto-backed / overcollateralized stablecoins to limit
// government / regulatory risk (e.g. USDC blacklisting until holders KYC)

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett
// Hameed








contract FraxPoolV3 is Owned {
    using SafeMath for uint256;
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    address public timelock_address;
    address public custodian_address; // Custodian is an EOA (or msig) with pausing privileges only, in case of an emergency
    IFrax private FRAX = IFrax(0xe548b5B9dbf950b621d75C47875d0005260a0eD2);
    IFxs private FXS = IFxs(0x9aE3eb5e0b1a8cfD32E0F8b4eB09B03281d4ABB1);
    mapping(address => bool) public amo_minter_addresses; // minter address -> is it enabled
    AggregatorV3Interface public priceFeedFRAXUSD = AggregatorV3Interface(0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD);
    AggregatorV3Interface public priceFeedFXSUSD = AggregatorV3Interface(0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f);
    uint256 private chainlink_frax_usd_decimals;
    uint256 private chainlink_fxs_usd_decimals;
    
    uint256 private frax_usd_price=1012817;
    uint256 private fxs_usd_price=4556665;

    // Collateral
    address[] public collateral_addresses;
    string[] public collateral_symbols;
    uint256[] public missing_decimals; // Number of decimals needed to get to E18. collateral index -> missing_decimals
    uint256[] public pool_ceilings; // Total across all collaterals. Accounts for missing_decimals
    uint256[] public collateral_prices; // Stores price of the collateral, if price is paused
    mapping(address => uint256) public collateralAddrToIdx; // collateral addr -> collateral index
    mapping(address => bool) public enabled_collaterals; // collateral address -> is it enabled

    // Redeem related
    mapping (address => uint256) public redeemFXSBalances;
    mapping (address => mapping(uint256 => uint256)) public redeemCollateralBalances; // Address -> collateral index -> balance
    uint256[] public unclaimedPoolCollateral; // collateral index -> balance
    uint256 public unclaimedPoolFXS;
    mapping (address => uint256) public lastRedeemed; // Collateral independent
    uint256 public redemption_delay = 2; // Number of blocks to wait before being able to collectRedemption()
    uint256 public redeem_price_threshold = 990000; // $0.99
    uint256 public mint_price_threshold = 1010000; // $1.01

    // Buyback related
    mapping(uint256 => uint256) public bbkHourlyCum; // Epoch hour ->  Collat out in that hour (E18)
    uint256 public bbkMaxColE18OutPerHour = 1000e18;

    // Recollat related
    mapping(uint256 => uint256) public rctHourlyCum; // Epoch hour ->  FXS out in that hour
    uint256 public rctMaxFxsOutPerHour = 1000e18;

    // Fees and rates
    // getters are in collateral_information()
    uint256[] private minting_fee;
    uint256[] private redemption_fee;
    uint256[] private buyback_fee;
    uint256[] private recollat_fee;
    uint256 public bonus_rate; // Bonus rate on FXS minted during recollateralize(); 6 decimals of precision, set to 0.75% on genesis

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 private collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102

    // Pause variables
    // getters are in collateral_information()
    bool[] private mintPaused; // Collateral-specific
    bool[] private redeemPaused; // Collateral-specific
    bool[] private recollateralizePaused; // Collateral-specific
    bool[] private buyBackPaused; // Collateral-specific

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyAMOMinters() {
        require(amo_minter_addresses[msg.sender], "Not an AMO Minter");
        _;
    }

    modifier collateralEnabled(uint256 col_idx) {
        require(enabled_collaterals[collateral_addresses[col_idx]], "Collateral disabled");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _pool_manager_address,
        address _custodian_address,
        address _timelock_address,
        address[] memory _collateral_addresses,
        uint256[] memory _pool_ceilings,
        uint256[] memory _initial_fees
    ) Owned(_pool_manager_address){
        // Core
        timelock_address = _timelock_address;
        custodian_address = _custodian_address;

        // Fill collateral info
        collateral_addresses = _collateral_addresses;
        for (uint256 i = 0; i < _collateral_addresses.length; i++){
            // For fast collateral address -> collateral idx lookups later
            collateralAddrToIdx[_collateral_addresses[i]] = i;

            // Set all of the collaterals initially to disabled
            enabled_collaterals[_collateral_addresses[i]] = false;

            // Add in the missing decimals
            missing_decimals.push(uint256(18).sub(ERC20(_collateral_addresses[i]).decimals()));

            // Add in the collateral symbols
            collateral_symbols.push(ERC20(_collateral_addresses[i]).symbol());

            // Initialize unclaimed pool collateral
            unclaimedPoolCollateral.push(0);

            // Initialize paused prices to $1 as a backup
            collateral_prices.push(PRICE_PRECISION);

            // Handle the fees
            minting_fee.push(_initial_fees[0]);
            redemption_fee.push(_initial_fees[1]);
            buyback_fee.push(_initial_fees[2]);
            recollat_fee.push(_initial_fees[3]);

            // Handle the pauses
            mintPaused.push(false);
            redeemPaused.push(false);
            recollateralizePaused.push(false);
            buyBackPaused.push(false);
        }

        // Pool ceiling
        pool_ceilings = _pool_ceilings;

        // Set the decimals
        // chainlink_frax_usd_decimals = priceFeedFRAXUSD.decimals();
        // chainlink_fxs_usd_decimals = priceFeedFXSUSD.decimals();
        chainlink_frax_usd_decimals = 8;
        chainlink_fxs_usd_decimals = 8;
    }

    /* ========== STRUCTS ========== */

    struct CollateralInformation {
        uint256 index;
        string symbol;
        address col_addr;
        bool is_enabled;
        uint256 missing_decs;
        uint256 price;
        uint256 pool_ceiling;
        bool mint_paused;
        bool redeem_paused;
        bool recollat_paused;
        bool buyback_paused;
        uint256 minting_fee;
        uint256 redemption_fee;
        uint256 buyback_fee;
        uint256 recollat_fee;
    }

    /* ========== VIEWS ========== */

    // Helpful for UIs
    function collateral_information(address collat_address) external view returns (CollateralInformation memory return_data){
        require(enabled_collaterals[collat_address], "Invalid collateral");

        // Get the index
        uint256 idx = collateralAddrToIdx[collat_address];

        return_data = CollateralInformation(
            idx, // [0]
            collateral_symbols[idx], // [1]
            collat_address, // [2]
            enabled_collaterals[collat_address], // [3]
            missing_decimals[idx], // [4]
            collateral_prices[idx], // [5]
            pool_ceilings[idx], // [6]
            mintPaused[idx], // [7]
            redeemPaused[idx], // [8]
            recollateralizePaused[idx], // [9]
            buyBackPaused[idx], // [10]
            minting_fee[idx], // [11]
            redemption_fee[idx], // [12]
            buyback_fee[idx], // [13]
            recollat_fee[idx] // [14]
        );
    }

    function allCollaterals() external view returns (address[] memory) {
        return collateral_addresses;
    }

    function getFRAXPrice() public view returns (uint256) {
        // ( , int price, , , ) = priceFeedFRAXUSD.latestRoundData();
        // return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlink_frax_usd_decimals);
        return frax_usd_price;
    }
    
    function getCollateralRatio() internal view returns (uint256) {
        return collateral_ratio;
    }

    function getFXSPrice() public view returns (uint256) {
        // ( , int price, , , ) = priceFeedFXSUSD.latestRoundData();
        // return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlink_fxs_usd_decimals);
        return fxs_usd_price;
    }

    // Returns the FRAX value in collateral tokens
    function getFRAXInCollateral(uint256 col_idx, uint256 frax_amount) public view returns (uint256) {
        return frax_amount.mul(PRICE_PRECISION).div(10 ** missing_decimals[col_idx]).div(collateral_prices[col_idx]);
    }

    // Used by some functions.
    function freeCollatBalance(uint256 col_idx) public view returns (uint256) {
        return ERC20(collateral_addresses[col_idx]).balanceOf(address(this)).sub(unclaimedPoolCollateral[col_idx]);
    }

    // Returns dollar value of collateral held in this Frax pool, in E18
    function collatDollarBalance() external view returns (uint256 balance_tally) {
        balance_tally = 0;

        // Test 1
        for (uint256 i = 0; i < collateral_addresses.length; i++){
            balance_tally += freeCollatBalance(i).mul(10 ** missing_decimals[i]).mul(collateral_prices[i]).div(PRICE_PRECISION);
        }

    }

    function comboCalcBbkRct(uint256 cur, uint256 max, uint256 theo) internal pure returns (uint256) {
        if (cur >= max) {
            // If the hourly limit has already been reached, return 0;
            return 0;
        }
        else {
            // Get the available amount
            uint256 available = max.sub(cur);

            if (theo >= available) {
                // If the the theoretical is more than the available, return the available
                return available;
            }
            else {
                // Otherwise, return the theoretical amount
                return theo;
            }
        }
    }

    // Returns the value of excess collateral (in E18) held globally, compared to what is needed to maintain the global collateral ratio
    // Also has throttling to avoid dumps during large price movements
    function buybackAvailableCollat() public view returns (uint256) {
        uint256 total_supply = FRAX.totalSupply();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 global_collat_value = FRAX.globalCollateralValue();

        if (global_collateral_ratio > PRICE_PRECISION) global_collateral_ratio = PRICE_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(PRICE_PRECISION); // Calculates collateral needed to back each 1 FRAX with $1 of collateral at current collat ratio

        if (global_collat_value > required_collat_dollar_value_d18) {
            // Get the theoretical buyback amount
            uint256 theoretical_bbk_amt = global_collat_value.sub(required_collat_dollar_value_d18);

            // See how much has collateral has been issued this hour
            uint256 current_hr_bbk = bbkHourlyCum[curEpochHr()];

            // Account for the throttling
            return comboCalcBbkRct(current_hr_bbk, bbkMaxColE18OutPerHour, theoretical_bbk_amt);
        }
        else return 0;
    }

    // Returns the missing amount of collateral (in E18) needed to maintain the collateral ratio
    function recollatTheoColAvailableE18() public view returns (uint256) {
        uint256 frax_total_supply = FRAX.totalSupply();
        uint256 effective_collateral_ratio = FRAX.globalCollateralValue().mul(PRICE_PRECISION).div(frax_total_supply); // Returns it in 1e6

        uint256 desired_collat_e24 = (FRAX.global_collateral_ratio()).mul(frax_total_supply);
        uint256 effective_collat_e24 = effective_collateral_ratio.mul(frax_total_supply);

        // Return 0 if already overcollateralized
        // Otherwise, return the deficiency
        if (effective_collat_e24 >= desired_collat_e24) return 0;
        else {
            return (desired_collat_e24.sub(effective_collat_e24)).div(PRICE_PRECISION);
        }
    }

    // Returns the value of FXS available to be used for recollats
    // Also has throttling to avoid dumps during large price movements
    function recollatAvailableFxs() public view returns (uint256) {
        uint256 fxs_price = getFXSPrice();

        // Get the amount of collateral theoretically available
        uint256 recollat_theo_available_e18 = recollatTheoColAvailableE18();

        // Get the amount of FXS theoretically outputtable
        uint256 fxs_theo_out = recollat_theo_available_e18.mul(PRICE_PRECISION).div(fxs_price);

        // See how much FXS has been issued this hour
        uint256 current_hr_rct = rctHourlyCum[curEpochHr()];

        // Account for the throttling
        return comboCalcBbkRct(current_hr_rct, rctMaxFxsOutPerHour, fxs_theo_out);
    }

    // Returns the current epoch hour
    function curEpochHr() public view returns (uint256) {
        return (block.timestamp / 3600); // Truncation desired
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function mintFrax(
        uint256 col_idx,
        uint256 frax_amt,
        uint256 frax_out_min,
        bool one_to_one_override
    ) external collateralEnabled(col_idx) returns (
        uint256 total_frax_mint,
        uint256 collat_needed,
        uint256 fxs_needed
    ) {
        require(mintPaused[col_idx] == false, "Minting is paused");

        // Prevent unneccessary mints
        require(getFRAXPrice() >= mint_price_threshold, "Frax price too low");

        uint256 global_collateral_ratio = getCollateralRatio();

        if (one_to_one_override || global_collateral_ratio >= PRICE_PRECISION) {
            // 1-to-1, overcollateralized, or user selects override
            collat_needed = getFRAXInCollateral(col_idx, frax_amt);
            fxs_needed = 0;
        } else if (global_collateral_ratio == 0) {
            // Algorithmic
            collat_needed = 0;
            fxs_needed = frax_amt.mul(PRICE_PRECISION).div(getFXSPrice());
        } else {
            // Fractional
            uint256 frax_for_collat = frax_amt.mul(global_collateral_ratio).div(PRICE_PRECISION);
            uint256 frax_for_fxs = frax_amt.sub(frax_for_collat);
            collat_needed = getFRAXInCollateral(col_idx, frax_for_collat);
            fxs_needed = frax_for_fxs.mul(PRICE_PRECISION).div(getFXSPrice());
        }

        // Subtract the minting fee
        total_frax_mint = (frax_amt.mul(PRICE_PRECISION.sub(minting_fee[col_idx]))).div(PRICE_PRECISION);

        // Checks
        require((frax_out_min <= total_frax_mint), "FRAX slippage");
        require(freeCollatBalance(col_idx).add(collat_needed) <= pool_ceilings[col_idx], "Pool ceiling");

        // Take the FXS and collateral first
        FXS.pool_burn_from(msg.sender, fxs_needed);
        TransferHelper.safeTransferFrom(collateral_addresses[col_idx], msg.sender, address(this), collat_needed);

        // Mint the FRAX
        FRAX.pool_mint(msg.sender, total_frax_mint);
    }

    function redeemFrax(
        uint256 col_idx,
        uint256 frax_amount,
        uint256 fxs_out_min,
        uint256 col_out_min
    ) external collateralEnabled(col_idx) returns (
        uint256 collat_out,
        uint256 fxs_out
    ) {
        require(redeemPaused[col_idx] == false, "Redeeming is paused");

        // Prevent unneccessary redemptions that could adversely affect the FXS price
        require(getFRAXPrice() <= redeem_price_threshold, "Frax price too high");

        uint256 global_collateral_ratio = getCollateralRatio();
        uint256 frax_after_fee = (frax_amount.mul(PRICE_PRECISION.sub(redemption_fee[col_idx]))).div(PRICE_PRECISION);

        // Assumes $1 FRAX in all cases
        if(global_collateral_ratio >= PRICE_PRECISION) {
            // 1-to-1 or overcollateralized
            collat_out = frax_after_fee
            .mul(collateral_prices[col_idx])
            .div(10 ** (6 + missing_decimals[col_idx])); // PRICE_PRECISION + missing decimals
            fxs_out = 0;
        } else if (global_collateral_ratio == 0) {
            // Algorithmic
            fxs_out = frax_after_fee
            .mul(PRICE_PRECISION)
            .div(getFXSPrice());
            collat_out = 0;
        } else {
            // Fractional
            collat_out = frax_after_fee
            .mul(global_collateral_ratio)
            .mul(collateral_prices[col_idx])
            .div(10 ** (12 + missing_decimals[col_idx])); // PRICE_PRECISION ^2 + missing decimals
            fxs_out = frax_after_fee
            .mul(PRICE_PRECISION.sub(global_collateral_ratio))
            .div(getFXSPrice()); // PRICE_PRECISIONS CANCEL OUT
        }

        // Checks
        require(collat_out <= (ERC20(collateral_addresses[col_idx])).balanceOf(address(this)).sub(unclaimedPoolCollateral[col_idx]), "Insufficient pool collateral");
        require(collat_out >= col_out_min, "Collateral slippage");
        require(fxs_out >= fxs_out_min, "FXS slippage");

        // Account for the redeem delay
        redeemCollateralBalances[msg.sender][col_idx] = redeemCollateralBalances[msg.sender][col_idx].add(collat_out);
        unclaimedPoolCollateral[col_idx] = unclaimedPoolCollateral[col_idx].add(collat_out);

        redeemFXSBalances[msg.sender] = redeemFXSBalances[msg.sender].add(fxs_out);
        unclaimedPoolFXS = unclaimedPoolFXS.add(fxs_out);

        lastRedeemed[msg.sender] = block.number;

        FRAX.pool_burn_from(msg.sender, frax_amount);
        FXS.pool_mint(address(this), fxs_out);
    }

    // After a redemption happens, transfer the newly minted FXS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out FRAX/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption(uint256 col_idx) external returns (uint256 fxs_amount, uint256 collateral_amount) {
        require(redeemPaused[col_idx] == false, "Redeeming is paused");
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Too soon");
        bool sendFXS = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if(redeemFXSBalances[msg.sender] > 0){
            fxs_amount = redeemFXSBalances[msg.sender];
            redeemFXSBalances[msg.sender] = 0;
            unclaimedPoolFXS = unclaimedPoolFXS.sub(fxs_amount);
            sendFXS = true;
        }

        if(redeemCollateralBalances[msg.sender][col_idx] > 0){
            collateral_amount = redeemCollateralBalances[msg.sender][col_idx];
            redeemCollateralBalances[msg.sender][col_idx] = 0;
            unclaimedPoolCollateral[col_idx] = unclaimedPoolCollateral[col_idx].sub(collateral_amount);
            sendCollateral = true;
        }

        // Send out the tokens
        if(sendFXS){
            TransferHelper.safeTransfer(address(FXS), msg.sender, fxs_amount);
        }
        if(sendCollateral){
            TransferHelper.safeTransfer(collateral_addresses[col_idx], msg.sender, collateral_amount);
        }
    }

    // Function can be called by an FXS holder to have the protocol buy back FXS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackFxs(uint256 col_idx, uint256 fxs_amount, uint256 col_out_min) external collateralEnabled(col_idx) returns (uint256 col_out) {
        require(buyBackPaused[col_idx] == false, "Buyback is paused");
        uint256 fxs_price = getFXSPrice();
        uint256 available_excess_collat_dv = buybackAvailableCollat();

        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible FXS with the desired collateral
        require(available_excess_collat_dv > 0, "Insuf Collat Avail For BBK");

        // Make sure not to take more than is available
        uint256 fxs_dollar_value_d18 = fxs_amount.mul(fxs_price).div(PRICE_PRECISION);
        require(fxs_dollar_value_d18 <= available_excess_collat_dv, "Insuf Collat Avail For BBK");

        // Get the equivalent amount of collateral based on the market value of FXS provided
        uint256 collateral_equivalent_d18 = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(collateral_prices[col_idx]);
        col_out = collateral_equivalent_d18.div(10 ** missing_decimals[col_idx]); // In its natural decimals()

        // Subtract the buyback fee
        col_out = (col_out.mul(PRICE_PRECISION.sub(buyback_fee[col_idx]))).div(PRICE_PRECISION);

        // Check for slippage
        require(col_out >= col_out_min, "Collateral slippage");

        // Take in and burn the FXS, then send out the collateral
        FXS.pool_burn_from(msg.sender, fxs_amount);
        TransferHelper.safeTransfer(collateral_addresses[col_idx], msg.sender, col_out);

        // Increment the outbound collateral, in E18, for that hour
        // Used for buyback throttling
        bbkHourlyCum[curEpochHr()] += collateral_equivalent_d18;
    }

    // When the protocol is recollateralizing, we need to give a discount of FXS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get FXS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of FXS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra FXS value from the bonus rate as an arb opportunity
    function recollateralize(uint256 col_idx, uint256 collateral_amount, uint256 fxs_out_min) external collateralEnabled(col_idx) returns (uint256 fxs_out) {
        require(recollateralizePaused[col_idx] == false, "Recollat is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals[col_idx]);
        uint256 fxs_price = getFXSPrice();

        // Get the amount of FXS actually available (accounts for throttling)
        uint256 fxs_actually_available = recollatAvailableFxs();

        // Calculated the attempted amount of FXS
        fxs_out = collateral_amount_d18.mul(PRICE_PRECISION.add(bonus_rate).sub(recollat_fee[col_idx])).div(fxs_price);

        // Make sure there is FXS available
        require(fxs_out <= fxs_actually_available, "Insuf FXS Avail For RCT");

        // Check slippage
        require(fxs_out >= fxs_out_min, "FXS slippage");

        // Don't take in more collateral than the pool ceiling for this token allows
        require(freeCollatBalance(col_idx).add(collateral_amount) <= pool_ceilings[col_idx], "Pool ceiling");

        // Take in the collateral and pay out the FXS
        TransferHelper.safeTransferFrom(collateral_addresses[col_idx], msg.sender, address(this), collateral_amount);
        FXS.pool_mint(msg.sender, fxs_out);

        // Increment the outbound FXS, in E18
        // Used for recollat throttling
        rctHourlyCum[curEpochHr()] += fxs_out;
    }

    // Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral
    function amoMinterBorrow(uint256 collateral_amount) external onlyAMOMinters {
        // Checks the col_idx of the minter as an additional safety check
        uint256 minter_col_idx = IFraxAMOMinter(msg.sender).col_idx();

        // Transfer
        TransferHelper.safeTransfer(collateral_addresses[minter_col_idx], msg.sender, collateral_amount);
    }

    /* ========== RESTRICTED FUNCTIONS, CUSTODIAN CAN CALL TOO ========== */

    function toggleMRBR(uint256 col_idx, uint8 tog_idx) external onlyByOwnGovCust {
        if (tog_idx == 0) mintPaused[col_idx] = !mintPaused[col_idx];
        else if (tog_idx == 1) redeemPaused[col_idx] = !redeemPaused[col_idx];
        else if (tog_idx == 2) buyBackPaused[col_idx] = !buyBackPaused[col_idx];
        else if (tog_idx == 3) recollateralizePaused[col_idx] = !recollateralizePaused[col_idx];

        emit MRBRToggled(col_idx, tog_idx);
    }

    /* ========== RESTRICTED FUNCTIONS, GOVERNANCE ONLY ========== */

    // Add an AMO Minter
    function addAMOMinter(address amo_minter_addr) external onlyByOwnGov {
        require(amo_minter_addr != address(0), "Zero address detected");

        // Make sure the AMO Minter has collatDollarBalance()
        uint256 collat_val_e18 = IFraxAMOMinter(amo_minter_addr).collatDollarBalance();
        require(collat_val_e18 >= 0, "Invalid AMO");

        amo_minter_addresses[amo_minter_addr] = true;

        emit AMOMinterAdded(amo_minter_addr);
    }

    // Remove an AMO Minter
    function removeAMOMinter(address amo_minter_addr) external onlyByOwnGov {
        amo_minter_addresses[amo_minter_addr] = false;

        emit AMOMinterRemoved(amo_minter_addr);
    }

    function setCollateralPrice(uint256 col_idx, uint256 _new_price) external onlyByOwnGov {
        collateral_prices[col_idx] = _new_price;

        emit CollateralPriceSet(col_idx, _new_price);
    }

    // Could also be called toggleCollateral
    function toggleCollateral(uint256 col_idx) external onlyByOwnGov {
        address col_address = collateral_addresses[col_idx];
        enabled_collaterals[col_address] = !enabled_collaterals[col_address];

        emit CollateralToggled(col_idx, enabled_collaterals[col_address]);
    }

    function setPoolCeiling(uint256 col_idx, uint256 new_ceiling) external onlyByOwnGov {
        pool_ceilings[col_idx] = new_ceiling;

        emit PoolCeilingSet(col_idx, new_ceiling);
    }

    function setFees(uint256 col_idx, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnGov {
        minting_fee[col_idx] = new_mint_fee;
        redemption_fee[col_idx] = new_redeem_fee;
        buyback_fee[col_idx] = new_buyback_fee;
        recollat_fee[col_idx] = new_recollat_fee;

        emit FeesSet(col_idx, new_mint_fee, new_redeem_fee, new_buyback_fee, new_recollat_fee);
    }
    
    function setFraxUSDPrice(uint256 new_price) external onlyByOwnGov {
        frax_usd_price = new_price;
    }
    
    function setFxsUSDPrice(uint256 new_price) external onlyByOwnGov {
        fxs_usd_price = new_price;
    }
    
    function setFRAXAddress(address frax_contract_address) external onlyByOwnGov {
        FRAX = IFrax(frax_contract_address);
    }

    function setFXSAddress(address fxs_contract_address) external onlyByOwnGov {
        FXS = IFxs(fxs_contract_address);
    }
    
    function setCollateralRatio(uint256 new_ratio) external onlyByOwnGov {
        collateral_ratio = new_ratio;
    }
    
    function setPoolParameters(uint256 new_bonus_rate, uint256 new_redemption_delay) external onlyByOwnGov {
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        emit PoolParametersSet(new_bonus_rate, new_redemption_delay);
    }

    function setPriceThresholds(uint256 new_mint_price_threshold, uint256 new_redeem_price_threshold) external onlyByOwnGov {
        mint_price_threshold = new_mint_price_threshold;
        redeem_price_threshold = new_redeem_price_threshold;
        emit PriceThresholdsSet(new_mint_price_threshold, new_redeem_price_threshold);
    }

    function setBbkRctPerHour(uint256 _bbkMaxColE18OutPerHour, uint256 _rctMaxFxsOutPerHour) external onlyByOwnGov {
        bbkMaxColE18OutPerHour = _bbkMaxColE18OutPerHour;
        rctMaxFxsOutPerHour = _rctMaxFxsOutPerHour;
        emit BbkRctPerHourSet(_bbkMaxColE18OutPerHour, _rctMaxFxsOutPerHour);
    }

    // Set the Chainlink oracles
    function setOracles(address _frax_usd_chainlink_addr, address _fxs_usd_chainlink_addr) external onlyByOwnGov {
        // Set the instances
        priceFeedFRAXUSD = AggregatorV3Interface(_frax_usd_chainlink_addr);
        priceFeedFXSUSD = AggregatorV3Interface(_fxs_usd_chainlink_addr);

        // Set the decimals
        chainlink_frax_usd_decimals = priceFeedFRAXUSD.decimals();
        chainlink_fxs_usd_decimals = priceFeedFXSUSD.decimals();

        emit OraclesSet(_frax_usd_chainlink_addr, _fxs_usd_chainlink_addr);
    }

    function setCustodian(address new_custodian) external onlyByOwnGov {
        custodian_address = new_custodian;

        emit CustodianSet(new_custodian);
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

    /* ========== EVENTS ========== */
    event CollateralToggled(uint256 col_idx, bool new_state);
    event PoolCeilingSet(uint256 col_idx, uint256 new_ceiling);
    event FeesSet(uint256 col_idx, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee);
    event PoolParametersSet(uint256 new_bonus_rate, uint256 new_redemption_delay);
    event PriceThresholdsSet(uint256 new_bonus_rate, uint256 new_redemption_delay);
    event BbkRctPerHourSet(uint256 bbkMaxColE18OutPerHour, uint256 rctMaxFxsOutPerHour);
    event AMOMinterAdded(address amo_minter_addr);
    event AMOMinterRemoved(address amo_minter_addr);
    event OraclesSet(address frax_usd_chainlink_addr, address fxs_usd_chainlink_addr);
    event CustodianSet(address new_custodian);
    event TimelockSet(address new_timelock);
    event MRBRToggled(uint256 col_idx, uint8 tog_idx);
    event CollateralPriceSet(uint256 col_idx, uint256 new_price);
}