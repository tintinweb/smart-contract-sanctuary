//SourceUnit: capacitor.sol

pragma solidity ^0.5.4;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
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

contract capacitor is Ownable{
    using SafeMath for uint256;

    struct user{
        bool allowed;
        uint256 totalCharge;
        uint256 totalDecharge;
        uint256 amount;
        uint256 moneyRequest;
    }

    mapping  (address => user) users;

    event SetPrivilege(address indexed addr);
    event Charge(address indexed addr, uint256 amount);
    event DechargeRequest(address indexed addr, uint256 amount);
    event ChargeFromOutside(address indexed sender ,address indexed reciever, uint256 amount);
    event DechargeFromOutside(address indexed reciever, uint256 amount);
    event Withdrawn(address indexed user ,address indexed reciever ,uint256 amount);

    modifier onlyAllowed() {
        require(users[msg.sender].allowed ,"You are not allowed to use capacitor!");
        _;
    }    

    function givePrivilege(address addr) public onlyOwner{
        users[addr].allowed = true;
        emit SetPrivilege(addr);
    }

    function deletePrivilege(address addr) public onlyOwner{
        users[addr].allowed = false;
    }

    function decharge(uint256 money) public onlyAllowed returns(uint256) {//in SUN not TRX 
        emit DechargeRequest(msg.sender, money);
        users[msg.sender].moneyRequest = users[msg.sender].moneyRequest.add(money);
        return 0;
    }

    function charge() public payable onlyAllowed{
        users[msg.sender].amount = users[msg.sender].amount.add(msg.value);
        users[msg.sender].totalCharge = users[msg.sender].totalCharge.add(msg.value);
        emit Charge(msg.sender, msg.value);
    }

    function getUserStat(address addr) public view onlyOwner returns (uint256,uint256,uint256,uint256) {
        return (users[addr].amount, users[addr].moneyRequest, users[addr].totalCharge ,users[addr].totalDecharge);
    }

    function withdraw(address addr, address payable reciever, uint256 money) public onlyOwner{
        require(users[addr].allowed ,"user is not allowed to use capacitor!");

        if(users[addr].amount < money){
            money = users[addr].amount;
        }
        users[addr].moneyRequest = 0;
        if(money > 0){
            reciever.transfer(money);
            users[addr].totalDecharge = users[addr].totalDecharge.add(money);
            users[addr].amount = users[addr].amount.sub(money);
            emit Withdrawn(addr, reciever, money);
        }
    }

    function chargeOuter(address payable reciever) public payable {
        require(users[reciever].allowed ,"Your reciecer is not allowed to use capacitor!");
        users[reciever].totalCharge = users[reciever].totalCharge.add(msg.value);
        users[reciever].amount = users[reciever].amount.add(msg.value);
        emit ChargeFromOutside(msg.sender, reciever, msg.value);
    }
}