/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts/interfaces/mdex/IMdexGridPair.sol

pragma solidity >=0.8.0;

interface IMdexGridPair {
    event RewardWithdraw(uint256 s);

    function swapRewardWithdraw() external;
    function getSwapReward() external view returns (uint256);
}

// File: contracts/interfaces/mdex/IMdexSwapMining.sol

pragma solidity >=0.8.0;

interface IMdexSwapMining {
    function getUserReward(uint256 _pid) external view returns (uint256, uint256);
    function poolLength() external view returns (uint256);
    function mdx() external view returns (address);
    function takerWithdraw() external;
}

// File: contracts/interfaces/mdex/IMdexSwapRouter.sol

pragma solidity >=0.8.0;

interface IMdexSwapRouter {
    function swapMining() external pure returns (address);
}

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.8.0;

// https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

}

// File: contracts/interfaces/ISwapPair.sol

pragma solidity >=0.8.0;

interface ISwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// File: contracts/interfaces/ISwapRouter.sol

pragma solidity >=0.8.0;

interface ISwapRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// File: contracts/interfaces/IGridFactory.sol

pragma solidity >=0.8.0;

interface IGridFactory {
    event GridCreated(address indexed tokenT, 
                      address indexed tokenU, 
                      address indexed grid);

    // TODO: owner()?
    function getOwner() external view returns (address);

    function feeTo() external view returns (address);
    function setFeeTo(address) external;

    function bot() external view returns (address);
    function setBot(address) external;

    function allGrids(uint256) external view returns (address grid);
    function allGridsLength() external view returns (uint256);
    function createFixedRateGrid(address _tokenT, address _tokenU,
        uint256 _j, uint256 _k) external returns (address);
}

// File: contracts/interfaces/IGridPair.sol

pragma solidity >=0.8.0;





interface IGridPair {
    event Deposit (address indexed addr, uint256 t, uint256 u, uint256 newS, uint256 balancedT, uint256 balancedU);
    event Withdraw(address indexed addr, uint256 t, uint256 u, uint256 newS);
    event Buy (uint256 t, uint256 u, uint256 minT, uint256 maxU);
    event Sell(uint256 t, uint256 u, uint256 maxT, uint256 minU);

    function factory() external view returns (IGridFactory);
    function tokenT() external view returns (IERC20);
    function tokenU() external view returns (IERC20);
    function swapPair() external view returns (ISwapPair);
    function swapRouter() external view returns (ISwapRouter);

    function totalShares() external view returns (uint256 s);
    function balanceOf(address owner) external view returns (uint256 t, uint256 u, uint256 s);
    function lastSwap() external view returns (uint256 t, uint256 u, bool isBuy);

    function deposit(uint256 t, uint256 u) external;
    function withdraw(uint256 t, uint256 u) external;

    function buy()  external;
    function sell() external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

