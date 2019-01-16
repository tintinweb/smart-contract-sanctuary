pragma solidity ^0.4.25;
contract ETHBank {
    address public admin;
    uint public feeDivider;
    uint public userBalances;
    mapping(address => uint) balances;
    event RequestAdded(address indexed user, bytes32 indexed txHash, uint indexed reward);
    event Transaction(address indexed from, address indexed to, uint amount, bool External, uint fee);
    constructor(address _admin, uint _feeDivider) public {
        admin = _admin;
        feeDivider = _feeDivider;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    modifier onlyUser() {
        require(balances[msg.sender] > 0);
        _;
    }
    function setAdmin(address newAdmin) public onlyAdmin returns(bool) {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function setFee(uint _fee) public onlyAdmin returns(bool) {
        require(_fee >= 100 && _fee <= 100000);
        feeDivider = _fee;
        return true;
    }
    function () public payable {
        require(msg.value > 0 && gasleft() >= 50000);
        cashIn();
    }
    function cashIn() public payable returns(bool) {
        require(msg.value > 0);
        balances[msg.sender] = msg.value;
        userBalances += msg.value;
        emit Transaction(msg.sender, address(this), msg.value, true, 0);
        return true;
    }
    function cashOut(uint amount) public onlyUser returns(bool) {
        require(amount > (2 * feeDivider) && amount <= balances[msg.sender]);
        uint pureAmount = amount;
        uint fee;
        if (msg.sender != admin) {
            fee = amount / feeDivider;
            balances[admin] += amount / feeDivider;
            pureAmount -= amount / feeDivider;
        }
        if (!msg.sender.call.gas(50000).value(pureAmount)())
        msg.sender.transfer(pureAmount);
        balances[msg.sender] -= amount;
        userBalances -= pureAmount;
        emit Transaction(address(this), msg.sender, pureAmount, true, fee);
        return true;
    }
    function transfer(address to, uint amount) public onlyUser returns(bool) {
        require(to != address(0) && address(this) != to);
        require(amount > 0 && amount <= balances[msg.sender]);
        balances[to] += amount;
        balances[msg.sender] -= amount;
        emit Transaction(msg.sender, to, amount, false, 0);
        return true;
    }
}