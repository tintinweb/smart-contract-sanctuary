// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBasicLender {
    struct Position {
        address owner;
        uint256 leverage;
        uint256 openedAt;
        uint256 closedAt;
        uint256 entryPrice;
        address liquidator;
        uint256 borrowSize;
        uint256 collateralSize;
        uint256 liquidationPrice;
        uint256 swappedBorrowSize;
    }

    function depositETH() external payable;

    function getPosition(uint256 positionId)
        external
        view
        returns (Position memory);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawETH(uint256 amount) external;

    function getAccruedInterest(uint256 positionId)
        external
        view
        returns (uint256);

    function getAccruedInterestPercent(uint256 openedAt)
        external
        view
        returns (uint256);

    function getPositionDebtWithInterest(uint256 positionId)
        external
        view
        returns (uint256);

    function setIntersetPercentPerYear(uint256 percent) external;

    function getTokensRequired(uint256 amount, address[] memory path)
        external
        view
        returns (uint256);

    function getAvailableBalance(address who) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';

interface ICustomERC20 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
    function setPeriod(uint256 _period) external;

    function callable() external view returns (bool);

    function getPeriod() external view returns (uint256);

    function getNextEpoch() external view returns (uint256);

    function getLastEpoch() external view returns (uint256);

    function getStartTime() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IBasicLender} from './IBasicLender.sol';

interface ILender is IBasicLender {
    function liquidatePosition(
        address liquidator,
        uint256 positionId,
        uint256 collateralToReward,
        uint256 collateralToStore
    ) external;

    function exitMarket(uint256 positionId) external;

