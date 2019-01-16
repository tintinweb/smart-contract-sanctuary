pragma solidity ^0.4.25;


library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b > 0); 
        uint256 c = a / b;
        assert(a == b * c + a % b); 
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

// interface of your Customize token
interface AfroToken {

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns(bool); 
    function transferFrom(address _from, address _to, uint256 _value) returns(bool);
    function approve(address _spender, uint256 _value) returns(bool);
    function allowance(address _owner, address _spender) constant returns(uint256);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
// ERC20 Your Customize Token Smart Contract
contract Afro is AfroToken {

    string public constant name = "Afro";
    string public constant symbol = "AFRO";
    uint8 public constant decimals = 18;
    uint public _intialSupply = 333333333;
    uint256 public RATE = 1;
    using SafeMath for uint256;
    address public contractOwner;
    address public tokenOwner;

// Functions with this modifier can only be executed by the owner
modifier onlyOwner() {
    if (msg.sender != contractOwner) {
    revert();
        }
     _;
    }
// Balances for each account
mapping(address => uint256) balances;
// Owner of account approves the transfer of an amount to another account
mapping(address => mapping(address=>uint256)) allowed;

// Constructor
    constructor() public {
        tokenOwner = 0x04b68bBD1D2942EA98b1EA9B7E96B0109CB2E3e7;
        balances[tokenOwner] = _intialSupply * 30/100 ;
        contractOwner = msg.sender; 
        balances[contractOwner] = _intialSupply.sub(balances[tokenOwner]) ;
    }

// Get the account balance of another account with address _owner 
    function balanceOf(address _contractOwner) public view returns (uint256 balance){
        return balances[_contractOwner];
    } 
//To find out the tokenConsumed by the all other account holders 
    function tokenConsumed () public view returns (uint) {
        return _intialSupply.sub(balances[address(contractOwner)]);
    }
 
// Transfer the balance from owner&#39;s account to another account 
    function transfer(address _to, uint256 _value) returns(bool) {
        require(_to != 0x0);
        require(balances[msg.sender] >=_value  && _value > 0 );
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
         // Save this for an assertion in the future
        uint previousBalances = balances[msg.sender] + balances[_to];
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        return true;
    }

// Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns(bool) {
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    } 

// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) returns(bool){
        allowed[msg.sender][_spender] = _value; 
        Approval(msg.sender, _spender, _value);
        return true;
    }

// Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns(uint256 remainig){
         return allowed[_owner][_spender];
    }
}