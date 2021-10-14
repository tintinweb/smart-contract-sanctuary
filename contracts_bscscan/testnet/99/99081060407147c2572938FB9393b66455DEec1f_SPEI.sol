// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.0 <0.9.0;

library Types {
    /*
types:

    date =  uint32 (max year 10,141), UNIX minutes
  amount =  uint80 1 unit = 1000 wei,  (max 1e27 GWei or 1,208,925,819 units) 
   ratio =  uint16 (max 65536)
    time =  uint16 (max 45 days), minutes
 account = uint160 (max 20 digits bank account)
   nonce =  uint48 (max 6 characters SPEI nonce)
*/

    /** Order fixed data, 256 bits */
    struct Order {
        /** dest account */
        uint160 dest;
        /** SPEI nonce */
        uint48 nonce;
        /** 
            Coin price in COIN units (1e18 wei) / (MXN * 1000)
            thus, 
                if ratio is 
                [1,1] -> 1 token = 1000 MXN,
                [2,1] -> 1 token = 2000 MXN ,
            [1, 1000] -> 1 token =    1 MXN
                    
        */
        uint16 priceMXN1000Num;
        uint16 priceMXN1000Den;
        /** Max public key index for this order, this prevents validating signatures for a seller-untrusted public key */
        uint16 maxPubKeyIndex;
    }

    /** Order variable info, 232 bits */
    struct OrderVariables {
        /**Order total funds */
        uint80 funds;
        /** Order locked funds */
        uint80 locked;
        /**Date at which the lock expires */
        uint32 expire;
        /** True to disable order locking */
        bool disabled;
        /** 
    Lock ratio in 1 / 10000 units, cost / amount indicates buyer needs to pay "cost" in order to lock "amount" funds
    The lock is free if cost == 0 
     */
        uint16 lockRatio10000;
        /** Lock time in minutes */
        uint16 lockTime;
        /** Order coin */
        uint16 coinIndex;
    }

    /** Order lock per buyer, 112 bits */
    struct BuyerLock {
        /** Order locked funds */
        uint80 amount;
        /**Date at which the lock expires */
        uint32 expire;
        /** Date at which the lock started, used to calculate public key enable state */
        uint32 publicKeyDateRef;
    }

    struct PublicKey {
        uint256 exp;
        uint256[8] modulus;
        /** Public key will be enabled at this time */
        uint32 enableTime;
        /** Public key will be disabled at this time */
        uint32 disableTime;
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP
 */


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`
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


library Utils {
    function mulRatio(
        uint80 amount,
        uint16 ratioNum,
        uint16 ratioDen
    ) internal pure returns (uint80) {
        return uint80((uint256(amount) * ratioNum) / ratioDen);
    }

    /** 
        Converts from MXN cents to 1000 wei units
        Price is in 
     */
    function MxnCentsTo1000Wei(
        uint80 amountMXN,
        uint16 priceMXN1000Num,
        uint16 priceMXN1000Den
    ) internal pure returns (uint80) {
        return
            uint80(
                (uint256(amountMXN) * priceMXN1000Den * 10000000000) /
                    priceMXN1000Num
            );
    }

    function addRatio(
        uint80 amount,
        uint16 ratioNum,
        uint16 ratioDen
    ) internal pure returns (uint80) {
        return uint80(amount + ((uint256(amount) * ratioNum) / ratioDen));
    }

    /** Returns an order locked funds or 0 if the lock is expired */
    function getLockedAmount(
        uint80 locked,
        uint32 lockExpire,
        uint32 nowMinutes
    ) internal pure returns (uint80 ret) {
        assembly {
            ret := mul(locked, lt(nowMinutes, lockExpire))
        }
    }

    function min(uint80 a, uint80 b) internal pure returns (uint80) {
        return a < b ? a : b;
    }

    function min(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }
}

contract UtilsTest {
    function MxnCentsTo1000Wei(
        uint80 amountMXN,
        uint16 priceMXN1000Num,
        uint16 priceMXN1000Den
    ) external pure returns (uint80) {
        return
            Utils.MxnCentsTo1000Wei(
                amountMXN,
                priceMXN1000Num,
                priceMXN1000Den
            );
    }
}



library Buy {
    /** Returns how much a buyer will get if a buy with the given MXN amount is executed
        considering buyer locks
     */
    function calcBuyAmount(
        uint80 bLock,
        uint80 amountMXN,
        uint16 priceMXNNum,
        uint16 priceMXNDen,
        uint16 lockRatio10000
    ) internal pure returns (uint80) {
        return Utils.min(
            Utils.addRatio(
                Utils.MxnCentsTo1000Wei(amountMXN, priceMXNNum, priceMXNDen),
                lockRatio10000, 
                10000
            )
            , bLock);
    }

    /** 
        Executes an already verified buy, returns the buy amount and fee in token units.
        Considers buyer lock amount
    */
    function executeBuy(
        mapping(uint256 => Types.OrderVariables) storage orderVars,
        mapping(address => uint256) storage ownerFees,
        mapping(uint16 => address) storage coins,
        mapping(address => mapping(uint256 => Types.BuyerLock)) storage buyerLocks,
        Types.BuyerLock memory buyerLock,
        uint256 orderIndex,
        uint80 amountMXN,
        uint16 priceMXNNum,
        uint16 priceMXNDen,
        uint8 ownerFeeRatio
    ) internal returns (uint80) {
        require(amountMXN > 0, "amount is 0");

        uint80 bLock;
        {
            bLock = Utils.getLockedAmount(
                buyerLock.amount,
                buyerLock.expire,
                uint32(block.timestamp / 60)
            );
        }

        require(bLock > 0, "no buyer lock");

        Types.OrderVariables memory order = orderVars[orderIndex];

        uint80 amount = calcBuyAmount(
            bLock,
            amountMXN,
            priceMXNNum,
            priceMXNDen,
            order.lockRatio10000
        );

        if (amount == 0) return 0;
        {
            address coin = coins[order.coinIndex];
            uint80 fee = amount * ownerFeeRatio / 1000;
            if(fee > 0) {
                ownerFees[coin] += fee;
            }
            if (!IERC20(coin).transfer(msg.sender, uint256(amount - fee) * 1000)) {
                // unreachable
                revert("not enough balance in contract");
            }
        }

        orderVars[orderIndex] = Types.OrderVariables({
            // copy
            expire: order.expire,
            lockTime: order.lockTime,
            lockRatio10000: order.lockRatio10000,
            disabled: order.disabled,
            coinIndex: order.coinIndex,

            // update
            funds: order.funds - amount,
            locked: order.locked - amount
        });

         buyerLocks[msg.sender][orderIndex] = Types.BuyerLock({
            // copy:
            expire: buyerLock.expire,
            publicKeyDateRef: buyerLock.publicKeyDateRef,

            // update:
            amount: bLock - amount
        });

        return amount;
    }
}




library Parser {
    /** 
    Returns the number of days since 1970-01-01
    Valid in the year range [2001, 2399]
    */
    function getUnixDate(
        uint32 y,
        uint32 m,
        uint32 d
    ) internal pure returns (uint32) {
        assembly {
            y := sub(y, lt(m, 3))
        }

        uint32 yoe = y - 2000; // [0, 399]
        uint32 doy = ((153 * ((m + 9) % 12) + 2) / 5) + d - 1; // [0, 365]
        uint32 doe = yoe * 365 + (yoe / 4) - (yoe / 100) + doy; // [0, 146096]
        return doe + 11017;
    }

    /** Parses a CEP "cadenaCDA" attribute */
    function parseMessage(string calldata message)
        external
        pure
        returns (
            uint32 date,
            uint48 nonce,
            uint160 dest,
            uint80 amount
        )
    {
        //parse the date:
        uint256 dateAscii;
        assembly {
            dateAscii := calldataload(add(message.offset, 13))
        }

        {
            uint32 day = uint32(
                (((dateAscii >> 248) & 0x0f) * 10) +
                    ((dateAscii >> 240) & 0x000f)
            );

            uint32 month = uint32(
                (((dateAscii >> 232) & 0x0f) * 10) +
                    ((dateAscii >> 224) & 0x000f)
            );

            uint32 year = uint32(
                (((dateAscii >> 216) & 0x0f) * 1000) +
                    (((dateAscii >> 208) & 0x000f) * 100) +
                    (((dateAscii >> 200) & 0x00000f) * 10) +
                    (((dateAscii >> 192) & 0x0000000f))
            );

            date = getUnixDate(year, month, day);
        }

        assembly {
            let b := add(message.offset, 22)
            {
                let pipeCount := 0
                for {

                } lt(pipeCount, 5) {
                    b := add(b, 1)
                } {
                    // if char is pipe
                    if eq(
                        and(
                            calldataload(b),
                            0xff00000000000000000000000000000000000000000000000000000000000000
                        ),
                        0x7c00000000000000000000000000000000000000000000000000000000000000
                    ) {
                        pipeCount := add(pipeCount, 1)
                    }
                }
            }

            // we know that on position 5 we have an account number with at least 12 bytes
            b := add(b, 12)
            {
                let pipeCount := 0
                for {

                } lt(pipeCount, 5) {
                    b := add(b, 1)
                } {
                    // if char is pipe
                    if eq(
                        and(
                            calldataload(b),
                            0xff00000000000000000000000000000000000000000000000000000000000000
                        ),
                        0x7c00000000000000000000000000000000000000000000000000000000000000
                    ) {
                        pipeCount := add(pipeCount, 1)
                    }
                }
            }

            // parse account number:
            dest := calldataload(b)

            let divisor := 0x100000000000000000000000000000000000000
            for {

            } iszero(
                eq(
                    and(div(dest, divisor), 0xff),
                    // search the pipe
                    0x7c
                )
            ) {

            } {
                b := add(b, 1)
                divisor := div(divisor, 0x100)
            }

            dest := div(dest, mul(divisor, 0x100))

            b := add(b, 13) // pipe(1) + initial read (11) + pipe (1)

            {
                //read until the next pipe:
                for {

                } iszero(
                    eq(
                        and(
                            calldataload(b),
                            0xff00000000000000000000000000000000000000000000000000000000000000
                        ),
                        0x7c00000000000000000000000000000000000000000000000000000000000000
                    )
                ) {

                } {
                    b := add(b, 1)
                }

                b := add(b, 1) // pipe
            }

            // parse the nonce

            nonce := div(
                and(
                    calldataload(b),
                    // nonce is 6 digits long
                    0xffffffffffff0000000000000000000000000000000000000000000000000000
                ),
                0x10000000000000000000000000000000000000000000000000000
            )

            b := add(b, 11) // read(6) + pipe(1) + read(min 4)

            //read until the next pipe:
            for {

            } iszero(
                eq(
                    and(
                        calldataload(b),
                        0xff00000000000000000000000000000000000000000000000000000000000000
                    ),
                    0x7c00000000000000000000000000000000000000000000000000000000000000
                )
            ) {

            } {
                b := add(b, 1)
            }

            b := add(b, 1) // +5 pipe count

            // parse amount:

            // parse integer part:
            let amountData := calldataload(b)
            amount := 0

            divisor := 0x100000000000000000000000000000000000000000000000000000000000000
            for {

            } iszero(
                eq(
                    and(div(amountData, divisor), 0xff),
                    // search the decimal dot
                    0x2e
                )
            ) {

            } {
                amount := add(
                    mul(amount, 10),
                    and(div(amountData, divisor), 0x0f)
                )
                divisor := div(divisor, 0x100)
            }

            // parse decimal part:
            amount := add(
                mul(amount, 100),
                add(
                    mul(and(div(amountData, div(divisor, 0x100)), 0x0f), 10),
                    and(div(amountData, div(divisor, 0x10000)), 0x0f)
                )
            )
        }
    }

    // END 2
}

contract ParserTest {
    /** Parses a CEP "cadenaCDA" attribute */
    function parseMessage(string calldata message)
        external
        pure
        returns (
            uint256 date,
            uint48 nonce,
            uint160 dest,
            uint256 amount
        )
    {
        return Parser.parseMessage(message);
    }

    /** 
    Returns the number of days since 2000-03-01
    Only valid since year 2001
    */
    function getUnixDate(
        uint32 y,
        uint32 m,
        uint32 d
    ) external pure returns (uint32) {
        return Parser.getUnixDate(y, m, d);
    }
}




library RSA {
    /** Verifies a digital signature for an ASCII message */
    function verifySig2048SHA256(
        string calldata message,
        uint256[8] memory sig,
        uint256 exp,
        uint256[8] memory modulus
    ) internal returns (bool) {
        bytes32 hash = sha256(abi.encodePacked(message));
        return verifySig2048SHA256(hash, sig, exp, modulus);
    }

    /** Verifies a digital signature */
    function verifySig2048SHA256(
        bytes32 hash,
        uint256[8] memory sig,
        uint256 exp,
        uint256[8] memory modulus
    ) private returns (bool) {
        bytes32[8] memory a = pad2048SHA256(hash);
        bytes32[8] memory b = powMod2048(sig, exp, modulus);

        return (a[0] == b[0] &&
            a[1] == b[1] &&
            a[2] == b[2] &&
            a[3] == b[3] &&
            a[4] == b[4] &&
            a[5] == b[5] &&
            a[6] == b[6] &&
            a[7] == b[7]);
    }

    /** Returns the pkcs1_v15 encoded SHA256*/
    function pad2048SHA256(bytes32 hash)
        internal
        pure
        returns (bytes32[8] memory pointer)
    {
        //0x30,0x31,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x01,0x05,0x00,0x04,0x20
        //
        assembly {
            // prefix
            mstore(
                pointer,
                0x0001000000000000000000000000000000000000000000000000000000000000
            )

            /*
                const keyLen = 2048 / 8;
                const hashInfoLen = 19;
                const hashLen = 256 / 8
                const onesLen = keyLen - hashInfoLen - hashLen - 3; // 202
            */
            // ones:
            mstore(
                add(pointer, 2),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 32
            )
            mstore(
                add(pointer, 34),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 64
            )
            mstore(
                add(pointer, 66),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 96
            )
            mstore(
                add(pointer, 98),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 128
            )
            mstore(
                add(pointer, 130),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 160
            )
            mstore(
                add(pointer, 162),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF // 192
            )

            // last 10 ones, plus one last 0
            mstore(
                add(pointer, 194),
                0xFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000000000000000 // 202 + 1
            )

            // hash info:
            mstore(
                add(pointer, 205),
                0x3031300d06096086480165030402010500042000000000000000000000000000
            )

            // hash:
            mstore(add(pointer, 224), hash)
        }
    }

    /**(base ^ exponent) % modulo*/
    function powMod2048(
        uint256[8] memory base,
        uint256 exponent,
        uint256[8] memory modulus
    ) private returns (bytes32[8] memory ret) {
        assembly {
            // Free memory pointer
            let pointer := mload(0x40)

            // bigExpMod contract input format:
            // <length_of_BASE> <length_of_EXPONENT> <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>

            //lengths
            mstore(pointer, 0x100)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x100)

            //

            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), mload(base))
            mstore(add(pointer, 0x80), mload(add(base, 0x20)))
            mstore(add(pointer, 0xA0), mload(add(base, 0x40)))
            mstore(add(pointer, 0xC0), mload(add(base, 0x60)))

            mstore(add(pointer, 0x0E0), mload(add(base, 0x80)))
            mstore(add(pointer, 0x100), mload(add(base, 0xA0)))
            mstore(add(pointer, 0x120), mload(add(base, 0xC0)))
            mstore(add(pointer, 0x140), mload(add(base, 0xE0)))

            mstore(add(pointer, 0x160), exponent)

            mstore(add(pointer, 0x180), mload(modulus))
            mstore(add(pointer, 0x1A0), mload(add(modulus, 0x20)))
            mstore(add(pointer, 0x1C0), mload(add(modulus, 0x40)))
            mstore(add(pointer, 0x1E0), mload(add(modulus, 0x60)))

            mstore(add(pointer, 0x200), mload(add(modulus, 0x80)))
            mstore(add(pointer, 0x220), mload(add(modulus, 0xA0)))
            mstore(add(pointer, 0x240), mload(add(modulus, 0xC0)))
            mstore(add(pointer, 0x260), mload(add(modulus, 0xE0)))

            // Store the result

            // Call the precompiled contract 0x05 = bigModExp
            if iszero(
                call(
                    gas(), //gas
                    0x05, //bigModExp address
                    0, //ETH value
                    pointer, //in
                    0x280, //in size
                    ret, //out
                    0x100 // out size
                )
            ) {
                revert(0, 0)
            }
        }
    }
}

contract RSATest {
    function hash(string calldata message) external pure returns (bytes32) {
        return sha256(abi.encodePacked(message));
    }

    function pad(string calldata message)
        external
        pure
        returns (bytes32[8] memory pointer)
    {
        return RSA.pad2048SHA256(sha256(abi.encodePacked(message)));
    }

    /** Verifies a digital signature for a string message */
    function verifySig2048SHA256(
        string calldata message,
        uint256[8] memory sig,
        uint256 exp,
        uint256[8] memory modulus
    ) external returns (bool) {
        return RSA.verifySig2048SHA256(message, sig, exp, modulus);
    }
}






library PublicKeys {
    /** Gets a public key params, requires that the key is enabled at dateRef time */
    function getValidPublicKey(
        mapping(uint16 => Types.PublicKey) storage publicKeys,
        uint16 index,
        uint32 dateRef
    ) internal view returns (uint256 exp, uint256[8] memory modulus) {
        Types.PublicKey memory r = publicKeys[index];
        require(dateRef >= r.enableTime, "public key not yet nabled");
        require(dateRef <= r.disableTime, "public key disabled");

        return (r.exp, r.modulus);
    }

    /**
     Add a new public keys that will be enabled after "timeLock" minutes
     Does not verify "index", so caller needs to ensure that this is an empty index.
     */
    function addPublicKey(
        mapping(uint16 => Types.PublicKey) storage publicKeys,
        uint16 timeLock,
        uint16 index,
        uint256 exp,
        uint256[8] memory modulus
    ) external {
        uint32 unixMinutes = uint32(block.timestamp / 60);
        publicKeys[index] = Types.PublicKey(
            exp,
            modulus,
            unixMinutes + timeLock,
            0xFFFFFFFF
        );
    }

    /** 
    Disables an specific public key after "timelock" minutes.
     */
    function disablePublicKey(
        mapping(uint16 => Types.PublicKey) storage publicKeys,
        uint16 timeLock,
        uint16 index
    ) external {
        Types.PublicKey memory r = publicKeys[index];
        uint32 unixMinutes = uint32(block.timestamp / 60);
        uint32 disableTime = unixMinutes + timeLock;
        require(disableTime < r.disableTime, "key already disabled");

        publicKeys[index] = Types.PublicKey(
            // copy:
            r.exp,
            r.modulus,
            r.enableTime,
            // update
            disableTime
        );
    }
}




library Coins {
    function initCoins(mapping(uint16 => address) storage coins, uint16 c)
        external
        returns (uint16)
    {
        // native wrapped:

        // WBNB
        coins[c++] = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

        // stables:

        // USDT
        coins[c++] = address(0x55d398326f99059fF775485246999027B3197955);

        // USDC
        coins[c++] = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);

        // BUSD
        coins[c++] = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

        // DAI
        coins[c++] = address(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);

        // USDC
        coins[c++] = address(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);

        // binance pegs:

        // BTC
        coins[c++] = address(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);

        // ETH
        coins[c++] = address(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);

        // ADA
        coins[c++] = address(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);

        // XRP
        coins[c++] = address(0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE);

        // DOT
        coins[c++] = address(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402);

        // LTC
        coins[c++] = address(0x4338665CBB7B2485A8855A139b75D5e34AB0DB94);

        return c;
    }
}









library Receipt {
    /** 
        Proves that the buyer payed the seller by sending a digitally signed "cadenaCDA",
        returns the verified buy amount in MXN cents
     */
    function getReceiptValidAmount(
        mapping(uint16 => Types.PublicKey) storage publicKeys,
        mapping(uint256 => Types.Order) storage orders,
        uint256 orderIndex,
        uint16 publicKeyIndex,
        uint32 pubKeyDateRef,
        uint256[8] memory sig,
        string calldata message
    ) internal returns (uint80) {
        Types.Order memory order = orders[orderIndex];
        // honor seller max pub key:
        require(
            publicKeyIndex <= order.maxPubKeyIndex,
            "seller doesn't trusts pub key"
        );

        // verify bank signature:
        (uint256 exp, uint256[8] memory modulus) = PublicKeys.getValidPublicKey(
            publicKeys,
            publicKeyIndex,
            pubKeyDateRef
        );

        require(
            RSA.verifySig2048SHA256(message, sig, exp, modulus),
            "invalid signature"
        );
        (uint32 dateDays, uint48 nonce, uint160 dest, uint80 amount) = Parser
            .parseMessage(message);

        {
            uint32 unixDays = uint32(block.timestamp / 60 / 60 / 24);

            // Receipt should be up to 7 days older and  newer
            require(
                dateDays >= (unixDays - 7) && dateDays <= (unixDays + 7),
                "out of date"
            );
        }

        // verify seller bank account and SPEI nonce:
        require(order.nonce == nonce && order.dest == dest, "nonce or dest");

        return amount;
    }
}






library Disable {
    function enableOrder(
        mapping(uint256 => Types.OrderVariables) storage orderVars,
        uint256 orderIndex
    ) internal {
        Types.OrderVariables memory order = orderVars[orderIndex];
        orderVars[orderIndex] = Types.OrderVariables({
            // copy:
            funds: order.funds,
            locked: order.locked,
            expire: order.expire,
            lockTime: order.lockTime,
            lockRatio10000: order.lockRatio10000,
            coinIndex: order.coinIndex,

            // update:
            disabled: false
        });
    }

    function disableOrder(
        mapping(uint256 => Types.OrderVariables) storage orderVars,
        uint256 orderIndex
    ) internal {
        Types.OrderVariables memory order = orderVars[orderIndex];
        orderVars[orderIndex] = Types.OrderVariables({
            // copy:
            funds: order.funds,
            locked: order.locked,
            expire: order.expire,
            lockTime: order.lockTime,
            lockRatio10000: order.lockRatio10000,
            coinIndex: order.coinIndex,

            // update
            disabled: true
        });
    }
}






library Creator {}












library Funding {
      /** Add funds to a sell order */
    function fundOrder(
            mapping(uint256 => Types.OrderVariables) storage orderVars,
            mapping(uint16 => address) storage coins,
            uint256 orderIndex, 
            uint80 amount) internal {
        require(amount  > 0, "amount is 0");
        // No need to verify that seller == msg.sender, anyone can fund an order
        Types.OrderVariables memory order = orderVars[orderIndex];
        
        address coin = coins[order.coinIndex];
        if(!IERC20(coin).transferFrom(msg.sender, address(this), uint256(amount) * 1000)) {
            revert("not enough funds");
        }

        orderVars[orderIndex] = Types.OrderVariables({
            // copy:
            locked: order.locked,
            expire: order.expire,
            disabled: order.disabled,
            lockRatio10000: order.lockRatio10000,
            lockTime: order.lockTime,
            coinIndex: order.coinIndex,

            // update:
            funds: order.funds + amount

        });
    }

    function defundOrder(
            mapping(uint256 => Types.OrderVariables) storage orderVars,
            mapping(uint16 => address) storage coins,
            uint256 orderIndex, 
            uint80 amount
            ) internal {
        require(amount > 0, "amount is zero");
        
        Types.OrderVariables memory order = orderVars[orderIndex];
        uint80 locked = Utils.getLockedAmount(order.locked, order.expire, uint32(block.timestamp / 60));
        uint80 free = order.funds - locked;

        require(amount <= free, "amount more than free funds");

        address coin = coins[order.coinIndex];
        if(!IERC20(coin).transfer(msg.sender, uint256(amount) * 1000)) {
            // unreachable
            revert("not enough balance in contract");
        }

        orderVars[orderIndex] = Types.OrderVariables({
            // copy
            expire: order.expire,
            lockTime: order.lockTime,
            lockRatio10000: order.lockRatio10000,
            disabled: order.disabled,
            coinIndex: order.coinIndex,

            // update
            funds: order.funds - amount,
            locked: locked
        });
    }
}


library Lock {
     /** Lock "amount" for the given order. Caller will pay amount * lockRatio  */
    function lockOrder(
        mapping(uint256 => Types.OrderVariables) storage orderVars,
        mapping(uint16 => address) storage coins,
        mapping(address => mapping(uint256 => Types.BuyerLock)) storage buyerLocks,
        uint256 orderIndex, 
        uint80 amount) internal {
        Types.OrderVariables memory order = orderVars[orderIndex];
        require(order.lockTime > 0, "order doesn't exists");
        require(!order.disabled, "order disabled");
        require(amount > 0, "amount is zero");

        address coin = coins[order.coinIndex];
        uint32 unixMinutes = uint32(block.timestamp / 60);
        uint80 lock =  Utils.getLockedAmount(order.locked, order.expire, unixMinutes);
        uint80 free = order.funds - lock;

        require(amount <= free, "not enough order funds");

        // Buyer pays amount * lockRatio
        uint80 fundsDelta = Utils.mulRatio(amount, order.lockRatio10000, 10000);
        if(fundsDelta > 0) {
            if(!IERC20(coin).transferFrom(msg.sender, address(this), uint256(fundsDelta) * 1000)) {
                revert("not enough funds");
            }
        }

        // Increment order funds and lock:

        uint32 expire = unixMinutes + order.lockTime;
        orderVars[orderIndex] = Types.OrderVariables({
            // copy:
            lockRatio10000: order.lockRatio10000,
            lockTime: order.lockTime,
            coinIndex: order.coinIndex,
            disabled: false,

            // update:
            funds: order.funds + fundsDelta,
            locked: lock + fundsDelta + amount,
            expire: expire
        });

        // Increment buyer lock:
        Types.BuyerLock memory buyerLock = buyerLocks[msg.sender][orderIndex];
        uint80 bLock =  Utils.getLockedAmount(buyerLock.amount, buyerLock.expire, unixMinutes);
        buyerLocks[msg.sender][orderIndex] = Types.BuyerLock({
            amount: bLock + fundsDelta + amount,
            expire: expire,
            publicKeyDateRef: unixMinutes
        });
    }
    
 
}









contract SPEI {
    event OrderCreated(uint256 index, address indexed seller);
    event BuyExecuted(uint80 amount);
    event OrderLocked(uint256 index, address indexed buyer);

    /** 

    ************************************************************************
    |  Feel free to buy me a cup of coffee by donating to this address :)  |
    ************************************************************************

     */
    address owner;

    constructor() {
        owner = msg.sender;
        initCoins();
    }

    // ***********************************
    // owner functions:
    // ***********************************

    modifier onlyOwner() {
        require(msg.sender == owner, "owner only");
        _;
    }

    function initCoins() private onlyOwner {
        require(coinCount == 0, "coins already initted");

        uint16 c = Coins.initCoins(coins, coinCount);
        coinCount = c;
    }

    function addCoin(address coin) external onlyOwner {
        require(coinCount > 0, "call initCoins");
        coins[coinCount] = coin;
        coinCount++;
    }

    function requestTimelockChange() external onlyOwner {
        uint32 unixMinutes = uint32(block.timestamp / 60);
        timeLockChangeEnabledAt = unixMinutes + timeLock;
    }

    /** Send collected fees to owner */
    function collectFees(address coin) external onlyOwner {
        uint256 balance = ownerFees[coin];
        require(balance > 0);

        if (!IERC20(coin).transfer(owner, uint256(balance) * 1000)) {
            revert("not enough funds");
        }
        ownerFees[coin] -= balance;
    }

    modifier onlyOwnerInTimelock() {
        require(msg.sender == owner);
        {
            uint32 unixMinutes = uint32(block.timestamp / 60);
            require(
                unixMinutes >= timeLockChangeEnabledAt &&
                    unixMinutes < (timeLockChangeEnabledAt + 60 * 3),
                "timelock only"
            );
        }
        _;
    }

    function changeOwner(address next) external onlyOwnerInTimelock {
        owner = next;
    }

    function changeTimelock(uint16 newTimelock) external onlyOwnerInTimelock {
        // Max timelock is 1 week
        require(newTimelock < 60 * 24 * 7);
        require(fixedTimeLock == false);

        timeLock = newTimelock;
    }

    function changeFee(uint8 newFee) external onlyOwnerInTimelock {
        ownerFeeRatio = newFee;
    }

    /** Adds a new bank public key that will be enabled after "timeLock" minutes */
    function addPublicKey(uint256 exp, uint256[8] memory modulus)
        external
        onlyOwner
    {
        uint16 index = publicKeyCount;
        PublicKeys.addPublicKey(publicKeys, timeLock, index, exp, modulus);
        publicKeyCount = index + 1;
    }

    /** Disables a public key after "timeLock" minutes */
    function disablePublicKey(uint16 index) external onlyOwner {
        PublicKeys.disablePublicKey(publicKeys, timeLock, index);
    }

    /** Disables the ability to change the timelock */
    function fixTimelock() external onlyOwner {
        fixedTimeLock = true;
    }

    /** Time required for owner to update public keys in minutes */
    uint16 public timeLock;
    /** timeLock and owner fee will be able change in the range [timeLockChangeEnabledAt, timeLockChangeEnabledAt + 3 hours] */
    uint32 public timeLockChangeEnabledAt;

    /** Prevents the timelock to be changed */
    bool public fixedTimeLock;

    /** 
        Owner fee for any executed buys in 0.1% steps,
        so max fee == 25.6%
        Fee can only be changed inside the timelock period
     */
    uint8 public ownerFeeRatio;

    /** Collected fees for each ERC20 coin */
    mapping(address => uint256) public ownerFees;

    /** For each order, the seller address */
    mapping(uint256 => address) internal orderSellers;

    /** All sell orders */
    mapping(uint256 => Types.Order) internal orders;

    /** Order variable data */
    mapping(uint256 => Types.OrderVariables) internal orderVars;

    /** For each buyer and order, the locked funds */
    mapping(address => mapping(uint256 => Types.BuyerLock)) internal buyerLocks;

    /** Public keys count, also the next public key index */
    uint16 internal publicKeyCount;

    /** Bank public keys */
    mapping(uint16 => Types.PublicKey) internal publicKeys;

    /** 
        Least significant 256 bits of already spent message signatures 
        Note that we didn't found a way to prevent double spending without tracking each receipt separately,
        this is an open problem that might be related to a secure way to generate random and non repeatable SPEI nonces
    */
    mapping(uint256 => bool) internal spentSignatures;

    /** coin address index */
    mapping(uint16 => address) internal coins;
    uint16 internal coinCount;

    function orderSeller(uint256 index) external view returns (address) {
        return orderSellers[index];
    }

    function getCoinCount() external view returns (uint16) {
        return coinCount;
    }

    function getCoin(uint16 index) external view returns (address) {
        return coins[index];
    }

    function orderDefinition(uint256 index)
        external
        view
        returns (Types.Order memory)
    {
        return orders[index];
    }

    function orderVariables(uint256 index)
        external
        view
        returns (Types.OrderVariables memory)
    {
        return orderVars[index];
    }

    function buyerLock(address buyer, uint256 order)
        external
        view
        returns (Types.BuyerLock memory)
    {
        return buyerLocks[buyer][order];
    }

    function getPublicKeyCount() external view returns (uint16) {
        return publicKeyCount;
    }

    function getValidPublicKey(uint16 orderIndex)
        external
        view
        returns (uint256 exp, uint256[8] memory modulus)
    {
        return
            PublicKeys.getValidPublicKey(
                publicKeys,
                orderIndex,
                uint32(block.timestamp / 60)
            );
    }

    function getPublicKey(uint16 index)
        external
        view
        returns (Types.PublicKey memory)
    {
        return publicKeys[index];
    }

    function getOwnerFees(address coin) external view returns (uint256) {
        return ownerFees[coin];
    }

    /** Creates a sell order and returns the order index. Caller must pay "funds" in "coin" */
    function createOrder(
        uint256 index,
        uint80 funds,
        uint160 dest,
        uint16 coinIndex,
        uint16 priceMXN1000Num,
        uint16 priceMXN1000Den,
        uint48 nonce,
        uint16 lockRatio10000,
        uint16 lockTime,
        uint16 maxPubKeyIndex
    ) external returns (uint256) {
        require(priceMXN1000Num > 0, "price num");
        require(priceMXN1000Den > 0, "price den");
        require(lockTime > 0, "lockTime is 0");

        // Can't overwrite orders:
        require(orderSellers[index] == address(0), "order already exists");

        if (funds > 0) {
            address coin = coins[coinIndex];
            require(coin != address(0), "invalid coin");

            if (
                !IERC20(coin).transferFrom(
                    msg.sender,
                    address(this),
                    uint256(funds) * 1000
                )
            ) {
                revert("not enough funds");
            }
        }

        orderSellers[index] = msg.sender;

        orders[index] = Types.Order({
            dest: dest,
            nonce: nonce,
            priceMXN1000Num: priceMXN1000Num,
            priceMXN1000Den: priceMXN1000Den,
            maxPubKeyIndex: maxPubKeyIndex
        });

        orderVars[index] = Types.OrderVariables({
            funds: funds,
            locked: 0,
            expire: 0,
            disabled: false,
            lockRatio10000: lockRatio10000,
            lockTime: lockTime,
            coinIndex: coinIndex
        });

        emit OrderCreated(index, msg.sender);

        return index;
    }

    /** Add funds to a sell order. Anyone can fund an order */
    function fundOrder(uint256 orderIndex, uint80 amount) external {
        Funding.fundOrder(orderVars, coins, orderIndex, amount);
    }

    /** Withdraw funds from a sell order */
    function defundOrder(uint256 orderIndex, uint80 amount) external {
        address seller = orderSellers[orderIndex];
        require(seller == msg.sender);

        return Funding.defundOrder(orderVars, coins, orderIndex, amount);
    }

    /** Prevent any buyer from locking this order */
    function disableOrder(uint256 orderIndex) external {
        require(orderSellers[orderIndex] == msg.sender);
        Disable.disableOrder(orderVars, orderIndex);
    }

    /** Allow again buyers to lock this order */
    function enableOrder(uint256 orderIndex) external {
        require(orderSellers[orderIndex] == msg.sender);
        Disable.enableOrder(orderVars, orderIndex);
    }

    /** Lock "amount" for the given order. Caller will pay amount * lockRatio  */
    function lockOrder(uint256 orderIndex, uint80 amount) external {
        Lock.lockOrder(orderVars, coins, buyerLocks, orderIndex, amount);
        emit OrderLocked(orderIndex, msg.sender);
    }

    /** Executes an already verified buy */
    function executeBuy(
        uint256 orderIndex,
        uint80 amountMXN,
        Types.BuyerLock memory lock
    ) internal {
        Types.Order memory order = orders[orderIndex];
        uint80 amount = Buy.executeBuy(
            orderVars,
            ownerFees,
            coins,
            buyerLocks,
            lock,
            orderIndex,
            amountMXN,
            order.priceMXN1000Num,
            order.priceMXN1000Den,
            ownerFeeRatio
        );

        emit BuyExecuted(amount);
    }

    /** Buys a sell order */
    function buy(
        uint256 orderIndex,
        uint16 publicKeyIndex,
        uint256[8] memory sig,
        string calldata message
    ) external {
        Types.BuyerLock memory lock = buyerLocks[msg.sender][orderIndex];

        uint80 amountMXN = Receipt.getReceiptValidAmount(
            publicKeys,
            orders,
            orderIndex,
            publicKeyIndex,
            lock.publicKeyDateRef,
            sig,
            message
        );
        require(!spentSignatures[sig[3]], "already spent");
        executeBuy(orderIndex, amountMXN, lock);
        spentSignatures[sig[3]] = true;
    }
}

contract SPEITest is SPEI {
    function executeBuyTest(uint256 orderIndex, uint80 amountMXN) external {
        Types.BuyerLock memory lock = buyerLocks[msg.sender][orderIndex];
        executeBuy(orderIndex, amountMXN, lock);
    }
}