    function enterMarket(uint256 collateralSize, uint256 borrowSize)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILiquidator {
    function liquidate(uint256 positionId) external;

    function getLiquidationPrice(uint256 entryPrice, uint256 leverage)
        external
        view
        returns (uint256);

    function canLiquidate(uint256 positionId) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISupplyPool {
    function borrow(uint256 amount) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function repayBorrow(uint256 amount, uint256 interest) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IEpoch} from './IEpoch.sol';

interface IUniswapOracle is IEpoch {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/contracts/math/SafeMath.sol';

import {BasicLending} from './BasicLending.sol';
import {ILender} from '../interfaces/ILender.sol';
import {ILiquidator} from '../interfaces/ILiquidator.sol';
import {ISupplyPool} from '../interfaces/ISupplyPool.sol';
import {ICustomERC20} from '../interfaces/ICustomERC20.sol';
import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';

contract ARTHETHLending is BasicLending, ILender {
    using SafeMath for uint256;
    using SafeERC20 for ICustomERC20;

    /**
     * State variables.
     */

    ILiquidator public liquidator;

    /**
     * Modifier.
     */
    modifier onlyLiquidationController {
        require(msg.sender == address(liquidator), 'Lending: forbidden');
        _;
    }

    /**
     * Constructor.
     */
    constructor(
        ISupplyPool pool_,
        ICustomERC20 bToken_,
        ICustomERC20 cToken_,
        IUniswapOracle oracle_,
        ILiquidator liquidator_,
        IUniswapV2Router02 router_
    ) BasicLending(pool_, bToken_, cToken_, oracle_, router_) {
        liquidator = liquidator_;
    }

    /**
     * Setters.
     */
    function setLiquidationController(ILiquidator liquidator_)
        public
        onlyOwner
    {
        liquidator = liquidator_;
    }

    /**
     * Mutations.
     */

    function enterMarket(uint256 collateralSize, uint256 borrowSize)
        public
        override
        returns (uint256)
    {
        require(
            collateralSize <= getAvailableBalance(msg.sender),
            'Lending: not enough available balance'
        );
        require(borrowSize > 0, 'Lending: borrow size = 0');

        uint256 swappedBorrowSize = borrowFromSupplyPool(borrowSize);
        // You have 1 BTC, You put that as collateral and go 10x. Hence your position is now
        // 10BTC. That means you've borrowed 9BTC. Hence you're leverage is (9 + 1 BTC) / 1BTC.
        // However, if you have 2 BTC, You put that as collateral and go 10x. Hence your position is now
        // 20BTC. That means you've borrowed 9BTC. Hence you're leverage is (18 + 2 BTC) / 2BTC.
        // Hence you're leverage will always be (borrowed + collateral) / collateral.
        uint256 leverage =
            swappedBorrowSize
                .add(collateralSize)
                .mul(1e18)
                .div(collateralSize)
                .div(1e18);

        uint256 entryPrice = oracle.consult(address(cToken), 1e18);
        uint256 liquidationPrice =
            liquidator.getLiquidationPrice(entryPrice, leverage);

        Position memory position =
            Position({
                owner: msg.sender,
                leverage: leverage,
                openedAt: block.timestamp,
                closedAt: 0,
                entryPrice: entryPrice,
                liquidator: address(0),
                borrowSize: borrowSize,
                collateralSize: collateralSize,
                liquidationPrice: liquidationPrice,
                swappedBorrowSize: swappedBorrowSize
            });

        positions.push(position);
        lockedBalances[msg.sender] = lockedBalances[msg.sender].add(
            collateralSize
        );

        return positions.length - 1;
    }

    function exitMarket(uint256 positionId)
        public
        override
        onlyOpenPosition(positionId)
        onlyPositionOwner(positionId)
    {
        Position storage position = positions[positionId];

        uint256 currentPrice = oracle.consult(address(cToken), 1e18);
        if (currentPrice > position.entryPrice) {
            uint256 earningsLeft = repayBorrowFromSupplyPool(positionId);
            require(
                earningsLeft > position.collateralSize,
                'Lending: earning not enough to cover collateral'
            );

            lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(
                position.collateralSize
            );
            earnedBalances[msg.sender] = earnedBalances[msg.sender].add(
                earningsLeft.sub(position.collateralSize)
            );
        } else {
            uint256 regainedCollateral = 0;
            uint256 earningsFromPosition = 0;

            uint256 earningsLeft = repayBorrowFromSupplyPool(positionId);

            if (earningsLeft > position.collateralSize) {
                regainedCollateral = position.collateralSize;
                earningsFromPosition = earningsLeft.sub(regainedCollateral);
            } else {
                regainedCollateral = earningsLeft;
                earningsFromPosition = 0;
            }

            lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(
                regainedCollateral
            );
            earnedBalances[msg.sender] = earnedBalances[msg.sender].add(
                earningsFromPosition
            );
        }

        position.closedAt = block.timestamp;
    }

    function liquidatePosition(
        address positionLiquidator,
        uint256 positionId,
        uint256 collateralToReward,
        uint256 collateralToStore
    ) public override onlyLiquidationController {
        Position storage position = positions[positionId];
        require(collateralToReward > 0, 'Lending: reward = 0');

        uint256 earningsLeft = repayBorrowFromSupplyPool(positionId);
        require(
            earningsLeft >= collateralToReward.add(collateralToStore),
            'Lending: amounts moved'
        );

        if (isETHCollateral) {
            cToken.withdraw(collateralToReward);
            (bool success, ) =
                positionLiquidator.call{value: collateralToReward}('');
            require(success, 'Lending: ETH transfer failed');
        } else {
            cToken.safeTransfer(positionLiquidator, collateralToReward);
        }

        position.closedAt = block.timestamp;
        position.liquidator = positionLiquidator;

        cTokenReserves = cTokenReserves.add(collateralToStore);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {
    SafeERC20
} from '@openzeppelin/contracts/contracts/token/ERC20/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/contracts/math/SafeMath.sol';
import {Ownable} from '@openzeppelin/contracts/contracts/access/Ownable.sol';
import {IERC20} from '@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol';

import {ISupplyPool} from '../interfaces/ISupplyPool.sol';
import {ICustomERC20} from '../interfaces/ICustomERC20.sol';
import {IBasicLender} from '../interfaces/IBasicLender.sol';
import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {IUniswapV2Router02} from '../interfaces/IUniswapV2Router02.sol';

abstract contract BasicLending is Ownable, IBasicLender {
    using SafeMath for uint256;
    using SafeERC20 for ICustomERC20;

    /**
     * State variables.
     */

    ISupplyPool public pool;
    ICustomERC20 public bToken;
    ICustomERC20 public cToken;
    IUniswapOracle public oracle;
    IUniswapV2Router02 public router;

    bool public enabled = true;
    uint256 public bTokenReserves = 0;
    uint256 public cTokenReserves = 0;
    bool public isETHCollateral = false;
    uint256 public performanceFeesPercentage = 5;

    uint256 interestPercentPerYear = 1;
    uint256 public constant secondsPerYear = 30758400; // 356 * 24 * 60 * 60;
    uint256 public interestPercentPerSecond =
        interestPercentPerYear.mul(1e18).div(secondsPerYear).div(1e18);

    Position[] public positions;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockedBalances;
    mapping(address => uint256) public earnedBalances;

    /**
     * Modifiers.
     */

    modifier isEnabled {
        require(enabled, 'Lending: protocol not enabled');
        _;
    }

    modifier onlyOpenPosition(uint256 id) {
        require(positions[id].closedAt == 0, 'Lending: position closed');
        _;
    }

    modifier onlyPositionOwner(uint256 id) {
        require(positions[id].owner == msg.sender, 'Lending: invalid access');
        _;
    }

    /**
     * Events.
     */

    // TODO: add events.

    /**
     * Constructor.
     */
    constructor(
        ISupplyPool pool_,
        ICustomERC20 bToken_,
        ICustomERC20 cToken_,
        IUniswapOracle oracle_,
        IUniswapV2Router02 router_
    ) {
        pool = pool_;
        router = router_;
        bToken = bToken_;
        cToken = cToken_;
        oracle = oracle_;

        isETHCollateral = address(cToken) == router.WETH() ? true : false;
    }

    /**
     * Setters.
     */

    function setIntersetPercentPerYear(uint256 percent)
        public
        override
        onlyOwner
    {
        require(percent <= 100, 'Lending: percent > 100');

        interestPercentPerYear = percent;
        interestPercentPerSecond = interestPercentPerYear
            .mul(1e18)
            .div(secondsPerYear)
            .div(1e18);
    }

    /**
     * Views.
     */

    function getPosition(uint256 positionId)
        public
        view
        override
        returns (Position memory)
    {
        return positions[positionId];
    }

    function getAvailableBalance(address who)
        public
        view
        override
        returns (uint256)
    {
        return balances[who].sub(lockedBalances[who]);
    }

    function getAccruedInterestPercent(uint256 openedAt)
        public
        view
        override
        returns (uint256)
    {
        return block.timestamp.sub(openedAt).mul(interestPercentPerSecond);
    }

    function getAccruedInterest(uint256 positionId)
        public
        view
        override
        onlyOpenPosition(positionId)
        returns (uint256)
    {
        Position memory position = positions[positionId];

        uint256 accruedPercent = getAccruedInterestPercent(position.openedAt);

        return
            position.borrowSize.mul(accruedPercent).mul(1e18).div(100).div(
                1e18
            );
    }

    function getPositionDebtWithInterest(uint256 positionId)
        public
        view
        override
        onlyOpenPosition(positionId)
        returns (uint256)
    {
        Position memory position = positions[positionId];

        return position.borrowSize.add(getAccruedInterest(positionId));
    }

    function getTokensRequired(uint256 amount, address[] memory path)
        public
        view
        override
        returns (uint256)
    {
        uint256[] memory tokensRequired = router.getAmountsIn(amount, path);

        return tokensRequired[0];
    }

    /**
     * Mutations.
     */

    function borrowFromSupplyPool(uint256 amountToBorrow)
        internal
        returns (uint256)
    {
        require(amountToBorrow > 0, 'Lending: borrowAmount = 0');

        pool.borrow(amountToBorrow);

        address[] memory path = new address[](2);
        path[0] = address(bToken);
        path[1] = address(cToken);

        uint256[] memory amountOuts =
            router.getAmountsOut(amountToBorrow, path);

        uint256 expectedpTokens = amountOuts[1];
        require(expectedpTokens > 0, 'Lending: swapped to 0');

        amountOuts = router.swapExactTokensForTokens(
            amountToBorrow,
            expectedpTokens,
            path,
            address(this),
            block.timestamp
        );

        return amountOuts[1];
    }

    // function repayBorrowFromSupplyPool(uint256 positionId)
    //     internal
    //     onlyOpenPosition(positionId)
    //     returns (uint256)
    // {
    //     Position memory position = positions[positionId];

    //     uint256 currentEarningSize =
    //         position.collateralSize.add(position.swappedBorrowSize);
    //     require(currentEarningSize > 0, 'Lending: earned = 0');

    //     uint256 amountToRepay = getPositionDebtWithInterest(positionId);
    //     uint256 accruedPercent = getAccruedInterestPercent(position.openedAt);

    //     address[] memory path = new address[](2);
    //     path[0] = address(cToken);
    //     path[1] = address(bToken);

    //     uint256 cTokensRequired = getTokensRequired(amountToRepay, path);
    //     require(
    //         currentEarningSize >= cTokensRequired,
    //         'Lending: cTokens earned < equivalent debt in cToken'
    //     );

    //     uint256 cTokensBeforeSwap = cToken.balanceOf(address(this));

    //     uint256[] memory amountOuts =
    //         router.swapExactTokensForTokens(
    //             cTokensRequired,
    //             amountToRepay,
    //             path,
    //             address(this),
    //             block.timestamp
    //         );
    //     require(
    //         amountOuts[1] >= position.borrowSize,
    //         'Lending: swapped < debt'
    //     );

    //     uint256 cTokensAfterSwap = cToken.balanceOf(address(this));
    //     uint256 cTokensLeft = cTokensAfterSwap.sub(cTokensBeforeSwap);

    //     bToken.safeApprove(address(pool), amountOuts[1]);
    //     pool.repayBorrow(position.borrowSize, accruedPercent);

    //     return cTokensLeft;
    // }

    function repayBorrowFromSupplyPool(uint256 positionId)
        internal
        onlyOpenPosition(positionId)
        returns (uint256)
    {
        Position memory position = positions[positionId];

        uint256 currentEarningSize =
            position.collateralSize.add(position.swappedBorrowSize);
        require(currentEarningSize > 0, 'Lending: earned = 0');

        // this will be calculated and passed as param minpTokensToRecieve
        uint256 amountToRepay = getPositionDebtWithInterest(positionId);
        uint256 accruedPercent = getAccruedInterestPercent(position.openedAt);

        address[] memory path = new address[](2);
        path[0] = address(cToken);
        path[1] = address(bToken);

        uint256 cTokensRequired = getTokensRequired(amountToRepay, path);
        require(
            currentEarningSize >= cTokensRequired,
            'Lending: cTokens earned < equivalent debt in cToken'
        );

        uint256 cTokensBeforeSwap = cToken.balanceOf(address(this));

        uint256[] memory amountOuts =
            router.swapExactTokensForTokens(
                cTokensRequired,
                amountToRepay,
                path,
                address(this),
                block.timestamp
            );
        require(
            amountOuts[1] >= position.borrowSize,
            'Lending: swapped < debt'
        );

        uint256 cTokensAfterSwap = cToken.balanceOf(address(this));
        uint256 cTokensLeft = cTokensAfterSwap.sub(cTokensBeforeSwap);

        bToken.safeApprove(address(pool), amountOuts[1]);
        pool.repayBorrow(position.borrowSize, accruedPercent);

        return cTokensLeft;
    }

    receive() external payable {}

    function depositETH() external payable override {
        require(msg.value > 0, 'Lending: amount = 0');
        require(isETHCollateral, 'Lending: ETH is not collateral');

        cToken.deposit{value: msg.value}();
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    function withdrawETH(uint256 amount) external override {
        require(amount > 0, 'Lending: amount = 0');
        require(isETHCollateral, 'Lending: ETH is not collateral');
        require(
            getAvailableBalance(msg.sender) >= amount,
            'Lending: not enough unlocked'
        );

        cToken.withdraw(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        (bool success, ) = msg.sender.call{value: amount}('');

        require(success, 'Lending: ETH transfer failed');
    }

    function deposit(uint256 amount) public override {
        require(!isETHCollateral, 'Lending: ETH is the collateral');
        require(amount > 0, 'Lending: amount = 0');

        cToken.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
    }

    function withdraw(uint256 amount) public override {
        require(!isETHCollateral, 'Lending: ETH is the collateral');
        require(amount > 0, 'Lending: amount = 0');
        require(
            getAvailableBalance(msg.sender) >= amount,
            'Lending: not enough unlocked'
        );

        cToken.safeTransfer(msg.sender, amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

