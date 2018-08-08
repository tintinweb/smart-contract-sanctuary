/*
 * Safe Math Smart Contract.  Copyright &#169; 2016–2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<span class="__cf_email__" data-cfemail="660b0f0d0e070f0a48100a07020f0b0f14091026010b070f0a4805090b">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.16;

/**
 * ERC-20 standard token interface, as defined
 * <a href="http://github.com/ethereum/EIPs/issues/20">here</a>.
 */
contract Token {
    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply () constant returns (uint256 supply);

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the
     *        owner of
     * @return number of tokens currently belonging to the owner of given address
     */
    function balanceOf (address _owner) constant returns (uint256 balance);

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer (address _to, uint256 _value) returns (bool success);

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom (address _from, address _to, uint256 _value)
    returns (bool success);

    /**
     * Allow given spender to transfer given number of tokens from message sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve (address _spender, uint256 _value) returns (bool success);

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
     * given owner.
     *
     * @param _owner address to get number of tokens allowed to be transferred
     *        from the owner of
     * @param _spender address to get number of tokens allowed to be transferred
     *        by the owner of
     * @return number of tokens given spender is currently allowed to transfer
     *         from given owner
     */
    function allowance (address _owner, address _spender) constant
    returns (uint256 remaining);

    /**
     * Logged when tokens were transferred from one owner to another.
     *
     * @param _from address of the owner, tokens were transferred from
     * @param _to address of the owner, tokens were transferred to
     * @param _value number of tokens transferred
     */
    event Transfer (address indexed _from, address indexed _to, uint256 _value);

    /**
     * Logged when owner approved his tokens to be transferred by some spender.
     *
     * @param _owner owner who approved his tokens to be transferred
     * @param _spender spender who were allowed to transfer the tokens belonging
     *        to the owner
     * @param _value number of tokens belonging to the owner, approved to be
     *        transferred by the spender
     */
    event Approval (
        address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract SafeMath {
    uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Add two uint256 values, throw in case of overflow.
     *
     * @param x first value to add
     * @param y second value to add
     * @return x + y
     */
    function safeAdd (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
    }

    /**
     * Subtract one uint256 value from another, throw in case of underflow.
     *
     * @param x value to subtract from
     * @param y value to subtract
     * @return x - y
     */
    function safeSub (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
        assert (x >= y);
        return x - y;
    }

    /**
     * Multiply two uint256 values, throw in case of overflow.
     *
     * @param x first value to multiply
     * @param y second value to multiply
     * @return x * y
     */
    function safeMul (uint256 x, uint256 y)
    constant internal
    returns (uint256 z) {
        if (y == 0) return 0; // Prevent division by zero at the next line
        assert (x <= MAX_UINT256 / y);
        return x * y;
    }
}

/**
 * Math Utilities smart contract.
 */
contract Math is SafeMath {
    /**
     * 2^127.
     */
    uint128 internal constant TWO127 = 0x80000000000000000000000000000000;

    /**
     * 2^128 - 1.
     */
    uint128 internal constant TWO128_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * 2^128.
     */
    uint256 internal constant TWO128 = 0x100000000000000000000000000000000;

    /**
     * 2^256 - 1.
     */
    uint256 internal constant TWO256_1 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * 2^255.
     */
    uint256 internal constant TWO255 =
    0x8000000000000000000000000000000000000000000000000000000000000000;

    /**
     * -2^255.
     */
    int256 internal constant MINUS_TWO255 =
    -0x8000000000000000000000000000000000000000000000000000000000000000;

    /**
     * 2^255 - 1.
     */
    int256 internal constant TWO255_1 =
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * ln(2) * 2^128.
     */
    uint128 internal constant LN2 = 0xb17217f7d1cf79abc9e3b39803f2f6af;

    /**
     * Return index of most significant non-zero bit in given non-zero 256-bit
     * unsigned integer value.
     *
     * @param x value to get index of most significant non-zero bit in
     * @return index of most significant non-zero bit in given number
     */
    function mostSignificantBit (uint256 x) pure internal returns (uint8) {
        require (x > 0);

        uint8 l = 0;
        uint8 h = 255;

        while (h > l) {
            uint8 m = uint8 ((uint16 (l) + uint16 (h)) >> 1);
            uint256 t = x >> m;
            if (t == 0) h = m - 1;
            else if (t > 1) l = m + 1;
            else return m;
        }

        return h;
    }

    /**
     * Calculate log_2 (x / 2^128) * 2^128.
     *
     * @param x parameter value
     * @return log_2 (x / 2^128) * 2^128
     */
    function log_2 (uint256 x) pure internal returns (int256) {
        require (x > 0);

        uint8 msb = mostSignificantBit (x);

        if (msb > 128) x >>= msb - 128;
        else if (msb < 128) x <<= 128 - msb;

        x &= TWO128_1;

        int256 result = (int256 (msb) - 128) << 128; // Integer part of log_2

        int256 bit = TWO127;
        for (uint8 i = 0; i < 128 && x > 0; i++) {
            x = (x << 1) + ((x * x + TWO127) >> 128);
            if (x > TWO128_1) {
                result |= bit;
                x = (x >> 1) - TWO127;
            }
            bit >>= 1;
        }

        return result;
    }

    /**
     * Calculate ln (x / 2^128) * 2^128.
     *
     * @param x parameter value
     * @return ln (x / 2^128) * 2^128
     */
    function ln (uint256 x) pure internal returns (int256) {
        require (x > 0);

        int256 l2 = log_2 (x);
        if (l2 == 0) return 0;
        else {
            uint256 al2 = uint256 (l2 > 0 ? l2 : -l2);
            uint8 msb = mostSignificantBit (al2);
            if (msb > 127) al2 >>= msb - 127;
            al2 = (al2 * LN2 + TWO127) >> 128;
            if (msb > 127) al2 <<= msb - 127;

            return int256 (l2 >= 0 ? al2 : -al2);
        }
    }

    /**
     * Calculate x * y / 2^128.
     *
     * @param x parameter x
     * @param y parameter y
     * @return x * y / 2^128
     */
    function fpMul (uint256 x, uint256 y) pure internal returns (uint256) {
        uint256 xh = x >> 128;
        uint256 xl = x & TWO128_1;
        uint256 yh = y >> 128;
        uint256 yl = y & TWO128_1;

        uint256 result = xh * yh;
        require (result <= TWO128_1);
        result <<= 128;

        result = safeAdd (result, xh * yl);
        result = safeAdd (result, xl * yh);
        result = safeAdd (result, (xl * yl) >> 128);

        return result;
    }

    /**
     * Calculate x * y.
     *
     * @param x parameter x
     * @param y parameter y
     * @return high and low words of x * y
     */
    function longMul (uint256 x, uint256 y)
    pure internal returns (uint256 h, uint256 l) {
        uint256 xh = x >> 128;
        uint256 xl = x & TWO128_1;
        uint256 yh = y >> 128;
        uint256 yl = y & TWO128_1;

        h = xh * yh;
        l = xl * yl;

        uint256 m1 = xh * yl;
        uint256 m2 = xl * yh;

        h += m1 >> 128;
        h += m2 >> 128;

        m1 <<= 128;
        m2 <<= 128;

        if (l > TWO256_1 - m1) h += 1;
        l += m1;

        if (l > TWO256_1 - m2) h += 1;
        l += m2;
    }

    /**
     * Calculate x * y / 2^128.
     *
     * @param x parameter x
     * @param y parameter y
     * @return x * y / 2^128
     */
    function fpMulI (int256 x, int256 y) pure internal returns (int256) {
        bool negative = (x ^ y) < 0; // Whether result is negative

        uint256 result = fpMul (
            x < 0 ? uint256 (-1 - x) + 1 : uint256 (x),
            y < 0 ? uint256 (-1 - y) + 1 : uint256 (y));

        if (negative) {
            require (result <= TWO255);
            return result == 0 ? 0 : -1 - int256 (result - 1);
        } else {
            require (result < TWO255);
            return int256 (result);
        }
    }

    /**
     * Calculate x + y, throw in case of over-/underflow.
     *
     * @param x parameter x
     * @param y parameter y
     * @return x + y
     */
    function safeAddI (int256 x, int256 y) pure internal returns (int256) {
        if (x < 0 && y < 0)
            assert (x >= MINUS_TWO255 - y);

        if (x > 0 && y > 0)
            assert (x <= TWO255_1 - y);

        return x + y;
    }

    /**
     * Calculate x / y * 2^128.
     *
     * @param x parameter x
     * @param y parameter y
     * @return  x / y * 2^128
     */
    function fpDiv (uint256 x, uint256 y) pure internal returns (uint256) {
        require (y > 0); // Division by zero is forbidden

        uint8 maxShiftY = mostSignificantBit (y);
        if (maxShiftY >= 128) maxShiftY -= 127;
        else maxShiftY = 0;

        uint256 result = 0;

        while (true) {
            uint256 rh = x >> 128;
            uint256 rl = x << 128;

            uint256 ph;
            uint256 pl;

            (ph, pl) = longMul (result, y);
            if (rl < pl) {
                ph = safeAdd (ph, 1);
            }

            rl -= pl;
            rh -= ph;

            if (rh == 0) {
                result = safeAdd (result, rl / y);
                break;
            } else {
                uint256 reminder = (rh << 128) + (rl >> 128);

                // How many bits to shift reminder left
                uint8 shiftReminder = 255 - mostSignificantBit (reminder);
                if (shiftReminder > 128) shiftReminder = 128;

                // How many bits to shift result left
                uint8 shiftResult = 128 - shiftReminder;

                // How many bits to shift Y right
                uint8 shiftY = maxShiftY;
                if (shiftY > shiftResult) shiftY = shiftResult;

                shiftResult -= shiftY;

                uint256 r = (reminder << shiftReminder) / (((y - 1) >> shiftY) + 1);

                uint8 msbR = mostSignificantBit (r);
                require (msbR <= 255 - shiftResult);

                result = safeAdd (result, r << shiftResult);
            }
        }

        return result;
    }
}


/**
 * Continuous Sale Action for selling PAT tokens.
 */
contract PATTokenSale is Math {
    /**
     * Time period when 15% bonus is in force.
     */
    uint256 private constant TRIPLE_BONUS = 1 hours;

    /**
     * Time period when 10% bonus is in force.
     */
    uint256 private constant DOUBLE_BONUS = 1 days;

    /**
     * Time period when 5% bonus is in force.
     */
    uint256 private constant SINGLE_BONUS = 1 weeks;

    /**
     * Create PAT Token Sale smart contract with given sale start time, token
     * contract and central bank address.
     *
     * @param _saleStartTime sale start time
     * @param _saleDuration sale duration
     * @param _token ERC20 smart contract managing tokens to be sold
     * @param _centralBank central bank address to transfer tokens from
     * @param _saleCap maximum amount of ether to collect (in Wei)
     * @param _minimumInvestment minimum investment amount (in Wei)
     * @param _a parameter a of price formula
     * @param _b parameter b of price formula
     * @param _c parameter c of price formula
     */
    function PATTokenSale (
        uint256 _saleStartTime, uint256 _saleDuration,
        Token _token, address _centralBank,
        uint256 _saleCap, uint256 _minimumInvestment,
        int256 _a, int256 _b, int256 _c) {
        saleStartTime = _saleStartTime;
        saleDuration = _saleDuration;
        token = _token;
        centralBank = _centralBank;
        saleCap = _saleCap;
        minimumInvestment = _minimumInvestment;
        a = _a;
        b = _b;
        c = _c;
    }

    /**
     * Equivalent to buy().
     */
    function () payable public {
        require (msg.data.length == 0);

        buy ();
    }

    /**
     * Buy tokens.
     */
    function buy () payable public {
        require (!finished);
        require (now >= saleStartTime);
        require (now < safeAdd (saleStartTime, saleDuration));

        require (msg.value >= minimumInvestment);

        if (msg.value > 0) {
            uint256 remainingCap = safeSub (saleCap, totalInvested);
            uint256 toInvest;
            uint256 toRefund;

            if (msg.value <= remainingCap) {
                toInvest = msg.value;
                toRefund = 0;
            } else {
                toInvest = remainingCap;
                toRefund = safeSub (msg.value, toInvest);
            }

            Investor storage investor = investors [msg.sender];
            investor.amount = safeAdd (investor.amount, toInvest);
            if (now < safeAdd (saleStartTime, TRIPLE_BONUS))
                investor.bonusAmount = safeAdd (
                    investor.bonusAmount, safeMul (toInvest, 6));
            else if (now < safeAdd (saleStartTime, DOUBLE_BONUS))
                investor.bonusAmount = safeAdd (
                    investor.bonusAmount, safeMul (toInvest, 4));
            else if (now < safeAdd (saleStartTime, SINGLE_BONUS))
                investor.bonusAmount = safeAdd (
                    investor.bonusAmount, safeMul (toInvest, 2));

            Investment (msg.sender, toInvest);

            totalInvested = safeAdd (totalInvested, toInvest);
            if (toInvest == remainingCap) {
                finished = true;
                finalPrice = price (now);

                Finished (finalPrice);
            }

            if (toRefund > 0)
                msg.sender.transfer (toRefund);
        }
    }

    /**
     * Buy tokens providing referral code.
     *
     * @param _referralCode referral code, actually address of referee
     */
    function buyReferral (address _referralCode) payable public {
        require (msg.sender != _referralCode);

        Investor storage referee = investors [_referralCode];

        // Make sure referee actually did invest something
        require (referee.amount > 0);

        Investor storage referrer = investors [msg.sender];
        uint256 oldAmount = referrer.amount;

        buy ();

        uint256 invested = safeSub (referrer.amount, oldAmount);

        // Make sure referrer actually did invest something
        require (invested > 0);

        referee.investedByReferrers = safeAdd (
            referee.investedByReferrers, invested);

        referrer.bonusAmount = safeAdd (
            referrer.bonusAmount,
            min (referee.amount, invested));
    }

    /**
     * Get number of tokens to be delivered to given investor.
     *
     * @param _investor address of the investor to get number of tokens to be
     *        delivered to
     * @return number of tokens to be delivered to given investor
     */
    function outstandingTokens (address _investor)
    constant public returns (uint256) {
        require (finished);
        assert (finalPrice > 0);

        Investor storage investor = investors [_investor];
        uint256 bonusAmount = investor.bonusAmount;
        bonusAmount = safeAdd (
            bonusAmount, min (investor.amount, investor.investedByReferrers));

        uint256 effectiveAmount = safeAdd (
            investor.amount,
            bonusAmount / 40);

        return fpDiv (effectiveAmount, finalPrice);
    }

    /**
     * Deliver purchased tokens to given investor.
     *
     * @param _investor investor to deliver purchased tokens to
     */
    function deliver (address _investor) public returns (bool) {
        require (finished);

        Investor storage investor = investors [_investor];
        require (investor.amount > 0);

        uint256 value = outstandingTokens (_investor);
        if (value > 0) {
            if (!token.transferFrom (centralBank, _investor, value)) return false;
        }

        totalInvested = safeSub (totalInvested, investor.amount);
        investor.amount = 0;
        investor.bonusAmount = 0;
        investor.investedByReferrers = 0;
        return true;
    }

    /**
     * Collect sale revenue.
     */
    function collectRevenue () public {
        require (msg.sender == centralBank);

        centralBank.transfer (this.balance);
    }

    /**
     * Return token price at given time in Wei per token natural unit.
     *
     * @param _time time to return price at
     * @return price at given time as 128.128 fixed point number
     */
    function price (uint256 _time) constant public returns (uint256) {
        require (_time >= saleStartTime);
        require (_time <= safeAdd (saleStartTime, saleDuration));

        require (_time <= TWO128_1);
        uint256 t = _time << 128;

        uint256 cPlusT = (c >= 0) ?
        safeAdd (t, uint256 (c)) :
        safeSub (t, uint256 (-1 - c) + 1);
        int256 lnCPlusT = ln (cPlusT);
        int256 bLnCPlusT = fpMulI (b, lnCPlusT);
        int256 aPlusBLnCPlusT = safeAddI (a, bLnCPlusT);

        require (aPlusBLnCPlusT >= 0);
        return uint256 (aPlusBLnCPlusT);
    }

    /**
     * Finish sale after sale period ended.
     */
    function finishSale () public {
        require (msg.sender == centralBank);
        require (!finished);
        uint256 saleEndTime = safeAdd (saleStartTime, saleDuration);
        require (now >= saleEndTime);

        finished = true;
        finalPrice = price (saleEndTime);

        Finished (finalPrice);
    }

    /**
     * Destroy smart contract.
     */
    function destroy () public {
        require (msg.sender == centralBank);
        require (finished);
        require (now >= safeAdd (saleStartTime, saleDuration));
        require (totalInvested == 0);
        require (this.balance == 0);

        selfdestruct (centralBank);
    }

    /**
     * Return minimum of two values.
     *
     * @param x first value
     * @param y second value
     * @return minimum of two values
     */
    function min (uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * Sale start time.
     */
    uint256 internal saleStartTime;

    /**
     * Sale duration.
     */
    uint256 internal saleDuration;

    /**
     * ERC20 token smart contract managing tokens to be sold.
     */
    Token internal token;

    /**
     * Address of central bank to transfer tokens from.
     */
    address internal centralBank;

    /**
     * Maximum number of Wei to collect.
     */
    uint256 internal saleCap;

    /**
     * Minimum investment amount in Wei.
     */
    uint256 internal minimumInvestment;

    /**
     * Price formula parameters.  Price at given time t is calculated as
     * a / 2^128 + b * ln ((c + t) / 2^128) / 2^128.
     */
    int256 internal a;
    int256 internal b;
    int256 internal c;

    /**
     * True is sale was finished successfully, false otherwise.
     */
    bool internal finished = false;

    /**
     * Final price for finished sale.
     */
    uint256 internal finalPrice;

    /**
     * Maps investor&#39;s address to corresponding Investor structure.
     */
    mapping (address => Investor) internal investors;

    /**
     * Total amount invested in Wei.
     */
    uint256 internal totalInvested = 0;

    /**
     * Encapsulates information about investor.
     */
    struct Investor {
        /**
         * Total amount invested in Wei.
         */
        uint256 amount;

        /**
         * Bonus amount in Wei multiplied by 40.
         */
        uint256 bonusAmount;

        /**
         * Total amount of ether invested by others while referring this address.
         */
        uint256 investedByReferrers;
    }

    /**
     * Logged when an investment was made.
     *
     * @param investor address of the investor who made the investment
     * @param amount investment amount
     */
    event Investment (address indexed investor, uint256 amount);

    /**
     * Logged when sale finished successfully.
     *
     * @param finalPrice final price of the sale in Wei per token natural unit as
     *                   128.128 bit fixed point number.
     */
    event Finished (uint256 finalPrice);
}