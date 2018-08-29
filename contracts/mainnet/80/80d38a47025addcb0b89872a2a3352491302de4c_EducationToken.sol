pragma solidity >0.4.22 <0.5.0;
///////////////////////////////// ERC223 ///////////////////////////////////////
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
contract ERC223Interface {
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public ;
    function transfer(address to, uint value, bytes data) public ;
    //event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value); //ERC 20 style
}
contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
contract EducationToken is ERC223Interface {
    
    using SafeMath for uint;
    
    string public constant name = "Education Token";
    string public constant symbol = "EDUTEST";
    uint8  public constant decimals = 18;
    
    uint256 public constant TotalSupply =  2 * (10 ** 9) * (10 ** 18); // 2 billion
    uint256 public constant Million     =      (10 ** 6);
    //uint256 public nowSupply = 0;
    
    address public constant contractOwner = 0x21bA616f20a14bc104615Cc955F818310E725aBA;
    
    mapping (address => uint256) balances;
    
    function EducationToken() {
        preAllocation();
    }
	function preAllocation() internal {
        balances[0x21bA616f20a14bc104615Cc955F818310E725aBA] =   0*(10**6)*(10**18); //  0% ,code writer
        balances[0x096AE211869e5DFF9d231717762640E50D53f96C] = 400*(10**6)*(10**18); // 20% ,contractOwner0
        balances[0x9089e320B026338c2E03FCFc07e97d76ca208B00] = 400*(10**6)*(10**18); // 20% ,contractOwner1
        balances[0xF357ab5623e828C3A535a1dc4B356E96885885f1] = 400*(10**6)*(10**18); // 20% ,contractOwner2
        balances[0x57F8558e895Db16c45754CE48fef8ea81B71b3F3] = 400*(10**6)*(10**18); // 20% ,contractOwner3
        balances[0x377F514196DD32A2b8b48E16065b81e61c40c5F2] = 400*(10**6)*(10**18); // 20% ,contractOwner4
	}
    function() payable {
        require(msg.value >= 0.0000001 ether);
    }
    function getETH(uint256 _amount) public {
        //require(now>endTime);
        require(msg.sender==contractOwner);
        msg.sender.transfer(_amount);
    }
    function nowSupply() constant public returns(uint){
        uint supply=TotalSupply;
        supply=supply-balances[0x21bA616f20a14bc104615Cc955F818310E725aBA];
        supply=supply-balances[0x096AE211869e5DFF9d231717762640E50D53f96C];
        supply=supply-balances[0x9089e320B026338c2E03FCFc07e97d76ca208B00];
        supply=supply-balances[0xF357ab5623e828C3A535a1dc4B356E96885885f1];
        supply=supply-balances[0x57F8558e895Db16c45754CE48fef8ea81B71b3F3];
        supply=supply-balances[0x377F514196DD32A2b8b48E16065b81e61c40c5F2];
        return supply;
    }
    
    /////////////////////////////////////////////////////////////////////
    ///////////////// ERC223 Standard functions /////////////////////////
    /////////////////////////////////////////////////////////////////////
    function transfer(address _to, uint _value, bytes _data) public {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;
        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to]+_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    function transfer(address _to, uint _value) public {
        uint codeLength;
        bytes memory empty;
        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(balances[_to]+_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    function totalSupply() public view returns (uint256) {
    return TotalSupply;
  }
}