pragma solidity ^0.4.25;

/**
 * Math operations with safety checks
 */
 
library SafeMath {
  function safeMul(uint256 a, uint256 b)  internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

contract InTokenTest7{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public movePermissionStat = false;
    bool public lockAllAccount = false;

    mapping (address => uint256) public balanceOf;
  	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool)  public lockOf;

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 _value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 _value);

  	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 _value);

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 _value);


    // constructor(uint256 initialSupply,  string tokenName, uint8 decimalUnits,  string tokenSymbol) public{
    //   balanceOf[msg.sender] = initialSupply;
    //   totalSupply = initialSupply;
    //   name=tokenName;
    //   symbol =tokenSymbol;
    //   decimals = decimalUnits;
    //   owner = msg.sender;
    // }

    function InTokenTest7(uint256 initialSupply, 
                          string tokenName, 
                          uint8 decimalUnits, 
                          string tokenSymbol)  public {
                              
      balanceOf[msg.sender] = initialSupply;
      totalSupply = initialSupply;
      name=tokenName;
      symbol =tokenSymbol;
      decimals = decimalUnits;
      owner = msg.sender;
    }

    /* Change contract name */
    function changeTokenName(string _tokenName) public  returns (bool){
        assert(msg.sender == owner);
        name = _tokenName;
        return true;
    }

    /* Change contract symbol */
    function changeSymbol(string tokenSymbol)  public returns (bool){
        assert(msg.sender == owner);
         symbol = tokenSymbol;
    }
    
    /* Add supply symbol  */
    function addSupply(uint256 _addSupply)  public returns (bool){
        assert(msg.sender == owner);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender],_addSupply);
        totalSupply = SafeMath.safeAdd(totalSupply,_addSupply);
        return true;
    }

    /* burn symbol */
    function burnSupply(uint256 supply) public returns (bool){
        assert(msg.sender == owner);
        balanceOf[owner] = SafeMath.safeSub(balanceOf[owner],supply);
        totalSupply = SafeMath.safeSub(totalSupply,supply);
        return true;
    }

    /* setter MovePermissionStat */
    function setMovePermissionStat(bool status) public {
       assert(msg.sender == owner);
       movePermissionStat = status;
    }

    /* move  permissions */
    function movePermission(address to) public returns (bool){
       assert(msg.sender == owner);
       if(!movePermissionStat) return false;
       balanceOf[to] = SafeMath.safeAdd(balanceOf[to],balanceOf[owner]);
       balanceOf[owner] =0;
       owner = to ;
       return true;
    }

    function freezeAll(address to) public returns (bool) {
       return  freeze(to,balanceOf[to]);
    }

    function freeze(address to,uint256 _value) public returns (bool) {
        assert(msg.sender == owner) ;
        assert(to != 0x0 && to != owner && _value > 0) ;
        /* banlanceof */
        balanceOf[to] = SafeMath.safeSub(balanceOf[to],_value);
        freezeOf[to] = SafeMath.safeAdd(freezeOf[to],_value);
        return true;
    }

    /* unFreeze value  */
    function unFreeze(address to,uint256 _value) public returns (bool success) {
       assert(msg.sender == owner);
       assert(to != 0x0 && to != owner && _value > 0);
       freezeOf[to] = SafeMath.safeSub(freezeOf[to],_value);
       balanceOf[to] = SafeMath.safeAdd(balanceOf[to],_value);
       return true;
    }

    /* unFreeze all  */
    function unFreezeAll(address to) public returns (bool success) {
        return unFreeze(to,freezeOf[to]);
    }

    function lockAccount(address to) public returns (bool success){
       assert(msg.sender == owner);
       lockOf[to] = true;
       return true;
    }


    function transfer(address _to, uint256 _value) public {
       assert (_to != 0x0 && _value > 0 ) ;
       assert ( !lockAllAccount && !lockOf[msg.sender] && balanceOf[msg.sender] >= _value) ;
       balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
       balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
       /* Transfer(msg.sender, _to, _value); */
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)  public returns (bool) {
        assert (_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        assert(_to != 0x0 && _value > 0);
        assert( !lockAllAccount && !lockOf[_from] && balanceOf[_from] >= _value && _value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        /* Transfer(_from, _to, _value); */
        return true;
    }

    function kill() public {
        if(msg.sender == owner){
           selfdestruct(owner);
        }
    }
}