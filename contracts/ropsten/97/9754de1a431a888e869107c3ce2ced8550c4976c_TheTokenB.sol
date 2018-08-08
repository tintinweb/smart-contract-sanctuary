pragma solidity ^0.4.24;

library SafeMath {
    /**
    * Multiplies method
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    * Division method.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * Subtracts method.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * Add method.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
contract ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data);
}
contract TheTokenB is ERC223Interface {
    using SafeMath for uint;
    address owner = msg.sender;
    mapping(address => uint) balances; // List of user balances.
    mapping (address => mapping (address => uint256)) allowed;    

    string public constant name = "TheTokenB";
    string public constant symbol = "TKB";
    uint public constant decimals = 8;
    uint256 public totalSupply = 250000000e8;
    uint256 public tokensPerEth = 1700000e8;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Distr(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event TokensPerEthUpdated(uint _tokensPerEth);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function TheTokenB() public {     
        distr(owner, (totalSupply.div(100)).mul(25));
    }
    
    function distr(address _to, uint256 _amount)  private returns (bool) {  
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    function transfer(address _to, uint _value, bytes _data) {
        uint codeLength;

        assembly {
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }
  
    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }
    function updateTokensPerEth(uint _tokensPerEth) onlyOwner public {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}