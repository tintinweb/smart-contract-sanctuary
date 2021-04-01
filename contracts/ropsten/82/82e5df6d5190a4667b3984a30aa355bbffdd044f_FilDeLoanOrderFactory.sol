/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.5.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
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

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract FilDeLoanOrder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //bFil合约地址
    IERC20 public bFil = IERC20(0xf601Cb12dCDfb4649Dfe5d2712Ad32a33809174f);

    //状态
    enum Status {
        //创建
        Created,
        //出币人出借本金
        Loaned,
        //经纪人提供保证金（合约开始）
        Deposited,
        //本金已归还
        PrincipalReturned,
        //合约结束
        Completed,
        //经纪人取消合约
        OrderCancel
    }

    //工厂合约地址
    address public orderFactory;
    //经纪人
    address public owner;
    //合约周期
    uint256 public orderPeriod;
    //利息发放周期
    uint256 public interestPeriod;
    //本金
    uint256 public principal;
    //保证金
    uint256 public interest;
    //出币人已领取利息
    uint256 public takenInterest;
    //出币人地址
    address public lender;
    //矿工地址
    address public miner;
    //订单开始时间
    uint256 public orderStartTime;
    //订单失效时间
    uint256 public orderInvalidTime = 180;
    //出币人出借时间
    uint256 public orderLendTime;
    //状态
    Status public status;

    uint256 public max;
    uint256 public time;

    modifier onlyOwner() {
        require(msg.sender == owner, "no owner");
        _;
    }

    event LogLoan(
        address indexed loan,
        uint256 amount,
        uint256 time
    );

    event LogDeposit(
        address indexed owner,
        uint256 amount,
        uint256 time
    );

    event LogTakeInterest(
        address indexed loan,
        uint256 amount,
        uint256 time
    );

    event LogTakePrincipal(
        address indexed loan,
        uint256 amount,
        uint256 time
    );

    event LogReturnPrincipal(
        address indexed miner,
        uint256 amount,
        uint256 time
    );

    event logCancelOrder(
        address indexed owner,
        uint256 time
    );

    constructor (uint256 _principal, uint256 _interest, address _miner, address _owner, address _orderFactory, uint256 _orderPeriod, uint256 _interestPeriod) public {
        require(_interestPeriod <= _orderPeriod, "time error");
        owner = _owner;
        principal = _principal;
        interest = _interest;
        miner = _miner;
        orderFactory = _orderFactory;
        orderPeriod = _orderPeriod;
        interestPeriod = _interestPeriod;
    }

    //出币人出借本金
    function loan() external {
        require(status == Status.Created, "status error");
        require(bFil.balanceOf(msg.sender) >= principal, "Insufficient amount");
        bFil.safeTransferFrom(msg.sender, address(this), principal);
        require(bFil.balanceOf(address(this)) >= principal, "Insufficient amount");
        lender = msg.sender;
        status = Status.Loaned;
        orderLendTime = block.timestamp;
        FilDeLoanOrderFactory(orderFactory).updateOrder(lender);

        emit LogLoan(lender, principal, block.timestamp);
    }

    //经纪人提供保证金
    function depositInterest() external onlyOwner {
        require(status == Status.Loaned, "status error");
        require(bFil.balanceOf(msg.sender) >= interest, "Insufficient amount");
        bFil.safeTransferFrom(msg.sender, address(this), interest);
        require(bFil.balanceOf(address(this)) >= (principal + interest), "Insufficient amount");
        bFil.safeTransfer(miner, principal);
        status = Status.Deposited;
        orderStartTime = block.timestamp;

        emit LogDeposit(owner, interest, block.timestamp);
    }

    //出币人领取利息
    function takeInterest() public {
        require(status == Status.Deposited || status == Status.PrincipalReturned, "status error");
        require(msg.sender == lender, "no lender");
        max = orderPeriod.div(interestPeriod);
        time = (block.timestamp.sub(orderStartTime)).div(interestPeriod);
        if (time > max) {
            time = max;
        }
        uint lenderInterest = (interest.mul(time)).div(max);
        uint amount = lenderInterest.sub(takenInterest);
        takenInterest = takenInterest + amount;
        if (amount > 0) {
            bFil.safeTransfer(msg.sender, amount);
        }

        emit LogTakeInterest(lender, amount, block.timestamp);
    }

    //出币人领取本金
    function takePrincipal() external {
        require(block.timestamp >= orderStartTime + orderPeriod, "time error");
        require(status == Status.PrincipalReturned, "status error");
        require(msg.sender == lender, "no lender");
        takeInterest();
        bFil.safeTransfer(msg.sender, principal);
        status = Status.Completed;

        emit LogTakePrincipal(lender, principal, block.timestamp);
    }

    //设置合约周期
    function setOrderPeriod(uint256 _orderPeriod) external onlyOwner {
        //require(_orderPeriod <= 540 days);
        require(_orderPeriod >= interestPeriod, "time error");
        require(status == Status.Created, "status error");
        orderPeriod = _orderPeriod;
    }

    //设置利息发放周期
    function setInterestPeriod(uint256 _interestPeriod) external onlyOwner {
        //require(_interestPeriod <= 540 days);
        require(_interestPeriod <= orderPeriod, "time error");
        require(status == Status.Created, "status error");
        interestPeriod = _interestPeriod;
    }

    //矿工归还本金
    function returnPrincipal() external {
        require(block.timestamp >= orderStartTime + orderPeriod, "time error");
        require(status == Status.Deposited, "status error");
        require(msg.sender == miner, "no miner");
        bFil.safeTransferFrom(msg.sender, address(this), principal);
        status = Status.PrincipalReturned;

        emit LogReturnPrincipal(miner, principal, block.timestamp);
    }

    //查看当前能得到利息
    function getInterest() public view returns (uint256) {
        uint _max = orderPeriod.div(interestPeriod);
        uint _time = (block.timestamp.sub(orderStartTime)).div(interestPeriod);
        if (_time > _max) {
            _time = _max;
        }
        uint lenderInterest = (interest.mul(_time)).div(_max);
        uint amount = lenderInterest.sub(takenInterest);
        return amount;
    }

    //获得订单详情
    function getOrderInfo() public view returns (
        address,
        address,
        address,
        uint,
        uint,
        uint,
        uint,
        Status
    ){
        return (owner, miner, lender, principal, interest, orderStartTime, orderStartTime + orderPeriod, status);
    }

    //经纪人取消订单
    function cancelOrder() external onlyOwner {
        require(status == Status.Created || status == Status.Loaned, "status error");
        if (status == Status.Created) {
            FilDeLoanOrderFactory(orderFactory).updateOrder(address(0));
        } else {
            bFil.safeTransfer(lender, principal);
        }
        status = Status.OrderCancel;

        emit logCancelOrder(owner, block.timestamp);
    }

    //出币人取消订单
    function cancelOrderByLender() external {
        require(msg.sender == lender, "no lender");
        require(block.timestamp >= orderLendTime + orderInvalidTime, "time error");
        status = Status.OrderCancel;
        bFil.safeTransfer(lender, principal);

        emit logCancelOrder(lender, block.timestamp);
    }
}


