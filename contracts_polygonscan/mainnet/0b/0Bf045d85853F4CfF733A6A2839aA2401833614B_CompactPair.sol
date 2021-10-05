/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;



// Part: ICompactCallee

interface ICompactCallee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// Part: ICompactFactory

interface ICompactFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function feeReceiver() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function vampire() external view returns (address);

    function setVampire(address) external;
}

// Part: ICompactPair

interface ICompactPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimeLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address tokenA, address tokenB) external;

    function addLpIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external;

    function addVolumeIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external;
}

// Part: IERC20

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// Part: IMasterVampire

interface IMasterVampire {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

// Part: IStakingRewards

interface IStakingRewards {
    function startTime() external view returns (uint256);

    function stakingToken() external view returns (address);

    function userWeight(address _user) external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function getWeek() external view returns (uint256);

    function weeklyTotalWeight(uint256 _week) external view returns (uint256);

    function weeklyWeightOf(address _user, uint256 _week)
        external
        view
        returns (uint256);

    function mintLockTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks,
        bool _penalty
    ) external returns (address);

    function depositFee(address _token, uint256 _amount)
        external
        returns (bool);

    function depositLockTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks,
        bool _penalty
    ) external returns (bool);
}

// Part: Math

/// @title a library for performing various math operations
library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /// @notice babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

// Part: SafeERC20

library SafeERC20 {
    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 private constant APPROVE_SELECTOR =
        bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER_SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFERFROM_SELECTOR, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFERFROM_FAILED"
        );
    }

    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(APPROVE_SELECTOR, spender, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "APPROVE_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// Part: SafeMath

/// @title a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// Part: UQ112x112

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// Part: IncentiveVault

/**
    @title Incentive Vault
    @dev This contract is deployed each time a `CompactPair` contract is initialized.
         It is owned by the pair, and used to store added incentive tokens. By isolating
         incentives in a different contract we avoid potential for accounting errors when
         a pair is incentivized with one of it's tokens.
 */
contract IncentiveVault {
    using SafeERC20 for address;
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    IStakingRewards public feeReceiver;
    address public pair;

    constructor(IStakingRewards _feeReceiver) public {
        pair = msg.sender;
        feeReceiver = _feeReceiver;
    }

    function deposit(address token) external returns (uint256) {
        require(msg.sender == pair);

        uint256 lastBalance = balances[token];
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        balances[token] = newBalance;

        if (lastBalance == 0) {
            token.safeApprove(address(feeReceiver), uint256(-1));
        }

        return newBalance.sub(lastBalance);
    }

    function withdrawWithFee(
        address token,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == pair);

        balances[token] = balances[token].sub(amount);
        uint256 stakerFee = amount / 1000;

        token.safeTransfer(to, amount - stakerFee);
        feeReceiver.depositFee(token, stakerFee);

        return true;
    }
}

// Part: CompactPair

