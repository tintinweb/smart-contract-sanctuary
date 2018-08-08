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

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract frozen is owned {

    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    modifier isFrozen(address _target) {
        require(!frozenAccount[_target]);
        _;
    }

    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }
}

contract XYCCTEST is frozen{
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 8;  
    uint256 public totalSupply;
    uint256 public lockPercent = 95;
    
    mapping (address => uint256) public balanceOf;
    
    mapping(address => uint256) freezeBalance;
    mapping(address => uint256) public preTotalTokens;

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function XYCCTEST() public {
        totalSupply = 1000000000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;                
        name = "llltest";                                   
        symbol = "lllt";                               
    }

    function _transfer(address _from, address _to, uint _value) internal isFrozen(_from) isFrozen(_to){
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        if(freezeBalance[_from] > 0){
            freezeBalance[_from] = preTotalTokens[_from].mul(lockPercent).div(100);
            require (_value <= balanceOf[_from].sub(freezeBalance[_from])); 
        }
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    
    function lock(address _to, uint256 _value) public onlyOwner isFrozen(_to){
        _value = _value.mul(10 ** uint256(decimals));
		require(balanceOf[owner] >= _value);
		require (balanceOf[_to].add(_value)> balanceOf[_to]); 
		require (_to != 0x0);
		uint previousBalances = balanceOf[owner].add(balanceOf[_to]);
        balanceOf[owner] = balanceOf[owner].sub(_value);
        balanceOf[ _to] =balanceOf[_to].add(_value);
        preTotalTokens[_to] = preTotalTokens[_to].add(_value);
        freezeBalance[_to] = preTotalTokens[_to].mul(lockPercent).div(100);
	    emit Transfer(owner, _to, _value);
	    assert(balanceOf[owner].add(balanceOf[_to]) == previousBalances);
    }
    
    function updataLockPercent() external onlyOwner {
        require(lockPercent > 0);
        lockPercent = lockPercent.sub(5);
    }

}