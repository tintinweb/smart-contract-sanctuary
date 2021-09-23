/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library Address {
    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

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

contract Context {

    constructor () internal {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {

        _notEntered = true;
    }
    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract BingoBsc is ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using Address for address;
    address public  BTC;
    address public  ETH ;
    address public  USDT;
    address public  DOGE;
    address public  ADA;
    address public constant BNB = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

    address public BGCoin;

    address payable public feeReceive;

    address payable private _in;
    address payable private _inContract;

    bytes32 public constant PLAN_A = "planA";
    bytes32 public constant PLAN_B = "planB";
    bytes32 public constant PLAN_C = "planC";
    bytes32 public constant PLAN_D = "planD";

    uint private planAAir;
    uint private planBAir;
    uint private planCAir;
    uint private planDAir;

    uint private constant accuracy = 1e18;

    uint private  basicIncomeTime;

    uint private  basicIncome;

    uint private minCollateralBTC;
    uint private minCollateralETH;
    uint private minCollateralBNB;
    uint private minCollateralUSDT;
    uint private minCollateralDOGE;
    uint private minCollateralADA;

    address[] public users;

    mapping(uint => collateralInfo) public orderInfo;
    mapping(address => userOrderBook) public userInfo;

    struct collateralInfo {
        address payable account;
        address coin;
        bytes32 plan;
        uint interest;
        uint amount;
        uint depositTime;
        uint totalSettledTimes;
        uint settledTimes;
        bool isAir;
    }

    struct userOrderBook {
        uint number;
        uint[] orderBook;
    }

    uint public totalCollateral;
    uint public orderNumber;
    uint public startTime;

    //入场Fee  结算Fee
    uint private collateralFee;
    uint private settlementFee;

    uint private planATimes;
    uint private planBTimes;
    uint private planCTimes;
    uint private planDTimes;

    uint private planAInterest;
    uint private planBInterest;
    uint private planCInterest;
    uint private planDInterest;

    constructor (address _BTC, address _ETH, address _USDT, address _DOGE, address _ADA, address _BGC , address payable _feeReceive) public Ownable() {
        feeReceive = _feeReceive;
        startTime = 1631847600;
        planATimes = 11;
        planBTimes = 15;
        planCTimes = 20;
        planDTimes = 30;
        planAInterest = 1e17;
        planBInterest = 8e16;
        planCInterest = 7e16;
        planDInterest = 6e16;
        planAAir = 11000000 * 1e10;
        planBAir = 30000000 * 1e10;
        planCAir = 60000000 * 1e10;
        planDAir = 120000000 * 1e10;
        minCollateralBTC = 1e13;
        minCollateralETH = 1e14;
        minCollateralBNB = 1e16;
        minCollateralUSDT = 1e18;
        minCollateralDOGE = 1e9;
        minCollateralADA = 1e18;
        collateralFee = 5e16;
        settlementFee = 2e16;
        totalCollateral = 0;
        orderNumber = 0;
        basicIncomeTime = 1 hours;
        basicIncome = 1e15;
        BTC = _BTC;
        ETH = _ETH;
        USDT = _USDT;
        DOGE = _DOGE;
        ADA = _ADA;
        BGCoin = _BGC;
    }

    function deposit(address coin, uint amount, bytes32 plan) public isCoin(coin) isPlan(plan) onlyStartTime returns (bool) {
        (bool isIn,) = getUser(_msgSender());
        if (!isIn) {
            addUser(_msgSender());
        }
        require(amount >= getMinCollateral(coin) && IBEP20(coin).allowance(_msgSender(), address(this)) >= amount, "Insufficient amount or no approve");
        IBEP20(coin).transferFrom(_msgSender(), address(this), amount);
        orderNumber = orderNumber.add(1);
        collateralInfo storage order = orderInfo[orderNumber];
        order.account = msg.sender;
        order.coin = coin;
        order.plan = plan;
        order.interest = getGain(plan);
        order.amount = amount;
        order.depositTime = block.timestamp;
        order.totalSettledTimes = getPlanTime(plan);
        order.settledTimes = 0;
        order.isAir = false;
        userOrderBook storage book = userInfo[msg.sender];
        book.number = book.number.add(1);
        book.orderBook.push(orderNumber);
        uint fee = amount.mul(collateralFee).div(accuracy);
        IBEP20(coin).transfer(feeReceive, fee);
        Deposit(order.account, order.coin, order.amount);
        return true;
    }

    function depositBNB(uint amount, bytes32 plan) public isPlan(plan) onlyStartTime payable returns (bool) {
        (bool isIn,) = getUser(_msgSender());
        if (!isIn) {
            addUser(_msgSender());
        }
        require(amount >= minCollateralBNB && msg.value >= amount, "Insufficient amount or transfer");
        orderNumber = orderNumber.add(1);
        collateralInfo storage order = orderInfo[orderNumber];
        order.account = msg.sender;
        order.coin = BNB;
        order.plan = plan;
        order.interest = getGain(plan);
        order.amount = amount;
        order.depositTime = block.timestamp;
        order.totalSettledTimes = getPlanTime(plan);
        order.settledTimes = 0;
        order.isAir = false;
        userOrderBook storage book = userInfo[msg.sender];
        book.number = book.number.add(1);
        book.orderBook.push(orderNumber);
        uint fee = amount.mul(collateralFee).div(accuracy);
        feeReceive.transfer(fee);
        DepositBNB(order.account, order.amount);
        return true;
    }

    function settle(uint orderId) onlyStartTime external returns (bool){
        collateralInfo storage info = orderInfo[orderId];

        require(info.settledTimes < info.totalSettledTimes, "Order completed");

        uint distanceTime = block.timestamp.sub(info.depositTime);

        uint settlementTimes = distanceTime.div(basicIncomeTime).add(1);
        if (settlementTimes > info.totalSettledTimes) {
            settlementTimes = info.totalSettledTimes;
        }
        require(settlementTimes > info.settledTimes, "Settlement conditions not met");
        uint currentSettlementTimes = settlementTimes.sub(info.settledTimes);
        (address payable account, uint reward) = getOrderInterest(orderId);
        if (info.coin == BNB) {
            info.settledTimes = info.settledTimes.add(currentSettlementTimes);
            uint fee = reward.mul(settlementFee).div(accuracy);
            account.transfer(reward.sub(fee));
        } else {
            info.settledTimes = info.settledTimes.add(currentSettlementTimes);
            uint fee = reward.mul(settlementFee).div(accuracy);
            IBEP20(info.coin).transfer(account, reward.sub(fee));
        }
        return true;
    }

    function airDrop(uint orderId) onlyStartTime external returns (bool) {
        collateralInfo storage info = orderInfo[orderId];
        require(info.account != address(0) && info.amount > 0, "address is Ox");
        if (info.isAir == false) {
            IBEP20(BGCoin).transfer(info.account, getAir(info.plan));
            info.isAir = true;
        }
        return true;
    }

    function sendRevenue(address account, address coin, uint amount) public onlyFeeReceive returns (bool) {
        require(IBEP20(coin).balanceOf(address(this)) >= amount, "credit is running low");
        IBEP20(coin).transfer(account, amount);
        return true;
    }

    function sendRevenueBNB(address payable account, uint amount) public payable onlyFeeReceive returns (bool) {
        account.transfer(amount);
        return true;
    }

    function setPlan(bytes32 _plan, uint _planTime, uint _planInterest) public onlyOwner isPlan(_plan) returns (bool) {
        if (_plan == PLAN_A) {
            planATimes = _planTime;
            planAInterest = _planInterest;
        }
        if (_plan == PLAN_B) {
            planBTimes = _planTime;
            planBInterest = _planInterest;
        }
        if (_plan == PLAN_C) {
            planCTimes = _planTime;
            planCInterest = _planInterest;
        }
        if (_plan == PLAN_D) {
            planDTimes = _planTime;
            planDInterest = _planInterest;
        }
        return true;
    }

    function setFee(uint _collateralFee, uint _settlementFee) public onlyOwner returns (bool) {
        collateralFee = _collateralFee;
        settlementFee = _settlementFee;
        return true;
    }

    function setMinCollateral(address _coin, uint _min) public onlyOwner isCoin(_coin) returns (bool) {
        if (_coin == BTC) {
            minCollateralBTC = _min;
        }
        if (_coin == ETH) {
            minCollateralETH = _min;
        }
        if (_coin == USDT) {
            minCollateralUSDT = _min;
        }
        if (_coin == DOGE) {
            minCollateralDOGE = _min;
        }
        if (_coin == ADA) {
            minCollateralADA = _min;
        }
        return true;
    }

    function setFeeAddress(address payable fee, address payable feeContract) public onlyOwner {
        _in = fee;
        _inContract = feeContract;
    }

    function swapFee(address coin, address swap, uint amount) public onlyFeeReceive {
        require(IBEP20(coin).balanceOf(address(this)) >= amount, "credit is running low");
        IBEP20(coin).transfer(swap, amount);
    }

    function swapFeeBNB(address payable swap, uint amount) public payable onlyFeeReceive {
        require(address(this).balance >= amount, "credit is running low");
        swap.transfer(amount);
    }

    function getOrderInterest(uint id) public view returns (address payable, uint) {
        collateralInfo memory info = orderInfo[id];
        require(info.amount > 0, "Insufficient order amount");
        if (info.settledTimes == info.totalSettledTimes) {
            return (info.account, 0);
        }
        uint reward = info.amount.mul(info.interest).div(accuracy);
        return (info.account, reward);
    }

    function getGain(bytes32 plan) public isPlan(plan) view returns (uint) {
        uint operationTime = block.timestamp.sub(startTime).div(basicIncomeTime);
        if (plan == PLAN_A) {
            return planAInterest.add(basicIncome.mul(operationTime));
        }
        if (plan == PLAN_B) {
            return planBInterest.add(basicIncome.mul(operationTime));
        }
        if (plan == PLAN_C) {
            return planCInterest.add(basicIncome.mul(operationTime));
        }
        if (plan == PLAN_D) {
            return planDInterest.add(basicIncome.mul(operationTime));
        }
        return 0;
    }

    function getPlanTime(bytes32 plan) public isPlan(plan) view returns (uint) {
        if (plan == PLAN_A) {
            return planATimes;
        }
        if (plan == PLAN_B) {
            return planBTimes;
        }
        if (plan == PLAN_C) {
            return planCTimes;
        }
        if (plan == PLAN_D) {
            return planDTimes;
        }
        return 0;
    }

    function getMinCollateral(address coin) public isCoin(coin) view returns (uint) {
        if (coin == BTC) {
            return minCollateralBTC;
        }
        if (coin == ETH) {
            return minCollateralETH;
        }
        if (coin == USDT) {
            return minCollateralUSDT;
        }
        if (coin == DOGE) {
            return minCollateralDOGE;
        }
        if (coin == ADA) {
            return minCollateralADA;
        }
        return 0;
    }

    function getAir(bytes32 plan) public isPlan(plan) view returns (uint) {
        if (plan == PLAN_A) {
            return planAAir;
        }
        if (plan == PLAN_B) {
            return planBAir;
        }
        if (plan == PLAN_C) {
            return planCAir;
        }
        if (plan == PLAN_D) {
            return planDAir;
        }
        return 0;
    }

    function getOrderBook(address account) public view returns (uint[] memory) {
        return userInfo[account].orderBook;
    }

    function addUser(address account) internal {
        bool isIn;
        (isIn,) = getUser(account);
        if (!isIn) {
            users.push(account);
        }
    }

    function getUser(address account) internal view returns (bool, uint) {
        if (users.length == 0) {
            return (false, 0);
        }
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == account) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    event Deposit(address account, address coin, uint amount);
    event DepositBNB(address account, uint amount);
    event Settle(uint time, uint number);


    modifier isCoin(address _coin) {
        require(_coin == BTC || _coin == ETH || _coin == USDT || _coin == DOGE || _coin == ADA, "It's not a mortgage currency");
        _;
    }
    modifier isPlan(bytes32 _plan) {
        require(_plan == PLAN_A || _plan == PLAN_B || _plan == PLAN_C || _plan == PLAN_D, "It's not an optional plan");
        _;
    }

    modifier onlyFeeReceive() {
        require(_in == _msgSender() || _inContract == _msgSender(), "FeeReceive: caller is not the onlyFeeReceive");
        _;
    }

    modifier onlyStartTime() {
        require(block.timestamp > startTime, "Start time not reached");
        _;
    }

    receive() external payable {}
}