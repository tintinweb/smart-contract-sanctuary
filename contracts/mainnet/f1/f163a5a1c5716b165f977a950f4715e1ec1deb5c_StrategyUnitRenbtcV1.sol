/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity 0.6.12;


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

// File: contracts/GSN/Context.sol
// SPDX-License-Identifier: MIT
// File: contracts/token/ERC20/IERC20.sol
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

// File: contracts/utils/Address.sol
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: contracts/token/ERC20/ERC20.sol
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface UniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

}

interface IController {
    function vaults(address) external view returns (address);

    function devfund() external view returns (address);

    function treasury() external view returns (address);

}

interface IUnitVaultParameters{
	function tokenDebtLimit(address asset) external view returns (uint);
}

interface IUnitVault{
	function calculateFee(address asset, address user, uint amount) external view returns (uint);
	function getTotalDebt(address asset, address user) external view returns (uint);
	function debts(address asset, address user) external view returns (uint);
	function collaterals(address asset, address user) external view returns (uint);
	function tokenDebts(address asset) external view returns (uint);
}

interface IUnitCDPManager {
	function exit(address asset, uint assetAmount, uint usdpAmount) external returns (uint);
	function join(address asset, uint assetAmount, uint usdpAmount) external;
}

interface IMasterchef {
    function notifyBuybackReward(uint256 _amount) external;
}

interface ICurveFi_2 {
    function get_virtual_price() external view returns (uint256);
	
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
	
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
 
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;
}

interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address addr) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);
}

interface ICurveMintr {
    function mint(address) external;

    function minted(address arg0, address arg1) external view returns (uint256);
}

interface IUniswapV2SlidingOracle {
    function current(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view returns (uint256);
    function work() external;
    function updatePair(address pair) external;
    function observationLength(address pair) external view returns (uint);
    function lastObservation(address pair) external view returns (uint timestamp, uint price0Cumulative, uint price1Cumulative);
    function observations(address pair, uint256 idx) external view returns (uint timestamp, uint price0Cumulative, uint price1Cumulative);
}

// Strategy Contract Basics
abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Perfomance fee 30% to buyback
    uint256 public performanceFee = 30000;
    uint256 public constant performanceMax = 100000;

    // Withdrawal fee 0.2% to buyback
    // - 0.14% to treasury
    // - 0.06% to dev fund
    uint256 public treasuryFee = 140;
    uint256 public constant treasuryMax = 100000;

    uint256 public devFundFee = 60;
    uint256 public constant devFundMax = 100000;

    // delay yield profit realization
    uint256 public delayBlockRequired = 1000;
    uint256 public lastHarvestBlock;
    uint256 public lastHarvestInWant;

    // buyback ready
    bool public buybackEnabled = true;
    address public mmToken = 0xa283aA7CfBB27EF0cfBcb2493dD9F4330E0fd304;
    address public masterChef = 0xf8873a6080e8dbF41ADa900498DE0951074af577;

