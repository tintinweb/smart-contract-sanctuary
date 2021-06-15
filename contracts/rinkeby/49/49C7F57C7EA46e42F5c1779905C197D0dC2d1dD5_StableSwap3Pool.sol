// SPDX-License-Identifier: UNLICENSED
// Pool for DAI/USDC/USDT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface LPToken {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address account, uint256 amount) external;
}

contract StableSwap3Pool is ReentrancyGuard {
    // This can (and needs to) be changed at compile time
    uint256 constant N_COINS = 3; // <- change

    uint256 constant FEE_DENOMINATOR = 10**10;
    uint256 constant LENDING_PRECISION = 10**18;
    uint256 constant PRECISION = 10**18; // The precision to convert to
    uint256[N_COINS] PRECISION_MUL = [1, 1000000000000, 1000000000000];
    uint256[N_COINS] RATES = [
        1000000000000000000,
        1000000000000000000000000000000,
        1000000000000000000000000000000
    ];
    uint256 constant FEE_INDEX = 2; // Which coin may potentially have fees (USDT)

    uint256 constant MAX_ADMIN_FEE = 10 * 10**9;
    uint256 constant MAX_FEE = 5 * 10**9;
    uint256 constant MAX_A = 10**6;
    uint256 constant MAX_A_CHANGE = 10;

    uint256 constant ADMIN_ACTIONS_DELAY = 3 * 86400;
    uint256 constant MIN_RAMP_TIME = 86400;

    event TokenExchange(
        address indexed buyer,
        uint256 sold_id,
        uint256 tokens_sold,
        uint256 bought_id,
        uint256 tokens_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256[N_COINS] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256[N_COINS] fees,
        uint256 token_supply
    );

    event RemoveLiquidityOne(
        address indexed provider,
        uint256 token_amount,
        uint256 coin_amount
    );

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256[N_COINS] fees,
        uint256 invariant,
        uint256 token_supply
    );

    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);

    event NewAdmin(address indexed admin);

    event CommitNewFee(
        uint256 indexed deadline,
        uint256 fee,
        uint256 admin_fee
    );

    event NewFee(uint256 fee, uint256 admin_fee);

    event RampA(
        uint256 old_A,
        uint256 new_A,
        uint256 initial_time,
        uint256 future_time
    );

    event StopRampA(uint256 A, uint256 t);

    address[N_COINS] public coins;
    uint256[N_COINS] public balances;
    uint256 public fee; // fee * 1e10
    uint256 public admin_fee; // admin_fee * 1e10

    address public owner;
    LPToken token;

    uint256 public initial_A;
    uint256 public future_A;
    uint256 public initial_A_time;
    uint256 public future_A_time;

    uint256 public admin_actions_deadline;
    uint256 public transfer_ownership_deadline;
    uint256 public future_fee;
    uint256 public future_admin_fee;
    address public future_owner;

    bool is_killed;
    uint256 kill_deadline;
    uint256 constant KILL_DEADLINE_DT = 2 * 30 * 86400;

    /// @notice Contract constructor
    /// @param _owner Contract owner address
    /// @param _coins Addresses of ERC20 conracts of coins
    /// @param _pool_token Address of the token representing LP share
    /// @param _A Amplification coefficient multiplied by n * (n - 1)
    /// @param _fee Fee to charge for exchanges
    /// @param _admin_fee Admin fee
    constructor(
        address _owner,
        address[N_COINS] memory _coins,
        address _pool_token,
        uint256 _A,
        uint256 _fee,
        uint256 _admin_fee
    ) {
        for (uint256 i = 0; i < N_COINS; i++) {
            require(_coins[i] != address(0));
        }

        coins = _coins;
        initial_A = _A;
        future_A = _A;
        fee = _fee;
        admin_fee = _admin_fee;
        owner = _owner;
        kill_deadline = block.timestamp + KILL_DEADLINE_DT;
        token = LPToken(_pool_token);
    }

    function _A() internal view returns (uint256) {
        // Handle ramping A up or down
        uint256 t1 = future_A_time;
        uint256 A1 = future_A;

        if (block.timestamp < t1) {
            uint256 A0 = initial_A;
            uint256 t0 = initial_A_time;
            // Expressions in uint256 cannot have negative numbers, thus "if"
            if (A1 > A0) {
                return A0 + ((A1 - A0) * (block.timestamp - t0)) / (t1 - t0);
            } else {
                return A0 - ((A0 - A1) * (block.timestamp - t0)) / (t1 - t0);
            }
        } else {
            // when t1 == 0 or block.timestamp >= t1
            return A1;
        }
    }

    function A() external view returns (uint256) {
        return _A();
    }

    function _xp() internal view returns (uint256[N_COINS] memory) {
        uint256[N_COINS] memory result = RATES;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = (result[i] * balances[i]) / LENDING_PRECISION;
        }
        return result;
    }

    function _xp_mem(uint256[N_COINS] memory _balances)
        internal
        view
        returns (uint256[N_COINS] memory)
    {
        uint256[N_COINS] memory result = RATES;
        for (uint256 i = 0; i < N_COINS; i++) {
            result[i] = (result[i] * _balances[i]) / PRECISION;
        }
        return result;
    }

    function get_D(uint256[N_COINS] memory xp, uint256 amp)
        internal
        pure
        returns (uint256)
    {
        uint256 S = 0;
        for (uint256 i = 0; i < N_COINS; i++) {
            S += xp[i];
        }

        if (S == 0) return 0;

        uint256 Dprev = 0;
        uint256 D = S;
        uint256 Ann = amp * N_COINS;
        for (int128 _i = 0; _i < 255; _i++) {
            uint256 D_P = D;
            for (uint256 i = 0; i < N_COINS; i++) {
                uint256 _x = xp[i];
                D_P = (D_P * D) / (_x * N_COINS); // If division by 0, this will be borked: only withdrawal will work. And that is good
            }
            Dprev = D;
            D =
                ((Ann * S + D_P * N_COINS) * D) /
                ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1) break;
            } else if (Dprev - D <= 1) break;
        }
        return D;
    }

    function get_D_mem(uint256[N_COINS] memory _balances, uint256 amp)
        internal
        view
        returns (uint256)
    {
        return get_D(_xp_mem(_balances), amp);
    }

    function get_virtual_price() external view returns (uint256) {
        // Returns portfolio virtual price (for calculating profit)
        // scaled up by 1e18

        uint256 D = get_D(_xp(), _A());
        // D is in the units similar to DAI (e.g. converted to precision 1e18)
        // When balanced, D = n * x_u - total virtual value of the portfolio
        uint256 token_supply = token.totalSupply();
        return (D * PRECISION) / token_supply;
    }

    /*
    Simplified method to calculate addition or reduction in token supply at
    deposit or withdrawal without taking fees into account (but looking at
    slippage).
    Needed to prevent front-running, not for precise calculations!
    */
    function calc_token_amount(uint256[N_COINS] calldata amounts, bool deposit)
        external
        view
        returns (uint256)
    {
        uint256[N_COINS] memory _balances = balances;
        uint256 amp = _A();
        uint256 D0 = get_D_mem(_balances, amp);
        for (uint256 i = 0; i < N_COINS; i++) {
            if (deposit) _balances[i] += amounts[i];
            else _balances[i] -= amounts[i];
        }
        uint256 D1 = get_D_mem(_balances, amp);
        uint256 token_amount = token.totalSupply();
        uint256 diff = 0;
        if (deposit) diff = D1 - D0;
        else diff = D0 - D1;
        return (diff * token_amount) / D0;
    }

    /// @notice Add liquidity
    /// @param amounts Amount for each coins to be added to liquidity
    /// @param min_mint_amount Minimum LP token mint amount considered by slippage
    function add_liquidity(
        uint256[N_COINS] calldata amounts,
        uint256 min_mint_amount
    ) external nonReentrant() {
        require(!is_killed); // dev: is killed

        uint256[N_COINS] memory fees;
        uint256 _fee = (fee * N_COINS) / (4 * (N_COINS - 1));
        uint256 _admin_fee = admin_fee;
        uint256 amp = _A();

        uint256 token_supply = token.totalSupply();
        // Initial invariant
        uint256 D0 = 0;
        if (token_supply > 0) D0 = get_D_mem(balances, amp);
        uint256[N_COINS] memory new_balances = balances;

        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 in_amount = amounts[i];
            if (token_supply == 0) require(in_amount > 0); // dev: initial deposit requires all coins
            address in_coin = coins[i];

            // Take coins from the sender
            if (in_amount > 0) {
                if (i == FEE_INDEX)
                    in_amount = IERC20(in_coin).balanceOf(address(this));

                // "safeTransferFrom" which works for ERC20s which return bool or not
                IERC20(in_coin).transferFrom(
                    msg.sender,
                    address(this),
                    amounts[i]
                );

                if (i == FEE_INDEX)
                    in_amount =
                        IERC20(in_coin).balanceOf(address(this)) -
                        in_amount;
            }

            new_balances[i] = balances[i] + in_amount;
        }

        // Invariant after change
        uint256 D1 = get_D_mem(new_balances, amp);
        require(D1 > D0);

        // We need to recalculate the invariant accounting for fees
        // to calculate fair user's share
        uint256 D2 = D1;
        if (token_supply > 0) {
            // Only account for fees if we are not the first to deposit
            for (uint256 i = 0; i < N_COINS; i++) {
                uint256 ideal_balance = (D1 * balances[i]) / D0;
                uint256 difference = 0;
                if (ideal_balance > new_balances[i])
                    difference = ideal_balance - new_balances[i];
                else difference = new_balances[i] - ideal_balance;
                fees[i] = (_fee * difference) / FEE_DENOMINATOR;
                balances[i] =
                    new_balances[i] -
                    ((fees[i] * _admin_fee) / FEE_DENOMINATOR);
                new_balances[i] -= fees[i];
            }
            D2 = get_D_mem(new_balances, amp);
        } else balances = new_balances;

        // Calculate, how much pool tokens to mint
        uint256 mint_amount = 0;
        if (token_supply == 0)
            mint_amount = D1; // Take the dust if there was any
        else mint_amount = (token_supply * (D2 - D0)) / D0;

        require(mint_amount >= min_mint_amount, "Slippage screwed you");

        // Mint pool tokens
        token.mint(msg.sender, mint_amount);

        emit AddLiquidity(
            msg.sender,
            amounts,
            fees,
            D1,
            token_supply + mint_amount
        );
    }

    function get_y(
        uint256 i,
        uint256 j,
        uint256 x,
        uint256[N_COINS] memory xp_
    ) internal view returns (uint256) {
        // x in the input is converted to the same price/precision

        require(i != j); // dev: same coin
        require(j >= 0); // dev: j below zero
        require(j < N_COINS); // dev: j above N_COINS

        // should be unreachable, but good for safety
        require(i >= 0);
        require(i < N_COINS);

        uint256 amp = _A();
        uint256 D = get_D(xp_, amp);
        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = amp * N_COINS;

        uint256 _x = 0;
        for (uint256 _i = 0; _i < N_COINS; _i++) {
            if (_i == i) _x = x;
            else if (_i != j) _x = xp_[_i];
            else continue;
            S_ += _x;
            c = (c * D) / (_x * N_COINS);
        }
        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann; // - D
        uint256 y_prev = 0;
        uint256 y = D;
        for (int128 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev) {
                if (y - y_prev <= 1) break;
            } else if (y_prev - y <= 1) break;
        }
        return y;
    }

    /// @notice Get estimated target coin for exchange, used for slippage calculation
    /// @param i source coin index
    /// @param j target coin index
    /// @param dx amount of i coin
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256) {
        // dx and dy in c-units
        uint256[N_COINS] storage rates = RATES;
        uint256[N_COINS] memory xp = _xp();

        uint256 x = xp[i] + ((dx * rates[i]) / PRECISION);
        uint256 y = get_y(i, j, x, xp);
        uint256 dy = ((xp[j] - y - 1) * PRECISION) / rates[j];
        uint256 _fee = (fee * dy) / FEE_DENOMINATOR;
        return dy - _fee;
    }

    /// @notice Get estimated target coin for exchange, used for slippage calculation
    /// @param i source coin index
    /// @param j target coin index
    /// @param dx amount of i coin
    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256) {
        // dx and dy in underlying units
        uint256[N_COINS] memory xp = _xp();
        uint256[N_COINS] storage precisions = PRECISION_MUL;

        uint256 x = xp[i] + dx * precisions[i];
        uint256 y = get_y(i, j, x, xp);
        uint256 dy = (xp[j] - y - 1) / precisions[j];
        uint256 _fee = (fee * dy) / FEE_DENOMINATOR;
        return dy - _fee;
    }

    /// @notice Exchange dx amount of i coin to minimum dy of j coin
    /// @param i source coin index
    /// @param j target coin index
    /// @param dx amount of i coin
    /// @param min_dy minimum amount of j coin to receive for slippage
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external nonReentrant() {
        require(!is_killed); // dev: is killed
        // uint256[N_COINS] storage rates = RATES;
        uint256[N_COINS] storage old_balances = balances;
        uint256[N_COINS] memory xp = _xp_mem(old_balances);

        // Handling an unexpected charge of a fee on transfer (USDT, PAXG)
        uint256 dx_w_fee = dx;
        address input_coin = coins[i];

        if (i == FEE_INDEX)
            dx_w_fee = IERC20(input_coin).balanceOf(address(this));

        // "safeTransferFrom" which works for ERC20s which return bool or not
        IERC20(input_coin).transferFrom(msg.sender, address(this), dx);

        if (i == FEE_INDEX)
            dx_w_fee = IERC20(input_coin).balanceOf(address(this)) - dx_w_fee;

        uint256 x = xp[i] + (dx_w_fee * RATES[i]) / PRECISION;
        uint256 y = get_y(i, j, x, xp);

        uint256 dy = xp[j] - y - 1; // -1 just in case there were some rounding errors
        uint256 dy_fee = (dy * fee) / FEE_DENOMINATOR;

        // Convert all to real units
        dy = ((dy - dy_fee) * PRECISION) / RATES[j];
        require(dy >= min_dy, "Exchange resulted in fewer coins than expected");

        uint256 dy_admin_fee = (dy_fee * admin_fee) / FEE_DENOMINATOR;
        dy_admin_fee = (dy_admin_fee * PRECISION) / RATES[j];

        // Change balances exactly in same way as we change actual ERC20 coin amounts
        balances[i] = old_balances[i] + dx_w_fee;
        // When rounding errors happen, we undercharge admin fee in favor of LP
        balances[j] = old_balances[j] - dy - dy_admin_fee;

        // "safeTransfer" which works for ERC20s which return bool or not
        IERC20(coins[j]).transfer(msg.sender, dy);

        emit TokenExchange(msg.sender, i, dx, j, dy);
    }

    /// @notice Remove liquidity based on number of lp tokens
    /// @param _amount amount of lp tokens to burn
    /// @param min_amounts minimum amount of tokens for each coin to get for slippage
    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] calldata min_amounts
    ) external nonReentrant() {
        uint256 total_supply = token.totalSupply();
        uint256[N_COINS] memory amounts;
        uint256[N_COINS] memory fees; // Fees are unused but we've got them historically in event

        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 value = (balances[i] * _amount) / total_supply;
            require(
                value >= min_amounts[i],
                "Withdrawal resulted in fewer coins than expected"
            );
            balances[i] -= value;
            amounts[i] = value;

            // "safeTransfer" which works for ERC20s which return bool or not
            IERC20(coins[i]).transfer(msg.sender, value);
        }

        token.burnFrom(msg.sender, _amount); // dev: insufficient funds

        emit RemoveLiquidity(msg.sender, amounts, fees, total_supply - _amount);
    }

    /// @notice Remove liquidity based on number of tokens for each coin
    /// @param amounts amount of tokens to withdraw
    /// @param max_burn_amount maximum lp burn amount for slippage
    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256 max_burn_amount
    ) external {
        require(!is_killed); // dev: is killed

        uint256 token_supply = token.totalSupply();
        require(token_supply != 0); // dev: zero total supply
        uint256 _fee = (fee * N_COINS) / (4 * (N_COINS - 1));
        uint256 _admin_fee = admin_fee;
        uint256 amp = _A();

        // uint256[N_COINS] storage old_balances = balances;
        uint256[N_COINS] memory new_balances = balances;
        uint256 D0 = get_D_mem(balances, amp);
        for (uint256 i = 0; i < N_COINS; i++) new_balances[i] -= amounts[i];
        uint256 D1 = get_D_mem(new_balances, amp);
        uint256[N_COINS] memory fees;
        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 ideal_balance = (D1 * balances[i]) / D0;
            uint256 difference = 0;
            if (ideal_balance > new_balances[i])
                difference = ideal_balance - new_balances[i];
            else difference = new_balances[i] - ideal_balance;
            fees[i] = (_fee * difference) / FEE_DENOMINATOR;
            balances[i] =
                new_balances[i] -
                ((fees[i] * _admin_fee) / FEE_DENOMINATOR);
            new_balances[i] -= fees[i];
        }
        uint256 D2 = get_D_mem(new_balances, amp);

        uint256 token_amount = ((D0 - D2) * token_supply) / D0;
        require(token_amount != 0); // dev: zero tokens burned
        token_amount += 1; // In case of rounding errors - make it unfavorable for the "attacker"
        require(token_amount <= max_burn_amount, "Slippage screwed you");

        token.burnFrom(msg.sender, token_amount); // dev: insufficient funds
        for (uint256 i = 0; i < N_COINS; i++) {
            if (amounts[i] != 0) {
                IERC20(coins[i]).transfer(msg.sender, amounts[i]);
            }
        }

        emit RemoveLiquidityImbalance(
            msg.sender,
            amounts,
            fees,
            D1,
            token_supply - token_amount
        );
    }

    function get_y_D(
        uint256 A_,
        uint256 i,
        uint256[N_COINS] memory xp,
        uint256 D
    ) internal view returns (uint256) {
        /*
    Calculate x[i] if one reduces D from being calculated for xp to D
    Done by solving quadratic equation iteratively.
    x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c
    x_1 = (x_1**2 + c) / (2*x_1 + b)
    */
        // x in the input is converted to the same price/precision

        require(i >= 0); // dev: i below zero
        require(i < N_COINS); // dev: i above N_COINS

        uint256 c = D;
        uint256 S_ = 0;
        uint256 Ann = A_ * N_COINS;

        uint256 _x = 0;
        for (uint256 _i = 0; _i < N_COINS; _i++) {
            if (_i != i) _x = xp[_i];
            else continue;
            S_ += _x;
            c = (c * D) / (_x * N_COINS);
        }
        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann;
        uint256 y_prev = 0;
        uint256 y = D;
        for (int128 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - D);
            // Equality with the precision of 1
            if (y > y_prev) {
                if (y - y_prev <= 1) break;
            } else if (y_prev - y <= 1) break;
        }
        return y;
    }

    function _calc_withdraw_one_coin(uint256 _token_amount, uint256 i)
        internal
        view
        returns (uint256, uint256)
    {
        // First, need to calculate
        // * Get current D
        // * Solve Eqn against y_i for D - _token_amount
        uint256 amp = _A();
        uint256 _fee = (fee * N_COINS) / (4 * (N_COINS - 1));
        uint256[N_COINS] storage precisions = PRECISION_MUL;
        uint256 total_supply = token.totalSupply();

        uint256[N_COINS] memory xp = _xp();

        uint256 D0 = get_D(xp, amp);
        uint256 D1 = D0 - (_token_amount * D0) / total_supply;
        uint256[N_COINS] memory xp_reduced = xp;

        uint256 new_y = get_y_D(amp, i, xp, D1);
        uint256 dy_0 = (xp[i] - new_y) / precisions[i]; // w/o fees

        for (uint256 j = 0; j < N_COINS; j++) {
            uint256 dx_expected = 0;
            if (j == i) dx_expected = (xp[j] * D1) / D0 - new_y;
            else dx_expected = xp[j] - (xp[j] * D1) / D0;
            xp_reduced[j] -= (_fee * dx_expected) / FEE_DENOMINATOR;
        }

        uint256 dy = xp_reduced[i] - get_y_D(amp, i, xp_reduced, D1);
        dy = (dy - 1) / precisions[i]; // Withdraw less to account for rounding errors

        return (dy, dy_0 - dy);
    }

    /// @notice Returns the expected amount for removing liquidity
    /// @param _token_amount amount of tokens to remove
    /// @param i token index
    function calc_withdraw_one_coin(uint256 _token_amount, uint256 i)
        external
        view
        returns (uint256)
    {
        (uint256 dy, ) = _calc_withdraw_one_coin(_token_amount, i);
        return dy;
    }

    /// @notice Remove _amount of liquidity all in a form of coin i
    /// @param _token_amount amount of tokens to remove
    /// @param i token index want to withdraw
    /// @param min_amount Minimum output token amount considered by slippage
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external nonReentrant() {
        require(!is_killed); // dev: is killed

        uint256 dy = 0;
        uint256 dy_fee = 0;
        (dy, dy_fee) = _calc_withdraw_one_coin(_token_amount, i);
        require(dy >= min_amount, "Not enough coins removed");

        balances[i] -= (dy + (dy_fee * admin_fee) / FEE_DENOMINATOR);
        token.burnFrom(msg.sender, _token_amount); // dev: insufficient funds

        // "safeTransfer" which works for ERC20s which return bool or not
        IERC20(coins[i]).transfer(msg.sender, dy);

        emit RemoveLiquidityOne(msg.sender, _token_amount, dy);
    }

    // Admin functions

    function ramp_A(uint256 _future_A, uint256 _future_time) external {
        require(msg.sender == owner); // dev: only owner
        require(block.timestamp >= initial_A_time + MIN_RAMP_TIME);
        require(_future_time >= block.timestamp + MIN_RAMP_TIME); // dev: insufficient time

        uint256 _initial_A = _A();
        require(_future_A > 0 && _future_A < MAX_A);
        require(
            ((_future_A >= _initial_A) &&
                (_future_A <= _initial_A * MAX_A_CHANGE)) ||
                ((_future_A < _initial_A) &&
                    (_future_A * MAX_A_CHANGE >= _initial_A))
        );
        initial_A = _initial_A;
        future_A = _future_A;
        initial_A_time = block.timestamp;
        future_A_time = _future_time;

        emit RampA(_initial_A, _future_A, block.timestamp, _future_time);
    }

    function stop_ramp_A() external {
        require(msg.sender == owner); // dev: only owner

        uint256 current_A = _A();
        initial_A = current_A;
        future_A = current_A;
        initial_A_time = block.timestamp;
        future_A_time = block.timestamp;
        // now (block.timestamp < t1) is always False, so we return saved A

        emit StopRampA(current_A, block.timestamp);
    }

    function commit_new_fee(uint256 new_fee, uint256 new_admin_fee) external {
        require(msg.sender == owner); // dev: only owner
        require(admin_actions_deadline == 0); // dev: active action
        require(new_fee <= MAX_FEE); // dev: fee exceeds maximum
        require(new_admin_fee <= MAX_ADMIN_FEE); // dev: admin fee exceeds maximum

        uint256 _deadline = block.timestamp + ADMIN_ACTIONS_DELAY;
        admin_actions_deadline = _deadline;
        future_fee = new_fee;
        future_admin_fee = new_admin_fee;

        emit CommitNewFee(_deadline, new_fee, new_admin_fee);
    }

    function apply_new_fee() external {
        require(msg.sender == owner); // dev: only owner
        require(block.timestamp >= admin_actions_deadline); // dev: insufficient time
        require(admin_actions_deadline != 0); // dev: no active action

        admin_actions_deadline = 0;
        uint256 _fee = future_fee;
        uint256 _admin_fee = future_admin_fee;
        fee = _fee;
        admin_fee = _admin_fee;

        emit NewFee(_fee, _admin_fee);
    }

    function revert_new_parameters() external {
        require(msg.sender == owner); // dev: only owner

        admin_actions_deadline = 0;
    }

    function commit_transfer_ownership(address _owner) external {
        require(msg.sender == owner); // dev: only owner
        require(transfer_ownership_deadline == 0); // dev: active transfer

        uint256 _deadline = block.timestamp + ADMIN_ACTIONS_DELAY;
        transfer_ownership_deadline = _deadline;
        future_owner = _owner;

        emit CommitNewAdmin(_deadline, _owner);
    }

    function apply_transfer_ownership() external {
        require(msg.sender == owner); // dev: only owner
        require(block.timestamp >= transfer_ownership_deadline); // dev: insufficient time
        require(transfer_ownership_deadline != 0); // dev: no active transfer

        transfer_ownership_deadline = 0;
        address _owner = future_owner;
        owner = _owner;

        emit NewAdmin(_owner);
    }

    function revert_transfer_ownership() external {
        require(msg.sender == owner); // dev: only owner

        transfer_ownership_deadline = 0;
    }

    function admin_balances(uint256 i) external view returns (uint256) {
        return IERC20(coins[i]).balanceOf(address(this)) - balances[i];
    }

    function withdraw_admin_fees() external {
        require(msg.sender == owner); // dev: only owner

        for (uint256 i = 0; i < N_COINS; i++) {
            address c = coins[i];
            uint256 value = IERC20(c).balanceOf(address(this)) - balances[i];
            if (value > 0)
                // "safeTransfer" which works for ERC20s which return bool or not
                IERC20(c).transfer(msg.sender, value);
        }
    }

    function donate_admin_fees() external {
        require(msg.sender == owner); // dev: only owner
        for (uint256 i = 0; i < N_COINS; i++)
            balances[i] = IERC20(coins[i]).balanceOf(address(this));
    }

    function kill_me() external {
        require(msg.sender == owner); // dev: only owner
        require(kill_deadline > block.timestamp); // dev: deadline has passed
        is_killed = true;
    }

    function unkill_me() external {
        require(msg.sender == owner); // dev: only owner
        is_killed = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}