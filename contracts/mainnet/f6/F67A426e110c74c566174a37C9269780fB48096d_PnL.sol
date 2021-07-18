/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

// SPDX-License-Identifier: AGPLv3
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

pragma solidity >=0.6.0 <0.7.0;

interface IPnL {
    function calcPnL() external view returns (uint256, uint256);

    function increaseGTokenLastAmount(bool pwrd, uint256 dollarAmount) external;

    function decreaseGTokenLastAmount(
        bool pwrd,
        uint256 dollarAmount,
        uint256 bonus
    ) external;

    function lastGvtAssets() external view returns (uint256);

    function lastPwrdAssets() external view returns (uint256);

    function utilisationRatio() external view returns (uint256);

    function emergencyPnL() external;

    function recover() external;

    function distributeStrategyGainLoss(
        uint256 gain,
        uint256 loss,
        address reward
    ) external;

    function distributePriceChange(uint256 currentTotalAssets) external;
}

pragma solidity >=0.6.0 <0.8.0;

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
        this; 
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
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

pragma solidity >=0.6.0 <0.7.0;

interface IController {
    function stablecoins() external view returns (address[3] memory);

    function vaults() external view returns (address[3] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function reward() external view returns (address);

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function emergencyHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external;

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external;

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external;

    function getUserAssets(bool pwrd, address account) external view returns (uint256 deductUsd);

    function referrals(address account) external view returns (address);

    function addReferral(address account, address referral) external;

    function getStrategiesTargetRatio() external view returns (uint256[] memory);

    function withdrawalFee(bool pwrd) external view returns (uint256);

    function validGTokenDecrease(uint256 amount) external view returns (bool);
}

pragma solidity >=0.6.0 <0.7.0;

interface IPausable {
    function paused() external view returns (bool);
}

pragma solidity >=0.6.0 <0.7.0;

contract Controllable is Ownable {
    address public controller;

    event ChangeController(address indexed oldController, address indexed newController);

    modifier whenNotPaused() {
        require(!_pausable().paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_pausable().paused(), "Pausable: not paused");
        _;
    }

    function ctrlPaused() public view returns (bool) {
        return _pausable().paused();
    }

    function setController(address newController) external onlyOwner {
        require(newController != address(0), "setController: !0x");
        address oldController = controller;
        controller = newController;
        emit ChangeController(oldController, newController);
    }

    function _controller() internal view returns (IController) {
        require(controller != address(0), "Controller not set");
        return IController(controller);
    }

    function _pausable() internal view returns (IPausable) {
        require(controller != address(0), "Controller not set");
        return IPausable(controller);
    }
}

pragma solidity >=0.6.0 <0.7.0;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; 
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
}

pragma solidity >=0.6.0 <0.7.0;

interface IToken {
    function factor() external view returns (uint256);

    function factor(uint256 totalAssets) external view returns (uint256);

    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burnAll(address account) external;

    function totalAssets() external view returns (uint256);

    function getPricePerShare() external view returns (uint256);

    function getShareAssets(uint256 shares) external view returns (uint256);

    function getAssets(address account) external view returns (uint256);
}

pragma solidity >=0.6.0 <0.7.0;

interface IVault {
    function withdraw(uint256 amount) external;

    function withdraw(uint256 amount, address recipient) external;

    function withdrawByStrategyOrder(
        uint256 amount,
        address recipient,
        bool reversed
    ) external;

    function withdrawByStrategyIndex(
        uint256 amount,
        address recipient,
        uint256 strategyIndex
    ) external;

    function deposit(uint256 amount) external;

    function updateStrategyRatio(uint256[] calldata strategyRetios) external;

    function totalAssets() external view returns (uint256);

    function getStrategiesLength() external view returns (uint256);

    function strategyHarvestTrigger(uint256 index, uint256 callCost) external view returns (bool);

    function strategyHarvest(uint256 index) external returns (bool);

