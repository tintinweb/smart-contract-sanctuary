pragma solidity 0.4.23;
/*
 This issue is covered by
INTERNATIONAL BILL OF EXCHANGE (IBOE), REGISTRATION NUMBER: 99-279-0080 and SERIAL
NUMBER: 062014 PARTIAL ASSIGNMENT /
RELEASE IN THE AMOUNT OF $ 500,000,000,000.00 USD in words;
FIVE HUNDRED BILLION and No / I00 USD, submitted to and in accordance with FINAL ARTICLES OF
(UNICITRAL Convention 1988) ratified Articles 1-7, 11-13.46-3, 47-4 (c), 51, House Joint Resolution 192 of June 5.1933,
UCC 1-104, 10-104. Reserved RELASED BY SECRETARY OF THE TRESAURY OF THE UNITED STATES OF AMERICA
 */

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


contract FENIX is ERC20
{
    using SafeMath for uint256;
        // Name of the token
    string public constant name = "FENIX";

    // Symbol of token
    string public constant symbol = "FNX";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 1000000000 * 10 ** 18; // 1 Billion FNX Coins
    address public owner;
    uint256 public _price_tokn = 100;  //1 USD in cents
    uint256 no_of_tokens;
    uint256 total_token;
    bool stopped = false;
    uint256 public ico_startdate;
    uint256 public ico_enddate;
    uint256 public preico_startdate;
    uint256 public preico_enddate;
    bool public icoRunningStatus;
    bool public lockstatus; 
  
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public ethFundMain = 0xBe80a978364649422708470c979435f43e027209; // address to receive ether from smart contract
    uint256 public ethreceived;
    uint bonusCalculationFactor;
    uint256 public pre_minContribution = 100000;// 1000 USD in cents for pre sale
    uint256 ContributionAmount;
    address public admin;  // admin address used to do transaction through the wallet on behalf of owner
 
 
    uint public priceFactor;
    mapping(address => uint256) availTokens;

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
        balances[owner] = 890000000 * 10 ** 18;  // 890 Million given to owner
        stage = Stages.NOTSTARTED;
        icoRunningStatus =true;
        lockstatus = true;
        priceFactor = EtherPriceFactor;
        emit Transfer(0, owner, balances[owner]);
    }

    function () public payable
    {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
        if (stage == Stages.PREICO && now <= preico_enddate){
             require((msg.value).mul(priceFactor.mul(100)) >= (pre_minContribution.mul(10 ** 18)));

          y();

    }
    else  if (stage == Stages.ICO && now <= ico_enddate){
  
          _price_tokn= getCurrentTokenPrice();
       
          y();

    }
    else {
        revert();
    }
    }
    
   

  function getCurrentTokenPrice() private returns (uint)
        {
        uint price_tokn;
        bonusCalculationFactor = (block.timestamp.sub(ico_startdate)).div(3600); //time period in seconds
        if (bonusCalculationFactor== 0) 
            price_tokn = 70;                     //30 % Discount
        else if (bonusCalculationFactor >= 1 && bonusCalculationFactor < 24) 
            price_tokn = 75;                     //25 % Discount
        else if (bonusCalculationFactor >= 24 && bonusCalculationFactor < 168) 
            price_tokn = 80;                      //20 % Discount
        else if (bonusCalculationFactor >= 168 && bonusCalculationFactor < 336) 
            price_tokn = 90;                     //10 % Discount
        else if (bonusCalculationFactor >= 336) 
            price_tokn = 100;                  //0 % Discount
            
            return price_tokn;
     
        }
        
         function y() private {
            
             no_of_tokens = ((msg.value).mul(priceFactor.mul(100))).div(_price_tokn);
             if(_price_tokn >=80){
                 availTokens[msg.sender] = availTokens[msg.sender].add(no_of_tokens);
             }
             ethreceived = ethreceived.add(msg.value);
             balances[address(this)] = (balances[address(this)]).sub(no_of_tokens);
             balances[msg.sender] = balances[msg.sender].add(no_of_tokens);
             emit  Transfer(address(this), msg.sender, no_of_tokens);
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
    
     function setAdminAddress(address newAdminaddress) external onlyOwner
    {
        admin = newAdminaddress;
    }
    
     function start_PREICO() external onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.PREICO;
          stopped = false;
          _price_tokn = 70;     //30 % dicount
          balances[address(this)] =10000000 * 10 ** 18 ; //10 million in preICO
         preico_startdate = now;
         preico_enddate = now + 7 days; //time for preICO
       emit Transfer(0, address(this), balances[address(this)]);
          }
    
    function start_ICO() external onlyOwner atStage(Stages.PREICO)
      {
          stage = Stages.ICO;
          stopped = false;
          balances[address(this)] =balances[address(this)].add(100000000 * 10 ** 18); //100 million in ICO
         ico_startdate = now;
         ico_enddate = now + 21 days; //time for ICO
       emit Transfer(0, address(this), 100000000 * 10 ** 18);
          }

    function end_ICO() external onlyOwner atStage(Stages.ICO)
    {
        require(now > ico_enddate);
        stage = Stages.ENDED;
        icoRunningStatus = false;
        uint256 x = balances[address(this)];
        balances[owner] = (balances[owner]).add( balances[address(this)]);
        balances[address(this)] = 0;
       emit  Transfer(address(this), owner , x);
        
    }
    
    // This function can be used by owner in emergency to update running status parameter
    function fixSpecications(bool RunningStatusICO) external onlyOwner
    {
        icoRunningStatus = RunningStatusICO;
    }
    
    // function to remove locking period after 12 months, can be called only be owner
    function removeLocking(bool RunningStatusLock) external onlyOwner
    {
        lockstatus = RunningStatusLock;
    }


   function balanceDetails(address investor)
        constant
        public
        returns (uint256,uint256)
    {
        return (availTokens[investor], balances[investor]) ;
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
        if (!icoRunningStatus && lockstatus) {
            require(_amount <= availTokens[msg.sender]);
        }
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
       
       if ( msg.sender == owner || msg.sender == admin) {
            require(balances[msg.sender] >= _amount && _amount >= 0);
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] += _amount;
            availTokens[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
        else
        if (!icoRunningStatus && lockstatus && msg.sender != owner) {
            require(availTokens[msg.sender] >= _amount);
            availTokens[msg.sender] -= _amount;
            balances[msg.sender] -= _amount;
            availTokens[_to] += _amount;
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