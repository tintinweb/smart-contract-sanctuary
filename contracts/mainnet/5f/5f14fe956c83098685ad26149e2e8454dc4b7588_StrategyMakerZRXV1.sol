/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.6.12;


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

interface ICToken {

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);


    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );


    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);


    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);
}

interface IComptroller {

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);


    // Claim all the COMP accrued by holder in specific markets
    function claimComp(address holder, address[] calldata cTokens) external;

    function markets(address cTokenAddress)
        external
        view
        returns (bool, uint256);
}

interface ICompoundLens {
    function getCompBalanceMetadataExt(
        address comp,
        address comptroller,
        address account
    )
        external
        returns (
            uint256 balance,
            uint256 votes,
            address delegate,
            uint256 allocated
        );
}

interface IMasterchef {
    function notifyBuybackReward(uint256 _amount) external;
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

    // buyback ready
    bool public buybackEnabled = true;
    address public mmToken = 0xa283aA7CfBB27EF0cfBcb2493dD9F4330E0fd304;
    address public masterChef = 0xf8873a6080e8dbF41ADa900498DE0951074af577;
	
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
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external virtual pure returns (string memory);

    // **** Setters **** //

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

    function harvest() public virtual;

    // **** Emergency functions ****


    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_to == mmToken && buybackEnabled == true) {
            if(_from == zrxBuyback){
                path = new address[](4);
                path[0] = _from;
                path[1] = weth;
                path[2] = usdcBuyback;
                path[3] = _to;
            }
        } else{		
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;		
        }

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

}

interface ManagerLike {
    function ilks(uint256) external view returns (bytes32);
    function owns(uint256) external view returns (address);
    function urns(uint256) external view returns (address);
    function vat() external view returns (address);
    function open(bytes32, address) external returns (uint256);
    function give(uint256, address) external;
    function frob(uint256, int256, int256) external;
    function flux(uint256, address, uint256) external;
    function move(uint256, address, uint256) external;
    function exit(address, uint256, address, uint256) external;
    function quit(uint256, address) external;
    function enter(address, uint256) external;
}

