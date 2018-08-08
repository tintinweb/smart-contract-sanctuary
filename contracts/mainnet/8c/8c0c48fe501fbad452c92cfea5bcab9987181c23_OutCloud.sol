pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply()public view returns(uint total_Supply);
    function balanceOf(address who)public view returns(uint256);
    function allowance(address owner, address spender)public view returns(uint);
    function transferFrom(address from, address to, uint value)public returns(bool ok);
    function approve(address spender, uint value)public returns(bool ok);
    function transfer(address to, uint value)public returns(bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract OutCloud is ERC20
{
    using SafeMath for uint256;
        // Name of the token
    string public constant name = "OutCloud";

    // Symbol of token
    string public constant symbol = "OUT";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 1200000000 * 10 ** 18; // 1.2 Billion OUT Coins
    address public owner;
    uint256 public _price_token;  // price in cents
    uint256 no_of_tokens;
    uint256 total_token;
    bool stopped = false;
    uint256 public ico_startdate;
    // uint256 public ico_enddate;
    uint256 public preico_startdate;
    uint256 public preico_enddate;
    bool public lockstatus; 
    uint256 constant public ETH_DECIMALS = 10 ** 18;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public ethFundMain = 0xbCa409CaD1d339267af01aF0A49002E00e9BE090; // address to receive ether from smart contract
    uint256 public ethreceived;
    uint256 public TotalICOSupply = 400000000 * 10 ** 18;
    uint public bonusCalculationFactor;
    uint256 public minContribution = 10000; // 10 USD  (1 USD = 1000)
    uint256 ContributionAmount;
    uint dis;
   
 
    uint public priceFactor;
   // mapping(address => uint256) availTokens;

    enum Stages {
        NOTSTARTED,
        PREICO,
        ICO,
        ENDED
    }
    Stages public stage;

    modifier atStage(Stages _stage) {
        require (stage == _stage);
        _;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
     _;
    }

  
    constructor(uint256 EtherPriceFactor) public
    {
        require(EtherPriceFactor != 0);
        owner = msg.sender;
        balances[owner] = 500000000 * 10 ** 18;  // 500 Million given to owner
        stage = Stages.NOTSTARTED;
        lockstatus = true;
        priceFactor = EtherPriceFactor;
        emit Transfer(0, owner, balances[owner]);
       
    }

    function () public payable
    {
        require(stage != Stages.ENDED);
        require(msg.value >= minContribution);
        require(!stopped && msg.sender != owner);
        ContributionAmount = ((msg.value).mul(priceFactor.mul(1000)));// 1USD = 1000
        if (stage == Stages.PREICO && now <= preico_enddate){
            
             
           dis= getCurrentTokenPricepreICO(ContributionAmount);
           _price_token = _price_token.sub(_price_token.mul(dis).div(100));
          y();

    }
    else  if (stage == Stages.ICO ){
  
          dis= getCurrentTokenPriceICO(ContributionAmount);
           _price_token = _price_token.sub(_price_token.mul(dis).div(100));
          y();

    }
    else {
        revert();
    }
    }
    
   

  function getCurrentTokenPricepreICO(uint256 individuallyContributedEtherInWei) private returns (uint)
        {
        require(individuallyContributedEtherInWei >= (minContribution.mul(ETH_DECIMALS)));
        uint disc;
        bonusCalculationFactor = (block.timestamp.sub(preico_startdate)).div(604800); // 1 week time period in seconds
        if (bonusCalculationFactor== 0) 
            disc = 30;                     //30 % Discount
        else if (bonusCalculationFactor == 1) 
            disc = 20;                     //20 % Discount
        else if (bonusCalculationFactor ==2 ) 
            disc = 10;                      //10 % Discount
        else if (bonusCalculationFactor == 3) 
           disc = 5;                     //5 % Discount
        
            
            return disc;
     
        }
        
        function getCurrentTokenPriceICO(uint256 individuallyContributedEtherInWei) private returns (uint)
        {
        require(individuallyContributedEtherInWei >= (minContribution.mul(ETH_DECIMALS)));
        uint disc;
        bonusCalculationFactor = (block.timestamp.sub(ico_startdate)).div(604800); // 1 week time period in seconds
        if (bonusCalculationFactor== 0) 
            disc = 30;                     //30 % Discount
        else if (bonusCalculationFactor == 1) 
            disc = 20;                     //20 % Discount
        else if (bonusCalculationFactor ==2 ) 
            disc = 10;                      //10 % Discount
        else if (bonusCalculationFactor == 3) 
           disc = 5;                     //5 % Discount
        else if (bonusCalculationFactor > 3) 
           disc = 0;                  //0% Discount
            
            return disc;
     
        }
        
         function y() private {
            
             no_of_tokens = ((msg.value).mul(priceFactor.mul(1000))).div(_price_token); //(1USD =1000)
             ethreceived = ethreceived.add(msg.value);
             balances[address(this)] = (balances[address(this)]).sub(no_of_tokens);
             balances[msg.sender] = balances[msg.sender].add(no_of_tokens);
             emit Transfer(address(this), msg.sender, no_of_tokens);
    }

   
    // called by the owner, pause ICO
    function StopICO() external onlyOwner  {
        stopped = true;

    }

    // called by the owner , resumes ICO
    function releaseICO() external onlyOwner
    {
        stopped = false;

    }
    
    // to change price of Ether in USD, in case price increases or decreases
     function setpricefactor(uint256 newPricefactor) external onlyOwner
    {
        priceFactor = newPricefactor;
        
    }
    
     function setEthmainAddress(address newEthfundaddress) external onlyOwner
    {
        ethFundMain = newEthfundaddress;
    }
 
    
     function start_PREICO() external onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.PREICO;
          stopped = false;
          _price_token = 100;  // 1 OUT =  10 cents (1USD = 1000)
        balances[address(this)] = 300000000 * 10 ** 18 ; //300 Million in pre-ICO
         preico_startdate = now;
         preico_enddate = now + 28 days; //time period for preICO = 4 weeks
      emit Transfer(0, address(this), balances[address(this)]);
          }
    
    function start_ICO() external onlyOwner atStage(Stages.PREICO)
      {
          stage = Stages.ICO;
          stopped = false;
          balances[address(this)] = balances[address(this)].add(TotalICOSupply) ; //400 Million in ICO
          _price_token = 150;   // 1 OUT =  15 cents (1USD = 1000)
          ico_startdate = now;
        //  ico_enddate = now + 28 days; //time period for ICO = 4 weeks
          emit Transfer(0, address(this), TotalICOSupply);
      
          }

    function end_ICO() external onlyOwner atStage(Stages.ICO)
    {
        // require(now > ico_enddate);
        stage = Stages.ENDED;
        lockstatus = false;
        uint256 x = balances[address(this)];
        balances[owner] = (balances[owner]).add( balances[address(this)]);
        balances[address(this)] = 0;
       emit  Transfer(address(this), owner , x);
        
    }
    
  
   // This function can be used by owner in emergency to update running status parameter
    function removeLocking(bool RunningStatusLock) external onlyOwner
    {
        lockstatus = RunningStatusLock;
    }


  
    // what is the total supply of the ech tokens
    function totalSupply() public view returns(uint256 total_Supply) {
        total_Supply = _totalsupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner)public view returns(uint256 balance) {
        return balances[_owner];
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)public returns(bool success) {
        require(_spender != 0x0);
        require( !lockstatus);
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns(uint256 remaining) {
        require(_owner != 0x0 && _spender != 0x0);
        return allowed[_owner][_spender];
    }
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) public returns(bool success) {
       
       if ( lockstatus && msg.sender == owner) {
            require(balances[msg.sender] >= _amount && _amount >= 0);
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
      
          else if(!lockstatus)
         {
           require(balances[msg.sender] >= _amount && _amount >= 0);
           balances[msg.sender] = (balances[msg.sender]).sub(_amount);
           balances[_to] = (balances[_to]).add(_amount);
           emit Transfer(msg.sender, _to, _amount);
           return true;
          }

        else{
            revert();
        }
    }


    //In case the ownership needs to be transferred
	function transferOwnership(address newOwner)public onlyOwner
	{
	    require( newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}


    function drain() external onlyOwner {
        address myAddress = this;
        ethFundMain.transfer(myAddress.balance);
    }

}