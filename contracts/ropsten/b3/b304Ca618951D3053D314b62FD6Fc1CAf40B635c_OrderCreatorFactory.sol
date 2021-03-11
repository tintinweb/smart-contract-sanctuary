pragma solidity ^0.6.6;

abstract contract ILimitOrderBookFactory {

    function emitOrderEvent(
        address _owner, uint _orderNo, address _stoken, address _btoken, uint _amountIn,
        uint _minAmountOut, uint _maxAmountOut, uint _stokenSwapRate, uint _status,
        uint _type, uint gWei) external virtual;

    function emitOrderCancel(address _owner, uint _orderNo) external virtual;

    function emitOrderExecuted(address _owner, uint _orderNo, uint tokensOut, uint fee) external virtual;

    function getTrxFee() public virtual returns (uint,uint);

}

pragma solidity ^0.6.6;

abstract contract IOrderExecutor {
    function execute(
        address[] calldata path,
        uint tokensIn,
        uint loTokenOut,
        uint hiTokenOut) external virtual returns (uint[] memory amounts);
}

pragma solidity ^0.6.6;

import "./contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "./contracts/interfaces/IWETH.sol";
import "./contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ILimitOrderBookFactory.sol";
import "./IOrderExecutor.sol";

contract LimitOrderBook {
    using SafeMath for uint;

    enum OrderStatus {
        CREATED,
        FAILED,
        COMPLETED,
        CANCELLED
    }

    struct OrderEx {
        address btoken;
        uint loTokensOut;
        OrderStatus status;
    }


    address public freeWalletExecutor;
    address public WETH;
    address public orderBookFactory;

    address payable public owner;
    address payable public feeTo;
    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // same for ropsten and main net

    mapping(uint => OrderEx) public ordersEx;
    uint public accruedGas;

    uint private orderNumber;

    IUniswapV2Router02 public uniswapRouter;
    ILimitOrderBookFactory private iOrderCreatorFactory;

    IWETH private iweth;
    address private oexecutor;


    constructor() public {

    }

    function initialize(address payable _owner, address _executor, address payable _feeTo,
        address _orderBookFactory, address _weth, address _oexecutor
    ) public {

        require(address(0) == orderBookFactory);

        owner = _owner;
        feeTo = _feeTo;
        WETH = _weth;
        iweth = IWETH(_weth);

        orderBookFactory = _orderBookFactory;
        freeWalletExecutor = _executor;
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        iOrderCreatorFactory = ILimitOrderBookFactory(_orderBookFactory);
        oexecutor = _oexecutor;
    }

    function calculateRange(
        uint tokensIn, address btoken, uint stokenSwapRate, uint downSlippage, uint upSlippage
    ) public view returns (uint loTokensOut, uint hiTokensOut, uint idealTokensOut) {

        uint minRate =
        stokenSwapRate - stokenSwapRate.mul(downSlippage).div(10000);

        uint maxRate =
        stokenSwapRate + stokenSwapRate.mul(upSlippage).div(10000);


        uint decimals = IERC20(btoken).decimals();

        uint minTokensOut = divider(tokensIn, minRate, decimals);
        uint maxTokensOut = divider(tokensIn, maxRate, decimals);
        uint exactTokensOut = divider(tokensIn, stokenSwapRate, decimals);

        (minTokensOut, maxTokensOut) = minTokensOut < maxTokensOut ?
        (minTokensOut, maxTokensOut) : (maxTokensOut, minTokensOut);

        return (minTokensOut, maxTokensOut, exactTokensOut);

    }

    function divider(uint numerator, uint denominator, uint precision)
    internal pure returns (uint) {

        return (numerator * (uint(10) ** uint(precision + 1)) / denominator + 5) / uint(10);
    }

    function limitOrderSwapExactETHForTokens(
        address btoken, uint stokenSwapRate, uint downSlippage, uint upSlippage,
        uint gasWei, uint oType
    ) external payable {

        require(msg.sender == owner, "err.notAuthorized");
        require(btoken != address(0), "err.zeroAddress");
        require(stokenSwapRate > 0, "err.invalidAmount");
        require(msg.value > 0, "err.invalidAmount");

        uint hiTokensOut;
        uint tokensIn = msg.value.sub(gasWei);

        {
            (uint lto, uint hto,) =
                calculateRange(tokensIn, btoken, stokenSwapRate, downSlippage, upSlippage);

            ordersEx[orderNumber] = OrderEx(btoken, lto, OrderStatus.CREATED);

            hiTokensOut = hto;
        }

        emitOrder(
            owner,
            orderNumber,
            WETH,
            btoken,
            tokensIn,
            ordersEx[orderNumber].loTokensOut,
            hiTokensOut,
            stokenSwapRate,
            uint(OrderStatus.CREATED),
            gasWei,
            oType
        );

        orderNumber++;
    }

    function limitOrderSwapExactTokensForETH(
        address stoken, uint tokensIn, uint stokenSwapRate, uint downSlippage, uint upSlippage,
        uint gasWei, uint oType
    ) external payable {

        require(msg.sender == owner, "err.notAuthorized");
        require(stoken != address(0), "err.zeroAddress");
        require(stokenSwapRate >= 0, "err.invalidRate");
        require(tokensIn > 0, "err.invalidAmount");
        require(msg.value == gasWei, "err.gasAmountMissMatch");

        // tansfer the tokens from the account to the contract address
        TransferHelper.safeTransferFrom(stoken, msg.sender, address(this), tokensIn);

        (uint loTokensOut, uint hiTokensOut,) =
        calculateRange(tokensIn, WETH, stokenSwapRate, downSlippage, upSlippage);

        ordersEx[orderNumber] = OrderEx(WETH, loTokensOut, OrderStatus.CREATED);

        emitOrder(
            owner,
            orderNumber,
            stoken,
            WETH,
            tokensIn,
            loTokensOut,
            hiTokensOut,
            stokenSwapRate,
            uint(OrderStatus.CREATED),
            gasWei,
            oType
        );


        orderNumber++;
    }


    function limitOrderSwapExactTokensForTokens(
        address stoken, address btoken, uint tokensIn, uint stokenSwapRate, uint downSlippage,
        uint upSlippage, uint gasWei, uint oType
    ) external payable {

        require(msg.sender == owner, "err.notAuthorized");
        require(stoken != address(0), "err.zeroAddress");
        require(btoken != address(0), "err.zeroAddress");
        require(stokenSwapRate >= 0, "err.invalidRate");
        require(tokensIn >= 0, "err.invalidAmount");
        require(msg.value == gasWei, "err.NotEnoughGasSent");

        TransferHelper.safeTransferFrom(stoken, msg.sender, address(this), tokensIn);

        (uint loTokensOut, uint hiTokensOut,) =
        calculateRange(tokensIn, btoken, stokenSwapRate, downSlippage, upSlippage);

        ordersEx[orderNumber] = OrderEx(btoken, loTokensOut, OrderStatus.CREATED);

        emitOrder(
            owner,
            orderNumber,
            stoken,
            btoken,
            tokensIn,
            loTokensOut,
            hiTokensOut,
            stokenSwapRate,
            uint(OrderStatus.CREATED),
            gasWei,
            oType
        );

        orderNumber++;
    }

    function emitOrder(address _owner, uint _orderNo, address _stoken, address _btoken, uint _amountIn,
        uint _minAmountOut, uint _maxAmountOut, uint _stokenSwapRate, uint status, uint gasWei, uint oType) internal {

        iOrderCreatorFactory.emitOrderEvent(
            _owner,
            _orderNo,
            _stoken,
            _btoken,
            _amountIn,
            _minAmountOut,
            _maxAmountOut,
            _stokenSwapRate,
            status,
            oType,
            gasWei
        );
    }


    function cancelAndWithDrawOrder(uint _orderNo, address stoken, uint tokensIn, uint gasWei) external {
        require(msg.sender == owner, "err.NotAuthorized");
        require(stoken != address(0), "err.invalidStokenAddr");
        require(ordersEx[_orderNo].btoken != address(0), "err.orderDoesntExist");
        require(ordersEx[_orderNo].status == OrderStatus.CREATED, "err.invalidStatus");

        if (stoken == WETH) {
            // refund gas + actual order amount
            TransferHelper.safeTransferETH(owner, tokensIn.add(gasWei));
        } else {
            TransferHelper.safeTransfer(stoken, owner, tokensIn);
            TransferHelper.safeTransferETH(owner, gasWei);
        }
        ordersEx[_orderNo].status = OrderStatus.CANCELLED;
        iOrderCreatorFactory.emitOrderCancel(owner, _orderNo);
    }


    function execute(address[] calldata path, uint _orderNo, uint tokensIn,
        uint hiTokensOut, uint gasWei) external {

        require(msg.sender == freeWalletExecutor, "err.notAuthorized");
        require(tokensIn > 0 , "err.invalidTokensIn");
        require(hiTokensOut > 0 , "err.invalidHiTokensOut");
        require(gasWei > 0 , "err.invalidGasWei");

        require(ordersEx[_orderNo].btoken != address(0), "err.orderDoesntExist");
        require(ordersEx[_orderNo].status == OrderStatus.CREATED, "err.invalidStatus");

        address stoken = path[0];
        uint[] memory amountOut;
        uint loTokensOut = ordersEx[_orderNo].loTokensOut;

        {
            address[] memory routedPath = new address[](path.length+1);

            for(uint i=0 ; i<path.length ; ++i) {
                routedPath[i] = path[i];
            }
            routedPath[routedPath.length-1] = ordersEx[_orderNo].btoken;

            // if the swap of ETH to Tokens wrap it
            if(stoken == WETH) {
                iweth.deposit{value : tokensIn}();
            }

            TransferHelper.safeApprove(stoken, oexecutor, tokensIn);

            amountOut = IOrderExecutor(oexecutor).execute(routedPath, tokensIn, loTokensOut, hiTokensOut);
        }
        uint actualAmountOut = amountOut[amountOut.length - 1];

        (uint feeMulFactor, uint feeDivFactor) = iOrderCreatorFactory.getTrxFee();

        uint executionFee = actualAmountOut.mul(feeMulFactor).div(feeDivFactor);
        uint remainingOut = actualAmountOut.sub(executionFee);


        {
            // if order output is ETH convert the WETH into ETH and then calculate the fee
            if (ordersEx[_orderNo].btoken == WETH) {
                iweth.withdraw(actualAmountOut);
                TransferHelper.safeTransferETH(feeTo, executionFee);
                TransferHelper.safeTransferETH(owner, remainingOut);
            } else {
                TransferHelper.safeTransfer(ordersEx[_orderNo].btoken, feeTo, executionFee);
                TransferHelper.safeTransfer(ordersEx[_orderNo].btoken, owner, remainingOut);
            }

            // transfer the gas to wallet
            TransferHelper.safeTransferETH(freeWalletExecutor, gasWei);
            ordersEx[_orderNo].status = OrderStatus.COMPLETED;
        }

        iOrderCreatorFactory.emitOrderExecuted(owner, _orderNo, remainingOut, executionFee);
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }
}