interface VatLike {
    function can(address, address) external view returns (uint256);
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function dai(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function frob(bytes32, address, address, address, int256, int256) external;
    function hope(address) external;
    function move(address, address, uint256) external;
}

interface GemJoinLike {
    function dec() external returns (uint256);
    function join(address, uint256) external payable;
    function exit(address, uint256) external;
}

interface DaiJoinLike {
    function join(address, uint256) external payable;
    function exit(address, uint256) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);
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


abstract contract StrategyMakerBase is StrategyBase {
    // MakerDAO modules
    address public dssCdpManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public daiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public jug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public vat = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public debtToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 public minDebt = 2001000000000000000000;
    address public eth_usd = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // sub-strategy related constants
    address public collateral;
    uint256 public collateralDecimal = 1e18;
    address public gemJoin;
    address public collateralOracle;
    bytes32 public collateralIlk;
    AggregatorV3Interface internal priceFeed;
    uint256 public collateralPriceDecimal = 1;
    bool public collateralPriceEth = false;
	
    // singleton CDP for this strategy
    uint256 public cdpId = 0;
	
    // configurable minimum collateralization percent this strategy would hold for CDP
    uint256 public minRatio = 300;
    // collateralization percent buffer in CDP debt actions
    uint256 public ratioBuff = 500;
    uint256 public ratioBuffMax = 10000;
    uint256 constant RAY = 10 ** 27;

    // Keeper bots, maintain ratio above minimum requirement
    mapping(address => bool) public keepers;

    constructor(
        address _collateralJoin,
        bytes32 _collateralIlk,
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
		
        gemJoin = _collateralJoin;
        collateralIlk = _collateralIlk;		    
        collateral = _collateral;   
        collateralDecimal = _collateralDecimal;
        collateralOracle = _collateralOracle;
        priceFeed = AggregatorV3Interface(collateralOracle);
        collateralPriceDecimal = _collateralPriceDecimal;
        collateralPriceEth = _collateralPriceEth;
    }

    // **** Modifiers **** //

    modifier onlyKeepers {
        require(
            keepers[msg.sender] ||
                msg.sender == address(this) ||
                msg.sender == strategist ||
                msg.sender == governance,
            "!keepers"
        );
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
	
    modifier onlyCDPInitiated {        
        require(cdpId > 0, '!noCDP');	
        _;
    }
    
    modifier onlyAboveMinDebt(uint256 _daiAmt) {  
        uint256 debtAmt = getDebtBalance();   
        require((_daiAmt < debtAmt && (debtAmt.sub(_daiAmt) >= minDebt)) || debtAmt <= _daiAmt, '!minDebt');
        _;
    }
	
    function getCollateralBalance() public view returns (uint256) {
        (uint256 ink, ) = VatLike(vat).urns(collateralIlk, ManagerLike(dssCdpManager).urns(cdpId));
        return ink;
    }
	
    function getDebtBalance() public view returns (uint256) {
        address urnHandler = ManagerLike(dssCdpManager).urns(cdpId);
        (, uint256 art) = VatLike(vat).urns(collateralIlk, urnHandler);
        (, uint256 rate, , , ) = VatLike(vat).ilks(collateralIlk);
        uint rad = mul(art, rate);
        if (rad == 0) {
            return 0;
        }
        uint256 wad = rad / RAY;
        return mul(wad, RAY) < rad ? wad + 1 : wad;
    }	

    // **** Getters ****
	
    function balanceOfPool() public override view returns (uint256){
        return getCollateralBalance();
    }

    function collateralValue(uint256 collateralAmt) public view returns (uint256){
        uint256 collateralPrice = getLatestCollateralPrice();
        return collateralAmt.mul(collateralPrice).mul(1e18).div(collateralDecimal).div(collateralPriceDecimal);
    }

    function currentRatio() public onlyCDPInUse view returns (uint256) {	    
        uint256 collateralAmt = collateralValue(getCollateralBalance()).mul(100);
        uint256 debtAmt = getDebtBalance();		
        return collateralAmt.div(debtAmt);
    } 
    
    // if borrow is true (for lockAndDraw): return (maxDebt - currentDebt) if positive value, otherwise return 0
    // if borrow is false (for redeemAndFree): return (currentDebt - maxDebt) if positive value, otherwise return 0
    function calculateDebtFor(uint256 collateralAmt, bool borrow) public view returns (uint256) {
        uint256 maxDebt = collateralValue(collateralAmt).mul(10000).div(minRatio.mul(10000).mul(ratioBuffMax + ratioBuff).div(ratioBuffMax).div(100));
		
        uint256 debtAmt = getDebtBalance();
		
        uint256 debt = 0;
        
        if (borrow && maxDebt >= debtAmt){
            debt = maxDebt.sub(debtAmt);
        } else if (!borrow && debtAmt >= maxDebt){
            debt = debtAmt.sub(maxDebt);
        }
        
        return (debt > 0)? debt : 0;
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
	
    function _depositDAI(uint256 _daiAmt) internal virtual;
	
    function _withdrawDAI(uint256 _daiAmt) internal virtual;
	
    // **** Oracle (using chainlink) ****
	
    function getLatestCollateralPrice() public view returns (uint256){
        require(collateralOracle != address(0), '!_collateralOracle');	
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
		
        if (price > 0){
            int ethPrice = 1;
            if (collateralPriceEth){
               (,ethPrice,,,) = AggregatorV3Interface(eth_usd).latestRoundData();			
            }
            return uint256(price).mul(collateralPriceDecimal).mul(uint256(ethPrice)).div(1e8).div(collateralPriceEth? 1e18 : 1);
        } else{
            return 0;
        }
    }

    // **** Setters ****
 
    function setMinDebt(uint256 _minDebt) external onlyGovernanceAndStrategist {
        minDebt = _minDebt;
    }	
 
    function setMinRatio(uint256 _minRatio) external onlyGovernanceAndStrategist {
        minRatio = _minRatio;
    }	
	
    function setRatioBuff(uint256 _ratioBuff) external onlyGovernanceAndStrategist {
        ratioBuff = _ratioBuff;
    }	

    function setKeeper(address _keeper, bool _enabled) external onlyGovernanceAndStrategist {
        keepers[_keeper] = _enabled;
    }
	
    // **** MakerDAO CDP actions ****

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }
	
    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, RAY);
    }
	
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-overflow");
    }
	
    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }
	
    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {
        wad = mul(amt, 10 ** (18 - GemJoinLike(gemJoin).dec()));
    }
	
    function _getDrawDart(address vat, address jug, address urn, bytes32 ilk, uint wad) internal returns (int256 dart) {
        uint256 rate = JugLike(jug).drip(ilk);
        uint256 dai = VatLike(vat).dai(urn);
        if (dai < toRad(wad)) {
            dart = toInt(sub(toRad(wad), dai).div(rate));
            dart = mul(uint256(dart), rate) < toRad(wad) ? dart + 1 : dart;
        }
    }
	
    function _getWipeDart(address vat, uint dai, address urn, bytes32 ilk) internal view returns (int256 dart) {
        (, uint256 rate,,,) = VatLike(vat).ilks(ilk);
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        dart = toInt(dai.div(rate));
        dart = uint256(dart) <= art ? - dart : - toInt(art);
    }
	
    function openCDP() external {
        require(msg.sender == governance, "!governance");
        require(cdpId <= 0, "!cdpAlreadyOpened");
		
        cdpId = ManagerLike(dssCdpManager).open(collateralIlk, address(this));		
		
        IERC20(collateral).approve(gemJoin, uint256(-1));
        IERC20(debtToken).approve(daiJoin, uint256(-1));
    }
	
    function getUrnVatIlk() internal returns (address, address, bytes32){
        return (ManagerLike(dssCdpManager).urns(cdpId), ManagerLike(dssCdpManager).vat(), ManagerLike(dssCdpManager).ilks(cdpId));
    }
	
    function addCollateralAndBorrow(uint256 _collateralAmt, uint256 _daiAmt) internal onlyCDPInitiated {   
        require(_daiAmt.add(getDebtBalance()) >= minDebt, '!minDebt');
        (address urn, address vat, bytes32 ilk) = getUrnVatIlk();		
		GemJoinLike(gemJoin).join(urn, _collateralAmt);  
		ManagerLike(dssCdpManager).frob(cdpId, toInt(convertTo18(gemJoin, _collateralAmt)), _getDrawDart(vat, jug, urn, ilk, _daiAmt));
		ManagerLike(dssCdpManager).move(cdpId, address(this), toRad(_daiAmt));
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        DaiJoinLike(daiJoin).exit(address(this), _daiAmt);
    } 
	
    function repayAndRedeemCollateral(uint256 _collateralAmt, uint _daiAmt) internal onlyCDPInitiated onlyAboveMinDebt(_daiAmt) { 
        (address urn, address vat, bytes32 ilk) = getUrnVatIlk();
        if (_daiAmt > 0){
            DaiJoinLike(daiJoin).join(urn, _daiAmt);
        }
        uint256 wad18 = _collateralAmt > 0? convertTo18(gemJoin, _collateralAmt) : 0;
        ManagerLike(dssCdpManager).frob(cdpId, -toInt(wad18),  _getWipeDart(vat, VatLike(vat).dai(urn), urn, ilk));
        if (_collateralAmt > 0){
            ManagerLike(dssCdpManager).flux(cdpId, address(this), wad18);
            GemJoinLike(gemJoin).exit(address(this), _collateralAmt);
        }
    } 

    // **** State Mutation functions ****
	
    function keepMinRatio() external onlyCDPInUse onlyKeepers {		
        uint256 requiredPaidback = requiredPaidDebt(0);
        if (requiredPaidback > 0){
            _withdrawDAI(requiredPaidback);
            uint256 wad = IERC20(debtToken).balanceOf(address(this));
            require(wad >= requiredPaidback, '!keepMinRatioRedeem');
			
            repayAndRedeemCollateral(0, requiredPaidback);
            uint256 goodRatio = currentRatio();
            require(goodRatio >= minRatio.sub(1), '!stillBelowMinRatio');
        }
    }
	
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {	
            uint256 _newDebt = calculateDebtFor(_want.add(getCollateralBalance()), true);
            if(_newDebt > 0 && _newDebt.add(getDebtBalance()) >= minDebt){
               addCollateralAndBorrow(_want, _newDebt);
               uint256 wad = IERC20(debtToken).balanceOf(address(this));
               _depositDAI(_newDebt > wad? wad : _newDebt);
            }
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        uint256 requiredPaidback = requiredPaidDebt(_amount);
        if (requiredPaidback > 0){
            _withdrawDAI(requiredPaidback);
            require(IERC20(debtToken).balanceOf(address(this)) >= requiredPaidback, '!mismatchAfterWithdraw');
        }
		
        repayAndRedeemCollateral(_amount, requiredPaidback);
        
        return _amount;
    }
    
}

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }
}

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }
}

