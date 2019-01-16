pragma solidity ^0.5.2;
contract ERC20 {
    function totalSupply() public view returns(uint);
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    function transferFrom(address from, address to, uint value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint indexed value);
}
contract ERC223 {
    function transfer(address to, uint value, bytes memory extraData) public returns(bool);
}
contract Bank {
    address public admin;
    bytes32 public BankID;
    address[] listed;
    mapping(address => mapping(address => uint)) balances;
    mapping(address => uint) totalBalances;
    event AdminshipTransferred(address indexed newAdmin, address indexed prevAdmin);
    event Deposit(address indexed member, address indexed token, uint value);
    event Withdraw(address indexed member, address indexed token, uint value);
    event Sent(address indexed from, address indexed to, address indexed token, uint value);
    event Donation(address indexed from, address indexed token, uint value);
    event Collected(address indexed collector, address indexed token, uint value);
    event TokenListed(address indexed token, uint blockNumber);
    event TokenRemoved(address indexed token, uint blockNumber);
    constructor() public {
        admin = msg.sender;
        BankID = keccak256(abi.encodeWithSignature("constructor(uint256,address,address,address,uint256)", now, msg.sender, address(0), address(this), block.number));
        listed.push(address(0));
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function transferAdminship(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0) && newAdmin != address(this));
        admin = newAdmin;
        emit AdminshipTransferred(newAdmin, msg.sender);
    }
    function isListed(ERC20 token) internal view returns(bool) {
        uint i;
        bool exists;
        while (i < listed.length) {
            if (listed[i] == address(token)) {
                break;
                exists = true;
            }
            i++;
        }
        return exists;
    }
    function addToken(ERC20 token) public onlyAdmin {
        require(token.totalSupply() > 0);
        if (isListed(token)) revert();
        listed.push(address(token));
        emit TokenListed(address(token), block.number);
    }
    function removeToken(ERC20 token) public onlyAdmin {
        require(isListed(token) && address(token) != address(0));
        uint i;
        while (i < listed.length) {
            if (address(token) == listed[i]) {
                break;
                delete(listed[i]);
            }
            i++;
        }
        emit TokenRemoved(address(token), block.number);
    }
    function deposit() public payable {
        if (msg.value < 1) revert();
        balances[address(0)][msg.sender] += msg.value;
        totalBalances[address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
    }
    function depositToken(ERC20 token, uint value) public {
        require(isListed(token));
        require(value > 0 && token.transferFrom(msg.sender, address(this), value));
        balances[address(token)][msg.sender] += value;
        totalBalances[address(token)] += value;
        emit Deposit(msg.sender, address(token), value);
    }
    function withdraw(uint value) public {
        require(value > 0 && value <= balances[address(0)][msg.sender]);
        msg.sender.transfer(value);
        balances[address(0)][msg.sender] -= value;
        totalBalances[address(0)] -= value;
        emit Withdraw(msg.sender, address(0), value);
    }
    function withdrawToken(ERC20 token, uint value) public {
        require(value > 0 && value <= balances[address(token)][msg.sender]);
        if (!token.transfer(msg.sender, value)) revert();
        balances[address(token)][msg.sender] -= value;
        totalBalances[address(token)] -= value;
        emit Withdraw(msg.sender, address(token), value);
    }
    function transfer(ERC20 token, address to, uint value) public {
        require(to != address(0) && address(this) != to);
        require(value > 0 && value <= balances[address(token)][msg.sender]);
        balances[address(token)][to] += value;
        balances[address(token)][msg.sender] -= value;
        emit Sent(msg.sender, to, address(token), value);
    }
    function collectUncapped(ERC20 token) public onlyAdmin {
        uint subValue = totalBalances[address(token)];
        uint value = token.balanceOf(address(this)) - subValue;
        balances[address(token)][msg.sender] += value;
        totalBalances[address(token)] += value;
        emit Collected(msg.sender, address(token), value);
    }
    function () external payable {
        if (msg.value > 0) donation();
    }
    function donation() public payable {
        require(msg.value > 0);
        emit Donation(msg.sender, address(0), msg.value);
    }
    function tokenFallback(address from, uint value, bytes memory extraData) public {
        bytes memory _extraData;
        ERC20 _token;
        _token = ERC20(msg.sender);
        _extraData = extraData;
        require(_token.totalSupply() > 0);
        emit Donation(from, msg.sender, value);
    }
}