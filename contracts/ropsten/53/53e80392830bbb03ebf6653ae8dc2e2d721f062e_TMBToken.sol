pragma solidity ^0.4.24;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
 
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
 
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
 
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
 
contract BurnableToken is StandardToken {
 
  function burn(uint256 _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint256 indexed value);
}

contract TMBToken is BurnableToken {
    
  string public constant name = "Teambrella Token";
    
  string public constant symbol = "TMB";
    
  uint32 public constant decimals = 3;
    
  uint256 public constant INITIAL_SUPPLY = 175000E3;  // 100 eth hardcap is 10M tokens + max 20% of presale cap (25 eth) + 40% to company and partners = 175K tokens
    
  bool public stopped = true;
  address public owner;
    
  modifier isRunning() {
    if (stopped) {
        if (msg.sender != owner)
            revert();
      }
    _;
  }

  constructor() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
  
  function start() public {
    require(msg.sender == owner);
    stopped = false;
  }

  function transfer(address _to, uint256 _value) public isRunning returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public isRunning returns (bool) {
    return super.approve(_spender, _value);
  }  
}

contract TMBTokenSale {
    
    using SafeMath for uint256;
    
    address public multisigOwner;

    address public multisigFunds;
    address public company;
    address public partners;
    
    // uint256 public constant rate = 1000;

    uint256 public constant soldPercent = 60;
    uint256 public constant partnersPercent = 5;
    uint256 public constant companyPercent = 35;

    uint256 public constant softcap = 20 * 1 ether;
    uint256 public constant presalecap = 25 * 1 ether;
    uint256 public constant hardcap = 100 * 1 ether;
 
    uint256 public constant startPresale = 1530947400; // 2018-07-07 14:10
    uint256 public constant endPresale = 1530951000; // 2018-07-07 15:10

    uint256 public constant startSale = 1530951300; // 2018-07-07 15:15
    uint256 public constant endSale = 1530954900; // 2018-07-07 16:15

    TMBToken public token = new TMBToken();

    bool public stoppedSale = false;
    bool public stoppedPresale = false;

    uint256 public receivedEth = 0;
    uint256 public deliveredEth = 0;
    
    uint256 public issuedTokens;
 
    mapping(address => uint256) public preBalances;
    mapping(address => uint256) public saleBalances;
    
    enum State{
       Running,
       Finished,
       CompanyTokensIssued
    }
    
    State tokensaleState = State.Running;
    
    event ReservedPresale(address indexed to, uint256 value);
    event ReservedSale(address indexed to, uint256 value);
    event Issued(address indexed to, uint256 value);
    event Refunded(address indexed to, uint256 value);

    constructor() public {
        
        multisigOwner = msg.sender; // todo - change this to multisig address

        multisigFunds = 0xD833D2F16725fD982B696fb6E22edcf5BdBF2013;
        company = 0x2b749333Ecbc6FfeC4afa87833708C1e834a5bF8;
        partners = 0xAD7A0cBc865Dda6d7da5FF30F9bc16F768139FA4;

    }
 
    modifier isAfterPresale() {
    	require(now > endPresale || (stoppedPresale && now > startPresale));
    	_;
    }

    modifier isAfterSale() {
    	require(now > endSale || (stoppedSale && now > startSale));
    	_;
    }
	
    modifier isAboveSoftCap() {
        require(receivedEth >= softcap);
        _;
    }

    modifier onlyOwner() {
        require(multisigOwner == msg.sender);
        _;
    }
    
    function() external payable {
      reserveFunds();
    }

   function reserveFunds() public payable {
       
       uint256 _value = msg.value;
       address _addr = msg.sender;
       
       require (!isContract(_addr));
       require(_value >= 1 * 1 ether);
       
       uint256 _totalFundedEth;
       
       if (!stoppedPresale && now > startPresale && now < endPresale)
       {
           _totalFundedEth = preBalances[_addr].add(_value);
           require(_totalFundedEth <= 10 * 1 ether);
           preBalances[_addr] = _totalFundedEth;
           receivedEth = receivedEth.add(_value);
           emit ReservedPresale(_addr, _value);
       }
       else if (!stoppedSale && now > startSale && now < endSale)
       {
           _totalFundedEth = saleBalances[_addr].add(_value);
           require(_totalFundedEth <= 15 * 1 ether);
           saleBalances[_addr] = _totalFundedEth;
           receivedEth = receivedEth.add(_value);
           emit ReservedSale(_addr, _value);
       }
       else
       {
           revert();
       }
    }

    function stopPresale() public onlyOwner {
        stoppedPresale = true;
    }
    
    function stopSale() public onlyOwner {
        stoppedSale = true;
    }

    function isContract(address _addr) constant internal returns(bool) {
	    uint256 size;
	    if (_addr == 0) return false;
	    assembly {
		    size := extcodesize(_addr)
	    }
	    return size > 0;
    }

    function issueTokens(address _addr, uint256 _valTokens) internal {

        token.transfer(_addr, _valTokens);
        issuedTokens = issuedTokens.add(_valTokens);
        emit Issued(_addr, _valTokens);
    }

    function deliverPresale(address _addr, uint256 _valEth) internal {

        uint256 _issuedTokens = _valEth * 1200; // _valEth * rate + 20% presale bonus, rate == 1000
        uint256 _newDeliveredEth = deliveredEth.add(_valEth);
        require(_newDeliveredEth < presalecap);
        multisigFunds.transfer(_valEth);
        deliveredEth = _newDeliveredEth;

        issueTokens(_addr, _issuedTokens);
    }
    
    function deliverSale(address _addr, uint256 _valEth) internal {

        uint256 _issuedTokens = _valEth * 1000; // _valEth * rate, rate == 1000
        uint256 _newDeliveredEth = deliveredEth.add(_valEth);
        require(_newDeliveredEth < hardcap);
        multisigFunds.transfer(_valEth);
        deliveredEth = _newDeliveredEth;

        issueTokens(_addr, _issuedTokens);
    }
    
    // everyone is able to withdraw his own money if no softcap
    function refund() public isAfterSale {
        require(receivedEth < softcap);
        uint256 _value = preBalances[msg.sender]; 
        _value += saleBalances[msg.sender]; 
        if (_value > 0)
        {
            preBalances[msg.sender] = 0;
            saleBalances[msg.sender] = 0; 
            msg.sender.transfer(_value);
            emit Refunded(msg.sender, _value);
        }
    }

    function issueTokensPresale(address _addr, uint256 _val) public onlyOwner isAfterPresale isAboveSoftCap {

        require(_val >= 0);
        require(tokensaleState == State.Running);
        
        uint256 _fundedEth = preBalances[_addr];
        if (_fundedEth > 0)
        {
            if (_fundedEth > _val)
            {
                // rollback the rest of funds
                uint256 _refunded = _fundedEth.sub(_val);
                _addr.transfer(_refunded);
                emit Refunded(_addr, _refunded);
                _fundedEth = _val;
            }

            if (_fundedEth > 0)
            {
                deliverPresale(_addr, _fundedEth);
            }
            preBalances[_addr] = 0;
        }
    }

    function issueTokensSale(address _addr, uint256 _val) public onlyOwner isAfterSale isAboveSoftCap {

        require(_val >= 0);
        require(tokensaleState == State.Running);
        
        uint256 _fundedEth = saleBalances[_addr];
        if (_fundedEth > 0)
        {
            if (_fundedEth > _val)
            {
                // rollback the rest of funds
                uint256 _refunded = _fundedEth.sub(_val);
                _addr.transfer(_refunded);
                emit Refunded(_addr, _refunded);
                _fundedEth = _val;
            }

            if (_fundedEth > 0)
            {
                deliverSale(_addr, _fundedEth);
            }
            saleBalances[_addr] = 0;
        }
    }

    function issueTokensPresale(address[] _addrs) public onlyOwner isAfterPresale isAboveSoftCap {

        require(tokensaleState == State.Running);

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = preBalances[_addr];
            if (_fundedEth > 0)
            {
                deliverPresale(_addr, _fundedEth);
                preBalances[_addr] = 0;
            }            
        }
    }

    function issueTokensSale(address[] _addrs) public onlyOwner isAfterSale isAboveSoftCap {

        require(tokensaleState == State.Running);

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = saleBalances[_addr];
            if (_fundedEth > 0)
            {
                deliverSale(_addr, _fundedEth);
                saleBalances[_addr] = 0;
            }            
        }
    }
    
    function refundTokensPresale(address[] _addrs) public onlyOwner isAfterPresale {

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = preBalances[_addr];
            if (_fundedEth > 0)
            {
                _addr.transfer(_fundedEth);
                emit Refunded(_addr, _fundedEth);
                preBalances[_addr] = 0;
            }
        }
    }

    function refundTokensSale(address[] _addrs) public onlyOwner isAfterSale {

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = saleBalances[_addr];
            if (_fundedEth > 0)
            {
                _addr.transfer(_fundedEth);
                emit Refunded(_addr, _fundedEth);
                saleBalances[_addr] = 0;
            }
        }
    }

    function finalize() public onlyOwner isAfterSale isAboveSoftCap {

        require(tokensaleState == State.Running);

        tokensaleState = State.Finished;
        
        uint256 _soldTokens = issuedTokens;
        
        // transfer tokens to partners
        uint256 _partnersTokens = _soldTokens * partnersPercent / soldPercent;
        issueTokens(partners, _partnersTokens);

        // burn everything but issued (sold + partners) and company&#39;s reserve
        uint256 _tokensToBurn = token.INITIAL_SUPPLY().sub(issuedTokens).sub(_soldTokens * companyPercent / soldPercent);
        token.burn(_tokensToBurn);
        token.start();
    }

    /* Only possible to call it in 1 days after the token sale ends */
    function issueCompanyTokens() public onlyOwner isAboveSoftCap {

        require(tokensaleState == State.Finished && now > endSale + 1 days);
        
        // the rest of tokens is exactly the company&#39;s amount
        uint256 _companyTokens = token.balanceOf(this);
        issueTokens(company, _companyTokens);
        
        tokensaleState == State.CompanyTokensIssued;
    }
}