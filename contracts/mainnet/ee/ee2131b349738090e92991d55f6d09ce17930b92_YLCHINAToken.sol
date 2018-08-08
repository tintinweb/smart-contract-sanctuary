pragma solidity ^0.4.23;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    address a = address(0xA9802C071dD0D9fC470A06a487a2DB3D938a7b02);
    owner = a;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract YLCHINAToken is Ownable{
    
    using SafeMath for uint256;
    
    string public constant name       = "YLCHINA";
    string public constant symbol     = "DYLC";
    uint32 public constant decimals   = 18;
    uint256 public totalSupply        = 5000000000 ether;
    uint256 public currentTotalAirdrop = 0;
    uint256 totalAirdrop              = 2880000 ether;
    uint256 startBalance              = 288 ether;
    
    mapping(address => bool) touched;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() public {
        balances[owner] = totalSupply - totalAirdrop;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        if( !touched[msg.sender] && currentTotalAirdrop < totalAirdrop ){
            balances[msg.sender] = balances[msg.sender].add( startBalance );
            touched[msg.sender] = true;
            currentTotalAirdrop = currentTotalAirdrop.add( startBalance );
        }
        
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
    
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
        require(_value <= allowed[_from][msg.sender]);
        
        if( !touched[_from] && currentTotalAirdrop < totalAirdrop ){
            touched[_from] = true;
            balances[_from] = balances[_from].add( startBalance );
            currentTotalAirdrop = currentTotalAirdrop.add( startBalance );
        }
        
        require(_value <= balances[_from]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
     }

    function getBalance(address _a) internal constant returns(uint256)
    {
        if( currentTotalAirdrop < totalAirdrop ){
            if( touched[_a] )
                return balances[_a];
            else
                return balances[_a].add( startBalance );
        } else {
            return balances[_a];
        }
    }
    

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return getBalance( _owner );
    }
}