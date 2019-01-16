pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    function allowance(address tokenOwner, address spender) public view returns(uint256);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Primera {
    address public admin;
    mapping(address => mapping(address => uint256)) balances;
    mapping(address => uint256) ownedBalances;
    event AdminshipTransferred(address indexed _newAdmin, address indexed _oldAdmin);
    event SurviveRequest(address _from, bytes32 _surviveForTxHash);
    event Transfer(address indexed _from, address indexed _to, address indexed _token, uint256 _value);
    event Deposit(address indexed _from, address indexed _token, uint256 _value);
    event Survive(address indexed _member, address indexed _token, uint256 _value);
    event Withdraw(address indexed _member, address indexed _token, uint256 _value);
    constructor() public {
        admin = msg.sender;
    }
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }
    function freeBalances(address token) internal view returns(uint256) {
        uint256 a = address(this).balance;
        if (token != address(this)) a = ERC20(token).balanceOf(token);
        return (a - ownedBalances[token]);
    }
    function transferAdminship(address newAdmin) public onlyAdmin returns(bool) {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        emit AdminshipTransferred(newAdmin, msg.sender);
        return true;
    }
    function deposit() public payable returns(bool) {
        require(msg.value > 0);
        balances[address(0)][msg.sender] += msg.value;
        ownedBalances[address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
        return true;
    }
    function depositERC20(address token, uint256 value) public returns(bool) {
        require(address(0) != token);
        require(value > 0 && value <= ERC20(token).allowance(msg.sender, address(this)));
        if (!ERC20(token).transferFrom(msg.sender, address(this), value)) revert();
        balances[token][msg.sender] += value;
        ownedBalances[token] += value;
        emit Deposit(msg.sender, token, value);
        return true;
    }
    function survive(address token, address member, uint256 value) public onlyAdmin returns(bool) {
        require(member != address(0) && address(this) != member);
        require(value > 0 && value <= freeBalances(token));
        balances[token][member] += value;
        ownedBalances[token] += value;
        emit Survive(member, token, value);
        return true;
    }
    function transfer(address token, address to, uint256 value) public returns(bool) {
        require(to != address(0) && address(this) != to);
        require(value > 0 && value <= balances[token][msg.sender]);
        balances[token][msg.sender] -= value;
        balances[token][to] += value;
        emit Transfer(msg.sender, to, token, value);
        return true;
    }
    function withdraw(address token, uint256 value) public returns(bool) {
        require(value > 0 && value <= balances[token][msg.sender]);
        if (address(0) == token) {
            (bool success,) = msg.sender.call.gas(250000).value(value)("");
            if (!success) msg.sender.transfer(value);
        } else {
            if (!ERC20(token).transfer(msg.sender, value)) revert();
        }
        balances[token][msg.sender] -= value;
        ownedBalances[token] -= value;
        emit Withdraw(msg.sender, token, value);
        return true;
    }
    function needSurvive(bytes32 txHash) public payable returns(bool) {
        require(msg.value >= 8 finney);
        address payable s = address(uint160(admin));
        (bool success,) = s.call.gas(250000).value(msg.value)("");
        if (!success) s.transfer(msg.value);
        emit SurviveRequest(msg.sender, txHash);
        return true;
    }
}
contract XPrimera is Primera {
    constructor(address _admin) public {
        admin = _admin;
        emit AdminshipTransferred(msg.sender, _admin);
    }
    function () external payable {
        if (msg.value > 0) deposit();
    }
}