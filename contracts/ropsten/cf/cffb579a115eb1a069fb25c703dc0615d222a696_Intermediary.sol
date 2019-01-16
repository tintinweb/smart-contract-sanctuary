pragma solidity ^0.4.25;
contract ERC20 {
    function decimals() public view returns(uint Decimals);
    function balanceOf(address _who) public view returns(uint Balance);
    function allowance(address _owner, address _spender) public view returns(uint Remaining);
    function transfer(address _to, uint _value) public returns(bool Success);
    function transferFrom(address _from, address _to, uint _value) public returns(bool Success);
    event Transfer(address indexed _from, address _to, uint _value);
}
contract Store {
    event Sent(address indexed _from, address indexed _to, address indexed _token, uint _value);
    event Purchase(address indexed _token, address indexed _seller, address indexed _buyer, uint _amountEther, uint _amountToken);
    event RequestAdded(address indexed _token, address indexed _seller, uint _rates);
    event Paid(address indexed _buyer, address indexed _seller, uint _amount, uint _fee);
    function transferOwnership(address _newOwner) public returns(bool Success);
    function checkRate(address _token, address _seller) public view returns(uint TokenPerEther);
    function checkAvailability(address _token, address _seller) public view returns(uint TokenAvailable);
    function setFeeDivider(uint _newDivider) public returns(bool Success);
    function buy(address _token, address _seller) public payable returns(bool Success);
    function sell(address _token, uint _rate) public returns(bool Success);
    function emergencyTransfer(address _token, address _to, uint _value) public returns(bool Success);
}
contract Ownable {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner returns(bool Success) {
        require(_newOwner != address(0) && address(this) != _newOwner);
        owner = _newOwner;
        return true;
    }
}
contract Intermediary is Store, Ownable {
    uint public feeDivider;
    mapping(address => mapping(address => uint)) queue;
    constructor(uint _feeDivider) public {
        feeDivider = _feeDivider;
    }
    function setFeeDivider(uint _newDivider) public onlyOwner returns(bool Success) {
        require(_newDivider >= 100);
        feeDivider = _newDivider;
        return true;
    }
    function checkRate(address _token, address _seller) public view returns(uint TokenPerEther) {
        return queue[_token][_seller];
    }
    function checkAvailability(address _token, address _seller) public view returns(uint TokenAvailable) {
        return ERC20(_token).allowance(_seller, address(this));
    }
    function getBalance(address _token, address _who) internal view returns(uint Balance) {
        if (_token == address(0)) return _who.balance;
        else return ERC20(_token).balanceOf(_who);
    }
    function toERC20(uint tokenDecimals, uint tokenPerEther, uint ethers) public pure returns(uint ERC20Token) {
        uint d;
        uint e;
        if (tokenDecimals < 18) d = 18 - tokenDecimals;
        if (ethers > 0 && tokenPerEther > 0) e = ethers * tokenPerEther;
        if (d > 0) e /= 10 ** d;
        return e;
    }
    function toEther(uint tokenDecimals, uint tokenPerEther, uint tokens) public pure returns(uint Ether) {
        uint d;
        uint e;
        if (tokenDecimals < 18) d = 18 - tokenDecimals;
        if (tokens > 0 && tokenPerEther > 0) e = tokens / tokenPerEther;
        if (d > 0) e *= 10 ** d;
        return e;
    }
    function emergencyTransfer(address _token, address _to, uint _value) public onlyOwner returns(bool Success) {
        require(_to != address(0) && address(this) != _to);
        require(_value > 0 && _value <= getBalance(_token, address(this)));
        if (_token == address(0)) {
            if (!_to.call.gas(100000).value(_value)())
            _to.transfer(_value);
        } else {
            if (!ERC20(_token).transfer(_to, _value))
            revert();
        }
        emit Sent(address(this), _to, _token, _value);
        return true;
    }
    function sell(address _token, uint _rate) public returns(bool Success) {
        require(address(0) != _token && _rate > 0);
        queue[_token][msg.sender] = _rate;
        emit RequestAdded(_token, msg.sender, _rate);
        return true;
    }
    function buy(address _token, address _seller) public payable returns(bool Success) {
        require(_token != address(0) && _seller != address(this) && address(0) != _seller && msg.value >= 1e9);
        require(checkAvailability(_token, _seller) >= (1 * 10 ** ERC20(_token).decimals()) && checkRate(_token, _seller) > 0);
        uint amountEther = msg.value;
        uint erc20Decimals = ERC20(_token).decimals();
        uint maxEther = toEther(erc20Decimals, checkRate(_token, _seller), checkAvailability(_token, _seller));
        uint restEther;
        uint fee;
        uint amountERC20;
        uint pureEther;
        require(maxEther > 0);
        if (amountEther > maxEther) restEther = amountEther - maxEther;
        amountERC20 = toERC20(erc20Decimals, checkRate(_token, _seller), (amountEther - maxEther));
        fee = (amountEther - restEther) / 1000;
        pureEther = amountEther - (restEther + fee);
        if (restEther > 0) {
            if (!msg.sender.call.gas(50000).value(restEther)())
            msg.sender.transfer(restEther);
            emit Sent(address(this), msg.sender, address(0), restEther);
        }
        if (!ERC20(_token).transferFrom(_seller, msg.sender, amountERC20)) revert();
        if (!owner.call.gas(50000).value(fee)()) owner.transfer(fee);
        if (!_seller.call.gas(50000).value(pureEther)()) _seller.transfer(pureEther);
        emit Purchase(_token, _seller, msg.sender, (pureEther + fee), amountERC20);
        emit Paid(msg.sender, _seller, (pureEther + fee), fee);
        return true;
    }
    function() public payable {}
}