pragma solidity ^0.4.24;

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
        owner = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    }
    

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}




contract ICO is Ownable{
        using SafeMath for uint256;

    //variable initialization for "setup" tab
    uint type_of_token; // store corresponding index value of selected option
    string ico_name;
    string public token_name;
    string public choose_a_symbol;
    uint public no_of_decimal_points;
    uint public rate; 
    uint funding_method;    // store corresponding index value of selected option
    uint public total_supply;
    uint tokens_available_for_sale_hardcap;
    uint minimum_investment;
    address client_wallet;
    uint256 no_of_tokens1;
    uint256 token;
    //non-phase related data of "phase" tab;
    uint end_date_time; //store single timestamp instead of separate date & time;
    mapping (address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
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
        type_of_token = 1; // store corresponding index value of selected option
        ico_name = "EtherExchange";
        token_name = "Ethereum";
        choose_a_symbol = "ETH";
        no_of_decimal_points = 5;
        rate = 1;    //should be in weiAmount
        funding_method = 3;    // store corresponding index value of selected option
        total_supply = 5000000;
        tokens_available_for_sale_hardcap = 4000000;
        minimum_investment = 10;
        client_wallet = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
        balances[owner] = total_supply;
    
        //for first phase
        phase_name = "phase1";
        phase_start_date_time = 1543449600;
        max_token_cap = 100000;
        bonus_percentage = 5;
        min_investment_tokens = 100;
        token_lockup_period = 9693621963;   //timestamp
    
        //save (push) data  of first phase into phase structure
        Phase memory thisPhase = Phase(phase_name, phase_start_date_time, max_token_cap, bonus_percentage, min_investment_tokens, token_lockup_period, max_token_cap);
        phases.push(thisPhase);
        no_of_phases++;
        
        //for second phase
        phase_name = "phase2";
        phase_start_date_time = 1543407605;
        max_token_cap = 100000;
        min_investment_tokens = 100;
        token_lockup_period = 9693621963;   //timestamp
    
        //save (push) data  of second phase into phase structure
        thisPhase = Phase(phase_name, phase_start_date_time, max_token_cap, bonus_percentage, min_investment_tokens, token_lockup_period, max_token_cap);
        phases.push(thisPhase);
        no_of_phases++;
        
        //save data of first custom token distribution (CTD)
        recieving_wallet = 0x583031d1113ad414f02576bd6afabfb302140225;
        lockup = 1543190400;
        no_of_tokens1 = 1000;
        name = "ankush";
        bonus = 5;
        no_of_tokens = no_of_tokens1 + (no_of_tokens1*bonus)/100;
        types_of_distribution = 2;  //it can be stored as a string or in corresponding index value
        balances[recieving_wallet]= no_of_tokens;
        //push this data into CTD structure array
        CTD memory thisCTD = CTD(recieving_wallet, lockup, no_of_tokens, name, bonus, types_of_distribution);
        ctdArray.push(thisCTD);
        no_of_CTD++;
        
        //save data of second custom token distribution (CTD)
        recieving_wallet = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148;
        lockup = 1543276800;
        no_of_tokens1 = 1200;
        name = "rahul";
        bonus = 5;
        no_of_tokens = no_of_tokens1+ (no_of_tokens1*bonus)/100;
        types_of_distribution = 2;  //it can be stored as a string or in corresponding index value
        balances[recieving_wallet]= no_of_tokens;
        //push this data into CTD structure array
        thisCTD = CTD(recieving_wallet, lockup, no_of_tokens, name, bonus, types_of_distribution);
        ctdArray.push(thisCTD);
        no_of_CTD++;
        
        
        //all data saved, constructor ends here
    }

    // getter functions to read stored data
    
    function readPhaseData(uint phaseIndex) public view returns(string, uint, uint, uint, uint, uint, uint){
        return (phases[phaseIndex].Name, phases[phaseIndex].StartDateTime, phases[phaseIndex].MaxCap, phases[phaseIndex].BonusPercent, phases[phaseIndex].MinInvest, phases[phaseIndex].TokenLockupPeriod, phases[phaseIndex].MaxCap);
    }
    
    function readCTDdata(uint CTDIndex) public view returns(address, uint, uint, string, uint, uint){
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
    
    
    function findLockupIfCTD(address Address) internal returns(uint){
        for(uint i=0;i<no_of_CTD;i++){
            if(ctdArray[i].RecievingWallet == Address)
                return ctdArray[i].LockupPeriod;
        }
        return 0;
    }



    
    // low level token purchase function
    
        
  
     function () public payable {
        BuyTokens(msg.sender);
    }

    function BuyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        
        uint256 weiAmount = msg.value; // Calculate tokens to sell
        // uint256 tokens = weiAmount.mul(10**18).div(rate);
        uint256 tokens = weiAmount.div(rate);

        require(tokens <= balances[owner]);
        getCurrentPhase();
        tokens = tokens+ (tokens*bonus)/100; 
        // no_of_tokens = no_of_tokens1+ (no_of_tokens1*bonus)/100;
        if(tokens > 0){
            balances[beneficiary] += tokens;
            balances[owner] -= tokens;
            total_supply -= tokens;
        }
    }



    
    //show current phases
    function getCurrentPhase() public view returns(uint, uint){
        uint currentTimestamp = now;
        uint currentPhase = 0;
        for(uint i=0;i<no_of_phases;i++){
            if(currentTimestamp > phases[i].StartDateTime)
                currentPhase = i;
        }
        uint256 bonus = phases[currentPhase].BonusPercent;
        return (currentPhase,bonus);
    }
    
    function findWhichCTD(address Address) internal returns(uint){
        for(uint i=0;i<no_of_CTD;i++){
            if(ctdArray[i].RecievingWallet == Address)
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
   
       

}