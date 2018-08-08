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




contract UNGT {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 8;  
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    function UNGT() public {
        totalSupply = 1000000000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = "Universal Green Token";                                   
        symbol = "UNGT";                               
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

}