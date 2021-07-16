//SourceUnit: Temp.sol

// File: contracts/interface/IUser.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IUser{
    function totalSupply(address token) external view returns (uint256);
    function balance(address token, address owner) external view returns (uint256);

    function deposit(uint8 coinType, address token, uint256 value) external payable;
    function withdraw(uint8 coinType, address token, uint256 value) external;

    function transfer(address token, address fromUser, uint256 value) external returns (bool);
    function receiveToken(address token, address toUser, uint256 value) external returns (bool);
}

// File: contracts/interface/IMaker.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IMaker {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function sharePrice() external view returns (uint);

    function setMinAddLiquidityAmount(uint _minAmount) external returns (bool);

    function setMinRemoveLiquidity(uint _minLiquidity) external returns (bool);

    function setOpenRate(uint _openRate) external returns (bool);

    function setRemoveLiquidityRate(uint _rate) external returns (bool);

    function canOpen(uint _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint[] memory);

    function getOrder(uint _no) external view returns (bytes memory _order);

    function openUpdate(uint _makerMargin, uint _takerMargin, uint _amount, uint _total, int8 _takerDirection) external returns (bool);

    function closeUpdate(
        uint _makerMargin,
        uint _takerMargin,
        uint _amount,
        uint _total,
        int makerProfit,
        uint makerFee,
        int8 _takerDirection
    ) external returns (bool);

    function open(uint _value) external returns (bool);

    function takerDepositMarginUpdate(uint _margin) external returns (bool);

    function addLiquidity(address sender, uint amount) external returns (uint _id, address _makerAddress, uint _amount, uint _cancelBlockElapse);

    function cancelAddLiquidity(address sender, uint id) external returns (uint _amount);

    function priceToAddLiquidity(uint256 id, uint256 price, uint256 priceTimestamp) external returns (uint liquidity);

    function removeLiquidity(address sender, uint liquidity) external returns (uint _id, address _makerAddress, uint _liquidity, uint _cancelBlockElapse);

    function priceToRemoveLiquidity(uint id, uint price, uint priceTimestamp) external returns (uint amount);

    function cancelRemoveLiquidity(address sender, uint id) external returns (bool);

    function getLpBalanceOf(address _maker) external view returns (uint _balance, uint _totalSupply);

    function systemCancelAddLiquidity(uint id) external;

    function systemCancelRemoveLiquidity(uint id) external;

    function canRemoveLiquidity(uint _price, uint _liquidity) external view returns (bool);

    function canAddLiquidity(uint _price) external view returns (bool);
}

// File: contracts/interface/IMarket.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IMarket {
    function open(address _taker, address inviter, uint256 minPrice, uint256 maxPrice, uint256 margin, uint256 leverage, int8 direction) external returns (uint256 id);
    function close(address _taker, uint256 id, uint256 minPrice, uint256 maxPrice) external;
    function openCancel(address _taker, uint256 id) external;
    function closeCancel(address _taker, uint256 id) external;
    function priceToOpen(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external;
    function priceToClose(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external;
    function priceToOpenCancel(uint256 id) external;
    function priceToCloseCancel(uint256 id) external;
    function liquidity(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external;
    function depositMargin(address _taker, uint256 _id, uint256 _value) external;

    function getTakerOrderlist(address _taker) external view returns (uint256[] memory);
    function getByID(uint256 id) external view returns (bytes memory);

    function clearAnchorRatio() external view returns (uint256);
    function clearAnchorRatioDecimals() external view returns (uint256);
}

// File: contracts/interface/IERC20.sol

pragma solidity >=0.5.15  <=0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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

// File: contracts/interface/IManager.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IManager{
    function feeOwner() external view returns (address);
    function riskFundingOwner() external view returns (address);
    function poolFeeOwner() external view returns (address);
    function taker() external view returns (address);
    function checkSigner(address _signer)  external view returns(bool);
    function checkController(address _controller)  view external returns(bool);
    function checkRouter(address _router) external view returns(bool);
    function checkMarket(address _market) external view returns(bool);
    function checkMaker(address _maker) external view returns(bool);

    function cancelBlockElapse() external returns (uint256);
    function openLongBlockElapse() external returns (uint256);

    function paused() external returns (bool);

}

// File: contracts/library/SafeMath.sol

pragma solidity >=0.5.15  <=0.5.17;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/library/SignedSafeMath.sol

pragma solidity >=0.5.15  <=0.5.17;

library SignedSafeMath {
    int256 constant private _INT256_MIN = - 2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == - 1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == - 1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }


    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: contracts/library/TransferHelper.sol

pragma solidity >=0.5.15  <=0.5.17;


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // usdt of tron mainnet TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t: 0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c
        if (token == address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c)){
            IERC20(token).transfer(to, value);
            return;
        }

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
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/library/Types.sol

