//SourceUnit: product_trace_v1.sol

pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    function totalSupply() view public returns (uint256);

    function balanceOf(address _owner) view public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function allowance(address _owner, address _spender) public view returns (uint256);

    event  Transfer(address  indexed _from, address  indexed _to, uint256 _value);
    event  Approval(address  indexed _owner, address  indexed _spender, uint256 _value);
}


contract OwnAble {
    address public owner;
    address public operate;
    address public finance;

    bool public paused = false;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        operate = msg.sender;
        finance = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOperate() {
        require(msg.sender == operate);
        _;
    }

    modifier onlyFinance() {
        require(msg.sender == finance);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getOperate() public view returns (address) {
        return operate;
    }

    function getFinance() public view returns (address) {
        return finance;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function setOperate(address _operateAddr) public onlyOwner {
        operate = _operateAddr;
    }

    function setFinance(address _financeAddr) public onlyOwner {
        finance = _financeAddr;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOperate whenNotPaused {
        paused = true;
    }

    function unPause() external onlyOperate whenPaused {
        paused = false;
    }
}

contract ByteGoTrace is OwnAble {
    uint256 public orderID = 0;

    mapping(uint256 => Trace) public traces;

    struct Trace {
        uint256 orderID;
        address userAddress;

        string productType;
        string productName;
        string province;
        string city;
        string location;
        uint256 growthDays;

        uint256 blockNumber;
        uint256 datetime;
    }

    uint256 public tradingFee = 1000000;
    address public tokenAddress;


    event onSetUserRegister(address userAddress, bool flag);

    event onSetTrace(address userAddress, bool flag);

    event onSetTradingFee(address addr, uint256 value);

    event onSetTokenAddress(address addr, bool flag);

    event oneExtractToken(address token, address addr, uint amount);


    using SafeMath for uint256;

    mapping(address => uint256) public userRegisters;

    function setTrace(address _userAddress, string _productType, string _productName, string _province, string _city, string _location, uint256 _growthDays, address _tokenAddress, uint256 _tradingFee) public whenNotPaused returns (uint256) {
        require(msg.sender == tx.origin);
        require(userRegisters[_userAddress] == 1, "user address not register");
        require(_tokenAddress == tokenAddress, "tokenAddress not match");
        require(_tradingFee >= tradingFee, "tradingFee not enough");

        require(Token(_tokenAddress).transferFrom(msg.sender, address(this), tradingFee), "tradingFee transfer error");

        orderID++;
        traces[orderID] = Trace(orderID, _userAddress, _productType, _productName, _province, _city, _location, _growthDays, block.number, block.timestamp);
        emit onSetTrace(_userAddress, true);
        return orderID;
    }

    function setUserRegister(address _userAddress) public onlyOperate {
        userRegisters[_userAddress] = 1;
        emit onSetUserRegister(_userAddress, true);
    }

    function getTrace(uint256 _orderID) public view returns (address, string, string, string, string, string, uint256, uint256, uint256) {
        Trace storage item = traces[_orderID];
        return (item.userAddress, item.productType, item.productName, item.province, item.city, item.location, item.growthDays, item.blockNumber, item.datetime);
    }

    function setTradingFee(uint256 _value) public onlyOperate returns (uint256){
        tradingFee = _value;
        emit onSetTradingFee(msg.sender, _value);
        return tradingFee;
    }

    function getTradingFee() public view returns (uint256) {
        return tradingFee;
    }

    function setTokenAddress(address _tokenAddress) public onlyOperate returns (address){
        tokenAddress = _tokenAddress;
        emit onSetTokenAddress(msg.sender, true);
        return tokenAddress;
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function extractToken(address _tokenAddress, uint256 _amount) public onlyFinance {
        require(Token(_tokenAddress).transfer(finance, _amount));
        emit oneExtractToken(_tokenAddress, finance, _amount);
    }
}