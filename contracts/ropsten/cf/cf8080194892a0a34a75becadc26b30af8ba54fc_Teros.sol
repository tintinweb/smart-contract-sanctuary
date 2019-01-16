pragma solidity ^0.5.1;

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

contract Ownable {
    address public owner;
    using SafeMath for uint256;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    
    constructor() public {
       owner = 0x3491542173Afe5cAc3e69934B17BDC26AD5073ee;
    }
    

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}




contract Teros is Ownable{
        using SafeMath for uint256;

    //variable initialization for "setup" tab
    uint type_of_token; // store corresponding index value of selected option
    string ico_name;
    string public token_name;
    string public symbol;
    uint256 public decimals;
    uint public rate; 
    uint funding_method;    // store corresponding index value of selected option
    uint public totalSupply;
    uint tokens_available_for_sale_hardcap;
    uint minimum_investment;
    address client_wallet;
    uint256 no_of_tokens1;
    uint256 token;
    //non-phase related data of "phase" tab;
    uint end_date_time; //store single timestamp instead of separate date & time;
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    mapping (address => mapping (address => uint256)) internal allowed;
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    //structure of phase (tab "phase")
    struct Phase{
        string Name;
        uint StartDateTime; //timestamp
        uint MaxCap;
        uint BonusPercent;
        uint MinInvest;
        uint TokenLockupPeriod;
        
        uint phaseRemainingBalance; //hidden
    }
    Phase[] public phases;
    uint no_of_phases=0;

    //variable initialization for phase (for temporarily handling phase data)
    string phase_name;
    uint phase_start_date_time;
    uint max_token_cap;
    uint bonus_percentage;
    uint min_investment_tokens;
    uint token_lockup_period;   //timestamp instead of a date and time;
    
    
    //structure for "Custom Token Distribution"
    struct CTD{
        address RecievingWallet;
        uint LockupPeriod; //as timestamp
        uint no_of_tokens;
        string Name;
        uint Bonus;
        uint TypesOfDistribution;
    }
    CTD[] public ctdArray;
    uint no_of_CTD=0;
    
    //declaration of local CTD variables
    address recieving_wallet;
    uint lockup;
    uint no_of_tokens;
    string name;
    uint bonus;
    uint types_of_distribution;
    
    constructor() public{
        
        //store "setup" tab data;
        type_of_token = 1;
        ico_name = &#39;TEST&#39;;
        end_date_time = 1546041600;
        token_name = &#39;IMTIYAZ&#39;;
        symbol = &#39;IMTI&#39;;
        decimals = 5;
        rate = 40513050899999997952;
        funding_method = 3;
        uint256 total_supply = 4500;
        totalSupply = total_supply * 10 ** uint256(decimals);
        tokens_available_for_sale_hardcap = 4400;
        minimum_investment = 4300;
        client_wallet = 0x3491542173Afe5cAc3e69934B17BDC26AD5073ee;
        balances[owner] = totalSupply;
        Phase memory thisPhase;
        CTD memory thisCTD;

        // Phase Imtiyaz
        phase_name = &#39;Imtiyaz&#39;;
        phase_start_date_time = 1545350400;
        max_token_cap = 4500;
        bonus_percentage = 45;
        min_investment_tokens = 4500;
        token_lockup_period = 1548680323;


        //save (push) data  of first phase into phase structure
        thisPhase = Phase(phase_name, phase_start_date_time, max_token_cap, bonus_percentage, min_investment_tokens, token_lockup_period, max_token_cap);
        phases.push(thisPhase);
        no_of_phases++;


        // Phase Imtiyaz Again
        phase_name = &#39;Imtiyaz Again&#39;;
        phase_start_date_time = 1545354000;
        max_token_cap = 4500;
        bonus_percentage = 45;
        min_investment_tokens = 421;
        token_lockup_period = 1545829124;


        //save (push) data  of first phase into phase structure
        thisPhase = Phase(phase_name, phase_start_date_time, max_token_cap, bonus_percentage, min_investment_tokens, token_lockup_period, max_token_cap);
        phases.push(thisPhase);
        no_of_phases++;




       // Custom Token Distribution 34
        recieving_wallet = 0x3491542173Afe5cAc3e69934B17BDC26AD5073ee;
        lockup = 34;
        no_of_tokens1 = 34;
        name = &#39;34&#39;;
        bonus = 34;
        no_of_tokens = no_of_tokens1+ (no_of_tokens1*bonus)/100;
        types_of_distribution = 2;
        balances[recieving_wallet]= no_of_tokens;

        //push this data into CTD structure array
        thisCTD = CTD(recieving_wallet, lockup, no_of_tokens, name, bonus, types_of_distribution);
        ctdArray.push(thisCTD);
        no_of_CTD++;


       // Custom Token Distribution 5563434
        recieving_wallet = 0x3491542173Afe5cAc3e69934B17BDC26AD5073ee;
        lockup = 34;
        no_of_tokens1 = 6433;
        name = &#39;5563434&#39;;
        bonus = 56;
        no_of_tokens = no_of_tokens1+ (no_of_tokens1*bonus)/100;
        types_of_distribution = 2;
        balances[recieving_wallet]= no_of_tokens;

        //push this data into CTD structure array
        thisCTD = CTD(recieving_wallet, lockup, no_of_tokens, name, bonus, types_of_distribution);
        ctdArray.push(thisCTD);
        no_of_CTD++;



        //all data saved, constructor ends here
    }

    // getter functions to read stored data
    
    function readPhaseData(uint phaseIndex) public view returns(string memory, uint, uint, uint, uint, uint, uint){
        return (phases[phaseIndex].Name, phases[phaseIndex].StartDateTime, phases[phaseIndex].MaxCap, phases[phaseIndex].BonusPercent, phases[phaseIndex].MinInvest, phases[phaseIndex].TokenLockupPeriod, phases[phaseIndex].MaxCap);
    }
    
    function readCTDdata(uint CTDIndex) public view returns(address, uint, uint, string memory, uint, uint){
        return (ctdArray[CTDIndex].RecievingWallet, ctdArray[CTDIndex].LockupPeriod, ctdArray[CTDIndex].no_of_tokens, ctdArray[CTDIndex].Name, ctdArray[CTDIndex].Bonus, ctdArray[CTDIndex].TypesOfDistribution);
    }
    
    



      function transfer(address _to, uint _value) public payable {
        //check if sender has a lockup period (ctd?)
        //for this , traverse the ctdArray
        
        uint senderLockup = findLockupIfCTD(msg.sender);    //lockup is a timestamp
        
        if(senderLockup<now){   //perform transaction
            //require conditions
            require(_to != address(0)); //_to address is valid
            require(_value <= balances[msg.sender]);    //sufficient funds to transfer
            
            //perform transaction
            balances[_to] = balances[_to].add(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
            emit Transfer(msg.sender, _to, _value);
            
        }
        else{
            //don&#39;t transact
            
        }
    }
    
    
    function findLockupIfCTD(address Address) public view returns(uint){
        for(uint i=0;i<no_of_CTD;i++){
            if(ctdArray[i].RecievingWallet == Address)
                return ctdArray[i].LockupPeriod;
        }
        return 0;
    }

    
  

      
   function () external payable {
        BuyTokens(msg.sender);
    }

    function BuyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        // uint256 tokens = weiAmount.mul(10**18).div(rate);
        uint256 tokens = weiAmount.div(rate);

        require(tokens <= balances[owner]);
        
        (uint _cPhase, uint _bonus,uint _mininv) = getCurrentPhase();
        require(_mininv <= tokens);   
        tokens = tokens+ (tokens*_bonus)/100;
        if(tokens > 0){
            _cPhase=  _cPhase;
            balances[beneficiary] += tokens;
            balances[owner] -= tokens;
            totalSupply -= tokens;
        }
    }




    
    //show current phases
    function getCurrentPhase() public view returns(uint, uint, uint256){
        uint currentTimestamp = now;
        uint currentPhase = 0;
        for(uint i=0;i<no_of_phases;i++){
            if(currentTimestamp > phases[i].StartDateTime)
                currentPhase = i;
        }
        uint256 _bonus = phases[currentPhase].BonusPercent;
        uint256 _minInvest = phases[currentPhase].MinInvest;
        return (currentPhase,_bonus,_minInvest);
    }
    
    function findWhichCTD(address _Address) public view returns(uint){
        for(uint i=0;i<no_of_CTD;i++){
            if(ctdArray[i].RecievingWallet == _Address)
                return i;
        }
        return 13072018;    // :P :D
    }
    
    function balanceOf(address Address) public view returns(uint){
        return balances[Address];
    }
    
  

    function total_no_of_CTD() public view returns(uint){
        return no_of_CTD;
    }    
   
    
   
  /**
   * @dev Transfer tokens from one address to another.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
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

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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