pragma solidity >=0.5.15  <=0.5.17;

library Types {
    enum OrderStatus {
        Open,
        Opened,
        Close,
        Closed,
        Liquidation,
        Broke,
        Expired,
        Canceled
    }

    enum PoolAction {
        Deposit,
        Withdraw
    }
    enum PoolActionStatus {
        Submit,
        Success,
        Fail,
        Cancel
    }

    struct Order {
        uint256 id;

        uint256 takerLeverage;
        //the rate is x/10000000000
        uint256 takerTrueLeverage;
        int8 direction;
        address inviter;
        address taker;
        uint256 takerOpenTimestamp;
        uint256 takerOpenDeadline;
        uint256 takerOpenPriceMin;
        uint256 takerOpenPriceMax;
        uint256 takerMargin;
        uint256 takerInitMargin;
        uint256 takerFee;
        uint256 feeToInviter;
        uint256 feeToExchange;
        uint256 feeToMaker;

        uint256 openPrice;
        uint256 openIndexPrice;
        uint256 openIndexPriceTimestamp;
        uint256 amount;
        uint256 makerMargin;
        uint256 makerLeverage;
        uint256 takerLiquidationPrice;
        uint256 takerBrokePrice;
        uint256 makerBrokePrice;
        uint256 clearAnchorRatio;

        uint256 takerCloseTimestamp;
        uint256 takerCloseDeadline;
        uint256 takerClosePriceMin;
        uint256 takerClosePriceMax;

        uint256 closePrice;
        uint256 closeIndexPrice;
        uint256 closeIndexPriceTimestamp;
        uint256 riskFunding;
        int256 takerProfit;
        int256 makerProfit;

        uint256 deadline;
        OrderStatus status;

    }

    struct MakerOrder {
        uint256 id;
        address maker;
        uint256 submitBlockHeight;
        uint256 submitBlockTimestamp;
        uint256 price;
        uint256 priceTimestamp;
        uint256 amount;
        uint256 liquidity;
        uint256 feeToPool;
        uint256 cancelBlockHeight;
        uint256 sharePrice;
        int poolTotal;
        int profit;
        PoolAction action;
        PoolActionStatus status;
    }
}

// File: contracts/library/Bytes.sol

pragma solidity >=0.5.15  <=0.5.17;

library Bytes {
    function contact(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory)  {
        bytes memory tempBytes;
        assembly {
            tempBytes := mload(0x40)
            let length := mload(_preBytes)
            mstore(tempBytes, length)
            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))
            mc := end
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31)
            ))
        }
        return tempBytes;
    }
}

