pragma solidity = 0.5.16;
import "./SafeMath.sol";
import "./Pausable.sol";
contract Management is Pausable {
    mapping(address => uint8) private _managers;
    
    constructor() internal {
        _managers[0x90aB684F940F2eda414e79A853901d4018c34420] = 1;
    }
    
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
    uint256 private _limitOfOneDay = 10 ** 12;
    uint256 private _remainingOfDay;

    address public constant youToken = 0x1d32916CFA6534D261AD53E2498AB95505bd2510;

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
        _dayBegin = 1617984000;
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
        require(newVal >= _limitOfOneDay.sub(_remainingOfDay), 'YouSwap:NOT_ALLOWED');
        if(newVal > _limitOfOneDay){
            _remainingOfDay = _remainingOfDay.add(newVal.sub(_limitOfOneDay));
        }
        else{
            _remainingOfDay = newVal.sub(_limitOfOneDay.sub(_remainingOfDay));
        }
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
        require(amount < _limitOfOneDay, 'YouSwap:FORBIDDEN');//IGNORE FEE
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