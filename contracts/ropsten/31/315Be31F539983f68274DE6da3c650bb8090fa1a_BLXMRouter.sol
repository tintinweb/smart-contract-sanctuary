// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./BLXMRewardProvider.sol";
import "./interfaces/IBLXMRouter.sol";

import "./interfaces/IWETH.sol";

import "./libraries/TransferHelper.sol";
import "./libraries/BLXMLibrary.sol";


contract BLXMRouter is BLXMRewardProvider, IBLXMRouter {

    address public override WETH;


    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    receive() external payable {
        assert(_msgSender() == WETH); // only accept ETH via fallback from the WETH contract
    }

    function initialize(address _WETH, address _TREASURY_MANAGER) public initializer {
        WETH = _WETH;
        __BLXMRewardProvider_init(_TREASURY_MANAGER);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address treasury,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private view returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB) = BLXMLibrary.getReserves(treasury, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address treasury = BLXMLibrary.getTreasury(TREASURY_MANAGER, tokenA, tokenB);
        (amountA, amountB) = _addLiquidity(treasury, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(tokenA, _msgSender(), address(this), amountA);
        TransferHelper.safeTransferFrom(tokenB, _msgSender(), address(this), amountB);
        TransferHelper.safeTransfer(tokenA, treasury, amountA);
        TransferHelper.safeTransfer(tokenB, treasury, amountB);
        liquidity = _mint(to, tokenA, tokenB, amountA, amountB, lockedDays);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        address treasury = BLXMLibrary.getTreasury(TREASURY_MANAGER, token, WETH);
        (amountToken, amountETH) = _addLiquidity(treasury, token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        TransferHelper.safeTransferFrom(token, _msgSender(), address(this), amountToken);
        TransferHelper.safeTransfer(token, treasury, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(treasury, amountETH));
        liquidity = _mint(to, token, WETH, amountToken, amountETH, lockedDays);
        if (msg.value > amountETH) TransferHelper.safeTransferCurrency(_msgSender(), msg.value - amountETH); // refund dust, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint idx
    ) public override ensure(deadline) returns (uint amountA, uint amountB, uint rewards) {
        require(BLXMLibrary.getTreasury(TREASURY_MANAGER, tokenA, tokenB) != address(0), 'TREASURY_NOT_FOUND');
        uint amount0;
        uint amount1;
        (amount0, amount1, rewards) = _burn(to, liquidity, idx);
        (address token0,) = BLXMLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'INSUFFICIENT_B_AMOUNT');
    }
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint idx
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH, uint rewards) {
        (amountToken, amountETH, rewards) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline, idx);
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferCurrency(to, amountETH);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public pure override returns (uint amountB) {
        return BLXMLibrary.quote(amountA, reserveA, reserveB);
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./interfaces/IBLXMRewardProvider.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./libraries/SafeMath.sol";
import "./libraries/Math.sol";
import "./libraries/BLXMLibrary.sol";
import "./libraries/DateTime.sol";


contract BLXMRewardProvider is OwnableUpgradeable, ReentrancyGuardUpgradeable, IBLXMRewardProvider {

    using SafeMath for uint;

    struct Field {
        uint syncDay; // at most sync once a day
        uint8 period; // rewards supply once a month
        uint totalLiquidity; // exclude extra liquidity
        uint reserveA;
        uint reserveB;
    }

    struct Statistics {
        uint liquidityIn; // include extra liquidity
        uint liquidityOut;
        uint rewards;
        uint aggregatedRewards; // rewards / (liquidityIn - liquidityOut)
    }

    struct Position {
        address tokenA;
        address tokenB;
        uint liquidity;
        uint extraLiquidity;
        uint startDay;
        uint endLocking; // locked until this day (exclude)
    }

    address public TREASURY_MANAGER;

    // treasury key (token A address + token B address) => Field
    mapping(uint => Field) public override treasuryFields;

    // treasury key (token A address + token B address) => day => statistics
    mapping(uint => mapping(uint => Statistics)) public override dailyStatistics;

    // user address => idx => position
    mapping(address => Position[]) public override allPosition;

    // locked days => factor
    mapping(uint16 => uint) public override getRewardFactor;
    uint16[] public override allLockedDays;



    function __BLXMRewardProvider_init(address _TREASURY_MANAGER) internal onlyInitializing {
        TREASURY_MANAGER = _TREASURY_MANAGER;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function updateRewardFactor(uint16 lockedDays, uint factor) external override onlyOwner returns (bool) {
        require(lockedDays != 0, 'ZERO_DAYS');
        require(factor >= 10 ** 18, 'FACTOR_BELOW_ONE');

        if (getRewardFactor[lockedDays] == 0) {
            allLockedDays.push(lockedDays);
        } 
        getRewardFactor[lockedDays] = factor;
        return true;
    }

    function allLockedDaysLength() public override view returns (uint) {
        return allLockedDays.length;
    }

    function allPositionLength(address investor) public override view returns (uint) {
        return allPosition[investor].length;
    }

    function addRewards(address tokenA, address tokenB, uint totalAmount) external override nonReentrant onlyOwner returns (uint amount) {
        require(totalAmount > 0, 'ZERO_REWARDS');

        address treasury = BLXMLibrary.getTreasury(TREASURY_MANAGER, tokenA, tokenB);
        require(treasury != address(0), 'TREASURY_NOT_FOUND');

        DateTime._DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        uint8 month = dt.month;
        uint key = BLXMLibrary.getTreasuryKey(TREASURY_MANAGER, tokenA, tokenB);
        require(month != treasuryFields[key].period, 'IN_PERIOD');
        _syncStatistics(key);

        uint8 daysInMonth = DateTime.getDaysInMonth(month, dt.year);
        amount = totalAmount / daysInMonth;

        uint today = BLXMLibrary.today();
        uint right = daysInMonth - dt.day;
        uint left = dt.day;

        for (uint i = 0; i <= right; i++) {
            dailyStatistics[key][today.add(i)].rewards = amount;
        }
        for (uint i = 1; i < left; i++) {
            dailyStatistics[key][today.sub(i)].rewards = amount;
            // set aggregate rewards for elapsed in the current period
            Statistics storage statistics = dailyStatistics[key][i];
            uint liquidity = statistics.liquidityIn.sub(statistics.liquidityOut);
            if (liquidity != 0) {
                statistics.aggregatedRewards = statistics.rewards.wdiv(liquidity);
            }
        }
        treasuryFields[key].period = month;
    }

    function calcRewards(address investor, uint idx) external override view returns (uint amount, bool isLocked) {
        require(idx < allPositionLength(investor), 'NO_POSITION');
        (amount, isLocked) = _calcRewards(allPosition[investor][idx]);
    }

    function syncStatistics(address tokenA, address tokenB) external override {
        address treasury = BLXMLibrary.getTreasury(TREASURY_MANAGER, tokenA, tokenB);
        require(treasury != address(0), 'TREASURY_NOT_FOUND');
        _syncStatistics(BLXMLibrary.getTreasuryKey(TREASURY_MANAGER, tokenA, tokenB));
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    // if (is locked) {
    //     (liquidity + extra liquidity) * (agg today - agg day in)
    // } else {
    //     liquidity * (agg today - agg day in)
    //     extra liquidity * (agg end locking - agg day in)
    // }
    function _calcRewards(Position memory position) internal view returns (uint amount, bool isLocked) {
        address treasury = BLXMLibrary.getTreasury(TREASURY_MANAGER, position.tokenA, position.tokenB);
        require(treasury != address(0), 'TREASURY_NOT_FOUND');
        uint today = BLXMLibrary.today();
        uint key = BLXMLibrary.getTreasuryKey(TREASURY_MANAGER, position.tokenA, position.tokenB);
        require(treasuryFields[key].syncDay == today, 'NOT_SYNC');

        if (today < position.startDay) {
            return (0, true);
        }

        if (today < position.endLocking) {
            isLocked = true;
        }

        uint liquidity = position.liquidity;
        uint extraLiquidity = position.extraLiquidity;
        uint aggNow = dailyStatistics[key][today.sub(1)].aggregatedRewards;
        uint aggStart = dailyStatistics[key][position.startDay.sub(1)].aggregatedRewards;
        if (isLocked) {
            amount = liquidity.add(extraLiquidity).wmul(aggNow.sub(aggStart));
        } else {
            uint aggEnd = dailyStatistics[key][position.endLocking.sub(1)].aggregatedRewards;
            amount = extraLiquidity.wmul(aggEnd.sub(aggStart));
            amount = amount.add(liquidity.wmul(aggNow.sub(aggStart)));
        }          
    }

    function _mint(address to, address tokenA, address tokenB, uint amountA, uint amountB, uint16 lockedDays) internal nonReentrant returns (uint liquidity) {
        address treasury = BLXMLibrary.getTreasury(TREASURY_MANAGER, tokenA, tokenB);
        require(treasury != address(0), 'TREASURY_NOT_FOUND');

        liquidity = Math.sqrt(amountA.mul(amountB));
        require(liquidity != 0, 'INSUFFICIENT_LIQUIDITY');
        uint key = BLXMLibrary.getTreasuryKey(TREASURY_MANAGER, tokenA, tokenB);
        _syncStatistics(key);

        uint factor = getRewardFactor[lockedDays];
        uint extraLiquidity;
        if (factor > 10 ** 18) {
            extraLiquidity = liquidity.wmul(factor).sub(liquidity);
        } else {
            lockedDays = 0;
        }

        uint startDay = BLXMLibrary.today().add(1);
        uint endLocking = startDay.add(lockedDays);

        allPosition[to].push(Position(tokenA, tokenB, liquidity, extraLiquidity, startDay, endLocking));
        
        _updateLiquidity(key, startDay, liquidity.add(extraLiquidity), 0);
        if (extraLiquidity != 0) {
            _updateLiquidity(key, endLocking, 0, extraLiquidity);
        }

        treasuryFields[key].reserveA = amountA.add(treasuryFields[key].reserveA);
        treasuryFields[key].reserveB = amountB.add(treasuryFields[key].reserveB);
        treasuryFields[key].totalLiquidity = liquidity.add(treasuryFields[key].totalLiquidity);
        emit Mint(_msgSender(), amountA, amountB);
    }

    function _burn(address to, uint liquidity, uint idx) internal nonReentrant returns (uint amountA, uint amountB, uint rewardAmount) {
        require(idx < allPositionLength(_msgSender()), 'NO_POSITION');
        Position memory position = allPosition[_msgSender()][idx];
        require(liquidity <= position.liquidity, 'INSUFFICIENT_LIQUIDITY');
        uint key = BLXMLibrary.getTreasuryKey(TREASURY_MANAGER, position.tokenA, position.tokenB);
        _syncStatistics(key);

        // The start day must be a full day, 
        // when add and remove on the same day, 
        // the next day's liquidity should be subtracted.
        uint day = BLXMLibrary.today();
        day = day >= position.startDay ? day : position.startDay;
        _updateLiquidity(key, day, 0, liquidity);

        uint extraLiquidity;
        uint _totalLiquidity = treasuryFields[key].totalLiquidity;
        uint _reserveA = treasuryFields[key].reserveA;
        uint _reserveB = treasuryFields[key].reserveB;
        {
            // calculation block, prevent stack too deep
            uint percentageByTotal = liquidity.wdiv(_totalLiquidity);
            amountA = _reserveA.wmul(percentageByTotal);
            amountB = _reserveB.wmul(percentageByTotal);

            uint percentage = liquidity.wdiv(position.liquidity);
            extraLiquidity = liquidity == position.liquidity ? position.extraLiquidity : position.extraLiquidity.wmul(percentage);

            bool isLocked;
            (rewardAmount, isLocked) = _calcRewards(position);
            rewardAmount = rewardAmount.wmul(percentage);
            if (isLocked) {
                _arrangeFailedRewards(key, rewardAmount);
                rewardAmount = 0;
                _updateLiquidity(key, day, 0, extraLiquidity);
                _updateLiquidity(key, position.endLocking, extraLiquidity, 0);
            }
        }

        allPosition[_msgSender()][idx].liquidity = position.liquidity.sub(liquidity);
        allPosition[_msgSender()][idx].extraLiquidity = position.extraLiquidity.sub(extraLiquidity);
        treasuryFields[key].totalLiquidity = _totalLiquidity.sub(liquidity);
        treasuryFields[key].reserveA = _reserveA.sub(amountA);
        treasuryFields[key].reserveB = _reserveB.sub(amountB);

        // TODO call treasury to transafer token pair?
        assert(BLXMLibrary.withdraw(TREASURY_MANAGER, to, position.tokenA, position.tokenB, amountA, amountB));
        // TODO Withdraw with rewards?
        emit Burn(_msgSender(), amountA, amountB, rewardAmount, to);
    }

    function _arrangeFailedRewards(uint treasuryKey, uint rewardAmount) internal {
        DateTime._DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        uint8 month = dt.month;
        uint8 daysInMonth = DateTime.getDaysInMonth(month, dt.year);
        uint8 leftDays = (daysInMonth - dt.day + 1);
        uint rewards = rewardAmount / leftDays;
        if (rewards != 0) {
            uint day = BLXMLibrary.today();
            uint target = day + leftDays;
            for (uint i = day; i < target; i++) {
                dailyStatistics[treasuryKey][i].rewards = dailyStatistics[treasuryKey][i].rewards.add(rewards);
            }
        }
    }

    function _updateLiquidity(uint treasuryKey, uint day, uint liquidityIn, uint liquidityOut) internal {
        require(day >= BLXMLibrary.today(), 'DATA_FIXED');

        Statistics memory statistics = dailyStatistics[treasuryKey][day];
        statistics.liquidityIn = statistics.liquidityIn.add(liquidityIn);
        statistics.liquidityOut = statistics.liquidityOut.add(liquidityOut);
        dailyStatistics[treasuryKey][day] = statistics;
    }

    // should sync statistics every time before liquidity or rewards change
    function _syncStatistics(uint treasuryKey) internal {
        uint today = BLXMLibrary.today();
        uint day = treasuryFields[treasuryKey].syncDay;
        if (day == 0) {
            treasuryFields[treasuryKey].syncDay = today;
        } else if (day < today) {
            Statistics storage statistics = dailyStatistics[treasuryKey][day];
            while (day < today) {
                // sync latest data until today
                uint liquidity = statistics.liquidityIn.sub(statistics.liquidityOut);
                uint aggregatedRewards = statistics.aggregatedRewards;
                if (liquidity != 0) {
                    aggregatedRewards = aggregatedRewards.add(statistics.rewards.wdiv(liquidity));
                    statistics.aggregatedRewards = aggregatedRewards;
                }
                // The remaining liquidity should be put on the next day
                day += 1;
                statistics = dailyStatistics[treasuryKey][day];
                statistics.liquidityIn = statistics.liquidityIn.add(liquidity);
                statistics.aggregatedRewards = aggregatedRewards;
            }
            treasuryFields[treasuryKey].syncDay = day;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRouter {

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint idx
    ) external returns (uint amountA, uint amountB, uint rewards);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint idx
    ) external returns (uint amountToken, uint amountETH, uint rewards);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferCurrency(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: CURRENCY_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "../interfaces/ITreasury.sol";
import "../interfaces/IBLXMTreasuryManager.sol";

import "./SafeMath.sol";


library BLXMLibrary {
    using SafeMath for uint;

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_RESERVES');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address treasury, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITreasury(treasury).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function withdraw(address treasuryManager, address to, address tokenA, address tokenB, uint amountA, uint amountB) internal returns (bool) {
        address treasury = getTreasury(treasuryManager, tokenA, tokenB);
        (uint amount0, uint amount1) = tokenA < tokenB ? (amountA, amountB) : (amountB, amountA);
        ITreasury(treasury).withdraw(to, amount0, amount1);
        return true;
    }

    function getTreasury(address treasuryManager, address tokenA, address tokenB) internal view returns (address) {
        return IBLXMTreasuryManager(treasuryManager).getTreasury(tokenA, tokenB);
    }

    function getTreasuryKey(address treasuryManager, address tokenA, address tokenB) internal view returns (uint) {
        return IBLXMTreasuryManager(treasuryManager).getTreasuryKey(tokenA, tokenB);
    }
    
    function today() internal view returns(uint) {
        return block.timestamp / 1 days;
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRewardProvider {

    event Mint(address indexed sender, uint amountA, uint amountB);
    event Burn(address indexed sender, uint amountA, uint amountB, uint rewardAmount, address indexed to);

    function treasuryFields(uint treasuryKey) external view returns(uint syncDay, uint8 period, uint totalLiquidity, uint reserveA, uint reserveB);

    function getRewardFactor(uint16 _days) external view returns (uint factor);
    function updateRewardFactor(uint16 lockedDays, uint factor) external returns (bool);
    function allLockedDays(uint idx) external view returns (uint16 _days);
    function allLockedDaysLength() external view returns (uint);

    function allPosition(address investor, uint idx) external view returns(address tokenA, address tokenB, uint liquidity, uint extraLiquidity, uint startDay, uint endLocking);
    function allPositionLength(address investor) external view returns (uint);
    function addRewards(address tokenA, address tokenB, uint totalAmount) external returns (uint amount);
    function calcRewards(address investor, uint idx) external view returns (uint amount, bool isLocked);
    
    function dailyStatistics(uint treasuryKey, uint _days) external view returns (uint liquidityIn, uint liquidityOut, uint rewards, uint aggregatedRewards);
    function syncStatistics(address tokenA, address tokenB) external;

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    uint constant WAD = 10 ** 18;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
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

pragma solidity ^0.8.0;


// https://github.com/pipermerriam/ethereum-datetime
library DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }
        }

        function getYear(uint timestamp) internal pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface ITreasury {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transfer() external payable;
    function withdraw(address to, uint amountA, uint amountB) external;
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasuryManager {

    event TreasuryPut(address indexed tokenA, address indexed tokenB, address indexed treasury, uint length);

    function putTreasury(address tokenA, address tokenB, address treasury) external;
    function getTreasury(address tokenA, address tokenB) external view returns (address treasury);
    function allTreasury(uint) external view returns (address treasury);
    function allTreasuryLength() external view returns (uint);
    function getTreasuryKey(address tokenA, address tokenB) external view returns (uint treasuryKey);
}