pragma solidity 0.6.12;

library FixidityLib {

    uint8 constant public initial_digits = 36;
    int256 constant public fixed_e =            2718281828459045235360287471352662498;
    int256 constant public fixed_pi =           3141592653589793238462643383279502884;
    int256 constant public fixed_exp_10 =   22026465794806716516957900645284244000000;

	struct Fixidity {
		uint8 digits;
		int256 fixed_1;
		int256 fixed_e;
        int256 fixed_pi;
        int256 fixed_exp_10;
	}

    function init(Fixidity storage fixidity, uint8 digits) public {
        assert(digits < 36);
        fixidity.digits = digits;
        fixidity.fixed_1 = int256(uint256(10) ** uint256(digits));
        int256 t = int256(uint256(10) ** uint256(initial_digits - digits));
        fixidity.fixed_e = fixed_e / t;
        fixidity.fixed_pi = fixed_pi / t;
        fixidity.fixed_exp_10 = fixed_exp_10 / t;
    }

    function round(Fixidity storage fixidity, int256 v) internal view returns (int256) {
        return round_off(fixidity, v, fixidity.digits);
    }

    function floor(Fixidity storage fixidity, int256 v) internal view returns (int256) {
        return (v / fixidity.fixed_1) * fixidity.fixed_1;
    }

    function multiply(Fixidity storage fixidity, int256 a, int256 b) internal view returns (int256) {
        if(b == fixidity.fixed_1) return a;
        int256 x1 = a / fixidity.fixed_1;
        int256 x2 = a - fixidity.fixed_1 * x1;
        int256 y1 = b / fixidity.fixed_1;
        int256 y2 = b - fixidity.fixed_1 * y1;
        return fixidity.fixed_1 * x1 * y1 + x1 * y2 + x2 * y1 + x2 * y2 / fixidity.fixed_1;
    }

    function divide(Fixidity storage fixidity, int256 a, int256 b) internal view returns (int256) {
        if(b == fixidity.fixed_1) return a;
        assert(b != 0);
        return multiply(fixidity, a, reciprocal(fixidity, b));
    }

    function add(Fixidity storage fixidity, int256 a, int256 b) internal view returns (int256) {
    	int256 t = a + b;
        assert(t - a == b);
    	return t;
    }

    function subtract(Fixidity storage fixidity, int256 a, int256 b) internal view returns (int256) {
    	int256 t = a - b;
    	assert(t + b == a);
    	return t;
    }

    function reciprocal(Fixidity storage fixidity, int256 a) internal view returns (int256) {
        return round_off(fixidity, 10 * fixidity.fixed_1 * fixidity.fixed_1 / a, 1) / 10;
    }

    function round_off(Fixidity storage fixidity, int256 v, uint8 digits) internal view returns (int256) {
        int256 t = int256(uint256(10) ** uint256(digits));
        int8 sign = 1;
        if(v < 0) {
            sign = -1;
            v = 0 - v;
        }
        if(v % t >= t / 2) v = v + t - v % t;
        return v * sign;
    }

    function round_to(Fixidity storage fixidity, int256 v, uint8 digits) internal view returns (int256) {
        assert(digits < fixidity.digits);
        return round_off(fixidity, v, fixidity.digits - digits);
    }

    function trunc_digits(Fixidity storage fixidity, int256 v, uint8 digits) internal view returns (int256) {
        if(digits <= 0) return v;
        return round_off(fixidity, v, digits) / int256(10 ** digits);
    }
}