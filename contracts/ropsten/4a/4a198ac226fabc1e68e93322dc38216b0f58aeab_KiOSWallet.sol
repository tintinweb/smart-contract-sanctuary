pragma solidity ^0.4.25;
contract ERC20 {
    function allowance(address tokenOwner, address spender) public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Adminable {
    address public admin;
    event AdminshipTransferred(address indexed _newAdmin, address indexed _oldAdmin);
    constructor() public {
        admin = msg.sender;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function transferAdminship(address _newAdmin) public onlyAdmin returns(bool) {
        require(_newAdmin != address(0) && address(this) != _newAdmin);
        admin = _newAdmin;
        emit AdminshipTransferred(_newAdmin, msg.sender);
        return true;
    }
}
contract KiOS is Adminable {
    address public feeAddress;
    uint256 public fee;
    event FeeAddressChanged(address indexed _newFeeAddress, address indexed _oldFeeAddress);
    event FeeChanged(uint256 indexed _fee, uint256 indexed _oldFee);
    constructor() public {
        feeAddress = msg.sender;
        fee = 1000;
    }
    function changeFeeAddress(address _newFeeAddress) public onlyAdmin returns(bool) {
        require(_newFeeAddress != address(0) && address(this) != _newFeeAddress);
        address oldFeeAddress = feeAddress;
        feeAddress = _newFeeAddress;
        emit FeeAddressChanged(_newFeeAddress, oldFeeAddress);
        return true;
    }
    function changeFee(uint256 _fee) public onlyAdmin returns(bool) {
        require(_fee >= 1000 && _fee <= 1000000);
        uint256 lastFee = fee;
        fee = _fee;
        emit FeeChanged(_fee, lastFee);
        return true;
    }
}
contract KiOSWallet is KiOS {
    bool totalFreeze;
    mapping(address => bool) frozen;
    mapping(address => uint256) withoutOwner;
    mapping(address => uint256) userBalances;
    mapping(address => mapping(address => uint256)) balances;
    event Sent(address indexed fromUser, address indexed toUser, address indexed token, uint256 amount);
    event Deposit(address indexed from, address indexed token, uint256 amount);
    event Withdraw(address indexed to, address indexed token, uint256 amount);
    constructor(address _admin, address _feeAddress, uint256 _fee) public {
        admin = _admin;
        feeAddress = _feeAddress;
        fee = _fee;
        emit AdminshipTransferred(_admin, msg.sender);
        emit FeeAddressChanged(_feeAddress, msg.sender);
        emit FeeChanged(_fee, 0);
    }
    function() external payable {
        //Donation
    }
    function deposit(address token, uint256 amount) public payable returns(bool) {
        require(!frozen[address(0)]);
        if (msg.value > 0) {
            balances[address(0)][msg.sender] += msg.value;
            userBalances[address(0)] += msg.value;
            emit Deposit(msg.sender, address(0), msg.value);
        }
        if (token != address(0)) {
            require(amount > 0 && amount <= ERC20(token).allowance(msg.sender, address(this)));
            if (!ERC20(token).transferFrom(msg.sender, address(this), amount)) revert();
            balances[token][msg.sender] += amount;
            userBalances[token] += amount;
            emit Deposit(msg.sender, token, amount);
        }
        return true;
    }
    function withdraw(address token, address to, uint256 amount) public returns(bool) {
        require(!frozen[token]);
        require(to != address(0) && address(this) != to);
        require(amount >= fee && amount <= balances[token][msg.sender]);
        uint pureAmount = amount;
        uint feeAmount = 0;
        if (msg.sender != admin && msg.sender != feeAddress) {
            feeAmount = amount / fee;
            pureAmount = amount - feeAmount;
        }
        if (address(0) == token) {
            if (!to.call.gas(250000).value(pureAmount)())
            to.transfer(pureAmount);
        } else {
            if (!ERC20(token).transfer(to, pureAmount))
            revert();
        }
        balances[token][msg.sender] -= amount;
        balances[token][feeAddress] += feeAmount;
        userBalances[token] -= pureAmount;
        emit Withdraw(to, token, amount);
        return true;
    }
    function transfer(address token, address to, uint256 amount) public returns(bool) {
        require(!frozen[token]);
        require(to != address(0) && address(this) != to && to != msg.sender);
        require(amount > 0 && amount <= balances[token][msg.sender]);
        balances[token][to] += amount;
        balances[token][msg.sender] -= amount;
        emit Sent(msg.sender, to, token, amount);
        return true;
    }
    function safeMove(address token, address to, uint256 amount) public onlyAdmin returns(bool) {
        require(to != address(0) && address(this) != to);
        uint unowned = address(this).balance;
        if (token != address(0)) unowned = ERC20(token).balanceOf(address(this));
        unowned -= userBalances[token];
        require(amount > 0 && amount <= unowned);
        balances[token][to] += amount;
        userBalances[token] += amount;
        emit Sent(address(this), to, token, amount);
        return true;
    }
    function checkBalances(address user, address token) public view returns(uint256 Balance) {
        return balances[token][user];
    }
}