    //curve rewards
    address public crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // Tokens
    address public want;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // buyback coins
    address public constant usdcBuyback = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant zrxBuyback = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    // Dex
    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //Sushi
    address constant public sushiRouter = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    constructor(
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public {
        require(_want != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        want = _want;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent {
        require(
            msg.sender == tx.origin ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        uint256 delayReduction;
        uint256 currentBlock = block.number;
        if (delayBlockRequired > 0 && lastHarvestInWant > 0 && currentBlock.sub(lastHarvestBlock) < delayBlockRequired){
            uint256 diffBlock = lastHarvestBlock.add(delayBlockRequired).sub(currentBlock);
            delayReduction = lastHarvestInWant.mul(diffBlock).mul(1e18).div(delayBlockRequired).div(1e18);
        }
        return balanceOfWant().add(balanceOfPool()).sub(delayReduction);
    }

    function getName() external virtual pure returns (string memory);

    // **** Setters **** //

    function setDelayBlockRequired(uint256 _delayBlockRequired) external {
        require(msg.sender == governance, "!governance");
        delayBlockRequired = _delayBlockRequired;
    }

    function setDevFundFee(uint256 _devFundFee) external {
        require(msg.sender == timelock, "!timelock");
        devFundFee = _devFundFee;
    }

    function setTreasuryFee(uint256 _treasuryFee) external {
        require(msg.sender == timelock, "!timelock");
        treasuryFee = _treasuryFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == timelock, "!timelock");
        performanceFee = _performanceFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function setMmToken(address _mmToken) external {
        require(msg.sender == governance, "!governance");
        mmToken = _mmToken;
    }

    function setBuybackEnabled(bool _buybackEnabled) external {
        require(msg.sender == governance, "!governance");
        buybackEnabled = _buybackEnabled;
    }

    function setMasterChef(address _masterChef) external {
        require(msg.sender == governance, "!governance");
        masterChef = _masterChef;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    function withdraw(IERC20 _asset) external virtual returns (uint256 balance);

    // Controller only function for creating additional rewards from dust
    function _withdrawNonWantAsset(IERC20 _asset) internal returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
				
        uint256 _feeDev = _amount.mul(devFundFee).div(devFundMax);
        uint256 _feeTreasury = _amount.mul(treasuryFee).div(treasuryMax);

        if (buybackEnabled == true) {
            // we want buyback mm using LP token
            (address _buybackPrinciple, uint256 _buybackAmount) = _convertWantToBuyback(_feeDev.add(_feeTreasury));
            buybackAndNotify(_buybackPrinciple, _buybackAmount);
        } else {
            IERC20(want).safeTransfer(IController(controller).devfund(), _feeDev);
            IERC20(want).safeTransfer(IController(controller).treasury(), _feeTreasury);
        }

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_vault, _amount.sub(_feeDev).sub(_feeTreasury));
    }
	
    // buyback MM and notify MasterChef
    function buybackAndNotify(address _buybackPrinciple, uint256 _buybackAmount) internal {
        if (buybackEnabled == true) {
            _swapUniswap(_buybackPrinciple, mmToken, _buybackAmount);
            uint256 _mmBought = IERC20(mmToken).balanceOf(address(this));
            IERC20(mmToken).safeTransfer(masterChef, _mmBought);
            IMasterchef(masterChef).notifyBuybackReward(_mmBought);
        }
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);	
	
    // convert LP to buyback principle token
    function _convertWantToBuyback(uint256 _lpAmount) internal virtual returns (address, uint256);

    // each harvest need to update `lastHarvestBlock=block.number` and `lastHarvestInWant=yield profit converted to want for re-invest`
    function harvest() public virtual;

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    revert(add(response, 0x20), size)
                }
        }
    }

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        if (_amount > 0){

            address[] memory path = (_to == usdcBuyback)? new address[](3) : new address[](2);
            path[0] = _from;
            if (_to == usdcBuyback){
                path[1] = weth;
                path[2] = _to;
            }else{
                path[1] = _to;
            }

            UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                now
            );
        }
    }

}


interface AggregatorV3Interface {
  
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
  );

}


