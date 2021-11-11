pragma solidity  ^0.5.16;


import "./NautStaking.sol";


contract NAUTIDO 
   
   {
       using SafeMath for uint256;
           
      address public owner;
      Nautstaking public nts;
      
      address public inputtoken;
      address public outputtoken;
      
     // total Supply for ICO
      uint256 public totalsupply;
     
      struct ICOUsersInfo {
        uint256 investedamount;
        uint256 maxallocation;
        uint256 remainingallocation;
        uint256 remainingClaim;
        uint256 claimround;
      }
   
     mapping (address => ICOUsersInfo)public ico;
     address[] public investors;
     mapping (address => bool) public existinguser;
     
     
     // Tier Max limit
     uint256 private tier1Max;
     uint256 private tier2Max;
     uint256 private tier3Max;
     uint256 private tier4Max;
     
     // pool weight   
     uint256 public poolweightTier1 = 0;          //  100
     uint256 public poolweightTier2 = 0;          //  250 
     uint256 public poolweightTier3 = 0;          //  375
     uint256 public poolweightTier4 = 0;          //  625
     
     bool poolweightinitialize = false;
 
     //set price of token  
      uint public tokenPrice;                   
 
     //hardcap 
      uint public icoTarget;
 
      //define a state variable to track the funded amount
      uint public receivedFund=0;
      
      
      uint public vestingTime;
      uint public vestingperc;
 
 
        bool public claimenabled = false;
        bool public icoStatus = false;
        bool claim = false;
 
        modifier onlyOwner() {
                require(msg.sender == owner);
                _;
        }   
    
        function transferOwnership(address _newowner) public onlyOwner {
            owner = _newowner;
        } 
 
        constructor (Nautstaking _nts) public  {
         nts = Nautstaking(_nts);
         owner = msg.sender;
         }
 

    /** @dev Stop IDO
     */
    function stopIDO() public onlyOwner {
        icoStatus = false;
    }

    /** @dev Start IDO
     */
    function startIDO() public onlyOwner {
        require(claimenabled == false , "claim enabled");
        require(claim == false , "claim already start");
        icoStatus = true;
    }

    /** @dev Start Claim
     */
    function StartClaim() public onlyOwner {
        require(icoStatus == false , "IDO is live");
        require(vestingTime != 0, "Initialze  Vesting Params");
        claimenabled = true;
        claim = true;
    }
    
    /** @dev Stop Claim
     */
    function StopClaim() public onlyOwner {
        claimenabled = false;
    }
    
 
    function getTotalWeightedUsers() internal view returns (uint256 _t) {
        
        uint256 t1 =  nts.tier1user();     //1
        uint256 t2 =  nts.tier2user();     //1
        uint256 t3 =  nts.tier3user();     //1
        uint256 t4 =  nts.tier4user();     //2
        
        uint256 tw = (t1 * poolweightTier1) + (t2 * poolweightTier2) + (t3 * poolweightTier3) + (t4 * poolweightTier4);
        
        return tw;                         //395
    }
 
    
    function TokenPerperson() internal view returns (uint256) {
        
        uint256 totalweight = getTotalWeightedUsers();
    
       if (totalweight != 0) 
        {
        uint256 tpp = (totalsupply) / totalweight;
        return tpp;                       // 253.164
        }
        return 0;
    }
     
     
    function getTier1Maxlimit() public view returns (uint256 _tier1limit) {    //34782
        
        return TokenPerperson() * poolweightTier1;         
    }
     
    
    function getTier2Maxlimit() public view returns (uint256 _tier2limit) {    // 86956
        
        return (TokenPerperson() * poolweightTier2);
    }
 
 
     function getTier3Maxlimit() public view returns (uint256 _tier2limit) {   // 130434 
        
        return (TokenPerperson() * poolweightTier3);
    }
 
 
     function getTier4Maxlimit() public view returns (uint256 _tier2limit) {   // 217391
        
        return (TokenPerperson() * poolweightTier4);
    }



    
     function getTier1MaxContribution() public view returns (uint256 _tier1limit) {
        
        if (getTier1Maxlimit() > 0 ) 
        {
        return getTier1Maxlimit() * 1000  / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
     
     
      function getTier2MaxContribution() public view returns (uint256 _tier1limit) {
        
       if (getTier2Maxlimit() > 0 ) 
        {
        return getTier2Maxlimit() * 1000 / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
     
     
      function getTier3MaxContribution() public view returns (uint256 _tier1limit) {
        
        if (getTier3Maxlimit() > 0 ) 
        {
        return getTier3Maxlimit() * 1000 / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
    
    
     function getTier4MaxContribution() public view returns (uint256 _tier1limit) {
        
         if (getTier4Maxlimit() > 0 ) 
        {
        return getTier4Maxlimit() * 1000 / tokenPrice / 1000000000000;
        }
        return 0 ;
         
     }
     
     
 
     function Investing(uint256 _amount) public {
    
     require(icoStatus == true, "ICO in not active");
    
     //check for hard cap
     require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
     
     ICOUsersInfo storage icoStorage = ico[msg.sender];  
     uint useralloc = _amount*tokenPrice*1000000000000 / 1000;
     
     // check for existinguser
     if (existinguser[msg.sender]==false) {
         
         (,uint8 b)  =  nts.getStaker(msg.sender);
         
         require(b==1 || b==2 || b==3 || b==4, "Not whitelisted ");
         
         if (b == 1) 
         {
          require (useralloc <= tier1Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier1Max;                            //1000 
          icoStorage.remainingallocation = tier1Max - (useralloc);                                 
         }   
         
        else if (b == 2) 
         {
          require (useralloc <= tier2Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier2Max;                            //1000 
          icoStorage.remainingallocation = tier2Max - (useralloc);                                 
         }   
         
        else if (b == 3) 
         {
          require (useralloc <= tier3Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier3Max;                            //1000 
          icoStorage.remainingallocation = tier3Max - (useralloc);                                 
         }
         
         else 
         {
          require (useralloc <= tier4Max, "Not allowed" );     
          icoStorage.investedamount = _amount;                            //100 => 200    
          icoStorage.maxallocation = tier4Max;                            //1000 
          icoStorage.remainingallocation = tier4Max - (useralloc);                                   
         }
         
        existinguser[msg.sender] = true;
        investors.push(msg.sender);
     }
     
     
       else {
         require ( ((_amount+icoStorage.investedamount)*tokenPrice*1000000000000) / 1000  <= icoStorage.maxallocation, "Not allowed" );
         icoStorage.investedamount += _amount;
         icoStorage.remainingallocation = icoStorage.remainingallocation - (useralloc);
       }
       
        icoStorage.remainingClaim = (icoStorage.investedamount * tokenPrice * 1000000000000) /1000;
        receivedFund = receivedFund + _amount;
        IBEP20(inputtoken).transferFrom(msg.sender,address(this), _amount);
     }
     
     
     function claimTokens() public {
    
     // check claim Status
     require(claimenabled == true, "Claim not start");
     
     require(existinguser[msg.sender] == true, "Already claim"); 
      
     ICOUsersInfo storage icoStorage = ico[msg.sender];
     
     uint256 redeemtokens = icoStorage.remainingClaim;
     
     require(redeemtokens>0, "No tokens to redeem");
     
       if (block.timestamp < vestingTime) {
                require(icoStorage.claimround == 0, "Already claim tokens of Round1");
                uint userclaim = (redeemtokens * vestingperc) / 100;
                icoStorage.remainingClaim -= userclaim; 
                icoStorage.claimround = 1; 
                IBEP20(outputtoken).transfer(msg.sender, userclaim);
        }
        else {
            
                IBEP20(outputtoken).transfer(msg.sender,  icoStorage.remainingClaim);
                existinguser[msg.sender] = false;   
                icoStorage.investedamount = 0;
                icoStorage.maxallocation = 0;
                icoStorage.remainingallocation = 0;
                icoStorage.remainingClaim = 0;
                icoStorage.claimround = 0;
        }
    }

    
    function checkyourTier(address _owner)public view returns (uint8 _tier) {
        
        (,uint8 b)  =  nts.getStaker(_owner);
        return b;
    }
    
    function maxBuyIDOToken(address _owner) public view returns (uint256 _max) {
        
        (,uint8 b)  =  nts.getStaker(_owner);
        
        if (b == 1) {
            return tier1Max;
        }
        
        else if (b == 2) {
            return tier2Max;
        }
        
        else if (b == 3) {
            return tier3Max;
        }
        else if (b == 4){
            return tier4Max;
        }
        else {
            return 0;
        }
    }
    
    
    function maximumContribution(address _owner) public view returns (uint256 _max) {
        
        (,uint8 b)  =  nts.getStaker(_owner);
        
        if (b == 1) {
            
            return ((tier1Max * 1000) /tokenPrice) / 1000000000000;
        }
        
        else if (b == 2) {
            return ((tier2Max * 1000) /tokenPrice) / 1000000000000;
        }
        
        else if (b == 3) {
            return ((tier3Max * 1000) /tokenPrice) / 1000000000000;
        }
        else if (b == 4){
            return ((tier4Max * 1000) /tokenPrice) / 1000000000000;
        }
        else {
            return 0;
        }
    }
    
    
    function remainigContribution(address _owner) public view returns (uint256) {
        
        ICOUsersInfo memory icoStorage = ico[_owner];
        
        uint256 remaining = maximumContribution(_owner) - icoStorage.investedamount;
        
        return remaining;
    }
    
    
    
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkICObalance(uint8 _token) public view returns(uint256 _balance) {
        
      if (_token == 1) {
          
        return IBEP20(outputtoken).balanceOf(address(this));
      }
      else if (_token == 2) {
          
        return IBEP20(inputtoken).balanceOf(address(this));  
      }
      
      else {
          return 0;
      }
    }
    
   

    function withdarwInputToken(address _admin, uint256 _amount) public onlyOwner{
        
    //   icoStatus = getIcoStatus();
    //   require(icoStatus == Status.completed, "ICO in not complete yet");
      
       uint256 raisedamount = IBEP20(inputtoken).balanceOf(address(this));
       
       require(raisedamount >= _amount, "Not enough token to withdraw");
       
       IBEP20(inputtoken).transfer(_admin, _amount);
        
    }
    
  
     function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{
        
    //   icoStatus = getIcoStatus();
    //   require(icoStatus == Status.completed, "ICO in not complete yet");
       
       uint256 remainingamount = IBEP20(outputtoken).balanceOf(address(this));
       
       require(remainingamount >= _amount, "Not enough token to withdraw");
       
       IBEP20(outputtoken).transfer(_admin, _amount);
    }
    
    
    
    function resetICO() public onlyOwner {
        
         for (uint256 i = 0; i < investors.length; i++) {
             
            if (existinguser[investors[i]]==true)
            {
                  existinguser[investors[i]]=false;
                  ico[investors[i]].investedamount = 0;
                  ico[investors[i]].maxallocation = 0;
                  ico[investors[i]].remainingallocation = 0;
                  ico[investors[i]].remainingClaim = 0;
                  ico[investors[i]].claimround = 0;
            }
        }
        
        require(IBEP20(outputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        require(IBEP20(inputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        
        totalsupply = 0;
        icoTarget = 0;
        icoStatus = false;
        tier1Max =  0;
        tier2Max =  0;
        tier3Max =  0;
        tier4Max =  0;
        receivedFund = 0;
        poolweightTier1 = 0;
        poolweightTier2 = 0;
        poolweightTier3 = 0;
        poolweightTier4 = 0;
        poolweightinitialize = false;
        claimenabled = false;
        claim=false;
        icoTarget = 0;
        vestingTime = 0;
        vestingperc = 0;
        
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        tokenPrice = 0;
        
        delete investors;
        
    }
    
     

    function initializeIDOPoolweight(uint256 pw1, uint256 pw2, uint256 pw3, uint256 pw4) external onlyOwner {
        
        require (poolweightinitialize == false, "Pool weight already initialize");
        
        poolweightTier1 = pw1;
        poolweightTier2 = pw2;
        poolweightTier3 = pw3;
        poolweightTier4 = pw4;
        
        poolweightinitialize = true;
    }
 
    
    function initializeIDO(address _inputtoken, address _outputtoken, uint256 _tokenprice) public onlyOwner {
        
        require (_tokenprice>0, "Token price must be greater than 0");
        require (poolweightinitialize == true, "First initialize pool weight");
        
        inputtoken = _inputtoken;
        outputtoken = _outputtoken;
        tokenPrice = _tokenprice;
        
        require(IBEP20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to IDO");
        require(IBEP20(inputtoken).decimals()==6, "Only six decimal input token allowed");
        
        totalsupply = IBEP20(outputtoken).balanceOf(address(this));
        icoTarget = ((totalsupply / _tokenprice) * 1000 ) / 1000000000000;
        tier1Max =  getTier1Maxlimit();
        tier2Max =  getTier2Maxlimit();
        tier3Max =  getTier3Maxlimit();
        tier4Max =  getTier4Maxlimit();
    }
    
    function InitialzeVesting(uint256 _vestingtime, uint256 _vestingperc) external onlyOwner {
            
        require(vestingTime ==0 && vestingperc==0, "Vesting already initialzed");
        require(_vestingperc < 100, "Incorrect vestingpercentage");
            
        vestingTime = block.timestamp + _vestingtime;
        vestingperc = _vestingperc;
    }
}