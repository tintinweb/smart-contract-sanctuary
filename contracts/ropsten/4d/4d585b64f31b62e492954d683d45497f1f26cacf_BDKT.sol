pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract BDKT is owned{
    
    using SafeMath for uint256;
     
    mapping (address => uint256) internal lockMonth;
    mapping (address => uint256) internal lockTime;
    mapping (address => uint256) internal lockSum;
    mapping (address => uint256) internal unlockMonth;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    function BDKT() public {
        totalSupply = 5000000000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = "bidaka token";                                  
        symbol = "BDKT";                              
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value)> balanceOf[_to]);
            
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function batchTransfer(address[] _tos,uint256[] _amounts)  public returns (bool) {
            require(_tos.length > 0);
            require(_amounts.length > 0);
            
          for(uint32 i=0;i<_tos.length;i++){
              _transfer(msg.sender, _tos[i],_amounts[i]* 10 ** uint256(decimals));
          }
          
         return true;
     }

}