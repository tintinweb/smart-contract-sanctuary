pragma solidity 0.8.7;

/***
 *@title Liquidity Gauge
 *@author InsureDAO
 * SPDX-License-Identifier: MIT
 *@notice Used for measuring liquidity and insurance
 */

//dao-contracts
import "./interfaces/dao/IGaugeController.sol";
import "./interfaces/dao/IInsureToken.sol";
import "./interfaces/dao/IMinter.sol";
import "./interfaces/dao/IVotingEscrow.sol";

//libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LiquidityGauge is ReentrancyGuard {
    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(
        address user,
        uint256 original_balance,
        uint256 original_supply,
        uint256 working_balance,
        uint256 working_supply,
        uint256 voting_balance,
        uint256 voting_total
    );
    event CommitOwnership(address admin);
    event AcceptOwnership(address admin);

    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant BOOST_WARMUP = 86400 * 14;
    uint256 constant WEEK = 604800;

    //Contracts
    IMinter public minter;
    IInsureToken public insure_token;
    IERC20 public template;
    IGaugeController public controller;
    IVotingEscrow public voting_escrow;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public future_epoch_time;

    // caller -> recipient -> can deposit?
    mapping(address => mapping(address => bool)) public approved_to_deposit;

    mapping(address => uint256) public working_balances;
    uint256 public working_supply;

    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    uint256 public period; //modified from "int256 public period" since it never be minus.

    uint256[100000000000000000000000000000] public period_timestamp;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    uint256[100000000000000000000000000000] public integrate_inv_supply; // bump epoch when rate() changes. Iis(t)=int(r'(t)/S(t))dt (from CurveDAO whitepaper)

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256) public integrate_inv_supply_of;
    mapping(address => uint256) public integrate_checkpoint_of;

    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units rate * t = already number of coins per address to issue
    mapping(address => uint256) public integrate_fraction; //Mintable Token amount (include minted amount)

    uint256 public inflation_rate;

    address public admin;
    address public future_admin; // Can and will be a smart contract
    bool public is_killed;

    constructor(
        address _lp_addr,
        address _minter,
        address _admin
    ) {
        /***
         *@notice Contract constructor
         *@param _lp_addr Liquidity Pool contract address
         *@param _minter Minter contract address
         *@param _admin Admin who can kill the gauge
         */

        assert(_lp_addr != address(0));
        assert(_minter != address(0));

        template = IERC20(_lp_addr);
        minter = IMinter(_minter);
        address _insure_addr = minter.insure_token();
        insure_token = IInsureToken(_insure_addr);
        controller = IGaugeController(minter.gauge_controller());
        voting_escrow = IVotingEscrow(controller.get_voting_escrow());
        period_timestamp[0] = block.timestamp;
        inflation_rate = insure_token.rate();
        future_epoch_time = insure_token.future_epoch_time_write();
        admin = _admin;
    }

    function _update_liquidity_limit(
        address _addr,
        uint256 _l,
        uint256 _L
    ) internal {
        /***
         *@notice Calculate limits which depend on the amount of INSURE Token per-user.
         *        Effectively it calculates working balances to apply amplification
         *        of INSURE production by INSURE
         *@param _addr User address
         *@param _l User's amount of liquidity (LP tokens)
         *@param _L Total amount of liquidity (LP tokens)
         */
        // To be called after totalSupply is updated
        uint256 _voting_balance = voting_escrow.balanceOf(
            _addr,
            block.timestamp
        );
        uint256 _voting_total = voting_escrow.totalSupply(block.timestamp);

        uint256 _lim = (_l * TOKENLESS_PRODUCTION) / 100;
        if (
            (_voting_total > 0) &&
            (block.timestamp > period_timestamp[0] + BOOST_WARMUP)
        ) {
            _lim +=
                (_L * _voting_balance * (100 - TOKENLESS_PRODUCTION)) /
                _voting_total /
                100;
        }

        _lim = min(_l, _lim);
        uint256 _old_bal = working_balances[_addr];
        working_balances[_addr] = _lim;
        uint256 _working_supply = working_supply + _lim - _old_bal;
        working_supply = _working_supply;

        emit UpdateLiquidityLimit(
            _addr,
            _l,
            _L,
            _lim,
            _working_supply,
            _voting_balance,
            _voting_total
        );
    }

    //to avoid "stack too deep"
    struct CheckPointParameters {
        uint256 period;
        uint256 period_time;
        uint256 integrate_inv_supply;
        uint256 rate;
        uint256 new_rate;
        uint256 prev_future_epoch;
        uint256 working_balance;
        uint256 working_supply;
    }

    function _checkpoint(address _addr) internal {
        /***
         *@notice Checkpoint for a user
         *@param _addr User address
         *
         *This function does,
         *1. Calculate Iis for All: Calc and add Iis for every week. Iis only increses over time.
         *2. Calculate Iu for _addr: Calc by (defferece between Iis(last time) and Iis(this time))* LP deposit amount of _addr(include INSURE locking boost)
         *
         * working_supply & working_balance = total_supply & total_balance with INSURE locking boost。
         * Check whitepaper about Iis and Iu.
         */
        CheckPointParameters memory _st;

        _st.period = period;
        _st.period_time = period_timestamp[_st.period];
        _st.integrate_inv_supply = integrate_inv_supply[_st.period];
        _st.rate = inflation_rate;
        _st.new_rate = _st.rate;
        _st.prev_future_epoch = future_epoch_time;
        if (_st.prev_future_epoch >= _st.period_time) {
            //update future_epoch_time & inflation_rate
            future_epoch_time = insure_token.future_epoch_time_write();
            _st.new_rate = insure_token.rate();
            inflation_rate = _st.new_rate;
        }
        controller.checkpoint_gauge(address(this));

        uint256 _working_balance = working_balances[_addr];
        uint256 _working_supply = working_supply;

        if (is_killed) {
            _st.rate = 0; // Stop distributing inflation as soon as killed
        }

        // Update integral of 1/supply
        if (block.timestamp > _st.period_time) {
            uint256 _prev_week_time = _st.period_time;
            uint256 _week_time = min(
                ((_st.period_time + WEEK) / WEEK) * WEEK,
                block.timestamp
            );

            for (uint256 i; i < 500; i++) {
                uint256 _dt = _week_time - _prev_week_time;
                uint256 _w = controller.gauge_relative_weight(
                    address(this),
                    (_prev_week_time / WEEK) * WEEK
                );

                if (_working_supply > 0) {
                    if (
                        _st.prev_future_epoch >= _prev_week_time &&
                        _st.prev_future_epoch < _week_time
                    ) {
                        // If we went across one or multiple epochs, apply the rate
                        // of the first epoch until it ends, and then the rate of
                        // the last epoch.
                        // If more than one epoch is crossed - the gauge gets less,
                        // but that'd meen it wasn't called for more than 1 year
                        _st.integrate_inv_supply +=
                            (_st.rate *
                                _w *
                                (_st.prev_future_epoch - _prev_week_time)) /
                            _working_supply;
                        _st.rate = _st.new_rate;
                        _st.integrate_inv_supply +=
                            (_st.rate *
                                _w *
                                (_week_time - _st.prev_future_epoch)) /
                            _working_supply;
                    } else {
                        _st.integrate_inv_supply +=
                            (_st.rate * _w * _dt) /
                            _working_supply;
                    }
                    // On precisions of the calculation
                    // rate ~= 10e18
                    // last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    // _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    // The largest loss is at dt = 1
                    // Loss is 1e-9 - acceptable
                }
                if (_week_time == block.timestamp) {
                    break;
                }
                _prev_week_time = _week_time;
                _week_time = min(_week_time + WEEK, block.timestamp);
            }
        }

        _st.period += 1;
        period = _st.period;
        period_timestamp[_st.period] = block.timestamp;
        integrate_inv_supply[_st.period] = _st.integrate_inv_supply;

        // Update user-specific integrals
        // Calc the ΔIu of _addr and add it to Iu.
        integrate_fraction[_addr] +=
            (_working_balance *
                (_st.integrate_inv_supply - integrate_inv_supply_of[_addr])) /
            10**18;
        integrate_inv_supply_of[_addr] = _st.integrate_inv_supply;
        integrate_checkpoint_of[_addr] = block.timestamp;
    }

    function user_checkpoint(address _addr) external returns (bool) {
        /***
         *@notice Record a checkpoint for `_addr`
         *@param _addr User address
         *@return bool success
         */
        require(
            (msg.sender == _addr) || (msg.sender == address(minter)),
            "dev: unauthorized"
        );
        _checkpoint(_addr);
        _update_liquidity_limit(_addr, balanceOf[_addr], totalSupply);
        return true;
    }

    function claimable_tokens(address _addr) external returns (uint256) {
        /***
         *@notice Get the number of claimable tokens per user
         *@dev This function should be manually changed to "view" in the ABI
         *@return uint256 number of claimable tokens per user
         */
        _checkpoint(_addr);
        return (integrate_fraction[_addr] -
            minter.minted(_addr, address(this)));
    }

    function kick(address _addr) external {
        /***
         *@notice Kick `_addr` for abusing their boost
         *@dev Only if either they had another voting event, or their voting escrow lock expired
         *@param _addr Address to kick
         */
        uint256 _t_last = integrate_checkpoint_of[_addr];
        uint256 _t_ve = voting_escrow.user_point_history__ts(
            _addr,
            voting_escrow.get_user_point_epoch(_addr)
        );
        uint256 _balance = balanceOf[_addr];

        require(
            voting_escrow.balanceOf(_addr, block.timestamp) == 0 ||
                _t_ve > _t_last,
            "dev: kick not allowed"
        );
        require(
            working_balances[_addr] > (_balance * TOKENLESS_PRODUCTION) / 100,
            "dev: kick not needed"
        );

        _checkpoint(_addr);
        _update_liquidity_limit(_addr, balanceOf[_addr], totalSupply);
    }

    function set_approve_deposit(address _addr, bool can_deposit) external {
        /***
         *@notice Set whether `_addr` can deposit tokens for `msg.sender`
         *@param _addr Address to set approval on
         *@param can_deposit bool - can this account deposit for `msg.sender`?
         */
        approved_to_deposit[_addr][msg.sender] = can_deposit;
    }

    function deposit(uint256 _value, address _addr) external nonReentrant {
        /***
         *@notice Deposit `_value` LP tokens
         *@param _value Number of tokens to deposit
         *@param _addr Address to deposit for
         */
        if (_addr != msg.sender) {
            require(approved_to_deposit[msg.sender][_addr], "Not approved");
        }

        _checkpoint(_addr);

        if (_value != 0) {
            uint256 _balance = balanceOf[_addr] + _value;
            uint256 _supply = totalSupply + _value;
            balanceOf[_addr] = _balance;
            totalSupply = _supply;

            _update_liquidity_limit(_addr, _balance, _supply);

            assert(template.transferFrom(msg.sender, address(this), _value));
        }
        emit Deposit(_addr, _value);
    }

    function withdraw(uint256 _value) external nonReentrant {
        /***
         *@notice Withdraw `_value` LP tokens
         *@param _value Number of tokens to withdraw
         */
        _checkpoint(msg.sender);

        uint256 _balance = balanceOf[msg.sender] - _value;
        uint256 _supply = totalSupply - _value;
        balanceOf[msg.sender] = _balance;
        totalSupply = _supply;

        _update_liquidity_limit(msg.sender, _balance, _supply);

        require(template.transfer(msg.sender, _value));

        emit Withdraw(msg.sender, _value);
    }

    function integrate_checkpoint() external view returns (uint256) {
        return period_timestamp[period];
    }

    function kill_me() external {
        assert(msg.sender == admin);
        is_killed = !is_killed;
    }

    function commit_transfer_ownership(address _addr) external {
        /***
         *@notice Transfer ownership of GaugeController to `_addr`
         *@param _addr Address to have ownership transferred to
         */
        require(msg.sender == admin, "dev: admin only");
        future_admin = _addr;
        emit CommitOwnership(_addr);
    }

    function accept_transfer_ownership() external {
        /***
         *@notice Accept a transfer of ownership
         *@return bool success
         */
        require(address(msg.sender) == future_admin, "dev: future_admin only");

        admin = future_admin;

        emit AcceptOwnership(admin);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IGaugeController {
    function gauge_types(address _addr)external view returns(uint256);
    function get_voting_escrow()external view returns(address);
    function checkpoint_gauge(address addr)external;
    function gauge_relative_weight(address addr, uint256 time)external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IInsureToken {
    function mint(address _to, uint256 _value)external returns(bool);
    function emergency_mint(uint256 _amountOut, address _to)external;
    function approve(address _spender, uint256 _value)external;
    function rate()external view returns(uint256);
    function future_epoch_time_write() external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IGaugeController.sol";
interface IMinter {
    function insure_token()external view returns(address);
    function controller()external view returns(address);
    function minted(address user, address gauge) external view returns(uint256);
    function gauge_controller()external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IVotingEscrow {
    function get_last_user_slope(address _addr) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    function balanceOf(address _addr, uint256 _t)
        external
        view
        returns (uint256);

    //function balanceOf(address addr)external view returns (uint256);
    function totalSupply(uint256 _t) external view returns (uint256);

    function get_user_point_epoch(address _user)
        external
        view
        returns (uint256);

    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
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