contract CompactPair {
    using SafeERC20 for address;
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    /**
        Arrays of `DayRecord` store data about trade volumes and user balances.
        * Structs in the array are ordered sequentially according to `day`.
        * `amount` is valid starting on the given day, until the day of the next array item.
     */
    struct DayRecord {
        uint16 day;
        uint240 amount;
    }

    /**
        Mappings of `IncentiveData` store data on available token incentives for this pair.
        * Each value in `dailyAmounts` is to the total available incentives for a given day,
          where the index value relates to the day returned by `getDay()`.
        * `start` is the first incentivized day, used to avoid iterating over many 0 values
          within `dailyAmounts`.
        * `lastUserClaim` stores the timestamp of each user's last claim for this incentive.
     */
    struct IncentiveData {
        uint256[65536] dailyAmounts;
        uint16 start;
        mapping(address => uint256) lastUserClaim;
    }

    /**
        `BalanceIndex` is used internally to help iterate over `DayRecord` arrays.
        * `idx` is the currently active array index within the iteration.
        * `nextDay` is the `day` value of the `DayRecord` at `idx + 1` within the
          array being iterated. When the final item is reached, this is set to `uint(-1)`.
     */
    struct BalanceIndex {
        uint256 idx;
        uint256 nextDay;
    }

    // constants
    bytes32 public DOMAIN_SEPARATOR;
    // solhint-disable-next-line max-line-length
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    // ERC20 storage vars
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    // AMM storage vars
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimeLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    // incentive storage vars
    IStakingRewards public feeReceiver;
    uint256 public startTime;

    // holds incentive tokens
    IncentiveVault public vault;

    // array of all incentive tokens that have been added (for both LPs and volume)
    address[] public incentiveTokens;

    // daily volumes are stored based on the output amount
    mapping(address => DayRecord[][2]) userDailyVolumes;
    DayRecord[][2] totalDailyVolumes;

    mapping(address => DayRecord[]) minimumDailyBalanceOf;
    DayRecord[] minimumDailyTotalSupply;

    mapping(address => IncentiveData) lpIncentives;
    mapping(address => IncentiveData) volumeIncentives;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event VolumeIncentiveAdded(
        address indexed from,
        address indexed token,
        uint256 amount,
        uint256 durationInDays
    );
    event LpIncentiveAdded(
        address indexed from,
        address indexed token,
        uint256 amount,
        uint256 durationInDays
    );
    event VolumeIncentiveClaimed(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );
    event LpIncentiveClaimed(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Compact: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        factory = msg.sender;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function universalSymbol(address token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = token.staticcall.gas(10000)(
            abi.encodeWithSignature("symbol()")
        );
        if (!success) {
            (success, data) = token.staticcall.gas(10000)(
                abi.encodeWithSignature("SYMBOL()")
            );
            if (!success) {
                return "";
            }
        }
        return abi.decode(data, (string));
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Compact: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        startTime = now;

        // ensure the minimum total supply record starts from day 0
        minimumDailyTotalSupply.push(DayRecord({day: 0, amount: 0}));

        string memory symbol0 = universalSymbol(_token0);
        string memory symbol1 = universalSymbol(_token1);

        if (bytes(symbol0).length == 0 || bytes(symbol1).length == 0) {
            symbol = "CLP";
            name = "Compact LP";
        } else {
            symbol = string(abi.encodePacked("CLP ", symbol0, "/", symbol1));
            name = string(
                abi.encodePacked("Compact LP ", symbol0, "/", symbol1)
            );
        }

        address _feeReceiver = ICompactFactory(factory).feeReceiver();
        feeReceiver = IStakingRewards(_feeReceiver);
        _token0.safeApprove(_feeReceiver, uint256(-1));
        _token1.safeApprove(_feeReceiver, uint256(-1));
        vault = new IncentiveVault(feeReceiver);
    }

    function getDay() public view returns (uint16) {
        return uint16((now - startTime) / 86400);
    }

    function incentiveTokensLength() external view returns (uint256) {
        return incentiveTokens.length;
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Compact: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Compact: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimeLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimeLast = blockTimeLast;
    }

    /**
        @notice Get the minimum balance of an account for a given day
        @dev LP-based incentives are paid out according to the minimum balance of a
             user in a given day, relative to the minimum total supply for that day
     */
    function getDailyMinUserBalance(address user, uint256 day)
        external
        view
        returns (uint256)
    {
        require(day <= getDay(), "Compact: DAY_GREATER_THAN_NOW");
        uint256 idx = _findIndex(minimumDailyBalanceOf[user], day).idx;
        return minimumDailyBalanceOf[user][idx].amount;
    }

    /**
        @notice Get the minimum totalSuppply for a given day
        @dev LP-based incentives are paid out according to the minimum balance of a
             user in a given day, relative to the minimum total supply for that day
     */
    function getDailyMinTotalSupply(uint256 day)
        external
        view
        returns (uint256)
    {
        require(day <= getDay(), "Compact: DAY_GREATER_THAN_NOW");
        uint256 idx = _findIndex(minimumDailyTotalSupply, day).idx;
        return minimumDailyTotalSupply[idx].amount;
    }

    /**
        @notice Get the daily trade volumes for a user on a given day
        @dev Trade volumes are tracked according to amountOut
        @return Array of total [amount0Out, amount1Out] traded by `_user` on `_day`
     */
    function getDailyUserVolumes(address user, uint256 day)
        external
        view
        returns (uint256[2] memory)
    {
        require(day <= getDay(), "Compact: DAY_GREATER_THAN_NOW");
        uint256 idx = _findIndex(userDailyVolumes[user][0], day).idx;
        return [
            uint256(userDailyVolumes[user][0][idx].amount),
            uint256(userDailyVolumes[user][1][idx].amount)
        ];
    }

    /**
        @notice Get the total daily trade volumes on a given day
        @dev Trade volumes are tracked according to amountOut
        @return Array of total [amount0Out, amount1Out] traded on `_day`
     */
    function getDailyTotalVolumes(uint256 day)
        external
        view
        returns (uint256[2] memory)
    {
        require(day <= getDay(), "Compact: DAY_GREATER_THAN_NOW");
        uint256 idx = _findIndex(totalDailyVolumes[0], day).idx;
        return [
            uint256(totalDailyVolumes[0][idx].amount),
            uint256(totalDailyVolumes[1][idx].amount)
        ];
    }

    /**
        @notice Get the total per-day available incentives of `token`
        @dev Arrays are 31 items long, with the first value corresponding to today's
             available incentives, then incrementing over the upcoming 30 days.
        @param token Incentive token
        @return lpAmounts Array of daily Lp incentives available
                volumeAmounts Array of daily volumme incentives available
     */
    function getDailyTotalIncentives(address token)
        external
        view
        returns (uint256[31] memory lpAmounts, uint256[31] memory volumeAmounts)
    {
        uint256 day = getDay();
        for (uint256 i; i < 31; i++) {
            lpAmounts[i] = lpIncentives[token].dailyAmounts[day + i];
            volumeAmounts[i] = volumeIncentives[token].dailyAmounts[day + i];
        }
        return (lpAmounts, volumeAmounts);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(-1) && balance1 <= uint112(-1),
            "Compact: OVERFLOW"
        );
        uint32 blockTime = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTime - blockTimeLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimeLast = blockTime;
        emit Sync(reserve0, reserve1);
    }

    function _increaseBalanceOf(
        address user,
        uint16 day,
        uint256 amount
    ) internal {
        // on an increase in balance, store the old user balance as the minimum
        // balance for today, and the new balance as the minimum balance for tomorrow
        uint256 oldBalance = balanceOf[user];
        uint256 newBalance = oldBalance.add(amount);
        require(uint240(newBalance) == newBalance);
        balanceOf[user] = newBalance;

        DayRecord[] storage userBalance = minimumDailyBalanceOf[user];
        uint256 length = userBalance.length;
        if (length > 0 && userBalance[length - 1].day == day + 1) {
            // if there was a previous balance update today, a record already
            // exists for tomorrow. only tomorrow's record must be updated.
            userBalance[length - 1].amount = uint240(newBalance);
        } else {
            if (length == 0 && day > 0) {
                // if this is the first record and not the first day, create an initial empty record.
                // this simplifies binary searches, as all user records start from the same day.
                userBalance.push(DayRecord({day: 0, amount: 0}));
            }
            if (length == 0 || userBalance[length - 1].day < day) {
                // if no record exists for today, store the old balance
                userBalance.push(
                    DayRecord({day: day, amount: uint240(oldBalance)})
                );
            }
            // store the updated balance in a record for tomorrow
            userBalance.push(
                DayRecord({day: day + 1, amount: uint240(newBalance)})
            );
        }
    }

    /// @dev Decrease the minimum balance for a user on a given day
    function _reduceBalanceOf(
        address user,
        uint16 day,
        uint256 amount
    ) internal returns (uint240 reduction) {
        // on a decrease in balance a record is only created for today
        uint240 newBalance = uint240(balanceOf[user].sub(amount));
        balanceOf[user] = newBalance;

        DayRecord[] storage userBalance = minimumDailyBalanceOf[user];
        uint256 idx = userBalance.length - 1;

        if (userBalance[idx].day > day) {
            // if a record already exists for tomorrow (due to a previous increase
            // in balance), only update the record if the new balance is less than
            // the currently recorded balance
            if (userBalance[idx].amount > newBalance) {
                userBalance[idx].amount = newBalance;
            }
            // reduce idx so that today's record is also updated
            idx--;
        }
        if (userBalance[idx].day == day) {
            // if a record exists for today, calculate the difference to the new
            // minimum balance and update the record if necessary
            uint240 oldBalance = userBalance[idx].amount;
            if (oldBalance > newBalance) {
                userBalance[idx].amount = newBalance;
                reduction = oldBalance - newBalance;
            }
        } else {
            // if no record exists for today, create one
            userBalance.push(DayRecord({day: day, amount: newBalance}));
            reduction = uint240(amount);
        }
        // return the difference between the old previous balance and the new one
        // so that the minimum total supply can also be updated
        return reduction;
    }

    /// @dev Decrease the minimum total supply on a given day
    function _reduceMinTotalSupply(
        uint16 day,
        uint240 reduction,
        uint240 finalSupply
    ) internal {
        uint256 length = minimumDailyTotalSupply.length;
        DayRecord storage latestSupply = minimumDailyTotalSupply[length - 1];

        if (latestSupply.day == day + 1) {
            // if the latest totalSupply record is for tomorrow, update tomorrow's record with
            // the current totalSupply, and reduce today's record by the reduction amount
            latestSupply.amount = finalSupply;
            minimumDailyTotalSupply[length - 2].amount -= reduction;
        } else if (latestSupply.day == day) {
            // if the latest record is for today, update today's record by the reduction amount
            // and create a new record for tomorrow with the current totalSupply
            latestSupply.amount -= reduction;
            minimumDailyTotalSupply.push(
                DayRecord({day: day + 1, amount: finalSupply})
            );
        } else {
            // if the latest record is prior to today, add new records for today and tomorrow
            minimumDailyTotalSupply.push(
                DayRecord({day: day, amount: latestSupply.amount - reduction})
            );
            minimumDailyTotalSupply.push(
                DayRecord({day: day + 1, amount: finalSupply})
            );
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        uint16 day = getDay();
        _increaseBalanceOf(to, day, value);
        uint240 reduction = _reduceBalanceOf(from, day, value);
        _reduceMinTotalSupply(day, reduction, uint240(totalSupply));

        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        uint16 day = getDay();

        uint256 _totalSupply = totalSupply; // gas savings
        if (_totalSupply == 0) {
            address vampire = ICompactFactory(factory).vampire();
            if (vampire == address(0)) {
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(
                    MINIMUM_LIQUIDITY
                );
                // permanently lock the first MINIMUM_LIQUIDITY tokens
                balanceOf[address(0)] = MINIMUM_LIQUIDITY;
                _totalSupply = MINIMUM_LIQUIDITY;
                emit Transfer(address(0), address(0), MINIMUM_LIQUIDITY);
                if (day > 0) {
                    minimumDailyTotalSupply.push(
                        DayRecord({day: day, amount: 0})
                    );
                }
            } else if (msg.sender == vampire) {
                liquidity = IMasterVampire(vampire).desiredLiquidity();
                require(
                    liquidity > 0 && liquidity != uint256(-1),
                    "Bad desired liquidity"
                );
            } else {
                revert("Compact: MINT_NOT_LAUNCHED");
            }
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "Compact: INSUFFICIENT_LIQUIDITY_MINTED");

        _increaseBalanceOf(to, day, liquidity);
        emit Transfer(address(0), to, liquidity);

        uint256 length = minimumDailyTotalSupply.length;
        if (minimumDailyTotalSupply[length - 1].day < day) {
            // if no entry for min totalSupply today, store the value prior to minting
            minimumDailyTotalSupply.push(
                DayRecord({day: day, amount: uint240(totalSupply)})
            );
            length++;
        }
        _totalSupply = _totalSupply.add(liquidity);
        require(_totalSupply == uint240(_totalSupply));
        totalSupply = _totalSupply;

        // ensure the entry for tomorrow's totalSupply is the current amount today
        if (minimumDailyTotalSupply[length - 1].day < day + 1) {
            minimumDailyTotalSupply.push(
                DayRecord({day: day + 1, amount: uint240(_totalSupply)})
            );
        } else {
            minimumDailyTotalSupply[length - 1].amount = uint240(_totalSupply);
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to)
        external
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "Compact: INSUFFICIENT_LIQUIDITY_BURNED"
        );

        uint16 day = getDay();
        uint240 reduction = _reduceBalanceOf(address(this), day, liquidity);
        emit Transfer(address(this), address(0), liquidity);

        _totalSupply = _totalSupply.sub(liquidity);
        totalSupply = _totalSupply;
        _reduceMinTotalSupply(day, reduction, uint240(_totalSupply));

        _token0.safeTransfer(to, amount0);
        _token1.safeTransfer(to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @dev Increase a volume record. The logic is identical for `userVolumes` and `totalDailyVolumes`.
    function _increaseVolume(
        DayRecord[] storage dailyVolumes,
        uint256 amount,
        uint16 day
    ) internal {
        uint256 length = dailyVolumes.length;
        if (length == 0 || dailyVolumes[length - 1].day < day) {
            if (length == 0 && day > 0) {
                // if this is the first record and not the first day, create an initial empty record.
                // this simplifies binary searches, as all user records start from the same day.
                dailyVolumes.push(DayRecord({day: 0, amount: 0}));
            }
            // if the day of the latest volume record is previous to today, create records
            // for today and tomorrow. the zero-volume record for tomorrow required to allow
            // generalized incentive calculations within _claimableIncentive
            dailyVolumes.push(DayRecord({day: day, amount: uint240(amount)}));
            dailyVolumes.push(DayRecord({day: day + 1, amount: 0}));
        } else if (dailyVolumes[length - 1].day > day) {
            // if the latest record is for tomorrow, only today's record must be updated
            uint256 oldAmount = dailyVolumes[length - 2].amount;
            uint240 newAmount = uint240(amount + oldAmount);
            require(newAmount >= oldAmount);
            dailyVolumes[length - 2].amount = newAmount;
        } else {
            // if the latest record is for today, update today's record and create a new
            // one for tomorrow
            uint256 oldAmount = dailyVolumes[length - 1].amount;
            uint240 newAmount = uint240(amount + oldAmount);
            require(newAmount >= oldAmount);
            dailyVolumes[length - 1].amount = newAmount;
            dailyVolumes.push(DayRecord({day: day + 1, amount: 0}));
        }
    }

    /// @dev this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "Compact: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "Compact: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "Compact: INVALID_TO");

            // optimistically transfer tokens
            if (amount0Out > 0) {
                _token0.safeTransfer(to, amount0Out);
            }
            if (amount1Out > 0) {
                _token1.safeTransfer(to, amount1Out);
            }

            // update daily volume records. amount0 and amount1 are both updated each time
            // to ensure the arrays are always the same length. different-length records
            // will cause issues when claiming volume incentives.
            DayRecord[][2] storage userVolumes = userDailyVolumes[to];
            uint16 day = getDay();
            _increaseVolume(userVolumes[0], amount0Out, day);
            _increaseVolume(userVolumes[1], amount1Out, day);
            _increaseVolume(totalDailyVolumes[0], amount0Out, day);
            _increaseVolume(totalDailyVolumes[1], amount1Out, day);

            if (data.length > 0)
                ICompactCallee(to).uniswapV2Call(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "Compact: INSUFFICIENT_INPUT_AMOUNT"
        );

        {
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));

            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(_reserve1).mul(1000**2),
                "Compact: K"
            );
        }

        // feeAmount is .05% of amount{0,1}In
        // multipling by .0005 is the same as dividing by 2000
        if (amount0In >= 2000) {
            uint256 feeAmount = amount0In / 2000;
            feeReceiver.depositFee(token0, feeAmount);
            balance0 -= feeAmount;
        }
        if (amount1In >= 2000) {
            uint256 feeAmount = amount1In / 2000;
            feeReceiver.depositFee(token1, feeAmount);
            balance1 -= feeAmount;
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /// @dev send 0.1% of the transfer to the Factory's feeReceiver and the rest to `_to`
    function _transferWithFee(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 stakerFee = _amount / 1000;
        _token.safeTransfer(_to, _amount - stakerFee);
        feeReceiver.depositFee(_token, stakerFee);
    }

    /// @notice force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _transferWithFee(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _transferWithFee(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    /// @notice force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    function _addIncentive(
        address token,
        uint256 duration,
        uint256 total,
        IncentiveData storage data
    ) internal returns (uint256) {
        require(duration < 31, "Cannot add incentives for more than 30 days");
        require(token != address(this), "Invalid incentive token");

        uint256 perDay = total / duration; // will revert on 0 duration
        token.safeTransferFrom(msg.sender, address(vault), perDay * duration);
        uint256 received = vault.deposit(token); // accounts for fee-on-transfer tokens
        perDay = received / duration;

        uint256 start = getDay() + 1;
        uint256 end = start + duration;
        uint256[65536] storage dailyAmounts = data.dailyAmounts;
        for (uint256 i = start; i < end; i++) {
            dailyAmounts[i] = dailyAmounts[i].add(perDay);
        }

        if (data.start == 0) {
            if (
                lpIncentives[token].start == 0 &&
                volumeIncentives[token].start == 0
            ) {
                // if this is a new incentive, add to `incentiveTokens`
                incentiveTokens.push(token);
            }
            data.start = uint16(start);
        }

        return perDay * duration;
    }

    /**
        @notice Add an incentive for liquidity providers in this pair
        @param token Address of the incentive token
        @param durationInDays `token` will be distributed linearly over this many days. Maximum 30.
        @param totalAmount The total amount of `token` to be distributed in the given time period.
     */
    function addLpIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external {
        uint256 amount = _addIncentive(
            token,
            durationInDays,
            totalAmount,
            lpIncentives[token]
        );
        emit VolumeIncentiveAdded(msg.sender, token, amount, durationInDays);
    }

    /**
        @notice Add an incentive for trade volume in this pair
        @dev Volume incentives are split evenly between trades in both directions.
             50% is given based on the total volume for amount0Out, 50% for amount1Out.
        @param token Address of the incentive token
        @param durationInDays `token` will be distributed linearly over this many days. Maximum 30.
        @param totalAmount The total amount of `token` to be distributed in the given time period.
     */
    function addVolumeIncentive(
        address token,
        uint256 durationInDays,
        uint256 totalAmount
    ) external {
        uint256 amount = _addIncentive(
            token,
            durationInDays,
            totalAmount,
            volumeIncentives[token]
        );
        emit LpIncentiveAdded(msg.sender, token, amount, durationInDays);
    }

    /**
        @dev Calculates the amount of claimable incentives for a user in a specific token.
             Returns the claimable amount, and a timestamp where the claimable amount was
             calculated to. The timestamp is necessary because claims are limited to 365 days
             to avoid potential gas exhaustion.
     */
    function _claimableIncentive(
        address user,
        IncentiveData storage data,
        DayRecord[] storage userBalances,
        DayRecord[] storage supply
    ) internal view returns (uint256, uint256) {
        uint256 lastClaim = data.lastUserClaim[user];
        if (lastClaim == 0) {
            lastClaim = startTime + (data.start * 86400);
        }
        uint256 lastClaimDay = (lastClaim - startTime) / 86400;

        // find DayRecord indexes of the last claim day, for totalSupply and user
        BalanceIndex memory balanceIdx = _findIndex(userBalances, lastClaimDay);
        BalanceIndex memory tsIdx = _findIndex(supply, lastClaimDay);

        uint256 amount;
        uint256[65536] storage dailyAmounts = data.dailyAmounts;

        uint256 next = Math.min(
            startTime + ((lastClaimDay + 1) * 86400),
            block.timestamp - 86400
        );
        if (next < lastClaim) {
            // nothing is claimable in the first 24 hours
            return (0, 0);
        }

        // calculate amount for last partially claimed day
        if (supply[tsIdx.idx].amount > 0) {
            uint256 remaining = dailyAmounts[lastClaimDay].mul(
                next.sub(lastClaim)
            ) / 86400;
            amount =
                remaining.mul(userBalances[balanceIdx.idx].amount) /
                supply[tsIdx.idx].amount;
        }

        if (block.timestamp - 86400 > next) {
            uint256 currentClaimDay = getDay() - 2;
            uint256 claimUntilDay = Math.min(
                lastClaimDay + 364,
                currentClaimDay
            ); // 364 + 1 from the partial day

            // add amounts for fully claimable days
            for (
                lastClaimDay++;
                lastClaimDay <= claimUntilDay;
                lastClaimDay++
            ) {
                if (lastClaimDay == balanceIdx.nextDay) {
                    balanceIdx = _nextIndex(userBalances, balanceIdx.idx);
                }
                if (lastClaimDay == tsIdx.nextDay) {
                    tsIdx = _nextIndex(supply, tsIdx.idx);
                }
                if (supply[tsIdx.idx].amount == 0) continue;
                uint256 claimAmount = dailyAmounts[lastClaimDay].mul(
                    userBalances[balanceIdx.idx].amount
                ) / supply[tsIdx.idx].amount;
                amount = amount.add(claimAmount);
            }

            // add partial amount for current day
            if (
                claimUntilDay == currentClaimDay && supply[tsIdx.idx].amount > 0
            ) {
                amount = amount.add(
                    (dailyAmounts[currentClaimDay + 1].mul(
                        block.timestamp -
                            86400 -
                            (startTime + ((currentClaimDay + 1) * 86400))
                    ) / 86400).mul(userBalances[balanceIdx.idx].amount) /
                        supply[tsIdx.idx].amount
                );
            } else {
                return (amount, startTime + ((claimUntilDay + 1) * 86400));
            }
        }
        return (amount, block.timestamp - 86400);
    }

    /**
        @notice Get the amount of `token` claimable by `user` that was earned by providing liquidity
     */
    function claimableLpIncentive(address user, address token)
        public
        view
        returns (uint256 claimable)
    {
        (claimable, ) = _claimableIncentive(
            user,
            lpIncentives[token],
            minimumDailyBalanceOf[user],
            minimumDailyTotalSupply
        );
        return claimable;
    }

    /**
        @notice Get the amount of `token` claimable by `user` that was earned through trade volume
     */
    function claimableVolumeIncentive(address user, address token)
        public
        view
        returns (uint256 claimable)
    {
        // check the volume for token 0
        (claimable, ) = _claimableIncentive(
            user,
            volumeIncentives[token],
            userDailyVolumes[user][0],
            totalDailyVolumes[0]
        );
        // check the volume for token 1
        (uint256 claimable2, ) = _claimableIncentive(
            user,
            volumeIncentives[token],
            userDailyVolumes[user][1],
            totalDailyVolumes[1]
        );
        // sum amounts and divide by 2 to split incentives evenly between the outputs
        return claimable.add(claimable2) / 2;
    }

    /**
        @notice Claim incentives for providing liquidity and/or trade volumes
        @param user Address to claim for. Any address may call to claim for any address.
        @param lpIncentiveTokens Array of token addresses to claim LP incentives for
        @param volumeIncentiveTokens Array of token addresses to claim trade volume incentives for
     */
    function claimIncentives(
        address user,
        address[] calldata lpIncentiveTokens,
        address[] calldata volumeIncentiveTokens
    ) external {
        for (uint256 i = 0; i < lpIncentiveTokens.length; i++) {
            address token = lpIncentiveTokens[i];
            (uint256 amount, uint256 claimTime) = _claimableIncentive(
                user,
                lpIncentives[token],
                minimumDailyBalanceOf[user],
                minimumDailyTotalSupply
            );
            if (amount > 0) {
                vault.withdrawWithFee(token, user, amount);
                emit LpIncentiveClaimed(msg.sender, user, token, amount);
            }
            lpIncentives[token].lastUserClaim[user] = claimTime;
        }

        for (uint256 i = 0; i < volumeIncentiveTokens.length; i++) {
            // volume incentives are split 50/50 so we cannot use `_claimIncentive`
            address token = volumeIncentiveTokens[i];
            (uint256 amount, uint256 claimTime) = _claimableIncentive(
                user,
                volumeIncentives[token],
                userDailyVolumes[user][0],
                totalDailyVolumes[0]
            );
            (uint256 amount2, ) = _claimableIncentive(
                user,
                volumeIncentives[token],
                userDailyVolumes[user][1],
                totalDailyVolumes[1]
            );
            amount = amount.add(amount2) / 2;
            if (amount > 0) {
                vault.withdrawWithFee(token, user, amount);
                emit VolumeIncentiveClaimed(msg.sender, user, token, amount);
            }
            volumeIncentives[token].lastUserClaim[user] = claimTime;
        }
    }

    /**
        @dev Binary search pattern used to locate an initial `DayRecord` when iterating
             an array. Returns a `BalanceIndex`.
     */
    function _findIndex(DayRecord[] storage dailyBalance, uint256 day)
        internal
        view
        returns (BalanceIndex memory)
    {
        uint256 length = dailyBalance.length;
        require(length > 0, "Compact: NO_RECORDS");

        uint256 low = 0;
        uint256 high = length - 1;

        while (low <= high) {
            uint256 middle = low + (high - low) / 2;
            uint256 prev = dailyBalance[middle].day;
            uint256 next = middle + 1 == length
                ? uint256(-1)
                : dailyBalance[middle + 1].day;
            if (prev <= day && next > day)
                return BalanceIndex({idx: middle, nextDay: next});
            else if (next <= day) low = middle + 1;
            else high = middle - 1;
        }
        revert("Compact: BINARY_SEARCH_FAILED");
    }

    /**
        @dev Given a `DayRecord` array and an index value, returns a `BalanceIndex`
             for the record at `idx + 1`.
     */
    function _nextIndex(DayRecord[] storage dailyBalance, uint256 idx)
        private
        view
        returns (BalanceIndex memory)
    {
        idx++;
        uint256 day;
        if (dailyBalance.length <= idx + 1) day = uint256(-1);
        else day = dailyBalance[idx + 1].day;
        return BalanceIndex({idx: idx, nextDay: day});
    }
}

// File: CompactFactory.sol

contract CompactFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    address public feeReceiver;
    address public vampire;

    event VampireSet(address oldVampire, address newVampire);
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeReceiver, address _vampire) public {
        require(_feeReceiver != address(0), "Compact: NO_FEE_RECEIVER");
        feeReceiver = _feeReceiver;
        // while the vampire is set, only the vampire can create pairs
        // this is important for reward accounting on the vampire
        vampire = _vampire;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(
            vampire == address(0) || msg.sender == vampire,
            "Compact: NOT_LAUNCHED"
        );
        require(tokenA != tokenB, "Compact: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Compact: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Compact: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(CompactPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ICompactPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setVampire(address _vampire) external {
        require(msg.sender == vampire, "Compact: FORBIDDEN");
        emit VampireSet(vampire, _vampire);
        vampire = _vampire;
    }
}