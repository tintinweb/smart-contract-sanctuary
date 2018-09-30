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
    event TF(address indexed from, address indexed to, uint value, bytes data);
}
contract USDCX is ERC223Interface {
    
    using SafeMath for uint;
    
    string public constant name = "USD Cuallix Token";
    string public constant symbol = "USDCX";
    uint8  public constant decimals = 18;
    uint256 public tokenRemained= 2 * (10 ** 9) * (10 ** 18); // 2 billion USDCX, decimals set to 18
    uint256 public constant TotalSupply =  2 * (10 ** 9) * (10 ** 18); // 2 billion
    uint256 public constant Million     =      (10 ** 6);
    uint256 public rate=0;
    
    address public contractOwner = 0xa8865ebfC03dB4F4769c58200862bD8195225560;
    
    mapping (address => uint256) balances;
    
    function USDCX() {
        contractOwner=msg.sender;
        preAllocation();
    }
	function preAllocation() internal {
        balances[contractOwner] =   0*(10**6)*(10**18); //  0% ,code writer
        rate=300;

	}
	
	function setRate(uint256 _newrate){
        require(msg.sender==contractOwner);
        require(_newrate>0);
        rate=_newrate;
    }
    
    function changeOwner(address _newOwner){
        require(msg.sender==contractOwner);
        contractOwner=_newOwner;
    }
    
    function getRate() returns (uint256){
        return rate;
    }
    
    function checkRemained(uint256 _rr) internal returns (uint256){
        
        if(tokenRemained.sub(_rr) > 0){return _rr;}
        else{return 0;} //fail!!!!!!
    }
    
    function() payable {
        require(msg.value >= 0.0000001 ether);
        require(rate>0);
        
        uint256 rr=msg.value*rate;
        uint256 requested=checkRemained(rr);
        //require(tokenRemained.sub(msg.value*rate)>0);
        uint256 toReturn = rr-requested;
        
        if (requested > 0) {
            require(balances[msg.sender]+rr >= balances[msg.sender]);
            balances[msg.sender] = balances[msg.sender]+rr;
            tokenRemained=tokenRemained.sub(rr);
        }
        
        if(toReturn > 0) {
            // return over payed ETH
            msg.sender.transfer(toReturn/rate);
        }
        
        
        
        
    }
    function getETH(uint256 _amount) public {
        require(msg.sender==contractOwner);
        msg.sender.transfer(_amount);
    }
    function nowSupply() constant public returns(uint256){
        uint256 supply=TotalSupply-tokenRemained;

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