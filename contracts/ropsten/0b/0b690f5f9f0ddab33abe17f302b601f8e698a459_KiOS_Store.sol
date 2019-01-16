pragma solidity ^0.4.25;
interface ERC20 {
    function allowance(address _owner, address _spender) external view returns(uint);
    function transferFrom(address _from, address _to, uint _value) external view returns(bool);
}
contract KiOS_Store {
    address public admin;
    uint public feeDivider;
    uint public minETH;
    mapping(address => mapping(address => queueInfo)) queue;
    event Sold(address indexed _token, address indexed _buyer, address indexed _seller, uint _amountETH, uint _amountToken, uint _fee);
    struct queueInfo {
        uint available;
        uint perETH;
    }
    constructor() public {
        admin = msg.sender;
        feeDivider = 1000;
        minETH = 1 szabo;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function setAdmin(address newAdmin) public onlyAdmin returns(bool) {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function sell(address token, uint amount, uint rate) public returns(bool) {
        require(address(0) != token && amount > 0 && rate > 0);
        uint authorized = ERC20(token).allowance(msg.sender, address(this));
        require(amount <= authorized);
        queue[token][msg.sender].available = amount;
        queue[token][msg.sender].perETH = rate;
        return true;
    }
    function buy(address token, address seller) public payable returns(bool) {
        queueInfo memory active = queue[token][seller];
        require(active.available > 0);
        uint amountEther = msg.value;
        uint amountToken = msg.value * active.perETH;
        uint feeAmount;
        uint exactAmount;
        uint restEther;
        if (amountToken > active.available) {
            amountToken = active.available;
            restEther = amountEther - (amountToken / active.perETH);
            amountEther -= restEther;
        }
        feeAmount = amountEther / 1000;
        exactAmount = amountEther - feeAmount;
        if (restEther > 0) msg.sender.transfer(restEther);
        if (!ERC20(token).transferFrom(seller, msg.sender, amountToken)) revert();
        admin.transfer(feeAmount);
        seller.transfer(exactAmount);
        emit Sold(token, msg.sender, seller, amountEther, amountToken, feeAmount);
        return true;
    }
    function() public payable {
        require(msg.value > 0);
        revert();
    }
}