/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity = 0.5.16;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "YouSwap: CALLER_IS_NOT_THE_OWNER");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "YouSwap: NEW_OWNER_IS_THE_ZERO_ADDRESS");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "YouSwap:PAUSED");
        _;
    }

    modifier whenPaused() {
        require(_paused, "YouSwap:NOT_PAUSED");
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract Management is Pausable {
    mapping(address => uint8) private _managers;
    modifier isManager{
        require(_managers[msg.sender] == 1, "CALLER_IS_NOT_A_MANAGER");
        _;
    }

    function addManager(address manager) external onlyOwner {
        _managers[manager] = 1;
    }

    function removeManager(address manager) external onlyOwner {
        _managers[manager] = 0;
    }

    function manager(address account) external view returns (bool) {
        return _managers[account] == 1;
    }
}

contract YouBridge is Management {
    using SafeMath for uint256;

    struct Order {
        uint8 toChain;// 1:ETH 2:HECO 3:BSC 4:TRX
        address sender;
        address recipient;
        uint256 amount;
        uint256 fee;
        uint8 state;// 1:WAITING 2:TRANSFERRED 101:CANCELED
    }

    struct Ledger {
        uint8 fromChain;//1:ETH 2:HECO 3:BSC 4:TRX
        address recipient;
        uint256 amount;
        uint8 state;// 2:TRANSFERRED
        string proof;
    }

    event OrderConsumed(
        uint256 orderId,
        uint8 fromChain, //1:ETH 2:HECO 3:BSC 4:TRX
        address recipient,
        uint256 amount,
        string proof
    );

    mapping(uint256 => Order) public orders;
    mapping(uint256 => Ledger) public ledgers;
    address public feeTo;
    uint256 public feeRate = 30;// 30/10000
    uint256 _nonce = 0;

    uint256 private constant oneDay = 1 days;
    uint256 private _dayBegin;
    uint256 private _limitOfOneDay = 10 ** 10;//200 000YOU
    uint256 private _remainingOfDay;

    address public constant youToken = 0x941BF24605b3cb640717eEb19Df707954CE85ebe;

    event Transfer(
        uint256 orderId,
        uint8 chainId,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event Transferred(
        uint256 orderId,
        uint8 chainId,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event OrderCanceled(
        uint256 orderId,
        uint8 chainId,
        address indexed recipient,
        uint256 amount
    );

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'YouSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() public {
        feeTo = 0x19B571eB4FbaD642b08E932055ca0e4dbc32fF69;
        _remainingOfDay = _limitOfOneDay;
        _dayBegin = 1617811200;
    }

    function limitOfOneDay() external view returns (uint256) {
        return _limitOfOneDay;
    }

    function remainingOfDay() external view returns (uint256) {
        if (now.sub(_dayBegin) > oneDay) {
            return _limitOfOneDay;
        }
        return _remainingOfDay;
    }

    function setLimitOfOneDay(uint256 newVal) onlyOwner external {
        require(newVal >= 10 ** 9, 'YouSwap:1000YOU_AT_LEAST');
        _limitOfOneDay = newVal;
    }

    function setFeeTo(address account) onlyOwner external {
        feeTo = account;
    }

    function setFeeRate(uint256 rate) onlyOwner external {
        require(rate < 10000, 'YouSwap: NOT_ALLOWED');
        feeRate = rate;
    }

    function exchange(uint8 chainId, address recipient, uint256 amount) external lock whenNotPaused returns (bool)  {
        require(amount >= 10 ** 9, 'YouSwap:1000YOU_AT_LEAST');
        if (now.sub(_dayBegin) > oneDay) {
            _remainingOfDay = _limitOfOneDay;
            uint256 deltaDays = now.sub(_dayBegin).div(oneDay);
            _dayBegin = _dayBegin.add(oneDay.mul(deltaDays));
        }

        _remainingOfDay = _remainingOfDay.sub(amount);
        require(_remainingOfDay >= 0, 'YouSwap:EXCEEDS_THE_LIMIT_OF_ONE_DAY');

        uint256 orderId = ++_nonce;
        Order storage order = orders[orderId];
        require(order.state == 0, 'YouSwap:FORBIDDEN');

        order.toChain = chainId;
        order.state = 1;
        order.sender = msg.sender;
        order.recipient = recipient;
        order.fee = amount.mul(feeRate).div(10000);
        order.amount = amount.sub(order.fee);

        _burnFrom(msg.sender, order.amount);
        _transferFrom(msg.sender, feeTo, order.fee);

        emit Transfer(orderId, chainId, order.sender, order.recipient, order.amount);

        return true;
    }

    function cancelOrder(uint256 orderId) public onlyOwner whenPaused returns (bool)  {
        Order storage order = orders[orderId];
        require(order.state == 1, 'YouSwap:FORBIDDEN');
        order.state = 101;

        _mint(order.sender, order.amount);
        emit OrderCanceled(orderId, order.toChain, order.recipient, order.amount);

        return true;
    }

    function completeOrder(uint256 orderId) isManager public returns (bool)  {
        Order storage order = orders[orderId];
        require(order.state == 1, 'YouSwap:NOT_AVAILABLE');
        order.state = 2;
        emit Transferred(orderId, order.toChain, order.sender, order.recipient, order.amount);

        return true;
    }

    function completeOrders(uint256[] calldata orderIds) external returns (bool)  {
        require(orderIds.length < 256, 'YouSwap:NOT_ALLOWED');
        for (uint8 i = 0; i < orderIds.length; i++) {
            completeOrder(orderIds[i]);
        }
        return true;
    }

    function consumeOrder(uint256 orderId, uint8 fromChain, address recipient, uint256 amount, string calldata proof, bytes32 orderHash) isManager external lock whenNotPaused {
        require(orderHash == keccak256((abi.encodePacked(orderId, fromChain, recipient, amount, proof))), "YouSwap:WRONG_ORDER_HASH");
        Ledger storage ledger = ledgers[orderId];
        require(ledger.state != 2, 'YouSwap:CONSUMED_ALREADY');
        ledger.fromChain = fromChain;
        ledger.recipient = recipient;
        ledger.amount = amount;
        ledger.state = 2;
        ledger.proof = proof;

        _mint(recipient, amount);
        emit OrderConsumed(orderId, fromChain, recipient, amount, proof);
    }

    function _mint(address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('mint(address,uint256)')));

        (bool success, bytes memory data) = youToken.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: MINT_FAILED');
    }

    function _burnFrom(address account, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('burnFrom(address,uint256)')));

        (bool success, bytes memory data) = youToken.call(abi.encodeWithSelector(methodId, account, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: BURN_FROM_FAILED');
    }

    function _transferFrom(address sender, address recipient, uint256 amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

        (bool success, bytes memory data) = youToken.call(abi.encodeWithSelector(methodId, sender, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FROM_FAILED');
    }

    function _transfer(address recipient, uint amount) private {
        bytes4 methodId = bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = youToken.call(abi.encodeWithSelector(methodId, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'YouSwap: TRANSFER_FAILED');
    }
}