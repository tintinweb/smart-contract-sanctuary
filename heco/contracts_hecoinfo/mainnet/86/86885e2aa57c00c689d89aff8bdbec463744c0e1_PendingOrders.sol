/**
 *Submitted for verification at hecoinfo.com on 2022-05-06
*/

// File: IPredictionPool.sol

pragma solidity ^0.7.4;







interface IPredictionPool {

    function buyWhite(uint256 maxPrice, uint256 payment) external;



    function buyBlack(uint256 maxPrice, uint256 payment) external;



    function sellWhite(uint256 tokensAmount, uint256 minPrice) external;



    function sellBlack(uint256 tokensAmount, uint256 minPrice) external;



    function _whitePrice() external returns (uint256);



    function _blackPrice() external returns (uint256);



    function _whiteToken() external returns (address);



    function _blackToken() external returns (address);



    function _thisCollateralization() external returns (address);



    function _eventStarted() external view returns (bool);



    // solhint-disable-next-line func-name-mixedcase

    function FEE() external returns (uint256);

}


// File: Common/Ownable.sol

pragma solidity ^0.7.4;





/**

 * @title Ownable

 * @dev The Ownable contract has an owner address, and provides basic authorization control

 * functions, this simplifies the implementation of "user permissions".

 */

abstract contract Ownable {

    address private _owner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    /**

     * @dev The Ownable constructor sets the original `owner` of the contract to the sender

     * account.

     */

    constructor () {

        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);

    }



    /**

     * @return the address of the owner.

     */

    function owner() public view returns (address) {

        return _owner;

    }



    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {

        require(isOwner());

        _;

    }



    /**

     * @return true if `msg.sender` is the owner of the contract.

     */

    function isOwner() public view returns (bool) {

        return msg.sender == _owner;

    }



    /**

     * @dev Allows the current owner to relinquish control of the contract.

     * @notice Renouncing to ownership will leave the contract without an owner.

     * It will not be possible to call the functions with the `onlyOwner`

     * modifier anymore.

     */

    function renounceOwnership() public onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);

    }



    /**

     * @dev Allows the current owner to transfer control of the contract to a newOwner.

     * @param newOwner The address to transfer ownership to.

     */

    function transferOwnership(address newOwner) public onlyOwner {

        _transferOwnership(newOwner);

    }



    /**

     * @dev Transfers control of the contract to a newOwner.

     * @param newOwner The address to transfer ownership to.

     */

    function _transferOwnership(address newOwner) internal {

        require(newOwner != address(0));

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;

    }

}
// File: Common/IERC20.sol

pragma solidity ^0.7.4;





interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}
// File: SafeMath.sol

pragma solidity >=0.5.16;







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

     */

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b != 0, errorMessage);

        return a % b;

    }

}
// File: DSMath.sol



// See <http://www.gnu.org/licenses/>



pragma solidity >0.4.13;



contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {

        require((z = x + y) >= x, "ds-math-add-overflow");

    }

    function sub(uint x, uint y) internal pure returns (uint z) {

        require((z = x - y) <= x, "ds-math-sub-underflow");

    }

    function mul(uint x, uint y) internal pure returns (uint z) {

        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");

    }



    function min(uint x, uint y) internal pure returns (uint z) {

        return x <= y ? x : y;

    }

    function max(uint x, uint y) internal pure returns (uint z) {

        return x >= y ? x : y;

    }

    function imin(int x, int y) internal pure returns (int z) {

        return x <= y ? x : y;

    }

    function imax(int x, int y) internal pure returns (int z) {

        return x >= y ? x : y;

    }



    uint constant WAD = 10 ** 18;

    uint constant RAY = 10 ** 27;



    //rounds to zero if x*y < WAD / 2

    function wmul(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, y), WAD / 2) / WAD;

    }

    //rounds to zero if x*y < WAD / 2

    function rmul(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, y), RAY / 2) / RAY;

    }

    //rounds to zero if x*y < WAD / 2

    function wdiv(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, WAD), y / 2) / y;

    }

    //rounds to zero if x*y < RAY / 2

    function rdiv(uint x, uint y) internal pure returns (uint z) {

        z = add(mul(x, RAY), y / 2) / y;

    }



    // This famous algorithm is called "exponentiation by squaring"

    // and calculates x^n with x as fixed-point and n as regular unsigned.

    //

    // It's O(log n), instead of O(n) for naive repeated multiplication.

    //

    // These facts are why it works:

    //

    //  If n is even, then x^n = (x^2)^(n/2).

    //  If n is odd,  then x^n = x * x^(n-1),

    //   and applying the equation for even x gives

    //    x^n = x * (x^2)^((n-1) / 2).

    //

    //  Also, EVM division is flooring and

    //    floor[(n-1) / 2] = floor[n / 2].

    //

    function rpow(uint x, uint n) internal pure returns (uint z) {

        z = n % 2 != 0 ? x : RAY;



        for (n /= 2; n != 0; n /= 2) {

            x = rmul(x, x);



            if (n % 2 != 0) {

                z = rmul(z, x);

            }

        }

    }

}


