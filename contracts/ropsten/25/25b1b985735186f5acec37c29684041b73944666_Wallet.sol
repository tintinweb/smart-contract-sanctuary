pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address _who) public view returns(uint);
    function transfer(address _to, uint _value) public returns(bool);
    function allowance(address _owner, address _spender) public view returns(uint);
    function approve(address _spender, uint _value) public returns(bool);
    function transferFrom(address _from, address _to, uint _value) public returns(bool);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract Wallet {
    address public admin;
    mapping(address => mapping(address => uint)) balances;
    event Deposited(address indexed _user, address indexed _token, uint _value);
    event Withdrawal(address indexed _user, address indexed _token, uint _value);
    event Sent(address indexed _fromUser, address indexed _toUser, address indexed _token, uint _value);
    constructor() public {
        admin = msg.sender;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function() public payable {
        require(msg.data.length == 0 && msg.value > 0);
        balances[msg.sender][address(0)] += msg.value;
        emit Deposited(msg.sender, address(0), msg.value);
    }
    function delegateApprove(address token, uint value) public returns(bool) {
        require(token != address(0));
        ERC20 a = ERC20(token);
        uint b = a.balanceOf(msg.sender);
        require(value > 0 && value <= b);
        if (!token.delegatecall.gas(250000)(bytes4(keccak256("approve(address,uint256)")),address(this),value)) revert();
        return true;
    }
    function deposit(address token) public returns(bool) {
        require(token != address(0));
        ERC20 a = ERC20(token);
        uint b = a.allowance(msg.sender, address(this));
        require(b > 0);
        require(a.transferFrom(msg.sender, address(this), b));
        balances[msg.sender][token] += b;
        emit Deposited(msg.sender, token, b);
        return true;
    }
    function withdraw(address token, uint value) public returns(bool) {
        require(value > 0 && value <= balances[msg.sender][token]);
        if (token == address(0)) {
            msg.sender.transfer(value);
        } else {
            if (!ERC20(token).transfer(msg.sender, value)) revert();
        }
        balances[msg.sender][token] -= value;
        emit Withdrawal(msg.sender, token, value);
        return true;
    }
    function sendTo(address to, address token, uint value) public returns(bool) {
        require(to != address(0) && address(this) != to);
        require(value > 0 && value <= balances[msg.sender][token]);
        if (balances[to][token] > 0) {
            balances[to][token] += value;
        } else {
            if (token == address(0)) {
                to.transfer(value);
            } else {
                if (!ERC20(token).transfer(to, value)) revert();
            }
        }
        balances[msg.sender][token] -= value;
        emit Sent(msg.sender, to, token, value);
        return true;
    }
    function checkBalance(address who, address token) public view returns(uint) {
        return balances[who][token];
    }
    function changeAdmin(address newAdmin) public onlyAdmin returns(bool) {
        require(newAdmin != address(0) && address(0) != newAdmin);
        admin = newAdmin;
        return true;
    }
}