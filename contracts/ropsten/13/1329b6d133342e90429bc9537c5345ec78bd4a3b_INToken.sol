pragma solidity ^0.4.17;

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

contract INToken{

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public movePermissionStat = false;
    bool public isLockTransfer = false;

    mapping (address => uint256) public balanceOf;
  	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool)  public lockOf;

    event AddSupply(address indexed from,uint256 _value);

    /* This notifies clients about the amount burnt */
    event BurnSupply(address indexed from, uint256 _value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 _value);

  	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 _value);

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MovePermission(address indexed form ,address indexed to);


    constructor(uint256 initialSupply,  string tokenName, uint8 decimalUnits,  string tokenSymbol) public{
      balanceOf[msg.sender] = initialSupply;
      totalSupply = initialSupply;
      name=tokenName;
      symbol =tokenSymbol;
      decimals = decimalUnits;
      owner = msg.sender;
    }

    // function InTokenTest1130(uint256 initialSupply,
    //                       string tokenName,
    //                       uint8 decimalUnits,
    //                       string tokenSymbol)  public {

    //   balanceOf[msg.sender] = initialSupply;
    //   totalSupply = initialSupply;
    //   name=tokenName;
    //   symbol =tokenSymbol;
    //   decimals = decimalUnits;
    //   owner = msg.sender;
    // }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier canTransfer{
        require(!isLockTransfer && !lockOf[msg.sender] );
        _;
    }

    /* Change contract name */
    function changeTokenName(string _tokenName) onlyOwner public returns (bool){
        name = _tokenName;
        return true;
    }

    /* Change contract symbol */
    function changeSymbol(string tokenSymbol)  onlyOwner public returns (bool){
         symbol = tokenSymbol;
    }

    /* Add supply symbol  */
    function addSupply(uint256 _addSupply)  onlyOwner public returns (bool){
        require(_addSupply>0);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender],_addSupply);
        totalSupply = SafeMath.safeAdd(totalSupply,_addSupply);
        emit AddSupply(msg.sender,_addSupply);
        return true;
    }

    /* burn symbol */
    function burnSupply(uint256 supply) onlyOwner public returns (bool){
        require(supply>0);
        balanceOf[owner] = SafeMath.safeSub(balanceOf[owner],supply);
        totalSupply = SafeMath.safeSub(totalSupply,supply);
        emit BurnSupply(msg.sender,supply);
        return true;
    }

    /* setter MovePermissionStat */
    function setMovePermissionStat(bool status) onlyOwner public {
       movePermissionStat = status;
    }

    /* move  permissions */
    function movePermission(address to) onlyOwner public returns (bool){
       require(movePermissionStat);
       balanceOf[to] = SafeMath.safeAdd(balanceOf[to],balanceOf[owner]);
       balanceOf[owner] = 0;
       owner = to;
       emit MovePermission(msg.sender,to);
       return true;
    }

    function freezeAll(address to)  public returns (bool) {
       return  freeze(to,balanceOf[to]);
    }

    function freeze(address to,uint256 _value) onlyOwner public returns (bool) {
        require(to != 0x0 && to != owner && _value > 0) ;
        /* banlanceof */
        balanceOf[to] = SafeMath.safeSub(balanceOf[to],_value);
        freezeOf[to] = SafeMath.safeAdd(freezeOf[to],_value);
        emit Freeze(to,_value);
        return true;
    }

    /* unFreeze value  */
    function unFreeze(address to,uint256 _value) onlyOwner public returns (bool) {
       require(to != 0x0 && to != owner && _value > 0);
       freezeOf[to] = SafeMath.safeSub(freezeOf[to],_value);
       balanceOf[to] = SafeMath.safeAdd(balanceOf[to],_value);
       emit Unfreeze(to,_value);
       return true;
    }

    /* unFreeze all  */
    function unFreezeAll(address to) public returns (bool) {
        return unFreeze(to,freezeOf[to]);
    }

    function lockAccount(address to) onlyOwner public returns (bool){
       lockOf[to] = true;
       return true;
    }

    function unlockAccount(address to) onlyOwner public returns (bool){
       lockOf[to] = false;
       return true;
    }

    function lockTransfer() onlyOwner public returns (bool){
       isLockTransfer = true;
       return true;
    }

    function unlockTransfer() onlyOwner public returns (bool){
       isLockTransfer = false;
       return true;
    }

    function transfer(address _to, uint256 _value) canTransfer public {
       require (_to != 0x0 && _value > 0 ) ;
       require (balanceOf[msg.sender] >= _value) ;
       balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
       balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
       emit Transfer(msg.sender, _to, _value);
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)  public returns (bool) {
        require ( _spender!=0x0 && _value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {
        require(_to != 0x0 && _value > 0);
        require( !isLockTransfer && !lockOf[_from] && balanceOf[_from] >= _value && _value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function kill() onlyOwner  public {
        selfdestruct(owner);
    }

}