abstract contract StrategyUnitBase is StrategyBase {
    // Unit Protocol module: https://github.com/unitprotocol/core/blob/master/CONTRACTS.md	
    address public constant cdpMgr01 = 0x0e13ab042eC5AB9Fc6F43979406088B9028F66fA;
    address public constant unitVault = 0xb1cFF81b9305166ff1EFc49A129ad2AfCd7BCf19;		
    address public constant unitVaultParameters = 0xB46F8CF42e504Efe8BEf895f848741daA55e9f1D;	
    address public constant debtToken = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address public constant eth_usd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // sub-strategy related constants
    address public collateral;
    uint256 public collateralDecimal = 1e18;
    address public unitOracle;
    uint256 public collateralPriceDecimal = 1;
    bool public collateralPriceEth = false;
	
    // configurable minimum collateralization percent this strategy would hold for CDP
    uint256 public minRatio = 200;
    // collateralization percent buffer in CDP debt actions
    uint256 public ratioBuff = 200;
    uint256 public constant ratioBuffMax = 10000;

    // Keeper bots, maintain ratio above minimum requirement
    mapping(address => bool) public keepers;

    constructor(
        address _collateral,
        uint256 _collateralDecimal,
        address _collateralOracle,
        uint256 _collateralPriceDecimal,
        bool _collateralPriceEth,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        require(_want == _collateral, '!mismatchWant');
		    
        collateral = _collateral;   
        collateralDecimal = _collateralDecimal;
        unitOracle = _collateralOracle;
        collateralPriceDecimal = _collateralPriceDecimal;
        collateralPriceEth = _collateralPriceEth;		
		
        IERC20(collateral).safeApprove(unitVault, uint256(-1));
        IERC20(debtToken).safeApprove(unitVault, uint256(-1));
    }

    // **** Modifiers **** //

    modifier onlyKeepers {
        require(keepers[msg.sender] || msg.sender == address(this) || msg.sender == strategist || msg.sender == governance, "!keepers");
        _;
    }
	
    modifier onlyGovernanceAndStrategist {
        require(msg.sender == governance || msg.sender == strategist, "!governance");
        _;
    }
	
    modifier onlyCDPInUse {
        uint256 collateralAmt = getCollateralBalance();
        require(collateralAmt > 0, '!zeroCollateral');
		
        uint256 debtAmt = getDebtBalance();
        require(debtAmt > 0, '!zeroDebt');		
        _;
    }
	
    function getCollateralBalance() public view returns (uint256) {
        return IUnitVault(unitVault).collaterals(collateral, address(this));
    }
	
    function getDebtBalance() public view returns (uint256) {
        return IUnitVault(unitVault).getTotalDebt(collateral, address(this));
    }	
	
    function getDebtWithoutFee() public view returns (uint256) {
        return IUnitVault(unitVault).debts(collateral, address(this));
    }	

    // **** Getters ****
	
    function debtLimit() public view returns (uint256){
        return IUnitVaultParameters(unitVaultParameters).tokenDebtLimit(collateral);
    }
	
    function debtUsed() public view returns (uint256){
        return IUnitVault(unitVault).tokenDebts(collateral);
    }
	
    function balanceOfPool() public override view returns (uint256){
        return getCollateralBalance();
    }

    function collateralValue(uint256 collateralAmt) public view returns (uint256){
        uint256 collateralPrice = getLatestCollateralPrice();
        return collateralAmt.mul(collateralPrice).mul(1e18).div(collateralDecimal).div(collateralPriceDecimal);// debtToken in 1e18 decimal
    }

    function currentRatio() public onlyCDPInUse view returns (uint256) {	    
        uint256 collateralAmt = collateralValue(getCollateralBalance()).mul(100);
        uint256 debtAmt = getDebtBalance();		
        return collateralAmt.div(debtAmt);
    } 
    
    // if borrow is true (for lockAndDraw): return (maxDebt - currentDebt) if positive value, otherwise return 0
    // if borrow is false (for redeemAndFree): return (currentDebt - maxDebt) if positive value, otherwise return 0
    function calculateDebtFor(uint256 collateralAmt, bool borrow) public view returns (uint256) {
        uint256 maxDebt = collateralValue(collateralAmt).mul(ratioBuffMax).div(_getBufferedMinRatio(ratioBuffMax));
		
        uint256 debtAmt = getDebtBalance();
		
        uint256 debt = 0;
        
        if (borrow && maxDebt >= debtAmt){
            debt = maxDebt.sub(debtAmt);
        } else if (!borrow && debtAmt >= maxDebt){
            debt = debtAmt.sub(maxDebt);
        }
        
        return (debt > 0)? debt : 0;
    }
	
    function _getBufferedMinRatio(uint256 _multiplier) internal view returns (uint256){
        return minRatio.mul(_multiplier).mul(ratioBuffMax.add(ratioBuff)).div(ratioBuffMax).div(100);
    }

    function borrowableDebt() public view returns (uint256) {
        uint256 collateralAmt = getCollateralBalance();
        return calculateDebtFor(collateralAmt, true);
    }

    function requiredPaidDebt(uint256 _redeemCollateralAmt) public view returns (uint256) {
        uint256 collateralAmt = getCollateralBalance().sub(_redeemCollateralAmt);
        return calculateDebtFor(collateralAmt, false);
    }

    // **** sub-strategy implementation ****
    function _convertWantToBuyback(uint256 _lpAmount) internal virtual override returns (address, uint256);
	
    function _depositUSDP(uint256 _usdpAmt) internal virtual;
	
    function _withdrawUSDP(uint256 _usdpAmt) internal virtual;
	
    // **** Oracle (using chainlink) ****
	
    function getLatestCollateralPrice() public view returns (uint256){
        require(unitOracle != address(0), '!_collateralOracle');	
		
        (,int price,,,) = AggregatorV3Interface(unitOracle).latestRoundData();
		
        if (price > 0){		
            int ethPrice = 1;
            if (collateralPriceEth){
               (,ethPrice,,,) = AggregatorV3Interface(eth_usd).latestRoundData();// eth price from chainlink in 1e8 decimal		
            }
            return uint256(price).mul(collateralPriceDecimal).mul(uint256(ethPrice)).div(1e8).div(collateralPriceEth? 1e18 : 1);
        } else{
            return 0;
        }
    }

    // **** Setters ****
	
    function setMinRatio(uint256 _minRatio) external onlyGovernanceAndStrategist {
        minRatio = _minRatio;
    }	
	
    function setRatioBuff(uint256 _ratioBuff) external onlyGovernanceAndStrategist {
        ratioBuff = _ratioBuff;
    }	

    function setKeeper(address _keeper, bool _enabled) external onlyGovernanceAndStrategist {
        keepers[_keeper] = _enabled;
    }
	
    // **** Unit Protocol CDP actions ****
	
    function addCollateralAndBorrow(uint256 _collateralAmt, uint256 _usdpAmt) internal {   
        require(_usdpAmt.add(debtUsed()) < debtLimit(), '!exceedLimit');
        IUnitCDPManager(cdpMgr01).join(collateral, _collateralAmt, _usdpAmt);		
    } 
	
    function repayAndRedeemCollateral(uint256 _collateralAmt, uint _usdpAmt) internal { 
        IUnitCDPManager(cdpMgr01).exit(collateral, _collateralAmt, _usdpAmt);     		
    } 

    // **** State Mutation functions ****
	
    function keepMinRatio() external onlyCDPInUse onlyKeepers {		
        uint256 requiredPaidback = requiredPaidDebt(0);
        if (requiredPaidback > 0){
            _withdrawUSDP(requiredPaidback);
			
            uint256 _actualPaidDebt = IERC20(debtToken).balanceOf(address(this));
            uint256 _fee = getDebtBalance().sub(getDebtWithoutFee());
			
            require(_actualPaidDebt > _fee, '!notEnoughForFee');	
            _actualPaidDebt = _actualPaidDebt.sub(_fee);// unit protocol will charge fee first
            _actualPaidDebt = _capMaxDebtPaid(_actualPaidDebt);			
			
            require(IERC20(debtToken).balanceOf(address(this)) >= _actualPaidDebt.add(_fee), '!notEnoughRepayment');
            repayAndRedeemCollateral(0, _actualPaidDebt);
        }
    }
	
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {	
            uint256 _newDebt = calculateDebtFor(_want.add(getCollateralBalance()), true);
            if (_newDebt > 0){
                addCollateralAndBorrow(_want, _newDebt);
                uint256 wad = IERC20(debtToken).balanceOf(address(this));
                _depositUSDP(_newDebt > wad? wad : _newDebt);
            }
        }
    }
	
    // to avoid repay all debt
    function _capMaxDebtPaid(uint256 _actualPaidDebt) internal view returns(uint256){
        uint256 _maxDebtToRepay = getDebtWithoutFee().sub(ratioBuffMax);
        return _actualPaidDebt >= _maxDebtToRepay? _maxDebtToRepay : _actualPaidDebt;
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        if (_amount == 0){
            return _amount;
        }
        
        uint256 requiredPaidback = requiredPaidDebt(_amount);		
        if (requiredPaidback > 0){
            _withdrawUSDP(requiredPaidback);
        }
		
        bool _fullWithdraw = _amount == balanceOfPool();
        uint256 _wantBefore = IERC20(want).balanceOf(address(this));
        if (!_fullWithdraw){
            uint256 _actualPaidDebt = IERC20(debtToken).balanceOf(address(this));
            uint256 _fee = getDebtBalance().sub(getDebtWithoutFee());
		
            require(_actualPaidDebt > _fee, '!notEnoughForFee');				
            _actualPaidDebt = _actualPaidDebt.sub(_fee); // unit protocol will charge fee first
            _actualPaidDebt = _capMaxDebtPaid(_actualPaidDebt);
			
            require(IERC20(debtToken).balanceOf(address(this)) >= _actualPaidDebt.add(_fee), '!notEnoughRepayment');
            repayAndRedeemCollateral(_amount, _actualPaidDebt);			
        }else{
            require(IERC20(debtToken).balanceOf(address(this)) >= getDebtBalance(), '!notEnoughFullRepayment');
            repayAndRedeemCollateral(_amount, getDebtBalance());
            require(getDebtBalance() == 0, '!leftDebt');
            require(getCollateralBalance() == 0, '!leftCollateral');
        }
		
        uint256 _wantAfter = IERC20(want).balanceOf(address(this));		
        return _wantAfter.sub(_wantBefore);
    }
    
}

