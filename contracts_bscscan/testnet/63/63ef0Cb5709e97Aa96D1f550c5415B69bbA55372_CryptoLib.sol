// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import "./interfaces/IWETH.sol";
import "./interfaces/IFactory.sol";

import "./tokens/LPToken.sol";

library CryptoLib {
    using SafeERC20 for IERC20;

    uint256 public constant N_COINS = 2;
    struct SwapStorage {
        uint256 initial_A_gamma;
        uint256 initial_A_gamma_time;

        uint256 allowed_extra_profit;
        uint256 adjustment_step;
        uint256 ma_half_time;

        uint256 D;
        uint256 xcp_profit;
        uint256 xcp_profit_a;
        bool not_adjusted;
        FeeStorage fees;
        CryptoStorage crypto;
        FutureStorage future;
    }

    struct FeeStorage {
        uint256 mid_fee;
        uint256 out_fee;
        uint256 admin_fee;
        uint256 fee_gamma;
        address admin_fee_receiver;
    }

    struct CryptoStorage {
        LPToken lp_token;
        uint256 [N_COINS] precisions;
        uint256[N_COINS] balances;
        address[N_COINS] coins;
        uint256 price_scale;
        uint256 price_oracle;
        uint256 last_prices;
        uint256 last_prices_timestamp;
        uint256 virtual_price;
    }

    struct FutureStorage {
        uint256 future_A_gamma;
        uint256 future_A_gamma_time;
        uint256 future_fee_gamma;
        uint256 future_adjustment_step;
        uint256 future_ma_half_time;
        uint256 future_mid_fee;
        uint256 future_out_fee;
        uint256 future_admin_fee;
        uint256 future_allowed_extra_profit;
    }

    uint256 public constant PRECISION = 10**18;
    uint256 public constant A_MULTIPLIER = 10000;

    uint256 constant KILL_DEADLINE_DT = 2 * 30 * 86400;

    uint256 constant MIN_A = N_COINS**N_COINS * A_MULTIPLIER / 100;
    uint256 constant MAX_A = 1000 * A_MULTIPLIER * N_COINS**N_COINS;

    uint256 constant MIN_GAMMA = 10**10;
    uint256 constant MAX_GAMMA = 5 * 10**16;
    uint256 constant NOISE_FEE = 10**5;

    struct ClaimAdminFeeInfo {
        address receiver;
        uint256 xcp_profit;
        uint256 xcp_profit_a;
        uint256 vprice;
        uint256 fees;
        uint256 total_supply;
    }

    struct TweakPriceInfo {
        uint256 norm;
        uint256 last_prices_timestamp;
        uint256 D_unadjusted;
        uint256 total_supply;
        uint256 old_xcp_profit;
        uint256 old_virtual_price;
        uint256 xcp_profit;
        uint256 virtual_price;
        uint256 D;
        uint256 ma_half_time;
        uint256 alpha;
        uint256 dx_price;
        uint256 price_oracle;
        uint256 last_prices;
        uint256 price_scale;
        uint256 p_new;
    }

    struct CalcWithdrawOneCoinInfo {
        uint256 D;
        uint256 D0;
        uint256 token_supply;
        uint256 price_scale_i;
        uint256 fee;
        uint256 dD;
        uint256 y;
        uint256 dy;
        uint256 p;
    }

    struct ExchangeInfo {
        uint256 ix;
        uint256 p;
        uint256 dy;
        uint256 y;
        uint256 prec_i;
        uint256 prec_j;
        uint256 x0;
        uint256 x1;
        uint256 t;
        uint256 _dx;
        uint256 _dy;
        uint256 price_scale;
    }

    struct AddLiquidityInfo {
        uint256 A;
        uint256 gamma;
        uint256 d_token;
        uint256 d_token_fee;
        uint256 token_supply;
        uint256 old_D;
        uint256 D;
        uint256 t;
        uint256 p;
        uint256 price_scale;
    }

    struct NewtonYInfo {
        uint256 y;
        uint256 K0_i;
        uint256 convergence_limit;
        uint256 y_prev;
        uint256 K0;
        uint256 S;
        uint256 _g1k0;
        uint256 mul1;
        uint256 mul2;
        uint256 yfprime;
        uint256 _dyfprime;
        uint256 fprime;
        uint256 y_minus;
        uint256 y_plus;
        uint256 diff;
        uint256 x_j;
    }

    function initDefaultParameters(SwapStorage storage self) external {
        uint256 A = (0.2 * 3 ** 3 * 10000);
        uint256 gamma = 3.5e-3 * 1e18;
        uint256 mid_fee = 1.1e-3 * 1e10;
        uint256 out_fee = 4.5e-3 * 1e10;
        uint256 allowed_extra_profit = 2 * 10**12;
        uint256 fee_gamma = 5e-4 * 1e18;
        uint256 adjustment_step = 0.00049 * 1e18;
        uint256 admin_fee = 5 * 10**9;
        uint256 ma_half_time = 600;

        uint256 A_gamma = shift(self, A, 128);
        A_gamma = A_gamma | gamma;
        self.future.future_A_gamma = A_gamma;

        self.fees.mid_fee = mid_fee;
        self.fees.out_fee = out_fee;
        self.fees.fee_gamma = fee_gamma;
        self.fees.admin_fee = admin_fee;

        self.initial_A_gamma = A_gamma;
        self.allowed_extra_profit = allowed_extra_profit;
        self.adjustment_step = adjustment_step;
        self.ma_half_time = ma_half_time;
        self.xcp_profit_a = 10 ** 18;

        self.crypto.last_prices_timestamp = block.timestamp;
    }

    /* ========== MATH FUNCTIONS ========== */

    function geometric_mean(uint256[N_COINS] memory unsorted_x, bool sort) internal pure returns(uint256) {
        uint256[N_COINS] memory x = unsorted_x;
        if (sort == true && x[0] < x[1]) {
            x = [unsorted_x[1], unsorted_x[0]];
        }
        uint256 D = x[0];
        uint256 diff = 0;
        for (uint256 i = 0; i < 255; i++) {
            uint256 D_prev = D;
            D = (D + x[0] * x[1] / D) / N_COINS;
            if (D > D_prev) {
                diff = D - D_prev;
            } else {
                diff = D_prev - D;
            }
            if (diff <= 1 || diff * 10**18 < D) {
                return D;
            }

        }
        revert('Did not converge');
    }

    function newton_D(uint256 ANN, uint256 gamma, uint256[N_COINS] memory x_unsorted) internal pure returns(uint256) {
        /*
            Finding the invariant using Newton method.
            ANN is higher by the factor A_MULTIPLIER
            ANN is already A * N**N

            Currently uses 60k gas
        */
        require(ANN > MIN_A - 1 && ANN < MAX_A + 1, 'unsafe values A');
        require(gamma > MIN_GAMMA - 1 && gamma < MAX_GAMMA + 1, 'unsafe values gamma');
        uint256[N_COINS] memory x = x_unsorted;
        if (x[0] < x[1]) {
            x = [x_unsorted[1], x_unsorted[0]];
        }
        require(x[0] > 10**9 - 1 && x[0] < 10**15 * 10**18 + 1, 'unsafe value x[0]');
        require(x[1] * 10**18 / x[0] > 10**14 - 1, 'unsafe values x[i]');

        uint256 D = N_COINS * geometric_mean(x, false);
        uint256 S = x[0] + x[1];

        for (uint256 i = 0 ; i < 255; i++) {
            uint256 D_prev = D;
            uint256 K0 = (10**18 * N_COINS**2) * x[0] / D * x[1] / D;

            uint256 _g1k0 = gamma + 10**18;
            if (_g1k0 > K0) {
                _g1k0 = _g1k0 - K0 + 1;
            } else {
                _g1k0 = K0 - _g1k0 + 1;
            }
            //          D / (A * N**N) * _g1k0**2 / gamma**2
            uint256 mul1 = 10**18 * D / gamma * _g1k0 / gamma * _g1k0 * A_MULTIPLIER / ANN;
            //          2*N*K0 / _g1k0
            uint256 mul2 = (2 * 10**18) * N_COINS * K0 / _g1k0;

            uint256 neg_fprime = (S + S * mul2 / 10**18) + mul1 * N_COINS / K0 - mul2 * D / 10**18;

            //            D -= f / fprime
            uint256 D_plus = D * (neg_fprime + S) / neg_fprime;
            uint256 D_minus = D * D / neg_fprime;
            if (10**18 > K0) {
                D_minus += D * (mul1 / neg_fprime) / 10**18 * (10**18 - K0) / K0;
            } else {
                D_minus -= D * (mul1 / neg_fprime) / 10**18 * (K0 - 10**18) / K0;
            }

            if (D_plus > D_minus) {
                D = D_plus - D_minus;
            } else {
                D = (D_minus - D_plus) / 2;
            }
            uint256 diff = 0;
            if (D > D_prev) {
                diff = D - D_prev;
            } else {
                diff = D_prev - D;
            }
            if (diff * 10**14 < max(10**16, D)) {
                for (uint256 j = 0; j < N_COINS; j++) {
                    uint256 frac = x[j] * 10**18 / D;
                    require(frac > 10**16 - 1 && frac < 10**20 + 1, 'unsafe values x[i]');
                }
                return D;
            }
        }
        revert('Dig not converge');
    }

    function newton_y(uint256 ANN, uint256 gamma, uint256[N_COINS] memory x, uint256 D, uint256 i) internal pure returns(uint256) {
        /*
           Calculating x[i] given other balances x[0..N_COINS-1] and invariant D
           ANN = A * N**N
       */
        require(ANN > MIN_A - 1 && ANN < MAX_A + 1, 'unsafe values A');
        require(gamma > MIN_GAMMA - 1 && gamma < MAX_GAMMA + 1, 'unsafe values gamma');
        require(D > 10**17 - 2 && D < 10**15 * 10**18 + 1, 'unsafe values D');

        NewtonYInfo memory v;
        v.x_j = x[1 - i];
        v.y = D**2 / (v.x_j * N_COINS**2);
        v.K0_i = (10**18 * N_COINS) * v.x_j / D;

        require(v.K0_i > 10**16*N_COINS - 1 && v.K0_i < 10**20*N_COINS + 1, 'unsafe value x[i]');


        v.convergence_limit = max(max(v.x_j / 10**14, D / 10**14), 100);


        for (uint256 j = 0; j < 255; j++) {
            v.y_prev = v.y;
            v.K0 = v.K0_i * v.y * N_COINS / D;
            v.S = v.x_j + v.y;

            v._g1k0 = gamma + 10**18;
            if (v._g1k0 > v.K0) {
                v._g1k0 = v._g1k0 - v.K0 + 1;
            } else {
                v._g1k0 = v.K0 - v._g1k0 + 1;
            }
            //D / (A * N**N) * _g1k0**2 / gamma**2
            v.mul1 = 10**18 * D / gamma * v._g1k0 / gamma * v._g1k0 * A_MULTIPLIER / ANN;

            //2*K0 / _g1k0
            v.mul2 = 10**18 + (2 * 10**18) * v.K0 / v._g1k0;

            v.yfprime = 10**18 * v.y + v.S * v.mul2 + v.mul1;
            v._dyfprime = D * v.mul2;
            if (v.yfprime < v._dyfprime) {
                v.y = v.y_prev / 2;
                continue;
            } else {
                v.yfprime -= v._dyfprime;
            }
            v.fprime = v.yfprime / v.y;
            //            y -= f / f_prime;  y = (y * fprime - f) / fprime
            //            y = (yfprime + 10**18 * D - 10**18 * S) // fprime + mul1 // fprime * (10**18 - K0) // K0
            v.y_minus = v.mul1 / v.fprime;
            v.y_plus = (v.yfprime + 10**18 * D) / v.fprime + v.y_minus * 10**18 / v.K0;
            v.y_minus += 10**18 * v.S / v.fprime;

            if (v.y_plus < v.y_minus) {
                v.y = v.y_prev / 2;
            } else {
                v.y = v.y_plus - v.y_minus;
            }

            v.diff = 0;
            if (v.y > v.y_prev) {
                v.diff = v.y - v.y_prev;
            } else {
                v.diff = v.y_prev - v.y;
            }
            if (v.diff < max(v.convergence_limit, v.y / 10**14)) {
                uint256 frac = v.y * 10**18 / D;
                require(frac > 10**16 - 1 && frac < 10**20 + 1, 'unsafe value for y');
                return v.y;
            }
        }
        revert('Did not converge');
    }

    function halfpow(uint256 power, uint256 precision) internal pure returns(uint256) {
        /*
            1e18 * 0.5 ** (power/1e18)
            Inspired by: https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol#L128
        */
        uint256 intpow = power / 10**18;
        uint256 otherpow = power - intpow * 10**18;
        if (intpow > 59) {
            return 0;
        }
        uint256 result = 10**18 / (2**intpow);
        if (otherpow == 0) {
            return result;
        }
        uint256 term = 10**18;
        uint256 x = 5 * 10**17;
        uint256 S = 10**18;
        bool neg = false;

        for (uint256 i = 1; i < 256; i++) {
            uint256 K = i * 10**18;
            uint256 c = K - 10**18;
            if (otherpow > c) {
                c = otherpow - c;
                neg = !neg;
            } else {
                c -= otherpow;
            }
            term = term * (c * x / 10**18) / K;
            if (neg) {
                S -= term;
            } else {
                S += term;
            }
            if (term < precision) {
                return result * S / 10**18;
            }
        }
        revert('Did not converge');
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function mint(CryptoStorage storage crypto, address to, uint256 amount) internal {
        crypto.lp_token.mint(to, amount);
    }

    function mint_relative(CryptoStorage storage crypto, address to, uint256 frac) internal returns(uint256) {
        uint256 supply = total_supply(crypto);
        uint256 d_supply = supply * frac / 10**18;
        if (d_supply > 0) {
            mint(crypto, to, d_supply);
        }
        return d_supply;
    }

    function burn(CryptoStorage memory crypto, address from, uint256 amount) internal {
        crypto.lp_token.burn(from, amount);
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) {
            return b;
        }
        return a;
    }

    function shift(SwapStorage storage self, uint256 x, int256 y) public pure returns(uint256) {
        if (y < 0) {
            return x >> uint256(-y);
        }
        return x << uint256(y);
    }

    function total_supply(CryptoStorage storage crypto) internal view returns(uint256) {
        return crypto.lp_token.totalSupply();
    }

    function xp(SwapStorage storage self) internal view returns(uint256[N_COINS] memory) {
        return [self.crypto.balances[0] * self.crypto.precisions[0], self.crypto.balances[1] * self.crypto.precisions[1] * self.crypto.price_scale / PRECISION];
    }

    function _A_gamma(SwapStorage storage self) public view returns(uint256[2] memory) {
        uint256 t1 = self.future.future_A_gamma_time;

        uint256 A_gamma_1 = self.future.future_A_gamma;
        uint256 gamma1 = A_gamma_1 & (2**128 - 1);
        uint256 A1 = shift(self, A_gamma_1, -128);

        if (block.timestamp < t1) {
            //# handle ramping up and down of A
            uint256 A_gamma_0 = self.initial_A_gamma;
            uint256 t0 = self.initial_A_gamma_time;

            //            # Less readable but more compact way of writing and converting to uint256
            //            # gamma0: uint256 = bitwise_and(A_gamma_0, 2**128-1)
            //            # A0: uint256 = shift(A_gamma_0, -128)
            //            # A1 = A0 + (A1 - A0) * (block.timestamp - t0) / (t1 - t0)
            //            # gamma1 = gamma0 + (gamma1 - gamma0) * (block.timestamp - t0) / (t1 - t0)
            t1 -= t0;
            t0 = block.timestamp - t0;
            A1 = (shift(self, A_gamma_0, -128)  * (t1 - t0) + A1 * t0) / t1;
            gamma1 = (A_gamma_0 & (2**128 - 1) * (t1 - t0) + gamma1 * t0)/ t1;
        }
        return [A1, gamma1];
    }

    function _fee(FeeStorage storage fee, uint256[N_COINS] memory xp) internal view returns(uint256) {
        uint256 f = xp[0] + xp[1] ;
        uint256 fee_gamma = fee.fee_gamma;
        f = fee_gamma * 10**18 / (
        fee_gamma + 10**18 - (10**18 * N_COINS**N_COINS) * xp[0] / f * xp[1] / f
        );
        return (fee.mid_fee * f + fee.out_fee * (10**18 - f)) / (10**18);
    }

    function fee(SwapStorage storage self) external view returns(uint256) {
        return _fee(self.fees, xp(self));
    }

    function get_xcp(SwapStorage storage self, uint256 D) internal view returns(uint256) {
        uint256[N_COINS] memory x = [D / N_COINS, D * PRECISION / (self.crypto.price_scale * N_COINS)];
        return geometric_mean(x, true);
    }

    function _claim_admin_fees(SwapStorage storage self) internal {
        ClaimAdminFeeInfo memory v = ClaimAdminFeeInfo({
            receiver : self.fees.admin_fee_receiver,
            xcp_profit : self.xcp_profit,
            xcp_profit_a : self.xcp_profit_a,
            vprice : self.crypto.virtual_price,
            fees : 0,
            total_supply : 0
            });
        address[N_COINS] memory _coins = self.crypto.coins;
        uint256[2] memory A_gamma = _A_gamma(self);

        for (uint256 i = 0; i < N_COINS; i++) {
            self.crypto.balances[i] = IERC20(_coins[i]).balanceOf(address(this));
        }

        v.vprice = self.crypto.virtual_price;

        if (v.xcp_profit > v.xcp_profit_a) {
            v.fees = (v.xcp_profit - v.xcp_profit_a) * self.fees.admin_fee / (2 * 10**10);
            if (v.fees > 0) {
                if (v.receiver != address(0)) {
                    uint256 frac = v.vprice * 10**18;
                    uint256 claimed = mint_relative(self.crypto, v.receiver, frac);
                    v.xcp_profit -= v.fees * 2;
                    self.xcp_profit = v.xcp_profit;
                    emit ClaimAdminFee(v.receiver, claimed);
                }
            }
        }

        v.total_supply = total_supply(self.crypto);
        uint256 D = newton_D(A_gamma[0], A_gamma[1], xp(self));
        self.D = D;
        self.crypto.virtual_price = 10**18 * get_xcp(self, D) / v.total_supply;
        if (v.xcp_profit > v.xcp_profit_a) {
            self.xcp_profit_a = v.xcp_profit;
        }
    }

    function tweak_price(SwapStorage storage self, uint256[2] memory A_gamma, uint256[N_COINS] memory _xp, uint256 p_i, uint256 new_D) internal{
        uint256[N_COINS] memory xp;
        TweakPriceInfo memory v;
        v.price_oracle = self.crypto.price_oracle;
        v.last_prices = self.crypto.last_prices;
        v.price_scale = self.crypto.price_scale;
        v.p_new = 0;
        v.last_prices_timestamp = self.crypto.last_prices_timestamp;

        if (v.last_prices_timestamp < block.timestamp) {
            //            # MA update required
            v.ma_half_time = self.ma_half_time;
            v.alpha = halfpow((block.timestamp - v.last_prices_timestamp) * (10**18) / v.ma_half_time, 10**10);
            v.price_oracle = (v.last_prices * (10**18 - v.alpha) + v.price_oracle * v.alpha) / 10**18;
            self.crypto.price_oracle = v.price_oracle;
            self.crypto.last_prices_timestamp = block.timestamp;
        }

        v.D_unadjusted = new_D;
        if (new_D == 0) {
            //# We will need this a few times (35k gas)
            v.D_unadjusted = newton_D(A_gamma[0], A_gamma[1], _xp);
        }

        if (p_i > 0) {
            v.last_prices = p_i;
        } else {
            uint256[N_COINS] memory __xp = _xp;
            v.dx_price = __xp[0] / 10**6;
            __xp[0] += v.dx_price;
            v.last_prices = v.price_scale * v.dx_price / (_xp[1] - newton_y(A_gamma[0], A_gamma[1], __xp, v.D_unadjusted, 1));
        }
        self.crypto.last_prices = v.last_prices;

        v.total_supply = total_supply(self.crypto);
        v.old_xcp_profit = self.xcp_profit;
        v.old_virtual_price = self.crypto.virtual_price;

        //        # Update profit numbers without price adjustment first
        xp = [v.D_unadjusted / N_COINS, v.D_unadjusted * PRECISION / (N_COINS * v.price_scale)];

        v.xcp_profit = 10**18;
        v.virtual_price = 10**18;

        if (v.old_virtual_price > 0) {
            uint256 xcp = geometric_mean(xp, true);
            v.virtual_price = 10**18 * xcp / v.total_supply;
            v.xcp_profit = v.old_xcp_profit * v.virtual_price / v.old_virtual_price;
            uint256 t = self.future.future_A_gamma_time;
            if (v.virtual_price < v.old_virtual_price && t == 0) {
                revert('Loss');
            }
            if (t == 1) {
                self.future.future_A_gamma_time = 0;
            }
        }
        self.xcp_profit = v.xcp_profit;
        bool needs_adjustment = self.not_adjusted;
        if (!needs_adjustment && v.virtual_price * 2 - 10**18 > v.xcp_profit + 2 * self.allowed_extra_profit) {
            needs_adjustment = true;
            self.not_adjusted = true;
        }

        if (needs_adjustment) {
            uint256 adjustment_step = self.adjustment_step;
            v.norm = v.price_oracle * 10**18 / v.price_scale;
            if (v.norm > 10**18) {
                v.norm -= 10**18;
            } else {
                v.norm = 10**18 - v.norm;
            }

            if ((v.norm > adjustment_step) && (v.old_virtual_price > 0)) {
                v.p_new =  (v.price_scale * (v.norm - adjustment_step) + adjustment_step * v.price_oracle) / v.norm;
                xp = [_xp[0], _xp[1] * v.p_new / v.price_scale];

                //            # Calculate "extended constant product" invariant xCP and virtual price
                v.D = newton_D(A_gamma[0], A_gamma[1], xp);
                xp = [v.D / N_COINS, v.D * PRECISION / (N_COINS * v.p_new)];
                //            # We reuse old_virtual_price here but it's not old anymore
                v.old_virtual_price = 10**18 * geometric_mean(xp, true) / v.total_supply;
                //            # Proceed if we've got enough profit
                if ((v.old_virtual_price > 10**18) && (2 * (v.old_virtual_price - 10**18) > v.xcp_profit - 10**18)) {
                    self.crypto.price_scale = v.p_new;
                    self.D = v.D;
                    self.crypto.virtual_price = v.old_virtual_price;
                    return;
                } else {
                    self.not_adjusted = false;
                    self.D = v.D_unadjusted;
                    self.crypto.virtual_price = v.virtual_price;
                    _claim_admin_fees(self);
                    return;
                }
            }
        }
        //        # If we are here, the price_scale adjustment did not happen
        //        # Still need to update the profit counter and D
        self.D = v.D_unadjusted;
        self.crypto.virtual_price = v.virtual_price;
    }

    function _calc_token_fee(SwapStorage storage self, uint256[N_COINS] memory amounts, uint256[N_COINS] memory xp) internal view returns(uint256) {
        //        # fee = sum(amounts_i - avg(amounts)) * fee' / sum(amounts)
        uint256 fee = _fee(self.fees, xp) * N_COINS / (4 * (N_COINS - 1));
        uint256 S = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            S += amounts[i];
        }
        uint256 avg = S / N_COINS;
        uint256 Sdiff = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > avg) {
                Sdiff += amounts[i] - avg;
            } else {
                Sdiff += avg - amounts[i];
            }
        }
        return fee * Sdiff / S + NOISE_FEE;
    }

    function _calc_withdraw_one_coin(SwapStorage storage self, uint256[2] memory A_gamma, uint256 token_amount, uint256 i, bool update_D, bool calc_price)
    internal view returns (uint256, uint256, uint256, uint256[N_COINS] memory) {
        CalcWithdrawOneCoinInfo memory v;
        v.token_supply = total_supply(self.crypto);
        require(token_amount <= v.token_supply && i < N_COINS);

        uint256[N_COINS] memory xx = self.crypto.balances;
        uint256[N_COINS] memory xp;
        uint256[N_COINS] memory precisions = self.crypto.precisions;

        v.price_scale_i = self.crypto.price_scale * precisions[1];
        xp = [xx[0] * precisions[0], xx[1] * v.price_scale_i / PRECISION];
        if (i == 0) {
            v.price_scale_i = PRECISION * precisions[0];
        }

        if (update_D) {
            v.D0 = newton_D(A_gamma[0], A_gamma[1], xp);
        } else {
            v.D0 = self.D;
        }
        v.D = v.D0;

        v.fee = _fee(self.fees, xp);
        v.dD = token_amount * v.D / v.token_supply;
        v.D -= (v.dD - (v.fee * v.dD / (2 * 10**10) + 1));
        v.y = newton_y(A_gamma[0], A_gamma[1], xp, v.D, i);
        v.dy = (xp[i] - v.y) * PRECISION / v.price_scale_i;
        xp[i] = v.y;

        //        # Price calc
        v.p = 0;
        if (calc_price && v.dy > 10**5 && token_amount > 10**5) {
            //            # p_i = dD / D0 * sum'(p_k * x_k) / (dy - dD / D0 * y0)
            uint256 S = 0;
            uint256 precision = precisions[0];
            if (i == 1) {
                S = xx[0] * precisions[0];
                precision = precisions[1];
            } else {
                S = xx[1] * precisions[1];
            }
            S = S * v.dD / v.D0;
            v.p = S * PRECISION / (v.dy * precision - v.dD * xx[i] * precision / v.D0);
            if (i == 0) {
                v.p = (10**18)**2 / v.p;
            }
        }
        return (v.dy, v.p, v.D, xp);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function get_A(SwapStorage storage self) external view returns (uint256) {
        return _A_gamma(self)[0];
    }

    function get_gamma(SwapStorage storage self) external view returns (uint256) {
        return _A_gamma(self)[1];
    }

    function get_virtual_price(SwapStorage storage self) external view returns(uint256) {
        return 10**18 * get_xcp(self, self.D) / total_supply(self.crypto);
    }

    function exchange(SwapStorage storage self, uint256 i, uint256 j, uint256 dx, uint256 min_dy)
    external returns(uint256) {
        require(i != j && i < N_COINS && j < N_COINS && dx > 0);
        ExchangeInfo memory v;
        uint256[2] memory A_gamma = _A_gamma(self);
        uint256[N_COINS] memory xp = self.crypto.balances;
        address[N_COINS] memory coins = self.crypto.coins;
        IERC20(coins[i]).transferFrom(msg.sender, address(this), dx);
        v.ix = j;

        if (true) { //# scope to reduce size of memory when making internal calls later
            v.y = xp[j];
            v.x0 = xp[i];
            xp[i] = v.x0 + dx;
            self.crypto.balances[i] = xp[i];
            v.prec_i = 0;
            v.prec_j = 0;
            v.price_scale = self.crypto.price_scale;

            uint256[N_COINS] memory precisions = self.crypto.precisions;
            xp = [xp[0] * precisions[0], xp[1] * v.price_scale * precisions[1] / PRECISION];

            v.prec_i = precisions[0];
            v.prec_j = precisions[1];
            if (i == 1) {
                v.prec_i = precisions[1];
                v.prec_j = precisions[0];
            }
            if (true) {
                v.t = self.future.future_A_gamma_time;
                if (v.t > 0) {
                    v.x0 *= v.prec_i;
                    if (i > 0) {
                        v.x0 = v.x0 * v.price_scale / PRECISION;
                    }
                    v.x1 = xp[i];
                    xp[i] = v.x0;
                    self.D = newton_D(A_gamma[0], A_gamma[1], xp);
                    xp[i] = v.x1;
                    if (block.timestamp >= v.t) {
                        self.future.future_A_gamma_time = 1;
                    }
                }
            }
            v.dy = xp[j] - newton_y(A_gamma[0], A_gamma[1], xp, self.D, j);
            //            # Not defining new "y" here to have less variables / make subsequent calls cheaper
            xp[j] -= v.dy;
            v.dy -= 1;
            if (j > 0) {
                v.dy = v.dy * PRECISION / v.price_scale;
            }
            v.dy /= v.prec_j;
            v.dy -= _fee(self.fees, xp) * v.dy / 10**10;
            require(v.dy >= min_dy, "Slippage");
            v.y -= v.dy;
            self.crypto.balances[j] = v.y;
            //            # assert might be needed for some tokens - removed one to save bytespace

            IERC20(coins[j]).transfer(msg.sender, v.dy);
            v.y = v.y * v.prec_j;
            if (j > 0) {
                v.y = v.y * v.price_scale / PRECISION;
            }
            xp[j] = v.y;
            //            # Calculate price
            if (dx > 10**5 && v.dy > 10**5) {
                v._dx = dx * v.prec_i;
                v._dy = v.dy * v.prec_j;
                if (i == 0) {
                    v.p = v._dx * 10**18 / v._dy;
                } else {
                    v.p = v._dy * 10**18 / v._dx;
                    v.ix = i;
                }
            }
        }
        tweak_price(self, A_gamma, xp, v.p, 0);
        emit TokenExchange(msg.sender, i, dx, j, v.dy);
        return v.dy;
    }

    function get_dy(SwapStorage storage self, uint256 i, uint256 j, uint256 dx) external view returns(uint256) {
        require(i != j && i < N_COINS && j < N_COINS, 'coin index out of range');
        uint256[N_COINS] memory precisions = self.crypto.precisions;
        uint256 price_scale = self.crypto.price_scale * precisions[1];
        uint256[N_COINS] memory _xp = self.crypto.balances;

        uint256[2] memory A_gamma = _A_gamma(self);
        uint256 D = self.D;
        if (self.future.future_A_gamma_time > 0) {
            D = newton_D(A_gamma[0], A_gamma[1], xp(self));
        }
        _xp[i] += dx;
        _xp = [_xp[0] * precisions[0], _xp[1] * price_scale / PRECISION];
        uint256 y = newton_y(A_gamma[0], A_gamma[1], _xp, D, j);
        uint256 dy = _xp[j] - y - 1;
        _xp[j] = y;
        if (j > 0) {
            dy = dy * PRECISION / price_scale;
        } else {
            dy /= precisions[0];
        }
        dy -= _fee(self.fees, _xp) * dy / 10**10;
        return dy;
    }

    function add_liquidity(SwapStorage storage self, uint256[N_COINS] calldata amounts, uint256 min_mint_amount) external {
        AddLiquidityInfo memory v ;
        uint256[2] memory A_gamma = _A_gamma(self);

        uint256[N_COINS] memory xp = self.crypto.balances;
        uint256[N_COINS] memory amountsp;
        uint256[N_COINS] memory xx;
        uint256[N_COINS] memory precisions = self.crypto.precisions;
        address[N_COINS] memory coins = self.crypto.coins;

        if (true) {
            uint256[N_COINS] memory xp_old = xp;
            for (uint256 i = 0; i < N_COINS; i++) {
                uint256 bal = xp[i] + amounts[i];
                xp[i] = bal;
                self.crypto.balances[i] = bal;
            }
            xx = xp;

            v.price_scale = self.crypto.price_scale * precisions[1];
            xp = [xp[0] * precisions[0], xp[1] * v.price_scale / PRECISION];
            xp_old = [xp_old[0] * precisions[0], xp_old[1] * v.price_scale / PRECISION];

            for (uint256 i = 0; i < N_COINS; i++) {
                if (amounts[i] > 0) {
                    IERC20(coins[i]).transferFrom(msg.sender, address(this), amounts[i]);
                    amountsp[i] = xp[i] - xp_old[i];
                }
            }

            require(amounts[0] > 0 || amounts[1] > 0, 'no coins to add');
            v.t = self.future.future_A_gamma_time;
            if (v.t > 0) {
                v.old_D = newton_D(A_gamma[0], A_gamma[1], xp_old);
                if (block.timestamp >= v.t) {
                    self.future.future_A_gamma_time = 1;
                }
            } else {
                v.old_D = self.D;
            }
        }
        v.D = newton_D(A_gamma[0], A_gamma[1], xp);
        v.token_supply = total_supply(self.crypto);
        if (v.old_D > 0) {
            v.d_token = v.token_supply * v.D / v.old_D - v.token_supply;
        } else {
            v.d_token = get_xcp(self, v.D);
        }
        require(v.d_token > 0, 'nothing minted');
        if (v.old_D > 0) {
            v.d_token_fee = _calc_token_fee(self, amountsp, xp) * v.d_token / 10**10 + 1;
            v.d_token -= v.d_token_fee;
            v.token_supply += v.d_token;
            mint(self.crypto, msg.sender, v.d_token);

            //            # Calculate price
            //            # p_i * (dx_i - dtoken / token_supply * xx_i) = sum{k!=i}(p_k * (dtoken / token_supply * xx_k - dx_k))
            //            # Only ix is nonzero
            v.p =0;
            if (v.d_token > 10**5) {
                if (amounts[0] == 0 || amounts[1] == 0) {
                    uint256 S = 0;
                    uint256 precision = 0;
                    uint256 ix = 0;
                    if (amounts[0] == 0) {
                        S = xx[0] * precisions[0];
                        precision = precisions[1];
                        ix = 1;
                    } else {
                        S = xx[1] * precisions[1];
                        precision = precisions[0];
                    }
                    S = S * v.d_token / v.token_supply;
                    v.p = S * PRECISION / (amounts[ix] * precision - v.d_token * xx[ix] * precision / v.token_supply);
                    if (ix == 0) {
                        v.p = (10**18)**2 / v.p;
                    }
                }
            }
            tweak_price(self, A_gamma, xp,v.p, v.D);
        } else {
            self.D = v.D;
            self.crypto.virtual_price = 10**18;
            self.xcp_profit = 10**18;
            mint(self.crypto, msg.sender, v.d_token);
        }
        require(v.d_token >= min_mint_amount, "Slippage");
        emit AddLiquidity(msg.sender, amounts, v.d_token_fee, v.token_supply);
    }

    function remove_liquidity(SwapStorage storage self, uint256 _amount, uint256[N_COINS] memory min_amounts) external {
        address[N_COINS] memory coins = self.crypto.coins;
        uint256 total_supply = total_supply(self.crypto);
        burn(self.crypto, msg.sender, _amount);
        uint256[N_COINS] memory balances = self.crypto.balances;
        uint256 amount = _amount - 1;

        for (uint256 i = 0; i < N_COINS; i++) {
            uint256 d_balance = balances[i] * amount / total_supply;
            require(d_balance >= min_amounts[i], '<min_amounts');
            self.crypto.balances[i] = balances[i] - d_balance;
            balances[i] = d_balance;
            IERC20(coins[i]).transfer(msg.sender, d_balance);
        }
        uint256 D = self.D;
        self.D = D - D * amount / total_supply;
        emit RemoveLiquidity(msg.sender, balances, total_supply - _amount);
    }

    function calc_token_amount(SwapStorage storage self, uint256[N_COINS] memory amounts) external view returns(uint256) {
        uint256[N_COINS] memory precisions = self.crypto.precisions;
        uint256 total_supply = total_supply(self.crypto);
        uint256 price_scale = self.crypto.price_scale * precisions[1];
        uint256[2] memory A_gamma = _A_gamma(self);
        uint256[N_COINS] memory _xp = xp(self);
        uint256[N_COINS] memory amountsp = [amounts[0] * precisions[0], amounts[1] * price_scale / PRECISION];
        uint256 D0 = self.D;
        if (self.future.future_A_gamma_time > 0) {
            D0 = newton_D(A_gamma[0], A_gamma[1], _xp);
        }
        _xp[0] += amountsp[0];
        _xp[1] += amountsp[1];
        uint256 D = newton_D(A_gamma[0], A_gamma[1], _xp);
        uint256 d_token = total_supply * D / D0 - total_supply;
        d_token = _calc_token_fee(self, amountsp, _xp) *  d_token/ 10**10 + 1;
        return d_token;
    }

    function calc_withdraw_one_coin(SwapStorage storage self, uint256 token_amount, uint256 i) external view returns(uint256) {
        (uint256 res, , , ) = _calc_withdraw_one_coin(self, _A_gamma(self), token_amount, i, true, false);
        return res;
    }

    function remove_liquidity_one_coin(SwapStorage storage self, uint256 token_amount, uint256 i, uint256 min_amount) external returns(uint256){
        uint256[2] memory A_gamma = _A_gamma(self);
        uint256 dy = 0;
        uint256 D = 0;
        uint256 p = 0;
        uint256[N_COINS] memory xp;
        uint256 future_A_gamma_time = self.future.future_A_gamma_time;
        (dy, p, D, xp) = _calc_withdraw_one_coin(self, A_gamma, token_amount, i, (future_A_gamma_time > 0), true);
        require(dy >= min_amount, "Slippage");

        if (block.timestamp >= future_A_gamma_time) {
            self.future.future_A_gamma_time = 1;
        }
        self.crypto.balances[i] -= dy;
        burn(self.crypto, msg.sender, token_amount);
        address[N_COINS] memory coins = self.crypto.coins;
        IERC20(coins[i]).transfer(msg.sender, dy);

        tweak_price(self, A_gamma, xp, p, D);
        emit RemoveLiquidityOne(msg.sender, token_amount, i, dy);
        return token_amount;

    }

    function claim_admin_fees(SwapStorage storage self) external {
        _claim_admin_fees(self);
    }


    /* =============== EVENTS ==================== */
    event TokenExchange(address indexed buyer, uint256 sold_id, uint256 tokens_sold, uint256 bought_id, uint256 tokens_bought);
    event AddLiquidity(address indexed provider, uint256[N_COINS] token_amounts, uint256 fee, uint256 token_supply);
    event RemoveLiquidity(address indexed provider, uint256[N_COINS] token_amounts, uint256 token_supply);
    event RemoveLiquidityOne(address indexed provider, uint256 token_amount, uint256 coin_index, uint256 coin_amount);
    event ClaimAdminFee(address indexed admin, uint256 tokens);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IFactory{
    function getPair(address tokenA, address tokenB) external  view returns(address);
    function feeTo() external view returns(address);
    function createPair(address[2] memory coins, uint256 initial_price, address operator) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract LPToken is ERC20Burnable {
    address public minter;
    string _name = 'LP_PAIR';
    string _symbol = 'LPP';
    modifier onlyMinter() {
        require(msg.sender == minter, "!minter");
        _;
    }

    constructor() ERC20(_name, _symbol) {
        minter = msg.sender;
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }

    function setMinter(address _minter) external {
        require(minter != address(0), "zeroMinter");
        minter = _minter;
    }

    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

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
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}