    constructor () {
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

// File: contracts/BaseGrid.sol

pragma solidity >=0.8.0;






// fit in one slot
struct UserInfo {
    uint192 shares;
    uint64  lastDepositTime; // in block
}

abstract contract BaseGrid is IGridPair, ReentrancyGuard {
    uint256 internal constant _10K = 10000;

    // TODO: set these params later
    bool    internal constant AUTO_BALANCE_UT   = true;
    uint256 internal constant DEPOSIT_LOCK_TIME = 1;    // in blocks, ~15s
    uint256 internal constant SERVICE_FEE_BPS   = 0;    // ‱
    uint256 internal constant WITHDRAW_FEE_BPS  = 0;    // ‱, WITHDRAWAL_FEE_BPS?
    uint256 internal constant PRICE_TOLERANCE   = 0;    // ‱


    IERC20       public immutable override tokenT;
    IERC20       public immutable override tokenU;
    ISwapPair    public immutable override swapPair;
    ISwapRouter  public immutable override swapRouter;
    IGridFactory public immutable override factory;

    uint256 public override totalShares;
    mapping(address => UserInfo) private users;

    constructor(address _tokenT, address _tokenU, address _swapPair, address _swapRouter) {
        factory  = IGridFactory(msg.sender);
        tokenT   = IERC20(_tokenT);
        tokenU   = IERC20(_tokenU);
        swapPair = ISwapPair(_swapPair);
        swapRouter = ISwapRouter(_swapRouter);

        // we trust grid factory
        // address token0 = ISwapPair(_swapPair).token0();
        // address token1 = ISwapPair(_swapPair).token1();
        // if (_tokenT == token0) {
        //     require(_tokenU == token1, "BG: tokenU != token1");
        // } else {
        //     require(_tokenT == token1, "BG: tokenT != token1");
        //     require(_tokenU == token0, "BG: tokenU != token0");
        // }
    }

    // TODO: use price oracle ?
    function getPrice() private view returns (uint256 t, uint256 u) {
        (uint112 r0, uint112 r1, ) = swapPair.getReserves();
        assert(r0 > 0 && r1 > 0);
        return address(tokenT) == swapPair.token0() ? (r0, r1) : (r1, r0);
    }

    function swap(IERC20 tokenA, uint256 amtA, uint256 minAmtB) internal returns (uint256 amtB) {
        IERC20 tokenB = (tokenA == tokenT) ? tokenU : tokenT;

        tokenA.approve(address(swapRouter), amtA); // TODO: TransferHelper.safeApprove() ?
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        uint[] memory results = swapRouter.swapExactTokensForTokens(amtA, 0, path, address(this), block.timestamp);
        amtB = results[1];

        // require(results[0] == amtA,    "BG: swap results[0] != amtA");
        // require(results[1] >= minAmtB, "BG: swap results[1] < minAmtB");
        // require(amtB >= minAmtB, string(abi.encodePacked(
        //     "BG: out:", amtA.toString(), ", minIn:", minAmtB.toString(), ", in:", amtB.toString())));
        require(amtB >= minAmtB, "BG: swap failed");
    }

    function collectFee(uint256 gotU) internal {
        if (SERVICE_FEE_BPS > 0) {
            address feeToAddr = factory.feeTo();
            if (feeToAddr != address(0)) {
                uint256 fee = gotU * SERVICE_FEE_BPS / _10K;
                totalShares += fee;
                // users[feeToAddr].shares += fee;
                UserInfo memory feeToUser = users[feeToAddr];
                feeToUser.shares += uint192(fee);
                users[feeToAddr] = feeToUser;
            }
        }
    }

    function lastDepositTime(address addr) public view returns (uint256) {
        return users[addr].lastDepositTime;
    }

    function balanceOf(address addr) external view override returns (uint256 t, uint256 u, uint256 s) {
        uint256 s0 = totalShares;
        if (s0 > 0) {
            uint256 t0 = tokenT.balanceOf(address(this));
            uint256 u0 = tokenU.balanceOf(address(this));
            s = users[addr].shares;
            t = (t0 * s) / s0;
            u = (u0 * s) / s0;
        }
    }

    function deposit(uint256 t, uint256 u) external override nonReentrant {
        require(t > 0 || u > 0, "BG: deposit 0");

        (uint256 pt, uint256 pu) = getPrice();
        uint256 s0 = totalShares;
        uint256 t0 = tokenT.balanceOf(address(this));
        uint256 u0 = tokenU.balanceOf(address(this));
        uint256 s = (s0 == 0) 
            ? (t * pu/pt) + u 
            : s0 * ((t * pu/pt) + u) / (t0 * pu/pt + u0);

        if (t > 0) { TransferHelper.safeTransferFrom(address(tokenT), msg.sender, address(this), t); }
        if (u > 0) { TransferHelper.safeTransferFrom(address(tokenU), msg.sender, address(this), u); }

        // balance t & u
        uint256 balancedT = t;
        uint256 balancedU = u;
        if (AUTO_BALANCE_UT) {        
            uint256 u1 = u0 + u;
            uint256 v1 = (t0 + t) * pu/pt;
            if (u > 0 && u1 > 3 * v1) {
                // u/2 -> t
                balancedU = u/2;
                balancedT += swap(tokenU, u/2, 0);
            } else if (t > 0 && v1 > 3 * u1) {
                // t/2 -> u
                balancedT = t/2;
                balancedU += swap(tokenT, t/2, 0);
            }
        }

        assert(s < 2**192);
        totalShares += s;
        UserInfo memory user = users[msg.sender];
        user.lastDepositTime = uint64(block.number);
        user.shares += uint192(s);
        users[msg.sender] = user;
        emit Deposit(msg.sender, t, u, user.shares, balancedT, balancedU);
    }

    function withdraw(uint256 t, uint256 u) external override nonReentrant {
        UserInfo memory user = users[msg.sender];
        require(block.number > user.lastDepositTime + DEPOSIT_LOCK_TIME,
            "BG: withdraw in lock time");
        require(t > 0 || u > 0, "BG: withdraw 0");

        (uint256 pt, uint256 pu) = getPrice();
        uint256 t0 = tokenT.balanceOf(address(this));
        uint256 u0 = tokenU.balanceOf(address(this));
        uint256 s0 = totalShares;
        uint256 s1 = user.shares;
        uint256 t1 = t0 * s1 / s0;
        uint256 u1 = u0 * s1 / s0;
        if (t > t1) { t = t1; }
        if (u > u1) { u = u1; }

        uint256 s = s0 * ((t * pu/pt) + u) / (t0 * pu/pt + u0);
        assert(s < 2**192);
        totalShares -= s;
        user.shares -= uint192(s);
        users[msg.sender] = user;

        // deduct fee
        if (WITHDRAW_FEE_BPS > 0) {
            t = t * (_10K - WITHDRAW_FEE_BPS) / _10K;
            u = u * (_10K - WITHDRAW_FEE_BPS) / _10K;
        }

        if (t > 0) { TransferHelper.safeTransfer(address(tokenT), msg.sender, t); }
        if (u > 0) { TransferHelper.safeTransfer(address(tokenU), msg.sender, u); }
        emit Withdraw(msg.sender, t, u, user.shares);
    }

}

// File: contracts/FixedRateGrid.sol

pragma solidity >=0.8.0;



// price = u / t
struct Swap {
    uint120 t;
    uint120 u;
    bool isBuy;
}

contract FixedRateGrid is IGridPair, BaseGrid {

    // params
    uint256 public immutable j; // ‱
    uint256 public immutable k; // ‱

    Swap[] private swapStack;

    constructor(address _router, 
                address _pair, 
                address _tokenT, 
                address _tokenU, 
                uint256 _j, 
                uint256 _k) BaseGrid(_tokenT, _tokenU, _pair, _router) {
        (j, k)  = (_j, _k);
    }

    modifier onlyBot() {
        require(factory.bot() == msg.sender, "FRG: caller is not the bot");
        _;
    }

    // TODO: make swapStack public
    function getSwapStackSize() public view returns (uint256) {
        return swapStack.length;
    }
    function getSwapStackElem(uint256 i) public view returns (Swap memory) {
        require(i < swapStack.length, "FRG: Stack Overflow");
        return swapStack[i];
    }

    function lastSwap() external override view returns (uint256 t, uint256 u, bool isBuy) {
        if (swapStack.length > 0) {
            Swap memory swap = swapStack[swapStack.length - 1];
            (t, u, isBuy) = (swap.t, swap.u, swap.isBuy);
        }
    }

    function buy() external override onlyBot {
        bool lastIsBuy = false;
        uint256 u0 = tokenU.balanceOf(address(this));
        uint256 u;
        uint256 t;
        if (swapStack.length == 0) {
            u = u0 * k / _10K;
            t = 0;
        } else {
            Swap memory _lastSwap = swapStack[swapStack.length - 1];
            uint256 t1 = _lastSwap.t;
            uint256 u1 = _lastSwap.u;
            lastIsBuy = _lastSwap.isBuy;
            if (lastIsBuy) {
                u = u0 * k / _10K;
            } else {
                u = min(u0, u1);
                swapStack.pop(); // pop last sell
            }
            t = u * t1 * _10K / u1 / (_10K - j);
        }

        if (PRICE_TOLERANCE > 0) {
            t = t * (_10K - PRICE_TOLERANCE) / _10K;
        }

        uint256 gotT = swap(tokenU, u, t);
        if (t == 0) { t = gotT; }
        if (lastIsBuy || swapStack.length == 0) {
            pushSwap(t, u, true);
        }
        emit Buy(gotT, u, t, u);
    }

    function sell() external override onlyBot {
        bool lastIsSell = false;
        uint256 t0 = tokenT.balanceOf(address(this));
        uint256 u;
        uint256 t;
        if (swapStack.length == 0) {
            t = t0 * k / _10K;
            u = 0;
        } else {        
            Swap memory _lastSwap = swapStack[swapStack.length - 1];
            uint256 t1 = _lastSwap.t;
            uint256 u1 = _lastSwap.u;
            lastIsSell = !_lastSwap.isBuy;
            if (lastIsSell) {
                t = t0 * k / _10K;
            } else {
                t = min(t0, t1);
                swapStack.pop(); // pop last buy
            }
            u = t * u1 * (_10K + j) / t1 / _10K;
        }

        if (PRICE_TOLERANCE > 0) {
            u = u * (_10K - PRICE_TOLERANCE) / _10K;
        }

        uint256 gotU = swap(tokenT, t, u);
        if (u == 0) { u = gotU; }
        if (lastIsSell || swapStack.length == 0) {
            pushSwap(t, u, false);
        }
        emit Sell(t, gotU, t, u);

        collectFee(gotU);
    }

    function pushSwap(uint256 t, uint256 u, bool isBuy) private {
        assert(t < 2**120 && u < 2**120);
        swapStack.push(Swap(uint120(t), uint120(u), isBuy));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

}

// File: contracts/MdexFixedRateGrid.sol

pragma solidity >=0.8.0;






contract MdexFixedRateGrid is FixedRateGrid, IMdexGridPair {
    IMdexSwapMining public immutable swapMining;

    constructor(
        address _router,
        address _pair,
        address _tokenT,
        address _tokenU,
        uint256 _j,
        uint256 _k
    ) FixedRateGrid(_router, _pair, _tokenT, _tokenU, _j, _k) {
        address swapMiningAddress = IMdexSwapRouter(_router).swapMining();
        swapMining = IMdexSwapMining(swapMiningAddress);
    }

    function swapRewardWithdraw() external override onlyBot {
        swapMining.takerWithdraw();
        IERC20 mdx = IERC20(swapMining.mdx());
        uint256 balance = mdx.balanceOf(address(this));
        TransferHelper.safeTransferFrom(address(mdx), address(this), factory.bot(), balance);
        emit RewardWithdraw(balance);
    }

    function getSwapReward() external view override returns (uint256) {
        uint256 length = swapMining.poolLength();
        uint256 sumReward;
        for (uint256 pid = 0; pid < length; ++pid) {
            (uint256 userSub, ) = swapMining.getUserReward(pid);
            sumReward += userSub;
        }
        return sumReward;
    }
}