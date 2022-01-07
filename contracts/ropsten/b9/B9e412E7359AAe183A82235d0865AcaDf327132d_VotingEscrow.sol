pragma solidity 0.8.7;

/***
 *@title VotingEscrow
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Votes have a weight depending on time, so that users are
 *        committed to the future of (whatever they are voting for)
 *@dev Vote weight decays linearly over time. Lock time cannot be
 *     more than `MAXTIME` (4 years).
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses
import "./interfaces/dao/ISmartWalletChecker.sol";
import "./interfaces/dao/ICollateralManager.sol";

//libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VotingEscrow is ReentrancyGuard {
    struct Point {
        int256 bias;
        int256 slope; // - dweight / dt
        uint256 ts; //timestamp
        uint256 blk; // block
    }
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    int256 constant DEPOSIT_FOR_TYPE = 0;
    int256 constant CREATE_LOCK_TYPE = 1;
    int256 constant INCREASE_LOCK_AMOUNT = 2;
    int256 constant INCREASE_UNLOCK_TIME = 3;

    event CommitOwnership(address admin);
    event AcceptOwnership(address admin);

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        int256 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event ForceUnlock(address target, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    uint256 constant WEEK = 7 * 86400; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    address public token;
    uint256 public supply;

    mapping(address => LockedBalance) public locked;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public epoch;
    Point[100000000000000000000000000000] public point_history; // epoch -> unsigned point.
    mapping(address => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => int256) public slope_changes; // time -> signed slope change

    // Aragon's view methods for compatibility
    address public controller;
    bool public transfersEnabled;

    string public name;
    string public symbol;
    string public version;
    uint256 public decimals;

    // Checker for whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    address public future_smart_wallet_checker;
    address public smart_wallet_checker;

    address public admin; // Can and will be a smart contract
    address public future_admin;

    address public collateral_manager;
    address public future_collateral_manager;

    modifier checkStatus() {
        if (collateral_manager != address(0)) {
            require(
                ICollateralManager(collateral_manager).checkStatus(msg.sender),
                "rejected by collateral manager"
            );
        }
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(
        address _token_addr,
        string memory _name,
        string memory _symbol,
        string memory _version
    ) {
        /***
         *@notice Contract constructor
         *@param token_addr `InsureToken` token address
         *@param _name Token name
         *@param _symbol Token symbol
         *@param _version Contract version - required for Aragon compatibility
         */
        admin = msg.sender;
        token = _token_addr;
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
        controller = msg.sender;
        transfersEnabled = true;

        uint256 _decimals = 18;
        assert(_decimals <= 255);
        decimals = _decimals;

        name = _name;
        symbol = _symbol;
        version = _version;
    }

    function assert_not_contract(address _addr) internal {
        /***
         *@notice Check if the call is from a whitelisted smart contract, revert if not
         *@param _addr Address to be checked
         */
        if (_addr != tx.origin) {
            address checker = smart_wallet_checker; //not going to be deployed at the moment of launch.
            if (checker != address(0)) {
                if (ISmartWalletChecker(checker).check(_addr)) {
                    return;
                }
            }
            revert("Smart contract depositors not allowed");
        }
    }

    function get_last_user_slope(address _addr)
        external
        view
        returns (uint256)
    {
        /***
         *@notice Get the most recently recorded rate of voting power decrease for `_addr`
         *@param _addr Address of the user wallet
         *@return Value of the slope
         */
        uint256 uepoch = user_point_epoch[_addr];
        return uint256(user_point_history[_addr][uepoch].slope);
    }

    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        /***
         *@notice Get the timestamp for checkpoint `_idx` for `_addr`
         *@param _addr User wallet address
         *@param _idx User epoch number
         *@return Epoch time of the checkpoint
         */
        return user_point_history[_addr][_idx].ts;
    }

    function locked__end(address _addr) external view returns (uint256) {
        /***
         *@notice Get timestamp when `_addr`'s lock finishes
         *@param _addr User wallet
         *@return Epoch time of the lock end
         */
        return locked[_addr].end;
    }

    function _checkpoint(
        address _addr,
        LockedBalance memory _old_locked,
        LockedBalance memory _new_locked
    ) internal {
        /***
         *@notice Record global and per-user data to checkpoint
         *@param _addr User's wallet address. No user checkpoint if 0x0
         *@param _old_locked Pevious locked amount / end lock time for the user
         *@param _new_locked New locked amount / end lock time for the user
         */
        Point memory _u_old;
        Point memory _u_new;
        int256 _old_dslope = 0;
        int256 _new_dslope = 0;
        uint256 _epoch = epoch;

        if (_addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_old_locked.end > block.timestamp && _old_locked.amount > 0) {
                _u_old.slope = _old_locked.amount / int256(MAXTIME);
                _u_old.bias =
                    _u_old.slope *
                    int256(_old_locked.end - block.timestamp);
            }
            if (_new_locked.end > block.timestamp && _new_locked.amount > 0) {
                _u_new.slope = _new_locked.amount / int256(MAXTIME);
                _u_new.bias =
                    _u_new.slope *
                    int256(_new_locked.end - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // _old_locked.end can be in the past and in the future
            // _new_locked.end can ONLY by in the FUTURE unless everything expired than zeros
            _old_dslope = slope_changes[_old_locked.end];
            if (_new_locked.end != 0) {
                if (_new_locked.end == _old_locked.end) {
                    _new_dslope = _old_dslope;
                } else {
                    _new_dslope = slope_changes[_new_locked.end];
                }
            }
        }
        Point memory _last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });
        if (_epoch > 0) {
            _last_point = point_history[_epoch];
        }
        uint256 _last_checkpoint = _last_point.ts;
        // _initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory _initial_last_point = _last_point;
        uint256 _block_slope = 0; // dblock/dt
        if (block.timestamp > _last_point.ts) {
            _block_slope =
                (MULTIPLIER * (block.number - _last_point.blk)) /
                (block.timestamp - _last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 _t_i = (_last_checkpoint / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            _t_i += WEEK;
            int256 d_slope = 0;
            if (_t_i > block.timestamp) {
                _t_i = block.timestamp;
            } else {
                d_slope = slope_changes[_t_i];
            }
            _last_point.bias =
                _last_point.bias -
                _last_point.slope *
                int256(_t_i - _last_checkpoint);
            _last_point.slope += d_slope;
            if (_last_point.bias < 0) {
                // This can happen
                _last_point.bias = 0;
            }
            if (_last_point.slope < 0) {
                // This cannot happen - just in case
                _last_point.slope = 0;
            }
            _last_checkpoint = _t_i;
            _last_point.ts = _t_i;
            _last_point.blk =
                _initial_last_point.blk +
                ((_block_slope * (_t_i - _initial_last_point.ts)) / MULTIPLIER);
            _epoch += 1;
            if (_t_i == block.timestamp) {
                _last_point.blk = block.number;
                break;
            } else {
                point_history[_epoch] = _last_point;
            }
        }
        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            _last_point.slope += _u_new.slope - _u_old.slope;
            _last_point.bias += _u_new.bias - _u_old.bias;
            if (_last_point.slope < 0) {
                _last_point.slope = 0;
            }
            if (_last_point.bias < 0) {
                _last_point.bias = 0;
            }
        }
        // Record the changed point into history
        point_history[_epoch] = _last_point;

        address _addr2 = _addr; //To avoid being "Stack Too Deep"

        if (_addr2 != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_new_locked.end]
            // and add old_user_slope to [_old_locked.end]
            if (_old_locked.end > block.timestamp) {
                // _old_dslope was <something> - _u_old.slope, so we cancel that
                _old_dslope += _u_old.slope;
                if (_new_locked.end == _old_locked.end) {
                    _old_dslope -= _u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[_old_locked.end] = _old_dslope;
            }
            if (_new_locked.end > block.timestamp) {
                if (_new_locked.end > _old_locked.end) {
                    _new_dslope -= _u_new.slope; // old slope disappeared at this point
                    slope_changes[_new_locked.end] = _new_dslope;
                }
                // else we recorded it already in _old_dslope
            }

            // Now handle user history
            uint256 _user_epoch = user_point_epoch[_addr2] + 1;

            user_point_epoch[_addr2] = _user_epoch;
            _u_new.ts = block.timestamp;
            _u_new.blk = block.number;
            user_point_history[_addr2][_user_epoch] = _u_new;
        }
    }

    function _deposit_for(
        address _addr,
        uint256 _value,
        uint256 _unlock_time,
        LockedBalance memory _locked_balance,
        int256 _type
    ) internal {
        /***
         *@notice Deposit and lock tokens for a user
         *@param _addr User's wallet address
         *@param _value Amount to deposit
         *@param _unlock_time New time when to unlock the tokens, or 0 if unchanged
         *@param _locked_balance Previous locked amount / timestamp
         */
        LockedBalance memory _locked = LockedBalance(
            _locked_balance.amount,
            _locked_balance.end
        );
        LockedBalance memory _old_locked = LockedBalance(
            _locked_balance.amount,
            _locked_balance.end
        );

        uint256 _supply_before = supply;
        supply = _supply_before + _value;
        //Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount + int256(_value);
        if (_unlock_time != 0) {
            _locked.end = _unlock_time;
        }
        locked[_addr] = _locked;

        // Possibilities
        // Both _old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)

        _checkpoint(_addr, _old_locked, _locked);

        if (_value != 0) {
            assert(IERC20(token).transferFrom(_addr, address(this), _value));
        }

        emit Deposit(_addr, _value, _locked.end, _type, block.timestamp);
        emit Supply(_supply_before, _supply_before + _value);
    }

    function checkpoint() public {
        /***
         *@notice Record global data to checkpoint
         */
        LockedBalance memory _a;
        LockedBalance memory _b;
        _checkpoint(address(0), _a, _b);
    }

    function deposit_for(address _addr, uint256 _value) external nonReentrant {
        /***
         *@notice Deposit `_value` tokens for `_addr` and add to the lock
         *@dev Anyone (even a smart contract) can deposit for someone else, but
         *    cannot extend their locktime and deposit for a brand new user
         *@param _addr User's wallet address
         *@param _value Amount to add to user's lock
         */
        LockedBalance memory _locked = locked[_addr];

        require(_value > 0, "dev: need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(_addr, _value, 0, locked[_addr], DEPOSIT_FOR_TYPE);
    }

    function create_lock(uint256 _value, uint256 _unlock_time)
        external
        nonReentrant
    {
        /***
         *@notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
         *@param _value Amount to deposit
         *@param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
         */

        assert_not_contract(msg.sender);
        _unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "dev: need non-zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            _unlock_time > block.timestamp,
            "Can only lock until time in the future"
        );
        require(
            _unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            _value,
            _unlock_time,
            _locked,
            CREATE_LOCK_TYPE
        );
    }

    function increase_amount(uint256 _value) external nonReentrant {
        /***
         *@notice Deposit `_value` additional tokens for `msg.sender`
         *        without modifying the unlock time
         *@param _value Amount of tokens to deposit and add to the lock
         */
        assert_not_contract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];

        assert(_value > 0);
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _deposit_for(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    function increase_unlock_time(uint256 _unlock_time) external nonReentrant {
        /***
         *@notice Extend the unlock time for `msg.sender` to `_unlock_time`
         *@param _unlock_time New epoch time for unlocking
         */
        assert_not_contract(msg.sender); //@shun: need to convert to solidity
        LockedBalance memory _locked = locked[msg.sender];
        _unlock_time = (_unlock_time / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(_unlock_time > _locked.end, "Can only increase lock duration");
        require(
            _unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _deposit_for(
            msg.sender,
            0,
            _unlock_time,
            _locked,
            INCREASE_UNLOCK_TIME
        );
    }

    function withdraw() external checkStatus nonReentrant {
        /***
         *@notice Withdraw all tokens for `msg.sender`
         *@dev Only possible if the lock has expired
         */

        LockedBalance memory _locked = LockedBalance(
            locked[msg.sender].amount,
            locked[msg.sender].end
        );

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 _value = uint256(_locked.amount);

        LockedBalance memory _old_locked = LockedBalance(
            locked[msg.sender].amount,
            locked[msg.sender].end
        );

        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 _supply_before = supply;
        supply = _supply_before - _value;

        // _old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _old_locked, _locked);

        assert(IERC20(token).transfer(msg.sender, _value));

        emit Withdraw(msg.sender, _value, block.timestamp);
        emit Supply(_supply_before, _supply_before - _value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    function find_block_epoch(uint256 _block, uint256 _max_epoch)
        internal
        view
        returns (uint256)
    {
        /***
         *@notice Binary search to estimate timestamp for block number
         *@param _block Block to find
         *@param _max_epoch Don't go beyond this epoch
         *@return Approximate timestamp for block
         */
        // Binary search
        uint256 _min = 0;
        uint256 _max = _max_epoch;
        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
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

    function balanceOf(address _addr) external view returns (uint256) {
        /***
         *@notice Get the current voting power for `msg.sender`
         *@dev Adheres to the ERC20 `balanceOf` interface for Metamask & Snapshot compatibility
         *@param _addr User wallet address
         *@return User's present voting power
         */

        uint256 _t = block.timestamp;

        uint256 _epoch = user_point_epoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _last_point = user_point_history[_addr][_epoch];
            _last_point.bias -= _last_point.slope * int256(_t - _last_point.ts);
            if (_last_point.bias < 0) {
                _last_point.bias = 0;
            }
            return uint256(_last_point.bias);
        }
    }

    function balanceOf(address _addr, uint256 _t)
        external
        view
        returns (uint256)
    {
        /***
         *@notice Get the current voting power for `msg.sender`
         *@dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
         *@param _addr User wallet address
         *@param _t Epoch time to return voting power at
         *@return User voting power
         *@dev return the present voting power if _t is 0
         */

        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = user_point_epoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _last_point = user_point_history[_addr][_epoch];
            _last_point.bias -= _last_point.slope * int256(_t - _last_point.ts);
            if (_last_point.bias < 0) {
                _last_point.bias = 0;
            }
            return uint256(_last_point.bias);
        }
    }

    //Struct to avoid "Stack Too Deep"
    struct Parameters {
        uint256 min;
        uint256 max;
        uint256 max_epoch;
        uint256 d_block;
        uint256 d_t;
    }

    function balanceOfAt(address _addr, uint256 _block)
        external
        view
        returns (uint256)
    {
        /***
         *@notice Measure voting power of `_addr` at block height `_block`
         *@dev Adheres to MiniMe `balanceOfAt` interface https//github.com/Giveth/minime
         *@param _addr User's wallet address
         *@param _block Block to calculate the voting power at
         *@return Voting power
         */
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        assert(_block <= block.number);

        Parameters memory _st;

        // Binary search
        _st.min = 0;
        _st.max = user_point_epoch[_addr];
        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_st.min >= _st.max) {
                break;
            }
            uint256 _mid = (_st.min + _st.max + 1) / 2;
            if (user_point_history[_addr][_mid].blk <= _block) {
                _st.min = _mid;
            } else {
                _st.max = _mid - 1;
            }
        }

        Point memory _upoint = user_point_history[_addr][_st.min];

        _st.max_epoch = epoch;
        uint256 _epoch = find_block_epoch(_block, _st.max_epoch);
        Point memory _point_0 = point_history[_epoch];
        _st.d_block = 0;
        _st.d_t = 0;
        if (_epoch < _st.max_epoch) {
            Point memory _point_1 = point_history[_epoch + 1];
            _st.d_block = _point_1.blk - _point_0.blk;
            _st.d_t = _point_1.ts - _point_0.ts;
        } else {
            _st.d_block = block.number - _point_0.blk;
            _st.d_t = block.timestamp - _point_0.ts;
        }
        uint256 block_time = _point_0.ts;
        if (_st.d_block != 0) {
            block_time += (_st.d_t * (_block - _point_0.blk)) / _st.d_block;
        }

        _upoint.bias -= _upoint.slope * int256(block_time - _upoint.ts);
        if (_upoint.bias >= 0) {
            return uint256(_upoint.bias);
        } else {
            return 0;
        }
    }

    function supply_at(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        /***
         *@notice Calculate total voting power at some point in the past
         *@param point The point (bias/slope) to start search from
         *@param t Time to calculate the total voting power at
         *@return Total voting power at that time
         */
        Point memory _last_point = point;
        uint256 _t_i = (_last_point.ts / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            _t_i += WEEK;
            int256 d_slope = 0;

            if (_t_i > t) {
                _t_i = t;
            } else {
                d_slope = slope_changes[_t_i];
            }
            _last_point.bias -=
                _last_point.slope *
                int256(_t_i - _last_point.ts);

            if (_t_i == t) {
                break;
            }
            _last_point.slope += d_slope;
            _last_point.ts = _t_i;
        }

        if (_last_point.bias < 0) {
            _last_point.bias = 0;
        }
        return uint256(_last_point.bias);
    }

    function totalSupply() external view returns (uint256) {
        /***
         *@notice Calculate total voting power
         *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
         *@return Total voting power
         */

        uint256 _epoch = epoch;
        Point memory _last_point = point_history[_epoch];

        return supply_at(_last_point, block.timestamp);
    }

    function totalSupply(uint256 _t) external view returns (uint256) {
        /***
         *@notice Calculate total voting power
         *@dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
         *@return Total voting power
         */
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory _last_point = point_history[_epoch];

        return supply_at(_last_point, _t);
    }

    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        /***
         *@notice Calculate total voting power at some point in the past
         *@param _block Block to calculate the total voting power at
         *@return Total voting power at `_block`
         */
        assert(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 _target_epoch = find_block_epoch(_block, _epoch);

        Point memory _point = point_history[_target_epoch];
        uint256 dt = 0;
        if (_target_epoch < _epoch) {
            Point memory _point_next = point_history[_target_epoch + 1];
            if (_point.blk != _point_next.blk) {
                dt =
                    ((_block - _point.blk) * (_point_next.ts - _point.ts)) /
                    (_point_next.blk - _point.blk);
            }
        } else {
            if (_point.blk != block.number) {
                dt =
                    ((_block - _point.blk) * (block.timestamp - _point.ts)) /
                    (block.number - _point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point

        return supply_at(_point, _point.ts + dt);
    }

    // Dummy methods for compatibility with Aragon
    function changeController(address _newController) external {
        /***
         *@dev Dummy method required for Aragon compatibility
         */
        assert(msg.sender == controller);
        controller = _newController;
    }

    function get_user_point_epoch(address _user)
        external
        view
        returns (uint256)
    {
        return user_point_epoch[_user];
    }

    //----------------------Investment module----------------------//

    function force_unlock(address _target) external returns (bool) {
        /***
         *@notice unlock INSURE token without waiting for its end time.
         *@param _target address of being unlocked.
         *@return
         */
        require(
            msg.sender == collateral_manager,
            "only collateral manager can execute this function"
        );

        //withdraw
        LockedBalance memory _locked = LockedBalance(
            locked[_target].amount,
            locked[_target].end
        );
        LockedBalance memory _old_locked = LockedBalance(
            locked[_target].amount,
            locked[_target].end
        );

        uint256 value = uint256(_locked.amount);

        //there must be locked INSURE
        require(value != 0, "There is no locked INSURE");

        _locked.end = 0;
        _locked.amount = 0;
        locked[_target] = _locked;
        uint256 _supply_before = supply;
        supply = _supply_before - value;

        _checkpoint(_target, _old_locked, _locked);

        //transfer INSURE to collateral_manager
        assert(IERC20(token).transfer(collateral_manager, value));

        emit ForceUnlock(_target, value, block.timestamp);
        emit Supply(_supply_before, _supply_before - value);

        return true;
    }

    //---------------------- Admin Only ----------------------//
    function commit_smart_wallet_checker(address _addr) external onlyAdmin {
        /***
         *@notice Set an external contract to check for approved smart contract wallets
         *@param _addr Address of Smart contract checker
         */
        future_smart_wallet_checker = _addr;
    }

    function apply_smart_wallet_checker() external onlyAdmin {
        /***
         *@notice Apply setting external contract to check approved smart contract wallets
         */
        smart_wallet_checker = future_smart_wallet_checker;
    }

    function commit_collateral_manager(address _new_collateral_manager)
        external
        onlyAdmin
    {
        /***
         *@notice Commit setting external contract to check user's collateral status
         */
        future_collateral_manager = _new_collateral_manager;
    }

    function apply_collateral_manager() external onlyAdmin {
        /***
         *@notice Apply setting external contract to check user's collateral status
         */
        collateral_manager = future_collateral_manager;
    }

    function commit_transfer_ownership(address _addr) external onlyAdmin {
        /***
         *@notice Transfer ownership of VotingEscrow contract to `_addr`
         *@param _addr Address to have ownership transferred to
         */
        future_admin = _addr;
        emit CommitOwnership(_addr);
    }

    //only future admin
    function accept_transfer_ownership() external {
        /***
         *@notice Accept a transfer of ownership
         *@return bool success
         */
        require(address(msg.sender) == future_admin, "dev: future_admin only");

        admin = future_admin;

        emit AcceptOwnership(admin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ISmartWalletChecker {
    function check(address _addr) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ICollateralManager {
    function checkStatus(address _addr) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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
}