pragma solidity ^0.4.18;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20{
    
  using SafeMath for uint256;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;

  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract RenCap is StandardToken {
    
    // Meta data
    
    string  public constant name        = "RenCap";
    string  public constant symbol      = "RNP";
    uint    public constant decimals    = 18;
    uint256 public etherRaised = 0;
    
    
    // Supply alocation and addresses

    uint public constant initialSupply  = 50000000 * (10 ** uint256(decimals));
    uint public salesSupply             = 25000000 * (10 ** uint256(decimals));
    uint public reserveSupply           = 22000000 * (10 ** uint256(decimals));
    uint public coreSupply              = 3000000  * (10 ** uint256(decimals));
    
    uint public stageOneCap             =  4500000 * (10 ** uint256(decimals));
    uint public stageTwoCap             = 13000000 * (10 ** uint256(decimals));
    uint public stageThreeCap           =  4400000 * (10 ** uint256(decimals));
    uint public stageFourCap            =  3100000 * (10 ** uint256(decimals));
    

    address public FundsWallet          = 0x6567cb2bfB628c74a190C0aF5745Ae1c090223a3;
    address public addressReserveSupply = 0x6567cb2bfB628c74a190C0aF5745Ae1c090223a3;
    address public addressSalesSupply   = 0x010AfFE21A326E327C273295BBd509ff6446F2F3;
    address public addressCoreSupply    = 0xbED065c02684364824749cE4dA317aC4231780AF;
    address public owner;
    
    
    // Dates

    uint public constant secondsInDay   = 86400; // 24hr * 60mnt * 60sec
    
    uint public stageOneStart           = 1523865600; // 16-Apr-18 08:00:00 UTC
    uint public stageOneEnd             = stageOneStart + (15 * secondsInDay);
  
    uint public stageTwoStart           = 1525680000; // 07-May-18 08:00:00 UTC
    uint public stageTwoEnd             = stageTwoStart + (22 * secondsInDay);
  
    uint public stageThreeStart         = 1528099200; // 04-Jun-18 08:00:00 UTC
    uint public stageThreeEnd           = stageThreeStart + (15 * secondsInDay);
  
    uint public stageFourStart          = 1530518400; // 02-Jul-18 08:00:00 UTC
    uint public stageFourEnd            = stageFourStart + (15 * secondsInDay);
    

    // constructor
    
    function RenCap() public {
        owner = msg.sender;
        
        totalSupply_                    = initialSupply;
        balances[owner]                 = reserveSupply;
        balances[addressSalesSupply]    = salesSupply;
        balances[addressCoreSupply]     = coreSupply;
        
        emit Transfer(0x0, owner, reserveSupply);
        emit Transfer(0x0, addressSalesSupply, salesSupply);
        emit Transfer(0x0, addressCoreSupply, coreSupply);
    }
    
    // Modifiers and Controllers
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onSaleRunning() {
        // Checks, if ICO is running and has not been stopped
        require(
            (stageOneStart   <= now  &&  now <=   stageOneEnd && stageOneCap   >= 0 &&  msg.value <= 1000 ether) ||
            (stageTwoStart   <= now  &&  now <=   stageTwoEnd && stageTwoCap   >= 0) ||
            (stageThreeStart <= now  &&  now <= stageThreeEnd && stageThreeCap >= 0) ||
            (stageFourStart  <= now  &&  now <=  stageFourEnd && stageFourCap  >= 0)
            );
        _;
    }
    
    
    
    // ExchangeRate
    
    function rate() public view returns (uint256) {
        if (stageOneStart   <= now  &&  now <=   stageOneEnd) return 1500;
        if (stageTwoStart   <= now  &&  now <=   stageTwoEnd) return 1300;
        if (stageThreeStart <= now  &&  now <= stageThreeEnd) return 1100;
            return 1030;
    }
    
    
    // Token Exchange
    
    function buyTokens(address _buyer, uint256 _value) internal {
        require(_buyer != 0x0);
        require(_value > 0);
        uint256 tokens =  _value.mul(rate());
      
        balances[_buyer] = balances[_buyer].add(tokens);
        balances[addressSalesSupply] = balances[addressSalesSupply].sub(tokens);
        etherRaised = etherRaised.add(_value);
        updateCap(tokens);
        
        owner.transfer(_value);
        emit Transfer(addressSalesSupply, _buyer, tokens );
    }
    
    // Token Cap Update

    function updateCap (uint256 _cap) internal {
        if (stageOneStart   <= now  &&  now <=   stageOneEnd) {
            stageOneCap = stageOneCap.sub(_cap);
        }
        if (stageTwoStart   <= now  &&  now <=   stageTwoEnd) {
            stageTwoCap = stageTwoCap.sub(_cap);
        }
        if (stageThreeStart   <= now  &&  now <=   stageThreeEnd) {
            stageThreeCap = stageThreeCap.sub(_cap);
        }
        if (stageFourStart   <= now  &&  now <=   stageFourEnd) {
            stageFourCap = stageFourCap.sub(_cap);
        }
    }
    
    
    // Fallback function
    
    function () public onSaleRunning payable {
        require(msg.value >= 100 finney);
        buyTokens(msg.sender, msg.value);
    }
  
}