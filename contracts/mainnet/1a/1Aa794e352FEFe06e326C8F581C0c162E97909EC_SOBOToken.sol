pragma solidity ^0.4.11;


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

contract SOBOToken {
    
    using SafeMath for uint256;
    
    string public name = "SOBO";      //  token name
    
    string public symbol = "SOBO";           //  token symbol
    
    uint256 public decimals = 8;            //  token digit

    mapping (address => uint256) public balanceOf;
    
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (address => uint256) public frozenBalances;
    
    mapping (address => uint256) public initTimes;
    
    mapping (address => uint) public initTypes;
    
    uint256 public totalSupply = 0;

    uint256 constant valueFounder = 5000000000000000000;
    
    address owner = 0x0;
    
    address operator = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }
    
    modifier isOperator {
        assert(operator == msg.sender);
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burn(address indexed from, uint256 value);

    constructor() public {
        owner = msg.sender;
        operator = msg.sender;
        totalSupply = valueFounder;
        balanceOf[msg.sender] = valueFounder;
        emit Transfer(0x0, msg.sender, valueFounder);
    }
    
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_to != 0x0);
        require(canTransferBalance(_from) >= _value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) validAddress public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) validAddress public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) validAddress public returns (bool success) {
        require(canTransferBalance(msg.sender) >= _value);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function burn(uint256 _value) validAddress public  returns (bool success) {
        require(canTransferBalance(msg.sender) >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }

    function initTransferArr(address[] _arr_addr, uint256[] _arr_value,uint[] _arr_initType) validAddress isOperator public returns (bool success) {
        require(_arr_addr.length == _arr_value.length && _arr_value.length == _arr_initType.length);
        require(_arr_addr.length > 0 && _arr_addr.length < 100);
        for (uint i = 0; i < _arr_addr.length ; ++i) {
            initTransfer(_arr_addr[i],_arr_value[i],_arr_initType[i]);
        }
        return true;
    }

    function initTransfer(address _to, uint256 _value, uint _initType) validAddress isOperator public returns (bool success) {
        require(_initType == 0x1 || _initType == 0x2);
        require(initTypes[_to]==0x0);
        frozenBalances[_to] = _value;
        initTimes[_to] = now;
        initTypes[_to] = _initType;
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function canTransferBalance(address addr) public view returns (uint256){
        if(initTypes[addr]==0x0){
            return balanceOf[addr];
        }else{
            uint256 s = now.sub(initTimes[addr]);
            if(initTypes[addr]==0x1){
                if(s >= 513 days){
                    return balanceOf[addr];    
                }else if(s >= 183 days){
                    return balanceOf[addr].sub(frozenBalances[addr]).add(frozenBalances[addr].div(12).mul((s.sub(183 days).div(30 days) + 1)));
                }else{
                    return balanceOf[addr].sub(frozenBalances[addr]);
                }
            }else if(initTypes[addr]==0x2){
                if(s >= 243 days){
                    return balanceOf[addr];    
                }else if(s >= 93 days){
                    return balanceOf[addr].sub(frozenBalances[addr]).add(frozenBalances[addr].div(6).mul((s.sub(93 days).div(30 days) + 1)));
                }else{
                    return balanceOf[addr].sub(frozenBalances[addr]);
                }
            }else{
                return 0;
            }
        }
    }
    
    function setOperator(address addr) validAddress isOwner public {
        operator = addr;
    }
    
}