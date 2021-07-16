//SourceUnit: Temp.sol

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

// File: contracts/ERC20.sol

pragma solidity >=0.5.15  <=0.5.17;



contract ERC20 is IERC20 {
    using SafeMath for uint;

    string public name = 'YFX V1';
    string public symbol = 'YFX-V1';
    uint public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    function _mint(address to, uint value) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(from != address(0), "ERC20: _burn from the zero address");
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: owner is the zero address");
        require(spender != address(0), "ERC20: spender is the zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        require(from != address(0), "ERC20: _transfer from the zero address");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(from != address(0), "ERC20: transferFrom from the zero address");
        if (allowance[from][msg.sender] != uint(- 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
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

// File: contracts/Maker.sol

pragma solidity >=0.5.15  <=0.5.17;













contract Maker is IMaker, ERC20, ReentrancyGuard {
    using SafeMath for uint;
    using SignedSafeMath for int;

    uint public makerAutoId = 1;
    uint public indexPrice;

    address public factory;
    address public market;
    address public manager;

    uint256 public balance;
    uint256 public makerLock;
    uint256 public sharePrice;

    uint256 public longAmount;
    uint256 public longMargin;
    uint256 public longOpenTotal;

    uint256 public shortAmount;
    uint256 public shortMargin;
    uint256 public shortOpenTotal;

    uint256 public takerTotalMargin;

    address public clearAnchorAddress;
    address public userAddress;
    uint public clearAnchorDecimals;
    uint256 public constant priceDecimals = 10;
    uint256 public constant amountDecimals = 10;
    uint256 public constant sharePriceDecimals = 20;
    uint public marketType;
    //the rate is x/10000
    uint public openRate = 5000;
    //the rate is x/1000000
    uint public removeLiquidityRate = 1000;
    uint public minAddLiquidityAmount;
    uint public minRemoveLiquidity;
    //
    int256 public rlzPNL;
    uint public feeToMaker;

    mapping(uint => Types.MakerOrder) makerOrders;
    mapping(address => uint[]) public makerOrderIds;
    mapping(address => uint) public lockBalanceOf;

    bool public addPaused = true;
    bool public removePaused = true;

    constructor(address _manager) public {
        require(_manager != address(0), "Maker:constructor _manager is zero address");
        manager = _manager;
        factory = msg.sender;
    }

    modifier _onlyMarket(){
        require(msg.sender == market, 'Caller is not market');
        _;
    }

    modifier _onlyRouter(){
        require(IManager(manager).checkRouter(msg.sender), 'only router');
        _;
    }

    modifier _onlyManager(){
        require(IManager(manager).checkController(msg.sender), 'only manage');
        _;
    }

    modifier whenNotAddPaused() {
        require(!IManager(manager).paused() && !addPaused, "paused");
        _;
    }

    modifier whenNotRemovePaused() {
        require(!IManager(manager).paused() && !removePaused, "paused");
        _;
    }

    function initialize(
        uint _indexPrice,
        address _clearAnchorAddress,
        address _market,
        uint _marketType,
        string calldata _lpTokenName
    ) external returns (bool){
        require(msg.sender == factory, 'Caller is not factory');
        require(_clearAnchorAddress != address(0), "Maker:initialize _clearAnchorAddress is zero address");
        require(_market != address(0), "Maker:initialize _market is zero address");
        indexPrice = _indexPrice;
        clearAnchorAddress = _clearAnchorAddress;
        market = _market;
        marketType = _marketType;
        name = _lpTokenName;
        symbol = _lpTokenName;
        clearAnchorDecimals = IERC20(clearAnchorAddress).decimals();
        userAddress = IManager(manager).taker();
        return true;
    }

    function getOrder(uint _no) external view returns (bytes memory _order){
        require(makerOrders[_no].id != 0, "not exist");
        bytes memory _order1 = abi.encode(
            makerOrders[_no].id,
            makerOrders[_no].maker,
            makerOrders[_no].submitBlockHeight,
            makerOrders[_no].submitBlockTimestamp,
            makerOrders[_no].price,
            makerOrders[_no].priceTimestamp,
            makerOrders[_no].amount,
            makerOrders[_no].liquidity,
            makerOrders[_no].feeToPool,
            makerOrders[_no].cancelBlockHeight);
        bytes memory _order2 = abi.encode(
            makerOrders[_no].sharePrice,
            makerOrders[_no].poolTotal,
            makerOrders[_no].profit,
            makerOrders[_no].action,
            makerOrders[_no].status);

        _order = Bytes.contact(_order1, _order2);
    }

    function open(uint _value) external nonReentrant _onlyMarket returns (bool){
        require(this.canOpen(_value), 'Insufficient pool balance');
        uint preTotal = balance.add(makerLock);
        balance = balance.sub(_value);
        makerLock = makerLock.add(_value);
        TransferHelper.safeTransfer(clearAnchorAddress, market, _value);
        assert(preTotal == balance.add(makerLock));
        return true;
    }

    function openUpdate(
        uint _makerMargin,
        uint _takerMargin,
        uint _amount,
        uint _total,
        int8 _takerDirection
    ) external nonReentrant _onlyMarket returns (bool){
        require(_makerMargin > 0 && _takerMargin > 0 && _amount > 0 && _total > 0, 'can not zero');
        require(_takerDirection == 1 || _takerDirection == - 1, 'takerDirection is invalid');
        takerTotalMargin = takerTotalMargin.add(_takerMargin);
        if (_takerDirection == 1) {
            longAmount = longAmount.add(_amount);
            longMargin = longMargin.add(_makerMargin);
            longOpenTotal = longOpenTotal.add(_total);
        } else {
            shortAmount = shortAmount.add(_amount);
            shortMargin = shortMargin.add(_makerMargin);
            shortOpenTotal = shortOpenTotal.add(_total);
        }
        return true;
    }

    function closeUpdate(
        uint _makerMargin,
        uint _takerMargin,
        uint _amount,
        uint _total,
        int makerProfit,
        uint makerFee,
        int8 _takerDirection
    ) external nonReentrant _onlyMarket returns (bool){
        require(_makerMargin > 0 && _takerMargin > 0 && _amount > 0 && _total > 0, 'can not zero');
        require(makerLock >= _makerMargin, 'makerMargin is invalid');
        require(_takerDirection == 1 || _takerDirection == - 1, 'takerDirection is invalid');
        makerLock = makerLock.sub(_makerMargin);
        balance = balance.add(makerFee);
        feeToMaker = feeToMaker.add(makerFee);
        rlzPNL = rlzPNL.add(makerProfit);
        int256 tempProfit = makerProfit.add(int(_makerMargin));
        require(tempProfit >= 0, 'tempProfit is invalid');
        balance = uint(tempProfit.add(int256(balance)));
        require(takerTotalMargin >= _takerMargin, 'takerMargin is invalid');
        takerTotalMargin = takerTotalMargin.sub(_takerMargin);
        if (_takerDirection == 1) {
            require(longAmount >= _amount && longMargin >= _makerMargin && longOpenTotal >= _total, 'long data error');
            longAmount = longAmount.sub(_amount);
            longMargin = longMargin.sub(_makerMargin);
            longOpenTotal = longOpenTotal.sub(_total);
        } else {
            require(shortAmount >= _amount && shortMargin >= _makerMargin && shortOpenTotal >= _total, 'short data error');
            shortAmount = shortAmount.sub(_amount);
            shortMargin = shortMargin.sub(_makerMargin);
            shortOpenTotal = shortOpenTotal.sub(_total);
        }
        return true;
    }

    function takerDepositMarginUpdate(uint _margin) external nonReentrant _onlyMarket returns (bool){
        require(_margin > 0, 'can not zero');
        require(takerTotalMargin > 0, 'empty position');
        takerTotalMargin = takerTotalMargin.add(_margin);
        return true;
    }

    function addLiquidity(
        address sender,
        uint amount
    ) external nonReentrant _onlyRouter whenNotAddPaused returns (
        uint _id,
        address _makerAddress,
        uint _amount,
        uint _cancelBlockElapse
    ){
        require(sender != address(0), "Maker:addLiquidity sender is zero address");
        require(amount >= minAddLiquidityAmount, 'amount < minAddLiquidityAmount');
        (bool isSuccess) = IUser(userAddress).transfer(clearAnchorAddress, sender, amount);
        require(isSuccess, 'transfer fail');
        makerOrders[makerAutoId] = Types.MakerOrder(
            makerAutoId,
            sender,
            block.number,
            block.timestamp,
            0,
            0,
            amount,
            0,
            0,
            0,
            sharePrice,
            0,
            0,
            Types.PoolAction.Deposit,
            Types.PoolActionStatus.Submit
        );
        makerOrders[makerAutoId].cancelBlockHeight = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        _id = makerOrders[makerAutoId].id;
        _makerAddress = address(this);
        _amount = makerOrders[makerAutoId].amount;
        _cancelBlockElapse = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        makerOrderIds[sender].push(makerAutoId);
        makerAutoId = makerAutoId.add(1);
    }

    function cancelAddLiquidity(
        address sender,
        uint id
    ) external nonReentrant _onlyRouter returns (uint _amount){
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.maker == sender, 'Caller is not order owner');
        require(order.action == Types.PoolAction.Deposit, 'not deposit');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        require(block.number > order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Can not cancel');
        order.status = Types.PoolActionStatus.Cancel;
        IUser(userAddress).receiveToken(clearAnchorAddress, order.maker, order.amount);
        TransferHelper.safeTransfer(clearAnchorAddress, userAddress, order.amount);
        _amount = order.amount;
        //makerOrders[id] = order;
    }

    function priceToAddLiquidity(
        uint256 id,
        uint256 price,
        uint256 priceTimestamp
    ) external nonReentrant _onlyRouter returns (uint liquidity){
        // require(price > 0, 'Price is not zero');
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(block.number < order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Time out');
        require(order.action == Types.PoolAction.Deposit, 'not deposit');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        order.status = Types.PoolActionStatus.Success;
        int totalUnPNL;
        if (balance.add(makerLock) > 0 && totalSupply > 0) {
            (totalUnPNL) = this.makerProfit(price);
            require(totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock), 'taker or maker is broken');
            liquidity = order.amount.mul(totalSupply).div(uint(totalUnPNL.add(int(makerLock)).add(int(balance))));
        } else {
            sharePrice = 10 ** sharePriceDecimals;
            liquidity = order.amount.mul(10 ** decimals).div(10 ** clearAnchorDecimals);
        }
        _mint(order.maker, liquidity);
        balance = balance.add(order.amount);
        order.poolTotal = int(balance).add(int(makerLock)).add(totalUnPNL);
        sharePrice = uint(order.poolTotal).mul(10 ** decimals).mul(10 ** sharePriceDecimals).div(totalSupply).div(10 ** clearAnchorDecimals);
        order.price = price;
        order.profit = rlzPNL.add(int(feeToMaker)).add(totalUnPNL);
        order.liquidity = liquidity;
        order.sharePrice = sharePrice;
        order.priceTimestamp = priceTimestamp;
        //makerOrders[id] = order;
    }

    function removeLiquidity(
        address sender,
        uint liquidity
    ) external nonReentrant _onlyRouter whenNotRemovePaused returns (
        uint _id,
        address _makerAddress,
        uint _liquidity,
        uint _cancelBlockElapse
    ){
        require(sender != address(0), "Maker:removeLiquidity sender is zero address");
        require(liquidity >= minRemoveLiquidity, 'liquidity < minRemoveLiquidity');
        require(balanceOf[sender] >= liquidity, 'Insufficient balance');
        balanceOf[sender] = balanceOf[sender].sub(liquidity);
        lockBalanceOf[sender] = lockBalanceOf[sender].add(liquidity);
        makerOrders[makerAutoId] = Types.MakerOrder(
            makerAutoId,
            sender,
            block.number,
            block.timestamp,
            0,
            0,
            0,
            liquidity,
            0,
            0,
            sharePrice,
            0,
            0,
            Types.PoolAction.Withdraw,
            Types.PoolActionStatus.Submit
        );
        makerOrders[makerAutoId].cancelBlockHeight = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        _id = makerOrders[makerAutoId].id;
        _makerAddress = address(this);
        _liquidity = makerOrders[makerAutoId].liquidity;
        _cancelBlockElapse = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        makerOrderIds[sender].push(makerAutoId);
        makerAutoId = makerAutoId.add(1);
    }

    function cancelRemoveLiquidity(address sender, uint id) external nonReentrant _onlyRouter returns (bool){
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.maker == sender, 'Caller is not sender');
        require(order.action == Types.PoolAction.Withdraw, 'not withdraw');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        require(block.number > order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Can not cancel');
        order.status = Types.PoolActionStatus.Cancel;
        lockBalanceOf[sender] = lockBalanceOf[sender].sub(order.liquidity);
        balanceOf[sender] = balanceOf[sender].add(order.liquidity);
        //makerOrders[id] = order;
        return true;
    }

    function systemCancelAddLiquidity(uint id) external nonReentrant _onlyRouter {
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.action == Types.PoolAction.Deposit, 'not deposit');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        order.status = Types.PoolActionStatus.Fail;
        IUser(userAddress).receiveToken(clearAnchorAddress, order.maker, order.amount);
        TransferHelper.safeTransfer(clearAnchorAddress, userAddress, order.amount);
    }

    function systemCancelRemoveLiquidity(uint id) external nonReentrant _onlyRouter {
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.action == Types.PoolAction.Withdraw, 'not withdraw');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        order.status = Types.PoolActionStatus.Fail;
        lockBalanceOf[order.maker] = lockBalanceOf[order.maker].sub(order.liquidity);
        balanceOf[order.maker] = balanceOf[order.maker].add(order.liquidity);
    }

    function priceToRemoveLiquidity(
        uint id,
        uint price,
        uint priceTimestamp
    ) external nonReentrant _onlyRouter returns (uint amount){
        require(price > 0 && totalSupply > 0 && balance.add(makerLock) > 0, 'params is invalid');
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(block.number < order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Time out');
        require(order.action == Types.PoolAction.Withdraw, 'not withdraw');
        require(order.status == Types.PoolActionStatus.Submit && totalSupply >= order.liquidity, 'not submit');
        order.status = Types.PoolActionStatus.Success;
        (int totalUnPNL) = this.makerProfit(price);
        require(totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock), 'taker or maker is broken');
        amount = order.liquidity.mul(uint(int(makerLock).add(int(balance)).add(totalUnPNL))).div(totalSupply);
        require(amount > 0, 'amount is zero');
        require(balance >= amount, 'Insufficient balance');
        balance = balance.sub(amount);
        balanceOf[order.maker] = balanceOf[order.maker].add(order.liquidity);
        lockBalanceOf[order.maker] = lockBalanceOf[order.maker].sub(order.liquidity);
        _burn(order.maker, order.liquidity);
        order.amount = amount.mul(uint(1000000).sub(removeLiquidityRate)).div(1000000);
        require(order.amount > 0, 'order.amount is zero');
        order.feeToPool = amount.sub(order.amount);
        IUser(userAddress).receiveToken(clearAnchorAddress, order.maker, order.amount);
        TransferHelper.safeTransfer(clearAnchorAddress, userAddress, order.amount);
        require(IManager(manager).poolFeeOwner() != address(0), 'poolFee is zero address');
        if (order.feeToPool > 0) {
            TransferHelper.safeTransfer(clearAnchorAddress, IManager(manager).poolFeeOwner(), order.feeToPool);
        }
        order.poolTotal = int(balance).add(int(makerLock)).add(totalUnPNL);
        if (totalSupply > 0) {
            sharePrice = uint(order.poolTotal).mul(10 ** decimals).mul(10 ** sharePriceDecimals).div(totalSupply).div(10 ** clearAnchorDecimals);
        } else {
            sharePrice = 10 ** sharePriceDecimals;
        }
        order.price = price;
        order.profit = rlzPNL.add(int(feeToMaker)).add(totalUnPNL);
        order.sharePrice = sharePrice;
        order.priceTimestamp = priceTimestamp;
        //makerOrders[id] = order;
    }

    function makerProfit(uint256 _price) external view returns (int256 unPNL){
        require(marketType == 0 || marketType == 1 || marketType == 2, 'marketType is invalid');
        int256 shortUnPNL = 0;
        int256 longUnPNL = 0;
        if (marketType == 1) {//rervese
            int256 closeLongTotal = int256(longAmount.mul(10 ** priceDecimals).mul(10 ** clearAnchorDecimals).div(_price).div(10 ** amountDecimals));
            int256 openLongTotal = int256(longOpenTotal);
            longUnPNL = (openLongTotal.sub(closeLongTotal)).mul(- 1);

            int256 closeShortTotal = int256(shortAmount.mul(10 ** priceDecimals).mul(10 ** clearAnchorDecimals).div(_price).div(10 ** amountDecimals));
            int256 openShortTotal = int256(shortOpenTotal);
            shortUnPNL = openShortTotal.sub(closeShortTotal);

            unPNL = shortUnPNL.add(longUnPNL);
        } else {
            int256 closeLongTotal = int256(longAmount.mul(_price).mul(10 ** clearAnchorDecimals).div(10 ** priceDecimals).div(10 ** amountDecimals));
            int256 openLongTotal = int256(longOpenTotal);
            longUnPNL = (closeLongTotal.sub(openLongTotal)).mul(- 1);

            int256 closeShortTotal = int256(shortAmount.mul(_price).mul(10 ** clearAnchorDecimals).div(10 ** priceDecimals).div(10 ** amountDecimals));
            int256 openShortTotal = int256(shortOpenTotal);
            shortUnPNL = closeShortTotal.sub(openShortTotal);

            unPNL = shortUnPNL.add(longUnPNL);
            if (marketType == 2) {
                unPNL = unPNL.mul(int(IMarket(market).clearAnchorRatio())).div(int(10 ** IMarket(market).clearAnchorRatioDecimals()));
            }
        }
    }

    function updateSharePrice(uint price) external view returns (
        uint _price,
        uint256 _balance,
        uint256 _makerLock,
        uint256 _feeToMaker,

        uint256 _longAmount,
        uint256 _longMargin,
        uint256 _longOpenTotal,

        uint256 _shortAmount,
        uint256 _shortMargin,
        uint256 _shortOpenTotal
    ){
        require(price > 0, 'params is invalid');
        (int totalUnPNL) = this.makerProfit(price);
        require(totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock), 'taker or maker is broken');
        if (totalSupply > 0) {
            _price = uint(totalUnPNL.add(int(makerLock)).add(int(balance))).mul(10 ** decimals).mul(10 ** sharePriceDecimals).div(totalSupply).div(10 ** clearAnchorDecimals);
        } else {
            _price = 10 ** sharePriceDecimals;
        }
        _balance = balance;
        _makerLock = makerLock;
        _feeToMaker = feeToMaker;

        _longAmount = longAmount;
        _longMargin = longMargin;
        _longOpenTotal = longOpenTotal;

        _shortAmount = shortAmount;
        _shortMargin = shortMargin;
        _shortOpenTotal = shortOpenTotal;
    }

    function setMinAddLiquidityAmount(uint _minAmount) external _onlyManager returns (bool){
        minAddLiquidityAmount = _minAmount;
        return true;
    }

    function setMinRemoveLiquidity(uint _minLiquidity) external _onlyManager returns (bool){
        minRemoveLiquidity = _minLiquidity;
        return true;
    }

    function setOpenRate(uint _openRate) external _onlyManager returns (bool){
        openRate = _openRate;
        return true;
    }

    function setRemoveLiquidityRate(uint _rate) external _onlyManager returns (bool){
        removeLiquidityRate = _rate;
        return true;
    }

    function setPaused(bool _add, bool _remove) external _onlyManager {
        addPaused = _add;
        removePaused = _remove;
    }

    function getMakerOrderIds(address _maker) external view returns (uint[] memory){
        return makerOrderIds[_maker];
    }

    function canOpen(uint _makerMargin) external view returns (bool _can){
        if (balance > _makerMargin) {
            uint rate = (makerLock.add(_makerMargin)).mul(10000).div(balance.add(makerLock));
            _can = (rate <= openRate) ? true : false;
        } else {
            _can = false;
        }
    }

    function canRemoveLiquidity(uint _price, uint _liquidity) external view returns (bool){
        if (_price > 0 && totalSupply > 0) {
            (int totalUnPNL) = this.makerProfit(_price);
            if (totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock)) {
                uint amount = _liquidity.mul(uint(int(makerLock).add(int(balance)).add(totalUnPNL))).div(totalSupply);
                if (balance >= amount) {
                    return true;
                }
            }
        }
        return false;
    }

    function canAddLiquidity(uint _price) external view returns (bool){
        (int totalUnPNL) = this.makerProfit(_price);
        if (totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock)) {
            return true;
        }
        return false;
    }

    function getLpBalanceOf(address _maker) external view returns (uint _balance, uint _totalSupply){
        _balance = balanceOf[_maker];
        _totalSupply = totalSupply;
    }
}