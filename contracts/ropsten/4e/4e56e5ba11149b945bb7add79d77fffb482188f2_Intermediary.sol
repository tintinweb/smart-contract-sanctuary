pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function allowance(address _owner, address _spender) public view returns(uint);
    function transferFrom(address _from, address _to, uint _value) public returns(bool);
}
contract IntermediaryEvents {
    event AddedToQueue(address indexed _seller, address indexed _token, uint _rate);
    event Sold(address indexed _buyer, address indexed _seller, address indexed _token, uint _value);
}
contract Intermediary is IntermediaryEvents {
    address public admin;
    uint256 public fee;
    mapping(address => mapping(address => uint)) queue;
    constructor() public {
        admin = msg.sender;
        fee = 1000;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function checkRate(address token, address seller) public view returns(uint) {
        return queue[token][seller];
    }
    function checkAvailability(address token, address seller) public view returns(uint) {
        uint a = ERC20(token).allowance(seller, address(this));
        uint b = ERC20(token).balanceOf(seller);
        if (a <= b) return a;
        else return b;
    }
    function setAdmin(address newAdmin) public onlyAdmin returns(bool) {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function setFee(uint newFee) public onlyAdmin returns(bool) {
        require(newFee >= 1000);
        fee = newFee;
        return true;
    }
    function () public payable {
        require(msg.value > 0);
        revert();
    }
    function sell(address token, uint rate) public returns(bool) {
        require(token != address(0) && rate > 0);
        queue[token][msg.sender] = rate;
        emit AddedToQueue(msg.sender, token, rate);
        return true;
    }
    function buy(address token, address seller) public payable returns(bool) {
        require(address(0) != token && msg.value > 1 szabo && address(0) != seller && address(this) != seller && msg.sender != seller);
        uint available = checkAvailability(token, seller);
        uint askRate = checkRate(token, seller);
        require(available > 0 && askRate > 0);
        uint ethValue = msg.value;
        uint amount = ethValue * askRate;
        uint totalFee = ethValue / fee;
        uint restEth = 0;
        if (amount > available) {
            restEth = ethValue - ((amount - available) / askRate);
            amount = available;
            ethValue -= restEth;
            totalFee = ethValue / 1000;
            msg.sender.transfer(restEth);
        }
        if (!ERC20(token).transferFrom(seller, msg.sender, amount)) revert();
        seller.transfer(ethValue - totalFee);
        admin.transfer(totalFee);
        emit Sold(msg.sender, seller, token, amount);
        return true;
    }
}