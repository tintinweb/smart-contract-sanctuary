// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "./libs/SafeMath.sol";
import "./libs/IERC20.sol";
import "./libs/Ownable.sol";
import "./libs/ReentrancyGuard.sol";

/* interface SmartWalletChecker {
    function check(address) external returns (bool);
} */
interface IRewardVeLendFlarePool {
    function stake(address _for, uint256 amount) external;

    function withdraw(address _for, uint256 amount) external;
}

contract LendFlareVotingEscrow is Ownable, ReentrancyGuard {
    uint256 constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    uint256 private _totalSupply;

    string private _name = "Vote-escrowed LFT";
    string private _symbol = "VeLFT";
    uint256 private _decimals = 18;
    string private _version;

    address public token;
    // address public future_smart_wallet_checker;
    // address public smart_wallet_checker;

    uint256 public epoch;

    enum DepositTypes {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    struct Point {
        int128 bias;
        int128 slope; // dweight / dt
        uint256 ts; // timestamp
        uint256 blk; // block number
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    IRewardVeLendFlarePool[] public rewardVeLendFlarePool;

    // Point[100000000000000000Point000000000000] public point_history; // epoch -> unsigned point
    mapping(uint256 => Point) public point_history; // epoch -> unsigned point
    // mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
    mapping(address => mapping(uint256 => Point)) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes; // time -> signed slope change
    mapping(address => LockedBalance) public locked;

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        DepositTypes depositTypes,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    constructor(string memory version_, address token_addr_) public {
        _version = version_;
        token = token_addr_;
    }

    // function commit_smart_wallet_checker(address addr) public {
    //     future_smart_wallet_checker = addr;
    // }

    // function apply_smart_wallet_checker() public {
    //     smart_wallet_checker = future_smart_wallet_checker;
    // }

    // function assert_not_contract(address addr) public {
    //     require(addr != tx.origin);

    //     address checker = smart_wallet_checker;

    //     if (checker != address(0)) {
    //         SmartWalletChecker(checker).check(addr);
    //     }
    // }
    function rewardVeLendFlarePoolLength() external view returns (uint256) {
        return rewardVeLendFlarePool.length;
    }

    function addRewardVeLendFlarePool(address _v) external returns (bool) {
        rewardVeLendFlarePool.push(IRewardVeLendFlarePool(_v));

        return true;
    }

    function clearRewardVeLendFlarePool() external {
        delete rewardVeLendFlarePool;
    }

    function get_last_user_slope(address addr) external view returns (int128) {
        uint256 uepoch = user_point_epoch[addr];

        return user_point_history[addr][uepoch].slope;
    }

    function user_point_history_ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return user_point_history[_addr][_idx].ts;
    }

    function locked_end(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    function _checkpoint(
        address addr,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;

        int128 old_dslope;
        int128 new_dslope;

        if (addr != address(0)) {
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / int128(MAXTIME);
                // u_old.bias = u_old.slope * convert(old_locked.end - block.timestamp, int128);
                u_old.bias =
                    u_old.slope *
                    int128(old_locked.end - block.timestamp);
            }

            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / int128(MAXTIME);
                u_new.bias =
                    u_new.slope *
                    int128(new_locked.end - block.timestamp);
            }

            old_dslope = slope_changes[old_locked.end];

            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });

        if (epoch > 0) {
            last_point = point_history[epoch];
        }

        uint256 last_checkpoint = last_point.ts;
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0;

        if (block.timestamp > last_point.ts) {
            block_slope =
                (MULTIPLIER * (block.number - last_point.blk)) /
                (block.timestamp - last_point.ts);
        }

        uint256 t_i = (last_checkpoint / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            int128 d_slope = 0;

            if (t_i > block.timestamp) {
                t_i = block.timestamp;
            } else {
                d_slope = slope_changes[t_i];
            }

            //    last_point.bias -= last_point.slope * convert(t_i - last_checkpoint, int128);
            last_point.bias -= last_point.slope * int128(t_i - last_checkpoint);
            last_point.slope += d_slope;

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }

            last_checkpoint = t_i;
            last_point.ts = t_i;
            last_point.blk =
                initial_last_point.blk +
                (block_slope * (t_i - initial_last_point.ts)) /
                MULTIPLIER;

            epoch += 1;

            if (t_i == block.timestamp) {
                last_point.blk = block.number;
                break;
            } else {
                point_history[epoch] = last_point;
            }
        }

        if (addr != address(0)) {
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (last_point.slope < 0) {
                last_point.slope = 0;
            }

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        point_history[epoch] = last_point;

        if (addr != address(0)) {
            if (old_locked.end > block.timestamp) {
                old_dslope += u_old.slope;

                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope;
                }

                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope;
                    slope_changes[new_locked.end] = new_dslope;
                }
            }

            uint256 user_epoch = user_point_epoch[addr] + 1;
            user_point_epoch[addr] = user_epoch;

            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[addr][user_epoch] = u_new;
        }
    }

    function _deposit_for(
        address _addr,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance memory locked_balance,
        DepositTypes depositTypes
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before + _value;
        LockedBalance memory old_locked = _locked;

        // _locked.amount += convert(_value, int128);
        _locked.amount += int128(_value);

        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }

        locked[_addr] = _locked;

        uint256 beforeVeBal = balanceOf(msg.sender);

        _checkpoint(_addr, old_locked, _locked);

        uint256 afterVeBal = balanceOf(msg.sender);

        if (_value != 0) {
            IERC20(token).transferFrom(_addr, address(this), _value);
        }

        if (afterVeBal - beforeVeBal > 0) {
            for (uint256 i = 0; i < rewardVeLendFlarePool.length; i++) {
                rewardVeLendFlarePool[i].stake(
                    msg.sender,
                    afterVeBal - beforeVeBal
                );
            }
        }

        emit Deposit(_addr, _value, _locked.end, depositTypes, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    // function checkpoint() external {
    //     LockedBalance memory lb;

    //     for (uint256 i = 0; i < rewardVeLendFlarePool.length; i++) {
    //         rewardVeLendFlarePool[i].updateRewardState(msg.sender);
    //     }

    //     _checkpoint(address(0), lb, lb);
    // }

    function deposit_for(address _addr, uint256 _value) external nonReentrant {
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(
            _addr,
            _value,
            0,
            locked[_addr],
            DepositTypes.DEPOSIT_FOR_TYPE
        );
    }

    function create_lock(uint256 _value, uint256 _unlock_time)
        external
        nonReentrant
    {
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "need non-zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            unlock_time > block.timestamp,
            "Can only lock until time in the future"
        );
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            _value,
            unlock_time,
            _locked,
            DepositTypes.CREATE_LOCK_TYPE
        );
    }

    function increase_amount(uint256 _value) external nonReentrant {
        LockedBalance memory _locked = locked[msg.sender];
        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(
            msg.sender,
            _value,
            0,
            _locked,
            DepositTypes.INCREASE_LOCK_AMOUNT
        );
    }

    function increase_unlock_time(uint256 _unlock_time) external nonReentrant {
        // assert_not_contract(msg.sender);

        LockedBalance memory _locked = locked[msg.sender];
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            0,
            unlock_time,
            _locked,
            DepositTypes.INCREASE_UNLOCK_TIME
        );
    }

    function withdraw() public {
        LockedBalance memory _locked = locked[msg.sender];

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        // uint256 value = convert(_locked.amount, uint256);
        uint256 value = uint256(_locked.amount);

        LockedBalance memory old_locked = _locked;
        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;

        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before - value;

        uint256 beforeVeBal = balanceOf(msg.sender);

        _checkpoint(msg.sender, old_locked, _locked);

        uint256 afterVeBal = balanceOf(msg.sender);

        IERC20(token).transfer(msg.sender, value);

        uint256 newVeBal;

        if (afterVeBal >= beforeVeBal) {
            newVeBal = afterVeBal - beforeVeBal;
        } else {
            newVeBal = beforeVeBal - afterVeBal;
        }

        for (uint256 i = 0; i < rewardVeLendFlarePool.length; i++) {
            rewardVeLendFlarePool[i].withdraw(msg.sender, newVeBal - newVeBal);
        }

        emit Withdraw(msg.sender, value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    function find_block_epoch(uint256 _block, uint256 max_epoch)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = max_epoch;

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    function balanceOf(address addr, uint256 _t) public view returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = user_point_epoch[addr];

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[addr][_epoch];
            // last_point.bias -= last_point.slope * convert(_t - last_point.ts, int128);
            last_point.bias -= last_point.slope * int128(_t - last_point.ts);

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            // return convert(last_point.bias, uint256);
            return uint256(last_point.bias);
        }
    }

    function balanceOfAt(address addr, uint256 _block)
        public
        view
        returns (uint256)
    {
        require(_block <= block.number);

        uint256 _min = 0;
        uint256 _max = user_point_epoch[addr];

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (user_point_history[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[addr][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;

        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        // upoint.bias -= upoint.slope * convert(block_time - upoint.ts, int128);
        upoint.bias -= upoint.slope * int128(block_time - upoint.ts);

        if (upoint.bias >= 0) {
            // return convert(upoint.bias, uint256);
            return uint256(upoint.bias);
        } else {
            return 0;
        }
    }

    function supply_at(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        Point memory last_point = point;
        uint256 t_i = (last_point.ts / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            int128 d_slope = 0;

            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }

            // last_point.bias -= last_point.slope * convert(t_i - last_point.ts, int128);
            last_point.bias -= last_point.slope * int128(t_i - last_point.ts);

            if (t_i == t) break;

            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }

        // return convert(last_point.bias, uint256);
        return uint256(last_point.bias);
    }

    function totalSupply(uint256 t) public view returns (uint256) {
        if (t == 0) {
            t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory last_point = point_history[_epoch];

        return supply_at(last_point, t);
    }

    function totalSupplyAt(uint256 _block) public view returns (uint256) {
        require(_block <= block.number);

        uint256 _epoch = epoch;
        uint256 target_epoch = find_block_epoch(_block, _epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;

        if (target_epoch < _epoch) {
            Point memory point_next = point_history[target_epoch + 1];

            if (point.blk != point_next.blk) {
                dt =
                    ((_block - point.blk) * (point_next.ts - point.ts)) /
                    (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }

        return supply_at(point, point.ts + dt);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOf(account, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

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
abstract contract ReentrancyGuard {
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

    constructor() internal {
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