pragma solidity 0.4.24;

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

contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract KNOWToken is ERC20
{
    using SafeMath for uint256;
    // Name of the token
    string public constant name = "KNOW Token";

    // Symbol of token
    string public constant symbol = "KNOW";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 18300000000 * 10 ** 18; // 18 billion total supply // muliplies dues to decimal precision
    address public owner;                    // Owner of this contract
    uint256 no_of_tokens;
    uint256 total_token;
    bool stopped = false;
    bool checkTransfer = false;
    uint256 public lockup_startdate;
    uint256 public lockup_enddate;
    uint256 public eth_received; // total ether received in the contract
    uint256 transferPercent;
    uint256 transferPercentTotal;
    uint256 transferDays;
    uint256 transferDaysTotal;
    uint256 transferLastTransaction;
    uint256 transferTotalSpent;
    uint256 transferPostDate;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => bool) addOfPrivateSale;
    mapping(address => bool) addOfContributors;
    mapping(address => bool) addOfContributors2;
    mapping(address => bool) addOfTechOperation;
    mapping(address => bool) addOfMarketingBusinessDev;
    mapping(address => bool) addOfEarlyInvestor;
    mapping(address => bool) addOfOwners;
    
    event EventPrivateSale(address indexed _PrivateSale, bool _status);
    event EventContributors(address indexed _Contributors, bool _status);
    event EventContributors2(address indexed _Contributors2, bool _status);
    event EventTechOperation(address indexed _TechOperation, bool _status);
    event EventMarketingBusinessDev(address indexed _MarketingBusinessDev, bool _status);
    event EventEarlyInvestor(address indexed _EarlyInvestor, bool _status);
    
    mapping(address => LockupHolderDetails) lockupHolderMap;
    
    struct LockupHolderDetails{
      uint transferPercent;
      uint transferDays;
      uint transferPercentTotal;
      uint transferDaysTotal;
      uint transferLastTransaction;
      uint transferTotalSpent;
      uint transferPostDate;
      bool reset;
    }
        
    enum Stages {
        LOCKUPNOTSTARTED,
        LOCKUPSTARTED,
        LOCKUPENDED
    }
    
    Stages public stage;
    
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            // Contract not in expected state
            revert();
        _;
    }
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }


    function KNOWToken() public
    {
        owner = msg.sender;
        stage = Stages.LOCKUPNOTSTARTED;
        
        uint256 _transfertoPrivateSale = 2745000000 * 10 ** 18; // 15% to Private Sale
        uint256 _transfertoContributors = 10980000000 * 10 ** 18; // 60% to Contributors
        uint256 _transfertoContributors2 = 1830000000 * 10 ** 18; // 10% to Contributors 2
        uint256 _transfertoTechOperationExpenses = 915000000 * 10 ** 18; // 5% to Tech & Operation Expenses
        uint256 _transfertoMarketingBusinessDev = 915000000 * 10 ** 18; // 5% to Marketing & Business Development
        uint256 _transfertoEarlyInvestors = 915000000 * 10 ** 18; // 5% to Early Investors
        
        // 15% to Private Sale
        balances[0x8eeC67a193B6B90A4B0047769De8F17a7ee87eB9] = _transfertoPrivateSale;
        Transfer(address(0), 0x8eeC67a193B6B90A4B0047769De8F17a7ee87eB9, _transfertoPrivateSale);
        
        // 60% to Contributors
        balances[0xc7991555F9F2E731bb2013cfB0ac2dcf6dc4A236] = _transfertoContributors;
        Transfer(address(0), 0xc7991555F9F2E731bb2013cfB0ac2dcf6dc4A236, _transfertoContributors);
        
        // 10% to Contributors 2
        balances[0xf26511984b53bf4b96d85355224E06a06180237F] = _transfertoContributors2;
        Transfer(address(0), 0xf26511984b53bf4b96d85355224E06a06180237F, _transfertoContributors2);
        
        // 5% to Tech & Operation Expenses
        balances[0xDd695A5b4594ad79e3D9cE5280f0A36fde72C70A] = _transfertoTechOperationExpenses;
        Transfer(address(0), 0xDd695A5b4594ad79e3D9cE5280f0A36fde72C70A, _transfertoTechOperationExpenses);
        
        // 5% to Marketing & Business Development
        balances[0x84B899f535b7128fEC47e53901cE3242CdC9C06f] = _transfertoMarketingBusinessDev;
        Transfer(address(0), 0x84B899f535b7128fEC47e53901cE3242CdC9C06f, _transfertoMarketingBusinessDev);
        
        // 5% to Early Investors
        balances[0xeD9200CffFBe17af59D288836a9B25520c6CeFa1] = _transfertoEarlyInvestors;
        Transfer(address(0), 0xeD9200CffFBe17af59D288836a9B25520c6CeFa1, _transfertoEarlyInvestors);
    }
    
    function () public payable 
    {
        revert();
        //Not Applicable   
    }
    
     // Start lockup periods
     function start_LOCKUP(uint _lockupEndDate) public onlyOwner atStage(Stages.LOCKUPNOTSTARTED)
     {
          stage = Stages.LOCKUPSTARTED;
          stopped = false;
          lockup_startdate = now;
          lockup_enddate = now + _lockupEndDate * 86400;
     }

     // End lockup periods
     function end_LOCKUP() external onlyOwner atStage(Stages.LOCKUPSTARTED)
     {
         require(now > lockup_enddate);
         stage = Stages.LOCKUPENDED;
     }
     
     // Add address to Private Sale
     function addtoPrivateSale(address _address, uint _transferPercent, uint _transferPercentTotal) public onlyOwner {
        addOfPrivateSale[_address] = true;
        emit EventPrivateSale(_address, true);
        lockupHolderMap[_address] = LockupHolderDetails({
                transferPercent: _transferPercent,
                transferDays: 1,
                transferPercentTotal: _transferPercentTotal,
                transferDaysTotal: 365,
                transferLastTransaction: 0,
                transferTotalSpent: 0,
                transferPostDate: now,
                reset: true
                });
     }
     
     // Add address to Contributors
     function addtoContributos(address _address, uint _transferPercent, uint _transferPercentTotal) public onlyOwner {
        addOfContributors[_address] = true;
        emit EventContributors(_address, true);
        lockupHolderMap[_address] = LockupHolderDetails({
                transferPercent: _transferPercent,
                transferDays: 1,
                transferPercentTotal: _transferPercentTotal,
                transferDaysTotal: 365,
                transferLastTransaction: 0,
                transferTotalSpent: 0,
                transferPostDate: now,
                reset: true
                });
     }
     
     // Add address to Contributors2
     function addtoContributos2(address _address, uint _transferPercent, uint _transferPercentTotal) public onlyOwner {
        addOfContributors2[_address] = true;
        emit EventContributors2(_address, true);
        lockupHolderMap[_address] = LockupHolderDetails({
                transferPercent: _transferPercent,
                transferDays: 1,
                transferPercentTotal: _transferPercentTotal,
                transferDaysTotal: 365,
                transferLastTransaction: 0,
                transferTotalSpent: 0,
                transferPostDate: now,
                reset: true
                });
     }
     
     // Add address to Tech & Operation
     function addtoTechOperation(address _address, uint _transferPercent, uint _transferPercentTotal) public onlyOwner {
        addOfTechOperation[_address] = true;
        emit EventTechOperation(_address, true);
        lockupHolderMap[_address] = LockupHolderDetails({
                transferPercent: _transferPercent,
                transferDays: 1,
                transferPercentTotal: _transferPercentTotal,
                transferDaysTotal: 365,
                transferLastTransaction: 0,
                transferTotalSpent: 0,
                transferPostDate: now,
                reset: true
                });
     }
     
     // Add address to Marketing & Business Development
     function addtoMarketingBusinessDev(address _address, uint _transferPercent, uint _transferPercentTotal) public onlyOwner {
        addOfMarketingBusinessDev[_address] = true;
        emit EventMarketingBusinessDev(_address, true);
        lockupHolderMap[_address] = LockupHolderDetails({
                transferPercent: _transferPercent,
                transferDays: 1,
                transferPercentTotal: _transferPercentTotal,
                transferDaysTotal: 365,
                transferLastTransaction: 0,
                transferTotalSpent: 0,
                transferPostDate: now,
                reset: true
                });
     }
     
     // Add address to Early Investors
     function addtoEarlyInvestors(address _address, uint _transferPercent, uint _transferPercentTotal) public onlyOwner{
        addOfEarlyInvestor[_address] = true;
        emit EventEarlyInvestor(_address, true);
        lockupHolderMap[_address] = LockupHolderDetails({
                transferPercent: _transferPercent,
                transferDays: 1,
                transferPercentTotal: _transferPercentTotal,
                transferDaysTotal: 365,
                transferLastTransaction: 0,
                transferTotalSpent: 0,
                transferPostDate: now,
                reset: true
                });
     }
     
     // Add owners
     function addtoOwners(address _address) public onlyOwner{
        addOfOwners[_address] = true;
     }
   
     // what is the total supply of the ech tokens
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalsupply;
     }
    
     // What is the balance of a particular account?
     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
     
     // Send _value amount of tokens from address _from to address _to
     // The transferFrom method is used for a withdraw workflow, allowing contracts to send
     // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     // fees in sub-currencies; the command should fail unless the _from account has
     // deliberately authorized the sender of the message via some mechanism; we propose
     // these standardized APIs for approval:
     function transferFrom(address _from, address _to, uint256 _amount)public returns (bool success) {
         require( _to != 0x0);
         checkTransfer = false;
         
         if(addOfOwners[_from]) {
             checkTransfer = true;
         } else
         if(addOfPrivateSale[_from]) {
             require(checkTransferFunctionPrivateSale(_from, _to, _amount));
         } else
         if(addOfContributors[_from]) {
             checkTransfer = true;
         } else
         if(addOfContributors2[_from] || addOfTechOperation[_from] || addOfMarketingBusinessDev[_from] || addOfEarlyInvestor[_from]) {
             require(checkTransferFunction(_from, _to, _amount));
         } 
         
         require(checkTransfer == true);
         require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
         balances[_from] = (balances[_from]).sub(_amount);
         allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
         balances[_to] = (balances[_to]).add(_amount);
         Transfer(_from, _to, _amount);
         return true;
     }
     
     function checkTransferFunction(address _from, address _to, uint256 _amount) internal returns (bool success) {
             
             require(now > lockup_enddate);
             
             transferDaysTotal = lockupHolderMap[_from].transferDaysTotal * 86400;
             transferPostDate = lockupHolderMap[_from].transferPostDate;
             
             if(now >= transferPostDate + transferDaysTotal) {
                 lockupHolderMap[_from].transferPostDate = lockupHolderMap[_from].transferPostDate + transferDaysTotal;
                 lockupHolderMap[_from].transferTotalSpent = 0;
             }
             
             transferPercent = lockupHolderMap[_from].transferPercent;
             transferPercentTotal = lockupHolderMap[_from].transferPercentTotal;
             transferDays = lockupHolderMap[_from].transferDays * 86400;
             transferDaysTotal = lockupHolderMap[_from].transferDaysTotal * 86400;
             transferLastTransaction = lockupHolderMap[_from].transferLastTransaction;
             transferTotalSpent = lockupHolderMap[_from].transferTotalSpent;
             transferPostDate = lockupHolderMap[_from].transferPostDate;
             
             require((_amount * 10 ** 18) <= ((_totalsupply).mul(transferPercent)).div(100));
             require((_amount * 10 ** 18) <= ((_totalsupply).mul(transferPercentTotal)).div(100));
             
             require(now >= transferLastTransaction + transferDays);
             require((transferTotalSpent * 10 ** 18) <= ((_totalsupply).mul(transferPercentTotal)).div(100));
             require(now <= transferPostDate + transferDaysTotal);
             
             lockupHolderMap[_from].transferLastTransaction = now;
             lockupHolderMap[_from].transferTotalSpent += _amount;
             
             checkTransfer = true;
             return true;
     }
     
     function checkTransferFunctionPrivateSale(address _from, address _to, uint256 _amount) internal returns (bool success) {
             
             require(stage == Stages.LOCKUPENDED);
             require(now > lockup_enddate);
            
             transferPercent = lockupHolderMap[_from].transferPercent;
             transferDays = lockupHolderMap[_from].transferDays * 86400;
             transferLastTransaction = lockupHolderMap[_from].transferLastTransaction;
             transferTotalSpent = lockupHolderMap[_from].transferTotalSpent;
             
             require((_amount * 10 ** 18) <= ((_totalsupply).mul(transferPercent)).div(100));
             
             require(now >= transferLastTransaction + transferDays);
             
             lockupHolderMap[_from].transferLastTransaction = now;
             
             checkTransfer = true;
             return true;
     }
     
    
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount)public returns (bool success) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
     
     
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
     }

     // Transfer the balance from owner&#39;s account to another account
     function transfer(address _to, uint256 _amount)public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
             return true;
     }
    
     // Transfer the balance from owner&#39;s account to another account
    function transferTokens(address _to, uint256 _amount) private returns(bool success) {
        require( _to != 0x0);       
        require(balances[address(this)] >= _amount && _amount > 0);
        balances[address(this)] = (balances[address(this)]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(address(this), _to, _amount);
        return true;
     }
 
     // Drain all coins 
     function drain() external onlyOwner {
        owner.transfer(this.balance);
     }
    
}