contract StrategyUnitRenbtcV1 is StrategyUnitBase {
    // strategy specific
    address public constant renbtc_collateral = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    uint256 public constant renbtc_collateral_decimal = 1e8;
    address public constant renbtc_oracle = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    uint256 public constant renbtc_price_decimal = 1;
    bool public constant renbtc_price_eth = false;
	
    // farming in usdp3crv 
    address public constant usdp3crv = 0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6;
    address public constant usdp = 0x1456688345527bE1f37E9e627DA0837D6f08C925;
    address public constant usdp_gauge = 0x055be5DDB7A925BfEF3417FC157f53CA77cA7222;
    address public constant curvePool = 0x42d7025938bEc20B69cBae5A77421082407f053A;
    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    
    // slippage protection for one-sided ape in/out
    uint256 public slippageProtectionIn = 50; // max 0.5%
    uint256 public slippageProtectionOut = 50; // max 0.5%
    uint256 public constant DENOMINATOR = 10000;

    constructor(address _governance, address _strategist, address _controller, address _timelock) 
        public StrategyUnitBase(
            renbtc_collateral,
            renbtc_collateral_decimal,
            renbtc_oracle,
            renbtc_price_decimal,
            renbtc_price_eth,
            renbtc_collateral,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        // approve for Curve pool and DEX
        IERC20(usdp).safeApprove(curvePool, uint256(-1));
        IERC20(usdp3crv).safeApprove(curvePool, uint256(-1));
        
        IERC20(usdp3crv).safeApprove(usdp_gauge, uint256(-1));
        
        IERC20(crv).safeApprove(univ2Router2, uint256(-1));
        IERC20(weth).safeApprove(univ2Router2, uint256(-1));
        IERC20(renbtc_collateral).safeApprove(univ2Router2, uint256(-1));
        IERC20(usdcBuyback).safeApprove(univ2Router2, uint256(-1));
    }
	
    // **** Setters ****	
	
    function setSlippageProtectionIn(uint256 _slippage) external onlyGovernanceAndStrategist{
        slippageProtectionIn = _slippage;
    }
	
    function setSlippageProtectionOut(uint256 _slippage) external onlyGovernanceAndStrategist{
        slippageProtectionOut = _slippage;
    }
	
    // **** State Mutation functions ****	

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(usdp_gauge).claimable_tokens(address(this));
    }

    function _convertWantToBuyback(uint256 _lpAmount) internal override returns (address, uint256){
        _swapUniswap(renbtc_collateral, usdcBuyback, _lpAmount);
        return (usdcBuyback, IERC20(usdcBuyback).balanceOf(address(this)));
    }	
	
    function harvest() public override onlyBenevolent {

        // Collects crv tokens
        ICurveMintr(mintr).mint(usdp_gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            _swapUniswap(crv, weth, _crv);
        }

        // buyback $MM
        uint256 _to = IERC20(weth).balanceOf(address(this));
        uint256 _buybackAmount = _to.mul(performanceFee).div(performanceMax);		
        if (buybackEnabled == true && _buybackAmount > 0) {
            buybackAndNotify(weth, _buybackAmount);
        }
		
        // re-invest to compounding profit
        _swapUniswap(weth, want, IERC20(weth).balanceOf(address(this)));
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            lastHarvestBlock = block.number;
            lastHarvestInWant = _want;
            deposit();
        }
    }
	
    function _depositUSDP(uint256 _usdpAmt) internal override{	
        if (_usdpAmt > 0 && checkSlip(_usdpAmt)) {
            uint256[2] memory amounts = [_usdpAmt, 0]; 
            ICurveFi_2(curvePool).add_liquidity(amounts, 0);
        }
		
        uint256 _usdp3crv = IERC20(usdp3crv).balanceOf(address(this));
        if (_usdp3crv > 0){
            ICurveGauge(usdp_gauge).deposit(_usdp3crv);		
        }
    }
	
    function _withdrawUSDP(uint256 _usdpAmt) internal override {	
        uint256 _requiredUsdp3crv = estimateRequiredUsdp3crv(_usdpAmt);
        _requiredUsdp3crv = _requiredUsdp3crv.mul(DENOMINATOR.add(slippageProtectionOut)).div(DENOMINATOR);// try to remove bit more
		
        uint256 _usdp3crv = IERC20(usdp3crv).balanceOf(address(this));
        uint256 _withdrawFromGauge = _usdp3crv < _requiredUsdp3crv? _requiredUsdp3crv.sub(_usdp3crv) : 0;
			
        if (_withdrawFromGauge > 0){
            uint256 maxInGauge = ICurveGauge(usdp_gauge).balanceOf(address(this));
            ICurveGauge(usdp_gauge).withdraw(maxInGauge < _withdrawFromGauge? maxInGauge : _withdrawFromGauge);			
        }
		    	
        _usdp3crv = IERC20(usdp3crv).balanceOf(address(this));
        if (_usdp3crv > 0){
            _requiredUsdp3crv = _requiredUsdp3crv > _usdp3crv?  _usdp3crv : _requiredUsdp3crv;
            uint256 maxSlippage = _requiredUsdp3crv.mul(DENOMINATOR.sub(slippageProtectionOut)).div(DENOMINATOR);
            ICurveFi_2(curvePool).remove_liquidity_one_coin(_requiredUsdp3crv, 0, maxSlippage);			
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external override returns (uint256 balance) {
        require(usdp3crv != address(_asset), "!usdp3crv");
        require(usdp != address(_asset), "!usdp");
        return _withdrawNonWantAsset(_asset);
    }

    // **** Views ****

    function virtualPriceToWant() public view returns (uint256) {
        return ICurveFi_2(curvePool).get_virtual_price();
    }
	
    function estimateRequiredUsdp3crv(uint256 _usdpAmt) public view returns (uint256) {
        uint256[2] memory amounts = [_usdpAmt, 0]; 
        return ICurveFi_2(curvePool).calc_token_amount(amounts, false);
    }
	
    function checkSlip(uint256 _usdpAmt) public view returns (bool){
        uint256 expectedOut = _usdpAmt.mul(1e18).div(virtualPriceToWant());
        uint256 maxSlip = expectedOut.mul(DENOMINATOR.sub(slippageProtectionIn)).div(DENOMINATOR);

        uint256[2] memory amounts = [_usdpAmt, 0]; 
        return ICurveFi_2(curvePool).calc_token_amount(amounts, true) >= maxSlip;
    }

    function getName() external override pure returns (string memory) {
        return "StrategyUnitRenbtcV1";
    }
}