pragma solidity ^0.6.6;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "./LimitOrderBook.sol";
import "./ILimitOrderBookFactory.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract OrderCreatorFactory is ILimitOrderBookFactory {
    using SafeMath for uint;

    // coupon details
    struct Coupon {
        string couponCode;
        uint mulFactor;
        uint divFactor;
        uint maxUsage;
        uint currUsage;
    }

    uint public fee = 500000000000000000; // 0.5 ether

    // initial fee
    uint trxFeeMulFactor = 3;
    uint trxFeeDivFactor = 1000;

    mapping(address => address) public ownerOrderBookMap;
    mapping(string => Coupon) public promotionMap;

    address payable public feeTo;
    address public promotionConfigurer;
    address public WETH;
    address public lboTemplate;
    address public oexecutor;

    event OrderBookCreated(
        address owner,
        address orderBookAddress,
        address executor,
        string couponCode,
        uint feePaid
    );

    event OrderEvent (
        address owner,
        uint orderNo,
        address stoken,
        address btoken,
        uint tokensIn,
        uint lbTokensOut,
        uint ubTokensOut,
        uint stokenSwapRate,
        uint status,
        uint orderType,
        uint gasWei
    );

    event OrderCancelled (
        address owner,
        uint orderNo
    );

    event OrderExecuted(
        address owner,
        uint orderNo,
        uint tokensOut,
        uint fee
    );

    event OrderGasAccrued(
        address orderBook,
        uint orderNo,
        uint gasPaidInWei
    );

    event PromotionCreated(
        string coupon,
        uint mulFactor,
        uint divFactor,
        uint maxUsage
    );

    event PromotionApplied(
        string coupon,
        uint currUsage,
        address owner
    );

    constructor(address payable _feeTo, address _promotionConfigurer,
        address _weth, address _limitBook, address _oexecutor) public {

        feeTo = _feeTo;
        promotionConfigurer = _promotionConfigurer;
        WETH = _weth;
        lboTemplate = _limitBook;
        oexecutor = _oexecutor;
    }

    // whatever the fee is - 0.1 ETH is always credited to the accounts floating wallet
    // rest is the protocol fee.
    function createLimitOrderBook(address _executor, string calldata _couponCode)
        external payable {

        require(address(0) == ownerOrderBookMap[msg.sender], "err.limitOrderBookAlreadyExists");

        bytes memory couponCode = bytes(_couponCode);

        if (0 == couponCode.length) {
            require(msg.value == fee, "err.feeMissMatch");
        } else {
            Coupon storage coupon = promotionMap[_couponCode];
            // fetch the coupon detailscwai
            uint discountedFee = fee.mul(coupon.mulFactor).div(coupon.divFactor);
            // calculate the discounted wei

            require(coupon.currUsage < coupon.maxUsage, "err.expiredCouponCode");
            require(msg.value == discountedFee, "err.feeMissMatch");
            // increase the current usage count
            promotionMap[_couponCode].currUsage += 1;
        }

        address limitOrderBookAddress = Clones.clone(lboTemplate);
//        LimitOrderBook(limitOrderBookAddress).initialize(msg.sender,
//            _executor, feeTo, address(this), WETH, oexecutor);

        ownerOrderBookMap[msg.sender] = limitOrderBookAddress;

        // The fee will always be greater than .1 ETH
        TransferHelper.safeTransferETH(_executor, 100000000000000000);

        if(msg.value > 100000000000000000) {
            // the rest is considered as the transaction fee
            uint protocolFee = msg.value.sub(100000000000000000);
            TransferHelper.safeTransferETH(feeTo, protocolFee);
        }

        emit OrderBookCreated(msg.sender, limitOrderBookAddress, _executor, _couponCode, msg.value);
    }

    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    function applyCouponCode(string calldata _couponCode) external view returns (uint) {
        Coupon storage coupon = promotionMap[_couponCode];
        return fee.mul(coupon.mulFactor).div(coupon.divFactor);
    }

    function createPromotion(string calldata _couponCode, uint _mulFactor,
        uint _divFactor, uint _maxUsage) external {

        require(msg.sender == promotionConfigurer, "err.NotAuthorized");
        Coupon storage coupon = promotionMap[_couponCode];
        bytes memory couponCode = bytes(coupon.couponCode);

        require(0 == couponCode.length, "err.couponCodeAlreadyExists");
        promotionMap[_couponCode] = Coupon(_couponCode, _mulFactor, _divFactor, _maxUsage, 0);

        emit PromotionCreated(_couponCode, _mulFactor, _divFactor, _maxUsage);
    }

    function createClone(address target) internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function emitOrderEvent(address _owner, uint _orderNo, address _stoken, address _btoken,
        uint _amountIn, uint _minAmountOut, uint _maxAmountOut, uint _stokenSwapRate,
        uint _status, uint oType, uint gWei) external override {

        require(address(0) != ownerOrderBookMap[_owner], "err.limitOrderBookNotFound");
        require(msg.sender == ownerOrderBookMap[_owner], "err.limitOrderBookMissMatch");

        emit OrderEvent(_owner, _orderNo, _stoken, _btoken, _amountIn, _minAmountOut,
            _maxAmountOut, _stokenSwapRate, _status, oType, gWei);
    }

    function emitOrderCancel(address _owner, uint _orderNo) external override {

        require(address(0) != ownerOrderBookMap[_owner], "err.limitOrderBookNotFound");
        require(msg.sender == ownerOrderBookMap[_owner], "err.limitOrderBookMissMatch");

        emit OrderCancelled(_owner, _orderNo);
    }

    function emitOrderExecuted(
        address _owner, uint _orderNo, uint _tokensOut, uint _fee) external override {

        require(address(0) != ownerOrderBookMap[_owner], "err.limitOrderBookNotFound");
        require(msg.sender == ownerOrderBookMap[_owner], "err.limitOrderBookMissMatch");
        emit OrderExecuted(_owner, _orderNo, _tokensOut, _fee);
    }

    function getTrxFee() public override returns (uint,uint)  {
        return (trxFeeMulFactor, trxFeeDivFactor);
    }

    function configureTrxFee(uint _trxFeeMulFactor) external {
        require(trxFeeMulFactor <= 5, "err.feeCantBeMoreThan.5Percent");
        require(msg.sender == promotionConfigurer, "err.notAuthorized");
        trxFeeMulFactor = _trxFeeMulFactor;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}