interface IERC3156FlashLender {
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external;
}

interface IERC3156FlashBorrower {
    function onFlashLoan(address sender, address token, uint256 amount, uint256 fee, bytes calldata data) external;
}

abstract contract StrategyCmpdDaiBase is Exponential, IERC3156FlashBorrower{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    enum Action {LEVERAGE, DELEVERAGE}
    bytes DATA_LEVERAGE = abi.encode(Action.LEVERAGE);
    bytes DATA_DELEVERAGE = abi.encode(Action.DELEVERAGE);
	
    address public constant comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant lens = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address public constant cdai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant cether = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public dydxFlashloanWrapper = 0x6bdC1FCB2F13d1bA9D26ccEc3983d5D4bf318693;
    address public constant dydxSoloMargin = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    bool public dydxFlashloanEnabled = true;

    // Require a 0.1 buffer between market collateral factor and strategy's collateral factor when leveraging
    uint256 colFactorLeverageBuffer = 100;
    uint256 colFactorLeverageBufferMax = 1000;

    // Allow a 0.05 buffer between market collateral factor and strategy's collateral factor until we have to deleverage
    // This is so we can hit max leverage and keep accruing interest
    uint256 colFactorSyncBuffer = 50;
    uint256 colFactorSyncBufferMax = 1000;

    event FlashLoanLeverage(uint256 _amount, uint256 _fee, bytes _data, Action action);
    event FlashLoanDeleverage(uint256 _amount, uint256 _fee, bytes _data, Action action);

    constructor() public {
        // Enter cDAI Market
        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;
        IComptroller(comptroller).enterMarkets(ctokens);

        IERC20(dai).safeApprove(cdai, uint256(-1));
    }

    // **** Modifiers **** //
    // **** Views **** //

    function getSuppliedView() public view returns (uint256) {
        (, uint256 cTokenBal, , uint256 exchangeRate) = ICToken(cdai).getAccountSnapshot(address(this));
        (, uint256 bal) = mulScalarTruncate(Exp({mantissa: exchangeRate}), cTokenBal);
        return bal;
    }

    function getBorrowedView() public view returns (uint256) {
        return ICToken(cdai).borrowBalanceStored(address(this));
    }

    // Given an unleveraged supply balance, return the target leveraged supply balance which is still within the safety buffer
    function getLeveragedSupplyTarget(uint256 supplyBalance) public view returns (uint256) {
        uint256 leverage = getMaxLeverage();
        return supplyBalance.mul(leverage).div(1e18);
    }

    function getSafeLeverageColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();
        // Collateral factor within the buffer
        uint256 safeColFactor = colFactor.sub(colFactorLeverageBuffer.mul(1e18).div(colFactorLeverageBufferMax));
        return safeColFactor;
    }

    function getSafeSyncColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();
        // Collateral factor within the buffer
        uint256 safeColFactor = colFactor.sub(colFactorSyncBuffer.mul(1e18).div(colFactorSyncBufferMax));
        return safeColFactor;
    }

    function getMarketColFactor() public view returns (uint256) {
        (, uint256 colFactor) = IComptroller(comptroller).markets(cdai);
        return colFactor;
    }

    // Max leverage we can go up to, w.r.t safe buffer
    function getMaxLeverage() public view returns (uint256) {
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();
        // Infinite geometric series
        uint256 leverage = uint256(1e36).div(1e18 - safeLeverageColFactor);
        return leverage;
    }	
	
    // If we have a strategy position at this SOS borrow rate and left unmonitored for 24+ hours, we might get liquidated
    // To safeguard with enough buffer, we divide the borrow rate by 2 which indicates allowing 48 hours response time
    function getSOSBorrowRate() public view returns (uint256) {
        uint256 safeColFactor = getSafeLeverageColFactor();
        return (colFactorLeverageBuffer.mul(182).mul(1e36).div(colFactorLeverageBufferMax)).div(safeColFactor);
    }

    // **** Pseudo-view functions (use `callStatic` on these) **** //
    /* The reason why these exists is because of the nature of the
       interest accruing supply + borrow balance. The "view" methods
       are technically snapshots and don't represent the real value.
       As such there are pseudo view methods where you can retrieve the
       results by calling `callStatic`.
    */

    function getCompAccrued() public returns (uint256) {
        (, , , uint256 accrued) = ICompoundLens(lens).getCompBalanceMetadataExt(comp, comptroller, address(this));
        return accrued;
    }

    function getColFactor() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return borrowed.mul(1e18).div(supplied);
    }

    function getSuppliedUnleveraged() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.sub(borrowed);
    }

    function getSupplied() public returns (uint256) {
        return ICToken(cdai).balanceOfUnderlying(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return ICToken(cdai).borrowBalanceCurrent(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IComptroller(comptroller).markets(cdai);

        // 99.99% just in case some dust accumulates
        return supplied.mul(colFactor).div(1e18).sub(borrowed).mul(9999).div(10000);
    }

    function getCurrentLeverage() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }

    // **** State mutations **** //

    // Leverages until we're supplying <x> amount
    function _lUntil(uint256 _supplyAmount) internal {
        uint256 leverage = getMaxLeverage();
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 supplied = getSupplied();
        require(_supplyAmount >= unleveragedSupply && _supplyAmount <= unleveragedSupply.mul(leverage).div(1e18) && _supplyAmount >= supplied, "!leverage");

        // Since we're only leveraging one asset
        // Supplied = borrowed
        uint256 _gap = _supplyAmount.sub(supplied);
        if (_flashloanApplicable(_gap)){
           IERC3156FlashLender(dydxFlashloanWrapper).flashLoan(address(this), dai, _gap, DATA_LEVERAGE);
        }else{
            uint256 _borrowAndSupply;
            while (supplied < _supplyAmount) {
                _borrowAndSupply = getBorrowable();
                if (supplied.add(_borrowAndSupply) > _supplyAmount) {
                   _borrowAndSupply = _supplyAmount.sub(supplied);
                }
                _leveraging(_borrowAndSupply, false);
                supplied = supplied.add(_borrowAndSupply);
            }
        }
    }

    // Deleverages until we're supplying <x> amount
    function _dlUntil(uint256 _supplyAmount) internal {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 supplied = getSupplied();
        require(_supplyAmount >= unleveragedSupply && _supplyAmount <= supplied, "!deleverage");

        // Since we're only leveraging on 1 asset
        // redeemable = borrowable
        uint256 _gap = supplied.sub(_supplyAmount);
        if (_flashloanApplicable(_gap)){
            IERC3156FlashLender(dydxFlashloanWrapper).flashLoan(address(this), dai, _gap, DATA_DELEVERAGE);
        } else{
            uint256 _redeemAndRepay = getBorrowable();
            do {
                if (supplied.sub(_redeemAndRepay) < _supplyAmount) {
                   _redeemAndRepay = supplied.sub(_supplyAmount);
                }
                _deleveraging(_redeemAndRepay, _redeemAndRepay, false);
                supplied = supplied.sub(_redeemAndRepay);
            } while (supplied > _supplyAmount);
        }
    }
	
    // **** internal state changer ****
	
    // for redeem supplied (unleveraged) DAI from compound
    function _redeemDAI(uint256 _want) internal {
        uint256 maxRedeem = getSuppliedUnleveraged();
        _want = _want > maxRedeem? maxRedeem : _want;
        
        uint256 _redeem = _want;
        if (_redeem > 0) {
            // Make sure market can cover liquidity
            require(ICToken(cdai).getCash() >= _redeem, "!cash-liquidity");

            // How much borrowed amount do we need to free?
            uint256 borrowed = getBorrowed();
            uint256 supplied = getSupplied();
            uint256 curLeverage = getCurrentLeverage();
            uint256 borrowedToBeFree = _redeem.mul(curLeverage).div(1e18);

            // If the amount we need to free is > borrowed, Just free up all the borrowed amount
            if (borrowedToBeFree > borrowed) {
                _dlUntil(getSuppliedUnleveraged());
            } else {
                // Otherwise just keep freeing up borrowed amounts until we hit a safe number to redeem our underlying
                _dlUntil(supplied.sub(borrowedToBeFree));
            }

            // Redeems underlying
            require(ICToken(cdai).redeemUnderlying(_redeem) == 0, "!redeem");
        }
    }
	
    function _supplyDAI(uint256 _wad) internal {
        if (_wad > 0) {
            require(ICToken(cdai).mint(_wad) == 0, "!depositIntoCmpd");
        }
    }
	
    function _claimComp() internal {
        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;
        IComptroller(comptroller).claimComp(address(this), ctokens);
    }

    function _flashloanApplicable(uint256 _gap) internal returns (bool){
        return dydxFlashloanEnabled && IERC20(dai).balanceOf(dydxSoloMargin) > _gap && _gap > 0;
    }

    //dydx flashloan callback
    function onFlashLoan(address origin, address _token, uint256 _amount, uint256 _loanFee, bytes calldata _data) public override {
        require(_token == dai && msg.sender == dydxFlashloanWrapper && origin == address(this), "!Flash");

        uint256 total = _amount.add(_loanFee);
        require(IERC20(dai).balanceOf(address(this)) >= _amount, '!balFlash');

        (Action action) = abi.decode(_data, (Action));

        if (action == Action.LEVERAGE){
            _leveraging(total, true);
            emit FlashLoanLeverage(_amount, _loanFee, _data, Action.LEVERAGE);
        } else{
            _deleveraging(_amount, total, true);
            emit FlashLoanDeleverage(_amount, _loanFee, _data, Action.DELEVERAGE);
        }

        require(IERC20(dai).balanceOf(address(this)) >= total, '!deficitFlashRepay');
    }
    
    function _leveraging(uint256 _borrowAmount, bool _flash) internal {
        if (_flash){
            _supplyDAI(IERC20(dai).balanceOf(address(this)));
            require(ICToken(cdai).borrow(_borrowAmount) == 0, "!bFlashLe");
        } else{
            require(ICToken(cdai).borrow(_borrowAmount) == 0, "!bLe");
            _supplyDAI(IERC20(dai).balanceOf(address(this)));
        }
    }
    
    function _deleveraging(uint256 _repayAmount, uint256 _redeemAmount, bool _flash) internal {
        if (_flash){
            require(ICToken(cdai).repayBorrow(_repayAmount) == 0, "!rFlashDe");
            require(ICToken(cdai).redeemUnderlying(_redeemAmount) == 0, "!reFlashDe");
        } else{
            require(ICToken(cdai).redeemUnderlying(_redeemAmount) == 0, "!reDe");
            require(ICToken(cdai).repayBorrow(_repayAmount) == 0, "!rDe");
        }
    }
}

