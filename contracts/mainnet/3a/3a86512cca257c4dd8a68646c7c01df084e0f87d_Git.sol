pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ERC223Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transfer(address to, uint256 value, bytes data) public returns (bool);
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223 is ERC223Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Token { 
    function distr(address _to, uint256 _value) public returns (bool);
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
}

contract Git is ERC223 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public constant name = "Git";
    string public constant symbol = "Git";
    uint public constant decimals = 18;
    
    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LOG_Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

    
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Git (uint256 _initialAmount) public {
        require(_initialAmount != 0);
        owner = msg.sender;
        totalSupply = _initialAmount;
        balances[msg.sender] = totalSupply;
    }
    
    function () external payable {
        
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

    // mitigates the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount, bytes _data, string _custom_fallback) onlyPayloadSize(2 * 32) public returns (bool success) {
        if(isContract(_to)) {
            require(balanceOf(msg.sender) >= _amount);
            balances[msg.sender] = balanceOf(msg.sender).sub(_amount);
            balances[_to] = balanceOf(_to).add(_amount);
            ContractReceiver receiver = ContractReceiver(_to);
            require(receiver.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _amount, _data));
            
            Transfer(msg.sender, _to, _amount);
            LOG_Transfer(msg.sender, _to, _amount, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _amount, _data);
        }
    }


    function transfer(address _to, uint256 _amount, bytes _data) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));

        if(isContract(_to)) {
            return transferToContract(_to, _amount, _data);
        }
        else {
            return transferToAddress(_to, _amount, _data);
        }
    }

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
    
        require(_to != address(0));
        
        bytes memory empty;
        
        if(isContract(_to)) {
            return transferToContract(_to, _amount, empty);
        }
        else {
            return transferToAddress(_to, _amount, empty);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        bytes memory empty;
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        LOG_Transfer(_from, _to, _amount, empty);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
    }
    
    function mint(uint256 _value) onlyOwner public {

        address minter = msg.sender;
        balances[minter] = balances[minter].add(_value);
        totalSupply = totalSupply.add(_value);
        Mint(minter, _value);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) payable public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
    
    function isContract(address _addr) private constant returns (bool) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] =  balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        LOG_Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function transferToContract(address _to, uint _value, bytes _data) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        LOG_Transfer(msg.sender, _to, _value, _data);
        return true;
    }

}