    function getStrategyAssets(uint256 index) external view returns (uint256);

    function token() external view returns (address);

    function vault() external view returns (address);

    function investTrigger() external view returns (bool);

    function invest() external;
}

pragma solidity >=0.6.0 <0.7.0;

contract FixedStablecoins is Constants {
    address public immutable DAI; 
    address public immutable USDC; 
    address public immutable USDT; 

    uint256 public immutable DAI_DECIMALS; 
    uint256 public immutable USDC_DECIMALS; 
    uint256 public immutable USDT_DECIMALS; 

    constructor(address[N_COINS] memory _tokens, uint256[N_COINS] memory _decimals) public {
        DAI = _tokens[0];
        USDC = _tokens[1];
        USDT = _tokens[2];
        DAI_DECIMALS = _decimals[0];
        USDC_DECIMALS = _decimals[1];
        USDT_DECIMALS = _decimals[2];
    }

    function underlyingTokens() internal view returns (address[N_COINS] memory tokens) {
        tokens[0] = DAI;
        tokens[1] = USDC;
        tokens[2] = USDT;
    }

    function getToken(uint256 index) internal view returns (address) {
        if (index == 0) {
            return DAI;
        } else if (index == 1) {
            return USDC;
        } else {
            return USDT;
        }
    }

    function decimals() internal view returns (uint256[N_COINS] memory _decimals) {
        _decimals[0] = DAI_DECIMALS;
        _decimals[1] = USDC_DECIMALS;
        _decimals[2] = USDT_DECIMALS;
    }

    function getDecimal(uint256 index) internal view returns (uint256) {
        if (index == 0) {
            return DAI_DECIMALS;
        } else if (index == 1) {
            return USDC_DECIMALS;
        } else {
            return USDT_DECIMALS;
        }
    }
}

contract FixedGTokens {
    IToken public immutable pwrd;
    IToken public immutable gvt;

    constructor(address _pwrd, address _gvt) public {
        pwrd = IToken(_pwrd);
        gvt = IToken(_gvt);
    }

    function gTokens(bool _pwrd) internal view returns (IToken) {
        if (_pwrd) {
            return pwrd;
        } else {
            return gvt;
        }
    }
}

contract FixedVaults is Constants {
    address public immutable DAI_VAULT;
    address public immutable USDC_VAULT;
    address public immutable USDT_VAULT;

    constructor(address[N_COINS] memory _vaults) public {
        DAI_VAULT = _vaults[0];
        USDC_VAULT = _vaults[1];
        USDT_VAULT = _vaults[2];
    }

    function getVault(uint256 index) internal view returns (address) {
        if (index == 0) {
            return DAI_VAULT;
        } else if (index == 1) {
            return USDC_VAULT;
        } else {
            return USDT_VAULT;
        }
    }

    function vaults() internal view returns (address[N_COINS] memory _vaults) {
        _vaults[0] = DAI_VAULT;
        _vaults[1] = USDC_VAULT;
        _vaults[2] = USDT_VAULT;
    }
}

pragma solidity >=0.6.0 <0.7.0;

