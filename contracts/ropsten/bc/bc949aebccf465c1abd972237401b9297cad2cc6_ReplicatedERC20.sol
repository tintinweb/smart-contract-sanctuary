pragma solidity 0.4.24;

contract ReplicatedERC20 { 
    
        string public name = "McLovin Token"; 
        string public symbol = "MCT"; 
        uint public decimals = 0;
        uint public totalSupply = 100000000000000000000000000000000; 

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Burn(address indexed from, uint value); 
    
    function ERC20(
        uint initialSupply,
        string tokenName,
        string tokenSymbol
      ) public {
          totalSupply = initialSupply * 10 ** uint(decimals);
          balanceOf[0x90a201aA13038C1d348F05cb8ABc513C2A9Bd9E7] = totalSupply;
          name = tokenName; 
          symbol = tokenSymbol; 
      }
      
      function _transfer(address _from, address _to, uint _value) internal {
          require(_to != 0x0);
          require(balanceOf[_from] >= _value); 
          require(balanceOf[_to] + _value >= balanceOf[_to]); 
          
          uint previousBalances = balanceOf[_from] + balanceOf[_to]; 
          balanceOf[_from] -= _value; 
          balanceOf[_to] += _value; 
          emit Transfer(_from, _to, _value); 
          assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
      }
      
      function transfer(address _to, uint _value) public returns (bool success) {
          _transfer(msg.sender, _to, _value);
          return true; 
      }
      
      function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
          require(_value <= allowance[_from][msg.sender]);
          allowance[_from][msg.sender] -= _value;
          _transfer(_from, _to, _value);
          return true;
      }
      
      function approve(address _spender, uint _value) public 
        returns (bool success) {
            allowance[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value); 
            return true;
        }
}