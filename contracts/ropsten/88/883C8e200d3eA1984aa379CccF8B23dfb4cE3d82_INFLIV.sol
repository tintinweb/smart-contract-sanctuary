pragma solidity 0.4.25;

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

contract INFLIVERC20 {
    function totalSupply() public view returns (uint total_Supply);
    function balanceOf (address who) public view returns (uint256);
    function allowance (address IFVOwner, address spender) public view returns (uint);
    function transferFrom (address from, address to, uint value) public returns (bool ok);
    function approve (address spender, uint value) public returns (bool ok);
    function transfer (address to, uint value) public returns (bool ok);
    event    Transfer (address indexed from, address indexed to, uint value);
    event    Approval (address indexed IFVOwner, address indexed spender, uint value);
}


contract INFLIV is INFLIVERC20 { 
    
    using SafeMath for uint256;
    
    string  public constant name        = "INFLIV";                             // Name of the token
    string  public constant symbol      = "IFV";                                // Symbol of token
    uint8   public constant decimals    = 18;
    
    uint    public _totalsupply         = 70000000 * 10 ** 18;                  // 70 million Total Supply
    uint256 maxPublicSale               = 22000000 * 10 ** 18;                  // 22 million Public Sale
                                   
    uint256 public PricePre             = 6000;                                 // 1 Ether = 6000 tokens in Pre-ICO
    uint256 public PriceICO1            = 3800;                                 // 1 Ether = 3800 tokens in ICO Phase 1
    uint256 public PriceICO2            = 2600;                                 // 1 Ether = 2600 tokens in ICO Phase 2
    uint256 public PublicPrice          = 1800;                                 // 1 Ether = 1800 tokens in Public Sale
    uint256 public PreStartTimeStamp;
    uint256 public PreEndTimeStamp;
    uint256 input_token;
    uint256 bonus_token;
    uint256 total_token;
    uint256 ICO1;
    uint256 ICO2;
    uint256 public ETHReceived;                                                 // Total ETH received in the contract
    mapping (address => uint) balances;
    mapping (address => mapping(address => uint)) allowed;
    
    address public IFVOwner;                                                    // Owner of this contract
    bool stopped = false;

    enum CurrentStages {
        NOTSTARTED,
        PRE,
        ICO,
        PAUSED,
        ENDED
    }
    
    CurrentStages public stage;
    
    modifier atStage(CurrentStages _stage) {
        if (stage != _stage)
            // Contract not in expected state
            revert();
        _;
    }
    
    modifier onlyOwner() {
        if (msg.sender != IFVOwner) {
            revert();
        }
        _;
    }

    function INFLIV() public {
        IFVOwner            = msg.sender;
        balances[IFVOwner]  = 48000000 * 10 ** 18;                              // 28 million to owner & 20 million to referral bonus
        balances[address(this)] = maxPublicSale;
        stage               = CurrentStages.NOTSTARTED;
        Transfer (0, IFVOwner, balances[IFVOwner]);
        Transfer (0, address(this), balances[address(this)]);
    }
  
    function () public payable {
        require(stage != CurrentStages.ENDED);
        require(!stopped && msg.sender != IFVOwner);
            if(stage == CurrentStages.PRE && now <= PreEndTimeStamp) { 
                    require (ETHReceived <= 1500 ether);                        // Hardcap
                    ETHReceived     = (ETHReceived).add(msg.value);
                    input_token     = ((msg.value).mul(PricePre)); 
                    bonus_token     = ((input_token).mul(50)).div(100);         // 50% bonus in Pre-ICO
                    total_token     = input_token + bonus_token;
                    transferTokens (msg.sender, total_token);
            }
            else if (now <= ICO2) {
                    
                if(now < ICO1)
                {
                    input_token     = (msg.value).mul(PriceICO1);
                    bonus_token     = ((input_token).mul(25)).div(100);         // 25% bonus in ICO Phase 1
                    total_token     = input_token + bonus_token;
                    transferTokens (msg.sender, total_token);
                }   
                else if(now >= ICO1 && now < ICO2)
                {
                    input_token     = (msg.value).mul(PriceICO2);
                    bonus_token     = ((input_token).mul(10)).div(100);         // 10% bonus in ICO Phase 2
                    total_token     = input_token + bonus_token;
                    transferTokens (msg.sender, total_token);
                }
            }
            else
            {
                    input_token     = (msg.value).mul(PublicPrice);
                    transferTokens (msg.sender, input_token);
            }
    }
     
    function start_ICO() public onlyOwner atStage(CurrentStages.NOTSTARTED)
    {
        stage                   = CurrentStages.PRE;
        stopped                 = false;
        PreStartTimeStamp       = now;
        PreEndTimeStamp         = now + 20 days;
        ICO1                    = PreEndTimeStamp + 20 days;
        ICO2                    = ICO1 + 20 days;
    }
    
    function PauseICO() external onlyOwner
    {
        stopped = true;
    }

    function ResumeICO() external onlyOwner
    {
        stopped = false;
    }
   
    function end_ICO() external onlyOwner atStage(CurrentStages.PRE)
    {
        require (now > ICO2);
        stage                       = CurrentStages.ENDED;
        _totalsupply                = (_totalsupply).sub(balances[address(this)]);
        balances[address(this)]     = 0;
        Transfer (address(this), 0 , balances[address(this)]);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require (_to != 0x0);
        require (balances[_from]    >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from]             = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender]  = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to]               = (balances[_to]).add(_amount);
        Transfer (_from, _to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (_to != 0x0);
        require (balances[msg.sender]       >= _amount && _amount >= 0);
        balances[msg.sender]                = (balances[msg.sender]).sub(_amount);
        balances[_to]                       = (balances[_to]).add(_amount);
        Transfer (msg.sender, _to, _amount);
        return true;
    }
    
    function transferTokens(address _to, uint256 _amount) private returns (bool success) {
        require (_to != 0x0);       
        require (balances[address(this)]    >= _amount && _amount > 0);
        balances[address(this)]             = (balances[address(this)]).sub(_amount);
        balances[_to]                       = (balances[_to]).add(_amount);
        Transfer (address(this), _to, _amount);
        return true;
    }
 
    function withdrawETH() external onlyOwner {
        IFVOwner.transfer(this.balance);
    }
    
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require (_spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval (msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require (_owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply                = _totalsupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}