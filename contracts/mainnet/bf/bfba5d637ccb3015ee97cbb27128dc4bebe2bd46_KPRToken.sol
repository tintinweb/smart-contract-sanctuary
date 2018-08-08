pragma solidity ^0.4.23;

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  // event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
  event Transfer(address indexed from, address indexed to, uint value);
}
contract ContractReceiver {
 
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }


    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
}


library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract KPRToken is ERC223 {
    
    using SafeMath for uint256;
    

    
    //public variables
    string public constant symbol="KPR"; 
    string public constant name="KPR Coin"; 
    uint8 public constant decimals=18;

    //1 ETH = 2,500 KPR
    uint256 public  buyPrice = 2500;

    //totalsupplyoftoken 
    uint public totalSupply = 100000000 * 10 ** uint(decimals);
    
    uint public buyabletoken = 70000000 * 10 ** uint(decimals);
    //where the ETH goes 
    address public owner;
    
    //map the addresses
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    // 1514764800 : Jan 1 2018
    uint256 phase1starttime = 1525132800; // Phase 1 Start Date May 1 2018
    uint256 phase1endtime = 1527033540;  // Phase 1 End Date May 22 2018
    uint256 phase2starttime = 1527811200;  // Phase 2 Start Date June 1 2018
    uint256 phase2endtime = 1529711940; // Phase 2 End Date June 22 2018
    
    //create token function = check

    function() payable{
        require(msg.value > 0);
        require(buyabletoken > 0);
        require(now >= phase1starttime && now <= phase2endtime);
        
        if (now > phase1starttime && now < phase1endtime){
            buyPrice = 3000;
        } else if(now > phase2starttime && now < phase2endtime){
            buyPrice = 2000;
        }
        
        uint256 amount = msg.value.mul(buyPrice); 
        
        balances[msg.sender] = balances[msg.sender].add(amount);
        
        balances[owner] = balances[owner].sub(amount);
        
        buyabletoken = buyabletoken.sub(amount);
        owner.transfer(msg.value);
    }

    function KPRToken() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
      event Burn(address indexed burner, uint256 value);

      /**
       * @dev Burns a specific amount of tokens.
       * @param _value The amount of token to be burned.
       */
      function burn(uint256 _value) public {
        _burn(msg.sender, _value);
      }

      function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
    
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
      }

    function balanceOf(address _owner) constant returns(uint256 balance) {
        
        return balances[_owner];
        
    }


    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value)
                revert();
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {
        
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
                //retrieve the size of the code on target address, this needs assembly
                length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value)
            revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value)
            revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    event Transfer(address indexed_from, address indexed_to, uint256 _value);
    event Approval(address indexed_owner, address indexed_spender, uint256 _value);
    
    
}