// File: PendingOrders.sol

pragma solidity ^0.7.4;












contract PendingOrders is DSMath, Ownable {

    using SafeMath for uint256;



    struct Order {

        /* solhint-disable prettier/prettier */

        address orderer;    // address of user placing order

        uint256 amount;     // amount of collateral tokens

        bool isWhite;       // TRUE for white side, FALSE for black side

        uint256 eventId;    // order target eventId

        bool isPending;     // TRUE when placed, FALSE when canceled

        /* solhint-enable prettier/prettier */

    }



    // ordersCount count number of orders so far, and is id of very last order

    uint256 public _ordersCount;



    IERC20 public _collateralToken;

    IPredictionPool public _predictionPool;



    address public _eventContractAddress;



    // mapping from order ID to Order detail

    mapping(uint256 => Order) public _orders;



    // mapping from user address to order IDs for that user

    mapping(address => uint256[]) public _ordersOfUser;



    struct Detail {

        /* solhint-disable prettier/prettier */

        uint256 amount;

        uint256 whiteCollateral;    // total amount of collateral for white side of the event

        uint256 blackCollateral;    // total amount of collateral for black side of the event

        uint256 whitePriceBefore;   // price of white token before the event

        uint256 blackPriceBefore;   // price of black token before the event

        uint256 whitePriceAfter;    // price of white token after the event

        uint256 blackPriceAfter;    // price of black token after the event

        bool isExecuted;            // FALSE before the event, TRUE after the event

        bool isStarted;             // FALSE before the event, TRUE after the event

        /* solhint-enable prettier/prettier */

    }



    // mapping from event ID to detail for that event

    mapping(uint256 => Detail) public _detailForEvent;



    event OrderCreated(uint256 id, address user, uint256 amount);

    event OrderCanceled(uint256 id, address user);

    event CollateralWithdrew(uint256 amount, address user);

    event ContractOwnerChanged(address owner);

    event EventContractAddressChanged(address eventContract);

    event FeeWithdrawAddressChanged(address feeAddress);

    event FeeWithdrew(uint256 amount);

    event FeeChanged(uint256 number);

    event AmountExecuted(uint256 amount);



    constructor(

        address predictionPoolAddress,

        address collateralTokenAddress,

        address eventContractAddress

    ) {

        require(

            predictionPoolAddress != address(0),

            "SECONDARY POOL ADDRESS SHOULD NOT BE NULL"

        );

        require(

            collateralTokenAddress != address(0),

            "COLLATERAL TOKEN ADDRESS SHOULD NOT BE NULL"

        );

        require(

            eventContractAddress != address(0),

            "EVENT ADDRESS SHOULD NOT BE NULL"

        );

        _predictionPool = IPredictionPool(predictionPoolAddress);

        _collateralToken = IERC20(collateralTokenAddress);

        _eventContractAddress = eventContractAddress;



        _collateralToken.approve(

            address(_predictionPool._thisCollateralization()),

            type(uint256).max

        );

        IERC20(_predictionPool._whiteToken()).approve(

            _predictionPool._thisCollateralization(),

            type(uint256).max

        );

        IERC20(_predictionPool._blackToken()).approve(

            _predictionPool._thisCollateralization(),

            type(uint256).max

        );

    }



    // Modifier to ensure call has been made by event contract

    modifier onlyEventContract() {

        require(

            msg.sender == _eventContractAddress,

            "CALLER SHOULD BE EVENT CONTRACT"

        );

        _;

    }



    function createOrder(

        uint256 _amount,

        bool _isWhite,

        uint256 _eventId

    ) external {

        require(!_detailForEvent[_eventId].isStarted, "EVENT ALREADY STARTED");

        require(

            _collateralToken.balanceOf(msg.sender) >= _amount,

            "NOT ENOUGH COLLATERAL IN USER'S ACCOUNT"

        );

        require(

            _collateralToken.allowance(msg.sender, address(this)) >= _amount,

            "NOT ENOUGHT DELEGATED TOKENS"

        );

        require(

            _ordersOfUser[msg.sender].length <= 10,

            "CANNOT HAVE MORE THAN 10 ORDERS FOR A USER SIMULTANEOUSLY"

        );



        _orders[_ordersCount] = Order(

            msg.sender,

            _amount,

            _isWhite,

            _eventId,

            true

        );



        /* solhint-disable prettier/prettier */

        _isWhite

            ? _detailForEvent[_eventId].whiteCollateral = _detailForEvent[_eventId].whiteCollateral.add(_amount)

            : _detailForEvent[_eventId].blackCollateral = _detailForEvent[_eventId].blackCollateral.add(_amount);

        /* solhint-enable prettier/prettier */

        _ordersOfUser[msg.sender].push(_ordersCount);



        _collateralToken.transferFrom(msg.sender, address(this), _amount);

        emit OrderCreated(_ordersCount, msg.sender, _amount);

        _ordersCount += 1;

    }



    function ordersOfUser(address user)

        external

        view

        returns (uint256[] memory)

    {

        return _ordersOfUser[user];

    }



    function cancelOrder(uint256 orderId) external {

        Order memory order = _orders[orderId];

        require(msg.sender == order.orderer, "NOT YOUR ORDER");



        require(order.isPending, "ORDER HAS ALREADY BEEN CANCELED");



        require(!_detailForEvent[order.eventId].isStarted, "EVENT IN PROGRESS");



        require(

            !_detailForEvent[order.eventId].isExecuted,

            "ORDER HAS ALREADY BEEN EXECUTED"

        );



        /* solhint-disable prettier/prettier */

        order.isWhite

            ? _detailForEvent[order.eventId].whiteCollateral = _detailForEvent[order.eventId].whiteCollateral.sub(order.amount)

            : _detailForEvent[order.eventId].blackCollateral = _detailForEvent[order.eventId].blackCollateral.sub(order.amount);

        /* solhint-enable prettier/prettier */

        _orders[orderId].isPending = false;

        _collateralToken.transfer(order.orderer, order.amount);

        emit OrderCanceled(orderId, msg.sender);

    }



    function eventStart(uint256 _eventId) external onlyEventContract {

        // solhint-disable-next-line var-name-mixedcase

        uint256 MAX_PRICE = 100 * WAD;

        uint256 forWhite = _detailForEvent[_eventId].whiteCollateral;

        uint256 forBlack = _detailForEvent[_eventId].blackCollateral;

        if (forWhite > 0) {

            _predictionPool.buyWhite(MAX_PRICE, forWhite);

            // solhint-disable-next-line prettier/prettier

            _detailForEvent[_eventId].whitePriceBefore = _predictionPool._whitePrice();

        }

        if (forBlack > 0) {

            _predictionPool.buyBlack(MAX_PRICE, forBlack);

            // solhint-disable-next-line prettier/prettier

            _detailForEvent[_eventId].blackPriceBefore = _predictionPool._blackPrice();

        }

        _detailForEvent[_eventId].isStarted = true;

    }



    function eventEnd(uint256 _eventId) external onlyEventContract {

        // solhint-disable-next-line var-name-mixedcase

        uint256 MIN_PRICE = 0;

        uint256 ownWhite = IERC20(_predictionPool._whiteToken()).balanceOf(

            address(this)

        );

        uint256 ownBlack = IERC20(_predictionPool._blackToken()).balanceOf(

            address(this)

        );



        if (ownWhite > 0) {

            _predictionPool.sellWhite(ownWhite, MIN_PRICE);

            // solhint-disable-next-line prettier/prettier

            _detailForEvent[_eventId].whitePriceAfter = _predictionPool._whitePrice();

        }

        if (ownBlack > 0) {

            _predictionPool.sellBlack(ownBlack, MIN_PRICE);

            // solhint-disable-next-line prettier/prettier

            _detailForEvent[_eventId].blackPriceAfter = _predictionPool._blackPrice();

        }

        _detailForEvent[_eventId].isExecuted = true;

    }



    function withdrawCollateral() external returns (uint256) {

        require(_ordersOfUser[msg.sender].length > 0, "YOU DON'T HAVE ORDERS");



        // total amount of collateral token that should be returned to user

        // feeAmount should be subtracted before actual return

        uint256 totalWithdrawAmount;



        uint256 i = 0;

        while (i < _ordersOfUser[msg.sender].length) {

            uint256 _oId = _ordersOfUser[msg.sender][i]; // order ID

            Order memory order = _orders[_oId];

            uint256 _eId = order.eventId; // event ID

            Detail memory eventDetail = _detailForEvent[_eId];



            // calculate and sum up collaterals to be returned

            // exclude canceled orders, only include executed orders

            if (order.isPending && eventDetail.isExecuted) {

                uint256 withdrawAmount = 0;

                uint256 priceAfter = 0;

                uint256 priceBefore = 0;



                if (order.isWhite) {

                    priceBefore = eventDetail.whitePriceBefore;

                    priceAfter = eventDetail.whitePriceAfter;

                } else {

                    priceBefore = eventDetail.blackPriceBefore;

                    priceAfter = eventDetail.blackPriceAfter;

                }



                withdrawAmount = order.amount.sub(

                    wmul(order.amount, _predictionPool.FEE())

                );

                withdrawAmount = wdiv(withdrawAmount, priceBefore);

                withdrawAmount = wmul(withdrawAmount, priceAfter);

                withdrawAmount = withdrawAmount.sub(

                    wmul(withdrawAmount, _predictionPool.FEE())

                );

                totalWithdrawAmount = totalWithdrawAmount.add(withdrawAmount);

            }



            // pop IDs of canceled or executed orders from ordersOfUser array

            if (!_orders[_oId].isPending || eventDetail.isExecuted) {

                delete _ordersOfUser[msg.sender][i];

                _ordersOfUser[msg.sender][i] = _ordersOfUser[msg.sender][

                    _ordersOfUser[msg.sender].length - 1

                ];

                _ordersOfUser[msg.sender].pop();



                delete _orders[_oId];

            } else {

                i++;

            }

        }



        if (totalWithdrawAmount > 0) {

            _collateralToken.transfer(msg.sender, totalWithdrawAmount.sub(1));

        }



        emit CollateralWithdrew(totalWithdrawAmount, msg.sender);



        return totalWithdrawAmount;

    }



    function changeContractOwner(address _newOwnerAddress) external onlyOwner {

        require(

            _newOwnerAddress != address(0),

            "NEW OWNER ADDRESS SHOULD NOT BE NULL"

        );

        transferOwnership(_newOwnerAddress);

        emit ContractOwnerChanged(_newOwnerAddress);

    }



    function changeEventContractAddress(address _newEventAddress)

        external

        onlyOwner

    {

        require(

            _newEventAddress != address(0),

            "NEW EVENT ADDRESS SHOULD NOT BE NULL"

        );

        _eventContractAddress = _newEventAddress;

        emit EventContractAddressChanged(_eventContractAddress);

    }



    function emergencyWithdrawCollateral() public onlyOwner {

        uint256 balance = _collateralToken.balanceOf(address(this));

        require(

            _collateralToken.transfer(msg.sender, balance),

            "Unable to transfer"

        );

    }

}