/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

contract BNum {
    uint256 public constant BONE = 10**18;
    uint256 public constant MAX_IN_RATIO = BONE / 2;

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");
        // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL");
        //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }
}

interface PoolInterface {
    function calcInGivenOut(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256);

    function calcOutGivenIn(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256);

    function calcSpotPrice(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isBound(address) external view returns (bool);

    function isPublicSwap() external view returns (bool);

    function getBalance(address) external view returns (uint256);

    function getSpotPrice(address, address) external view returns (uint256);

    function getDenormalizedWeight(address) external view returns (uint256);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}

interface RegistryInterface {
    function getBestPoolsWithLimit(
        address,
        address,
        uint256
    ) external view returns (address[] memory);
}

contract Validator is BNum {
    address public owner;
    address private constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    struct Record {
        uint256 denorm;
        uint256 balance;
    }

    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERR_ONLYOWNER");
        _;
    }

    function isETH(TokenInterface token) internal pure returns (bool) {
        return (address(token) == ETH_ADDRESS);
    }

    function multihopBatchSwapExactInValidator(
        Swap[][] calldata swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut
    ) external view returns (bool) {
        uint256 totalAmountOut;
        if (isETH(tokenIn)) {
            require(
                msg.sender.balance >= totalAmountIn,
                "ERR_ETH_TRANSFER_FAILED"
            );
        } else {
            uint256 balance = tokenIn.allowance(msg.sender, address(this));
            require(balance >= totalAmountIn, "ERR_EXCESS_BALANCE");
            require(
                tokenIn.balanceOf(msg.sender) >= balance,
                "ERR_APPROVE_EXCESS_BALANCE"
            );
        }
        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountOut;
            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                if (k == 1) {
                    swap.swapAmount = tokenAmountOut;
                }

                PoolInterface pool = PoolInterface(swap.pool);
                (tokenAmountOut, ) = swapExactAmountIn(pool, swap);
            }
            totalAmountOut = badd(tokenAmountOut, totalAmountOut);
        }
        require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");
        return true;
    }

    function multihopBatchSwapExactOutValidator(
        Swap[][] calldata swapSequences,
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint256 maxTotalAmountIn
    ) external view returns (bool) {
        if (isETH(tokenIn)) {
            require(
                msg.sender.balance >= maxTotalAmountIn,
                "ERR_ETH_TRANSFER_FAILED"
            );
        } else {
            uint256 balance = tokenIn.allowance(msg.sender, address(this));
            require(balance >= maxTotalAmountIn, "ERR_EXCESS_BALANCE");
            require(
                tokenIn.balanceOf(msg.sender) >= balance,
                "ERR_APPROVE_EXCESS_BALANCE"
            );
        }
        uint256 totalAmountIn;
        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountInFirstSwap;
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                PoolInterface pool = PoolInterface(swap.pool);
                (tokenAmountInFirstSwap, ) = swapExactAmountOut(pool, swap);
            } else {
                uint256 intermediateTokenAmount;
                Swap memory secondSwap = swapSequences[i][1];
                PoolInterface poolSecondSwap = PoolInterface(secondSwap.pool);
                intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                    poolSecondSwap.getBalance(secondSwap.tokenIn),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                    poolSecondSwap.getBalance(secondSwap.tokenOut),
                    poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                    secondSwap.swapAmount,
                    poolSecondSwap.getSwapFee()
                );

                Swap memory firstSwap = swapSequences[i][0];

                PoolInterface poolFirstSwap = PoolInterface(firstSwap.pool);

                firstSwap.swapAmount = intermediateTokenAmount;
                (tokenAmountInFirstSwap, ) = swapExactAmountOut(
                    poolFirstSwap,
                    firstSwap
                );
                swapExactAmountOut(poolSecondSwap, secondSwap);
            }
            totalAmountIn = badd(tokenAmountInFirstSwap, totalAmountIn);
        }
        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");
        return true;
    }

    function swapExactAmountIn(PoolInterface pool, Swap memory swap)
        public
        view
        returns (uint256 tokenAmountOut, uint256 spotPriceAfter)
    {
        address tokenIn = swap.tokenIn;
        uint256 tokenAmountIn = swap.swapAmount;
        address tokenOut = swap.tokenOut;
        uint256 minAmountOut = swap.limitReturnAmount;
        uint256 maxPrice = swap.maxPrice;
        require(pool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(pool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(pool.isPublicSwap(), "ERR_SWAP_NOT_PUBLIC");
        Record memory inRecord;
        Record memory outRecord;

        inRecord.balance = pool.getBalance(tokenIn);
        inRecord.denorm = pool.getDenormalizedWeight(tokenIn);
        outRecord.balance = pool.getBalance(tokenOut);
        outRecord.denorm = pool.getDenormalizedWeight(tokenOut);
        uint256 maxInRatio = MAX_IN_RATIO;
        uint256 swapFee = pool.getSwapFee();

        require(
            tokenAmountIn <= bmul(inRecord.balance, maxInRatio),
            "ERR_MAX_IN_RATIO"
        );

        uint256 spotPriceBefore = pool.getSpotPrice(tokenIn, tokenOut);
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = pool.calcOutGivenIn(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountIn,
            swapFee
        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = pool.calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(
            spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
            "ERR_MATH_APPROX"
        );
        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(PoolInterface pool, Swap memory swap)
        public
        view
        returns (uint256 tokenAmountIn, uint256 spotPriceAfter)
    {
        address tokenIn = swap.tokenIn;
        address tokenOut = swap.tokenOut;
        uint256 maxAmountIn = swap.limitReturnAmount;
        uint256 tokenAmountOut = swap.swapAmount;
        uint256 maxPrice = swap.maxPrice;

        require(pool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(pool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(pool.isPublicSwap(), "ERR_SWAP_NOT_PUBLIC");

        Record memory inRecord;
        Record memory outRecord;

        inRecord.balance = pool.getBalance(tokenIn);
        inRecord.denorm = pool.getDenormalizedWeight(tokenIn);
        outRecord.balance = pool.getBalance(tokenOut);
        outRecord.denorm = pool.getDenormalizedWeight(tokenOut);
        uint256 maxInRatio = MAX_IN_RATIO;
        uint256 swapFee = pool.getSwapFee();
        require(
            tokenAmountOut <= bmul(outRecord.balance, maxInRatio),
            "ERR_MAX_OUT_RATIO"
        );

        uint256 spotPriceBefore =
            pool.calcSpotPrice(
                inRecord.balance,
                inRecord.denorm,
                outRecord.balance,
                outRecord.denorm,
                swapFee
            );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = pool.calcInGivenOut(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            tokenAmountOut,
            swapFee
        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = pool.calcSpotPrice(
            inRecord.balance,
            inRecord.denorm,
            outRecord.balance,
            outRecord.denorm,
            swapFee
        );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(
            spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut),
            "ERR_MATH_APPROX"
        );
        return (tokenAmountIn, spotPriceAfter);
    }
}