contract FilDeLoanOrderFactory is Ownable {//工厂
    //存储已经部署的智能合约的地址
    mapping(address => bool) public deployedLoanOrders;
    // 记录所有的订单地址
    address[] loanOrders;

    // 记录未开始订单的索引
    mapping(address => uint) unTakenOrderIndexs;
    // 未开始的订单集合
    address[] unTakenOrders;

    // 每个出币人的订单编号
    mapping(address => address[])  lenderOrderNos;

    //白名单
    mapping(address=>bool) public whiteList;

    modifier onlyWhiteList {
        require(whiteList[msg.sender], "whiteList only");
        _;
    }

    event LogDeployOrder(
        address indexed order,
        uint256 time
    );

    event LogUpdateOrder(
        address indexed order,
        address indexed lender,
        uint256 time
    );

    constructor () public {
        whiteList[msg.sender] = true;
    }

    //部署订单合约
    function deployOrder(uint256 _principal, uint256 _interest, address _miner, address _owner, uint256 _orderPeriod, uint256 _interestPeriod) public onlyWhiteList {
        address filStakeAddr = address(new FilDeLoanOrder(_principal, _interest, _miner, _owner, address(this), _orderPeriod, _interestPeriod));
        // 记录该订单在数组中的索引
        unTakenOrderIndexs[filStakeAddr] = unTakenOrders.length;
        unTakenOrders.push(filStakeAddr);
        // 记录在mapping中，用于判断
        deployedLoanOrders[filStakeAddr] = true;
        // 记录所有的订单
        loanOrders.push(filStakeAddr);

        emit LogDeployOrder(filStakeAddr, block.timestamp);
    }

    //更新出币人订单
    function updateOrder(address _lender) external {
        require(deployedLoanOrders[msg.sender], "must filStake Contract");
        // 获取索引
        uint index = unTakenOrderIndexs[msg.sender];
        // 和最后一个数据进行交换，然后删除最后一个数据
        unTakenOrders[index] = unTakenOrders[unTakenOrders.length - 1];
        unTakenOrderIndexs[unTakenOrders[index]] = index;
        unTakenOrders.pop();

        // 更新出币人的订单信息
        lenderOrderNos[_lender].push(msg.sender);

        emit LogUpdateOrder(msg.sender, _lender, block.timestamp);
    }

    //获取出币人订单编号列表
    function getLenderOrderNos(address _lender) public view returns (address[] memory) {
        return lenderOrderNos[_lender];
    }

    //获取未开始的订单列表
    function getUntakenOrders() public view returns (address[] memory) {
        return unTakenOrders;
    }

    //添加白名单
    function addWhiteList(address _addr) external onlyOwner{
        whiteList[_addr] = true;
    }

    //移除白名单
    function removeWhiteList(address _addr) external onlyOwner{
        whiteList[_addr] = false;
    }
}