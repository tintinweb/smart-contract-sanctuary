/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }


  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

 
}
contract JabariToken is SafeMath{
    
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint _initialSupply;
    
    mapping(address => uint256) public coinBalance;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 _amount);
    
   
    constructor( ) public {
        
        name = "Jabari";
        symbol = "JUT";
        _initialSupply = 280000000 * 10**uint(decimals);
        coinBalance[msg.sender] = _initialSupply;
        
        
        //coinBalance[msg.sender] = _initialSupply;
        //check this in future
        //totalSupply = _initialSupply;
    }
    /* function to implement delegated authorization for transfer*/
    function authorize(address _authorizedAccount, uint256 _allowance) public returns(bool success){
        allowance[msg.sender][_authorizedAccount] = _allowance;
        return true;
    }
    
    /* implementation of delegated transfers authorized */
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool success){
        require(_to != 0x0);
        require(coinBalance[_from] > _amount);
        require(coinBalance[_to] + _amount >= coinBalance[_to]);
        require(_amount <= allowance [_from][msg.sender]);
        coinBalance[_from] = SafeMath.safeSub(coinBalance[_from], _amount);
        coinBalance[_to] = SafeMath.safeAdd(coinBalance[_to], _amount);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _amount);
        emit Transfer(_from, _to, _amount);
        
       
        
    }
    function transfer(address _to, uint256 _amount) public{
        require(_to != 0x0);
        require(coinBalance[msg.sender] > _amount);
        require(coinBalance[_to] + _amount >= coinBalance[_to]);
        coinBalance[msg.sender] = SafeMath.safeSub(coinBalance[msg.sender], _amount);
        coinBalance[_to] = SafeMath.safeAdd(coinBalance[_to], _amount);
        emit Transfer(msg.sender, _to, _amount);
        
         
        
        
    }
}