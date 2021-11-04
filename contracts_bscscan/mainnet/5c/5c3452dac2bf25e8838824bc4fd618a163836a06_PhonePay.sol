/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity 0.4.16;

contract IBEP20{
    function totalSupply() constant returns (uint256 total);

    function balanceOf(address _who) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PhonePay is IBEP20 {
    using SafeMath for uint256;

    string public name = "PhonePay Token";
    string public symbol = "PPAY";

    uint256 public totalSupply = 100000000000 * 10**8;
    uint8 public decimals = 8;

    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
 
    uint256 public totalPayments;
    mapping(address => uint256) public payments;

    bool public paused = false;

    uint256 reclaimAmount;

    event Burn(address indexed burner, uint indexed value);
    event Mint(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PaymentForTest(address indexed to, uint256 amount);
    event WithdrawPaymentForTest(address indexed to, uint256 amount);

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function PhonePay() {
        owner = msg.sender;
        balances[owner] = 100000000000 * 10**8;
    }

    function totalSupply() constant returns (uint256 total) {
        return totalSupply;
    }

    function balanceOf(address _who) constant returns (uint256 balance) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool success) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) whenNotPaused returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) whenNotPaused returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) whenNotPaused returns (bool success) {

        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint _value) returns (bool success)
    {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner returns (bool success) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    function () payable {

    }

    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }

    function destroy() onlyOwner {
        selfdestruct(owner);
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function reclaimToken(IBEP20 token) external onlyOwner {
        reclaimAmount = token.balanceOf(this);
        token.transfer(owner, reclaimAmount);
        reclaimAmount = 0;
    }

    function asyncSend(address _to, uint256 _amount) onlyOwner {
        payments[_to] = payments[_to].add(_amount);
        totalPayments = totalPayments.add(_amount);
        PaymentForTest(_to, _amount);
    }

    function withdrawPayments() {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(this.balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        payee.transfer(payment);
        WithdrawPaymentForTest(msg.sender, payment);
    }

    function withdrawToAdress(address _to, uint256 _amount) onlyOwner {
        require(_to != address(0));
        require(this.balance >= _amount);
        _to.transfer(_amount);
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}