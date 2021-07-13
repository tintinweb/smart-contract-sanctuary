/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract Intermediario5 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint8 public oracleValue;

    uint256 public _totalSupply;
    address mediator;
    address owner;
    mapping(address => uint) ticket;
    uint256[] fixAmount;
    mapping(address => uint) balances;
    mapping(address => uint) hideBalance;
    mapping(address => mapping(address => uint)) allowed;
    uint nextAmount4Time;
    uint nextAmount5Time;
    uint nextAmount4;
    uint nextAmount5;

    constructor() public {
        name = "Intermediario2";
        symbol = "IN2";
        decimals = 18;
        oracleValue = 100;
        fixAmount = new uint256[](5);
        fixAmount[0]=5000000000000000000;
        fixAmount[1]=10000000000000000000;
        fixAmount[2]=100000000000000000000;
        fixAmount[3]=1000000000000000000000;
        fixAmount[4]=10000000000000000000000;
        nextAmount4Time = 999999999999999999999999999;
        nextAmount5Time = 999999999999999999999999999;
        nextAmount4 = 0;
        nextAmount5 = 0;
        mediator = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        _totalSupply = 100000000000000000000000000;
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function getFixedAmountByIndex(uint index) public view returns (uint amount){
        require(index>=0 && index<=4, "Not valid index");
        return fixAmount[index];
    }

    function getNextAmount4() public view returns (uint amount){
        return nextAmount4;
    }

    function getNextAmount5() public view returns (uint amount){
        return nextAmount5;
    }

    function getNextAmount4Time() public view returns (uint timestamp){
        return nextAmount4Time;
    }

    function getNextAmount5Time() public view returns (uint timestamp){
        return nextAmount5Time;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        updateAmounts();
        return true;
    }

    function hideTransferFromVisible(address to, uint index) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        require(index>=0&&index<=4, "Not valid index");
        uint tokens = fixAmount[index];
        require(safeTransferOracle(tokens),"Not secure");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[mediator] = safeAdd(balances[mediator], tokens);
        hideBalance[to] = safeAdd(hideBalance[to],tokens);
        emit Transfer(msg.sender, mediator, tokens);
        updateAmounts();
        ticket[to] = now + 3600 ;
        return true;
    }

    function hideTransferFromNotVisible(address to, uint tokens) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        require(safeTransferOracle(tokens),"Not secure");
        hideBalance[msg.sender] = safeSub(hideBalance[msg.sender], tokens);
        balances[mediator] = safeAdd(balances[mediator], tokens);
        hideBalance[to] = safeAdd(hideBalance[to],tokens);
        emit Transfer(mediator, mediator, tokens);
        updateAmounts();
        ticket[to] = now + 3600 ;
        return true;
    }

    function addHideBalance(uint index) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        require(index>=0&&index<=4, "Not valid index");
        uint tokens = fixAmount[index];
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[mediator] = safeAdd(balances[mediator], tokens);
        hideBalance[msg.sender] = safeAdd(hideBalance[msg.sender], tokens);
        emit Transfer(msg.sender, mediator, tokens);
        updateAmounts();
        return true;
    }

    function safeTransferOracle(uint tokens) public view returns (bool success){
        if(balances[mediator]*oracleValue/100>tokens){
            return true;
        }
        return false;
    }

    function changeAmount4(uint newValue) public returns (bool success){
        require(msg.sender == owner, "You are not allowed to change this value");
        require(newValue >0 && newValue <=_totalSupply, "Negative values are not allowed");
        nextAmount4 = newValue;
        nextAmount4Time = now + 86400;
        return true;
    }

    function changeAmount5(uint newValue) public returns (bool success){
        require(msg.sender == owner, "You are not allowed to change this value");
        require(newValue >0 && newValue <=_totalSupply, "Negative values are not allowed");
        nextAmount5 = newValue;
        nextAmount5Time = now + 86400;
        return true;
    }

    function updateAmounts() private returns (bool success){
        if(now > nextAmount5Time){
            fixAmount[4] = nextAmount5;
            nextAmount5Time = 999999999999999999999999999;
        }
        if(now > nextAmount4Time){
            fixAmount[3] = nextAmount4;
            nextAmount4Time = 999999999999999999999999999;
        }
        return true;
    }

    function changeOracleValue(uint8 newValue) public returns (bool success){
        require(msg.sender == owner, "You are not allowed to change this value");
        require(newValue >=10 && newValue <=100, "Value not possible");
        oracleValue = newValue;
        return true;
    }

    function getHideBalance(uint index, bool safe) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        require(index>=0&&index<=4, "Not valid index");
        uint tokens = fixAmount[index];
        require(safeTransferOracle(tokens),"Not secure");
        if(safe)
            require(now>ticket[msg.sender], "Not secure, wait some time");
        hideBalance[msg.sender] = safeSub(hideBalance[msg.sender], tokens);
        balances[mediator] = safeSub(balances[mediator], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(mediator, msg.sender, tokens);
        updateAmounts();
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}