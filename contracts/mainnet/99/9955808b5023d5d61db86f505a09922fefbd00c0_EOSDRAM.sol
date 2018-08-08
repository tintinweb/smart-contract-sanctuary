pragma solidity ^0.4.8;

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 supply);
    function balance() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface Token { 
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
}

interface EOSToken {
  function balanceOf(address who) constant public returns (uint value);
}

contract EOSDRAM is ERC20Interface {
    string public constant symbol = "DRAM";
    string public constant name = "EOS DRAM";
    uint8 public constant decimals = 18;

    address EOSContract = 0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0;

    // 1 DRAM is the equivalent of EOS 1 Kb of RAM
    // total fixed supply is 64 GB of DRAM;
    // total fixed supply = 64 * 1024 *1024 = 67108864
    // unlike the EOS blockchain, 64 GB is a fixed total supply that can never be changed/increased
    // having a fixed supply means that all future RAM increases on the EOS blockchain will have no effect here on DRAM
    

    uint256 _totalSupply = 67108864e18;
    
    // as per the locked EOS contract 0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0 there are 330687 EOS holders
    // 10% of the total supply will be reserved for exchanges/dev and the remaining 90% will be distributed equally among the 330687 EOS holders
    // this means each address receives 182 DRAM
   
   uint256 _airdropAmount = 182e18;
    

    mapping(address => uint256) balances;
    mapping(address => bool) initialized;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    address public owner;
    
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

    function EOSDRAM() public {
        owner = msg.sender;
        initialized[msg.sender] = true;
        //~10% reserve for exchanges and dev
        balances[msg.sender] = 6923830e18;
        Transfer(0, owner, 6923830e18);
      }

    function totalSupply() public constant returns (uint256 supply) {
        return _totalSupply;
    }

    // What&#39;s my balance?
    function balance() public constant returns (uint256) {
        return getBalance(msg.sender);
    }

    // What is the balance of a particular account?
    function balanceOf(address _address) public constant returns (uint256) {
        return getBalance(_address);
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        initialize(msg.sender);

        if (balances[msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(msg.sender, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        initialize(_from);

        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            initialize(_to);
            if (balances[_to] + _amount > balances[_to]) {

                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;

                Transfer(_from, _to, _amount);

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // internal private functions
    function initialize(address _address) internal returns (bool success) {
       // ensure we only airdrop once per address
        if (!initialized[_address]) {
       
       // we verify the balance of the EOS contract
       EOSToken token = EOSToken(EOSContract);
       uint256 has_eos = token.balanceOf(_address);
       if (has_eos > 0) {
       	    // if the address has eos, we grant the DRAM airdrop
            initialized[_address] = true;
            balances[_address] = _airdropAmount;
            }
        }
        return true;
    }

    function getBalance(address _address) internal returns (uint256) {
        if (!initialized[_address]) {
            EOSToken token = EOSToken(EOSContract);
	    uint256 has_eos = token.balanceOf(_address);
      	   
      	   if (has_eos > 0) {
            return balances[_address] + _airdropAmount;
            }
            else {
            return balances[_address];
            }
        }
        else {
            return balances[_address];
        }
    }
}