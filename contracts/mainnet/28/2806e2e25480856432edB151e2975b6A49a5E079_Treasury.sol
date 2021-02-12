// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import {Math} from '@openzeppelin/contracts/math/Math.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
    ReentrancyGuard
} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import {ICustomERC20} from '../interfaces/ICustomERC20.sol';
import {IUniswapV2Factory} from '../interfaces/IUniswapV2Factory.sol';
import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';
import {IBoardroom} from '../interfaces/IBoardroom.sol';
import {IBasisAsset} from '../interfaces/IBasisAsset.sol';
import {ISimpleERCFund} from '../interfaces/ISimpleERCFund.sol';
import {Operator} from '../owner/Operator.sol';
import {Epoch} from '../utils/Epoch.sol';
import {ContractGuard} from '../utils/ContractGuard.sol';
import {TreasuryHelpers} from './TreasuryHelpers.sol';

/**
 * @title ARTH Treasury contract
 * @notice Monetary policy logic to adjust supplies of basis cash assets
 * @author Steven Enamakel & Yash Agrawal. Original code written by Summer Smith & Rick Sanchez
 */
contract Treasury is TreasuryHelpers {
    using SafeERC20 for ICustomERC20;

    constructor(
        // tokens
        address _dai,
        address _cash,
        address _bond,
        address _share,
        // oracles
        address _bondOracle,
        address _arthMahaOracle,
        address _seigniorageOracle,
        address _gmuOracle,
        // others
        address _uniswapRouter,
        uint256 _startTime,
        uint256 _period,
        uint256 _startEpoch
    )
        public
        TreasuryHelpers(
            _dai,
            _cash,
            _bond,
            _share,
            _bondOracle,
            _arthMahaOracle,
            _seigniorageOracle,
            _gmuOracle,
            _uniswapRouter,
            _startTime,
            _period,
            _startEpoch
        )
    {}

    function initialize() public checkOperator {
        require(!initialized, '!initialized');

        // set accumulatedSeigniorage to the treasury's balance
        accumulatedSeigniorage = IERC20(cash).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function buyBonds(uint256 amountInDai, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
        updatePrice
        returns (uint256)
    {
        require(amountInDai > 0, 'zero amount');

        // Update the price to latest before using.
        uint256 cash1hPrice = getBondOraclePrice();

        require(cash1hPrice <= targetPrice, 'cash price moved');
        require(
            cash1hPrice <= getBondPurchasePrice(), // price < $0.95
            'cash price not eligible'
        );
        require(cashToBondConversionLimit > 0, 'no more bonds');

        // Find the expected amount recieved when swapping the following
        // tokens on uniswap.
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(cash);

        uint256[] memory amountsOut =
            IUniswapV2Router02(uniswapRouter).getAmountsOut(amountInDai, path);
        uint256 expectedCashAmount = amountsOut[1];

        // 1. Take Dai from the user
        ICustomERC20(dai).safeTransferFrom(
            msg.sender,
            address(this),
            amountInDai
        );

        // 2. Approve dai for trade on uniswap
        ICustomERC20(dai).safeApprove(uniswapRouter, amountInDai);

        // 3. Swap dai for ARTH from uniswap and send the ARTH to the sender
        // we send the ARTH back to the sender just in case there is some slippage
        // in our calculations and we end up with more ARTH than what is needed.
        uint256[] memory output =
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                amountInDai,
                expectedCashAmount,
                path,
                msg.sender,
                block.timestamp
            );

        // set approve to 0 after transfer
        ICustomERC20(dai).safeApprove(uniswapRouter, 0);

        // we do this to understand how much ARTH was bought back as without this, we
        // could witness a flash loan attack. (given that the minted amount of ARTHB
        // minted is based how much ARTH was received)
        uint256 boughtBackCash = Math.min(output[1], expectedCashAmount);

        // basis the amount of ARTH being bought back; understand how much of it
        // can we convert to bond tokens by looking at the conversion limits
        uint256 cashToConvert =
            Math.min(
                boughtBackCash,
                cashToBondConversionLimit.sub(accumulatedBonds)
            );

        // if all good then mint ARTHB, burn ARTH and update the counters
        require(cashToConvert > 0, 'no more bond limit');

        uint256 bondsToIssue =
            cashToConvert.mul(uint256(100).add(bondDiscount)).div(100);
        accumulatedBonds = accumulatedBonds.add(bondsToIssue);

        // 3. Burn bought ARTH cash and mint bonds at the discounted price.
        // TODO: Set the minting amount according to bond price.
        // TODO: calculate premium basis size of the trade
        IBasisAsset(cash).burnFrom(msg.sender, cashToConvert);
        IBasisAsset(bond).mint(msg.sender, bondsToIssue);

        emit BoughtBonds(msg.sender, amountInDai, cashToConvert, bondsToIssue);

        return bondsToIssue;
    }

    /**
     * Redeeming bonds happen when
     */
    function redeemBonds(uint256 amount)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
        updatePrice
    {
        require(amount > 0, 'zero amount');

        uint256 cashPrice = _getCashPrice(bondOracle);
        require(
            cashPrice > getBondRedemtionPrice(), // price > $1.00
            'cashPrice less than ceiling'
        );

        require(
            ICustomERC20(cash).balanceOf(address(this)) >= amount,
            'treasury has not enough budget'
        );

        amount = Math.min(accumulatedSeigniorage, amount);

        // charge stabilty fees in MAHA
        if (stabilityFee > 0) {
            uint256 stabilityFeeInARTH = amount.mul(stabilityFee).div(100);
            uint256 stabilityFeeInMAHA =
                getArthMahaOraclePrice().mul(stabilityFeeInARTH).div(1e18);

            // charge the stability fee
            ICustomERC20(share).burnFrom(msg.sender, stabilityFeeInMAHA);

            emit StabilityFeesCharged(msg.sender, stabilityFeeInMAHA);
        }

        // hand over the ARTH directly
        accumulatedSeigniorage = accumulatedSeigniorage.sub(amount);
        IBasisAsset(bond).burnFrom(msg.sender, amount);
        ICustomERC20(cash).safeTransfer(msg.sender, amount);

        emit RedeemedBonds(msg.sender, amount);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkEpoch
        checkOperator
    {
        emit AdvanceEpoch(msg.sender);

        _updateCashPrice();
        uint256 cash12hPrice = getSeigniorageOraclePrice();

        // send 300 ARTH reward to the person advancing the epoch to compensate for gas
        IBasisAsset(cash).mint(msg.sender, uint256(300).mul(1e18));

        // update the bond limits
        _updateConversionLimit(cash12hPrice);

        if (cash12hPrice <= cashTargetPrice) {
            return; // just advance epoch instead revert
        }

        if (cash12hPrice <= getExpansionLimitPrice()) {
            // if we are below the ceiling price (or expansion limit price) but
            // above the target price, then we try to pay off all the bond holders
            // as much as possible.

            // calculate how much seigniorage should be minted basis deviation from target price
            uint256 seigniorage = estimateSeignorageToMint(cash12hPrice);

            // if we don't have to pay bond holders anything then simply return.
            if (seigniorage == 0) return;

            // we have to pay them some amount; so mint, distribute and return
            IBasisAsset(cash).mint(address(this), seigniorage);
            emit SeigniorageMinted(seigniorage);

            if (enableSurprise) {
                // surprise!! send 10% to boardooms and 90% to bond holders
                _allocateToBondHolders(seigniorage.mul(90).div(100));
                _allocateToBoardrooms(seigniorage.mul(10).div(100));
            } else {
                _allocateToBondHolders(seigniorage);
            }

            return;
        }

        uint256 seigniorage = estimateSeignorageToMint(cash12hPrice);
        if (seigniorage == 0) return;

        IBasisAsset(cash).mint(address(this), seigniorage);
        emit SeigniorageMinted(seigniorage);

        // send funds to the ecosystem development and raindy fund
        uint256 ecosystemReserve =
            _allocateToFund(
                ecosystemFund,
                ecosystemFundAllocationRate,
                seigniorage
            );

        uint256 raindayReserve =
            _allocateToFund(
                rainyDayFund,
                rainyDayFundAllocationRate,
                seigniorage
            );

        seigniorage = seigniorage.sub(ecosystemReserve).sub(raindayReserve);

        // keep 90% of the funds to bond token holders; and send the remaining to the boardroom
        uint256 allocatedForBondHolders =
            seigniorage.mul(bondSeigniorageRate).div(100);
        uint256 treasuryReserve =
            _allocateToBondHolders(allocatedForBondHolders);
        seigniorage = seigniorage.sub(treasuryReserve);

        // allocate everything else to the boardroom
        _allocateToBoardrooms(seigniorage);
    }

    event AdvanceEpoch(address indexed from);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: MIT

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
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

interface ICustomERC20 is IERC20 {
    using SafeERC20 for IERC20;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IUniswapOracle {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBoardroom {
    function allocateSeigniorage(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ISimpleERCFund {
    function deposit(
        address token,
        uint256 amount,
        string memory reason
    ) external;

    function withdraw(
        address token,
        uint256 amount,
        address to,
        string memory reason
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() internal {
        _operator = _msgSender();

        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            'operator: zero address given for new operator'
        );

        emit OperatorTransferred(address(0), newOperator_);

        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../owner/Operator.sol';

contract Epoch is Operator {
    using SafeMath for uint256;

    uint256 public period = 1;
    uint256 public startTime;
    uint256 public lastExecutedAt;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        uint256 _period,
        uint256 _startTime,
        uint256 _startEpoch
    ) public {
        // require(_startTime > block.timestamp, 'Epoch: invalid start time');
        period = _period;
        startTime = _startTime;
        lastExecutedAt = startTime.add(_startEpoch.mul(period));
    }

    /* ========== Modifier ========== */

    modifier checkStartTime {
        require(now >= startTime, 'Epoch: not started yet');

        _;
    }

    modifier checkEpoch {
        require(now > startTime, 'Epoch: not started yet');
        require(callable(), 'Epoch: not allowed');

        _;

        lastExecutedAt = block.timestamp;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function callable() public view returns (bool) {
        return getCurrentEpoch() >= getNextEpoch();
    }

    // epoch
    function getLastEpoch() public view returns (uint256) {
        return lastExecutedAt.sub(startTime).div(period);
    }

    function getCurrentEpoch() public view returns (uint256) {
        return Math.max(startTime, block.timestamp).sub(startTime).div(period);
    }

    function getNextEpoch() public view returns (uint256) {
        if (startTime == lastExecutedAt) {
            return getLastEpoch();
        }
        return getLastEpoch().add(1);
    }

    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(getNextEpoch().mul(period));
    }

    // params
    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    /* ========== GOVERNANCE ========== */

    function setPeriod(uint256 _period) external onlyOperator {
        period = _period;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            'ContractGuard: one block, one function'
        );
        require(
            !checkSameSenderReentranted(),
            'ContractGuard: one block, one function'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import {Math} from '@openzeppelin/contracts/math/Math.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ICustomERC20} from '../interfaces/ICustomERC20.sol';
import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';
import {IBoardroom} from '../interfaces/IBoardroom.sol';
import {ISimpleERCFund} from '../interfaces/ISimpleERCFund.sol';
import {Operator} from '../owner/Operator.sol';
import {Epoch} from '../utils/Epoch.sol';
import {TreasurySetters} from './TreasurySetters.sol';

/**
 * @title ARTH Treasury contract
 * @notice Monetary policy logic to adjust supplies of basis cash assets
 * @author Steven Enamakel & Yash Agrawal. Original code written by Summer Smith & Rick Sanchez
 */
contract TreasuryHelpers is TreasurySetters {
    using SafeERC20 for ICustomERC20;

    constructor(
        address _dai,
        address _cash,
        address _bond,
        address _share,
        address _bondOracle,
        address _arthMahaOracle,
        address _seigniorageOracle,
        address _gmuOracle,
        // address _arthUniLiquidityBoardroom,
        // address _arthMlpLiquidityBoardroom,
        // address _mahaLiquidityBoardroom,
        // address _arthBoardroom,
        // address _fund,
        // address _rainyDayFund,
        address _uniswapRouter,
        uint256 _startTime,
        uint256 _period,
        uint256 _startEpoch
    ) public Epoch(_period, _startTime, _startEpoch) {
        // tokens
        dai = _dai;
        cash = _cash;
        bond = _bond;
        share = _share;

        // oracles
        bondOracle = _bondOracle;
        arthMahaOracle = _arthMahaOracle;
        seigniorageOracle = _seigniorageOracle;
        gmuOracle = _gmuOracle;

        // funds
        // arthLiquidityUniBoardroom = _arthUniLiquidityBoardroom;
        // arthLiquidityMlpBoardroom = _arthMlpLiquidityBoardroom;
        // arthBoardroom = _arthBoardroom;
        // ecosystemFund = _fund;
        // rainyDayFund = _rainyDayFund;

        // others
        uniswapRouter = _uniswapRouter;

        // _updateCashPrice();
    }

    modifier updatePrice {
        _;

        _updateCashPrice();
    }

    function setBoardrooms(
        address _arthUniLiquidityBoardroom,
        address _arthMlpLiquidityBoardroom,
        address _mahaLiquidityBoardroom,
        address _arthBoardroom,
        address _fund
    ) public onlyOwner {
        // funds
        arthLiquidityUniBoardroom = _arthUniLiquidityBoardroom;
        arthLiquidityMlpBoardroom = _arthMlpLiquidityBoardroom;
        mahaLiquidityBoardroom = _mahaLiquidityBoardroom;
        arthBoardroom = _arthBoardroom;
        ecosystemFund = _fund;
    }

    function migrate(address target) public onlyOperator {
        require(target != address(0), 'migrate to zero');
        require(!migrated, '!migrated');

        // TODO: check if the destination is a treasury or not

        // cash
        if (Operator(cash).owner() == address(this)) {
            Operator(cash).transferOperator(target);
            Operator(cash).transferOwnership(target);
            ICustomERC20(cash).transfer(
                target,
                ICustomERC20(cash).balanceOf(address(this))
            );
        }

        // bond
        if (Operator(bond).owner() == address(this)) {
            Operator(bond).transferOperator(target);
            Operator(bond).transferOwnership(target);
            ICustomERC20(bond).transfer(
                target,
                ICustomERC20(bond).balanceOf(address(this))
            );
        }

        // share - disabled ownership and operator functions as MAHA tokens don't have these
        ICustomERC20(share).transfer(
            target,
            ICustomERC20(share).balanceOf(address(this))
        );

        migrated = true;
        emit Migration(target);
    }

    function initializeFunds(
        // boardrooms
        address _arthUniLiquidityBoardroom,
        address _arthMlpLiquidityBoardroom,
        address _mahaLiquidityBoardroom,
        address _arthBoardroom,
        // ecosystem fund
        address _fund,
        address _rainyDayFund
    ) public onlyOwner {
        setAllFunds(
            // boardrooms
            _arthUniLiquidityBoardroom,
            _arthMlpLiquidityBoardroom,
            _mahaLiquidityBoardroom,
            _arthBoardroom,
            // ecosystem fund
            _fund,
            _rainyDayFund
        );
    }

    function _allocateToFund(
        address fund,
        uint256 rate,
        uint256 seigniorage
    ) internal returns (uint256) {
        uint256 allocation = seigniorage.mul(rate).div(100);
        if (allocation > 0) {
            ICustomERC20(cash).safeApprove(fund, allocation);
            ISimpleERCFund(fund).deposit(
                cash,
                allocation,
                'Treasury: Fund Seigniorage Allocation'
            );
            emit PoolFunded(fund, allocation);
            return allocation;
        }

        return 0;
    }

    /**
     * Updates the cash price from the various oracles.
     * TODO: this function needs to be optimised for gas
     */
    function _updateCashPrice() internal {
        if (Epoch(bondOracle).callable()) {
            try IUniswapOracle(bondOracle).update() {} catch {}
        }

        if (Epoch(seigniorageOracle).callable()) {
            try IUniswapOracle(seigniorageOracle).update() {} catch {}
        }

        // TODO: do the same for the gmu oracle as well
        // if (Epoch(seigniorageOracle).callable()) {
        //     try IOracle(seigniorageOracle).update() {} catch {}
        // }

        cashTargetPrice = getGMUOraclePrice();
    }

    /**
     * Helper function to allocate seigniorage to bond token holders. Seigniorage
     * before the boardrooms get paid.
     */
    function _allocateToBondHolders(uint256 seigniorage)
        internal
        returns (uint256)
    {
        uint256 treasuryReserve =
            Math.min(
                seigniorage,
                ICustomERC20(bond).totalSupply().sub(accumulatedSeigniorage)
            );

        if (treasuryReserve > 0) {
            // update accumulated seigniorage
            accumulatedSeigniorage = accumulatedSeigniorage.add(
                treasuryReserve
            );
            emit TreasuryFunded(now, treasuryReserve);
            return treasuryReserve;
        }

        return 0;
    }

    /**
     * Helper function to allocate seigniorage to boardooms. Seigniorage is allocated
     * after bond token holders have been paid first.
     */
    function _allocateToBoardroom(
        address boardroom,
        uint256 rate,
        uint256 seigniorage
    ) internal {
        if (seigniorage == 0) return;

        // Calculate boardroom reserves.
        uint256 reserve = seigniorage.mul(rate).div(100);

        // arth-dai uniswap lp
        if (reserve > 0) {
            ICustomERC20(cash).safeApprove(boardroom, reserve);
            IBoardroom(boardroom).allocateSeigniorage(reserve);
            emit PoolFunded(boardroom, reserve);
        }
    }

    function _allocateToBoardrooms(uint256 boardroomReserve) internal {
        if (boardroomReserve <= 0) return;

        _allocateToBoardroom(
            arthLiquidityUniBoardroom,
            arthLiquidityUniAllocationRate,
            boardroomReserve
        );

        _allocateToBoardroom(
            arthLiquidityMlpBoardroom,
            arthLiquidityMlpAllocationRate,
            boardroomReserve
        );

        _allocateToBoardroom(
            arthBoardroom,
            arthBoardroomAllocationRate,
            boardroomReserve
        );

        _allocateToBoardroom(
            mahaLiquidityBoardroom,
            mahaLiquidityBoardroomAllocationRate,
            boardroomReserve
        );
    }

    /**
     * This function calculates how much bonds should be minted given an epoch
     * https://github.com/Basis-Cash/basiscash-protocol/issues/27
     *
     * The cap will be of the following size: ($1-1hTWAP)*(Circ $BAC),
     * where 1hTWAP is the 1h TWAP of the $ARTH price and “Circ $ARTH is
     * the Circulating $ARTH supply. The cap will last for one hour; after
     * an hour a new TWAP will be calculated and the cap is reset based on
     * next 12h epoch.
     */
    function _updateConversionLimit(uint256 cash1hPrice) internal {
        // reset this counter so that new bonds can now be minted.
        accumulatedBonds = 0;
        cashToBondConversionLimit = estimateBondsToIssue(cash1hPrice);
    }

    // GOV
    event Initialized(address indexed executor, uint256 at);
    event Migration(address indexed target);
    event RedeemedBonds(address indexed from, uint256 amount);
    event BoughtBonds(
        address indexed from,
        uint256 amountDaiIn,
        uint256 amountBurnt,
        uint256 bondsIssued
    );
    event Log(uint256 data);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event SeigniorageMinted(uint256 seigniorage);
    event BondsAllocated(uint256 limit);
    event PoolFunded(address indexed pool, uint256 seigniorage);
    event StabilityFeesCharged(address indexed from, uint256 stabilityFeeValue);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';

import '../interfaces/IBoardroom.sol';
import '../interfaces/IBasisAsset.sol';
import '../interfaces/ISimpleERCFund.sol';
import './TreasuryGetters.sol';

abstract contract TreasurySetters is TreasuryGetters {
    function setAllFunds(
        // boardrooms
        address _arthUniLiquidityBoardroom,
        address _arthMlpLiquidityBoardroom,
        address _mahaLiquidityBoardroom,
        address _arthBoardroom,
        // ecosystem fund
        address _fund,
        address _rainyDayFund
    ) public onlyOwner {
        arthLiquidityUniBoardroom = _arthUniLiquidityBoardroom;
        arthLiquidityMlpBoardroom = _arthMlpLiquidityBoardroom;
        mahaLiquidityBoardroom = _mahaLiquidityBoardroom;
        arthBoardroom = _arthBoardroom;

        ecosystemFund = _fund;
        rainyDayFund = _rainyDayFund;
    }

    function setFund(address newFund, uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        ecosystemFund = newFund;
        ecosystemFundAllocationRate = rate;
    }

    function setBondDiscount(uint256 rate) public onlyOwner returns (uint256) {
        require(rate <= 100, 'rate >= 0');
        bondDiscount = rate;
    }

    function setConsiderUniswapLiquidity(bool val) public onlyOwner {
        considerUniswapLiquidity = val;
    }

    function setMaxDebtIncreasePerEpoch(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        maxDebtIncreasePerEpoch = rate;
    }

    function setMaxSupplyIncreasePerEpoch(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        maxSupplyIncreasePerEpoch = rate;
    }

    function setSurprise(bool val) public onlyOwner {
        enableSurprise = val;
    }

    function setSafetyRegion(uint256 rate) public onlyOwner returns (uint256) {
        require(rate <= 100, 'rate >= 0');
        safetyRegion = rate;
    }

    function setBondSeigniorageRate(uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        bondSeigniorageRate = rate;
    }

    function setArthBoardroom(address newFund, uint256 rate) public onlyOwner {
        require(rate <= 100, 'rate >= 0');
        arthBoardroom = newFund;
        arthBoardroomAllocationRate = rate;
    }

    function setArthLiquidityUniBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');
        arthLiquidityUniBoardroom = newFund;
        arthLiquidityUniAllocationRate = rate;
    }

    function setArthLiquidityMlpBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');
        arthLiquidityMlpBoardroom = newFund;
        arthLiquidityMlpAllocationRate = rate;
    }

    function setMahaLiquidityBoardroom(address newFund, uint256 rate)
        public
        onlyOwner
    {
        require(rate <= 100, 'rate >= 0');
        mahaLiquidityBoardroom = newFund;
        mahaLiquidityBoardroomAllocationRate = rate;
    }

    // ORACLE
    function setBondOracle(address newOracle) public onlyOwner {
        bondOracle = newOracle;
    }

    function setSeigniorageOracle(address newOracle) public onlyOwner {
        seigniorageOracle = newOracle;
    }

    function setUniswapRouter(address val) public onlyOwner {
        uniswapRouter = val;
    }

    function setGMUOracle(address newOracle) public onlyOwner {
        gmuOracle = newOracle;
    }

    function setArthMahaOracle(address newOracle) public onlyOwner {
        arthMahaOracle = newOracle;
    }

    function setStabilityFee(uint256 _stabilityFee) public onlyOwner {
        require(_stabilityFee <= 100, 'rate >= 0');
        stabilityFee = _stabilityFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Math} from '@openzeppelin/contracts/math/Math.sol';

import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {ISimpleOracle} from '../interfaces/ISimpleOracle.sol';
import {TreasuryState} from './TreasuryState.sol';
import {Epoch} from '../utils/Epoch.sol';
import {ICustomERC20} from '../interfaces/ICustomERC20.sol';
import {IUniswapV2Factory} from '../interfaces/IUniswapV2Factory.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';

abstract contract TreasuryGetters is TreasuryState {
    function getReserve() public view returns (uint256) {
        return accumulatedSeigniorage;
    }

    function getStabilityFee() public view returns (uint256) {
        return stabilityFee;
    }

    function getBondOraclePrice() public view returns (uint256) {
        return _getCashPrice(bondOracle);
    }

    function getGMUOraclePrice() public view returns (uint256) {
        return ISimpleOracle(gmuOracle).getPrice();
    }

    function getArthMahaOraclePrice() public view returns (uint256) {
        return ISimpleOracle(arthMahaOracle).getPrice();
    }

    function getPercentDeviationFromTarget(uint256 price)
        public
        view
        returns (uint256)
    {
        uint256 target = getGMUOraclePrice();

        if (price > target) return price.sub(target).mul(100).div(target);
        return target.sub(price).mul(100).div(target);
    }

    function getSeigniorageOraclePrice() public view returns (uint256) {
        return _getCashPrice(seigniorageOracle);
    }

    function arthCirculatingSupply() public view returns (uint256) {
        return IERC20(cash).totalSupply().sub(accumulatedSeigniorage);
    }

    function bondCirculatingSupply() public view returns (uint256) {
        return ICustomERC20(bond).totalSupply().sub(accumulatedSeigniorage);
    }

    /**
     * Understand how much Seignorage should be minted
     */
    function estimateSeignorageToMint(uint256 price)
        public
        view
        returns (uint256)
    {
        if (price <= cashTargetPrice) return 0; // < $1.00

        // cap the max supply increase per epoch to only 30%
        uint256 finalPercentage =
            Math.min(
                getPercentDeviationFromTarget(price),
                maxSupplyIncreasePerEpoch
            );

        // take into consideration uniswap liq. if flag is on, ie how much liquidity is there in the ARTH uniswap pool
        uint256 toMint = arthCirculatingSupply().mul(finalPercentage).div(100);

        // if we are below the expansion price limit; only pay back bond holders if we are within the right price range
        // < $1.05
        if (price <= getExpansionLimitPrice()) {
            return Math.min(toMint, bondCirculatingSupply());
        }

        return toMint;
    }

    function estimateBondsToIssue(uint256 price) public view returns (uint256) {
        // check if we are in contraction mode.
        if (price > getBondPurchasePrice()) return 0; // <= $0.95

        // in contraction mode -> issue bonds.
        // set a limit to how many bonds are there.

        uint256 percentage = getPercentDeviationFromTarget(price);

        // understand how much % deviation do we have from target price
        // if target price is 2.5$ and we are at 2$; then percentage should be 20%
        // cap the bonds to be issed; we don't want too many
        uint256 finalPercentage = Math.min(percentage, maxDebtIncreasePerEpoch);

        // accordingly set the new conversion limit to be that % from the
        // current circulating supply of ARTH and if uniswap enabled then uniswap liquidity.
        return
            arthCirculatingSupply()
                .mul(finalPercentage)
                .div(100)
                .mul(getCashSupplyInLiquidity())
                .div(100);
    }

    function getBondRedemtionPrice() public view returns (uint256) {
        return cashTargetPrice; // 1$
    }

    function getExpansionLimitPrice() public view returns (uint256) {
        return cashTargetPrice.mul(safetyRegion.add(100)).div(100); // 1.05$
    }

    function getBondPurchasePrice() public view returns (uint256) {
        return cashTargetPrice.mul(uint256(100).sub(safetyRegion)).div(100); // 0.95$
    }

    function getCashSupplyInLiquidity() public view returns (uint256) {
        // check if enabled or not
        if (!considerUniswapLiquidity) return uint256(100);

        address uniswapFactory = IUniswapV2Router02(uniswapRouter).factory();
        address uniswapLiquidityPair =
            IUniswapV2Factory(uniswapFactory).getPair(cash, dai);

        // Get the liquidity of cash locked in uniswap pair.
        uint256 uniswapLiquidityPairCashBalance =
            ICustomERC20(cash).balanceOf(uniswapLiquidityPair);

        // Get the liquidity percent.
        return
            uniswapLiquidityPairCashBalance.mul(100).div(
                ICustomERC20(cash).totalSupply()
            );
    }

    function get1hourEpoch() public view returns (uint256) {
        return Epoch(bondOracle).getLastEpoch();
    }

    function _getCashPrice(address oracle) internal view returns (uint256) {
        try IUniswapOracle(oracle).consult(cash, 1e18) returns (uint256 price) {
            return price;
        } catch {
            revert('Treasury: failed to consult cash price from the oracle');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ISimpleOracle {
    function getPrice() external view returns (uint256 amountOut);
    // function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

import {FixedPoint} from '../lib/FixedPoint.sol';
import {Safe112} from '../lib/Safe112.sol';
import {Operator} from '../owner/Operator.sol';
import {Epoch} from '../utils/Epoch.sol';
import {ContractGuard} from '../utils/ContractGuard.sol';

abstract contract TreasuryState is ContractGuard, Epoch {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using Safe112 for uint112;

    /* ========== STATE VARIABLES ========== */

    // ========== FLAGS
    bool public migrated = false;
    bool public initialized = false;

    // ========== CORE
    address public dai;
    address public cash;
    address public bond;
    address public share;
    address public uniswapRouter;

    address public arthLiquidityUniBoardroom;
    address public arthLiquidityMlpBoardroom;
    address public mahaLiquidityBoardroom;
    address public arthBoardroom;

    address public ecosystemFund;
    address public rainyDayFund;

    // oracles
    address public bondOracle;
    address public seigniorageOracle;
    address public gmuOracle;
    address public arthMahaOracle;

    // cash price tracking vars
    uint256 public cashTargetPrice = 1e18;

    // these govern how much bond tokens are issued
    uint256 public cashToBondConversionLimit = 0;
    uint256 public accumulatedBonds = 0;

    // this governs how much cash tokens are issued
    uint256 public accumulatedSeigniorage = 0;

    // flag whether we should considerUniswapLiquidity or not.
    bool public considerUniswapLiquidity = false;

    // used to limit how much of the supply is converted into bonds
    uint256 public maxDebtIncreasePerEpoch = 5; // in %

    // the discount given to bond purchasers
    uint256 public bondDiscount = 20; // in %

    // the band beyond which bond purchase or protocol expansion happens.
    uint256 public safetyRegion = 5; // in %
    // uint256 public bondPurchasePrice = 5; // in %

    // at the most how much % of the supply should be increased
    uint256 public maxSupplyIncreasePerEpoch = 10; // in %

    // the ecosystem fund recieves seigniorage before anybody else; this
    // value decides how much of the new seigniorage is sent to this fund.
    uint256 public ecosystemFundAllocationRate = 2; // in %
    uint256 public rainyDayFundAllocationRate = 2; // in %

    // this controls how much of the new seigniorage is given to bond token holders
    // when we are in expansion mode. ideally 90% of new seigniorate is
    // given to bond token holders.
    uint256 public bondSeigniorageRate = 90; // in %

    // we decide how much allocation to give to the boardrooms. there
    // are currently two boardrooms; one for ARTH holders and the other for
    // ARTH liqudity providers
    //
    // TODO: make one for maha holders and one for the various community pools
    uint256 public arthLiquidityUniAllocationRate = 5; // In %.
    uint256 public arthLiquidityMlpAllocationRate = 65; // In %.
    uint256 public arthBoardroomAllocationRate = 20; // IN %.
    uint256 public mahaLiquidityBoardroomAllocationRate = 10; // IN %.

    // stability fee is a special fee charged by the protocol in MAHA tokens
    // whenever a person is going to redeem his/her bonds. the fee is charged
    // basis how much ARTHB is being redeemed.
    //
    // eg: a 1% fee means that while redeeming 100 ARTHB, 1 ARTH worth of MAHA is
    // deducted to pay for stability fees.
    uint256 public stabilityFee = 1; // IN %;

    // wut? algo coin surprise sheeet?
    bool public enableSurprise = false;

    modifier checkMigration {
        require(!migrated, 'Treasury: migrated');
        _;
    }

    modifier checkOperator {
        require(
            Operator(cash).operator() == address(this) &&
                Operator(bond).operator() == address(this) &&
                Operator(arthLiquidityMlpBoardroom).operator() ==
                address(this) &&
                Operator(arthLiquidityUniBoardroom).operator() ==
                address(this) &&
                Operator(arthBoardroom).operator() == address(this) &&
                Operator(mahaLiquidityBoardroom).operator() == address(this),
            'Treasury: need more permission'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './Babylonian.sol';

// A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format)).
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            'FixedPoint: MULTIPLICATION_OVERFLOW'
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library Safe112 {
    function add(uint112 a, uint112 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'Safe112: addition overflow');

        return c;
    }

    function sub(uint112 a, uint112 b) internal pure returns (uint256) {
        return sub(a, b, 'Safe112: subtraction overflow');
    }

    function sub(
        uint112 a,
        uint112 b,
        string memory errorMessage
    ) internal pure returns (uint112) {
        require(b <= a, errorMessage);
        uint112 c = a - b;

        return c;
    }

    function mul(uint112 a, uint112 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'Safe112: multiplication overflow');

        return c;
    }

    function div(uint112 a, uint112 b) internal pure returns (uint256) {
        return div(a, b, 'Safe112: division by zero');
    }

    function div(
        uint112 a,
        uint112 b,
        string memory errorMessage
    ) internal pure returns (uint112) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint112 c = a / b;

        return c;
    }

    function mod(uint112 a, uint112 b) internal pure returns (uint256) {
        return mod(a, b, 'Safe112: modulo by zero');
    }

    function mod(
        uint112 a,
        uint112 b,
        string memory errorMessage
    ) internal pure returns (uint112) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}