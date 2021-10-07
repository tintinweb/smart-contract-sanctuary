/**
 *Submitted for verification at arbiscan.io on 2021-10-04
*/

// Degens Protocol (C) degens.com

pragma solidity ^0.7.6;

interface IERC20Token {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract Degens {
    // Constants

    uint private constant MAX_SANE_AMOUNT = (2**128) - 1;
    uint private constant MIN_SANE_AMOUNT = 2;
    uint private constant MAX_PRICE = 1000000000;

    bytes32 immutable private EIP712_DOMAIN;

    constructor() {
        uint chainId;
        assembly { chainId := chainid() }

        EIP712_DOMAIN = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("Degens"),
            keccak256("1.0"),
            chainId,
            address(this)
        ));
    }


    // Events

    event LogRequestTrade(address indexed sender);
    event LogRequestMatchOrders(address indexed sender);
    event LogRequestClaim(address indexed sender);
    event LogRequestRecoverFunds(address indexed sender);

    event LogTrade(
        address indexed takerAccount,
        address indexed makerAccount,
        uint indexed matchId,
        address token,
        uint orderFillHash,
        uint8 orderDirection,
        uint32 price,
        uint longAmount,
        int newLongPosition,
        uint shortAmount,
        int newShortPosition,
        int longBalanceDelta,
        int shortBalanceDelta
    );

    event LogTradeError(
        address indexed takerAccount,
        address indexed makerAccount,
        uint indexed matchId,
        address token,
        uint orderFillHash,
        uint16 status
    );

    event LogCancel(
        address indexed account,
        address token,
        uint amount,
        uint orderGroup
    );

    event LogCancelAll(
        address indexed account,
        uint timestamp
    );

    event LogFinalizeMatch(
        uint indexed matchId,
        uint32 finalPrice
    );

    event LogClaim(
        address indexed account,
        uint indexed matchId,
        address indexed token,
        uint amount,
        uint graderFee
    );


    // Storage

    struct Match {
        mapping(address => mapping(address => int)) positions; // account => token => position
        bool finalized;
        uint32 finalPrice;
        uint32 graderFee;
        address[] graders;
    }

    mapping(uint => Match) private matches;
    mapping(uint => uint) private filledAmounts;
    mapping(address => uint) private cancelTimestamps;


    // Order

    struct Order {
        address maker;
        address taker;
        address token;
        uint matchId;
        uint amount;
        uint32 price;
        uint8 direction;
        uint expiry;
        uint timestamp;
        uint orderGroup;

        uint fillHash;
    }

    bytes32 private constant EIP712_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(
        "Order(",
            "address maker,",
            "address taker,",
            "address token,",
            "uint256 matchId,",
            "uint256 amount,",
            "uint256 price,",
            "uint256 direction,",
            "uint256 expiry,",
            "uint256 timestamp,",
            "uint256 orderGroup",
        ")"
    ));

    function unpackShared(uint[4] memory packed, Order memory o) private view {
        o.maker = address(packed[0] >> (12*8));
        o.taker = packed[0] & (0x01 << (11*8)) == 0 ? address(0) : msg.sender;
        o.amount = packed[1] >> (16*8);
        o.price = uint32(packed[1] >> uint32((12*8)) & 0xFFFFFFFF);
        o.direction = uint8((packed[0] >> (10*8)) & 0xFF);
        o.expiry = (packed[0] >> (5*8)) & 0xFFFFFFFFFF;
        o.timestamp = packed[0] & 0xFFFFFFFFFF;
        o.orderGroup = packed[1] & 0xFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    function computeFillHash(Order memory o) private pure {
        o.fillHash = uint(keccak256(abi.encodePacked(o.maker, o.token, o.amount, o.orderGroup)));
    }

    function unpackOrder(uint matchId, address token, uint[4] memory packed) private view returns(Order memory o) {
        unpackShared(packed, o);

        o.token = token;
        o.matchId = matchId;

        computeFillHash(o);

        bytes32 signatureHash = keccak256(abi.encodePacked(
            "\x19\x01",
            EIP712_DOMAIN,
            keccak256(abi.encode(
                EIP712_ORDER_SCHEMA_HASH,
                o.maker,
                o.taker,
                o.token,
                o.matchId,
                o.amount,
                uint(o.price),
                uint(o.direction),
                o.expiry,
                o.timestamp,
                o.orderGroup
            ))
        ));

        if ((packed[0] & (0x02 << (11*8))) != 0) signatureHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signatureHash));

        require(ecrecoverPacked(signatureHash, packed[2], packed[3]) == o.maker, "DERR_INVALID_ORDER_SIGNATURE");
        require(o.taker == address(0) || o.taker == msg.sender, "DERR_INVALID_TAKER"); // not reachable
        require(o.price > 0 && o.price < MAX_PRICE, "DERR_INVALID_PRICE");
        require(o.direction < 2, "DERR_INVALID_DIRECTION");
    }

    function unpackOrderForQuery(uint[4] memory packed) private view returns(Order memory o) {
        unpackShared(packed, o);

        o.matchId = packed[2];
        o.token = address(packed[3]);
        o.taker = address(0);

        computeFillHash(o);
    }


    // Trade

    enum TradeStatus {
        INVALID,
        OK,

        TAKER_NO_BALANCE,
        TRADE_EXPIRED,
        MATCH_FINALIZED,
        TRADE_TOO_SMALL,

        ORDER_NO_BALANCE,
        ORDER_EXPIRED,
        ORDER_CANCELLED,

        AMOUNT_MALFORMED,
        SELF_TRADE
    }

    struct Trade {
        TradeStatus status;
        address longAddr;
        address shortAddr;
        int newLongPosition;
        int newShortPosition;
        int longBalanceDelta;
        int shortBalanceDelta;
        uint shortAmount;
        uint longAmount;
        uint takerAmount;
        uint makerAmount;
    }


    // External interface

    fallback() external {
        revert("DERR_UNKNOWN_METHOD");
    }

    receive() payable external {
        revert("DERR_UNKNOWN_METHOD2");
    }

    function trade(uint amount, uint expiry, uint matchId, address token, uint[4][] calldata packedOrders) external {
        emit LogRequestTrade(msg.sender);

        if (expiry != 0 && block.timestamp >= expiry) {
            emit LogTradeError(msg.sender, address(0), matchId, token, 0, uint16(TradeStatus.TRADE_EXPIRED));
            return;
        }

        require(packedOrders.length > 0, "DERR_EMPTY_PACKEDORDERS");

        uint amountRemaining = amount;

        for (uint i = 0; i < packedOrders.length; i++) {
            Order memory o = unpackOrder(matchId, token, packedOrders[i]);

            Trade memory t = tradeCore(amountRemaining, o, false);

            if (t.status == TradeStatus.OK) {
                applyTradePositions(o, t);
                applyTradeBalances(o, t);
                applyTradeLog(o, t);
                amountRemaining = safeSub(amountRemaining, t.takerAmount);
            } else {
                emit LogTradeError(msg.sender, o.maker, o.matchId, o.token, o.fillHash, uint16(t.status));
            }

            if (amountRemaining < MIN_SANE_AMOUNT) break;
        }
    }

    function matchOrders(uint matchId, address token, uint[4] calldata packedLeftOrder, uint[4][] calldata packedRightOrders) external {
        emit LogRequestMatchOrders(msg.sender);

        require(packedRightOrders.length > 0, "DERR_EMPTY_PACKEDRIGHTORDERS");

        Order memory leftOrder = unpackOrder(matchId, token, packedLeftOrder);

        for (uint i = 0; i < packedRightOrders.length; i++) {
            Order memory rightOrder = unpackOrder(matchId, token, packedRightOrders[i]);

            require(leftOrder.maker != rightOrder.maker, "DERR_SAME_MAKER");
            require(rightOrder.direction != leftOrder.direction, "DERR_SAME_DIRECTION");


            (uint leftMaxPosition, uint leftAmount) = computeMaxPosition(leftOrder);
            (uint rightMaxPosition, uint rightAmount) = computeMaxPosition(rightOrder);

            if (leftMaxPosition > rightMaxPosition) {
                leftAmount = uint(priceDivide(int(rightMaxPosition), leftOrder.direction == 1 ? (MAX_PRICE - leftOrder.price) : leftOrder.price));
            } else {
                rightAmount = uint(priceDivide(int(leftMaxPosition), leftOrder.direction == 1 ? rightOrder.price : (MAX_PRICE - rightOrder.price)));
            }


            Trade memory rightTrade = tradeCore(rightAmount, rightOrder, true);

            if (rightTrade.status != TradeStatus.OK) {
                emit LogTradeError(msg.sender, rightOrder.maker, rightOrder.matchId, rightOrder.token, rightOrder.fillHash, uint16(rightTrade.status));
                continue;
            }

            applyTradePositions(rightOrder, rightTrade);

            Trade memory leftTrade = tradeCore(leftAmount, leftOrder, true);

            require(leftTrade.status == TradeStatus.OK, "DERR_LEFT_TRADE_FAIL");

            applyTradePositions(leftOrder, leftTrade);


            int takerBalanceDelta = 0;

            if (leftOrder.direction == 1) {
                takerBalanceDelta = leftTrade.shortBalanceDelta + rightTrade.longBalanceDelta;
                leftTrade.shortBalanceDelta = rightTrade.longBalanceDelta = 0;
            } else {
                takerBalanceDelta = leftTrade.longBalanceDelta + rightTrade.shortBalanceDelta;
                leftTrade.longBalanceDelta = rightTrade.shortBalanceDelta = 0;
            }


            if (takerBalanceDelta < 0) adjustBalance(leftOrder.token, msg.sender, takerBalanceDelta);

            if (leftTrade.shortBalanceDelta + leftTrade.longBalanceDelta < rightTrade.shortBalanceDelta + rightTrade.longBalanceDelta) {
                applyTradeBalances(leftOrder, leftTrade);
                applyTradeBalances(rightOrder, rightTrade);
            } else {
                applyTradeBalances(rightOrder, rightTrade);
                applyTradeBalances(leftOrder, leftTrade);
            }

            if (takerBalanceDelta > 0) adjustBalance(leftOrder.token, msg.sender, takerBalanceDelta);


            applyTradeLog(rightOrder, rightTrade);
            applyTradeLog(leftOrder, leftTrade);
        }
    }

    function cancel(address token, uint amount, uint orderGroup) external {
        require(orderGroup <= 0xFFFFFFFFFFFFFFFFFFFFFFFF, "DERR_BAD_ORDERGROUP");
        uint fillHash = uint(keccak256(abi.encodePacked(msg.sender, token, amount, orderGroup)));
        filledAmounts[fillHash] = uint(-1);
        emit LogCancel(msg.sender, token, amount, orderGroup);
    }

    function cancelAll() external {
        cancelTimestamps[msg.sender] = block.timestamp;
        emit LogCancelAll(msg.sender, block.timestamp);
    }

    function claim(bytes32 witness, uint256 graderQuorum, uint256 graderFee, address[] calldata graders, uint32 finalPrice, uint256[2][] calldata sigs, uint256[] calldata targets) external {
        emit LogRequestClaim(msg.sender);

        uint matchId = uint(keccak256(abi.encodePacked(witness, graderQuorum, graderFee, graders)));

        Match storage m = matches[matchId];

        if (!m.finalized) {
            require(graderQuorum > 0, "DERR_ZERO_GRADER_QUORUM");
            require(sigs.length == graders.length, "DERR_INVALID_NUM_SIGS");
            require(graderFee <= MAX_PRICE, "DERR_INVALID_GRADERFEE");

            bytes32 messageHash = keccak256(abi.encodePacked(
                                      "\x19Ethereum Signed Message:\n32",
                                      keccak256(abi.encodePacked(address(this), matchId, finalPrice))
                                  ));

            uint validated = 0;

            for (uint i = 0; i < graders.length; i++) {
                if (sigs[i][0] != 0) {
                    address signer = ecrecoverPacked(messageHash, sigs[i][0], sigs[i][1]);
                    require(signer == graders[i], "DERR_BAD_GRADER_SIG");
                    m.graders.push(graders[i]);
                    validated++;
                }
            }

            require(validated >= graderQuorum, "DERR_INSUFFICIENT_GRADERS");

            bool waiveFees = (finalPrice & 0x80000000) != 0;
            uint32 maskedPrice = finalPrice & 0x7fffffff;

            m.finalized = true;
            m.finalPrice = maskedPrice;
            m.graderFee = waiveFees ? 0 : uint32(graderFee);

            require(m.finalPrice <= MAX_PRICE, "DERR_BAD_FINALPRICE");

            emit LogFinalizeMatch(matchId, finalPrice);
        }

        processClaims(matchId, targets);
    }

    function claimFinalized(uint matchId, uint256[] calldata targets) external {
        emit LogRequestClaim(msg.sender);

        Match storage m = matches[matchId];

        require(m.finalized, "DERR_MATCH_NOT_FINALIZED");

        processClaims(matchId, targets);
    }

    function recoverFunds(uint256 detailsHash, uint256 recoveryTime, uint256 cancelPrice, uint256 graderQuorum, uint256 graderFee, address[] calldata graders) external {
        emit LogRequestRecoverFunds(msg.sender);

        bytes32 witness = keccak256(abi.encodePacked(detailsHash, recoveryTime, cancelPrice));
        uint matchId = uint(keccak256(abi.encodePacked(witness, graderQuorum, graderFee, graders)));

        Match storage m = matches[matchId];

        require(!m.finalized, "DERR_MATCH_IS_FINALIZED");
        require(recoveryTime < block.timestamp, "DERR_TOO_SOON_TO_RECOVER");
        require(cancelPrice <= MAX_PRICE, "DERR_INVALID_CANCELPRICE");

        m.finalized = true;
        m.finalPrice = uint32(cancelPrice);
        m.graderFee = 0;

        emit LogFinalizeMatch(matchId, uint32(cancelPrice));
    }


    // External read-only interface

    function getPosition(uint matchId, address account, address token) external view returns(int) {
        return matches[matchId].positions[account][token];
    }

    function getFinalizedStatus(uint matchId) external view returns(bool, uint32, uint32, address[] memory graders) {
        Match storage m = matches[matchId];
        return (m.finalized, m.finalPrice, m.graderFee, m.graders);
    }

    function getFilledAmount(bytes32 fillHash) external view returns(uint) {
        return filledAmounts[uint(fillHash)];
    }

    function getCancelTimestamp(address account) external view returns(uint) {
        return cancelTimestamps[account];
    }

    function testOrder(uint[4] calldata packed) external view returns(uint256, uint256) {
        Order memory o = unpackOrderForQuery(packed);
        return (getOrderAmount(o), filledAmounts[o.fillHash]);
    }


    // Utilities that modify storage

    function adjustBalance(address token, address addr, int delta) private {
        if (delta > 0) {
            require(IERC20Token(token).transfer(addr, uint(delta)), "DERR_TOKEN_TRANSFER_FAIL");
        } else if (delta < 0) {
            require(IERC20Token(token).transferFrom(addr, address(this), uint(-1 * delta)), "DERR_TOKEN_TRANSFERFROM_FAIL");
        }
    }

    function applyTradePositions(Order memory o, Trade memory t) private {
        assert(t.status == TradeStatus.OK);

        Match storage m = matches[o.matchId];

        m.positions[t.longAddr][o.token] = t.newLongPosition;
        m.positions[t.shortAddr][o.token] = t.newShortPosition;
    }

    function applyTradeBalances(Order memory o, Trade memory t) private {
        assert(t.status == TradeStatus.OK);

        if (t.longBalanceDelta < t.shortBalanceDelta) {
            adjustBalance(o.token, t.longAddr, t.longBalanceDelta);
            adjustBalance(o.token, t.shortAddr, t.shortBalanceDelta);
        } else {
            adjustBalance(o.token, t.shortAddr, t.shortBalanceDelta);
            adjustBalance(o.token, t.longAddr, t.longBalanceDelta);
        }

        filledAmounts[o.fillHash] += (o.direction == 0 ? t.shortAmount : t.longAmount);
    }

    function applyTradeLog(Order memory o, Trade memory t) private {
        emit LogTrade(msg.sender, o.maker, o.matchId, o.token, o.fillHash, o.direction, o.price, t.longAmount, t.newLongPosition, t.shortAmount, t.newShortPosition, t.longBalanceDelta, t.shortBalanceDelta);
    }

    function processClaims(uint matchId, uint256[] memory targets) private {
        Match storage m = matches[matchId];
        assert(m.finalized);
        assert(m.graderFee <= MAX_PRICE);

        for (uint i = 0; i < targets.length;) {
            address token = address(targets[i] & 0x00ffffffffffffffffffffffffffffffffffffffff);
            int totalFee = 0;

            for (i++; i < targets.length && (targets[i] & (1<<255)) == 0; i++) {
                address addr = address(targets[i]);
                int delta = 0;
                int targetPosition = m.positions[addr][token];

                if (targetPosition > 0) {
                    delta = priceDivide(targetPosition, m.finalPrice);
                } else if (targetPosition < 0) {
                    delta = priceDivide(-targetPosition, MAX_PRICE - m.finalPrice);
                } else {
                    continue;
                }

                assert(delta >= 0);

                int fee = priceDivide(delta, m.graderFee);
                assert(fee >= 0);

                delta -= fee;
                totalFee += fee;

                assert(delta >= 0);

                m.positions[addr][token] = 0;
                adjustBalance(token, addr, delta);

                emit LogClaim(addr, matchId, token, uint(delta), uint(fee));
            }

            if (m.graderFee == 0 || totalFee == 0) continue;

            int feePerGrader = totalFee / int(m.graders.length);

            for (uint j = 0; j < m.graders.length - 1; j++) {
                totalFee -= feePerGrader;
                adjustBalance(token, m.graders[j], feePerGrader);
            }

            adjustBalance(token, m.graders[m.graders.length - 1], totalFee);
        }
    }


    // Utilities that read from storage

    function lookupBalance(address token, address addr) private view returns(uint) {
        uint balance = minu256(IERC20Token(token).balanceOf(addr), IERC20Token(token).allowance(addr, address(this)));
        require(balance <= MAX_SANE_AMOUNT, "DERR_BALANCE_INSANE");

        return balance;
    }

    function tradeCore(uint amount, Order memory o, bool takerUnlimitedBalance) private view returns(Trade memory t) {
        t.status = TradeStatus.INVALID;

        if (block.timestamp >= o.expiry) {
            t.status = TradeStatus.ORDER_EXPIRED;
            return t;
        }

        uint orderFilledAmount = filledAmounts[o.fillHash];

        if (cancelTimestamps[o.maker] >= o.timestamp || orderFilledAmount == uint(-1)) {
            t.status = TradeStatus.ORDER_CANCELLED;
            return t;
        }

        if (msg.sender == o.maker) {
            t.status = TradeStatus.SELF_TRADE;
            return t;
        }

        if (amount > MAX_SANE_AMOUNT) {
            t.status = TradeStatus.AMOUNT_MALFORMED;
            return t;
        }

        Match storage m = matches[o.matchId];

        if (m.finalized) {
            t.status = TradeStatus.MATCH_FINALIZED;
            return t;
        }


        uint longAmount;
        uint shortAmount;
        uint longBalance;
        uint shortBalance;

        if (o.direction == 0) {
            // maker short, taker long
            t.longAddr = msg.sender;
            longAmount = amount;

            t.shortAddr = o.maker;
            shortAmount = safeSub(o.amount, orderFilledAmount);

            longBalance = takerUnlimitedBalance ? MAX_SANE_AMOUNT : lookupBalance(o.token, t.longAddr);
            shortBalance = lookupBalance(o.token, t.shortAddr);
        } else {
            // maker long, taker short
            t.longAddr = o.maker;
            longAmount = safeSub(o.amount, orderFilledAmount);

            t.shortAddr = msg.sender;
            shortAmount = amount;

            longBalance = lookupBalance(o.token, t.longAddr);
            shortBalance = takerUnlimitedBalance ? MAX_SANE_AMOUNT : lookupBalance(o.token, t.shortAddr);
        }

        int oldLongPosition = m.positions[t.longAddr][o.token];
        int oldShortPosition = m.positions[t.shortAddr][o.token];

        longAmount = minu256(longAmount, computeEffectiveBalance(longBalance, oldLongPosition, o.price, true));
        shortAmount = minu256(shortAmount, computeEffectiveBalance(shortBalance, oldShortPosition, o.price, false));

        if (longAmount < MIN_SANE_AMOUNT) {
            t.status = o.direction == 0 ? TradeStatus.TAKER_NO_BALANCE : TradeStatus.ORDER_NO_BALANCE;
            return t;
        }

        if (shortAmount < MIN_SANE_AMOUNT) {
            t.status = o.direction == 0 ? TradeStatus.ORDER_NO_BALANCE : TradeStatus.TAKER_NO_BALANCE;
            return t;
        }

        (longAmount, shortAmount) = computePriceWeightedAmounts(longAmount, shortAmount, o.price);

        if (longAmount < MIN_SANE_AMOUNT || shortAmount < MIN_SANE_AMOUNT) {
            t.status = TradeStatus.TRADE_TOO_SMALL;
            return t;
        }

        int newLongPosition = oldLongPosition + (int(longAmount) + int(shortAmount));
        int newShortPosition = oldShortPosition - (int(longAmount) + int(shortAmount));


        t.longBalanceDelta = 0;
        t.shortBalanceDelta = 0;

        if (oldLongPosition < 0) t.longBalanceDelta += priceDivide(-oldLongPosition + min256(0, newLongPosition), MAX_PRICE - o.price);
        if (newLongPosition > 0) t.longBalanceDelta -= priceDivide(newLongPosition - max256(0, oldLongPosition), o.price);

        if (oldShortPosition > 0) t.shortBalanceDelta += priceDivide(oldShortPosition - max256(0, newShortPosition), o.price);
        if (newShortPosition < 0) t.shortBalanceDelta -= priceDivide(-newShortPosition + min256(0, oldShortPosition), MAX_PRICE - o.price);

        int exposureDelta = computeExposureDelta(t.longBalanceDelta, t.shortBalanceDelta, oldLongPosition, newLongPosition, oldShortPosition, newShortPosition);

        if (exposureDelta != 0) {
            if (exposureDelta == 1) {
                newLongPosition--;
                newShortPosition++;
            } else if (exposureDelta == -1) {
                t.longBalanceDelta++; // one left-over wei: arbitrarily give it to long
            } else {
                assert(false);
            }

            exposureDelta = computeExposureDelta(t.longBalanceDelta, t.shortBalanceDelta, oldLongPosition, newLongPosition, oldShortPosition, newShortPosition);
            assert(exposureDelta == 0);
        }


        t.status = TradeStatus.OK;
        t.newLongPosition = newLongPosition;
        t.newShortPosition = newShortPosition;
        t.shortAmount = shortAmount;
        t.longAmount = longAmount;

        if (o.direction == 0) {
            t.takerAmount = t.longAmount;
            t.makerAmount = t.shortAmount;
        } else {
            t.takerAmount = t.shortAmount;
            t.makerAmount = t.longAmount;
        }

        return t;
    }

    function getOrderAmount(Order memory o) private view returns(uint) {
        if (block.timestamp >= o.expiry || cancelTimestamps[o.maker] >= o.timestamp) return 0;

        uint filled = filledAmounts[o.fillHash];
        if (filled == uint(-1)) return 0;

        Match storage m = matches[o.matchId];

        uint amount = safeSub(o.amount, filled);
        int position = m.positions[o.maker][o.token];

        return minu256(amount, computeEffectiveBalance(lookupBalance(o.token, o.maker), position, o.price, o.direction == 1));
    }

    function computeMaxPosition(Order memory o) private view returns(uint, uint) {
        if (o.direction == 1) {
            (uint longAmount, uint shortAmount) = computePriceWeightedAmounts(getOrderAmount(o), MAX_SANE_AMOUNT, o.price);

            return (longAmount + shortAmount, shortAmount);
        } else {
            (uint longAmount, uint shortAmount) = computePriceWeightedAmounts(MAX_SANE_AMOUNT, getOrderAmount(o), o.price);

            return (longAmount + shortAmount, longAmount);
        }
    }


    // Pure utilities

    function ecrecoverPacked(bytes32 hash, uint r, uint sv) private pure returns (address) {
        return ecrecover(hash, uint8(27 + (sv >> 255)), bytes32(r), bytes32(sv & ((1<<255) - 1)));
    }

    function priceDivide(int amount, uint price) private pure returns(int) {
        assert(amount >= 0);
        return int(safeMul(uint(amount), price) / MAX_PRICE);
    }

    function computeEffectiveBalance(uint balance, int position, uint price, bool isLong) private pure returns(uint) {
        uint effectiveBalance = balance;

        if (isLong) {
            if (position < 0) effectiveBalance += uint(priceDivide(-position, price));
        } else {
            if (position > 0) effectiveBalance += uint(priceDivide(position, MAX_PRICE - price));
        }

        return effectiveBalance;
    }

    function computePriceWeightedAmounts(uint longAmount, uint shortAmount, uint price) private pure returns(uint, uint) {
        uint totalLongAmount = longAmount + (safeMul(longAmount, MAX_PRICE - price) / price);
        uint totalShortAmount = shortAmount + (safeMul(shortAmount, price) / (MAX_PRICE - price));

        if (totalLongAmount > totalShortAmount) {
            return (totalShortAmount - shortAmount, shortAmount);
        } else {
            return (longAmount, totalLongAmount - longAmount);
        }
    }

    function computeExposureDelta(int longBalanceDelta, int shortBalanceDelta, int oldLongPosition, int newLongPosition, int oldShortPosition, int newShortPosition) private pure returns(int) {
        int positionDelta = 0;
        if (newLongPosition > 0) positionDelta += newLongPosition - max256(0, oldLongPosition);
        if (oldShortPosition > 0) positionDelta -= oldShortPosition - max256(0, newShortPosition);

        return positionDelta + longBalanceDelta + shortBalanceDelta;
    }

    function safeMul(uint a, uint b) private pure returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) private pure returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function minu256(uint a, uint b) private pure returns(uint) {
        return a < b ? a : b;
    }

    function max256(int a, int b) private pure returns(int) {
        return a >= b ? a : b;
    }

    function min256(int a, int b) private pure returns(int) {
        return a < b ? a : b;
    }
}