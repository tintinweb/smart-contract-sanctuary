contract ERC20CompatibleToken {
    using SafeMath for uint;

    mapping(address => uint) balances; // List of user balances.

    event Transfer(address indexed from, address indexed to, uint value);
  	event Approval(address indexed owner, address indexed spender, uint value);

  	mapping (address => mapping (address => uint)) internal allowed;

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

}


contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address _who) public view returns (uint);
    function transfer(address _to, uint _value) public returns(bool);
    function transfer(address _to, uint _value, bytes _data) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}





















contract GamingTableToken is ERC223Interface,ERC20CompatibleToken,Ownable {
    using SafeMath for uint;
    
    string public name    = "Gaming Table Token";
    string public symbol  = "GTT";
    uint public decimals = 18;
    uint public totalSupply;
    
    uint private initialAmount=1000*10000 * 1 ether;
    uint private maxTotalSupply = 2000*10000*1 ether;
    
    uint public lastMinedBlock;
    
    address poolWallet;
    
    modifier mine() {
        //if(totalSupply + _minedTokens > 2000*10000*1 ether + 120000){
        if(totalSupply < maxTotalSupply){
            uint _minedTokens=(block.number-lastMinedBlock)*160 * 1 ether;
            lastMinedBlock=block.number;
            if(totalSupply.add(_minedTokens) > maxTotalSupply){
                _minedTokens=maxTotalSupply.sub(totalSupply);
                totalSupply=maxTotalSupply;
                balances[poolWallet]=balances[poolWallet].add(_minedTokens);
            }else{
                totalSupply+=_minedTokens;
                balances[poolWallet]=balances[poolWallet].add(_minedTokens);
            }
        }

        _;
    }

    constructor(address pool) public {
        poolWallet=pool;
        lastMinedBlock=block.number;
        totalSupply = initialAmount;
        
		balances[owner]=totalSupply;
        emit Transfer(this,owner,totalSupply);
    }
   
    function name() public view returns(string){return name;}
    function symbol() public view returns(string){return symbol;}
    function decimals() public view returns(uint){return decimals;}
    function totalSupply() public view returns(uint256 _totalSupply){return totalSupply;}


    function balanceOf(address _who) public view returns(uint){
        return balances[_who];
    }
    
    /*  ERC223 Transfer */
    function transfer(address _to, uint256 _value,bytes _data) public mine returns (bool) {
        require(_to != address(0));
        require(_value >= 0);
        require(_value <= balances[msg.sender]);

        if(isContract(_to)){
            return transferToContract(_to, _value, _data);
        }else{
            return transferToAddress(_to, _value);
        }
    }
    
    /*  Added due to backwards ERC20 compatibility reasons. */
    function transfer(address _to, uint256 _value) public mine returns (bool) {
        require(_to != address(0));
        require(_value >= 0);
        require(_value <= balances[msg.sender]);

        bytes memory empty;
        if(isContract(_to)){
            return transferToContract(_to, _value, empty);
        }else{
            return transferToAddress(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) mine public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        
        bytes memory empty;

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value,empty);
        return true;
    }
    
    function updateTotalSupply() mine public returns (bool) {
        return true;
    }

    
    /* ERC233 => msg.sender is account or contract*/
    function isContract(address _addr) internal view returns(bool) {
        uint length; assembly {length := extcodesize(_addr) }
        return (length>0);
    }
    
    
    function transferToAddress(address _to, uint _value) private returns (bool success){
        require(balances[msg.sender] >= _value);
        
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;

    }
    
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success){
        require(balances[msg.sender] >= _value);
        
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        
        
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data); 

        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }
 
}

/* ************************************************************************ */

interface ContractReceiver{
    function tokenFallback(address _from,uint _value, bytes _data) external;
}