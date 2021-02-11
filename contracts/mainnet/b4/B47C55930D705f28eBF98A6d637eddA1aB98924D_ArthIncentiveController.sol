// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import {Math} from '../libraries/Math.sol';
import {Setters} from './Setters.sol';
import {IIncentiveController} from '../interfaces/IIncentiveController.sol';
import {IMahaswapV1Pair} from '../interfaces/IMahaswapV1Pair.sol';
import {Epoch} from '../Epoch.sol';
import {IBurnableERC20} from '../interfaces/IBurnableERC20.sol';

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract ArthIncentiveController is IIncentiveController, Setters, Epoch {
    /**
     * Constructor.
     */
    constructor(
        address _pairAddress,
        address _protocolTokenAddress,
        address _incentiveToken,
        uint256 _rewardPerEpoch,
        uint256 _arthToMahaRate
    )
        public
        Epoch(
            12 * 60 * 60, /* 12 hour epochs */
            block.timestamp,
            0
        )
    {
        pairAddress = _pairAddress;
        protocolTokenAddress = _protocolTokenAddress;
        incentiveToken = IBurnableERC20(_incentiveToken);
        isTokenAProtocolToken = IMahaswapV1Pair(_pairAddress).token0() == _protocolTokenAddress;
        rewardPerEpoch = _rewardPerEpoch;
        arthToMahaRate = _arthToMahaRate;

        // start expecting $1mn in volume
        expectedVolumePerEpoch = 1000000 * 1e18;
        currentVolumPerEpoch = expectedVolumePerEpoch;
        availableRewardThisEpoch = rewardPerEpoch;
    }

    function estimatePenaltyToCharge(
        uint256 price,
        uint256 liquidity,
        uint256 sellVolume
    ) public view returns (uint256) {
        uint256 targetPrice = getPenaltyPrice();

        // % of pool = sellVolume / liquidity
        // % of deviation from target price = (tgt_price - price) / price
        // amountToburn = sellVolume * % of deviation from target price * % of pool * 100
        if (price >= targetPrice) return 0;

        uint256 percentOfPool = sellVolume.mul(10000).div(liquidity);
        uint256 deviationFromTarget = targetPrice.sub(price).mul(10000).div(targetPrice);
        uint256 feeToCharge = Math.max(percentOfPool, deviationFromTarget); // a number from 0-100%

        // NOTE: Shouldn't this be multiplied by 10000 instead of 100
        // NOTE: multiplication by 100, is removed in the mock controller
        return sellVolume.mul(feeToCharge).div(10000).mul(arthToMahaRate).div(1e18);
    }

    function estimateRewardToGive(uint256 buyVolume) public view returns (uint256) {
        return
            Math.min(
                buyVolume.mul(rewardPerEpoch).div(expectedVolumePerEpoch),
                Math.min(availableRewardThisEpoch, incentiveToken.balanceOf(address(this)))
            );
    }

    function _penalizeTrade(
        uint256 price,
        uint256 sellVolume,
        uint256 liquidity,
        address to
    ) private {
        uint256 amountToBurn = estimatePenaltyToCharge(price, liquidity, sellVolume);

        if (amountToBurn > 0) {
            // NOTE: amount has to be approved from frontend.
            // Burn and charge penalty.
            incentiveToken.burnFrom(to, amountToBurn);
        }
    }

    function _incentiviseTrade(uint256 buyVolume, address to) private {
        // Calculate the amount as per volumne and rate.
        uint256 amountToReward = estimateRewardToGive(buyVolume);

        if (amountToReward > 0) {
            availableRewardThisEpoch = availableRewardThisEpoch.sub(amountToReward);

            // Send reward to the appropriate address.
            incentiveToken.transfer(to, amountToReward);
        }
    }

    /**
     * This is the function that burns the MAHA and returns how much ARTH should
     * actually be spent.
     *
     * Note we are always selling tokenA.
     */
    function conductChecks(
        uint112 reserveA,
        uint112 reserveB,
        uint256 priceALast,
        uint256 priceBLast,
        uint256 amountOutA,
        uint256 amountOutB,
        uint256 amountInA,
        uint256 amountInB,
        address from,
        address to
    ) external onlyPair {
        if (isTokenAProtocolToken) {
            // then A is ARTH
            uint256 price = uint256(reserveB).mul(1e18).div(uint256(reserveA));
            _conductChecks(reserveA, price, amountOutA, amountInA, to);
        } else {
            // then B is ARTH
            uint256 price = uint256(reserveA).mul(1e18).div(uint256(reserveB));
            _conductChecks(reserveB, price, amountOutB, amountInB, to);
        }
    }

    function _conductChecks(
        uint112 reserveA, // ARTH liquidity
        uint256 priceA, // ARTH price
        uint256 amountOutA, // ARTH being bought
        uint256 amountInA, // ARTH being sold
        address to
    ) private {
        // capture volume and snapshot it every epoch.
        if (getCurrentEpoch() >= getNextEpoch()) _updateForEpoch();
        currentVolumPerEpoch = currentVolumPerEpoch.add(amountOutA).add(amountInA);

        // Check if we are selling and if we are blow the target price?
        if (amountInA > 0) {
            // Check if we are below the targetPrice.
            uint256 penaltyTargetPrice = getPenaltyPrice();

            if (priceA < penaltyTargetPrice) {
                // is the user expecting some DAI? if so then this is a sell order
                // Calculate the amount of tokens sent.
                _penalizeTrade(priceA, amountInA, reserveA, to);

                // stop here to save gas
                return;
            }
        }

        // Check if we are buying and below the target price
        if (amountOutA > 0 && priceA < getRewardIncentivePrice() && availableRewardThisEpoch > 0) {
            // is the user expecting some ARTH? if so then this is a sell order
            // If we are buying the main protocol token, then we incentivize the tx sender.
            _incentiviseTrade(amountOutA, to);
        }
    }

    function _updateForEpoch() private {
        expectedVolumePerEpoch = Math.max(currentVolumPerEpoch, 1);
        availableRewardThisEpoch = rewardPerEpoch;
        currentVolumPerEpoch = 0;

        lastExecutedAt = block.timestamp;
    }

    function refundIncentiveToken() external onlyOwner {
        incentiveToken.transfer(msg.sender, incentiveToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

/**
 * A library for performing various math operations
 */
library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import {Getters} from './Getters.sol';
import {IBurnableERC20} from '../interfaces/IBurnableERC20.sol';

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract Setters is Getters {
    /**
     * Setters.
     */
    function setArthToMahaRate(uint256 val) external onlyOwner {
        arthToMahaRate = val;
    }

    function setIncentiveToken(address newToken) public onlyOwner {
        require(newToken != address(0), 'Pair: invalid token');
        incentiveToken = IBurnableERC20(newToken);
    }

    function setPenaltyPrice(uint256 val) public onlyOwner {
        penaltyPrice = val;
    }

    function setRewardPrice(uint256 val) public onlyOwner {
        rewardPrice = val;
    }

    function setTokenAProtocolToken(bool val) public onlyOwner {
        isTokenAProtocolToken = val;
    }

    function setExpectedVolumePerEpoch(uint256 val) public onlyOwner {
        expectedVolumePerEpoch = val;
    }

    function setAvailableRewardThisEpoch(uint256 val) public onlyOwner {
        availableRewardThisEpoch = val;
    }

    function setMahaPerEpoch(uint256 val) public onlyOwner {
        rewardPerEpoch = val;
    }

    function setUseOracle(bool val) public onlyOwner {
        useOracle = val;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IIncentiveController {
    function conductChecks(
        uint112 reserveA,
        uint112 reserveB,
        uint256 priceALast,
        uint256 priceBLast,
        uint256 amountOutA,
        uint256 amountOutB,
        uint256 amountInA,
        uint256 amountInB,
        address from,
        address to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IMahaswapV1Pair {
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function setSwapingPaused(bool isSet) external;

    function setIncentiveController(address controller) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import './libraries/SafeMath.sol';
import './libraries/Math.sol';
import './libraries/Ownable.sol';

contract Epoch is Ownable {
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

    /* ========== VIEW FUNCTIONS ========== */

    function canUpdate() public view returns (bool) {
        return getCurrentEpoch() >= getNextEpoch();
    }

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

    function getPeriod() public view returns (uint256) {
        return period;
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function setPeriod(uint256 _period) external onlyOwner {
        period = _period;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import './IERC20.sol';

interface IBurnableERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import {State} from './State.sol';

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract Getters is State {
    /**
     * Getters.
     */
    function _getOraclePrice() private view returns (uint256) {
        // try {
        //     return uniswapOracle.consult(protocolTokenAddress, 1e18);
        // } catch {
        //     revert('Controller: failed to consult cash price from the oracle');
        // }
    }

    // Given an output amount of an asset and pair reserves,
    // Returns a required input amount of the other asset.
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) private pure returns (uint256 amountIn) {
        require(amountOut > 0, 'Controller: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'Controller: INSUFFICIENT_LIQUIDITY');

        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);

        amountIn = (numerator / denominator).add(1);
    }

    function getPenaltyPrice() public view returns (uint256) {
        // If (useOracle) then get penalty price from an oracle
        // else get from a variable.
        // This variable is settable from the factory.
        if (!useOracle) return penaltyPrice;
        return _getOraclePrice();
    }

    function getRewardIncentivePrice() public view returns (uint256) {
        // If (useOracle) then get reward price from an oracle
        // else get from a variable.
        // This variable is settable from the factory.
        if (!useOracle) return rewardPrice;
        return _getOraclePrice();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import {SafeMath} from '../libraries/SafeMath.sol';
import {UQ112x112} from '../libraries/UQ112x112.sol';
import {IBurnableERC20} from '../interfaces/IBurnableERC20.sol';
import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {Ownable} from '../libraries/Ownable.sol';

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract State is Ownable {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    // Token which will be used to charge penalty or reward incentives.
    IBurnableERC20 public incentiveToken;

    // Pair that will be using this contract.
    address public pairAddress;

    // Token which is the main token of a protocol.
    address public protocolTokenAddress;

    // Used to track the latest twap price.
    IUniswapOracle public uniswapOracle;

    // Default price of when reward is to be given.
    uint256 public rewardPrice = uint256(100).mul(1e16); // ~1.2$
    // Default price of when penalty is to be charged.
    uint256 public penaltyPrice = uint256(100).mul(1e16); // ~0.95$

    // Should we use oracle to get diff. price feeds or not.
    bool public useOracle = false;

    bool public isTokenAProtocolToken = true;

    // Max. reward per hour to be given out.
    uint256 public rewardPerEpoch = 0;

    uint256 public availableRewardThisEpoch = 0;
    uint256 public expectedVolumePerEpoch = 1;
    uint256 public currentVolumPerEpoch = 0;

    uint256 public arthToMahaRate;

    /**
     * Modifier.
     */
    modifier onlyPair {
        require(msg.sender == pairAddress, 'Controller: Forbidden');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

/**
 * A library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

/**
 * A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
 * range: [0, 2**112 - 1]
 * resolution: 1 / 2**112
 */
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // Encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // Multiply a UQ112x112 by a uint112, returning a UQ112x112
    function uqmul(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x * uint224(y);
    }

    // Divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapOracle {
    function update() external;

    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(owner() == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}