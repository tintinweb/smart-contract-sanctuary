// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./BloxMoveRewardProvider.sol";
import "./interfaces/IBloxMoveRouter.sol";

import "./interfaces/IWETH.sol";

import "./libraries/TransferHelper.sol";
import "./libraries/BloxMoveLibrary.sol";


contract BloxMoveRouter is BloxMoveRewardProvider, IBloxMoveRouter {

    address public immutable override WETH;


    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _WETH, address _rewardToken) BloxMoveRewardProvider(_rewardToken) {
        WETH = _WETH;
    }

    receive() external payable {
        assert(_msgSender() == WETH); // only accept ETH via fallback from the WETH contract
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
        (uint reserveA, uint reserveB) = BloxMoveLibrary.getReserves(treasury, tokenA, tokenB);
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
        address treasury = getTreasury[tokenA][tokenB];
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
        address treasury = getTreasury[token][WETH];
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
        require (getTreasury[tokenA][tokenB] != address(0), 'TREASURY_NOT_FOUND');
        uint amount0;
        uint amount1;
        (amount0, amount1, rewards) = _burn(to, liquidity, idx);
        (address token0,) = BloxMoveLibrary.sortTokens(tokenA, tokenB);
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
        return BloxMoveLibrary.quote(amountA, reserveA, reserveB);
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./interfaces/IBloxMoveRewardProvider.sol";
import "./BloxMoveTreasuryManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/SafeMath.sol";
import "./libraries/Math.sol";
import "./libraries/BloxMoveLibrary.sol";
import "./libraries/DateTime.sol";


contract BloxMoveRewardProvider is Ownable, BloxMoveTreasuryManager, IBloxMoveRewardProvider {

    using SafeMath for uint;

    address public override immutable REWARD_TOKEN;

    struct Statistics {
        // include extra liquidity
        uint liquidityIn;
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

    struct Tag {
        uint32 syncDay; // at most sync once a day
        uint8 period; // rewards supply once a month
    }

    uint public override totalLiquidity;
    // user address => idx => position
    mapping(address => Position[]) public allPosition;

    // treasury address => day => statistics
    mapping(address => mapping(uint => Statistics)) public dailyStatistics;

    // locked days => factor
    mapping(uint16 => uint) public override getRewardFactor;
    uint16[] public override allLockedDays;

    // treasury address => Tag
    mapping(address => Tag) public override tag;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // TODO should make it upgradeable?
    constructor(address _rewardToken) {
        REWARD_TOKEN = _rewardToken;
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

    function allPositionLength(address _address) public override view returns (uint) {
        return allPosition[_address].length;
    }

    function addRewards(address tokenA, address tokenB, uint totalAmount) external override lock onlyOwner returns (uint amount) {

        DateTime._DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        uint8 month = dt.month;

        require(totalAmount > 0, 'ZERO_REWARDS');
        address treasury = getTreasury[tokenA][tokenB];
        require(treasury != address(0), 'TREASURY_NOT_FOUND');
        require(month != tag[treasury].period, 'IN_PERIOD');
        _syncStatistics(treasury);

        uint8 daysInMonth = DateTime.getDaysInMonth(month, dt.year);
        amount = totalAmount / daysInMonth;

        uint today = BloxMoveLibrary.today();
        uint right = daysInMonth - dt.day;
        uint left = dt.day;

        for (uint i = 0; i <= right; i++) {
            dailyStatistics[treasury][today.add(i)].rewards = amount;
        }
        for (uint i = 1; i < left; i++) {
            dailyStatistics[treasury][today.sub(i)].rewards = amount;
            // set aggregate rewards for elapsed in the current period
            Statistics memory statistics = dailyStatistics[treasury][i];
            uint liquidity = statistics.liquidityIn.sub(statistics.liquidityOut);
            if (liquidity != 0) {
                dailyStatistics[treasury][i].aggregatedRewards = statistics.rewards.wdiv(liquidity);
            }
        }
        tag[treasury].period = month;
    }

    function calcRewards(address _address, uint idx) external override view returns (uint amount, bool isLocked) {
        require(idx < allPositionLength(_address), 'NO_POSITION');
        (amount, isLocked) = _calcRewards(allPosition[_address][idx]);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function _calcRewards(Position memory position) internal view returns (uint amount, bool isLocked) {
        address treasury = getTreasury[position.tokenA][position.tokenB];
        require(treasury != address(0), 'TREASURY_NOT_FOUND');
        uint today = BloxMoveLibrary.today();
        if (today < position.startDay) {
            return (0, true);
        }

        if (today < position.endLocking) {
            isLocked = true;
        }

        uint liquidity = position.liquidity;
        uint extraLiquidity = position.extraLiquidity;
        uint aggNow = dailyStatistics[treasury][today.sub(1)].aggregatedRewards;
        uint aggStart = dailyStatistics[treasury][position.startDay.sub(1)].aggregatedRewards;
        if (isLocked) {
            amount = liquidity.add(extraLiquidity).mul(aggNow.sub(aggStart));
        } else {
            uint aggEnd = dailyStatistics[treasury][position.endLocking.sub(1)].aggregatedRewards;
            amount = extraLiquidity.mul(aggEnd.sub(aggStart));
            amount = amount.add(liquidity.mul(aggNow.sub(aggStart)));
        }          
    }

    function _mint(address to, address tokenA, address tokenB, uint amountA, uint amountB, uint16 lockedDays) internal lock returns (uint liquidity) {
        address treasury = getTreasury[tokenA][tokenB];
        require(treasury != address(0), 'TREASURY_NOT_FOUND');

        liquidity = Math.sqrt(amountA.mul(amountB));
        require(liquidity != 0, 'INSUFFICIENT_LIQUIDITY');
        _syncStatistics(treasury);

        uint factor = getRewardFactor[lockedDays];
        uint extraLiquidity;
        if (factor > 10 ** 18) {
            extraLiquidity = liquidity.wmul(factor).sub(liquidity);
        } else {
            lockedDays = 0;
        }

        uint startDay = BloxMoveLibrary.today().add(1);
        uint endLocking = startDay.add(lockedDays);

        allPosition[to].push(Position(tokenA, tokenB, liquidity, extraLiquidity, startDay, endLocking));
        
        _updateLiquidity(treasury, startDay, liquidity.add(extraLiquidity), 0);
        if (extraLiquidity != 0) {
            _updateLiquidity(treasury, endLocking, 0, extraLiquidity);
        }

        totalLiquidity = liquidity.add(totalLiquidity);
        emit Mint(_msgSender(), amountA, amountB);
    }

    function _burn(address to, uint liquidity, uint idx) internal lock returns (uint amountA, uint amountB, uint rewardAmount) {
        require(idx < allPositionLength(_msgSender()), 'NO_POSITION');
        Position memory position = allPosition[_msgSender()][idx];
        require(liquidity <= position.liquidity, 'INSUFFICIENT_LIQUIDITY');
        address treasury = getTreasury[position.tokenA][position.tokenB];
        _syncStatistics(treasury);

        // The start day must be a full day, 
        // when add and remove on the same day, 
        // the next day's liquidity should be subtracted.
        uint day = BloxMoveLibrary.today();
        day = day >= position.startDay ? day : position.startDay;
        _updateLiquidity(treasury, day, 0, liquidity);

        uint extraLiquidity;
        uint _totalLiquidity = totalLiquidity;
        {
            // calculation block, prevent stack too deep
            (uint reserveA, uint reserveB) = BloxMoveLibrary.getReserves(treasury, position.tokenA, position.tokenB);
            uint percentage = liquidity.wdiv(_totalLiquidity);
            amountA = reserveA.wmul(percentage);
            amountB = reserveB.wmul(percentage);

            extraLiquidity = liquidity == position.liquidity ? position.extraLiquidity : position.extraLiquidity.wmul(percentage);

            bool isLocked;
            (rewardAmount, isLocked) = _calcRewards(position);
            if (isLocked) {
                _arrangeFailedRewards(treasury, rewardAmount);
                rewardAmount = 0;
                _updateLiquidity(treasury, day, 0, extraLiquidity);
                _updateLiquidity(treasury, position.endLocking, extraLiquidity, 0);
            } else {
                rewardAmount = rewardAmount.wmul(percentage);
            }
        }

        position.liquidity = position.liquidity.sub(liquidity);
        position.extraLiquidity = position.extraLiquidity.sub(extraLiquidity);
        allPosition[_msgSender()][idx] = position;
        totalLiquidity = _totalLiquidity.sub(liquidity);
        
        // TODO call treasury to transafer token pair?
        assert(withdraw(to, position.tokenA, position.tokenB, amountA, amountB));
        // TODO Withdraw with rewards?
        emit Burn(_msgSender(), amountA, amountB, rewardAmount, to);
    }

    function _arrangeFailedRewards(address treasury, uint rewardAmount) internal {
        DateTime._DateTime memory dt = DateTime.parseTimestamp(block.timestamp);
        uint8 month = dt.month;
        uint8 daysInMonth = DateTime.getDaysInMonth(month, dt.year);
        uint rewards = rewardAmount / (daysInMonth - dt.day + 1);
        for (uint i = dt.day; i <= daysInMonth; i++) {
            Statistics memory statistics = dailyStatistics[treasury][i];
            statistics.rewards = statistics.rewards.add(rewards);
            dailyStatistics[treasury][i] = statistics;
        }
    }

    function _updateLiquidity(address treasury, uint day, uint liquidityIn, uint liquidityOut) internal {
        require(day >= BloxMoveLibrary.today(), 'DATA_FIXED');

        Statistics memory statistics = dailyStatistics[treasury][day];
        statistics.liquidityIn = statistics.liquidityIn.add(liquidityIn);
        statistics.liquidityOut = statistics.liquidityOut.add(liquidityOut);
        dailyStatistics[treasury][day] = statistics;
    }

    // should sync statistics every time before liquidity or rewards change
    function _syncStatistics(address treasury) internal {
        uint today = BloxMoveLibrary.today();
        uint32 day = tag[treasury].syncDay;
        if (day == 0) {
            day == today;
        } else if (day != today) {
            Statistics memory statistics = dailyStatistics[treasury][day];
            while (day < today) {
                // sync latest data until today
                uint liquidity = statistics.liquidityIn.sub(statistics.liquidityOut);
                if (liquidity != 0) {
                    dailyStatistics[treasury][day].aggregatedRewards = statistics.rewards.wdiv(liquidity);
                }
                // The remaining liquidity should be put on the next day
                day += 1;
                statistics = dailyStatistics[treasury][day];
                dailyStatistics[treasury][day].liquidityIn = statistics.liquidityIn.add(liquidity);
            }
            tag[treasury].syncDay = day;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBloxMoveRouter {

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

import "./SafeMath.sol";


library BloxMoveLibrary {
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

    function today() internal view returns(uint) {
        return block.timestamp / 1 days;
    }
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBloxMoveRewardProvider {

    event Mint(address indexed sender, uint amountA, uint amountB);
    event Burn(address indexed sender, uint amountA, uint amountB, uint rewardAmount, address indexed to);

    function REWARD_TOKEN() external view returns (address);

    function tag(address) external view returns(uint32, uint8);

    function getRewardFactor(uint16) external view returns (uint);
    function updateRewardFactor(uint16 lockedDays, uint factor) external returns (bool);
    function allLockedDays(uint) external view returns (uint16);
    function allLockedDaysLength() external view returns (uint);

    function totalLiquidity() external view returns (uint);
    function allPositionLength(address _address) external view returns (uint);
    function addRewards(address tokenA, address tokenB, uint totalAmount) external returns (uint amount);
    function calcRewards(address _address, uint idx) external view returns (uint amount, bool isLocked);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./interfaces/IBloxMoveTreasuryManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ITreasury.sol";

import "./libraries/BloxMoveLibrary.sol";

contract BloxMoveTreasuryManager is Ownable, IBloxMoveTreasuryManager {

    // token A(B) => token B(A) => treasury
    mapping(address => mapping(address => address)) public override getTreasury;
    address[] public override allTreasury;

    function putTreasury(address tokenA, address tokenB, address treasury) external override onlyOwner {
        require(treasury != address(0), 'TREASURY_NOT_FOUND');
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');

        getTreasury[token0][token1] = treasury;
        getTreasury[token1][token0] = treasury; // populate mapping in the reverse direction

        allTreasury.push(treasury);
        emit TreasuryPut(token0, token1, treasury, allTreasury.length);
    }

    function allTreasuryLength() external view override returns (uint) {
        return allTreasury.length;
    }

    // TODO how to withdraw token in real treasury contract?
    function withdraw(address to, address tokenA, address tokenB, uint amountA, uint amountB) internal returns (bool) {
        (uint amount0, uint amount1) = tokenA < tokenB ? (amountA, amountB) : (amountB, amountA);
        ITreasury(getTreasury[tokenA][tokenB]).withdraw(to, amount0, amount1);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBloxMoveTreasuryManager {

    event TreasuryPut(address indexed tokenA, address indexed tokenB, address indexed treasury, uint length);

    function putTreasury(address tokenA, address tokenB, address treasury) external;
    function getTreasury(address tokenA, address tokenB) external view returns (address treasury);
    function allTreasury(uint) external view returns (address treasury);
    function allTreasuryLength() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface ITreasury {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function transfer() external payable;
    function withdraw(address to, uint amountA, uint amountB) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}