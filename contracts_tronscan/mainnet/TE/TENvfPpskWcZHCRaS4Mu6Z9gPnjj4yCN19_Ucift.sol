//SourceUnit: UCIFT.sol

pragma solidity ^0.4.23;

contract Ucift {
    //Supply definition
    string public name;
    string public symbol;
    uint256 public ownerSupply;
    uint256 public icoSupply;
    uint256 public poolSupply;
    uint256 public totalSupply;
    uint256 _poolSupply = 200000000e18;
    uint256 _saleSupply = 100000000e18;
    uint256 _reserveSupply = 100000000e18;
    uint256 public constant decimals = 18;
    uint256 _totalSupply = _poolSupply + _saleSupply + _reserveSupply;
    uint256 countOnPool = 0;
    //Token
    string _tokenName = "Universal Crypto Investment Fund";
    string _symbol = "UCIFT";
    address public owner;
    uint256 public price = 1 trx;
    uint256 public saleDate = 1563164918;
    uint256 public escrow = 0;
    //Addresses
    address public marketing;
    address public development;
    //Mappings
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => mapping(uint256 => Investor[])) public staking;
    mapping(uint256 => Referral) public referral;
    mapping(uint256 => mapping(uint256 => Request[])) public request;
    //Events
    event Transfer(address _from, address _to, uint256 _value);
    //Helper
    uint256 exists;
    uint256 public staked;
    uint256 requestExists;
    uint256 count = 0;
    uint256 public requestCount = 0;
    //Struct
    struct Investor{
        address person;
        uint256 timestamp;
        uint256 amount;
        uint256 amountCredited;
        bool onPool;
        uint256 referralCode;
        uint256 referred;
    }
    
    struct Referral {
        uint256 id;
        address person;
    }
    
    struct Request {
        address person;
        uint256 amount;
        bool processed;
    }
    //Modifiers
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier Allowed(){
        require(now >= saleDate);
        require(now <= (saleDate + 7776000)); //90 days
        _;
    }

    modifier buyBackAllowed(){
        require(now >= (saleDate + 7776000));
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        count++;
        referral[count] = Referral(count, msg.sender);
        name = _tokenName;
        symbol = _symbol;
        ownerSupply = _reserveSupply;
        poolSupply = _poolSupply;
        icoSupply = _saleSupply;
        totalSupply = _totalSupply;
        balanceOf[owner] = _reserveSupply;
        marketing = owner;
        development = owner;
    }
    
    function changeOwner(address _new) public onlyOwner{
        owner = _new;
    }
    
    function setMarketingAddress(address _new) public onlyOwner{
        marketing = _new;
    }
    
    function setDevelopmentAddress(address _new) public onlyOwner{
        development = _new;
    }
    
    function moveIcoToPool() public onlyOwner{
        require(now >= (saleDate + 7776000));
            if(icoSupply > 0){
                poolSupply += icoSupply;
                icoSupply = 0;
            }
    }
    
    function buyToken(uint256 _amount) public payable Allowed{
         uint256 amount = _amount*10**decimals;
         require(amount <= icoSupply);
         require(msg.value >= price);
         uint256 result = _amount * price;
         require(msg.value == result);
         balanceOf[msg.sender] += amount;
         icoSupply -= amount;
         owner.transfer(result);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function isOnPool(address _person) internal returns(bool) {
        
        for(uint256 i = 0; i < staking[1][1].length; i++){
            if(staking[1][1][i].person == _person) {
                exists = i;
                return true;
                
            }
        }
        return false;
    }
    
    function isRequest(address _person) internal returns(bool){
        _person = msg.sender;
        
        for(uint256 i=0; i < request[1][1].length; i++){
            if(request[1][1][i].person == _person){
                requestExists = i;
                return true;
            }
        }
        return false;
    }
    
    function viewRequests() public view returns(address){
        for(uint256 i = 0; i < request[1][1].length; i++){
            if(request[1][1][i].processed == false ){
                request[1][1][i].person;
            }
        }
    }
   
   function createReferral(address _person) internal {
       count += 1;
        referral[count] = Referral(count, _person);
   }
   
   function viewReferralCode() public view returns(uint256){
       for(uint256 i = 1; i <= count; i++){
           if(referral[i].person == msg.sender){
               return referral[i].id;
        
           }
       }
      revert();
   }
   
   function invest(uint256 _amount, uint256 _id) public {
      uint256 amount = _amount*10**decimals;
      require(amount >= 1);
      require(msg.sender != 0);
      require(balanceOf[msg.sender] >= (amount));
      uint256 _timestamp = now;
      address _person = msg.sender;
      bool _onPool = true;
      uint256 onePercent = (amount)/ 100; // 1%
      uint256 investor = (amount * 96) / 100; //96% Investor
      require(investor <= poolSupply);
      
      if(isOnPool(msg.sender) == false && (msg.sender != owner)){
        require(_id > 0 && _id <= count);
        createReferral(msg.sender); //Creates referral code;
        staking[1][1].push(Investor(_person, _timestamp, amount, investor, _onPool, count, _id));
        balanceOf[msg.sender] -= amount;
        
        balanceOf[referral[_id].person] += onePercent;//Referral %
        balanceOf[marketing] += onePercent; //Marketing %
        balanceOf[development] += onePercent; //Devs %
        poolSupply += onePercent; //Pool %
        poolSupply -= investor; // Algorithm
        //balanceOf[msg.sender] += investor;
      }
      else if(msg.sender == owner && isOnPool(msg.sender) == false){
        staking[1][1].push(Investor(_person, _timestamp, amount, investor, _onPool, 1, 0));
        balanceOf[msg.sender] -= amount;
        poolSupply += onePercent; //As Owner has no referral, pool should have +1%
        balanceOf[marketing] += onePercent;
        balanceOf[development] += onePercent;
        poolSupply += onePercent; //Respective pool %
        poolSupply -= investor; //Algorithm
        //balanceOf[msg.sender] += investor;
      }
       else if(msg.sender == owner && isOnPool(msg.sender) == true){
        balanceOf[msg.sender] -= amount;
        poolSupply += onePercent; //As Owner has no referral, pool should have +1%
        balanceOf[marketing] += onePercent;
        balanceOf[development] += onePercent;
        poolSupply += onePercent; //Respective pool %
        poolSupply -= investor;
        //balanceOf[msg.sender] += investor;
        staking[1][1][exists].amount += amount;
        staking[1][1][exists].amountCredited += investor;
        staking[1][1][exists].onPool = true;
      }
      else if(isOnPool(msg.sender) == true && (msg.sender) != owner){
        balanceOf[msg.sender] -= amount;
       
        balanceOf[marketing] += onePercent;
        balanceOf[development] += onePercent;
        uint256 ref = staking[1][1][exists].referred;
        balanceOf[referral[ref].person] += onePercent;
        poolSupply += onePercent;
        poolSupply -= investor;
        //balanceOf[msg.sender] += investor;
        staking[1][1][exists].onPool = true;
        staking[1][1][exists].amount += amount;
        staking[1][1][exists].amountCredited += investor;
      }
    }
  
  function withdraw() public {
      require(isOnPool(msg.sender) == true);
      require(staking[1][1][exists].onPool == true);
    
      uint256 amountInvested = staking[1][1][exists].amount;
      uint256 credited = (amountInvested *96) / 100;
      uint256 c = now - staking[1][1][exists].timestamp;
      uint256 d = c * amountInvested;
      require(d / c == amountInvested);
      
      uint256 stakedOne = (((d/100)/86400)); // 1% daily
     
      require(stakedOne >= 1e18);
      
      staking[1][1][exists].onPool = false;
      assert(staking[1][1][exists].timestamp <= now);
      
      balanceOf[msg.sender] += stakedOne;
      balanceOf[msg.sender] += staking[1][1][exists].amountCredited;
      staking[1][1][exists].amount = 0;
      poolSupply += credited;
      poolSupply -= stakedOne;
  }
  
  function viewStake() public returns(uint256){
    require(isOnPool(msg.sender) == true);
    require(staking[1][1][exists].onPool == true);
    
    uint256 amountInvested = staking[1][1][exists].amount;
    uint256 c = now - staking[1][1][exists].timestamp;
    uint256 d = c * amountInvested;
    require(d / c == amountInvested);
    staked = ((d /100)/86400);
    
    return staked;
    
    }

   function withdrawStake() public returns(uint256){
    require(isOnPool(msg.sender) == true);
    require(staking[1][1][exists].onPool == true);
    
    uint256 amountInvested = staking[1][1][exists].amount;
    uint256 c = now - staking[1][1][exists].timestamp;
    uint256 d = c * amountInvested;
    require(d / c == amountInvested);
    uint256 stakedOne = ((d /100)/86400);
    require(stakedOne >= 1e18);
    uint256 totalStake = stakedOne;
    balanceOf[msg.sender] += totalStake;
    poolSupply -= totalStake;
    staking[1][1][exists].timestamp = now;

    return totalStake;
    
    }
    
 function requestBuyBack(uint256 _amount) public buyBackAllowed {
     uint256 amount = _amount*10**decimals;
     require(balanceOf[msg.sender] >= amount);
     require(isOnPool(msg.sender) == true);
     
     if(isRequest(msg.sender) == false){
         balanceOf[msg.sender] -= amount;
         escrow += amount;
         
         requestCount += 1;

         request[1][1].push(Request(msg.sender, _amount, false));
     }
     else {
         balanceOf[msg.sender] -= amount;
         escrow += amount;

         request[1][1][requestExists].amount += _amount;
         request[1][1][requestExists].processed = false;
     }
 }

 function cancelBuyBack() public buyBackAllowed {
     require(isOnPool(msg.sender) == true);
     require(isRequest(msg.sender) == true);

     uint256 _amount = request[1][1][requestExists].amount;
    
     require(escrow >= _amount);

     escrow -= _amount;
     balanceOf[msg.sender] += _amount;

     request[1][1][requestExists].processed = true;
     request[1][1][requestExists].amount = 0;
 }
 
 function processRequest(uint256 _id, uint256 amount) public payable onlyOwner{
     require(request[1][1][_id].processed == false);
     require(isOnPool(request[1][1][_id].person) == true);
     require(msg.value == (amount * price));
     uint256 onePercent = (msg.value)/ 100; // 1%
     uint256 investor = (msg.value * 96) / 100; //96% Investor
     address person = request[1][1][_id].person;
     address referred = referral[staking[1][1][_id].referred].person;
     uint256 fromEscrow = amount*10**decimals;

     
     development.transfer(onePercent);
     marketing.transfer(onePercent);
     referred.transfer(onePercent);
     person.transfer(investor);
    
    require(fromEscrow <= escrow);
    escrow -= fromEscrow;
    
    
    poolSupply += fromEscrow;
    request[1][1][_id].processed = true;
    request[1][1][_id].amount = 0;
     
    }
}