// File: contracts/library/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.15  <=0.5.17;

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
contract ReentrancyGuard {
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

// File: contracts/Market.sol

pragma solidity >=0.5.15  <=0.5.17;












contract Market is IMarket, ReentrancyGuard {
    using SafeMath for uint;
    using SignedSafeMath for int;

    uint8 public marketType = 0;

    uint32 public insertID;
    mapping(uint256 => Types.Order) orders;
    mapping(address => uint256) public takerValues;

    address public clearAnchor;
    uint256 public clearAnchorRatio = 10 ** 10;
    uint256 public clearAnchorRatioDecimals = 10;

    address public taker;
    address public maker;

    address public manager;

    uint256 public indexPriceID;

    uint256 public clearAnchorDecimals;
    uint256 public constant priceDecimals = 10;
    uint256 public constant amountDecimals = 10;
    uint256 public constant leverageDecimals = 10;

    uint256 public takerLeverageMin = 1;
    uint256 public takerLeverageMax = 100;
    uint256 public takerMarginMin = 10000;
    uint256 public takerMarginMax = 10 ** 30;
    uint256 public takerValueMin = 10000;
    uint256 public takerValueMax = 10 ** 40;

    uint256 public takerValueLimit = 10 ** 30;

    uint256 public makerLeverageRate = 5;

    //the rate is x/1000000
    uint256 public constant mmDecimal = 1000000;
    uint256 public mm = 5000;

    uint256 public coinMaxPrice = 1000000 * 10 ** 10;

    //the rate is x/10000
    uint256 public constant feeDecimal = 10000;
    uint256 public feeRate = 10;
    uint256 public feeInvitorPercent = 4000;
    uint256 public feeExchangePercent = 4000;
    uint256 public feeMakerPercent = 2000;

    mapping(address => uint256[]) public takerOrderlist;

    bool public openPaused = true;
    bool public closePaused = true;

    address factory;
    constructor(address _manager) public {
        manager = _manager;
        factory = msg.sender;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "caller is not the controller");
        _;
    }

    modifier onlyRouter() {
        require(IManager(manager).checkRouter(msg.sender), "caller is not the router");
        _;
    }

    modifier whenNotOpenPaused() {
        require(!IManager(manager).paused() && !openPaused, "paused");
        _;
    }

    modifier whenNotClosePaused() {
        require(!IManager(manager).paused() && !closePaused, "paused");
        _;
    }

    function setPaused(bool _open, bool _close) external onlyController {
        openPaused = _open;
        closePaused = _close;
    }

    function initialize(uint256 _indexPrice, address _clearAnchor, uint256 _clearAnchorRatio, address _maker, uint8 _marketType) external {
        require(msg.sender == factory, "not factory");
        indexPriceID = _indexPrice;
        clearAnchor = _clearAnchor;
        clearAnchorRatio = _clearAnchorRatio;
        maker = _maker;
        taker = IManager(manager).taker();
        marketType = _marketType;
        clearAnchorDecimals = IERC20(clearAnchor).decimals();
    }

    function setClearAnchorRatio(uint256 _ratio) external onlyController {
        require(marketType == 2 && _ratio > 0, "error");
        clearAnchorRatio = _ratio;
    }

    function setTakerLeverage(uint256 min, uint256 max) external onlyController {
        require(min > 0 && min < max, "value not right");
        takerLeverageMin = min;
        takerLeverageMax = max;
    }

    function setTakerMargin(uint256 min, uint256 max) external onlyController {
        require(min > 0 && min < max, "value not right");
        takerMarginMin = min;
        takerMarginMax = max;
    }

    function setTakerValue(uint256 min, uint256 max) external onlyController {
        require(min > 0 && min < max, "value not right");
        takerValueMin = min;
        takerValueMax = max;
    }

    function setTakerValueLimit(uint256 limit) external onlyController {
        require(limit > 0, "limit not be zero");
        takerValueLimit = limit;
    }

    function setFee(
        uint256 _feeRate,
        uint256 _feeInvitorPercent,
        uint256 _feeExchangePercent,
        uint256 _feeMakerPercent
    ) external onlyController {
        require(_feeInvitorPercent.add(_feeMakerPercent).add(_feeExchangePercent) == feeDecimal, "percent all not one");
        require(_feeRate < feeDecimal, "feeRate more than one");
        feeRate = _feeRate;
        feeInvitorPercent = _feeInvitorPercent;
        feeExchangePercent = _feeExchangePercent;
        feeMakerPercent = _feeMakerPercent;
    }

    function setMM(uint256 _mm) external onlyController {
        require(_mm > 0 && _mm < mmDecimal, "mm is not right");
        mm = _mm;
    }

    function setCoinMaxPrice(uint256 max) external onlyController {
        require(max > 0 , "mm is not right");
        coinMaxPrice = max;
    }

    function setMakerLevarageRate(uint256 rate) external onlyController {
        require(rate > 0, "value is not right");
        makerLeverageRate = rate;
    }

    function open(
        address _taker,
        address inviter,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 margin,
        uint256 leverage,
        int8 direction
    ) external nonReentrant onlyRouter whenNotOpenPaused returns (uint256 id) {
        require(minPrice <= maxPrice, "price error");
        require(direction == 1 || direction == - 1, "direction not allow");
        require(takerLeverageMin <= leverage && leverage <= takerLeverageMax, "leverage not allow");
        require(takerMarginMin <= margin && margin <= takerMarginMax, "margin not allow");
        require(takerValueMin <= margin.mul(leverage) && margin.mul(leverage) <= takerValueMax, "value not allow");

        uint256 fee = margin.mul(feeRate).mul(leverage).div(feeRate.mul(leverage).add(feeDecimal));
        uint256 imargin = margin.sub(fee);
        uint256 value = imargin.mul(leverage);

        require(value.add(takerValues[_taker]) < takerValueLimit, "taker total value too big");

        require(IUser(taker).balance(clearAnchor, _taker) >= margin, "balance not enough");
        bool success = IUser(taker).transfer(clearAnchor, _taker, margin);
        require(success, "transfer error");

        insertID++;
        id = insertID;
        Types.Order storage order = orders[id];
        order.id = id;
        order.inviter = inviter;
        order.taker = _taker;
        order.takerOpenTimestamp = block.timestamp;
        order.takerOpenDeadline = block.number.add(IManager(manager).cancelBlockElapse());
        order.takerOpenPriceMin = minPrice;
        order.takerOpenPriceMax = maxPrice;
        order.takerMargin = imargin;
        order.takerInitMargin = imargin;
        order.takerLeverage = leverage;
        order.takerTrueLeverage = leverage * (10 ** leverageDecimals);
        order.direction = direction;
        order.takerFee = fee;
        if (inviter != address(0)) {
            order.feeToInviter = fee.mul(feeInvitorPercent).div(feeDecimal);
        }
        order.feeToMaker = fee.mul(feeMakerPercent).div(feeDecimal);
        order.feeToExchange = fee.sub(order.feeToInviter).sub(order.feeToMaker);

        require(order.takerFee == (order.feeToInviter).add(order.feeToExchange).add(order.feeToMaker), "fee add error");
        require(margin == (order.takerMargin).add(order.takerFee), "margin add error");

        order.deadline = block.number.add(IManager(manager).openLongBlockElapse());
        order.status = Types.OrderStatus.Open;
        takerOrderlist[_taker].push(id);
        takerValues[_taker] = value.add(takerValues[_taker]);
    }

    function priceToOpen(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external nonReentrant onlyRouter {
        Types.Order storage order = orders[id];
        require(order.id > 0, "order not exist");
        require(order.status == Types.OrderStatus.Open, "order status not match");
        require(block.number < order.takerOpenDeadline, "deadline");
        require(price >= order.takerOpenPriceMin && price <= order.takerOpenPriceMax, "price not match");

        order.openPrice = price;
        order.openIndexPrice = indexPrice;
        order.openIndexPriceTimestamp = indexPriceTimestamp;

        uint256 margin = order.takerMargin;
        if (marketType == 2) {
            margin = margin.mul(10 ** clearAnchorRatioDecimals).div(clearAnchorRatio);
        }
        order.clearAnchorRatio = clearAnchorRatio;

        if (marketType == 0 || marketType == 2) {
            order.amount = (margin).mul(order.takerLeverage).mul(10 ** amountDecimals).mul(10 ** priceDecimals).div(price).div(10 ** clearAnchorDecimals);
        } else {
            order.amount = (margin).mul(order.takerLeverage).mul(price).mul(10 ** amountDecimals).div(10 ** priceDecimals).div(10 ** clearAnchorDecimals);
        }

        order.makerLeverage = order.takerLeverage.add(makerLeverageRate - 1).div(makerLeverageRate);
        order.makerMargin = (order.takerMargin).mul(order.takerLeverage).div(order.makerLeverage);

        bool success = IMaker(maker).open(order.makerMargin);
        require(success, "maker open fail");
        IMaker(maker).openUpdate(order.makerMargin, order.takerMargin, order.amount, margin.mul(order.takerLeverage), order.direction);

        if (order.direction > 0) {
            if (marketType == 0 || marketType == 2) {
                order.makerBrokePrice = price.add(price.div(order.makerLeverage));
                uint256 takerBrokePrice = price.sub(price.div(order.takerLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).sub(mm));
            } else {
                order.makerBrokePrice = coinMaxPrice;
                if (order.makerLeverage > 1) {
                    order.makerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals - uint256(10**leverageDecimals).div(order.makerLeverage));
                }
                uint256 takerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals + uint256(10**leverageDecimals).div(order.takerLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal + mm).div(mmDecimal);
            }
        } else {
            if (marketType == 0 || marketType == 2) {
                order.makerBrokePrice = price.sub(price.div(order.makerLeverage));
                uint256 takerBrokePrice = price.add(price.div(order.takerLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).add(mm));
            } else {
                order.makerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals + uint256(10**leverageDecimals).div(order.makerLeverage));
                uint256 takerBrokePrice = coinMaxPrice;
                if (order.takerLeverage > 1) {
                    takerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals - uint256(10**leverageDecimals).div(order.takerLeverage));
                }
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal - mm).div(mmDecimal);
            }
        }

        order.status = Types.OrderStatus.Opened;
    }

    function depositMargin(address _taker, uint256 _id, uint256 _value) external nonReentrant onlyRouter {
        Types.Order storage order = orders[_id];
        require(order.id > 0, "order not exist");
        require(order.taker == _taker, 'caller is not taker');
        require(order.status == Types.OrderStatus.Opened, "order status not match");

        order.takerMargin = order.takerMargin.add(_value);
        require(order.makerMargin >= order.takerMargin, 'margin is error');
        IMaker(maker).takerDepositMarginUpdate(_value);

        require(IUser(taker).balance(clearAnchor, order.taker) >= _value, "balance not enough");
        bool success = IUser(taker).transfer(clearAnchor, order.taker, _value);
        require(success, "transfer error");

        order.takerTrueLeverage = (order.takerInitMargin).mul(order.takerLeverage).mul(10 ** leverageDecimals).div(order.takerMargin);

        if (order.direction > 0) {
            if (marketType == 0 || marketType == 2) {
                uint256 takerBrokePrice = order.openPrice.sub(order.openPrice.mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).sub(mm));
            } else {
                uint256 takerBrokePrice = order.openPrice.mul(10**leverageDecimals).div(10**leverageDecimals + uint256(10**leverageDecimals).mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal + mm).div(mmDecimal);
            }
        } else {
            if (marketType == 0 || marketType == 2) {
                uint256 takerBrokePrice = order.openPrice.add(order.openPrice.mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).add(mm));
            } else {
                uint256 takerBrokePrice = coinMaxPrice;
                if (order.takerTrueLeverage > 10**leverageDecimals) {
                    takerBrokePrice = order.openPrice.mul(10**leverageDecimals).div(10**leverageDecimals - uint256(10**leverageDecimals).mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                }
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal - mm).div(mmDecimal);
            }
        }

    }

    function close(address _taker, uint256 id, uint256 minPrice, uint256 maxPrice) external nonReentrant onlyRouter whenNotClosePaused {
        require(minPrice <= maxPrice, "price error");

        Types.Order storage order = orders[id];
        require(order.id > 0, "order not exist");
        require(order.taker == _taker, "not the taker");
        require(order.status == Types.OrderStatus.Opened, "order status not match");

        order.takerCloseTimestamp = block.timestamp;
        order.takerCloseDeadline = block.number.add(IManager(manager).cancelBlockElapse());
        order.takerClosePriceMin = minPrice;
        order.takerClosePriceMax = maxPrice;
        order.status = Types.OrderStatus.Close;
    }

    function priceToClose(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external nonReentrant onlyRouter {
        require(orders[id].id > 0, "order not exist");
        require(orders[id].status == Types.OrderStatus.Close, "order status not match");
        require(block.number < orders[id].takerCloseDeadline, "deadline");
        require(price >= orders[id].takerClosePriceMin && price <= orders[id].takerClosePriceMax, "price not match");

        orders[id].closeIndexPrice = indexPrice;
        orders[id].closeIndexPriceTimestamp = indexPriceTimestamp;
        _close(id, price);
    }

    function liquidity(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external nonReentrant onlyRouter {
        require(orders[id].id > 0, "order not exist");
        require(orders[id].status == Types.OrderStatus.Opened || orders[id].status == Types.OrderStatus.Close, "order status not match");

        if (block.number < orders[id].deadline) {
            if (orders[id].direction > 0) {
                require(price <= orders[id].takerLiquidationPrice || price >= orders[id].makerBrokePrice, "price not match");
            } else {
                require(price <= orders[id].makerBrokePrice || price >= orders[id].takerLiquidationPrice, "price not match");
            }
        }

        orders[id].closeIndexPrice = indexPrice;
        orders[id].closeIndexPriceTimestamp = indexPriceTimestamp;
        _close(id, price);
    }

    function _close(uint256 id, uint256 price) internal {
        bool isLiquidity;
        bool isBroke;
        if (orders[id].direction > 0) {
            if (price >= orders[id].makerBrokePrice) {
                isBroke = true;
            }
            if (price <= orders[id].takerLiquidationPrice) {
                isLiquidity = true;
            }
        } else {
            if (price <= orders[id].makerBrokePrice) {
                isBroke = true;
            }
            if (price >= orders[id].takerLiquidationPrice) {
                isLiquidity = true;
            }
        }

        int256 profit;
        if (isBroke) {
            profit = int256(orders[id].makerMargin);
            orders[id].status = Types.OrderStatus.Broke;
            orders[id].closePrice = orders[id].makerBrokePrice;
        } else {
            if (isLiquidity) {
                price = orders[id].takerLiquidationPrice;
            }

            if (marketType == 0 || marketType == 2) {
                profit = (int256(price).sub(int256(orders[id].openPrice))).mul(int256(10 ** clearAnchorDecimals)).mul(int256(orders[id].amount)).div(int256(10 ** (priceDecimals + amountDecimals)));
                if (marketType == 2) {
                    profit = profit.mul(int256(orders[id].clearAnchorRatio)).div(int256(10 ** clearAnchorRatioDecimals));
                }
            } else {
                uint256 a = (orders[id].amount).mul(10 ** (clearAnchorDecimals + priceDecimals)).div(orders[id].openPrice).div(10 ** amountDecimals);
                uint256 b = (orders[id].amount).mul(10 ** (priceDecimals + clearAnchorDecimals)).div(price).div(10 ** amountDecimals);
                profit = int256(a).sub(int256(b));
            }
            profit = profit.mul(orders[id].direction);
            if (block.number >= orders[id].deadline) {
                orders[id].status = Types.OrderStatus.Expired;
            } else {
                orders[id].status = Types.OrderStatus.Closed;
            }
            orders[id].closePrice = price;

            if (isLiquidity) {
                require(profit < 0, "profit error");
                require(- profit < int256(orders[id].takerMargin), "profit too big");
                orders[id].status = Types.OrderStatus.Liquidation;
                orders[id].riskFunding = orders[id].takerMargin.sub(uint256(- profit));
            }
        }

        orders[id].takerProfit = profit;
        orders[id].makerProfit = - profit;

        _settle(id);
    }

    function _settle(uint256 id) internal {
        TransferHelper.safeTransfer(clearAnchor, IManager(manager).feeOwner(), orders[id].feeToExchange);

        if (orders[id].feeToInviter > 0) {
            TransferHelper.safeTransfer(clearAnchor, orders[id].inviter, orders[id].feeToInviter);
        }

        if (orders[id].riskFunding > 0) {
            TransferHelper.safeTransfer(clearAnchor, IManager(manager).riskFundingOwner(), orders[id].riskFunding);
        }

        int256 takerBalance = int256(orders[id].takerMargin).add(orders[id].takerProfit).sub(int256(orders[id].riskFunding));
        require(takerBalance >= 0, "takerBalance error");
        if (takerBalance > 0) {
            TransferHelper.safeTransfer(clearAnchor, taker, uint256(takerBalance));
            IUser(taker).receiveToken(clearAnchor, orders[id].taker, uint256(takerBalance));
        }

        int256 makerBalance = int256(orders[id].makerMargin).add(orders[id].makerProfit).add(int256(orders[id].feeToMaker));
        require(makerBalance >= 0, "takerBalance error");
        if (makerBalance > 0) {
            TransferHelper.safeTransfer(clearAnchor, maker, uint256(makerBalance));
        }
        uint256 margin = orders[id].takerInitMargin;
        if (marketType == 2) {
            margin = margin.mul(10 ** clearAnchorRatioDecimals).div(orders[id].clearAnchorRatio);
        }
        IMaker(maker).closeUpdate(orders[id].makerMargin, orders[id].takerMargin, orders[id].amount, margin.mul(orders[id].takerLeverage), orders[id].makerProfit, orders[id].feeToMaker, orders[id].direction);

        uint256 income = (orders[id].takerMargin).add(orders[id].takerFee).add(orders[id].makerMargin);
        uint256 payout = (orders[id].feeToInviter).add(orders[id].feeToExchange).add(orders[id].riskFunding).add(uint256(takerBalance)).add(uint256(makerBalance));
        require(income == payout, "settle error");

        uint256 value = orders[id].takerInitMargin.mul(orders[id].takerLeverage);
        takerValues[orders[id].taker] = takerValues[orders[id].taker].sub(value);
    }

    function openCancel(address _taker, uint256 id) external nonReentrant onlyRouter {
        require(orders[id].taker == _taker, "not taker");
        require(orders[id].status == Types.OrderStatus.Open, "not open");
        require(orders[id].takerOpenDeadline < block.number, "deadline");
        _cancel(id);
    }

    function closeCancel(address _taker, uint256 id) external nonReentrant onlyRouter {
        require(orders[id].taker == _taker, "not taker");
        require(orders[id].status == Types.OrderStatus.Close, "not close");
        require(orders[id].takerCloseDeadline < block.number, "deadline");

        orders[id].status = Types.OrderStatus.Opened;
    }

    function priceToOpenCancel(uint256 id) external nonReentrant onlyRouter {
        require(orders[id].status == Types.OrderStatus.Open, "not open");
        _cancel(id);
    }

    function priceToCloseCancel(uint256 id) external nonReentrant onlyRouter {
        require(orders[id].status == Types.OrderStatus.Close, "not close");
        orders[id].status = Types.OrderStatus.Opened;
    }

    function _cancel(uint256 id) internal {
        orders[id].status = Types.OrderStatus.Canceled;
        uint256 value = orders[id].takerInitMargin.mul(orders[id].takerLeverage);
        takerValues[orders[id].taker] = takerValues[orders[id].taker].sub(value);
        uint256 balance = orders[id].takerMargin.add(orders[id].takerFee);
        TransferHelper.safeTransfer(clearAnchor, taker, balance);
        IUser(taker).receiveToken(clearAnchor, orders[id].taker, balance);
    }

    function getTakerOrderlist(address _taker) external view returns (uint256[] memory) {
        return takerOrderlist[_taker];
    }

    function getByID(uint256 id) external view returns (bytes memory) {
        bytes memory _preBytes = abi.encode(
            orders[id].inviter,
            orders[id].taker,
            orders[id].takerOpenDeadline,
            orders[id].takerOpenPriceMin,
            orders[id].takerOpenPriceMax,
            orders[id].takerMargin,
            orders[id].takerLeverage,
            orders[id].direction,
            orders[id].takerFee
        );
        bytes memory _postBytes = abi.encode(
            orders[id].feeToInviter,
            orders[id].feeToExchange,
            orders[id].feeToMaker,
            orders[id].openPrice,
            orders[id].openIndexPrice,
            orders[id].openIndexPriceTimestamp,
            orders[id].amount,
            orders[id].makerMargin,
            orders[id].makerLeverage,
            orders[id].takerLiquidationPrice
        );

        bytes memory tempBytes = Bytes.contact(_preBytes, _postBytes);

        _postBytes = abi.encode(
            orders[id].takerBrokePrice,
            orders[id].makerBrokePrice,
            orders[id].takerCloseDeadline,
            orders[id].takerClosePriceMin,
            orders[id].takerClosePriceMax,
            orders[id].closePrice,
            orders[id].closeIndexPrice,
            orders[id].closeIndexPriceTimestamp,
            orders[id].takerProfit,
            orders[id].makerProfit
        );

        tempBytes = Bytes.contact(tempBytes, _postBytes);

        _postBytes = abi.encode(
            orders[id].riskFunding,
            orders[id].deadline,
            orders[id].status,
            orders[id].takerOpenTimestamp,
            orders[id].takerCloseTimestamp,
            orders[id].clearAnchorRatio,
            orders[id].takerInitMargin,
            orders[id].takerTrueLeverage
        );

        tempBytes = Bytes.contact(tempBytes, _postBytes);

        return tempBytes;
    }

}