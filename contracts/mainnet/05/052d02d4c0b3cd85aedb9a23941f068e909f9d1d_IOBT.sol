pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b > 0); 
      uint256 c = a / b;
      assert(a == b * c + a % b); 
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


  function Ownable() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract ERC20Standard {


    // total amount of tokens
    function totalSupply() public constant returns (uint256) ;

    /*
     *  Events
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /*
     *  Public functions
     */
    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool);


    function approve(address _spender, uint256 _value) public  returns (bool);

    function balanceOf(address _owner) public constant returns (uint256);

    function allowance(address _owner, address _spender) public constant returns (uint256);
}

contract ERC20StandardToken is ERC20Standard {
    using SafeMath for uint256;

    /*
     *  Storage
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;


    function transfer(address to, uint256 value) public returns (bool){
        require(to !=address(0));
        require(value<=balances[msg.sender]);

        balances[msg.sender]=balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender,to,value);
        return true;
    }


    function transferFrom(address from, address to, uint256 value) public returns (bool){
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowances[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;

    }

    function approve(address spender, uint256 value) public returns (bool){
        require((value == 0) || (allowances[msg.sender][spender] == 0));
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public constant returns (uint256){
        return allowances[owner][spender];
    }


    function balanceOf(address owner) public constant returns (uint256){
        return balances[owner];
    }
}

contract IOBT is ERC20StandardToken, Ownable {

    // token information
    string public constant name = "Internet of Blockchain Token";
    string public constant symbol = "IOBT";
    uint8 public constant decimals = 18;
    uint256 TotalTokenSupply=5*(10**8)*(10**uint256(decimals));

     function totalSupply() public constant returns (uint256 ) {
          return TotalTokenSupply;
      }

    /// transfer all tokens to holders
    address public constant MAIN_HOLDER_ADDR=0x7e647B726052238AE2439BD36257C2a2bB283dDa;


    function IOBT() public onlyOwner{
        balances[MAIN_HOLDER_ADDR]+=TotalTokenSupply;
        emit Transfer(0,MAIN_HOLDER_ADDR,TotalTokenSupply);
      }
}