contract PnL is Controllable, Constants, FixedGTokens, IPnL {
    using SafeMath for uint256;

    uint256 public override lastGvtAssets;
    uint256 public override lastPwrdAssets;
    bool public rebase = true;

    uint256 public performanceFee; 

    event LogRebaseSwitch(bool status);
    event LogNewPerfromanceFee(uint256 fee);
    event LogNewGtokenChange(bool pwrd, int256 change);
    event LogPnLExecution(
        uint256 deductedAssets,
        int256 totalPnL,
        int256 investPnL,
        int256 pricePnL,
        uint256 withdrawalBonus,
        uint256 performanceBonus,
        uint256 beforeGvtAssets,
        uint256 beforePwrdAssets,
        uint256 afterGvtAssets,
        uint256 afterPwrdAssets
    );

    constructor(
        address pwrd,
        address gvt,
        uint256 pwrdAssets,
        uint256 gvtAssets
    ) public FixedGTokens(pwrd, gvt) {
        lastPwrdAssets = pwrdAssets;
        lastGvtAssets = gvtAssets;
    }

    function setRebase(bool _rebase) external onlyOwner {
        rebase = _rebase;
        emit LogRebaseSwitch(_rebase);
    }

    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        performanceFee = _performanceFee;
        emit LogNewPerfromanceFee(_performanceFee);
    }

    function increaseGTokenLastAmount(bool pwrd, uint256 dollarAmount) external override {
        require(msg.sender == controller, "increaseGTokenLastAmount: !controller");
        if (!pwrd) {
            lastGvtAssets = lastGvtAssets.add(dollarAmount);
        } else {
            lastPwrdAssets = lastPwrdAssets.add(dollarAmount);
        }
        emit LogNewGtokenChange(pwrd, int256(dollarAmount));
    }

    function decreaseGTokenLastAmount(
        bool pwrd,
        uint256 dollarAmount,
        uint256 bonus
    ) external override {
        require(msg.sender == controller, "decreaseGTokenLastAmount: !controller");
        uint256 lastGA = lastGvtAssets;
        uint256 lastPA = lastPwrdAssets;
        if (!pwrd) {
            lastGA = dollarAmount > lastGA ? 0 : lastGA.sub(dollarAmount);
        } else {
            lastPA = dollarAmount > lastPA ? 0 : lastPA.sub(dollarAmount);
        }
        if (bonus > 0) {
            uint256 preGABeforeBonus = lastGA;
            uint256 prePABeforeBonus = lastPA;
            uint256 preTABeforeBonus = preGABeforeBonus.add(prePABeforeBonus);
            if (rebase) {
                lastGA = preGABeforeBonus.add(bonus.mul(preGABeforeBonus).div(preTABeforeBonus));
                lastPA = prePABeforeBonus.add(bonus.mul(prePABeforeBonus).div(preTABeforeBonus));
            } else {
                lastGA = preGABeforeBonus.add(bonus);
            }
            emit LogPnLExecution(0, int256(bonus), 0, 0, bonus, 0, preGABeforeBonus, prePABeforeBonus, lastGA, lastPA);
        }

        lastGvtAssets = lastGA;
        lastPwrdAssets = lastPA;
        emit LogNewGtokenChange(pwrd, -int256(dollarAmount));
    }

    function calcPnL() external view override returns (uint256, uint256) {
        return (lastGvtAssets, lastPwrdAssets);
    }

    function utilisationRatio() external view override returns (uint256) {
        return lastGvtAssets != 0 ? lastPwrdAssets.mul(PERCENTAGE_DECIMAL_FACTOR).div(lastGvtAssets) : 0;
    }

    function emergencyPnL() external override {
        require(msg.sender == controller, "emergencyPnL: !controller");
        forceDistribute();
    }

    function recover() external override {
        require(msg.sender == controller, "recover: !controller");
        forceDistribute();
    }

    function handleInvestGain(
        uint256 gvtAssets,
        uint256 pwrdAssets,
        uint256 profit,
        address reward
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 performanceBonus;
        if (performanceFee > 0 && reward != address(0)) {
            performanceBonus = profit.mul(performanceFee).div(PERCENTAGE_DECIMAL_FACTOR);
            profit = profit.sub(performanceBonus);
        }
        if (rebase) {
            uint256 totalAssets = gvtAssets.add(pwrdAssets);
            uint256 gvtProfit = profit.mul(gvtAssets).div(totalAssets);
            uint256 pwrdProfit = profit.mul(pwrdAssets).div(totalAssets);

            uint256 factor = pwrdAssets.mul(10000).div(gvtAssets);
            if (factor > 10000) factor = 10000;
            if (factor < 8000) {
                factor = factor.mul(3).div(8).add(3000);
            } else {
                factor = factor.sub(8000).mul(2).add(6000);
            }

            uint256 portionFromPwrdProfit = pwrdProfit.mul(factor).div(10000);
            gvtAssets = gvtAssets.add(gvtProfit.add(portionFromPwrdProfit));
            pwrdAssets = pwrdAssets.add(pwrdProfit.sub(portionFromPwrdProfit));
        } else {
            gvtAssets = gvtAssets.add(profit);
        }
        return (gvtAssets, pwrdAssets, performanceBonus);
    }

    function handleLoss(
        uint256 gvtAssets,
        uint256 pwrdAssets,
        uint256 loss
    ) private pure returns (uint256, uint256) {
        uint256 maxGvtLoss = gvtAssets.sub(DEFAULT_DECIMALS_FACTOR);
        if (loss > maxGvtLoss) {
            gvtAssets = DEFAULT_DECIMALS_FACTOR;
            pwrdAssets = pwrdAssets.sub(loss.sub(maxGvtLoss));
        } else {
            gvtAssets = gvtAssets - loss;
        }
        return (gvtAssets, pwrdAssets);
    }

    function forceDistribute() private {
        uint256 total = _controller().totalAssets();

        if (total > lastPwrdAssets.add(DEFAULT_DECIMALS_FACTOR)) {
            lastGvtAssets = total - lastPwrdAssets;
        } else {
            lastGvtAssets = DEFAULT_DECIMALS_FACTOR;
            lastPwrdAssets = total.sub(DEFAULT_DECIMALS_FACTOR);
        }
    }

    function distributeStrategyGainLoss(
        uint256 gain,
        uint256 loss,
        address reward
    ) external override {
        require(msg.sender == controller, "!Controller");
        uint256 lastGA = lastGvtAssets;
        uint256 lastPA = lastPwrdAssets;
        uint256 performanceBonus;
        uint256 gvtAssets;
        uint256 pwrdAssets;
        int256 investPnL;
        if (gain > 0) {
            (gvtAssets, pwrdAssets, performanceBonus) = handleInvestGain(lastGA, lastPA, gain, reward);
            if (performanceBonus > 0) {
                gvt.mint(reward, gvt.factor(gvtAssets), performanceBonus);
                gvtAssets = gvtAssets.add(performanceBonus);
            }

            lastGvtAssets = gvtAssets;
            lastPwrdAssets = pwrdAssets;
            investPnL = int256(gain);
        } else if (loss > 0) {
            (lastGvtAssets, lastPwrdAssets) = handleLoss(lastGA, lastPA, loss);
            investPnL = -int256(loss);
        }

        emit LogPnLExecution(
            0,
            investPnL,
            investPnL,
            0,
            0,
            performanceBonus,
            lastGA,
            lastPA,
            lastGvtAssets,
            lastPwrdAssets
        );
    }

    function distributePriceChange(uint256 currentTotalAssets) external override {
        require(msg.sender == controller, "!Controller");
        uint256 gvtAssets = lastGvtAssets;
        uint256 pwrdAssets = lastPwrdAssets;
        uint256 totalAssets = gvtAssets.add(pwrdAssets);

        if (currentTotalAssets > totalAssets) {
            lastGvtAssets = gvtAssets.add(currentTotalAssets.sub(totalAssets));
        } else if (currentTotalAssets < totalAssets) {
            (lastGvtAssets, lastPwrdAssets) = handleLoss(gvtAssets, pwrdAssets, totalAssets.sub(currentTotalAssets));
        }
        int256 priceChange = int256(currentTotalAssets) - int256(totalAssets);

        emit LogPnLExecution(
            0,
            priceChange,
            0,
            priceChange,
            0,
            0,
            gvtAssets,
            pwrdAssets,
            lastGvtAssets,
            lastPwrdAssets
        );
    }
}