contract StrategyMakerZRXV1 is StrategyMakerBase, StrategyCmpdDaiBase {
    // strategy specific
    address public zrx_collateral = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
    address public zrx_eth = 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962;
    uint256 public zrx_collateral_decimal = 1e18;
    bytes32 public zrx_ilk = "ZRX-A";
    address public zrx_apt = 0xc7e8Cd72BDEe38865b4F5615956eF47ce1a7e5D0;
    uint256 public zrx_price_decimal = 1e2;
    bool public zrx_price_eth = true;

    constructor(address _governance, address _strategist, address _controller, address _timelock) 
        public StrategyMakerBase(
            zrx_apt,
            zrx_ilk,
            zrx_collateral,
            zrx_collateral_decimal,
            zrx_eth,
            zrx_price_decimal,
            zrx_price_eth,
            zrx_collateral,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        // approve for dex swap
        IERC20(zrx_collateral).safeApprove(univ2Router2, uint256(-1));
        IERC20(comp).safeApprove(univ2Router2, uint256(-1));
        IERC20(dai).safeApprove(dydxFlashloanWrapper, uint256(-1));
    }
	
    // **** Setters ****	

    function setColFactorLeverageBuffer(uint256 _colFactorLeverageBuffer) public onlyGovernanceAndStrategist {
        colFactorLeverageBuffer = _colFactorLeverageBuffer;
    }

    function setColFactorSyncBuffer(uint256 _colFactorSyncBuffer) public onlyGovernanceAndStrategist {
        colFactorSyncBuffer = _colFactorSyncBuffer;
    }

    function setDydxFlashloanEnabled(bool _dydxFlashloanEnabled) public onlyGovernanceAndStrategist {
        dydxFlashloanEnabled = _dydxFlashloanEnabled;
    }
	
    // **** State Mutation functions ****	

    function leverageToMax() public onlyKeepers{
        uint256 idealSupply = getLeveragedSupplyTarget(getSuppliedUnleveraged());
        _lUntil(idealSupply);
    }

    function deleverageToMin() public onlyKeepers{
        _dlUntil(getSuppliedUnleveraged());
    }
	
    function harvest() public override onlyBenevolent {
        _claimComp();
		
        uint256 _comp = IERC20(comp).balanceOf(address(this));
        if (_comp > 0) {
            _swapUniswap(comp, want, _comp);
        }

        uint256 _want = IERC20(want).balanceOf(address(this));
        uint256 _buybackAmount = _want.mul(performanceFee).div(performanceMax);

        if (buybackEnabled == true && _buybackAmount > 0) {
            buybackAndNotify(want, _buybackAmount);
        } 

        // re-invest to compounding profit
        deposit();
    }
	
    function _convertWantToBuyback(uint256 _lpAmount) internal override returns (address, uint256){
        return (zrx_collateral, _lpAmount);
    }
	
    function _depositDAI(uint256 _daiAmt) internal override{	
        _supplyDAI(_daiAmt);
    }
	
    function _withdrawDAI(uint256 _daiAmt) internal override{	
        _redeemDAI(_daiAmt);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external override returns (uint256 balance) {
        require(cdai != address(_asset), "!cToken");
        _withdrawNonWantAsset(_asset);
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategyMakerZRXV1";
    }
}