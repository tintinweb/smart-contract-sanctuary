pragma solidity >=0.4.22 <0.7.0;


contract Ownable {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


library SafeMath {
  
   function times(uint256 a, uint256 b) 
     internal
     pure
     returns (uint256 c) 
  {
    c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint256 a, uint256 b) 
    internal 
    pure 
  returns (uint256 c) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint256 a, uint256 b) 
    internal 
    pure 
  returns (uint256 c) {
    c = a + b;
    assert(c>=a);
    return c;
  }

}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function totalSupply() external view returns (uint256);    
    function allowance (address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Topswap is ERC20, Ownable {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 internal totalSupply_;
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    
    event Mint(address indexed to, uint256 amount);
    event Burn(uint256 amount);
    
    constructor(uint256 initialSupply, string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }
  
    function mint(address _to, uint256 _amount)
      onlyOwner
      public
    {
      totalSupply_ = totalSupply_.plus(_amount);
      balances[_to] = balances[_to].plus(_amount);
      emit Mint(_to, _amount);
      emit Transfer(address(0), _to, _amount);
    }

    function burn(uint256 _amount)
      onlyOwner
      public
    {
      totalSupply_ = totalSupply_.minus(_amount);
      balances[msg.sender] = balances[msg.sender].minus(_amount);
      emit Burn(_amount);
      emit Transfer(msg.sender, address(0), _amount);
    }
    
    
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value)
      public
      returns(bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].minus(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)
      public 
      returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) 
      public 
      view 
      returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint256 _addedValue) 
      public 
      returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].plus(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) 
      public 
      returns(bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        }else {
            allowed[msg.sender][_spender] = oldValue.minus(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function isToken() 
        public 
        view 
        returns (bool)
    {
        return true;
    }
    
}