pragma solidity ^0.4.25;
contract ERC20 {
    function decimals() public view returns(uint Decimals);
    function balanceOf(address _who) public view returns(uint Balance);
    function allowance(address _owner, address _spender) public view returns(uint Remaining);
    function approve(address _spender, uint _value) public returns(bool Success);
    function transfer(address _to, uint _value) public returns(bool Success);
    function transferFrom(address _from, address _to, uint _value) public returns(bool Success);
    event Transfer(address indexed _from, address _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract Store {
    event Sent(address indexed _from, address indexed _to, address indexed _token, uint _value);
    event Purchase(address indexed _token, address indexed _seller, address indexed _buyer, uint _amountEther, uint _amountToken);
    event RequestAdded(address indexed _token, address indexed _seller, uint _rates);
    event Paid(address indexed _buyer, address indexed _seller, uint _amount, uint _fee);
    function buy(address _token, address _seller) public payable returns(bool Success);
    function sell(address _token, uint _rate) public returns(bool Success);
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
contract ERC20Wallet is Ownable {
    address public intermediary;
    constructor(address _intermediary) public {
        intermediary = _intermediary;
    }
    function setIntermediary(address newIntermediary) public onlyOwner returns(bool Success) {
        require(newIntermediary != address(0) && address(this) != newIntermediary);
        intermediary = newIntermediary;
        return true;
    }
    function() public payable {}
    function sendEther(address to, uint amount) public onlyOwner returns(bool Success) {
        require(to != address(0) && address(this) != to);
        require(amount > 0 && amount <= address(this).balance);
        if (!to.call.gas(100000).value(amount)()) to.transfer(amount);
        return true;
    }
    function sendERC20(address token, address to, uint amount) public onlyOwner returns(bool Success) {
        require(to != address(0) && address(this) != to && token != address(0));
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).transfer(to, amount)) revert();
        return true;
    }
    function approveERC20(address token, address spender, uint amount) public onlyOwner returns(bool Success) {
        require(address(0) != token && spender != address(0) && address(this) != spender);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).approve(spender, amount)) revert();
        return true;
    }
    function sendData(address to, uint amount, uint gasLimit, bytes data) public onlyOwner returns(bool Success) {
        require(to != address(0) && gasLimit >= 25000);
        if (!to.call.gas(gasLimit).value(amount)(data)) revert();
        return true;
    }
    function sellERC20(address token, uint amount, uint rate) public onlyOwner returns(bool Success) {
        require(address(0) != token && rate > 0);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!approveERC20(token, intermediary, amount)) revert();
        if (!Store(intermediary).sell(token, rate)) revert();
        return true;
    }
}